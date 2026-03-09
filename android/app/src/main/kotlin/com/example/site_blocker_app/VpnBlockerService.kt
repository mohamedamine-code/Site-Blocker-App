package com.example.site_blocker_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.database.sqlite.SQLiteDatabase
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.app.NotificationCompat
import java.io.File
import java.io.FileInputStream
import java.io.IOException
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.jvm.Volatile
import kotlin.text.Charsets

class VpnBlockerService : VpnService() {

    companion object {
        private const val TAG = "VpnBlockerService"
        private const val CHANNEL_ID = "site_blocker_vpn_channel"
        private const val NOTIFICATION_ID = 1337
        private const val ACTION_REFRESH = "com.example.site_blocker_app.REFRESH_BLOCKLIST"
        private const val DATABASE_NAME = "site_blocker.db"
        private const val TABLE_NAME = "blocked_sites"
        @Volatile
        private var lastBlockedDomain: String? = null

        fun broadcastRefresh(context: Context) {
            context.sendBroadcast(Intent(ACTION_REFRESH))
        }

        fun consumePendingBlockedDomain(): String? {
            val value = lastBlockedDomain
            lastBlockedDomain = null
            return value
        }
    }

    private var vpnInterface: ParcelFileDescriptor? = null
    private var monitorThread: Thread? = null
    private val running = AtomicBoolean(false)
    private val blocklist = mutableSetOf<String>()

    private val refreshReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            loadBlocklist()
        }
    }

    override fun onCreate() {
        super.onCreate()
        val filter = IntentFilter(ACTION_REFRESH)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(refreshReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("DEPRECATION")
            registerReceiver(refreshReceiver, filter)
        }
    }

    override fun onDestroy() {
        unregisterReceiver(refreshReceiver)
        stopMonitoring()
        teardownVpn()
        super.onDestroy()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startVpn()
        return START_STICKY
    }

    private fun startVpn() {
        if (running.get()) {
            loadBlocklist()
            return
        }
        val builder = Builder()
            .setSession("Site Blocker VPN")
            .addAddress("10.0.0.2", 32)
            .addDnsServer("1.1.1.1")
            .addDnsServer("8.8.8.8")
            .addRoute("0.0.0.0", 0)

        vpnInterface = builder.establish()
        if (vpnInterface == null) {
            Log.e(TAG, "Failed to establish VPN interface")
            stopSelf()
            return
        }

        loadBlocklist()
        startForegroundNotification()
        startMonitoring()
        running.set(true)
    }

    private fun startForegroundNotification() {
        val manager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Site Blocker VPN",
                NotificationManager.IMPORTANCE_LOW,
            )
            manager?.createNotificationChannel(channel)
        }

        val launchIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Site blocker is active")
            .setContentText("Monitoring traffic for blocked domains")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
        startForeground(NOTIFICATION_ID, notification)
    }

    private fun loadBlocklist() {
        try {
            val dbFile: File = applicationContext.getDatabasePath(DATABASE_NAME)
            if (!dbFile.exists()) {
                synchronized(blocklist) {
                    blocklist.clear()
                }
                return
            }
            val database = SQLiteDatabase.openDatabase(
                dbFile.path,
                null,
                SQLiteDatabase.OPEN_READONLY,
            )
            val cursor = database.query(
                TABLE_NAME,
                arrayOf("url"),
                null,
                null,
                null,
                null,
                null,
            )
            val domains = mutableSetOf<String>()
            cursor.use {
                while (it.moveToNext()) {
                    domains.add(it.getString(0))
                }
            }
            database.close()
            synchronized(blocklist) {
                blocklist.clear()
                blocklist.addAll(domains)
            }
        } catch (ex: Exception) {
            Log.e(TAG, "Unable to load blocklist", ex)
        }
    }

    private fun startMonitoring() {
        stopMonitoring()
        val descriptor = vpnInterface ?: return
        monitorThread = Thread {
            try {
                FileInputStream(descriptor.fileDescriptor).use { input ->
                    val buffer = ByteArray(32 * 1024)
                    while (!Thread.currentThread().isInterrupted && running.get()) {
                        val length = input.read(buffer)
                        if (length <= 0) continue
                        val payload = String(buffer, 0, length, Charsets.UTF_8)
                        val blockedDomain = findBlockedDomain(payload)
                        if (blockedDomain != null) {
                            notifyBlockedAttempt(blockedDomain)
                        }
                    }
                }
            } catch (ex: IOException) {
                Log.d(TAG, "Monitor stopped: ${ex.message}")
            }
        }.apply { start() }
    }

    private fun stopMonitoring() {
        monitorThread?.interrupt()
        monitorThread = null
    }

    private fun teardownVpn() {
        try {
            vpnInterface?.close()
        } catch (ex: IOException) {
            Log.e(TAG, "Error closing VPN interface", ex)
        }
        vpnInterface = null
        running.set(false)
    }

    private fun findBlockedDomain(payload: String): String? {
        synchronized(blocklist) {
            return blocklist.firstOrNull { domain ->
                payload.contains(domain, ignoreCase = true)
            }
        }
    }

    private fun notifyBlockedAttempt(domain: String) {
        lastBlockedDomain = domain
        FlutterChannelBridge.sendBlockedDomain(domain)
        val manager = getSystemService(NotificationManager::class.java)
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Blocked site attempt")
            .setContentText("$domain is blocked on this device.")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setAutoCancel(true)
            .build()
        manager?.notify(NOTIFICATION_ID + 1, notification)
    }
}

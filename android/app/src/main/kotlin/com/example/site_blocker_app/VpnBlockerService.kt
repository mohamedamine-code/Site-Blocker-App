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
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.net.SocketTimeoutException
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException
import java.io.ByteArrayOutputStream
import kotlin.math.min
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.jvm.Volatile

class VpnBlockerService : VpnService() {

    companion object {
        private const val TAG = "VpnBlockerService"
        private const val CHANNEL_ID = "site_blocker_vpn_channel"
        private const val NOTIFICATION_ID = 1337
        private const val ACTION_REFRESH = "com.example.site_blocker_app.REFRESH_BLOCKLIST"
        private const val DATABASE_NAME = "site_blocker.db"
        private const val TABLE_NAME = "blocked_sites"
        private const val VPN_DNS_ADDRESS = "10.0.0.2"
        private const val PRIMARY_DNS = "1.1.1.1"
        private const val SECONDARY_DNS = "8.8.8.8"
        private val inMemoryBlocklist = mutableSetOf<String>()
        @Volatile
        private var lastBlockedDomain: String? = null

        fun updateInMemoryBlocklist(domains: List<String>) {
            synchronized(inMemoryBlocklist) {
                inMemoryBlocklist.clear()
                domains.forEach { domain ->
                    val canonical = canonicalizeDomain(domain)
                    if (canonical.isNotEmpty()) {
                        inMemoryBlocklist.add(canonical)
                    }
                }
            }
        }

        private fun canonicalizeDomain(raw: String): String {
            val normalized = raw.trim().lowercase().trimEnd('.')
            return if (normalized.startsWith("www.")) {
                normalized.removePrefix("www.")
            } else {
                normalized
            }
        }

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
            .addAddress(VPN_DNS_ADDRESS, 32)
            // Force system DNS into the VPN interface itself.
            .addDnsServer(VPN_DNS_ADDRESS)
            .addRoute(VPN_DNS_ADDRESS, 32)

        vpnInterface = builder.establish()
        if (vpnInterface == null) {
            Log.e(TAG, "Failed to establish VPN interface")
            stopSelf()
            return
        }

        loadBlocklist()
        startForegroundNotification()
        running.set(true)
        startMonitoring()
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
                    val canonical = canonicalizeDomain(it.getString(0))
                    if (canonical.isNotEmpty()) {
                        domains.add(canonical)
                    }
                }
            }
            database.close()

            synchronized(inMemoryBlocklist) {
                domains.addAll(inMemoryBlocklist)
            }

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
                    FileOutputStream(descriptor.fileDescriptor).use { output ->
                    val buffer = ByteArray(32 * 1024)
                    while (!Thread.currentThread().isInterrupted && running.get()) {
                        val length = input.read(buffer)
                        if (length <= 0) continue

                        val request = parseDnsRequest(buffer, length) ?: continue
                        val blockedDomain = findMatchingBlockedDomain(request.queryDomain)
                        val dnsResponse = if (blockedDomain != null) {
                            notifyBlockedAttempt(blockedDomain)
                            buildBlockedDnsResponse(request.dnsPayload, request.questionEndOffset)
                        } else {
                            forwardDnsQuery(request.dnsPayload)
                        }

                        if (dnsResponse != null) {
                            val ipPacket = buildIpv4UdpResponsePacket(request, dnsResponse)
                            output.write(ipPacket)
                        }
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
        running.set(false)
        try {
            vpnInterface?.close()
        } catch (ex: IOException) {
            Log.e(TAG, "Error closing VPN interface", ex)
        }
        vpnInterface = null
    }

    private fun findMatchingBlockedDomain(queryDomain: String): String? {
        val normalizedQuery = canonicalizeDomain(queryDomain)
        synchronized(blocklist) {
            return blocklist.firstOrNull { domain ->
                normalizedQuery == domain || normalizedQuery.endsWith(".$domain")
            }
        }
    }

    private data class ParsedDnsRequest(
        val sourceIp: Int,
        val destinationIp: Int,
        val sourcePort: Int,
        val destinationPort: Int,
        val dnsPayload: ByteArray,
        val queryDomain: String,
        val questionEndOffset: Int,
    )

    private fun parseDnsRequest(packet: ByteArray, packetLength: Int): ParsedDnsRequest? {
        if (packetLength < 28) return null

        val version = (packet[0].toInt() ushr 4) and 0x0F
        if (version != 4) return null

        val ipHeaderLength = (packet[0].toInt() and 0x0F) * 4
        if (ipHeaderLength < 20 || packetLength < ipHeaderLength + 8) return null

        val totalLength = readU16(packet, 2)
        if (totalLength <= ipHeaderLength + 8 || totalLength > packetLength) return null
        if (packet[9].toInt() and 0xFF != 17) return null // UDP

        val udpOffset = ipHeaderLength
        val sourcePort = readU16(packet, udpOffset)
        val destinationPort = readU16(packet, udpOffset + 2)
        if (destinationPort != 53) return null

        val udpLength = readU16(packet, udpOffset + 4)
        val dnsOffset = udpOffset + 8
        val dnsLength = min(totalLength - dnsOffset, udpLength - 8)
        if (dnsLength < 12 || dnsOffset + dnsLength > packetLength) return null

        val dnsPayload = packet.copyOfRange(dnsOffset, dnsOffset + dnsLength)
        val parsedQuestion = parseDnsQuestion(dnsPayload) ?: return null

        return ParsedDnsRequest(
            sourceIp = readU32(packet, 12),
            destinationIp = readU32(packet, 16),
            sourcePort = sourcePort,
            destinationPort = destinationPort,
            dnsPayload = dnsPayload,
            queryDomain = parsedQuestion.first,
            questionEndOffset = parsedQuestion.second,
        )
    }

    private fun parseDnsQuestion(dnsPayload: ByteArray): Pair<String, Int>? {
        val questionCount = readU16(dnsPayload, 4)
        if (questionCount <= 0) return null

        var index = 12
        val labels = mutableListOf<String>()
        while (index < dnsPayload.size) {
            val length = dnsPayload[index].toInt() and 0xFF
            if (length == 0) {
                index += 1
                break
            }
            // DNS compression pointers are not expected in standard queries.
            if ((length and 0xC0) == 0xC0) {
                return null
            }
            index += 1
            if (index + length > dnsPayload.size) return null
            labels.add(String(dnsPayload, index, length, Charsets.UTF_8))
            index += length
        }

        if (index + 4 > dnsPayload.size) return null
        val questionEndOffset = index + 4
        val domain = labels.joinToString(".")
        return Pair(domain, questionEndOffset)
    }

    private fun forwardDnsQuery(dnsPayload: ByteArray): ByteArray? {
        return queryUpstreamDns(PRIMARY_DNS, dnsPayload)
            ?: queryUpstreamDns(SECONDARY_DNS, dnsPayload)
    }

    private fun queryUpstreamDns(dnsServerIp: String, dnsPayload: ByteArray): ByteArray? {
        return try {
            val destination = InetAddress.getByName(dnsServerIp)
            DatagramSocket().use { socket ->
                if (!protect(socket)) {
                    Log.w(TAG, "Could not protect DNS socket; dropping DNS query")
                    return null
                }
                socket.soTimeout = 2500

                val outgoing = DatagramPacket(dnsPayload, dnsPayload.size, destination, 53)
                socket.send(outgoing)

                val responseBuffer = ByteArray(4096)
                val incoming = DatagramPacket(responseBuffer, responseBuffer.size)
                socket.receive(incoming)
                incoming.data.copyOfRange(0, incoming.length)
            }
        } catch (_: SocketTimeoutException) {
            null
        } catch (ex: Exception) {
            Log.w(TAG, "DNS forward failed via $dnsServerIp: ${ex.message}")
            null
        }
    }

    private fun buildBlockedDnsResponse(requestPayload: ByteArray, questionEndOffset: Int): ByteArray {
        val stream = ByteArrayOutputStream()
        // Transaction ID
        stream.write(requestPayload[0].toInt())
        stream.write(requestPayload[1].toInt())
        // Standard response + recursion available + NXDOMAIN
        stream.write(0x81)
        stream.write(0x83)
        // QDCOUNT=1, ANCOUNT=0, NSCOUNT=0, ARCOUNT=0
        stream.write(0x00)
        stream.write(0x01)
        stream.write(0x00)
        stream.write(0x00)
        stream.write(0x00)
        stream.write(0x00)
        stream.write(0x00)
        stream.write(0x00)

        // Copy original question section.
        val safeQuestionEnd = questionEndOffset.coerceIn(12, requestPayload.size)
        stream.write(requestPayload, 12, safeQuestionEnd - 12)
        return stream.toByteArray()
    }

    private fun buildIpv4UdpResponsePacket(request: ParsedDnsRequest, dnsPayload: ByteArray): ByteArray {
        val ipHeaderLength = 20
        val udpHeaderLength = 8
        val totalLength = ipHeaderLength + udpHeaderLength + dnsPayload.size
        val packet = ByteArray(totalLength)

        packet[0] = 0x45
        packet[1] = 0x00
        writeU16(packet, 2, totalLength)
        writeU16(packet, 4, 0)
        writeU16(packet, 6, 0)
        packet[8] = 64
        packet[9] = 17
        writeU16(packet, 10, 0)
        writeU32(packet, 12, request.destinationIp)
        writeU32(packet, 16, request.sourceIp)
        writeU16(packet, 10, computeIpv4HeaderChecksum(packet, 0, ipHeaderLength))

        val udpOffset = ipHeaderLength
        writeU16(packet, udpOffset, request.destinationPort)
        writeU16(packet, udpOffset + 2, request.sourcePort)
        writeU16(packet, udpOffset + 4, udpHeaderLength + dnsPayload.size)
        // For IPv4 UDP, zero checksum means checksum disabled.
        writeU16(packet, udpOffset + 6, 0)

        System.arraycopy(dnsPayload, 0, packet, ipHeaderLength + udpHeaderLength, dnsPayload.size)
        return packet
    }

    private fun readU16(bytes: ByteArray, offset: Int): Int {
        if (offset + 1 >= bytes.size) return 0
        return ((bytes[offset].toInt() and 0xFF) shl 8) or (bytes[offset + 1].toInt() and 0xFF)
    }

    private fun readU32(bytes: ByteArray, offset: Int): Int {
        if (offset + 3 >= bytes.size) return 0
        return ((bytes[offset].toInt() and 0xFF) shl 24) or
            ((bytes[offset + 1].toInt() and 0xFF) shl 16) or
            ((bytes[offset + 2].toInt() and 0xFF) shl 8) or
            (bytes[offset + 3].toInt() and 0xFF)
    }

    private fun writeU16(bytes: ByteArray, offset: Int, value: Int) {
        bytes[offset] = ((value ushr 8) and 0xFF).toByte()
        bytes[offset + 1] = (value and 0xFF).toByte()
    }

    private fun writeU32(bytes: ByteArray, offset: Int, value: Int) {
        bytes[offset] = ((value ushr 24) and 0xFF).toByte()
        bytes[offset + 1] = ((value ushr 16) and 0xFF).toByte()
        bytes[offset + 2] = ((value ushr 8) and 0xFF).toByte()
        bytes[offset + 3] = (value and 0xFF).toByte()
    }

    private fun computeIpv4HeaderChecksum(bytes: ByteArray, offset: Int, length: Int): Int {
        var sum = 0
        var index = offset
        while (index < offset + length) {
            if (index == offset + 10) {
                index += 2
                continue
            }
            val word = ((bytes[index].toInt() and 0xFF) shl 8) or (bytes[index + 1].toInt() and 0xFF)
            sum += word
            while ((sum ushr 16) != 0) {
                sum = (sum and 0xFFFF) + (sum ushr 16)
            }
            index += 2
        }
        return sum.inv() and 0xFFFF
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

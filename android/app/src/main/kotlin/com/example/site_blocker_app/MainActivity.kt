package com.example.site_blocker_app

import android.content.Intent
import android.net.VpnService
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channelName = "site_blocker_vpn"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        FlutterChannelBridge.channel = channel
        channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "startVpn" -> {
                        val intent = VpnService.prepare(this)
                        if (intent != null) {
                            startActivity(intent)
                            result.error(
                                "vpn_permission",
                                "VPN permission required. Accept the system dialog and try again.",
                                null
                            )
                        } else {
                            startVpnService()
                            result.success(null)
                        }
                    }
                    "refreshBlocklist" -> {
                        VpnBlockerService.broadcastRefresh(this)
                        result.success(null)
                    }
                    "stopVpn" -> {
                        stopService(Intent(this, VpnBlockerService::class.java))
                        result.success(null)
                    }
                    "getPendingBlockedDomain" -> {
                        result.success(VpnBlockerService.consumePendingBlockedDomain())
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        FlutterChannelBridge.channel = null
        super.onDestroy()
    }

    private fun startVpnService() {
        val intent = Intent(this, VpnBlockerService::class.java)
        ContextCompat.startForegroundService(this, intent)
    }
}

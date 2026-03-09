package com.example.site_blocker_app

import android.content.Intent
import android.net.VpnService
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val VPN_REQUEST_CODE = 2001
    }

    private val channelName = "site_blocker_vpn"
    private var pendingVpnPermissionResult: MethodChannel.Result? = null

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
                            pendingVpnPermissionResult?.error(
                                "vpn_permission_interrupted",
                                "A new VPN permission request replaced the previous one.",
                                null,
                            )
                            pendingVpnPermissionResult = result
                            @Suppress("DEPRECATION")
                            startActivityForResult(intent, VPN_REQUEST_CODE)
                        } else {
                            startVpnService()
                            result.success(null)
                        }
                    }
                    "refreshBlocklist" -> {
                        val domains =
                            (call.arguments as? List<*>)
                                ?.mapNotNull { (it as? String)?.trim()?.lowercase() }
                                ?: emptyList()
                        VpnBlockerService.updateInMemoryBlocklist(domains)
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

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != VPN_REQUEST_CODE) {
            return
        }

        val pendingResult = pendingVpnPermissionResult
        pendingVpnPermissionResult = null
        if (resultCode == RESULT_OK) {
            startVpnService()
            pendingResult?.success(null)
        } else {
            pendingResult?.error(
                "vpn_permission_denied",
                "VPN permission was denied. Please allow it to enable blocking.",
                null,
            )
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

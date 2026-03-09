package com.example.site_blocker_app

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel

object FlutterChannelBridge {
    var channel: MethodChannel? = null

    fun sendBlockedDomain(domain: String) {
        val methodChannel = channel ?: return
        Handler(Looper.getMainLooper()).post {
            methodChannel.invokeMethod("blockedDomain", domain)
        }
    }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/block_screen.dart';

class VpnServiceController {
  VpnServiceController._() {
    _channel.setMethodCallHandler(_handleNativeCallbacks);
  }

  static final VpnServiceController instance = VpnServiceController._();

  static const _channel = MethodChannel('site_blocker_vpn');

  GlobalKey<NavigatorState>? _navigatorKey;

  void attachNavigator(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  Future<void> _handleNativeCallbacks(MethodCall call) async {
    if (call.method == 'blockedDomain') {
      final blockedUrl = (call.arguments as String?) ?? 'Blocked site';
      _openBlockScreen(blockedUrl);
    }
  }

  void _openBlockScreen(String url) {
    final navigator = _navigatorKey?.currentState;
    navigator?.pushNamed(
      BlockScreen.routeName,
      arguments: url,
    );
  }

  Future<void> startVpn() async {
    try {
      await _channel.invokeMethod('startVpn');
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Unable to start VPN service');
    }
  }

  Future<void> refreshBlocklist() async {
    try {
      await _channel.invokeMethod('refreshBlocklist');
    } on PlatformException {
      // The service might not be running yet; ignore and rely on the next refresh.
    }
  }

  Future<void> stopVpn() async {
    try {
      await _channel.invokeMethod('stopVpn');
    } on PlatformException {
      // Best effort only.
    }
  }

  Future<void> showPendingBlockedScreen() async {
    try {
      final blocked =
          await _channel.invokeMethod<String?>('getPendingBlockedDomain');
      if (blocked != null) {
        _openBlockScreen(blocked);
      }
    } on PlatformException {
      // No pending state available.
    }
  }
}

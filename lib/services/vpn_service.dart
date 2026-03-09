import 'package:flutter/services.dart';

import 'backend_blocklist_service.dart';
import 'database_service.dart';

class VpnServiceController {
  VpnServiceController._() {
    _channel.setMethodCallHandler(_handleNativeCallbacks);
  }

  static final VpnServiceController instance = VpnServiceController._();

  static const _channel = MethodChannel('site_blocker_vpn');

  void attachNavigator(dynamic navigatorKey) {
    // No-op: blocked-site screen flow is intentionally disabled.
  }

  Future<void> _handleNativeCallbacks(MethodCall call) async {
    if (call.method == 'blockedDomain') {
      // Intentionally ignored to avoid showing blocked-site message screens.
    }
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
      final localDomains = await DatabaseService.instance.getBlockedDomains();
      final backendDomains =
          await BackendBlocklistService.instance.fetchBlockedDomains();
      final blockedDomains = {
        ...localDomains,
        ...backendDomains,
      }.toList()
        ..sort();
      final applied =
          await _channel.invokeMethod<bool>('refreshBlocklist', blockedDomains);
      if (applied != true) {
        // Service may still be starting; one short retry avoids requiring app restart.
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await _channel.invokeMethod<bool>('refreshBlocklist', blockedDomains);
      }
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
    // Intentionally disabled to avoid message screens for blocked attempts.
  }

  Future<String> getPrivateDnsMode() async {
    try {
      final mode = await _channel.invokeMethod<String>('getPrivateDnsMode');
      return mode ?? 'unknown';
    } on PlatformException {
      return 'unknown';
    }
  }

  Future<String?> findMatchingBlockedDomain(String domain) async {
    try {
      if (domain.trim().isEmpty) {
        return null;
      }
      return await _channel.invokeMethod<String>(
        'findMatchingBlockedDomain',
        domain,
      );
    } on PlatformException {
      return null;
    }
  }
}

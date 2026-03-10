import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  AppSettingsService._();

  static final AppSettingsService instance = AppSettingsService._();

  static const _vpnAutoStartKey = 'vpn_auto_start_enabled';

  Future<bool> isVpnAutoStartEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vpnAutoStartKey) ?? true;
  }

  Future<void> setVpnAutoStartEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vpnAutoStartKey, enabled);
  }
}

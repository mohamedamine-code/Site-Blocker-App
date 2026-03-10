import 'package:flutter/material.dart';

import 'screens/BlockedSiteInfo.dart';
import 'screens/add_site_screen.dart';
import 'screens/block_screen.dart';
import 'screens/home_screen.dart';
import 'screens/remove_site_screen.dart';
import 'screens/settings_screen.dart';
import 'services/app_settings_service.dart';
import 'services/database_service.dart';
import 'services/vpn_service.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.instance.initialize();
  VpnServiceController.instance.attachNavigator(appNavigatorKey);
  runApp(const SiteBlockerApp());
}

class SiteBlockerApp extends StatefulWidget {
  const SiteBlockerApp({super.key});

  @override
  State<SiteBlockerApp> createState() => _SiteBlockerAppState();
}

class _SiteBlockerAppState extends State<SiteBlockerApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoStartVpnOnLaunch();
    });
  }

  Future<void> _autoStartVpnOnLaunch() async {
    final autoStartEnabled =
        await AppSettingsService.instance.isVpnAutoStartEnabled();
    if (!autoStartEnabled) {
      return;
    }

    try {
      await VpnServiceController.instance.startVpn();
      await VpnServiceController.instance.refreshBlocklist();
    } catch (_) {
      // Best effort: user may deny permission or service may be unavailable briefly.
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Site Blocker',
      navigatorKey: appNavigatorKey,
      theme: buildAppTheme(),
      initialRoute: HomeScreen.routeName,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case HomeScreen.routeName:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const HomeScreen(),
            );
          case BlockedSiteInfoScreen.routeName:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const BlockedSiteInfoScreen(),
            );
          case AddSiteScreen.routeName:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const AddSiteScreen(),
            );
          case RemoveSiteScreen.routeName:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const RemoveSiteScreen(),
            );
          case SettingsScreen.routeName:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const SettingsScreen(),
            );
          case BlockScreen.routeName:
            final url = settings.arguments as String? ?? 'Blocked site';
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => BlockScreen(url: url),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const HomeScreen(),
            );
        }
      },
    );
  }
}

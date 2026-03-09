import 'package:flutter/material.dart';

import 'screens/add_site_screen.dart';
import 'screens/block_screen.dart';
import 'screens/home_screen.dart';
import 'screens/remove_site_screen.dart';
import 'services/database_service.dart';
import 'services/vpn_service.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.instance.initialize();
  VpnServiceController.instance.attachNavigator(appNavigatorKey);
  runApp(const SiteBlockerApp());
}

class SiteBlockerApp extends StatelessWidget {
  const SiteBlockerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Site Blocker',
      navigatorKey: appNavigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      initialRoute: HomeScreen.routeName,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case HomeScreen.routeName:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const HomeScreen(),
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

import 'package:flutter/material.dart';

import 'screens/BlockedSiteInfo.dart';
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
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0D6E6E),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Site Blocker',
      navigatorKey: appNavigatorKey,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF5F7F8),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          centerTitle: false,
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          filled: true,
          fillColor: colorScheme.surface,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
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

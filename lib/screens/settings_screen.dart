import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/app_settings_service.dart';
import '../services/database_service.dart';
import '../services/vpn_service.dart';
import '../widgets/security_app_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoStart = true;
  bool _darkTheme = true;
  bool _isProtected = true;
  bool _exporting = false;
  String _versionLabel = 'v--';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final results = await Future.wait<dynamic>([
      VpnServiceController.instance.getPrivateDnsMode(),
      PackageInfo.fromPlatform(),
      AppSettingsService.instance.isVpnAutoStartEnabled(),
    ]);

    if (!mounted) {
      return;
    }

    final dnsMode = results[0] as String;
    final packageInfo = results[1] as PackageInfo;
    final autoStartEnabled = results[2] as bool;

    setState(() {
      _isProtected = dnsMode != 'opportunistic' && dnsMode != 'hostname';
      _versionLabel = 'v${packageInfo.version} (${packageInfo.buildNumber})';
      _autoStart = autoStartEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: SecurityAppBar(
        title: 'Settings',
        isProtected: _isProtected,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: _autoStart,
                  onChanged: (value) async {
                    HapticFeedback.selectionClick();
                    await AppSettingsService.instance.setVpnAutoStartEnabled(value);
                    if (!mounted) {
                      return;
                    }
                    setState(() {
                      _autoStart = value;
                    });
                  },
                  title: const Text('VPN auto-start'),
                  subtitle: Text(
                    'Start protection automatically on app launch.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ),
                Divider(color: colors.outlineVariant, height: 1),
                SwitchListTile(
                  value: _darkTheme,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Dark mode is the only available theme for now.')),
                    );
                    setState(() {
                      _darkTheme = true;
                    });
                  },
                  title: const Text('Dark theme'),
                  subtitle: Text(
                    'Security-focused dark visual mode.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _exporting ? null : _exportBlocklist,
              icon: _exporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_outlined),
              label: const Text('Export blocklist'),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _versionLabel,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBlocklist() async {
    setState(() {
      _exporting = true;
    });

    try {
      final sites = await DatabaseService.instance.fetchBlockedSites();
      final lines = <String>['domain,date_added'];
      for (final site in sites) {
        lines.add('${site.url},${site.dateAdded.toIso8601String()}');
      }

      final csv = lines.join('\n');
      await Clipboard.setData(ClipboardData(text: csv));
      await HapticFeedback.lightImpact();

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Blocklist CSV copied to clipboard.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _exporting = false;
        });
      }
    }
  }
}

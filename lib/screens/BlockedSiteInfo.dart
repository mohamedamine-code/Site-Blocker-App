// ignore_for_file: file_names

import 'package:flutter/material.dart';

import '../models/blocked_site.dart';
import '../services/database_service.dart';
import '../services/vpn_service.dart';
import '../widgets/action_tile.dart';
import '../widgets/metric_chip.dart';
import '../widgets/status_card.dart';
import 'add_site_screen.dart';
import 'home_screen.dart';
import 'remove_site_screen.dart';

class BlockedSiteInfoScreen extends StatefulWidget {
  const BlockedSiteInfoScreen({super.key});

  static const routeName = '/blocked-site-info';

  @override
  State<BlockedSiteInfoScreen> createState() => _BlockedSiteInfoScreenState();
}

class _BlockedSiteInfoScreenState extends State<BlockedSiteInfoScreen> {
  final _database = DatabaseService.instance;
  final _vpnService = VpnServiceController.instance;

  List<BlockedSite> _sites = [];
  bool _loading = true;
  bool _loadingMetrics = true;
  bool _privateDnsWarningShown = false;
  bool _vpnHealthy = true;
  String? _errorMessage;
  String? _syncWarning;
  DateTime? _lastSyncedAt;
  DailySummary _todaySummary =
      const DailySummary(blockedCount: 0, lastBlockedAt: null);
  int _cleanStreak = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.wait<void>([
      _loadSites(),
      _loadMetrics(),
    ]);
    await _startVpn();
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _loadingMetrics = true;
    });

    try {
      final results = await Future.wait<dynamic>([
        _database.getDailySummary(),
        _database.getCleanStreak(),
      ]);
      final summary = results[0] as DailySummary;
      final streak = results[1] as int;
      if (!mounted) return;
      setState(() {
        _todaySummary = summary;
        _cleanStreak = streak;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingMetrics = false;
        });
      }
    }
  }

  Future<void> _loadSites() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final sites = await _database.fetchBlockedSites();
      setState(() {
        _sites = sites;
      });
    } catch (error) {
      setState(() => _errorMessage = error.toString());
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _startVpn() async {
    try {
      final mode = await _vpnService.getPrivateDnsMode();
      final isBypassRisk = mode == 'opportunistic' || mode == 'hostname';
      if (isBypassRisk) {
        await _showPrivateDnsStrictModeDialog();
        if (!mounted) return;
        setState(() {
          _vpnHealthy = false;
          _errorMessage =
              'Strict blocking is disabled while Private DNS is enabled. Turn it off in Android network settings.';
        });
        return;
      }

      await _vpnService.startVpn();
      await _vpnService.refreshBlocklist();
      if (!mounted) return;
      setState(() {
        _vpnHealthy = true;
      });
    } catch (error) {
      setState(() {
        _vpnHealthy = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _showPrivateDnsStrictModeDialog() async {
    if (_privateDnsWarningShown) {
      return;
    }
    if (!mounted) return;

    _privateDnsWarningShown = true;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Disable Private DNS'),
          content: const Text(
            'Strict URL blocking requires Private DNS to be Off.\n\n'
            'Go to Android Settings > Network & Internet > Private DNS and set it to Off, then return to the app.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _navigateToAddSite() async {
    final added = await Navigator.pushNamed(context, AddSiteScreen.routeName);
    if (added == true) {
      await _loadSites();
      await _vpnService.refreshBlocklist();
      await _loadMetrics();
      if (!mounted) return;
      setState(() {
        _lastSyncedAt = DateTime.now();
      });
    }
  }

  Future<void> _navigateToRemoveSite() async {
    final removed =
        await Navigator.pushNamed(context, RemoveSiteScreen.routeName);
    if (removed == true) {
      await _loadSites();
      await _vpnService.refreshBlocklist();
      await _loadMetrics();
      if (!mounted) return;
      setState(() {
        _lastSyncedAt = DateTime.now();
      });
    }
  }

  void _openDashboard() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Site Blocker'),
        actions: [
          IconButton(
            onPressed: _openDashboard,
            tooltip: 'Dashboard',
            icon: const Icon(Icons.home_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshSitesAndBlocklist,
        child: _buildBody(),
      ),
    );
  }

  Future<void> _refreshSitesAndBlocklist() async {
    if (!mounted) return;
    setState(() {
      _syncWarning = null;
    });
    await _loadSites();
    await _startVpn();
    await _vpnService.refreshBlocklist();
    final unmatchedCount = await _validateRefreshCoverage();
    await _loadMetrics();
    if (!mounted) {
      return;
    }
    setState(() {
      _lastSyncedAt = DateTime.now();
      if (unmatchedCount > 0) {
        _syncWarning =
            '$unmatchedCount domain(s) are still not active after refresh. Kill and reopen the browser to clear DNS cache.';
      }
    });
  }

  Future<int> _validateRefreshCoverage() async {
    if (_sites.isEmpty) {
      return 0;
    }

    final unmatchedDomains = <String>[];
    for (final site in _sites) {
      final matchedDomain =
          await _vpnService.findMatchingBlockedDomain(site.url);
      if (matchedDomain == null) {
        unmatchedDomains.add(site.url);
      }
    }

    return unmatchedDomains.length;
  }

  Widget _buildBody() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _buildProtectionCard(),
        const SizedBox(height: 10),
        _buildMetricsRow(),
        const SizedBox(height: 14),
        Row(
          children: [
            ActionTile(
              label: 'Add Site',
              icon: Icons.add_circle_outline,
              onTap: _navigateToAddSite,
            ),
            const SizedBox(width: 10),
            ActionTile(
              label: 'Remove',
              icon: Icons.remove_circle_outline,
              color: Theme.of(context).colorScheme.error,
              onTap: _navigateToRemoveSite,
            ),
          ],
        ),
        if (_syncWarning != null) ...[
          const SizedBox(height: 12),
          StatusCard(
            title: 'Sync note',
            subtitle: _syncWarning!,
            icon: Icons.info_outline,
            color: Colors.orange,
          ),
        ],
        const SizedBox(height: 18),
        Text(
          'Blocked Sites',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_sites.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: const [
                  Icon(Icons.shield_outlined, size: 56, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    'No blocked sites yet. Tap Add Site to start protection.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ..._sites.map(
            (site) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(site.url),
                  subtitle: Text('Added on ${_formatDate(site.dateAdded)}'),
                ),
              ),
            ),
          ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }

  Widget _buildProtectionCard() {
    if (!_vpnHealthy || _errorMessage != null) {
      return StatusCard(
        title: 'Protection needs attention',
        subtitle: _errorMessage ?? 'VPN is not fully active.',
        icon: Icons.warning_amber_rounded,
        color: Theme.of(context).colorScheme.error,
      );
    }

    return const StatusCard(
      title: 'Protection active',
      subtitle: 'DNS blocking is running. Pull down to sync latest rules.',
      icon: Icons.verified_user,
      color: Colors.green,
    );
  }

  Widget _buildMetricsRow() {
    final streakValue = _loadingMetrics ? '...' : '$_cleanStreak';
    final todayValue = _loadingMetrics ? '...' : '${_todaySummary.blockedCount}';
    final lastSyncValue = _lastSyncedAt == null ? '--:--' : _formatTime(_lastSyncedAt!);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        MetricChip(
          label: 'Clean streak',
          value: streakValue,
          icon: Icons.local_fire_department,
        ),
        MetricChip(
          label: 'Blocked today',
          value: todayValue,
          icon: Icons.block,
        ),
        MetricChip(
          label: 'Last sync',
          value: lastSyncValue,
          icon: Icons.sync,
        ),
      ],
    );
  }

  String _formatTime(DateTime date) {
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

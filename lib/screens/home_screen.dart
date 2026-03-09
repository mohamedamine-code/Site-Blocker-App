import 'package:flutter/material.dart';

import '../models/blocked_site.dart';
import '../services/database_service.dart';
import '../services/vpn_service.dart';
import 'add_site_screen.dart';
import 'remove_site_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _database = DatabaseService.instance;
  final _vpnService = VpnServiceController.instance;

  List<BlockedSite> _sites = [];
  bool _loading = true;
  bool _privateDnsWarningShown = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadSites();
    await _startVpn();
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
          _errorMessage =
              'Strict blocking is disabled while Private DNS is enabled. Turn it off in Android network settings.';
        });
        return;
      }

      await _vpnService.startVpn();
      await _vpnService.refreshBlocklist();
    } catch (error) {
      setState(() => _errorMessage = error.toString());
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
    }
  }

  Future<void> _navigateToRemoveSite() async {
    final removed =
        await Navigator.pushNamed(context, RemoveSiteScreen.routeName);
    if (removed == true) {
      await _loadSites();
      await _vpnService.refreshBlocklist();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Site Blocker'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshSitesAndBlocklist,
        child: _buildBody(),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'add-site',
            onPressed: _navigateToAddSite,
            icon: const Icon(Icons.add),
            label: const Text('Add Site'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'remove-site',
            backgroundColor: Colors.redAccent,
            onPressed: _navigateToRemoveSite,
            icon: const Icon(Icons.remove_circle_outline),
            label: const Text('Remove Site'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshSitesAndBlocklist() async {
    await _loadSites();
    await _startVpn();
    await _vpnService.refreshBlocklist();
    await _validateRefreshCoverage();
  }

  Future<void> _validateRefreshCoverage() async {
    if (_sites.isEmpty) {
      return;
    }

    final unmatchedDomains = <String>[];
    for (final site in _sites) {
      final matchedDomain =
          await _vpnService.findMatchingBlockedDomain(site.url);
      if (matchedDomain == null) {
        unmatchedDomains.add(site.url);
      }
    }

    if (!mounted || unmatchedDomains.isEmpty) {
      return;
    }

    final previewDomains = unmatchedDomains.take(3).join(', ');
    final remainingCount = unmatchedDomains.length - 3;
    final remainingLabel =
        remainingCount > 0 ? ' +$remainingCount more' : '';

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Refresh completed, but ${unmatchedDomains.length} domain(s) are not active yet: '
          '$previewDomains$remainingLabel',
        ),
      ),
    );
  }

  Widget _buildBody() {

    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 200),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      );
    }

    if (_sites.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Icon(Icons.shield, size: 72, color: Colors.grey),
          SizedBox(height: 16),
          Center(
            child: Text(
              'No blocked sites yet.\nUse the button below to add one.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _sites.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final site = _sites[index];
        return ListTile(
          leading: const Icon(Icons.language),
          title: Text(site.url),
          subtitle:
              Text('Added on ${_formatDate(site.dateAdded)}'),
        );
      },
    );

  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

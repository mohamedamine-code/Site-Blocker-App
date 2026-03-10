import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';

import '../services/database_service.dart';
import '../services/vpn_service.dart';
import '../widgets/action_tile.dart';
import '../widgets/error_banner.dart';
import '../widgets/hex_grid_background.dart';
import '../widgets/metric_chip.dart';
import '../widgets/security_app_bar.dart';
import 'BlockedSiteInfo.dart';
import 'add_site_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _database = DatabaseService.instance;
  final _vpnService = VpnServiceController.instance;

  bool _loading = true;
  bool _isProtected = true;
  String? _errorMessage;
  DateTime _displayedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  Set<int> _blockedDays = <int>{};
  DailySummary _todaySummary = const DailySummary(blockedCount: 0, lastBlockedAt: null);
  int _cleanStreak = 0;
  int _totalSites = 0;
  DateTime? _firstTrackedDate;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final results = await Future.wait<dynamic>([
        _database.getCalendarStatus(_displayedMonth),
        _database.getDailySummary(),
        _database.getCleanStreak(),
        _database.getFirstBlockedSiteDate(),
        _database.fetchBlockedSites(),
        _vpnService.getPrivateDnsMode(),
      ]);

      if (!mounted) {
        return;
      }

      final monthData = results[0] as Set<int>;
      final summary = results[1] as DailySummary;
      final streak = results[2] as int;
      final firstTracked = results[3] as DateTime?;
      final sites = results[4] as List<dynamic>;
      final privateDnsMode = results[5] as String;

      setState(() {
        _blockedDays = monthData;
        _todaySummary = summary;
        _cleanStreak = streak;
        _firstTrackedDate = firstTracked;
        _totalSites = sites.length;
        _isProtected = privateDnsMode != 'opportunistic' && privateDnsMode != 'hostname';
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SecurityAppBar(
        title: 'Site Blocker',
        isProtected: _isProtected,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            tooltip: 'Blocked sites',
            onPressed: _openBlockedSiteInfo,
            icon: const Icon(Icons.list_alt_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSite,
        icon: const Icon(Icons.add),
        label: const Text('Add site'),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: HexGridBackground()),
          Positioned.fill(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorState()
                    : RefreshIndicator(
                        onRefresh: _loadStats,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                          children: [
                            _buildProtectionHero(),
                            const SizedBox(height: 16),
                            _buildCounterCard(),
                            const SizedBox(height: 16),
                            _buildActionRow(),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                MetricChip(
                                  label: 'Blocked today',
                                  value: '${_todaySummary.blockedCount}',
                                  icon: Icons.block,
                                ),
                                MetricChip(
                                  label: 'Last blocked',
                                  value: _todaySummary.lastBlockedAt == null
                                      ? '--'
                                      : _timeLabel(_todaySummary.lastBlockedAt!),
                                  icon: Icons.schedule,
                                ),
                                MetricChip(
                                  label: 'Clean streak',
                                  value: '$_cleanStreak day(s)',
                                  icon: Icons.local_fire_department_outlined,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildCalendarHeader(context),
                            const SizedBox(height: 8),
                            _buildLegend(context),
                            const SizedBox(height: 8),
                            Card(child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: _buildCalendarGrid(context),
                            )),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        ErrorBanner(
          message: _errorMessage ?? 'Unable to load dashboard data.',
          onRetry: _loadStats,
        ),
      ],
    );
  }

  Widget _buildProtectionHero() {
    final colors = Theme.of(context).colorScheme;

    // Designer note: This top hero anchors attention on protection state first, since trust is primary for a VPN blocker.
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _isProtected
                    ? colors.primary.withValues(alpha: 0.14)
                    : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isProtected ? colors.primary : colors.outlineVariant,
                ),
              ),
              child: _buildAnimatedShieldIcon(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isProtected ? 'Protection is active' : 'Protection is limited',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isProtected
                        ? 'System-wide DNS filtering is running.'
                        : 'Disable Android Private DNS to restore strict blocking.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Container(
                      key: ValueKey<bool>(_isProtected),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isProtected
                            ? colors.primary.withValues(alpha: 0.16)
                            : colors.error.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _isProtected ? 'PROTECTED' : 'EXPOSED',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: _isProtected ? colors.primary : colors.error,
                              fontSize: 12,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedShieldIcon() {
    final colors = Theme.of(context).colorScheme;
    final icon = Icon(
      _isProtected ? Icons.shield_rounded : Icons.shield_outlined,
      color: _isProtected ? colors.primary : colors.onSurfaceVariant,
      size: 34,
    );

    if (_isProtected) {
      // Designer note: Subtle pulse communicates active enforcement without noisy motion.
      return icon
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scale(
            begin: const Offset(0.94, 0.94),
            end: const Offset(1.08, 1.08),
            duration: 900.ms,
            curve: Curves.easeInOut,
          );
    }

    return icon.animate().fadeIn(duration: 250.ms);
  }

  Widget _buildCounterCard() {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total blocked sites', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text(
                    '$_totalSites',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.track_changes, color: colors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow() {
    return Row(
      children: [
        ActionTile(
          label: 'Blocklist',
          icon: Icons.list_alt_outlined,
          onTap: _openBlockedSiteInfo,
        ),
        const SizedBox(width: 8),
        ActionTile(
          label: 'Settings',
          icon: Icons.tune,
          onTap: _openSettings,
        ),
      ],
    );
  }

  Widget _buildCalendarHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => _changeMonth(-1),
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            _monthLabel(_displayedMonth),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          onPressed: () => _changeMonth(1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _buildLegend(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Widget dot(Color color, String label) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        dot(colors.primary, 'Clean day'),
        dot(colors.error, 'Blocked day'),
        dot(colors.outlineVariant, 'Inactive/future'),
      ],
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    final monthStart = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final monthDays = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final leadingBlank = monthStart.weekday - 1;

    final cells = <Widget>[];
    for (var i = 0; i < leadingBlank; i++) {
      cells.add(const SizedBox());
    }

    for (var day = 1; day <= monthDays; day++) {
      final date = DateTime(_displayedMonth.year, _displayedMonth.month, day);
      cells.add(_buildDayCell(context, date));
    }

    const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      children: [
        Row(
          children: weekDays
              .map(
                (label) => Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
          children: cells,
        ),
      ],
    );
  }

  Widget _buildDayCell(BuildContext context, DateTime date) {
    final colors = Theme.of(context).colorScheme;
    final today = _dayOnly(DateTime.now());
    final firstTracked = _firstTrackedDate;
    final isFuture = date.isAfter(today);
    final beforeTracked = firstTracked != null && date.isBefore(firstTracked);
    final blocked = _blockedDays.contains(date.day);

    Color background;
    Color foreground;

    if (isFuture || beforeTracked) {
      background = colors.surfaceContainerHighest;
      foreground = colors.onSurfaceVariant;
    } else if (blocked) {
      background = colors.error.withValues(alpha: 0.18);
      foreground = colors.error;
    } else {
      background = colors.primary.withValues(alpha: 0.18);
      foreground = colors.primary;
    }

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: foreground.withValues(alpha: 0.45)),
      ),
      child: Text(
        '${date.day}',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: foreground),
      ),
    );
  }

  void _changeMonth(int delta) {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + delta, 1);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadStats();
    });
  }

  DateTime _dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  String _monthLabel(DateTime date) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${names[date.month - 1]} ${date.year}';
  }

  String _timeLabel(DateTime date) {
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _openBlockedSiteInfo() async {
    await HapticFeedback.lightImpact();
    if (!mounted) {
      return;
    }
    await Navigator.of(context).pushNamed(BlockedSiteInfoScreen.routeName);
    await _loadStats();
  }

  Future<void> _openSettings() async {
    await HapticFeedback.lightImpact();
    if (!mounted) {
      return;
    }
    await Navigator.of(context).pushNamed(SettingsScreen.routeName);
  }

  Future<void> _openAddSite() async {
    await HapticFeedback.lightImpact();
    if (!mounted) {
      return;
    }
    final added = await Navigator.of(context).pushNamed(AddSiteScreen.routeName);
    if (added == true) {
      await _loadStats();
    }
  }
}

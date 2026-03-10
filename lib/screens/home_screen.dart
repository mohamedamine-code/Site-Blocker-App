import 'package:flutter/material.dart';

import 'BlockedSiteInfo.dart';
import '../services/database_service.dart';
import '../widgets/metric_chip.dart';
import '../widgets/status_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _database = DatabaseService.instance;

  bool _loading = true;
  DateTime _displayedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  Set<int> _blockedDays = <int>{};
  DailySummary _todaySummary = const DailySummary(blockedCount: 0, lastBlockedAt: null);
  int _cleanStreak = 0;
  DateTime? _firstTrackedDate;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    final results = await Future.wait<dynamic>([
      _database.getCalendarStatus(_displayedMonth),
      _database.getDailySummary(),
      _database.getCleanStreak(),
      _database.getFirstBlockedSiteDate(),
    ]);
    final monthData = results[0] as Set<int>;
    final summary = results[1] as DailySummary;
    final streak = results[2] as int;
    final firstTracked = results[3] as DateTime?;

    if (!mounted) {
      return;
    }

    setState(() {
      _blockedDays = monthData;
      _todaySummary = summary;
      _cleanStreak = streak;
      _firstTrackedDate = firstTracked;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Tracking Stats'),
        actions: [
          IconButton(
            onPressed: _openBlockedSiteInfo,
            tooltip: 'Blocked sites',
            icon: const Icon(Icons.list_alt_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  StatusCard(
                    title: 'Clean streak',
                    subtitle: '$_cleanStreak day(s) with zero blocked attempts',
                    icon: Icons.local_fire_department,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 10),
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
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildCalendarHeader(context),
                  const SizedBox(height: 10),
                  _buildLegend(context),
                  const SizedBox(height: 12),
                  _buildCalendarGrid(context),
                ],
              ),
            ),
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
    Widget dot(Color color, String label) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        dot(Colors.green.shade400, 'Clean day'),
        dot(Colors.red.shade400, 'Blocked attempt'),
        dot(Colors.grey.shade400, 'Inactive/future'),
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
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          children: cells,
        ),
      ],
    );
  }

  Widget _buildDayCell(BuildContext context, DateTime date) {
    final today = _dayOnly(DateTime.now());
    final firstTracked = _firstTrackedDate;
    final isFuture = date.isAfter(today);
    final beforeTracked = firstTracked != null && date.isBefore(firstTracked);
    final blocked = _blockedDays.contains(date.day);

    Color color;
    if (isFuture || beforeTracked) {
      color = Colors.grey.shade300;
    } else if (blocked) {
      color = Colors.red.shade300;
    } else {
      color = Colors.green.shade300;
    }

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${date.day}',
        style: Theme.of(context).textTheme.labelLarge,
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

  void _openBlockedSiteInfo() {
    Navigator.of(context).pushNamed(BlockedSiteInfoScreen.routeName);
  }
}

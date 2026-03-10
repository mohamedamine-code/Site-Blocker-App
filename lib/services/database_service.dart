import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/blocking_event.dart';
import '../models/blocked_site.dart';
import '../utils/code_generator.dart';

class DailySummary {
  const DailySummary({
    required this.blockedCount,
    required this.lastBlockedAt,
  });

  final int blockedCount;
  final DateTime? lastBlockedAt;
}

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();
  static const _dbName = 'site_blocker.db';
  static const _dbVersion = 2;

  Database? _database;

  Future<void> initialize() async {
    _database ??= await _openDatabase();
  }

  Future<Database> _openDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _createBlockedSitesTable(db);
        await _createBlockingEventsTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createBlockingEventsTable(db);
        }
      },
    );
  }

  Future<void> _createBlockedSitesTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${BlockedSite.tableName}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT NOT NULL UNIQUE,
        removal_code_hash TEXT NOT NULL,
        date_added INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createBlockingEventsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${BlockingEvent.tableName}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        domain TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_blocking_events_timestamp '
      'ON ${BlockingEvent.tableName}(timestamp)',
    );
  }

  Future<Database> _ensureDb() async {
    if (_database == null) {
      await initialize();
    }
    return _database!;
  }

  Future<List<BlockedSite>> fetchBlockedSites() async {
    final db = await _ensureDb();
    final rows = await db.query(
      BlockedSite.tableName,
      orderBy: 'date_added DESC',
    );
    return rows.map(BlockedSite.fromMap).toList();
  }

  Future<Set<String>> getBlockedDomains() async {
    final db = await _ensureDb();
    final rows = await db.query(
      BlockedSite.tableName,
      columns: ['url'],
    );
    return rows.map((row) => row['url'] as String).toSet();
  }

  Future<String> addBlockedSite(String rawUrl) async {
    final db = await _ensureDb();
    final normalizedUrl = _normalizeUrl(rawUrl);
    final removalCode = CodeGenerator.generate();
    final hashedCode = _hash(removalCode);

    try {
      await db.insert(
        BlockedSite.tableName,
        {
          'url': normalizedUrl,
          'removal_code_hash': hashedCode,
          'date_added': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        throw StateError('This site is already blocked.');
      }
      throw StateError('Failed to block site: ${error.toString()}');
    }
    return removalCode;
  }

  Future<bool> removeBlockedSiteByCode(String removalCode) async {
    final sanitized = removalCode.trim();
    if (sanitized.isEmpty) {
      throw ArgumentError('Removal code cannot be empty');
    }
    final db = await _ensureDb();
    final hashedCode = _hash(sanitized);
    final deleted = await db.delete(
      BlockedSite.tableName,
      where: 'removal_code_hash = ?',
      whereArgs: [hashedCode],
    );
    return deleted > 0;
  }

  Future<void> recordBlockingEvent(String domain) async {
    final normalized = domain.trim().toLowerCase();
    if (normalized.isEmpty) {
      return;
    }
    final db = await _ensureDb();
    await db.insert(
      BlockingEvent.tableName,
      {
        'domain': normalized,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  Future<DailySummary> getDailySummary([DateTime? day]) async {
    final db = await _ensureDb();
    final target = _dayOnly(day ?? DateTime.now());
    final dayStart = target.millisecondsSinceEpoch;
    final dayEnd = target.add(const Duration(days: 1)).millisecondsSinceEpoch;

    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS blocked_count, MAX(timestamp) AS last_blocked '
      'FROM ${BlockingEvent.tableName} WHERE timestamp >= ? AND timestamp < ?',
      [dayStart, dayEnd],
    );

    if (rows.isEmpty) {
      return const DailySummary(blockedCount: 0, lastBlockedAt: null);
    }

    final row = rows.first;
    final blockedCount = (row['blocked_count'] as int?) ?? 0;
    final lastBlockedRaw = row['last_blocked'] as int?;
    return DailySummary(
      blockedCount: blockedCount,
      lastBlockedAt: lastBlockedRaw == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastBlockedRaw),
    );
  }

  Future<DateTime?> getFirstBlockedSiteDate() async {
    final db = await _ensureDb();
    final rows = await db.rawQuery(
      'SELECT MIN(date_added) AS first_date FROM ${BlockedSite.tableName}',
    );
    if (rows.isEmpty) {
      return null;
    }
    final raw = rows.first['first_date'] as int?;
    if (raw == null) {
      return null;
    }
    return _dayOnly(DateTime.fromMillisecondsSinceEpoch(raw));
  }

  Future<Set<int>> getCalendarStatus(DateTime month) async {
    final db = await _ensureDb();
    final monthStart = DateTime(month.year, month.month, 1);
    final nextMonth = DateTime(month.year, month.month + 1, 1);

    final rows = await db.rawQuery(
      "SELECT DISTINCT strftime('%d', timestamp / 1000, 'unixepoch', 'localtime') AS day "
      'FROM ${BlockingEvent.tableName} WHERE timestamp >= ? AND timestamp < ?',
      [
        monthStart.millisecondsSinceEpoch,
        nextMonth.millisecondsSinceEpoch,
      ],
    );

    final blockedDays = <int>{};
    for (final row in rows) {
      final value = row['day'] as String?;
      if (value == null) {
        continue;
      }
      final parsed = int.tryParse(value);
      if (parsed != null) {
        blockedDays.add(parsed);
      }
    }
    return blockedDays;
  }

  Future<int> getCleanStreak() async {
    final firstTracked = await getFirstBlockedSiteDate();
    if (firstTracked == null) {
      return 0;
    }

    final blockedDayKeys = await _getBlockedDayKeys();
    var streak = 0;
    var cursor = _dayOnly(DateTime.now());

    while (!cursor.isBefore(firstTracked)) {
      if (blockedDayKeys.contains(_dayKey(cursor))) {
        break;
      }
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  Future<Set<String>> _getBlockedDayKeys() async {
    final db = await _ensureDb();
    final rows = await db.rawQuery(
      "SELECT DISTINCT date(timestamp / 1000, 'unixepoch', 'localtime') AS day "
      'FROM ${BlockingEvent.tableName}',
    );
    final keys = <String>{};
    for (final row in rows) {
      final value = row['day'] as String?;
      if (value != null && value.isNotEmpty) {
        keys.add(value);
      }
    }
    return keys;
  }

  String _normalizeUrl(String rawUrl) {
    var value = rawUrl.trim();
    if (value.isEmpty) {
      throw ArgumentError('URL cannot be empty');
    }
    if (!value.contains('://')) {
      value = 'https://$value';
    }
    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty) {
      throw ArgumentError('Invalid URL');
    }

    var host = uri.host.toLowerCase().trim();
    if (host.startsWith('www.')) {
      host = host.substring(4);
    }
    host = host.replaceAll(RegExp(r'\.+$'), '');
    if (host.isEmpty || host.contains(' ')) {
      throw ArgumentError('Invalid URL');
    }
    return host;
  }

  String _hash(String code) {
    final digest = sha256.convert(utf8.encode(code));
    return digest.toString();
  }

  DateTime _dayOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _dayKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

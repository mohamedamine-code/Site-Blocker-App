import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/blocked_site.dart';
import '../utils/code_generator.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();
  static const _dbName = 'site_blocker.db';
  static const _dbVersion = 1;

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
        await db.execute('''
          CREATE TABLE ${BlockedSite.tableName}(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            url TEXT NOT NULL UNIQUE,
            removal_code_hash TEXT NOT NULL,
            date_added INTEGER NOT NULL
          )
        ''');
      },
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
}

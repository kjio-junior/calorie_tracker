import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

class BackupException implements Exception {
  const BackupException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// JSON export/import of every table plus profile and display settings.
/// The AI API key (secure storage) is intentionally never exported.
class BackupService {
  static const _tables = [
    'weight_logs',
    'daily_targets',
    'saved_foods',
    'food_logs',
    'cardio_logs',
    'workout_sessions',
    'workout_logs',
    'ai_summaries',
  ];

  static const _formatVersion = 1;

  static bool _isBackedUp(String key) =>
      key.startsWith('profile_') ||
      key.startsWith('ui_') ||
      key == 'theme_id' ||
      key == 'font_family' ||
      key == 'text_scale';

  Future<Uint8List> buildBackup() async {
    final db = await AppDatabase.instance.database;
    final tables = <String, Object?>{};
    for (final t in _tables) {
      tables[t] = await db.query(t);
    }

    final prefs = await SharedPreferences.getInstance();
    final prefMap = <String, Object>{};
    for (final k in prefs.getKeys()) {
      if (!_isBackedUp(k)) continue;
      final v = prefs.get(k);
      if (v != null) prefMap[k] = v;
    }

    final data = {
      'app': 'calorie_tracker',
      'format': _formatVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'tables': tables,
      'prefs': prefMap,
    };
    return Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(data)),
    );
  }

  /// Replaces ALL current data with the backup. Validation happens first and
  /// the database part runs in one transaction, so a bad file changes nothing.
  Future<void> restore(Uint8List bytes) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const BackupException('That file is not valid JSON.');
    }
    if (decoded is! Map<String, dynamic> ||
        decoded['app'] != 'calorie_tracker' ||
        decoded['tables'] is! Map) {
      throw const BackupException('This is not a Calorie Tracker backup.');
    }
    final format = decoded['format'];
    if (format is! int || format > _formatVersion) {
      throw const BackupException(
        'This backup was made by a newer version of the app.',
      );
    }
    final tables = decoded['tables'] as Map<String, dynamic>;
    for (final t in _tables) {
      final rows = tables[t];
      if (rows != null && rows is! List) {
        throw BackupException('The "$t" data in this backup is damaged.');
      }
    }

    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      for (final t in _tables) {
        final info = await txn.rawQuery('PRAGMA table_info($t)');
        final columns = info.map((r) => r['name'] as String).toSet();

        await txn.delete(t);
        final rows = (tables[t] as List?) ?? const [];
        for (final row in rows) {
          if (row is! Map) continue;
          final values = <String, Object?>{};
          row.forEach((k, v) {
            if (k is String && columns.contains(k)) values[k] = v;
          });
          if (values.isEmpty) continue;
          await txn.insert(
            t,
            values,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });

    final prefs = await SharedPreferences.getInstance();
    for (final k in prefs.getKeys().toList()) {
      if (_isBackedUp(k)) await prefs.remove(k);
    }
    final saved = decoded['prefs'];
    if (saved is Map) {
      for (final entry in saved.entries) {
        final k = entry.key;
        final v = entry.value;
        if (k is! String || !_isBackedUp(k)) continue;
        if (v is bool) {
          await prefs.setBool(k, v);
        } else if (v is int) {
          await prefs.setInt(k, v);
        } else if (v is double) {
          await prefs.setDouble(k, v);
        } else if (v is String) {
          await prefs.setString(k, v);
        } else if (v is List) {
          await prefs.setStringList(k, v.map((e) => e.toString()).toList());
        }
      }
    }
  }
}

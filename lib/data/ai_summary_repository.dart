import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

class AiSummaryRecord {
  const AiSummaryRecord({required this.date, required this.text});

  final String date;
  final String text;
}

class AiSummaryRepository {
  /// The most recent saved summary (kept so it stays readable offline).
  Future<AiSummaryRecord?> latest() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'ai_summaries',
      orderBy: 'date DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AiSummaryRecord(
      date: rows.first['date'] as String,
      text: rows.first['summary'] as String,
    );
  }

  Future<void> save(String date, String text) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'ai_summaries',
      {
        'date': date,
        'summary': text,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

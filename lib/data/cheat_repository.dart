import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

class CheatRepository {
  Future<Set<String>> allDays() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('cheat_days');
    return rows.map((r) => r['date'] as String).toSet();
  }

  Future<void> add(String date) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'cheat_days',
      {'date': date, 'created_at': DateTime.now().millisecondsSinceEpoch},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> remove(String date) async {
    final db = await AppDatabase.instance.database;
    await db.delete('cheat_days', where: 'date = ?', whereArgs: [date]);
  }
}

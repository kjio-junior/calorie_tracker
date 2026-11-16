import 'package:sqflite/sqflite.dart';

import '../core/utils/formatters.dart';
import '../domain/calorie_engine.dart';
import 'app_database.dart';

class WeightEntry {
  const WeightEntry({
    required this.id,
    required this.date,
    required this.weightKg,
  });

  final int id;
  final DateTime date;
  final double weightKg;
}

class DailyTargetRecord {
  const DailyTargetRecord({
    required this.date,
    required this.calorieTarget,
    required this.proteinTarget,
    required this.bmr,
    required this.tdee,
    required this.weightKg,
  });

  final String date;
  final int calorieTarget;
  final int? proteinTarget;
  final double bmr;
  final double tdee;
  final double weightKg;
}

class WeightRepository {
  Future<Database> get _db => AppDatabase.instance.database;

  /// One weigh-in per day: logging again on the same day replaces it.
  Future<void> upsertWeight(String date, double kg) async {
    final db = await _db;
    await db.insert(
      'weight_logs',
      {
        'date': date,
        'weight_kg': kg,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<WeightEntry>> allWeights() async {
    final db = await _db;
    final rows = await db.query('weight_logs', orderBy: 'date ASC');
    return rows
        .map(
          (r) => WeightEntry(
            id: r['id'] as int,
            date: Fmt.parseKey(r['date'] as String),
            weightKg: (r['weight_kg'] as num).toDouble(),
          ),
        )
        .toList();
  }

  Future<void> upsertTargets(
    String date,
    NutritionTargets t,
    double weightKg,
  ) async {
    final db = await _db;
    await db.insert(
      'daily_targets',
      {
        'date': date,
        'calorie_target': t.calorieTarget,
        'protein_target': t.proteinTarget,
        'bmr': t.bmr,
        'tdee': t.tdee,
        'weight_kg': weightKg,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// The targets that applied on [date]: the most recent record on or before it.
  Future<DailyTargetRecord?> targetsFor(String date) async {
    final db = await _db;
    final rows = await db.query(
      'daily_targets',
      where: 'date <= ?',
      whereArgs: [date],
      orderBy: 'date DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return DailyTargetRecord(
      date: r['date'] as String,
      calorieTarget: r['calorie_target'] as int,
      proteinTarget: r['protein_target'] as int?,
      bmr: (r['bmr'] as num).toDouble(),
      tdee: (r['tdee'] as num).toDouble(),
      weightKg: (r['weight_kg'] as num).toDouble(),
    );
  }

  /// Every saved daily-target record, oldest first (used for streaks).
  Future<List<DailyTargetRecord>> allTargets() async {
    final db = await _db;
    final rows = await db.query('daily_targets', orderBy: 'date ASC');
    return rows
        .map(
          (r) => DailyTargetRecord(
            date: r['date'] as String,
            calorieTarget: r['calorie_target'] as int,
            proteinTarget: r['protein_target'] as int?,
            bmr: (r['bmr'] as num).toDouble(),
            tdee: (r['tdee'] as num).toDouble(),
            weightKg: (r['weight_kg'] as num).toDouble(),
          ),
        )
        .toList();
  }

  Future<void> deleteWeight(int id) async {
    final db = await _db;
    await db.delete('weight_logs', where: 'id = ?', whereArgs: [id]);
  }
}

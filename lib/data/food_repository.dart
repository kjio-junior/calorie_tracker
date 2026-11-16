import 'package:sqflite/sqflite.dart';

import '../domain/food.dart';
import 'app_database.dart';

class FoodRepository {
  Future<Database> get _db => AppDatabase.instance.database;

  // ---- food log ----

  Future<List<FoodLogEntry>> logsForDate(String date) async {
    final db = await _db;
    final rows = await db.query(
      'food_logs',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'created_at ASC, id ASC',
    );
    return rows
        .map(
          (r) => FoodLogEntry(
            id: r['id'] as int,
            date: r['date'] as String,
            meal: Meal.values.byName(r['meal'] as String),
            name: r['name'] as String,
            servingDesc: r['serving_desc'] as String?,
            quantity: (r['quantity'] as num).toDouble(),
            calories: (r['calories'] as num).toDouble(),
            protein: (r['protein'] as num).toDouble(),
            savedFoodId: r['saved_food_id'] as int?,
          ),
        )
        .toList();
  }

  Future<int> insertLog(FoodLogEntry e) async {
    final db = await _db;
    return db.insert('food_logs', {
      'date': e.date,
      'meal': e.meal.name,
      'name': e.name,
      'serving_desc': e.servingDesc,
      'quantity': e.quantity,
      'calories': e.calories,
      'protein': e.protein,
      'saved_food_id': e.savedFoodId,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Edits name, meal, calories and protein of an existing entry.
  Future<void> updateLog(FoodLogEntry e) async {
    final db = await _db;
    await db.update(
      'food_logs',
      {
        'meal': e.meal.name,
        'name': e.name,
        'serving_desc': e.servingDesc,
        'calories': e.calories,
        'protein': e.protein,
      },
      where: 'id = ?',
      whereArgs: [e.id],
    );
  }

  Future<void> deleteLog(int id) async {
    final db = await _db;
    await db.delete('food_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<DayTotal>> dayTotals() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT date, COUNT(*) AS n, SUM(calories) AS cal, SUM(protein) AS pro
      FROM food_logs GROUP BY date ORDER BY date ASC''');
    return rows
        .map(
          (r) => DayTotal(
            date: r['date'] as String,
            entries: r['n'] as int,
            calories: (r['cal'] as num?)?.toDouble() ?? 0,
            protein: (r['pro'] as num?)?.toDouble() ?? 0,
          ),
        )
        .toList();
  }

  // ---- saved foods (cache of searched foods + custom offline foods) ----

  Future<int> saveFood(Food f) async {
    final db = await _db;
    final values = <String, Object?>{
      'name': f.name,
      'brand': f.brand,
      'source': f.source,
      'off_code': f.offCode,
      'serving_g': f.servingG,
      'serving_desc': f.servingDesc,
      'kcal_per_100g': f.kcalPer100g,
      'protein_per_100g': f.proteinPer100g,
      'kcal_per_serving': f.kcalPerServing,
      'protein_per_serving': f.proteinPerServing,
    };

    int? existingId = f.id;
    if (existingId == null && f.offCode != null) {
      final rows = await db.query(
        'saved_foods',
        columns: ['id'],
        where: 'off_code = ?',
        whereArgs: [f.offCode],
        limit: 1,
      );
      if (rows.isNotEmpty) existingId = rows.first['id'] as int;
    } else if (existingId == null) {
      final rows = await db.query(
        'saved_foods',
        columns: ['id'],
        where: "source = 'custom' AND lower(name) = lower(?)",
        whereArgs: [f.name],
        limit: 1,
      );
      if (rows.isNotEmpty) existingId = rows.first['id'] as int;
    }

    if (existingId != null) {
      await db.update(
        'saved_foods',
        values,
        where: 'id = ?',
        whereArgs: [existingId],
      );
      return existingId;
    }
    return db.insert('saved_foods', {
      ...values,
      'use_count': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> markUsed(int id) async {
    final db = await _db;
    await db.rawUpdate(
      'UPDATE saved_foods SET use_count = use_count + 1, last_used = ? '
      'WHERE id = ?',
      [DateTime.now().millisecondsSinceEpoch, id],
    );
  }

  /// Recent first, then most used, then alphabetical.
  Future<List<Food>> savedFoods({String query = ''}) async {
    final db = await _db;
    final q = query.trim();
    final rows = await db.query(
      'saved_foods',
      where: q.isEmpty ? null : 'name LIKE ? OR brand LIKE ?',
      whereArgs: q.isEmpty ? null : ['%$q%', '%$q%'],
      orderBy: 'last_used IS NULL, last_used DESC, use_count DESC, '
          'name COLLATE NOCASE',
      limit: 200,
    );
    return rows
        .map(
          (r) => Food(
            id: r['id'] as int,
            name: r['name'] as String,
            brand: r['brand'] as String?,
            source: r['source'] as String,
            offCode: r['off_code'] as String?,
            servingG: (r['serving_g'] as num?)?.toDouble(),
            servingDesc: r['serving_desc'] as String?,
            kcalPer100g: (r['kcal_per_100g'] as num?)?.toDouble(),
            proteinPer100g: (r['protein_per_100g'] as num?)?.toDouble(),
            kcalPerServing: (r['kcal_per_serving'] as num?)?.toDouble(),
            proteinPerServing: (r['protein_per_serving'] as num?)?.toDouble(),
          ),
        )
        .toList();
  }

  Future<void> deleteSavedFood(int id) async {
    final db = await _db;
    await db.delete('saved_foods', where: 'id = ?', whereArgs: [id]);
  }
}

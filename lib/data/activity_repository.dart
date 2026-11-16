import 'package:sqflite/sqflite.dart';

import '../domain/activity.dart';
import 'app_database.dart';

class ActivityRepository {
  Future<Database> get _db => AppDatabase.instance.database;

  // ---------------- cardio ----------------

  Future<List<CardioEntry>> cardioForDate(String date) async {
    final db = await _db;
    final rows = await db.query(
      'cardio_logs',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'created_at ASC, id ASC',
    );
    return rows
        .map(
          (r) => CardioEntry(
            id: r['id'] as int,
            date: r['date'] as String,
            type: CardioType.values.byName(r['activity_type'] as String),
            durationMin: (r['duration_min'] as num).toDouble(),
            distanceKm: (r['distance_km'] as num?)?.toDouble(),
            calories: (r['calories_burned'] as num?)?.toDouble(),
          ),
        )
        .toList();
  }

  Future<int> insertCardio(CardioEntry e) async {
    final db = await _db;
    return db.insert('cardio_logs', {
      'date': e.date,
      'activity_type': e.type.name,
      'duration_min': e.durationMin,
      'distance_km': e.distanceKm,
      'calories_burned': e.calories,
      'source': 'manual',
      'external_id': null,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> deleteCardio(int id) async {
    final db = await _db;
    await db.delete('cardio_logs', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- strength workouts ----------------

  Future<List<WorkoutSession>> sessionsForDate(String date) async {
    final db = await _db;
    final sessionRows = await db.query(
      'workout_sessions',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'created_at ASC, id ASC',
    );

    final result = <WorkoutSession>[];
    for (final r in sessionRows) {
      final id = r['id'] as int;
      final setRows = await db.query(
        'workout_logs',
        where: 'session_id = ?',
        whereArgs: [id],
        orderBy: 'id ASC',
      );

      final byExercise = <String, SessionExercise>{};
      for (final s in setRows) {
        final exId = s['exercise_id'] as String;
        final entry = byExercise.putIfAbsent(
          exId,
          () => SessionExercise(
            exerciseId: exId,
            name: s['exercise_name'] as String,
            group: MuscleGroup.values.byName(s['muscle_group'] as String),
            sets: [],
          ),
        );
        entry.sets.add(
          WorkoutSet(
            reps: s['reps'] as int,
            weightKg: (s['weight_kg'] as num).toDouble(),
          ),
        );
      }

      final intensity = r['intensity'] as String?;
      result.add(
        WorkoutSession(
          id: id,
          date: r['date'] as String,
          name: r['name'] as String?,
          durationMin: (r['duration_min'] as num?)?.toDouble(),
          intensity:
              intensity == null ? null : Intensity.values.byName(intensity),
          estCalories: (r['est_calories'] as num?)?.toDouble(),
          exercises: byExercise.values.toList(),
        ),
      );
    }
    return result;
  }

  Future<int> saveSession(WorkoutSession s) async {
    final db = await _db;
    return db.transaction<int>((txn) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final id = await txn.insert('workout_sessions', {
        'date': s.date,
        'name': s.name,
        'duration_min': s.durationMin,
        'intensity': s.intensity?.name,
        'est_calories': s.estCalories,
        'created_at': now,
      });
      for (final e in s.exercises) {
        for (var i = 0; i < e.sets.length; i++) {
          await txn.insert('workout_logs', {
            'session_id': id,
            'date': s.date,
            'exercise_id': e.exerciseId,
            'exercise_name': e.name,
            'muscle_group': e.group.name,
            'set_index': i + 1,
            'reps': e.sets[i].reps,
            'weight_kg': e.sets[i].weightKg,
            'est_calories': null,
            'created_at': now,
          });
        }
      }
      return id;
    });
  }

  Future<void> deleteSession(int id) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('workout_logs', where: 'session_id = ?', whereArgs: [id]);
      await txn.delete('workout_sessions', where: 'id = ?', whereArgs: [id]);
    });
  }
}

import 'app_database.dart';

class HistoryRepository {
  /// Every date that has any food, cardio, workout or weigh-in.
  Future<Set<String>> datesWithData() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT date FROM food_logs
      UNION SELECT date FROM cardio_logs
      UNION SELECT date FROM workout_sessions
      UNION SELECT date FROM weight_logs''');
    return rows.map((r) => r['date'] as String).toSet();
  }
}

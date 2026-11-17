import 'dart:math' as math;

import '../core/utils/formatters.dart';
import '../data/weight_repository.dart';
import 'food.dart';

class StreakStats {
  const StreakStats({
    required this.logging,
    required this.calorie,
    required this.protein,
    required this.bestLogging,
  });

  final int logging;
  final int calorie;
  final int protein;
  final int bestLogging;

  static const empty =
      StreakStats(logging: 0, calorie: 0, protein: 0, bestLogging: 0);
}

class StreakService {
  StreakService._();

  static const milestones = [3, 7, 14, 30, 60];

  /// Rules:
  /// - logging: at least one food entry that day
  /// - calorie: ate between 50% and 100% of that day's target
  /// - protein: reached that day's protein goal
  /// Today doesn't break a streak until it has finished: if today doesn't
  /// qualify yet, counting starts from yesterday.
  static StreakStats compute({
    required List<DayTotal> days,
    required List<DailyTargetRecord> targets,
    required DateTime today,
    Set<String> cheatDays = const {},
  }) {
    final byDate = {for (final d in days) d.date: d};

    DailyTargetRecord? targetFor(String key) {
      DailyTargetRecord? best;
      for (final t in targets) {
        if (t.date.compareTo(key) <= 0) {
          best = t;
        } else {
          break;
        }
      }
      return best;
    }

    bool logged(String k) => byDate.containsKey(k);

    bool calorieOk(String k) {
      final d = byDate[k];
      final t = targetFor(k);
      if (d == null || t == null) return false;
      return d.calories >= t.calorieTarget * 0.5 &&
          d.calories <= t.calorieTarget;
    }

    bool proteinOk(String k) {
      final d = byDate[k];
      final goal = targetFor(k)?.proteinTarget;
      if (d == null || goal == null) return false;
      return d.protein >= goal;
    }

    // With skipCheat, cheat days neither break nor extend the streak.
    int current(bool Function(String) ok, {bool skipCheat = false}) {
      bool neutral(String k) => skipCheat && cheatDays.contains(k);
      var d = DateTime.utc(today.year, today.month, today.day);
      final todayKey = Fmt.dateKey(d);
      if (!ok(todayKey) && !neutral(todayKey)) {
        d = d.subtract(const Duration(days: 1));
      }
      var n = 0;
      while (true) {
        final k = Fmt.dateKey(d);
        if (neutral(k)) {
          d = d.subtract(const Duration(days: 1));
          continue;
        }
        if (!ok(k)) break;
        n++;
        d = d.subtract(const Duration(days: 1));
      }
      return n;
    }

    var best = 0;
    var run = 0;
    DateTime? prev;
    for (final day in days) {
      final c = Fmt.parseKey(day.date);
      final cur = DateTime.utc(c.year, c.month, c.day);
      if (prev != null && cur.difference(prev).inDays == 1) {
        run++;
      } else {
        run = 1;
      }
      best = math.max(best, run);
      prev = cur;
    }

    return StreakStats(
      logging: current(logged),
      calorie: current(calorieOk, skipCheat: true),
      protein: current(proteinOk, skipCheat: true),
      bestLogging: best,
    );
  }
}

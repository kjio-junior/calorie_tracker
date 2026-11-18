import '../core/utils/formatters.dart';
import '../data/activity_repository.dart';
import '../data/food_repository.dart';
import '../data/weight_repository.dart';

/// Aggregated stats over a date range, used by the share card.
class PeriodStats {
  const PeriodStats({
    required this.startDate,
    required this.endDate,
    required this.daysLogged,
    required this.totalCalories,
    required this.totalBurned,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.avgCalorieTarget,
    this.startWeightKg,
    this.endWeightKg,
  });

  final DateTime startDate;
  final DateTime endDate;
  final int daysLogged;

  final double totalCalories;
  final double totalBurned;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final int avgCalorieTarget;

  final double? startWeightKg;
  final double? endWeightKg;

  int get days {
    final d = endDate.difference(startDate).inDays + 1;
    return d < 1 ? 1 : d;
  }

  int get avgCalories => daysLogged > 0
      ? (totalCalories / daysLogged).round()
      : 0;
  int get avgBurned => daysLogged > 0
      ? (totalBurned / daysLogged).round()
      : 0;
  double get avgProtein =>
      daysLogged > 0 ? totalProtein / daysLogged : 0;
  double get avgCarbs =>
      daysLogged > 0 ? totalCarbs / daysLogged : 0;
  double get avgFat =>
      daysLogged > 0 ? totalFat / daysLogged : 0;

  double? get weightChange =>
      startWeightKg != null && endWeightKg != null
          ? endWeightKg! - startWeightKg!
          : null;

  String get dateRangeLabel {
    if (startDate == endDate) return Fmt.shortDate(startDate);
    return '${Fmt.shortDate(startDate)} – ${Fmt.shortDate(endDate)}';
  }
}

/// Fetches aggregated nutrition + activity + weight data for arbitrary ranges.
class PeriodStatsService {
  PeriodStatsService._();

  static Future<PeriodStats> fetch({
    required DateTime start,
    required DateTime end,
  }) async {
    final foodRepo = FoodRepository();
    final activityRepo = ActivityRepository();
    final weightRepo = WeightRepository();

    // Food totals for the range.
    final dayTotals = await foodRepo.dayTotals();
    final startKey = Fmt.dateKey(start);
    final endKey = Fmt.dateKey(end);

    final inRange = dayTotals
        .where((d) => d.date.compareTo(startKey) >= 0 &&
            d.date.compareTo(endKey) <= 0)
        .toList();

    double totalCal = 0, totalPro = 0, totalCarb = 0, totalFat = 0;
    for (final d in inRange) {
      totalCal += d.calories;
      totalPro += d.protein;
      totalCarb += d.carbs;
      totalFat += d.fat;
    }

    // Activity totals (we have to sum day-by-day).
    double totalBurned = 0;
    var cursor = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    while (!cursor.isAfter(endDay)) {
      final key = Fmt.dateKey(cursor);
      final cardio = await activityRepo.cardioForDate(key);
      final sessions = await activityRepo.sessionsForDate(key);
      totalBurned += cardio.fold(0.0, (s, e) => s + (e.calories ?? 0));
      totalBurned += sessions.fold(0.0, (s, e) => s + (e.estCalories ?? 0));
      cursor = cursor.add(const Duration(days: 1));
    }

    // Weight at boundaries.
    final allWeights = await weightRepo.allWeights();
    double? wStart, wEnd;
    for (final w in allWeights) {
      final wKey = Fmt.dateKey(w.date);
      if (wKey.compareTo(startKey) >= 0 && wKey.compareTo(endKey) <= 0) {
        wStart ??= w.weightKg;
        wEnd = w.weightKg;
      }
    }

    // Average calorie target over the range.
    final allTargets = await weightRepo.allTargets();
    int targetSum = 0;
    int targetCount = 0;
    for (final t in allTargets) {
      if (t.date.compareTo(startKey) >= 0 &&
          t.date.compareTo(endKey) <= 0) {
        targetSum += t.calorieTarget;
        targetCount++;
      }
    }
    // Fall back to the most recent target before the range.
    if (targetCount == 0 && allTargets.isNotEmpty) {
      final fallback = allTargets.lastWhere(
        (t) => t.date.compareTo(startKey) <= 0,
        orElse: () => allTargets.last,
      );
      targetSum = fallback.calorieTarget;
      targetCount = 1;
    }

    return PeriodStats(
      startDate: start,
      endDate: end,
      daysLogged: inRange.length,
      totalCalories: totalCal,
      totalBurned: totalBurned,
      totalProtein: totalPro,
      totalCarbs: totalCarb,
      totalFat: totalFat,
      avgCalorieTarget:
          targetCount > 0 ? (targetSum / targetCount).round() : 2000,
      startWeightKg: wStart,
      endWeightKg: wEnd,
    );
  }
}

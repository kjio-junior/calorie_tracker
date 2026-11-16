import 'user_profile.dart';

class NutritionTargets {
  const NutritionTargets({
    required this.bmr,
    required this.tdee,
    required this.dailyDeficit,
    required this.rawCalorieTarget,
    required this.calorieTarget,
    required this.proteinTarget,
    required this.goalReached,
    required this.weeksToGoal,
    required this.warnings,
  });

  final double bmr;
  final double tdee;
  final int dailyDeficit;

  /// TDEE minus the deficit, before the safety floor is applied.
  final int rawCalorieTarget;

  /// The target actually used (never below the safety floor).
  final int calorieTarget;
  final int? proteinTarget;
  final bool goalReached;
  final double? weeksToGoal;
  final List<String> warnings;
}

class CalorieEngine {
  CalorieEngine._();

  /// Mifflin-St Jeor equation.
  static double bmr({
    required Sex sex,
    required double weightKg,
    required double heightCm,
    required int age,
  }) {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return sex == Sex.male ? base + 5 : base - 161;
  }

  /// Commonly cited minimums for unsupervised dieting.
  static int minCalories(Sex sex) => sex == Sex.male ? 1500 : 1200;

  static NutritionTargets compute(UserProfile p, double weightKg) {
    final bmr = CalorieEngine.bmr(
      sex: p.sex,
      weightKg: weightKg,
      heightCm: p.heightCm,
      age: p.age,
    );
    final tdee = bmr * p.activity.multiplier;
    final goalReached = weightKg <= p.goalWeightKg;
    final deficit = goalReached ? 0 : p.pace.dailyDeficitKcal;
    final raw = (tdee - deficit).round();
    final floor = minCalories(p.sex);
    final target = raw < floor ? floor : raw;

    final warnings = <String>[];
    if (raw < floor) {
      warnings.add(
        'This pace would put you at $raw kcal/day, below the $floor kcal '
        'generally considered safe without medical supervision. Your target '
        'is set to $floor kcal. A slower pace is recommended.',
      );
    }
    final heightM = p.heightCm / 100;
    final goalBmi = p.goalWeightKg / (heightM * heightM);
    if (goalBmi < 18.5) {
      warnings.add(
        'Your goal weight gives a BMI of ${goalBmi.toStringAsFixed(1)}, which '
        'is below the healthy range (18.5 and up). Consider a higher goal.',
      );
    }
    if (p.age < 18) {
      warnings.add(
        'Calorie deficits are not recommended under 18. Please talk to a '
        'doctor before dieting.',
      );
    }

    return NutritionTargets(
      bmr: bmr,
      tdee: tdee,
      dailyDeficit: deficit,
      rawCalorieTarget: raw,
      calorieTarget: target,
      proteinTarget:
          p.proteinMode ? (weightKg * p.proteinPerKg).round() : null,
      goalReached: goalReached,
      weeksToGoal:
          goalReached ? null : (weightKg - p.goalWeightKg) / p.pace.kgPerWeek,
      warnings: warnings,
    );
  }
}

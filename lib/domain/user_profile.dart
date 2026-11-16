import 'package:shared_preferences/shared_preferences.dart';

enum Sex { male, female }

enum ActivityLevel {
  sedentary(1.2, 'Sedentary', 'Desk job, little or no exercise'),
  light(1.375, 'Lightly active', 'Exercise 1-3 days per week'),
  moderate(1.55, 'Moderately active', 'Exercise 3-5 days per week'),
  veryActive(1.725, 'Very active', 'Hard exercise 6-7 days per week'),
  extra(1.9, 'Extra active', 'Physical job plus hard training');

  const ActivityLevel(this.multiplier, this.label, this.description);
  final double multiplier;
  final String label;
  final String description;
}

enum DeficitPace {
  mild(0.25, 'Mild'),
  moderate(0.5, 'Moderate'),
  aggressive(0.75, 'Aggressive');

  const DeficitPace(this.kgPerWeek, this.label);
  final double kgPerWeek;
  final String label;

  /// About 7,700 kcal per kg of body fat, spread over 7 days.
  int get dailyDeficitKcal => (kgPerWeek * 7700 / 7).round();
}

class UserProfile {
  const UserProfile({
    required this.name,
    required this.sex,
    required this.age,
    required this.heightCm,
    required this.startWeightKg,
    required this.goalWeightKg,
    required this.activity,
    required this.pace,
    required this.useLbs,
    required this.proteinMode,
    required this.proteinPerKg,
  });

  final String name;
  final Sex sex;
  final int age;
  final double heightCm;
  final double startWeightKg;
  final double goalWeightKg;
  final ActivityLevel activity;
  final DeficitPace pace;
  final bool useLbs;
  final bool proteinMode;
  final double proteinPerKg;

  UserProfile copyWith({
    String? name,
    Sex? sex,
    int? age,
    double? heightCm,
    double? startWeightKg,
    double? goalWeightKg,
    ActivityLevel? activity,
    DeficitPace? pace,
    bool? useLbs,
    bool? proteinMode,
    double? proteinPerKg,
  }) {
    return UserProfile(
      name: name ?? this.name,
      sex: sex ?? this.sex,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      startWeightKg: startWeightKg ?? this.startWeightKg,
      goalWeightKg: goalWeightKg ?? this.goalWeightKg,
      activity: activity ?? this.activity,
      pace: pace ?? this.pace,
      useLbs: useLbs ?? this.useLbs,
      proteinMode: proteinMode ?? this.proteinMode,
      proteinPerKg: proteinPerKg ?? this.proteinPerKg,
    );
  }

  static const _k = 'profile_';

  Future<void> save(SharedPreferences p) async {
    await p.setString('${_k}name', name);
    await p.setString('${_k}sex', sex.name);
    await p.setInt('${_k}age', age);
    await p.setDouble('${_k}height_cm', heightCm);
    await p.setDouble('${_k}start_kg', startWeightKg);
    await p.setDouble('${_k}goal_kg', goalWeightKg);
    await p.setString('${_k}activity', activity.name);
    await p.setString('${_k}pace', pace.name);
    await p.setBool('${_k}use_lbs', useLbs);
    await p.setBool('${_k}protein_mode', proteinMode);
    await p.setDouble('${_k}protein_per_kg', proteinPerKg);
  }

  /// Returns null until onboarding has been completed.
  static UserProfile? load(SharedPreferences p) {
    if (!p.containsKey('${_k}sex')) return null;
    return UserProfile(
      name: p.getString('${_k}name') ?? '',
      sex: Sex.values.byName(p.getString('${_k}sex') ?? 'male'),
      age: p.getInt('${_k}age') ?? 25,
      heightCm: p.getDouble('${_k}height_cm') ?? 170,
      startWeightKg: p.getDouble('${_k}start_kg') ?? 70,
      goalWeightKg: p.getDouble('${_k}goal_kg') ?? 65,
      activity: ActivityLevel.values
          .byName(p.getString('${_k}activity') ?? 'light'),
      pace: DeficitPace.values.byName(p.getString('${_k}pace') ?? 'moderate'),
      useLbs: p.getBool('${_k}use_lbs') ?? false,
      proteinMode: p.getBool('${_k}protein_mode') ?? false,
      proteinPerKg: p.getDouble('${_k}protein_per_kg') ?? 1.8,
    );
  }
}

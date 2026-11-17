import '../core/utils/formatters.dart';

const String kCoachSystemPrompt =
    'You are a supportive nutrition and fitness coach inside a personal '
    'calorie-tracking app. Write a short daily summary in plain text (no '
    'markdown, no bullet points, no emojis), at most 110 words. Cover '
    'calories versus the target, protein progress if the user tracks it, '
    'the weight trend, and activity. Then give one specific, practical tip. '
    'If the day is not finished, talk about what is left instead of judging '
    'the day. Be warm and encouraging, never shaming. Use only the numbers '
    'provided and do not invent data. You are not a doctor: give no medical '
    'advice, and if intake looks unsafely low, gently suggest eating more or '
    'talking to a professional.';

/// Everything the coach is told. The user's name, age and sex are not sent.
class CoachSnapshot {
  const CoachSnapshot({
    required this.now,
    required this.calorieTarget,
    required this.eatenKcal,
    required this.burnedKcal,
    required this.burnedAddsBack,
    required this.proteinGoal,
    required this.proteinEaten,
    required this.startKg,
    required this.currentKg,
    required this.goalKg,
    required this.weightChange14dKg,
    required this.useLbs,
    required this.paceKgPerWeek,
    required this.goalReached,
    required this.weeksToGoal,
    required this.cardioMinutes,
    required this.workoutSessions,
    required this.workoutSets,
    required this.loggingStreak,
    this.weekLoggedDays,
    this.weekAvgKcal,
    this.weekAvgProtein,
    this.isCheatDay = false,
  });

  final DateTime now;
  final int calorieTarget;
  final int eatenKcal;
  final int burnedKcal;
  final bool burnedAddsBack;
  final int? proteinGoal;
  final int proteinEaten;
  final double startKg;
  final double currentKg;
  final double goalKg;
  final double? weightChange14dKg;
  final bool useLbs;
  final double paceKgPerWeek;
  final bool goalReached;
  final double? weeksToGoal;
  final int cardioMinutes;
  final int workoutSessions;
  final int workoutSets;
  final int loggingStreak;
  final int? weekLoggedDays;
  final int? weekAvgKcal;
  final int? weekAvgProtein;
  final bool isCheatDay;

  CoachSnapshot withWeek({
    required int loggedDays,
    required int? avgKcal,
    required int? avgProtein,
  }) =>
      CoachSnapshot(
        now: now,
        calorieTarget: calorieTarget,
        eatenKcal: eatenKcal,
        burnedKcal: burnedKcal,
        burnedAddsBack: burnedAddsBack,
        proteinGoal: proteinGoal,
        proteinEaten: proteinEaten,
        startKg: startKg,
        currentKg: currentKg,
        goalKg: goalKg,
        weightChange14dKg: weightChange14dKg,
        useLbs: useLbs,
        paceKgPerWeek: paceKgPerWeek,
        goalReached: goalReached,
        weeksToGoal: weeksToGoal,
        cardioMinutes: cardioMinutes,
        workoutSessions: workoutSessions,
        workoutSets: workoutSets,
        loggingStreak: loggingStreak,
        weekLoggedDays: loggedDays,
        weekAvgKcal: avgKcal,
        weekAvgProtein: avgProtein,
        isCheatDay: isCheatDay,
      );

  String toPrompt() {
    String w(double kg) => Units.weight(kg, useLbs);
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final b = StringBuffer()
      ..writeln('Local time: $hh:$mm. ${now.hour < 21 ? 'The day is still in progress.' : 'The day is nearly over.'}')
      ..writeln(
        'Calorie target today: $calorieTarget kcal. Eaten so far: $eatenKcal kcal.',
      )
      ..writeln(
        'Calories burned by logged activity today: $burnedKcal kcal '
        '(${burnedAddsBack ? 'added to the food allowance' : 'not added to the food allowance'}).',
      );

    if (proteinGoal != null) {
      b.writeln('Protein goal: $proteinGoal g. Eaten so far: $proteinEaten g.');
    } else {
      b.writeln('The user does not track protein.');
    }

    b.writeln(
      'Weight: started at ${w(startKg)}, now ${w(currentKg)}, goal ${w(goalKg)}.',
    );
    if (weightChange14dKg != null) {
      final d = weightChange14dKg!;
      final sign = d > 0 ? '+' : (d < 0 ? '-' : '');
      b.writeln(
        'Change over the last 14 days: $sign${w(d.abs())}.',
      );
    } else {
      b.writeln('Not enough recent weigh-ins to show a 14-day trend.');
    }
    if (goalReached) {
      b.writeln('The goal weight has been reached; the target is now maintenance.');
    } else {
      b.writeln(
        'Chosen pace: $paceKgPerWeek kg per week'
        '${weeksToGoal == null ? '' : ', about ${weeksToGoal!.ceil()} weeks to goal'}.',
      );
    }

    b.writeln(
      'Activity today: $workoutSessions strength workout(s) ($workoutSets sets), '
      '$cardioMinutes minutes of cardio.',
    );
    if (weekLoggedDays != null) {
      b.writeln(
        'Previous 7 days: food logged on $weekLoggedDays day(s)'
        '${weekAvgKcal == null ? '' : ', average $weekAvgKcal kcal per logged day'}'
        '${weekAvgProtein == null ? '' : ', average $weekAvgProtein g protein'}.',
      );
    }
    b.writeln('Food logging streak: $loggingStreak day(s).');
    if (isCheatDay) {
      b.writeln('Today is a planned cheat day: do not criticise going over the target.');
    }
    b.writeln();
    b.write('Write the daily summary now.');
    return b.toString();
  }
}

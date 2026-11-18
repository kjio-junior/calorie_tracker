import '../core/utils/formatters.dart';

const String kCoachSystemPrompt =
    'You are a supportive nutrition and fitness coach inside a personal '
    'calorie-tracking app. Reply with exactly three lines of plain text (no '
    'markdown, no bullets, no emojis). Line 1: one short insight about today '
    '(max 20 words). Line 2: start with "Tip:" and give one specific, '
    'practical recommendation (max 20 words). Line 3: start with "More:" and '
    'add two or three sentences of extra detail covering calories, protein, '
    'the weight trend and activity (max 60 words). If the day is not '
    'finished, talk about what is left instead of judging the day. Be warm '
    'and encouraging, never shaming. Use only the numbers provided and do '
    'not invent data. You are not a doctor: give no medical advice, and if '
    'intake looks unsafely low, gently suggest eating more or talking to a '
    'professional.';

/// The coach answer split into a short insight, a tip and optional details.
/// Older, longer summaries are handled too: the first sentence becomes the
/// insight and the rest goes into the details.
class CoachParts {
  const CoachParts({required this.insight, this.tip, this.more});

  final String insight;
  final String? tip;
  final String? more;

  static CoachParts parse(String raw) {
    final lines = raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    String? tip;
    String? more;
    final others = <String>[];
    for (final l in lines) {
      final lower = l.toLowerCase();
      if (lower.startsWith('tip:')) {
        tip = l.substring(4).trim();
      } else if (lower.startsWith('more:')) {
        more = l.substring(5).trim();
      } else {
        others.add(l);
      }
    }
    if (others.isEmpty) {
      return CoachParts(insight: raw.trim(), tip: tip, more: more);
    }
    var insight = others.first;
    final extra = <String>[...others.skip(1)];
    // Old long paragraph: keep only the first sentence as the headline.
    if (tip == null && more == null && insight.length > 140) {
      final m = RegExp(r'^(.{20,}?[.!?])\s+(.*)$', dotAll: true)
          .firstMatch(insight);
      if (m != null) {
        insight = m.group(1)!;
        extra.insert(0, m.group(2)!);
      }
    }
    if (more != null) extra.add(more);
    return CoachParts(
      insight: insight,
      tip: tip,
      more: extra.isEmpty ? null : extra.join('\n'),
    );
  }
}

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

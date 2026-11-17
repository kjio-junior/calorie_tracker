import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_controller.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/meal_guess.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/offline_badge.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/weight_trend_chart.dart';
import '../../domain/food.dart';
import '../../domain/streaks.dart';
import '../../state/activity_controller.dart';
import '../../state/cheat_controller.dart';
import '../../state/connectivity_controller.dart';
import '../../state/food_controller.dart';
import '../../state/profile_controller.dart';
import '../../state/ui_prefs.dart';
import '../activity/cardio_screen.dart';
import '../activity/workout_screen.dart';
import '../food/add_food_screen.dart';
import '../weight/log_weight_sheet.dart';
import 'activity_cards.dart';
import 'ai_coach_card.dart';

const _overColor = Color(0xFFFF5C5C);
const _proteinColor = Color(0xFFFFB347);
const _cheatColor = Color(0xFFFFB020);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeController>().theme;
    final pc = context.watch<ProfileController>();
    final food = context.watch<FoodController>();
    final ui = context.watch<UiPrefs>();
    final activity = context.watch<ActivityController>();
    final cheat = context.watch<CheatController>();
    final online = context.watch<ConnectivityController>().isOnline;
    final profile = pc.profile!;
    final targets = pc.targets!;
    final text = Theme.of(context).textTheme;
    final muted = t.textColor.withValues(alpha: 0.7);
    final onAccent =
        ThemeData.estimateBrightnessForColor(t.accent) == Brightness.dark
            ? Colors.white
            : Colors.black87;

    final eaten = food.calories.round();
    final burned = activity.burnedToday.round();
    final isCheat = cheat.todayIsCheat;
    final addBack = ui.burnedAddsBack ? burned : 0;

    // Normal day: your target. Cheat day: maintenance, or no limit.
    final int? limit = isCheat
        ? (ui.cheatUnlimited ? null : targets.tdee.round())
        : targets.calorieTarget;
    final int? allowance = limit == null ? null : limit + addBack;
    final int? remaining = allowance == null ? null : allowance - eaten;
    final over = remaining != null && remaining < 0;
    final ringColor = isCheat ? _cheatColor : (over ? _overColor : t.accent);
    final ringProgress = allowance == null ? 1.0 : eaten / allowance;
    final proteinEaten = food.protein.round();
    final streak = food.streaks.logging;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddFoodScreen(initialMeal: guessMeal()),
          ),
        ),
        backgroundColor: t.accent,
        foregroundColor: onAccent,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log food'),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
          children: [
            // ---- header ----
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, ${profile.name}',
                        style: text.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Today, ${Fmt.shortDate(DateTime.now())}',
                        style: text.bodyMedium?.copyWith(color: muted),
                      ),
                    ],
                  ),
                ),
                if (!online) ...[
                  const OfflineBadge(),
                  const SizedBox(width: 8),
                ],
                if (streak > 0) _StreakChip(days: streak),
              ],
            ),
            const SizedBox(height: 16),

            // ---- hero: calories ----
            GlassCard(
              tint: ringColor.withValues(alpha: 0.10),
              borderColor: ringColor.withValues(alpha: 0.45),
              child: Row(
                children: [
                  ProgressRing(
                    progress: ringProgress,
                    color: ringColor,
                    size: 148,
                    strokeWidth: 15,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          allowance == null ? '$eaten' : '${remaining!.abs()}',
                          style: text.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          allowance == null
                              ? 'kcal eaten'
                              : (over ? 'kcal over' : 'kcal left'),
                          style: text.bodySmall?.copyWith(color: muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      children: [
                        _StatRow(
                          isCheat ? 'Cheat limit' : 'Target',
                          limit == null ? 'No limit' : '$limit kcal',
                          muted,
                        ),
                        _StatRow('Eaten', '$eaten kcal', muted),
                        _StatRow('Burned', '$burned kcal', muted),
                        if (burned > 0)
                          Text(
                            ui.burnedAddsBack
                                ? 'Added to allowance'
                                : 'Not added to allowance',
                            style: text.labelSmall?.copyWith(color: muted),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ---- cheat day banner ----
            if (isCheat) ...[
              const SizedBox(height: 12),
              GlassCard(
                tint: _cheatColor.withValues(alpha: 0.12),
                borderColor: _cheatColor.withValues(alpha: 0.55),
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: Row(
                  children: [
                    const Icon(Icons.celebration_rounded, color: _cheatColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cheat day is on',
                            style: text.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            ui.cheatUnlimited
                                ? 'No calorie limit today. Streaks pause. Back on track tomorrow.'
                                : 'Limit is your maintenance calories today. Streaks pause. Back on track tomorrow.',
                            style: text.bodySmall?.copyWith(color: muted),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => cheat.toggle(DateTime.now()),
                      child: const Text('Turn off'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // ---- quick actions ----
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _QuickTile(
                      icon: Icons.monitor_weight_rounded,
                      label: 'Log weight',
                      onTap: () => LogWeightSheet.show(context),
                    ),
                  ),
                  if (ui.workoutsEnabled) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _QuickTile(
                        icon: Icons.fitness_center_rounded,
                        label: 'Workout',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LogWorkoutScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (ui.cardioEnabled) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _QuickTile(
                        icon: Icons.directions_run_rounded,
                        label: 'Cardio',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LogCardioScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickTile(
                      icon: Icons.celebration_rounded,
                      label: isCheat ? 'Cheat day on' : 'Cheat day',
                      active: isCheat,
                      activeColor: _cheatColor,
                      onTap: () => cheat.toggle(DateTime.now()),
                    ),
                  ),
                ],
              ),
            ),

            // ---- protein ----
            if (profile.proteinMode && targets.proteinTarget != null) ...[
              const SizedBox(height: 12),
              GlassCard(
                child: Row(
                  children: [
                    ProgressRing(
                      progress: proteinEaten / targets.proteinTarget!,
                      color: _proteinColor,
                      size: 84,
                      strokeWidth: 9,
                      child: Text(
                        '${proteinEaten}g',
                        style: text.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Protein',
                            style: text.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Goal: ${targets.proteinTarget} g '
                            '(${profile.proteinPerKg.toStringAsFixed(1)} g/kg)',
                            style: text.bodySmall?.copyWith(color: muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (targets.warnings.isNotEmpty) ...[
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final w in targets.warnings)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFFFFB020),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(w, style: text.bodySmall)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],

            // ---- coach ----
            const SizedBox(height: 12),
            const AiCoachCard(),

            // ---- meals ----
            const _SectionTitle('Meals'),
            for (final meal in Meal.values) ...[
              const SizedBox(height: 10),
              _MealCard(meal: meal),
            ],

            // ---- activity ----
            if (ui.cardioEnabled || ui.workoutsEnabled)
              const _SectionTitle('Activity'),
            if (ui.cardioEnabled) ...[
              const SizedBox(height: 10),
              const CardioCard(),
            ],
            if (ui.workoutsEnabled) ...[
              const SizedBox(height: 10),
              const WorkoutCard(),
            ],

            // ---- progress ----
            const _SectionTitle('Progress'),
            if (ui.showStreaks) ...[
              const SizedBox(height: 10),
              _StreakCard(cheatDaysThisMonth: cheat.thisMonthCount),
            ],
            const SizedBox(height: 10),
            const _WeightCard(),
            const SizedBox(height: 10),
            const _TrendCard(),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeController>().theme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: t.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.activeColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeController>().theme;
    final text = Theme.of(context).textTheme;
    final color = active ? (activeColor ?? t.accent) : t.accent;

    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      onTap: onTap,
      tint: active ? color.withValues(alpha: 0.18) : null,
      borderColor: active ? color.withValues(alpha: 0.6) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.16),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0x33FF8A3D),
        border: Border.all(color: const Color(0x80FF8A3D)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            size: 18,
            color: Color(0xFFFF8A3D),
          ),
          const SizedBox(width: 4),
          Text(
            '$days',
            style: text.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _WeightCard extends StatelessWidget {
  const _WeightCard();

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeController>().theme;
    final pc = context.watch<ProfileController>();
    final profile = pc.profile!;
    final targets = pc.targets!;
    final text = Theme.of(context).textTheme;
    final muted = t.textColor.withValues(alpha: 0.7);
    final lbs = profile.useLbs;
    final current = pc.currentKg ?? pc.startKg;
    final lost = pc.totalLostKg;
    final toGo = math.max(0.0, current - profile.goalWeightKg);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weight',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _WeightStat('Start', Units.weight(pc.startKg, lbs), muted),
              Icon(Icons.arrow_forward_rounded, color: muted),
              _WeightStat('Current', Units.weight(current, lbs), muted),
              Icon(Icons.flag_rounded, color: muted),
              _WeightStat(
                'Goal',
                Units.weight(profile.goalWeightKg, lbs),
                muted,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            lost >= 0
                ? 'Lost ${Units.weight(lost, lbs)} so far'
                : 'Up ${Units.weight(-lost, lbs)} since you started',
            style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            targets.goalReached
                ? 'Goal reached. Your target is now maintenance.'
                : '${Units.weight(toGo, lbs)} to go '
                    '(~${targets.weeksToGoal!.ceil()} weeks at this pace)',
            style: text.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => LogWeightSheet.show(context),
              icon: const Icon(Icons.monitor_weight_rounded),
              label: const Text('Log weight'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard();

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeController>().theme;
    final pc = context.watch<ProfileController>();
    final text = Theme.of(context).textTheme;
    final muted = t.textColor.withValues(alpha: 0.7);
    final lbs = pc.profile!.useLbs;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weight trend',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (pc.weights.length < 2)
            Text(
              'Log at least two weigh-ins to see your trend.',
              style: text.bodySmall?.copyWith(color: muted),
            )
          else ...[
            WeightTrendChart(
              entries: pc.weights,
              useLbs: lbs,
              color: t.accent,
              textColor: t.textColor,
            ),
            const SizedBox(height: 6),
            Text(
              'Bold line = 7-entry moving average. Dots = weigh-ins.',
              style: text.bodySmall?.copyWith(color: muted),
            ),
          ],
        ],
      ),
    );
  }
}

IconData _mealIcon(Meal m) {
  switch (m) {
    case Meal.breakfast:
      return Icons.free_breakfast_rounded;
    case Meal.lunch:
      return Icons.lunch_dining_rounded;
    case Meal.dinner:
      return Icons.dinner_dining_rounded;
    case Meal.snack:
      return Icons.cookie_rounded;
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal});

  final Meal meal;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeController>().theme;
    final food = context.watch<FoodController>();
    final text = Theme.of(context).textTheme;
    final muted = t.textColor.withValues(alpha: 0.7);
    final entries = food.logsFor(meal);
    final kcal = entries.fold<double>(0, (s, e) => s + e.calories).round();

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 8, 6, 8),
      child: Column(
        children: [
          Row(
            children: [
              Icon(_mealIcon(meal), color: t.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  meal.label,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text('$kcal kcal', style: text.bodySmall?.copyWith(color: muted)),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddFoodScreen(initialMeal: meal),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          for (final e in entries)
            Dismissible(
              key: ValueKey('log_${e.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                color: Colors.red.withValues(alpha: 0.5),
                child: const Icon(Icons.delete_rounded),
              ),
              onDismissed: (_) {
                food.deleteLog(e);
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    SnackBar(
                      content: Text('Removed ${e.name}'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () => food.restoreLog(e),
                      ),
                    ),
                  );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 6, 10, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${e.servingDesc ?? ''}'
                            '${e.protein > 0 ? '  |  ${e.protein.toStringAsFixed(1)} g protein' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall?.copyWith(color: muted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${e.calories.round()} kcal',
                      style: text.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 2, 10, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Nothing logged yet. Tap Add to log ${meal.label.toLowerCase()}.',
                  style: text.bodySmall?.copyWith(color: muted),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({this.cheatDaysThisMonth = 0});

  final int cheatDaysThisMonth;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeController>().theme;
    final s = context.watch<FoodController>().streaks;
    final proteinMode = context.watch<ProfileController>().profile!.proteinMode;
    final text = Theme.of(context).textTheme;
    final muted = t.textColor.withValues(alpha: 0.7);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                size: 40,
                color: Color(0xFFFF8A3D),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${s.logging}-day logging streak',
                      style: text.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Best: ${s.bestLogging} days',
                      style: text.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StreakPill(
                icon: Icons.track_changes_rounded,
                label: '${s.calorie} days on target',
              ),
              if (proteinMode)
                _StreakPill(
                  icon: Icons.egg_alt_rounded,
                  label: '${s.protein} days protein goal',
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final m in StreakService.milestones)
                _Badge(days: m, earned: s.bestLogging >= m),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'On target = you ate 50-100% of your calorie target that day. '
            'Cheat days pause calorie and protein streaks.'
            '${cheatDaysThisMonth > 0 ? ' Cheat days this month: $cheatDaysThisMonth.' : ''}',
            style: text.bodySmall?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeController>().theme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: t.accent.withValues(alpha: 0.15),
        border: Border.all(color: t.accent.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: t.accent),
          const SizedBox(width: 6),
          Text(label, style: text.labelMedium),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.days, required this.earned});

  final int days;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeController>().theme;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: earned ? t.accent : Colors.transparent,
            border: Border.all(
              color: earned ? t.accent : t.textColor.withValues(alpha: 0.25),
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: earned
              ? Icon(
                  Icons.emoji_events_rounded,
                  size: 22,
                  color: t.isDark ? Colors.white : Colors.white,
                )
              : Text(
                  '$days',
                  style: text.labelLarge?.copyWith(
                    color: t.textColor.withValues(alpha: 0.5),
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          '$days d',
          style: text.labelSmall?.copyWith(
            color: t.textColor.withValues(alpha: earned ? 1 : 0.5),
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(this.label, this.value, this.muted);

  final String label;
  final String value;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: text.bodyMedium?.copyWith(color: muted)),
          Text(
            value,
            style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _WeightStat extends StatelessWidget {
  const _WeightStat(this.label, this.value, this.muted);

  final String label;
  final String value;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(label, style: text.labelSmall?.copyWith(color: muted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

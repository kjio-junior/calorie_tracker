import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_controller.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/offline_badge.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/weight_trend_chart.dart';
import '../../domain/food.dart';
import '../../domain/streaks.dart';
import '../../state/connectivity_controller.dart';
import '../../state/food_controller.dart';
import '../../state/profile_controller.dart';
import '../../state/ui_prefs.dart';
import '../../state/activity_controller.dart';
import '../food/add_food_screen.dart';
import '../history/history_screen.dart';
import 'activity_cards.dart';
import '../settings/settings_screen.dart';
import '../weight/log_weight_sheet.dart';

const _overColor = Color(0xFFFF5C5C);
const _proteinColor = Color(0xFFFFB347);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeController>().theme;
    final pc = context.watch<ProfileController>();
    final food = context.watch<FoodController>();
    final ui = context.watch<UiPrefs>();
    final activity = context.watch<ActivityController>();
    final online = context.watch<ConnectivityController>().isOnline;
    final profile = pc.profile!;
    final targets = pc.targets!;
    final text = Theme.of(context).textTheme;
    final muted = t.textColor.withValues(alpha: 0.7);
    final lbs = profile.useLbs;

    final eaten = food.calories.round();
    final burned = activity.burnedToday.round();
    // Remaining = target - eaten (+ burned, only if the setting is on).
    final allowance = targets.calorieTarget + (ui.burnedAddsBack ? burned : 0);
    final remaining = allowance - eaten;
    final over = remaining < 0;
    final proteinEaten = food.protein.round();

    final current = pc.currentKg ?? pc.startKg;
    final lost = pc.totalLostKg;
    final toGo = math.max(0.0, current - profile.goalWeightKg);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calorie Tracker'),
        actions: [
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
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
                      const SizedBox(height: 4),
                      Text(
                        'Today, ${Fmt.shortDate(DateTime.now())}',
                        style: text.bodyMedium?.copyWith(color: muted),
                      ),
                    ],
                  ),
                ),
                if (!online) const OfflineBadge(),
              ],
            ),
            const SizedBox(height: 20),

            // Calories
            GlassCard(
              child: Row(
                children: [
                  ProgressRing(
                    progress: eaten / allowance,
                    color: over ? _overColor : t.accent,
                    size: 132,
                    strokeWidth: 14,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${remaining.abs()}',
                          style: text.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          over ? 'kcal over' : 'kcal left',
                          style: text.bodySmall?.copyWith(color: muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: [
                        _StatRow('Target', '${targets.calorieTarget} kcal', muted),
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

            if (targets.warnings.isNotEmpty) ...[
              const SizedBox(height: 16),
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

            // Protein
            if (profile.proteinMode && targets.proteinTarget != null) ...[
              const SizedBox(height: 16),
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

            // Meals
            for (final meal in Meal.values) ...[
              const SizedBox(height: 16),
              _MealCard(meal: meal),
            ],
            if (ui.cardioEnabled) ...[
              const SizedBox(height: 16),
              const CardioCard(),
            ],
            if (ui.workoutsEnabled) ...[
              const SizedBox(height: 16),
              const WorkoutCard(),
            ],

            // Streaks
            if (ui.showStreaks) ...[
              const SizedBox(height: 16),
              const _StreakCard(),
            ],
            const SizedBox(height: 16),

            // Weight progress
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weight',
                    style: text.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
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
                    style: text.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
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
            ),
            const SizedBox(height: 16),

            // Trend chart
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weight trend',
                    style: text.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
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
            ),
          ],
        ),
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
              IconButton(
                tooltip: 'Add to ${meal.label}',
                icon: Icon(Icons.add_circle_rounded, color: t.accent),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddFoodScreen(initialMeal: meal),
                  ),
                ),
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
                  'Nothing logged yet',
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
  const _StreakCard();

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
            'On target = you ate 50-100% of your calorie target that day.',
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

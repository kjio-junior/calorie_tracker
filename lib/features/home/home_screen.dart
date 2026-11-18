import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_context.dart';
import '../../core/ui/app_button.dart';
import '../../core/ui/macro_bar.dart';
import '../../core/ui/section_header.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/meal_guess.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/offline_badge.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/weight_trend_chart.dart';
import '../../domain/food.dart';
import '../../domain/macro_goals.dart';
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final pc = context.watch<ProfileController>();
    final food = context.watch<FoodController>();
    final ui = context.watch<UiPrefs>();
    final activity = context.watch<ActivityController>();
    final cheat = context.watch<CheatController>();
    final online = context.watch<ConnectivityController>().isOnline;
    final profile = pc.profile!;
    final targets = pc.targets!;
    final text = Theme.of(context).textTheme;

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
    final ringColor = isCheat ? t.warning : (over ? t.danger : t.accent);
    final ringProgress = allowance == null ? 1.0 : eaten / allowance;
    final streak = food.streaks.logging;

    final current = pc.currentKg ?? pc.startKg;
    final goals = MacroGoals.compute(
      calorieTarget: targets.calorieTarget,
      weightKg: current,
      proteinTarget: targets.proteinTarget,
    );

    return Scaffold(
      bottomNavigationBar: const _LogFoodBar(),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          children: [
            // ---------------------------------------------------- header
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, ${profile.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Today, ${Fmt.shortDate(DateTime.now())}',
                          style: text.bodySmall
                              ?.copyWith(color: t.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (!online) ...[
                    const OfflineBadge(),
                    const SizedBox(width: 8),
                  ],
                  if (streak > 0) _StreakInline(days: streak),
                ],
              ),
            ),

            // ------------------------------------------- calorie tracker
            GlassCard(
              tint: isCheat
                  ? t.warning.withValues(alpha: 0.07)
                  : (over ? t.danger.withValues(alpha: 0.05) : null),
              borderColor: isCheat
                  ? t.warning.withValues(alpha: 0.5)
                  : (over ? t.danger.withValues(alpha: 0.45) : null),
              child: Row(
                children: [
                  ProgressRing(
                    progress: ringProgress,
                    color: ringColor,
                    size: 120,
                    strokeWidth: 12,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          allowance == null ? '$eaten' : '${remaining!.abs()}',
                          style: text.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          allowance == null
                              ? 'kcal eaten'
                              : (over ? 'kcal over' : 'kcal left'),
                          style: text.labelSmall
                              ?.copyWith(color: t.textSecondary),
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
                        ),
                        _StatRow('Eaten', '$eaten kcal'),
                        _StatRow('Burned', '$burned kcal'),
                        if (burned > 0)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              ui.burnedAddsBack
                                  ? 'Added to allowance'
                                  : 'Not added to allowance',
                              style: text.labelSmall
                                  ?.copyWith(color: t.textSecondary),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (isCheat) ...[
              const SizedBox(height: 10),
              GlassCard(
                tint: t.warning.withValues(alpha: 0.08),
                borderColor: t.warning.withValues(alpha: 0.5),
                padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                child: Row(
                  children: [
                    Icon(Icons.celebration_rounded, color: t.warning, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        ui.cheatUnlimited
                            ? 'Cheat day: no calorie limit. Streaks pause.'
                            : 'Cheat day: limit is your maintenance calories. Streaks pause.',
                        style: text.bodySmall,
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
            const SizedBox(height: 12),

            // --------------------------------------------- quick actions
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.monitor_weight_rounded,
                    label: 'Weight',
                    onTap: () => LogWeightSheet.show(context),
                  ),
                ),
                if (ui.workoutsEnabled) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickAction(
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
                    child: _QuickAction(
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
                  child: _QuickAction(
                    icon: Icons.celebration_rounded,
                    label: 'Cheat day',
                    active: isCheat,
                    onTap: () => cheat.toggle(DateTime.now()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ------------------------------------------------ nutrition
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Nutrition',
                          style: text.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        'Estimated goals',
                        style: text.labelSmall
                            ?.copyWith(color: t.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  MacroBar(
                    label: 'Protein',
                    value: food.protein,
                    goal: goals.protein,
                    color: t.protein,
                  ),
                  const SizedBox(height: 12),
                  MacroBar(
                    label: 'Carbohydrates',
                    value: food.carbs,
                    goal: goals.carbs,
                    color: t.carbs,
                  ),
                  const SizedBox(height: 12),
                  MacroBar(
                    label: 'Fat',
                    value: food.fat,
                    goal: goals.fat,
                    color: t.fat,
                  ),
                ],
              ),
            ),

            if (targets.warnings.isNotEmpty) ...[
              const SizedBox(height: 12),
              GlassCard(
                tint: t.warning.withValues(alpha: 0.06),
                borderColor: t.warning.withValues(alpha: 0.4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final w in targets.warnings)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: t.warning,
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

            // ---------------------------------------------------- coach
            const SizedBox(height: 12),
            const AiCoachCard(),

            // --------------------------------------------------- meals
            const SectionHeader('Meals'),
            for (final meal in Meal.values) ...[
              _MealCard(meal: meal),
              const SizedBox(height: 10),
            ],

            // ------------------------------------------------ activity
            if (ui.cardioEnabled || ui.workoutsEnabled)
              const SectionHeader('Activity', top: 14),
            if (ui.cardioEnabled) ...[
              const CardioCard(),
              const SizedBox(height: 10),
            ],
            if (ui.workoutsEnabled) ...[
              const WorkoutCard(),
              const SizedBox(height: 10),
            ],

            // ----------------------------------------------- progress
            const SectionHeader('Progress', top: 14),
            if (ui.showStreaks) ...[
              _StreakCard(cheatDaysThisMonth: cheat.thisMonthCount),
              const SizedBox(height: 10),
            ],
            const _WeightCard(),
            const SizedBox(height: 10),
            const _TrendCard(),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- small parts

/// Persistent bottom action: sits between the content and the navigation
/// bar, so it never covers anything.
class _LogFoodBar extends StatelessWidget {
  const _LogFoodBar();

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: t.background,
        border: Border(top: BorderSide(color: t.divider)),
      ),
      child: AppButton(
        label: 'Log food',
        icon: Icons.add_rounded,
        expanded: true,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddFoodScreen(initialMeal: guessMeal()),
          ),
        ),
      ),
    );
  }
}

class _StreakInline extends StatelessWidget {
  const _StreakInline({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded, size: 16, color: t.warning),
          const SizedBox(width: 4),
          Text(
            '$days',
            style: text.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: t.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: text.bodyMedium?.copyWith(color: t.textSecondary)),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final text = Theme.of(context).textTheme;
    final color = active ? t.warning : t.accent;

    return GlassCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      onTap: onTap,
      tint: active ? color.withValues(alpha: 0.10) : null,
      borderColor: active ? color.withValues(alpha: 0.6) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
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
    final t = context.appTheme;
    final food = context.watch<FoodController>();
    final text = Theme.of(context).textTheme;
    final entries = food.logsFor(meal);
    final kcal = entries.fold<double>(0, (s, e) => s + e.calories).round();

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: t.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_mealIcon(meal), size: 18, color: t.accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  meal.label,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (entries.isNotEmpty)
                Text(
                  '$kcal kcal',
                  style: text.bodySmall?.copyWith(color: t.textSecondary),
                ),
              AppButton(
                label: 'Add',
                icon: Icons.add_rounded,
                kind: AppButtonKind.text,
                dense: true,
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
                color: t.danger.withValues(alpha: 0.5),
                child: const Icon(Icons.delete_rounded, color: Colors.white),
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
                padding: const EdgeInsets.fromLTRB(0, 6, 8, 6),
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
                            [
                              if ((e.servingDesc ?? '').isNotEmpty)
                                e.servingDesc!,
                              if (e.protein + e.carbs + e.fat > 0)
                                'P ${e.protein.round()} | C ${e.carbs.round()} | F ${e.fat.round()}',
                            ].join('  |  '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall
                                ?.copyWith(color: t.textSecondary),
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
              padding: const EdgeInsets.fromLTRB(0, 0, 8, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Nothing logged yet',
                  style: text.bodySmall?.copyWith(color: t.textSecondary),
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
    final t = context.appTheme;
    final s = context.watch<FoodController>().streaks;
    final proteinMode = context.watch<ProfileController>().profile!.proteinMode;
    final text = Theme.of(context).textTheme;

    Widget pill(IconData icon, String label) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: t.accent.withValues(alpha: 0.12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: t.accent),
              const SizedBox(width: 6),
              Text(label, style: text.labelMedium),
            ],
          ),
        );

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                size: 32,
                color: t.warning,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${s.logging}-day logging streak',
                      style: text.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Best: ${s.bestLogging} days',
                      style: text.bodySmall?.copyWith(color: t.textSecondary),
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
              pill(Icons.track_changes_rounded, '${s.calorie} days on target'),
              if (proteinMode)
                pill(Icons.egg_alt_rounded, '${s.protein} days protein goal'),
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
            style: text.bodySmall?.copyWith(color: t.textSecondary),
          ),
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
    final t = context.appTheme;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: earned ? t.accent : Colors.transparent,
            border: Border.all(color: earned ? t.accent : t.border, width: 1.6),
          ),
          alignment: Alignment.center,
          child: earned
              ? Icon(Icons.emoji_events_rounded, size: 20, color: t.onAccent)
              : Text(
                  '$days',
                  style: text.labelLarge?.copyWith(color: t.textSecondary),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          '$days d',
          style: text.labelSmall?.copyWith(
            color: earned ? t.textPrimary : t.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _WeightCard extends StatelessWidget {
  const _WeightCard();

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final pc = context.watch<ProfileController>();
    final profile = pc.profile!;
    final targets = pc.targets!;
    final text = Theme.of(context).textTheme;
    final lbs = profile.useLbs;
    final current = pc.currentKg ?? pc.startKg;
    final lost = pc.totalLostKg;
    final toGo = math.max(0.0, current - profile.goalWeightKg);

    Widget stat(String label, String value) => Column(
          children: [
            Text(label, style: text.labelSmall?.copyWith(color: t.textSecondary)),
            const SizedBox(height: 2),
            Text(
              value,
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        );

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weight',
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              stat('Start', Units.weight(pc.startKg, lbs)),
              Icon(Icons.arrow_forward_rounded, color: t.textSecondary),
              stat('Current', Units.weight(current, lbs)),
              Icon(Icons.flag_rounded, color: t.textSecondary),
              stat('Goal', Units.weight(profile.goalWeightKg, lbs)),
            ],
          ),
          const SizedBox(height: 12),
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
            style: text.bodySmall?.copyWith(color: t.textSecondary),
          ),
          const SizedBox(height: 14),
          AppButton(
            label: 'Log weight',
            icon: Icons.monitor_weight_rounded,
            expanded: true,
            onPressed: () => LogWeightSheet.show(context),
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
    final t = context.appTheme;
    final pc = context.watch<ProfileController>();
    final text = Theme.of(context).textTheme;
    final lbs = pc.profile!.useLbs;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weight trend',
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (pc.weights.length < 2)
            Text(
              'Log at least two weigh-ins to see your trend.',
              style: text.bodySmall?.copyWith(color: t.textSecondary),
            )
          else ...[
            WeightTrendChart(
              entries: pc.weights,
              useLbs: lbs,
              color: t.accent,
              textColor: t.textPrimary,
            ),
            const SizedBox(height: 6),
            Text(
              'Bold line = 7-entry moving average. Dots = weigh-ins.',
              style: text.bodySmall?.copyWith(color: t.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_controller.dart';
import '../../core/utils/activity_icons.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/exercise_icons.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/month_calendar.dart';
import '../../data/weight_repository.dart';
import '../../domain/activity.dart';
import '../../domain/exercise_library.dart';
import '../../domain/food.dart';
import '../../core/utils/meal_guess.dart';
import '../../state/cheat_controller.dart';
import '../../state/history_controller.dart';
import '../food/add_food_screen.dart';
import '../../state/profile_controller.dart';
import '../../state/ui_prefs.dart';
import '../weight/log_weight_sheet.dart';
import 'edit_food_sheet.dart';

const _weekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

Widget _deleteBackground() => Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 16),
      color: Colors.red.withValues(alpha: 0.5),
      child: const Icon(Icons.delete_rounded),
    );

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final h = context.watch<HistoryController>();
    final ui = context.watch<UiPrefs>();
    final cheat = context.watch<CheatController>();
    final t = context.watch<ThemeController>().theme;
    final text = Theme.of(context).textTheme;
    final detail = h.detail;
    final d = h.selected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            tooltip: 'Jump to today',
            icon: const Icon(Icons.today_rounded),
            onPressed: h.goToToday,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            GlassCard(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
              child: MonthCalendar(
                month: h.month,
                selected: h.selected,
                marked: h.marked,
                cheatDates: cheat.days,
                onSelect: h.select,
                onMonthChanged: h.showMonth,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_weekdays[d.weekday - 1]}, ${Fmt.shortDate(d)}, ${d.year}',
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: t.textColor,
                    ),
                  ),
                ),
                FilterChip(
                  avatar: const Icon(Icons.celebration_rounded, size: 18),
                  label: const Text('Cheat day'),
                  selected: cheat.isCheat(Fmt.dateKey(d)),
                  onSelected: (_) => cheat.toggle(d),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (detail == null)
              const Center(child: CircularProgressIndicator())
            else ...[
              _SummaryCard(detail: detail),
              const SizedBox(height: 16),
              _FoodSection(detail: detail),
              if (ui.cardioEnabled || detail.cardio.isNotEmpty) ...[
                const SizedBox(height: 16),
                _CardioSection(detail: detail),
              ],
              if (ui.workoutsEnabled || detail.sessions.isNotEmpty) ...[
                const SizedBox(height: 16),
                _WorkoutSection(detail: detail),
              ],
              const SizedBox(height: 16),
              const _WeightSection(),
            ],
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- summary

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.detail});

  final DayDetail detail;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeController>().theme;
    final ui = context.watch<UiPrefs>();
    final text = Theme.of(context).textTheme;
    final muted = t.textColor.withValues(alpha: 0.7);

    final eaten = detail.calories.round();
    final burned = detail.burned.round();
    final target = detail.target?.calorieTarget;
    final proteinGoal = detail.target?.proteinTarget;
    final isCheat = context.watch<CheatController>().isCheat(detail.date);
    int? limit = target;
    if (isCheat && target != null) {
      limit = ui.cheatUnlimited ? null : detail.target!.tdee.round();
    }
    final allowance =
        limit == null ? null : limit + (ui.burnedAddsBack ? burned : 0);
    final remaining = allowance == null ? null : allowance - eaten;
    final over = remaining != null && remaining < 0;
    const overColor = Color(0xFFFF5C5C);

    Widget stat(String label, String value) => Expanded(
          child: Column(
            children: [
              Text(
                value,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(label, style: text.labelSmall?.copyWith(color: muted)),
            ],
          ),
        );

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCheat)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.celebration_rounded,
                    size: 18,
                    color: Color(0xFFFFB020),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    ui.cheatUnlimited
                        ? 'Cheat day: no calorie limit'
                        : 'Cheat day: maintenance limit',
                    style: text.labelLarge?.copyWith(
                      color: const Color(0xFFFFB020),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              stat('Eaten', '$eaten kcal'),
              stat('Target', target == null ? '-' : '$target kcal'),
              stat('Burned', '$burned kcal'),
            ],
          ),
          if (allowance != null) ...[
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: (eaten / allowance).clamp(0.0, 1.0).toDouble(),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              color: over ? overColor : t.accent,
              backgroundColor: t.accent.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 6),
            Text(
              over
                  ? '${-remaining} kcal over'
                  : '$remaining kcal remaining',
              style: text.bodySmall?.copyWith(
                color: over ? overColor : muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (proteinGoal != null) ...[
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: (detail.protein / proteinGoal).clamp(0.0, 1.0).toDouble(),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              color: const Color(0xFFFFB347),
              backgroundColor: const Color(0x26FFB347),
            ),
            const SizedBox(height: 6),
            Text(
              'Protein ${detail.protein.round()} / $proteinGoal g',
              style: text.bodySmall?.copyWith(color: muted),
            ),
          ],
          if (target == null) ...[
            const SizedBox(height: 10),
            Text(
              'No target was set yet on this day.',
              style: text.bodySmall?.copyWith(color: muted),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- food

class _FoodSection extends StatelessWidget {
  const _FoodSection({required this.detail});

  final DayDetail detail;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeController>().theme;
    final h = context.read<HistoryController>();
    final text = Theme.of(context).textTheme;
    final muted = t.textColor.withValues(alpha: 0.7);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Food',
                  style: text.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddFoodScreen(
                        initialMeal: guessMeal(),
                        date: h.selected,
                      ),
                    ),
                  );
                  if (context.mounted) h.refresh();
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add food'),
              ),
            ],
          ),
          if (detail.food.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No food logged.',
                style: text.bodySmall?.copyWith(color: muted),
              ),
            ),
          for (final meal in Meal.values)
            if (detail.food.any((e) => e.meal == meal)) ...[
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Text(
                  meal.label,
                  style: text.labelLarge?.copyWith(color: muted),
                ),
              ),
              for (final e in detail.food.where((e) => e.meal == meal))
                Dismissible(
                  key: ValueKey('hfood_${e.id}'),
                  direction: DismissDirection.endToStart,
                  background: _deleteBackground(),
                  onDismissed: (_) {
                    h.deleteFood(e);
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(
                        SnackBar(
                          content: Text('Removed ${e.name}'),
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () => h.restoreFood(e),
                          ),
                        ),
                      );
                  },
                  child: InkWell(
                    onTap: () async {
                      final updated = await EditFoodSheet.show(context, e);
                      if (updated != null) h.updateFood(updated);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
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
                                  style: text.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
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
                          const SizedBox(width: 6),
                          Icon(Icons.edit_rounded, size: 16, color: muted),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          if (detail.food.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Tap to edit, swipe left to delete.',
                style: text.labelSmall?.copyWith(color: muted),
              ),
            ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- cardio

class _CardioSection extends StatelessWidget {
  const _CardioSection({required this.detail});

  final DayDetail detail;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeController>().theme;
    final h = context.read<HistoryController>();
    final text = Theme.of(context).textTheme;
    final muted = t.textColor.withValues(alpha: 0.7);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cardio',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (detail.cardio.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No activity logged.',
                style: text.bodySmall?.copyWith(color: muted),
              ),
            ),
          for (final e in detail.cardio)
            Dismissible(
              key: ValueKey('hcardio_${e.id}'),
              direction: DismissDirection.endToStart,
              background: _deleteBackground(),
              onDismissed: (_) {
                h.deleteCardio(e);
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    SnackBar(
                      content: Text('Removed ${e.type.label}'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () => h.restoreCardio(e),
                      ),
                    ),
                  );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(cardioIcon(e.type), size: 22, color: muted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.type.label,
                            style: text.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${Fmt.amount(e.durationMin)} min'
                            '${e.distanceKm != null ? '  |  ${Fmt.amount(e.distanceKm!)} km' : ''}',
                            style: text.bodySmall?.copyWith(color: muted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${(e.calories ?? 0).round()} kcal',
                      style: text.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- workouts

class _WorkoutSection extends StatelessWidget {
  const _WorkoutSection({required this.detail});

  final DayDetail detail;

  String _setText(SessionExercise ex, bool lbs) {
    final timed = kExerciseLibrary.any((e) => e.id == ex.exerciseId && e.timed);
    return ex.sets.map((s) {
      if (timed) return '${s.reps}s';
      if (s.weightKg <= 0) return '${s.reps}';
      final w = double.parse(Units.fromKg(s.weightKg, lbs).toStringAsFixed(1));
      return '${Fmt.amount(w)} ${Units.unit(lbs)} x ${s.reps}';
    }).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeController>().theme;
    final h = context.read<HistoryController>();
    final lbs = context.watch<ProfileController>().profile!.useLbs;
    final text = Theme.of(context).textTheme;
    final muted = t.textColor.withValues(alpha: 0.7);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Strength',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (detail.sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No workout logged.',
                style: text.bodySmall?.copyWith(color: muted),
              ),
            ),
          for (final s in detail.sessions)
            Dismissible(
              key: ValueKey('hworkout_${s.id}'),
              direction: DismissDirection.endToStart,
              background: _deleteBackground(),
              onDismissed: (_) {
                h.deleteSession(s);
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    SnackBar(
                      content: Text('Removed ${s.title}'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () => h.restoreSession(s),
                      ),
                    ),
                  );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        for (final g in s.groups.take(3))
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: MuscleGroupIcon(group: g, size: 26),
                          ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            s.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (s.estCalories != null)
                          Text(
                            '${s.estCalories!.round()} kcal',
                            style: text.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    for (final ex in s.exercises)
                      Padding(
                        padding: const EdgeInsets.only(left: 2, top: 2),
                        child: Text(
                          '${ex.name}: ${_setText(ex, lbs)}',
                          style: text.bodySmall?.copyWith(color: muted),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- weight

class _WeightSection extends StatelessWidget {
  const _WeightSection();

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeController>().theme;
    final h = context.watch<HistoryController>();
    final pc = context.watch<ProfileController>();
    final text = Theme.of(context).textTheme;
    final muted = t.textColor.withValues(alpha: 0.7);
    final lbs = pc.profile!.useLbs;
    final key = Fmt.dateKey(h.selected);

    WeightEntry? entry;
    for (final w in pc.weights) {
      if (Fmt.dateKey(w.date) == key) entry = w;
    }
    final isToday = key == Fmt.dateKey(DateTime.now());

    Future<void> openSheet() async {
      await LogWeightSheet.show(context, date: h.selected);
      if (context.mounted) h.refresh();
    }

    Future<void> confirmDelete(WeightEntry e) async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Delete this weigh-in?'),
          content: const Text(
            'Your calorie and protein targets will be recalculated from your '
            'latest remaining weigh-in.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(c).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(c).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (ok != true || !context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final deleted = await pc.deleteWeight(e.id);
      if (!context.mounted) return;
      if (!deleted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Keep at least one weigh-in.')),
        );
      }
      h.refresh();
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weight',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (entry != null)
            Row(
              children: [
                Icon(Icons.monitor_weight_rounded, color: t.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    Units.weight(entry.weightKg, lbs),
                    style: text.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  tooltip: 'Edit weigh-in',
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: openSheet,
                ),
                IconButton(
                  tooltip: 'Delete weigh-in',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => confirmDelete(entry!),
                ),
              ],
            )
          else
            Text(
              'No weigh-in on this day.',
              style: text.bodySmall?.copyWith(color: muted),
            ),
          if (entry == null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: openSheet,
                icon: const Icon(Icons.add_rounded),
                label: Text(isToday ? 'Log weight' : 'Log weight for this day'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

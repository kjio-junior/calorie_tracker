import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_context.dart';
import '../../core/ui/app_button.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/macro_bar.dart';
import '../../core/ui/screen_title.dart';
import '../../core/utils/activity_icons.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/meal_guess.dart';
import '../../core/widgets/exercise_icons.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/month_calendar.dart';
import '../../data/weight_repository.dart';
import '../../domain/activity.dart';
import '../../domain/exercise_library.dart';
import '../../domain/food.dart';
import '../../domain/macro_goals.dart';
import '../../state/cheat_controller.dart';
import '../../state/history_controller.dart';
import '../../state/profile_controller.dart';
import '../../state/ui_prefs.dart';
import '../food/add_food_screen.dart';
import '../weight/log_weight_sheet.dart';
import 'edit_food_sheet.dart';

const _weekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

Widget _deleteBackground(BuildContext context) => Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 16),
      color: context.appTheme.danger.withValues(alpha: 0.5),
      child: const Icon(Icons.delete_rounded, color: Colors.white),
    );

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _showMonth = false;

  @override
  Widget build(BuildContext context) {
    final h = context.watch<HistoryController>();
    final ui = context.watch<UiPrefs>();
    final cheat = context.watch<CheatController>();
    final detail = h.detail;
    final d = h.selected;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayDiff = today.difference(d).inDays;
    final relative = dayDiff == 0
        ? 'Today'
        : dayDiff == 1
            ? 'Yesterday'
            : '$dayDiff days ago';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const ScreenTitle('History', subtitle: 'Review and edit any day'),

            // ---- date navigator (never clips: the date scales down) ----
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Previous day',
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () => h.select(d.subtract(const Duration(days: 1))),
                  ),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _showMonth = !_showMonth),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${Fmt.shortDate(d)}, ${d.year}',
                                maxLines: 1,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            Text(
                              '${_weekdays[d.weekday - 1]}  |  $relative',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: context.appTheme.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next day',
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: dayDiff <= 0
                        ? null
                        : () => h.select(d.add(const Duration(days: 1))),
                  ),
                  IconButton(
                    tooltip: _showMonth ? 'Hide calendar' : 'Show calendar',
                    icon: Icon(
                      _showMonth
                          ? Icons.expand_less_rounded
                          : Icons.calendar_month_rounded,
                    ),
                    onPressed: () => setState(() => _showMonth = !_showMonth),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ---- week strip or full month ----
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: _showMonth
                  ? GlassCard(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
                      child: MonthCalendar(
                        month: h.month,
                        selected: h.selected,
                        marked: h.marked,
                        cheatDates: cheat.days,
                        onSelect: (day) {
                          h.select(day);
                          setState(() => _showMonth = false);
                        },
                        onMonthChanged: h.showMonth,
                      ),
                    )
                  : _WeekStrip(
                      selected: d,
                      marked: h.marked,
                      cheatDates: cheat.days,
                      onSelect: h.select,
                    ),
            ),
            const SizedBox(height: 12),

            if (detail == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _SummaryCard(detail: detail, date: d),
              const SizedBox(height: 12),
              _FoodSection(detail: detail),
              if (ui.cardioEnabled || detail.cardio.isNotEmpty) ...[
                const SizedBox(height: 12),
                _CardioSection(detail: detail),
              ],
              if (ui.workoutsEnabled || detail.sessions.isNotEmpty) ...[
                const SizedBox(height: 12),
                _WorkoutSection(detail: detail),
              ],
              const SizedBox(height: 12),
              const _WeightSection(),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- week strip

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.selected,
    required this.marked,
    required this.cheatDates,
    required this.onSelect,
  });

  final DateTime selected;
  final Set<String> marked;
  final Set<String> cheatDates;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final text = Theme.of(context).textTheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Sunday-first week containing the selected day.
    final start = selected.subtract(Duration(days: selected.weekday % 7));
    const letters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Builder(
                builder: (context) {
                  final day = DateTime(start.year, start.month, start.day + i);
                  final key = Fmt.dateKey(day);
                  final isSelected = Fmt.dateKey(selected) == key;
                  final isFuture = day.isAfter(today);
                  final isToday = day == today;
                  final hasData = marked.contains(key);
                  final isCheat = cheatDates.contains(key);

                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: isFuture ? null : () => onSelect(day),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            letters[i],
                            style: text.labelSmall
                                ?.copyWith(color: t.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? t.accent : Colors.transparent,
                              border: isToday && !isSelected
                                  ? Border.all(color: t.accent, width: 1.5)
                                  : null,
                            ),
                            child: Text(
                              '${day.day}',
                              style: text.labelLarge?.copyWith(
                                fontWeight:
                                    isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected
                                    ? t.onAccent
                                    : (isFuture
                                        ? t.textSecondary.withValues(alpha: 0.4)
                                        : t.textPrimary),
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCheat
                                  ? t.warning
                                  : (hasData ? t.accent : Colors.transparent),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------- summary

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.detail, required this.date});

  final DayDetail detail;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final ui = context.watch<UiPrefs>();
    final cheat = context.watch<CheatController>();
    final text = Theme.of(context).textTheme;

    final eaten = detail.calories.round();
    final burned = detail.burned.round();
    final record = detail.target;
    final target = record?.calorieTarget;
    final isCheat = cheat.isCheat(detail.date);

    int? limit = target;
    if (isCheat && target != null) {
      limit = ui.cheatUnlimited ? null : record!.tdee.round();
    }
    final allowance =
        limit == null ? null : limit + (ui.burnedAddsBack ? burned : 0);
    final remaining = allowance == null ? null : allowance - eaten;
    final over = remaining != null && remaining < 0;

    Widget stat(String label, String value, {Color? color}) => Expanded(
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(label, style: text.labelSmall?.copyWith(color: t.textSecondary)),
            ],
          ),
        );

    final goals = record == null
        ? null
        : MacroGoals.compute(
            calorieTarget: record.calorieTarget,
            weightKg: record.weightKg,
            proteinTarget: record.proteinTarget,
          );

    return GlassCard(
      tint: isCheat ? t.warning.withValues(alpha: 0.06) : null,
      borderColor: isCheat ? t.warning.withValues(alpha: 0.5) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Daily summary',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              FilterChip(
                avatar: const Icon(Icons.celebration_rounded, size: 16),
                label: const Text('Cheat day'),
                selected: isCheat,
                visualDensity: VisualDensity.compact,
                onSelected: (_) => cheat.toggle(date),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              stat('Eaten', '$eaten'),
              stat('Target', limit == null && isCheat ? 'None' : (target == null ? '-' : '${limit ?? target}')),
              stat('Burned', '$burned'),
              stat(
                over ? 'Over' : 'Left',
                remaining == null ? '-' : '${remaining.abs()}',
                color: over ? t.danger : null,
              ),
            ],
          ),
          if (allowance != null) ...[
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween(
                begin: 0,
                end: (eaten / allowance).clamp(0.0, 1.0).toDouble(),
              ),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: v,
                  minHeight: 8,
                  color: over ? t.danger : (isCheat ? t.warning : t.accent),
                  backgroundColor: t.accent.withValues(alpha: 0.16),
                ),
              ),
            ),
          ],
          if (goals != null) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: MacroBar(
                    compact: true,
                    label: 'Protein',
                    value: detail.protein,
                    goal: goals.protein,
                    color: t.protein,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MacroBar(
                    compact: true,
                    label: 'Carbs',
                    value: detail.carbs,
                    goal: goals.carbs,
                    color: t.carbs,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MacroBar(
                    compact: true,
                    label: 'Fat',
                    value: detail.fat,
                    goal: goals.fat,
                    color: t.fat,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              'No target was set yet on this day.',
              style: text.bodySmall?.copyWith(color: t.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- section card

/// Shared shell for Food, Cardio, Strength and Weight so they all match.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.action,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final text = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: t.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------- food

class _FoodSection extends StatelessWidget {
  const _FoodSection({required this.detail});

  final DayDetail detail;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final h = context.read<HistoryController>();
    final text = Theme.of(context).textTheme;

    return _SectionCard(
      title: 'Food',
      icon: Icons.restaurant_rounded,
      action: AppButton(
        label: 'Add food',
        icon: Icons.add_rounded,
        kind: AppButtonKind.tonal,
        dense: true,
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
      ),
      child: detail.food.isEmpty
          ? const EmptyState(
              icon: Icons.restaurant_menu_rounded,
              message: 'No food logged for this day.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final meal in Meal.values)
                  if (detail.food.any((e) => e.meal == meal)) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 2),
                      child: Text(
                        meal.label,
                        style: text.labelLarge?.copyWith(
                          color: t.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    for (final e in detail.food.where((e) => e.meal == meal))
                      Dismissible(
                        key: ValueKey('hfood_${e.id}'),
                        direction: DismissDirection.endToStart,
                        background: _deleteBackground(context),
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
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.edit_rounded,
                                  size: 16,
                                  color: t.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                const SizedBox(height: 6),
                Text(
                  'Tap to edit, swipe left to delete.',
                  style: text.labelSmall?.copyWith(color: t.textSecondary),
                ),
              ],
            ),
    );
  }
}

// -------------------------------------------------------------------- cardio

class _CardioSection extends StatelessWidget {
  const _CardioSection({required this.detail});

  final DayDetail detail;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final h = context.read<HistoryController>();
    final text = Theme.of(context).textTheme;

    return _SectionCard(
      title: 'Cardio',
      icon: Icons.directions_run_rounded,
      child: detail.cardio.isEmpty
          ? const EmptyState(
              icon: Icons.directions_run_rounded,
              message: 'No activity logged for this day.',
            )
          : Column(
              children: [
                for (final e in detail.cardio)
                  Dismissible(
                    key: ValueKey('hcardio_${e.id}'),
                    direction: DismissDirection.endToStart,
                    background: _deleteBackground(context),
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
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: t.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(cardioIcon(e.type), size: 19, color: t.accent),
                          ),
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
                                  style: text.bodySmall
                                      ?.copyWith(color: t.textSecondary),
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

// ------------------------------------------------------------------ workouts

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
    final t = context.appTheme;
    final h = context.read<HistoryController>();
    final lbs = context.watch<ProfileController>().profile!.useLbs;
    final text = Theme.of(context).textTheme;

    return _SectionCard(
      title: 'Strength',
      icon: Icons.fitness_center_rounded,
      child: detail.sessions.isEmpty
          ? const EmptyState(
              icon: Icons.fitness_center_rounded,
              message: 'No workout logged for this day.',
            )
          : Column(
              children: [
                for (final s in detail.sessions)
                  Dismissible(
                    key: ValueKey('hworkout_${s.id}'),
                    direction: DismissDirection.endToStart,
                    background: _deleteBackground(context),
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
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              for (final g in s.groups.take(3))
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: MuscleGroupIcon(
                                    group: g,
                                    size: 30,
                                    badge: true,
                                  ),
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
                          for (final ex in s.exercises)
                            Padding(
                              padding: const EdgeInsets.only(left: 2, top: 3),
                              child: Text(
                                '${ex.name}: ${_setText(ex, lbs)}',
                                style: text.bodySmall
                                    ?.copyWith(color: t.textSecondary),
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

// -------------------------------------------------------------------- weight

class _WeightSection extends StatelessWidget {
  const _WeightSection();

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final h = context.watch<HistoryController>();
    final pc = context.watch<ProfileController>();
    final text = Theme.of(context).textTheme;
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
            AppButton(
              label: 'Delete',
              kind: AppButtonKind.destructive,
              onPressed: () => Navigator.of(c).pop(true),
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

    final current = entry;
    return _SectionCard(
      title: 'Weight',
      icon: Icons.monitor_weight_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (current != null)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Units.weight(current.weightKg, lbs),
                        style: text.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Weigh-in on ${Fmt.shortDate(current.date)}',
                        style: text.bodySmall?.copyWith(color: t.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Delete weigh-in',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => confirmDelete(current),
                ),
              ],
            )
          else
            const EmptyState(
              icon: Icons.scale_rounded,
              message: 'No weigh-in on this day.',
            ),
          const SizedBox(height: 12),
          AppButton(
            label: current == null
                ? (isToday ? 'Log weight' : 'Log weight for this day')
                : 'Update weight',
            icon: current == null ? Icons.add_rounded : Icons.edit_rounded,
            kind: current == null ? AppButtonKind.primary : AppButtonKind.secondary,
            expanded: true,
            onPressed: openSheet,
          ),
        ],
      ),
    );
  }
}

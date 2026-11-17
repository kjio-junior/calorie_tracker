import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_controller.dart';
import '../../core/utils/activity_icons.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/exercise_icons.dart';
import '../../core/widgets/glass_card.dart';
import '../../domain/activity.dart';
import '../../state/activity_controller.dart';
import '../../state/profile_controller.dart';
import '../activity/cardio_screen.dart';
import '../activity/workout_screen.dart';

Widget _deleteBackground() => Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 16),
      color: Colors.red.withValues(alpha: 0.5),
      child: const Icon(Icons.delete_rounded),
    );

class CardioCard extends StatelessWidget {
  const CardioCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeController>().theme;
    final activity = context.watch<ActivityController>();
    final text = Theme.of(context).textTheme;
    final muted = t.textColor.withValues(alpha: 0.7);
    final entries = activity.cardio;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 8, 6, 8),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.directions_run_rounded, color: t.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cardio',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${activity.cardioBurned.round()} kcal',
                style: text.bodySmall?.copyWith(color: muted),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LogCardioScreen()),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Log'),
              ),
            ],
          ),
          for (final e in entries)
            Dismissible(
              key: ValueKey('cardio_${e.id}'),
              direction: DismissDirection.endToStart,
              background: _deleteBackground(),
              onDismissed: (_) {
                activity.deleteCardio(e);
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    SnackBar(
                      content: Text('Removed ${e.type.label}'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () => activity.restoreCardio(e),
                      ),
                    ),
                  );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 6, 10, 6),
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
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 2, 10, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'No activity logged today',
                  style: text.bodySmall?.copyWith(color: muted),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class WorkoutCard extends StatelessWidget {
  const WorkoutCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeController>().theme;
    final activity = context.watch<ActivityController>();
    final lbs = context.watch<ProfileController>().profile!.useLbs;
    final text = Theme.of(context).textTheme;
    final muted = t.textColor.withValues(alpha: 0.7);
    final sessions = activity.sessions;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 8, 6, 8),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center_rounded, color: t.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Strength',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${activity.workoutBurned.round()} kcal',
                style: text.bodySmall?.copyWith(color: muted),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LogWorkoutScreen()),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Log'),
              ),
            ],
          ),
          for (final s in sessions)
            Dismissible(
              key: ValueKey('workout_${s.id}'),
              direction: DismissDirection.endToStart,
              background: _deleteBackground(),
              onDismissed: (_) {
                activity.deleteWorkout(s);
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    SnackBar(
                      content: Text('Removed ${s.title}'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () => activity.restoreWorkout(s),
                      ),
                    ),
                  );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 6, 10, 6),
                child: Row(
                  children: [
                    for (final g in s.groups.take(3))
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: MuscleGroupIcon(group: g, size: 28),
                      ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${s.exercises.length} exercises  |  ${s.totalSets} sets  |  '
                            '${Fmt.amount(double.parse(Units.fromKg(s.volumeKg, lbs).toStringAsFixed(0)))} ${Units.unit(lbs)} lifted',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall?.copyWith(color: muted),
                          ),
                        ],
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
              ),
            ),
          if (sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 2, 10, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'No workout logged today',
                  style: text.bodySmall?.copyWith(color: muted),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

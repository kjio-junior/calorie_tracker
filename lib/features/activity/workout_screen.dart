import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_controller.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/exercise_icons.dart';
import '../../core/widgets/glass_card.dart';
import '../../domain/activity.dart';
import '../../domain/met.dart';
import '../../state/activity_controller.dart';
import '../../state/profile_controller.dart';
import 'exercise_picker.dart';

class _SetDraft {
  _SetDraft({String weight = '', String reps = ''})
      : weight = TextEditingController(text: weight),
        reps = TextEditingController(text: reps);

  final TextEditingController weight;
  final TextEditingController reps;

  void dispose() {
    weight.dispose();
    reps.dispose();
  }
}

class _ExerciseDraft {
  _ExerciseDraft(this.exercise) {
    sets.add(_SetDraft());
  }

  final Exercise exercise;
  final List<_SetDraft> sets = [];
}

/// Lyfta-style logger: add exercises from the offline library, then log
/// sets, reps and weight. Optionally estimates calories from MET x weight.
class LogWorkoutScreen extends StatefulWidget {
  const LogWorkoutScreen({super.key});

  @override
  State<LogWorkoutScreen> createState() => _LogWorkoutScreenState();
}

class _LogWorkoutScreenState extends State<LogWorkoutScreen> {
  final _name = TextEditingController();
  final _duration = TextEditingController(text: '45');
  final _drafts = <_ExerciseDraft>[];

  // Controllers of removed rows are disposed with the screen, not at removal,
  // because the removed TextFields are still on screen for one more frame.
  final _trash = <_SetDraft>[];

  bool _estimate = true;
  Intensity _intensity = Intensity.moderate;

  @override
  void dispose() {
    _name.dispose();
    _duration.dispose();
    for (final d in _drafts) {
      for (final s in d.sets) {
        s.dispose();
      }
    }
    for (final s in _trash) {
      s.dispose();
    }
    super.dispose();
  }

  double get _weightKg {
    final pc = context.read<ProfileController>();
    return pc.currentKg ?? pc.startKg;
  }

  double? get _minutes {
    final v = double.tryParse(_duration.text.trim().replaceAll(',', '.'));
    return (v == null || v <= 0 || v > 1440) ? null : v;
  }

  double? get _estKcal {
    final m = _minutes;
    if (!_estimate || m == null) return null;
    return Met.kcal(met: _intensity.met, weightKg: _weightKg, minutes: m);
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _addExercise() async {
    final ex = await ExercisePicker.show(context);
    if (ex == null || !mounted) return;
    if (_drafts.any((d) => d.exercise.id == ex.id)) {
      _snack('${ex.name} is already in this workout.');
      return;
    }
    setState(() => _drafts.add(_ExerciseDraft(ex)));
  }

  void _addSet(_ExerciseDraft d) {
    final last = d.sets.last;
    setState(
      () => d.sets.add(_SetDraft(weight: last.weight.text, reps: last.reps.text)),
    );
  }

  void _removeSet(_ExerciseDraft d, _SetDraft s) {
    if (d.sets.length == 1) return;
    setState(() {
      d.sets.remove(s);
      _trash.add(s);
    });
  }

  void _removeExercise(_ExerciseDraft d) {
    setState(() {
      _drafts.remove(d);
      _trash.addAll(d.sets);
    });
  }

  Future<void> _save() async {
    final lbs = context.read<ProfileController>().profile!.useLbs;

    final exercises = <SessionExercise>[];
    for (final d in _drafts) {
      final sets = <WorkoutSet>[];
      for (final s in d.sets) {
        final reps = int.tryParse(s.reps.text.trim());
        if (reps == null || reps <= 0) continue;
        final w = double.tryParse(s.weight.text.trim().replaceAll(',', '.')) ?? 0;
        sets.add(
          WorkoutSet(reps: reps, weightKg: Units.toKg(w < 0 ? 0 : w, lbs)),
        );
      }
      if (sets.isNotEmpty) {
        exercises.add(
          SessionExercise(
            exerciseId: d.exercise.id,
            name: d.exercise.name,
            group: d.exercise.group,
            sets: sets,
          ),
        );
      }
    }
    if (exercises.isEmpty) {
      _snack('Add at least one exercise with a set that has reps.');
      return;
    }
    if (_estimate && _minutes == null) {
      _snack('Enter the workout duration to estimate calories.');
      return;
    }

    final name = _name.text.trim();
    final session = WorkoutSession(
      date: Fmt.dateKey(DateTime.now()),
      name: name.isEmpty ? null : name,
      durationMin: _minutes,
      intensity: _estimate ? _intensity : null,
      estCalories: _estKcal,
      exercises: exercises,
    );

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await context.read<ActivityController>().saveWorkout(session);
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Workout saved: ${session.totalSets} sets'
          '${session.estCalories == null ? '' : ', ~${session.estCalories!.round()} kcal'}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeController>().theme;
    final lbs = context.watch<ProfileController>().profile!.useLbs;
    final text = Theme.of(context).textTheme;
    final muted = t.textColor.withValues(alpha: 0.7);
    final est = _estKcal;

    return Scaffold(
      appBar: AppBar(title: const Text('Log workout')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Workout name (optional)',
                      hintText: 'e.g. Push day',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Estimate calories burned'),
                    subtitle: const Text('MET x your weight x duration'),
                    value: _estimate,
                    onChanged: (v) => setState(() => _estimate = v),
                  ),
                  if (_estimate) ...[
                    TextField(
                      controller: _duration,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Duration',
                        suffixText: 'min',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final i in Intensity.values)
                          ChoiceChip(
                            label: Text('${i.label} (MET ${i.met})'),
                            selected: _intensity == i,
                            onSelected: (_) => setState(() => _intensity = i),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      est == null
                          ? 'Enter a duration to see an estimate.'
                          : 'About ${est.round()} kcal. Rough estimate only.',
                      style: text.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                ],
              ),
            ),
            for (final d in _drafts) ...[
              const SizedBox(height: 16),
              _ExerciseCard(
                draft: d,
                lbs: lbs,
                onAddSet: () => _addSet(d),
                onRemoveSet: (s) => _removeSet(d, s),
                onRemoveExercise: () => _removeExercise(d),
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _addExercise,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add exercise'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text('Save workout'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.draft,
    required this.lbs,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onRemoveExercise,
  });

  final _ExerciseDraft draft;
  final bool lbs;
  final VoidCallback onAddSet;
  final void Function(_SetDraft) onRemoveSet;
  final VoidCallback onRemoveExercise;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeController>().theme;
    final text = Theme.of(context).textTheme;
    final muted = t.textColor.withValues(alpha: 0.7);
    final ex = draft.exercise;
    final repsLabel = ex.timed ? 'Seconds' : 'Reps';

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MuscleGroupIcon(group: ex.group, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ex.name,
                      style: text.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${ex.group.label} | ${ex.equipment.label}',
                      style: text.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
              EquipmentIcon(equipment: ex.equipment, size: 28),
              IconButton(
                tooltip: 'Remove exercise',
                icon: const Icon(Icons.close_rounded),
                onPressed: onRemoveExercise,
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < draft.sets.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 26,
                    child: Text(
                      '${i + 1}',
                      style: text.titleSmall?.copyWith(color: muted),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: draft.sets[i].weight,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'Weight (${Units.unit(lbs)})',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: draft.sets[i].reps,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: repsLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove set',
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    onPressed: draft.sets.length == 1
                        ? null
                        : () => onRemoveSet(draft.sets[i]),
                  ),
                ],
              ),
            ),
          TextButton.icon(
            onPressed: onAddSet,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add set'),
          ),
        ],
      ),
    );
  }
}

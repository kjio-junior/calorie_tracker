import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_controller.dart';
import '../../core/utils/activity_icons.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_card.dart';
import '../../domain/activity.dart';
import '../../domain/met.dart';
import '../../state/activity_controller.dart';
import '../../state/profile_controller.dart';

/// Manual entry that mirrors Strava's summary stats.
/// The cardio_logs table already has `source` and `external_id` columns, so
/// Strava OAuth sync can be added later by upserting rows with
/// source = 'strava' and the activity id, without changing the schema.
class LogCardioScreen extends StatefulWidget {
  const LogCardioScreen({super.key});

  @override
  State<LogCardioScreen> createState() => _LogCardioScreenState();
}

class _LogCardioScreenState extends State<LogCardioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _duration = TextEditingController();
  final _distance = TextEditingController();
  final _kcal = TextEditingController();
  CardioType _type = CardioType.run;

  @override
  void dispose() {
    _duration.dispose();
    _distance.dispose();
    _kcal.dispose();
    super.dispose();
  }

  double? _num(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  double get _weightKg {
    final pc = context.read<ProfileController>();
    return pc.currentKg ?? pc.startKg;
  }

  double? _estimate() {
    final minutes = _num(_duration);
    if (minutes == null || minutes <= 0) return null;
    return Met.cardioKcal(
      _type,
      minutes: minutes,
      weightKg: _weightKg,
      distanceKm: _num(_distance),
    );
  }

  void _fillEstimate() {
    final e = _estimate();
    if (e == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a duration first.')),
      );
      return;
    }
    setState(() => _kcal.text = e.round().toString());
  }

  String? _range(String? v, double min, double max, {bool required = false}) {
    if ((v ?? '').trim().isEmpty) return required ? 'Required' : null;
    final n = double.tryParse(v!.trim().replaceAll(',', '.'));
    if (n == null) return 'Enter a number';
    if (n < min || n > max) return 'Out of range';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final minutes = _num(_duration)!;
    final entered = _num(_kcal);
    final calories = entered ?? _estimate()!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await context.read<ActivityController>().addCardio(
          CardioEntry(
            date: Fmt.dateKey(DateTime.now()),
            type: _type,
            durationMin: minutes,
            distanceKm: _num(_distance),
            calories: calories,
          ),
        );
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${_type.label} logged: ${Fmt.amount(minutes)} min, '
          '${calories.round()} kcal'
          '${entered == null ? ' (estimated)' : ''}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeController>().theme;
    final text = Theme.of(context).textTheme;
    final muted = t.textColor.withValues(alpha: 0.7);
    const numeric = TextInputType.numberWithOptions(decimal: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Log activity')),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activity type',
                      style: text.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final type in CardioType.values)
                          ChoiceChip(
                            avatar: Icon(cardioIcon(type), size: 18),
                            label: Text(type.label),
                            selected: _type == type,
                            onSelected: (_) => setState(() => _type = type),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _duration,
                            keyboardType: numeric,
                            decoration: const InputDecoration(
                              labelText: 'Duration',
                              suffixText: 'min',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (v) =>
                                _range(v, 1, 1440, required: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _distance,
                            keyboardType: numeric,
                            decoration: const InputDecoration(
                              labelText: 'Distance',
                              suffixText: 'km',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (v) => _range(v, 0, 1000),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _kcal,
                      keyboardType: numeric,
                      decoration: const InputDecoration(
                        labelText: 'Calories burned',
                        suffixText: 'kcal',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => _range(v, 0, 10000),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Leave blank to use an estimate from your weight, '
                            'duration and distance.',
                            style: text.bodySmall?.copyWith(color: muted),
                          ),
                        ),
                        TextButton(
                          onPressed: _fillEstimate,
                          child: Text(
                            _estimate() == null
                                ? 'Estimate'
                                : 'Estimate (~${_estimate()!.round()})',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('Save activity'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

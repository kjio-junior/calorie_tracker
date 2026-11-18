import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_controller.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/select_tile.dart';
import '../../domain/calorie_engine.dart';
import '../../domain/user_profile.dart';
import '../../state/profile_controller.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _current = TextEditingController();
  final _goal = TextEditingController();
  final _height = TextEditingController();
  final _age = TextEditingController();

  Sex _sex = Sex.male;
  bool _lbs = false;
  ActivityLevel _activity = ActivityLevel.light;
  DeficitPace _pace = DeficitPace.moderate;
  bool _protein = false;
  double _perKg = 1.8;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _current.dispose();
    _goal.dispose();
    _height.dispose();
    _age.dispose();
    super.dispose();
  }

  double? _num(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  void _setUnits(bool lbs) {
    if (lbs == _lbs) return;
    for (final c in [_current, _goal]) {
      final v = _num(c);
      if (v != null) {
        c.text = Units.fromKg(Units.toKg(v, _lbs), lbs).toStringAsFixed(1);
      }
    }
    setState(() => _lbs = lbs);
  }

  /// Builds a profile from the form if all numbers are usable, else null.
  UserProfile? _draft() {
    final cur = _num(_current);
    final goal = _num(_goal);
    final h = _num(_height);
    final age = int.tryParse(_age.text.trim());
    if (cur == null || goal == null || h == null || age == null) return null;
    final curKg = Units.toKg(cur, _lbs);
    final goalKg = Units.toKg(goal, _lbs);
    if (curKg < 30 || curKg > 300 || goalKg < 30 || goalKg > 300) return null;
    if (h < 100 || h > 250 || age < 13 || age > 100) return null;
    return UserProfile(
      name: _name.text.trim(),
      sex: _sex,
      age: age,
      heightCm: h,
      startWeightKg: curKg,
      goalWeightKg: goalKg,
      activity: _activity,
      pace: _pace,
      useLbs: _lbs,
      proteinMode: _protein,
      proteinPerKg: _perKg,
    );
  }

  String? _weightValidator(String? v) {
    final n = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
    if (n == null) return 'Enter a number';
    final kg = Units.toKg(n, _lbs);
    if (kg < 30 || kg > 300) return 'Enter a realistic weight';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final draft = _draft();
    if (draft == null) return;
    setState(() => _saving = true);
    await context.read<ProfileController>().completeOnboarding(draft);
    // RootGate swaps to the dashboard once onboarding is saved.
  }

  InputDecoration _dec(String label, {String? suffix}) => InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
      );

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeController>().theme;
    final text = Theme.of(context).textTheme;
    final muted = t.textColor.withValues(alpha: 0.7);
    final unit = Units.unit(_lbs);
    final draft = _draft();
    final preview = draft == null
        ? null
        : CalorieEngine.compute(draft, draft.startWeightKg);

    Widget heading(String s) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            s,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Set up your plan')),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(
                'Welcome',
                style: text.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'A few details so I can calculate your daily targets. '
                'Everything stays on this phone.',
                style: text.bodyMedium?.copyWith(color: muted),
              ),
              const SizedBox(height: 20),

              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    heading('About you'),
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: _dec('Name'),
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? 'Enter your name'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    SegmentedButton<Sex>(
                      segments: const [
                        ButtonSegment(value: Sex.male, label: Text('Male')),
                        ButtonSegment(value: Sex.female, label: Text('Female')),
                      ],
                      selected: {_sex},
                      onSelectionChanged: (s) =>
                          setState(() => _sex = s.first),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _age,
                            keyboardType: TextInputType.number,
                            decoration: _dec('Age', suffix: 'yrs'),
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              final n = int.tryParse((v ?? '').trim());
                              if (n == null) return 'Enter your age';
                              if (n < 13 || n > 100) return '13 to 100';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _height,
                            keyboardType: const TextInputType
                                .numberWithOptions(decimal: true),
                            decoration: _dec('Height', suffix: 'cm'),
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              final n = double.tryParse(
                                (v ?? '').trim().replaceAll(',', '.'),
                              );
                              if (n == null) return 'Enter height';
                              if (n < 100 || n > 250) return '100 to 250';
                              return null;
                            },
                          ),
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
                    heading('Weight'),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('kg')),
                        ButtonSegment(value: true, label: Text('lb')),
                      ],
                      selected: {_lbs},
                      onSelectionChanged: (s) => _setUnits(s.first),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _current,
                            keyboardType: const TextInputType
                                .numberWithOptions(decimal: true),
                            decoration: _dec('Current', suffix: unit),
                            onChanged: (_) => setState(() {}),
                            validator: _weightValidator,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _goal,
                            keyboardType: const TextInputType
                                .numberWithOptions(decimal: true),
                            decoration: _dec('Goal', suffix: unit),
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              final base = _weightValidator(v);
                              if (base != null) return base;
                              final g = _num(_goal)!;
                              final c = _num(_current);
                              if (c != null && g >= c) {
                                return 'Must be below current';
                              }
                              return null;
                            },
                          ),
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
                    heading('Activity level'),
                    for (final a in ActivityLevel.values)
                      SelectTile(
                        title: a.label,
                        subtitle: a.description,
                        selected: _activity == a,
                        onTap: () => setState(() => _activity = a),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    heading('Deficit pace'),
                    for (final p in DeficitPace.values)
                      SelectTile(
                        title: '${p.label}: ${p.kgPerWeek} kg/week',
                        subtitle: 'About ${p.dailyDeficitKcal} kcal/day deficit',
                        selected: _pace == p,
                        onTap: () => setState(() => _pace = p),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Protein tracker',
                        style: text.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text(
                        'Daily protein goal based on your body weight',
                      ),
                      value: _protein,
                      onChanged: (v) => setState(() => _protein = v),
                    ),
                    if (_protein) ...[
                      Text(
                        '${_perKg.toStringAsFixed(1)} g per kg of body weight',
                        style: text.labelLarge?.copyWith(color: muted),
                      ),
                      Slider(
                        value: _perKg,
                        min: 1.6,
                        max: 2.2,
                        divisions: 6,
                        label: '${_perKg.toStringAsFixed(1)} g/kg',
                        onChanged: (v) => setState(() => _perKg = v),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    heading('Your plan'),
                    if (preview == null)
                      Text(
                        'Fill in the details above to see your daily target.',
                        style: text.bodyMedium?.copyWith(color: muted),
                      )
                    else ...[
                      _PreviewRow('BMR', '${preview.bmr.round()} kcal', muted),
                      _PreviewRow('TDEE', '${preview.tdee.round()} kcal', muted),
                      _PreviewRow(
                        'Daily target',
                        '${preview.calorieTarget} kcal',
                        muted,
                        bold: true,
                      ),
                      if (preview.proteinTarget != null)
                        _PreviewRow(
                          'Protein goal',
                          '${preview.proteinTarget} g',
                          muted,
                        ),
                      if (preview.weeksToGoal != null)
                        _PreviewRow(
                          'Estimated time to goal',
                          '~${preview.weeksToGoal!.ceil()} weeks',
                          muted,
                        ),
                      for (final w in preview.warnings)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: t.warning,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(w, style: text.bodySmall),
                              ),
                            ],
                          ),
                        ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      'Estimates only, not medical advice.',
                      style: text.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: Text(_saving ? 'Saving...' : 'Start tracking'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow(this.label, this.value, this.muted, {this.bold = false});

  final String label;
  final String value;
  final Color muted;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: text.bodyMedium?.copyWith(color: muted)),
          Text(
            value,
            style: text.bodyMedium?.copyWith(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/select_tile.dart';
import '../../domain/user_profile.dart';
import '../../state/profile_controller.dart';

/// Edit the details you entered during onboarding. Saving recalculates your
/// BMR, TDEE, calorie target and protein goal right away.
class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild the form when the weight unit changes so the goal field
    // shows the right unit.
    final lbs =
        context.select<ProfileController, bool>((c) => c.profile!.useLbs);
    return _ProfileForm(key: ValueKey(lbs));
  }
}

class _ProfileForm extends StatefulWidget {
  const _ProfileForm({super.key});

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _height;
  late final TextEditingController _age;
  late final TextEditingController _goal;
  late Sex _sex;
  late ActivityLevel _activity;
  late bool _lbs;

  @override
  void initState() {
    super.initState();
    final p = context.read<ProfileController>().profile!;
    _lbs = p.useLbs;
    _name = TextEditingController(text: p.name);
    _height = TextEditingController(text: Fmt.amount(p.heightCm));
    _age = TextEditingController(text: '${p.age}');
    _goal = TextEditingController(
      text: Units.fromKg(p.goalWeightKg, p.useLbs).toStringAsFixed(1),
    );
    _sex = p.sex;
    _activity = p.activity;
  }

  @override
  void dispose() {
    _name.dispose();
    _height.dispose();
    _age.dispose();
    _goal.dispose();
    super.dispose();
  }

  double? _num(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final pc = context.read<ProfileController>();
    final messenger = ScaffoldMessenger.of(context);
    await pc.updateProfile(
      pc.profile!.copyWith(
        name: _name.text.trim(),
        sex: _sex,
        age: int.parse(_age.text.trim()),
        heightCm: _num(_height)!,
        goalWeightKg: Units.toKg(_num(_goal)!, _lbs),
        activity: _activity,
      ),
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Profile saved. Daily target: ${pc.targets?.calorieTarget} kcal.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const numeric = TextInputType.numberWithOptions(decimal: true);

    return GlassCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Enter your name' : null,
            ),
            const SizedBox(height: 12),
            SegmentedButton<Sex>(
              segments: const [
                ButtonSegment(value: Sex.male, label: Text('Male')),
                ButtonSegment(value: Sex.female, label: Text('Female')),
              ],
              selected: {_sex},
              onSelectionChanged: (s) => setState(() => _sex = s.first),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _age,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      suffixText: 'yrs',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final n = int.tryParse((v ?? '').trim());
                      if (n == null || n < 13 || n > 100) return '13 to 100';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _height,
                    keyboardType: numeric,
                    decoration: const InputDecoration(
                      labelText: 'Height',
                      suffixText: 'cm',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final n = double.tryParse(
                        (v ?? '').trim().replaceAll(',', '.'),
                      );
                      if (n == null || n < 100 || n > 250) return '100 to 250';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _goal,
              keyboardType: numeric,
              decoration: InputDecoration(
                labelText: 'Goal weight',
                suffixText: Units.unit(_lbs),
                helperText:
                    'A goal at or below your current weight gives a '
                    'maintenance target.',
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                final n = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
                if (n == null) return 'Enter a number';
                final kg = Units.toKg(n, _lbs);
                if (kg < 30 || kg > 300) return 'Enter a realistic weight';
                return null;
              },
            ),
            const SizedBox(height: 14),
            Text('Activity level', style: text.labelLarge),
            const SizedBox(height: 8),
            for (final a in ActivityLevel.values)
              SelectTile(
                title: a.label,
                subtitle: a.description,
                selected: _activity == a,
                onTap: () => setState(() => _activity = a),
              ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Save profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

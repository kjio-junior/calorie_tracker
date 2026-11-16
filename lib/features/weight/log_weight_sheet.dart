import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_card.dart';
import '../../state/profile_controller.dart';

class LogWeightSheet extends StatefulWidget {
  const LogWeightSheet({super.key, this.date});

  /// The day to log for. Defaults to today.
  final DateTime? date;

  static Future<void> show(BuildContext context, {DateTime? date}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LogWeightSheet(date: date),
    );
  }

  @override
  State<LogWeightSheet> createState() => _LogWeightSheetState();
}

class _LogWeightSheetState extends State<LogWeightSheet> {
  late final TextEditingController _ctrl;
  late DateTime _date;
  String? _error;

  @override
  void initState() {
    super.initState();
    _date = widget.date ?? DateTime.now();
    final pc = context.read<ProfileController>();
    final lbs = pc.profile!.useLbs;
    final key = Fmt.dateKey(_date);
    double? onThatDay;
    for (final w in pc.weights) {
      if (Fmt.dateKey(w.date) == key) onThatDay = w.weightKg;
    }
    _ctrl = TextEditingController(
      text: Units.fromKg(onThatDay ?? pc.currentKg ?? pc.startKg, lbs)
          .toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final pc = context.read<ProfileController>();
    final lbs = pc.profile!.useLbs;
    final v = double.tryParse(_ctrl.text.trim().replaceAll(',', '.'));
    final kg = v == null ? null : Units.toKg(v, lbs);
    if (kg == null || kg < 30 || kg > 300) {
      setState(() => _error = 'Enter a realistic weight.');
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await pc.logWeight(kg, on: _date);
    final target = pc.targets?.calorieTarget;
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          target == null
              ? 'Weight saved.'
              : 'Weight saved. Daily target: $target kcal.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pc = context.watch<ProfileController>();
    final lbs = pc.profile!.useLbs;
    final text = Theme.of(context).textTheme;
    final key = Fmt.dateKey(_date);
    final isToday = key == Fmt.dateKey(DateTime.now());
    final replaces = pc.weights.any((w) => Fmt.dateKey(w.date) == key);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Log weight',
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _ctrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Weight',
                suffixText: Units.unit(lbs),
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: Text(isToday ? 'Today' : Fmt.shortDate(_date)),
            ),
            if (replaces)
              Text(
                'This replaces the weigh-in already saved for that day.',
                style: text.bodySmall,
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

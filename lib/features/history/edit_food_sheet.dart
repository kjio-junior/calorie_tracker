import 'package:flutter/material.dart';

import '../../core/theme/theme_context.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_card.dart';
import '../../domain/food.dart';

/// Edit a logged food: name, meal, calories, protein, carbs and fat.
class EditFoodSheet extends StatefulWidget {
  const EditFoodSheet({super.key, required this.entry});

  final FoodLogEntry entry;

  static Future<FoodLogEntry?> show(BuildContext context, FoodLogEntry entry) {
    return showModalBottomSheet<FoodLogEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditFoodSheet(entry: entry),
    );
  }

  @override
  State<EditFoodSheet> createState() => _EditFoodSheetState();
}

class _EditFoodSheetState extends State<EditFoodSheet> {
  late final TextEditingController _name;
  late final TextEditingController _kcal;
  late final TextEditingController _protein;
  late final TextEditingController _carbs;
  late final TextEditingController _fat;
  late Meal _meal;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _name = TextEditingController(text: e.name);
    _kcal = TextEditingController(text: e.calories.round().toString());
    _protein = TextEditingController(text: e.protein.toStringAsFixed(1));
    _carbs = TextEditingController(text: e.carbs.toStringAsFixed(1));
    _fat = TextEditingController(text: e.fat.toStringAsFixed(1));
    _meal = e.meal;
  }

  @override
  void dispose() {
    for (final c in [_name, _kcal, _protein, _carbs, _fat]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  double? _grams(TextEditingController c, double max) {
    if (c.text.trim().isEmpty) return 0;
    final v = _num(c);
    return (v == null || v < 0 || v > max) ? null : v;
  }

  void _scale(double factor) {
    setState(() {
      final k = _num(_kcal);
      if (k != null) _kcal.text = (k * factor).round().toString();
      for (final c in [_protein, _carbs, _fat]) {
        final v = _num(c);
        if (v != null) c.text = (v * factor).toStringAsFixed(1);
      }
    });
  }

  void _save() {
    final e = widget.entry;
    final name = _name.text.trim();
    final kcal = _num(_kcal);
    final protein = _grams(_protein, 1000);
    final carbs = _grams(_carbs, 1000);
    final fat = _grams(_fat, 1000);
    if (name.isEmpty) {
      setState(() => _error = 'Enter a name.');
      return;
    }
    if (kcal == null || kcal < 0 || kcal > 10000) {
      setState(() => _error = 'Calories must be between 0 and 10000.');
      return;
    }
    if (protein == null || carbs == null || fat == null) {
      setState(() => _error = 'Protein, carbs and fat must be 0 to 1000 g.');
      return;
    }
    final changed = (kcal - e.calories).abs() > 0.5 ||
        (protein - e.protein).abs() > 0.05 ||
        (carbs - e.carbs).abs() > 0.05 ||
        (fat - e.fat).abs() > 0.05;
    final desc = e.servingDesc;
    final newDesc = !changed
        ? desc
        : (desc == null || desc.isEmpty)
            ? '(edited)'
            : (desc.endsWith('(edited)') ? desc : '$desc (edited)');

    Navigator.of(context).pop(
      FoodLogEntry(
        id: e.id,
        date: e.date,
        meal: _meal,
        name: name,
        servingDesc: newDesc,
        quantity: e.quantity,
        calories: kcal,
        protein: protein,
        carbs: carbs,
        fat: fat,
        savedFoodId: e.savedFoodId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final text = Theme.of(context).textTheme;
    const numeric = TextInputType.numberWithOptions(decimal: true);

    Widget grams(TextEditingController c, String label) => Expanded(
          child: TextField(
            controller: c,
            keyboardType: numeric,
            decoration: InputDecoration(labelText: label, suffixText: 'g'),
          ),
        );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: GlassCard(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit entry',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (widget.entry.servingDesc != null)
                Text(
                  'Logged as ${widget.entry.servingDesc} on '
                  '${Fmt.shortDate(Fmt.parseKey(widget.entry.date))}',
                  style: text.bodySmall?.copyWith(color: t.textSecondary),
                ),
              const SizedBox(height: 14),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Food name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _kcal,
                keyboardType: numeric,
                decoration: const InputDecoration(
                  labelText: 'Calories',
                  suffixText: 'kcal',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  grams(_protein, 'Protein'),
                  const SizedBox(width: 8),
                  grams(_carbs, 'Carbs'),
                  const SizedBox(width: 8),
                  grams(_fat, 'Fat'),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Scale:', style: text.labelLarge),
                  ActionChip(label: const Text('x0.5'), onPressed: () => _scale(0.5)),
                  ActionChip(label: const Text('x1.5'), onPressed: () => _scale(1.5)),
                  ActionChip(label: const Text('x2'), onPressed: () => _scale(2)),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  for (final m in Meal.values)
                    ChoiceChip(
                      label: Text(m.label),
                      selected: _meal == m,
                      onSelected: (_) => setState(() => _meal = m),
                    ),
                ],
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _error!,
                    style: text.bodySmall?.copyWith(color: t.danger),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

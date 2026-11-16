import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_card.dart';
import '../../domain/food.dart';

/// Edit a logged food: name, meal, calories and protein.
class EditFoodSheet extends StatefulWidget {
  const EditFoodSheet({super.key, required this.entry});

  final FoodLogEntry entry;

  static Future<FoodLogEntry?> show(BuildContext context, FoodLogEntry entry) {
    return showModalBottomSheet<FoodLogEntry>(
      context: context,
      isScrollControlled: true,
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
  late Meal _meal;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _name = TextEditingController(text: e.name);
    _kcal = TextEditingController(text: e.calories.round().toString());
    _protein = TextEditingController(text: e.protein.toStringAsFixed(1));
    _meal = e.meal;
  }

  @override
  void dispose() {
    _name.dispose();
    _kcal.dispose();
    _protein.dispose();
    super.dispose();
  }

  double? _num(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  void _scale(double factor) {
    final k = _num(_kcal);
    final p = _num(_protein);
    setState(() {
      if (k != null) _kcal.text = (k * factor).round().toString();
      if (p != null) _protein.text = (p * factor).toStringAsFixed(1);
    });
  }

  void _save() {
    final e = widget.entry;
    final name = _name.text.trim();
    final kcal = _num(_kcal);
    final protein = _protein.text.trim().isEmpty ? 0.0 : _num(_protein);
    if (name.isEmpty) {
      setState(() => _error = 'Enter a name.');
      return;
    }
    if (kcal == null || kcal < 0 || kcal > 10000) {
      setState(() => _error = 'Calories must be between 0 and 10000.');
      return;
    }
    if (protein == null || protein < 0 || protein > 1000) {
      setState(() => _error = 'Protein must be between 0 and 1000 g.');
      return;
    }
    final changed =
        (kcal - e.calories).abs() > 0.5 || (protein - e.protein).abs() > 0.05;
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
        savedFoodId: e.savedFoodId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const numeric = TextInputType.numberWithOptions(decimal: true);

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
                  'Logged as ${widget.entry.servingDesc}'
                  ' on ${Fmt.shortDate(Fmt.parseKey(widget.entry.date))}',
                  style: text.bodySmall,
                ),
              const SizedBox(height: 14),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Food name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _kcal,
                      keyboardType: numeric,
                      decoration: const InputDecoration(
                        labelText: 'Calories',
                        suffixText: 'kcal',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _protein,
                      keyboardType: numeric,
                      decoration: const InputDecoration(
                        labelText: 'Protein',
                        suffixText: 'g',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 8),
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
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: text.bodySmall?.copyWith(
                      color: const Color(0xFFFF6B6B),
                    ),
                  ),
                ),
              const SizedBox(height: 14),
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

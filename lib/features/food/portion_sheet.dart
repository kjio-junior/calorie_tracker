import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/glass_card.dart';
import '../../domain/food.dart';
import '../../state/food_controller.dart';

/// Pick an amount (servings or grams) of a food and add it to a meal.
class PortionSheet extends StatefulWidget {
  const PortionSheet({super.key, required this.food, required this.meal});

  final Food food;
  final Meal meal;

  static Future<void> show(
    BuildContext context, {
    required Food food,
    required Meal meal,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PortionSheet(food: food, meal: meal),
    );
  }

  @override
  State<PortionSheet> createState() => _PortionSheetState();
}

class _PortionSheetState extends State<PortionSheet> {
  late PortionMode _mode;
  final _ctrl = TextEditingController();

  Food get _food => widget.food;

  @override
  void initState() {
    super.initState();
    _mode = _food.canServings ? PortionMode.servings : PortionMode.grams;
    _ctrl.text = _mode == PortionMode.servings ? '1' : '100';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Portion? get _portion {
    final v = double.tryParse(_ctrl.text.trim().replaceAll(',', '.'));
    if (v == null || v <= 0) return null;
    if (_mode == PortionMode.grams) {
      if (v > 5000 || !_food.canGrams) return null;
      return _food.byGrams(v);
    }
    if (v > 50 || !_food.canServings) return null;
    return _food.byServings(v);
  }

  void _setMode(PortionMode m) {
    if (m == _mode) return;
    setState(() {
      _mode = m;
      _ctrl.text = m == PortionMode.servings ? '1' : '100';
    });
  }

  Future<void> _add() async {
    final portion = _portion;
    if (portion == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final controller = context.read<FoodController>();
    await controller.addFood(
      food: _food,
      portion: portion,
      meal: widget.meal,
    );
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(content: Text('Added ${_food.name} to ${widget.meal.label}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final portion = _portion;
    final both = _food.canGrams && _food.canServings;

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
                _food.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (_food.brand != null)
                Text(_food.brand!, style: text.bodySmall),
              const SizedBox(height: 14),
              if (both) ...[
                SegmentedButton<PortionMode>(
                  segments: [
                    ButtonSegment(
                      value: PortionMode.servings,
                      label: Text(
                        'Servings',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const ButtonSegment(
                      value: PortionMode.grams,
                      label: Text('Grams'),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (s) => _setMode(s.first),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _ctrl,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _mode == PortionMode.grams
                      ? 'Amount'
                      : 'Number of servings',
                  suffixText: _mode == PortionMode.grams ? 'g' : 'x',
                  helperText: _mode == PortionMode.servings
                      ? '1 serving = ${_food.servingLabel}'
                      : null,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    portion == null
                        ? '-'
                        : '${portion.calories.round()} kcal',
                    style: text.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    portion == null
                        ? '-'
                        : '${portion.protein.toStringAsFixed(1)} g protein',
                    style: text.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: portion == null ? null : _add,
                  child: Text('Add to ${widget.meal.label}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

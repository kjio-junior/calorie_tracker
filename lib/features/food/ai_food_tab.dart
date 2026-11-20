import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_context.dart';
import '../../core/ui/app_button.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/offline_badge.dart';
import '../../data/ai_service.dart';
import '../../domain/ai_food.dart';
import '../../domain/food.dart';
import '../../state/ai_coach_controller.dart';
import '../../state/connectivity_controller.dart';
import '../../state/food_controller.dart';
import '../../state/nav_controller.dart';

/// Describe a food (and ideally its weight) and let the AI work out the
/// calories, protein, carbs and fat. The numbers stay editable, and the food
/// is saved to "My foods" so it can be reused offline.
class AiFoodTab extends StatefulWidget {
  const AiFoodTab({super.key, required this.meal, this.date});

  final Meal meal;
  final DateTime? date;

  @override
  State<AiFoodTab> createState() => _AiFoodTabState();
}

class _AiFoodTabState extends State<AiFoodTab>
    with AutomaticKeepAliveClientMixin {
  final _desc = TextEditingController();
  final _weight = TextEditingController();

  // Result fields (editable).
  final _name = TextEditingController();
  final _grams = TextEditingController();
  final _kcal = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();

  bool _loading = false;
  bool _adding = false;
  bool _save = true;
  AiFoodEstimate? _estimate;
  String? _error;
  String? _formError;

  // Nutrition per 100 g from the AI answer, so changing the weight rescales.
  double _k100 = 0, _p100 = 0, _c100 = 0, _f100 = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    for (final c in [_desc, _weight, _name, _grams, _kcal, _protein, _carbs, _fat]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _n(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _estimateFood() async {
    final description = _desc.text.trim();
    if (description.length < 2) {
      setState(() => _error = 'Describe the food first.');
      return;
    }
    double? weight;
    if (_weight.text.trim().isNotEmpty) {
      weight = _n(_weight);
      if (weight == null || weight < 1 || weight > 5000) {
        setState(() => _error = 'Weight must be between 1 and 5000 g.');
        return;
      }
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _estimate = null;
    });
    try {
      final e = await context
          .read<AiCoachController>()
          .estimateFood(description: description, weightG: weight);
      if (!mounted) return;
      _applyEstimate(e);
    } on AiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyEstimate(AiFoodEstimate e) {
    // The weight you typed is authoritative; otherwise use the AI's serving.
    final typed = _n(_weight);
    final w = (typed != null && typed > 0) ? typed : e.weightG;
    _k100 = e.calories * 100 / e.weightG;
    _p100 = e.proteinG * 100 / e.weightG;
    _c100 = e.carbsG * 100 / e.weightG;
    _f100 = e.fatG * 100 / e.weightG;
    setState(() {
      _estimate = e;
      _formError = null;
      _name.text = e.name;
      _grams.text = Fmt.amount(w);
      _rescaleNutrition(w);
    });
  }

  void _rescaleNutrition(double w) {
    _kcal.text = (_k100 * w / 100).round().toString();
    _protein.text = (_p100 * w / 100).toStringAsFixed(1);
    _carbs.text = (_c100 * w / 100).toStringAsFixed(1);
    _fat.text = (_f100 * w / 100).toStringAsFixed(1);
  }

  void _reset() {
    for (final c in [_desc, _weight, _name, _grams, _kcal, _protein, _carbs, _fat]) {
      c.clear();
    }
    _estimate = null;
    _error = null;
    _formError = null;
  }

  Future<void> _add() async {
    final name = _name.text.trim();
    final w = _n(_grams);
    final kcal = _n(_kcal);
    double? grams(TextEditingController c) {
      if (c.text.trim().isEmpty) return 0;
      final v = _n(c);
      return (v == null || v < 0 || v > 1000) ? null : v;
    }

    final protein = grams(_protein);
    final carbs = grams(_carbs);
    final fat = grams(_fat);

    String? problem;
    if (name.isEmpty) {
      problem = 'Enter a name.';
    } else if (w == null || w < 1 || w > 5000) {
      problem = 'Weight must be between 1 and 5000 g.';
    } else if (kcal == null || kcal < 0 || kcal > 5000) {
      problem = 'Calories must be between 0 and 5000.';
    } else if (protein == null || carbs == null || fat == null) {
      problem = 'Protein, carbs and fat must be 0 to 1000 g.';
    }
    if (problem != null) {
      setState(() => _formError = problem);
      return;
    }

    setState(() {
      _adding = true;
      _formError = null;
    });
    try {
      final weight = w!;
      final food = Food.create(
        name: name,
        brand: 'AI estimate',
        source: 'custom',
        servingG: weight,
        servingDesc: '${Fmt.amount(weight)} g',
        kcalPer100g: kcal! * 100 / weight,
        proteinPer100g: protein! * 100 / weight,
        carbsPer100g: carbs! * 100 / weight,
        fatPer100g: fat! * 100 / weight,
      );
      final portion = food.byGrams(weight);
      await context.read<FoodController>().addFood(
            food: food,
            portion: portion,
            meal: widget.meal,
            saveToFoods: _save,
            date: widget.date,
          );
      if (!mounted) return;
      _snack('Added $name to ${widget.meal.label}'
          '${_save ? ' and saved it to My foods' : ''}.');
      setState(_reset);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = context.appTheme;
    final text = Theme.of(context).textTheme;
    final ai = context.watch<AiCoachController>();
    final online = context.watch<ConnectivityController>().isOnline;
    const numeric = TextInputType.numberWithOptions(decimal: true);

    final canEstimate = online && ai.ready && !_loading;

    // Do the macros roughly add up to the calories?
    String? mismatch;
    final k = _n(_kcal), p = _n(_protein) ?? 0, c = _n(_carbs) ?? 0, f = _n(_fat) ?? 0;
    if (_estimate != null && k != null && k > 0) {
      final fromMacros = 4 * p + 4 * c + 9 * f;
      if ((k - fromMacros).abs() > math.max(60, k * 0.3)) {
        mismatch = 'Calories and macros do not quite add up (the macros '
            'suggest about ${fromMacros.round()} kcal). Please review.';
      }
    }

    Widget numberField(TextEditingController c, String label,
            {String? suffix, ValueChanged<String>? onChanged}) =>
        TextField(
          controller: c,
          keyboardType: numeric,
          onChanged: onChanged ?? (_) => setState(() {}),
          decoration: InputDecoration(labelText: label, suffixText: suffix),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: t.accent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Describe your food',
                      style: text.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (!online) const OfflineBadge(),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _desc,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'What did you eat?',
                  hintText: 'e.g. Chicken adobo with rice',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _weight,
                keyboardType: numeric,
                decoration: const InputDecoration(
                  labelText: 'Weight',
                  suffixText: 'g',
                  helperText:
                      'Optional but more accurate. Leave empty and the AI '
                      'assumes a typical serving.',
                  helperMaxLines: 3,
                ),
              ),
              const SizedBox(height: 14),
              if (!ai.ready)
                AppButton(
                  label: 'Add your free API key',
                  icon: Icons.key_rounded,
                  kind: AppButtonKind.secondary,
                  expanded: true,
                  onPressed: () {
                    final nav = context.read<NavController>();
                    Navigator.of(context).pop();
                    nav.go(2);
                  },
                )
              else
                AppButton(
                  label: online ? 'Estimate with AI' : 'Offline',
                  icon: Icons.auto_awesome_rounded,
                  expanded: true,
                  onPressed: canEstimate ? _estimateFood : null,
                ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: LinearProgressIndicator(),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _error!,
                    style: text.bodySmall?.copyWith(color: t.danger),
                  ),
                ),
            ],
          ),
        ),
        if (_estimate != null) ...[
          const SizedBox(height: 12),
          GlassCard(
            borderColor: t.accent.withValues(alpha: 0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI estimate',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (_estimate!.note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _estimate!.note,
                    style: text.bodySmall?.copyWith(color: t.textSecondary),
                  ),
                ],
                const SizedBox(height: 14),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Food name'),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: numberField(
                        _grams,
                        'Weight',
                        suffix: 'g',
                        onChanged: (v) {
                          final w = _n(_grams);
                          setState(() {
                            if (w != null && w > 0 && w <= 5000) {
                              _rescaleNutrition(w);
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: numberField(_kcal, 'Calories', suffix: 'kcal')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: numberField(_protein, 'Protein', suffix: 'g')),
                    const SizedBox(width: 8),
                    Expanded(child: numberField(_carbs, 'Carbs', suffix: 'g')),
                    const SizedBox(width: 8),
                    Expanded(child: numberField(_fat, 'Fat', suffix: 'g')),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Changing the weight rescales the numbers. You can edit any '
                  'value. AI estimates can be off, so check them first.',
                  style: text.labelSmall?.copyWith(color: t.textSecondary),
                ),
                if (mismatch != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      mismatch,
                      style: text.bodySmall?.copyWith(color: t.warning),
                    ),
                  ),
                if (_formError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _formError!,
                      style: text.bodySmall?.copyWith(color: t.danger),
                    ),
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Keep it saved'),
                  subtitle: const Text('Reuse it from My foods, even offline'),
                  value: _save,
                  onChanged: (v) => setState(() => _save = v),
                ),
                const SizedBox(height: 4),
                AppButton(
                  label: 'Add to ${widget.meal.label}',
                  icon: Icons.add_rounded,
                  expanded: true,
                  onPressed: _adding ? null : _add,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

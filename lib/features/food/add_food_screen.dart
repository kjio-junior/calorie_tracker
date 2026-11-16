import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_controller.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/offline_badge.dart';
import '../../data/open_food_facts_service.dart';
import '../../domain/food.dart';
import '../../state/connectivity_controller.dart';
import '../../state/food_controller.dart';
import 'portion_sheet.dart';

InputDecoration _dec(String label, {String? suffix, String? hint}) =>
    InputDecoration(
      labelText: label,
      suffixText: suffix,
      hintText: hint,
      border: const OutlineInputBorder(),
    );

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({super.key, required this.initialMeal});

  final Meal initialMeal;

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  late Meal _meal = widget.initialMeal;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add food'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Search'),
              Tab(text: 'Saved'),
              Tab(text: 'Manual'),
            ],
          ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    for (final m in Meal.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(m.label),
                          selected: _meal == m,
                          onSelected: (_) => setState(() => _meal = m),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _SearchTab(meal: _meal),
                    _SavedTab(meal: _meal),
                    _ManualTab(meal: _meal),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lightweight list row (no blur, so long lists stay smooth).
class _FoodTile extends StatelessWidget {
  const _FoodTile({required this.food, required this.onTap});

  final Food food;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeController>().theme;
    final text = Theme.of(context).textTheme;
    final muted = t.textColor.withValues(alpha: 0.7);

    final String nutrition;
    if (food.kcalPer100g != null) {
      final p = food.proteinPer100g;
      nutrition = '${food.kcalPer100g!.round()} kcal'
          '${p == null ? '' : ' | ${Fmt.amount(double.parse(p.toStringAsFixed(1)))} g protein'}'
          ' per 100 g';
    } else {
      final p = food.proteinPerServing ?? 0;
      nutrition = '${food.kcalPerServing!.round()} kcal'
          ' | ${Fmt.amount(double.parse(p.toStringAsFixed(1)))} g protein'
          ' per ${food.servingLabel}';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: t.glassFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: t.glassBorder),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (food.brand != null)
                        Text(
                          food.brand!,
                          style: text.bodySmall?.copyWith(color: muted),
                        ),
                      Text(
                        nutrition,
                        style: text.bodySmall?.copyWith(color: muted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.add_circle_outline_rounded, color: t.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Search

class _SearchTab extends StatefulWidget {
  const _SearchTab({required this.meal});

  final Meal meal;

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab>
    with AutomaticKeepAliveClientMixin {
  final _ctrl = TextEditingController();
  bool _loading = false;
  bool _searched = false;
  String? _error;
  List<Food> _results = const [];

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _ctrl.text.trim();
    if (q.length < 2) {
      setState(() => _error = 'Type at least 2 characters.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await context.read<OpenFoodFactsService>().search(q);
      if (!mounted) return;
      setState(() {
        _results = r;
        _searched = true;
      });
    } on FoodSearchException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final online = context.watch<ConnectivityController>().isOnline;
    final t = context.watch<ThemeController>().theme;
    final text = Theme.of(context).textTheme;
    final muted = t.textColor.withValues(alpha: 0.7);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          if (!online) ...[
            GlassCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const OfflineBadge(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Online search needs internet. Use Saved or Manual.',
                      style: text.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _ctrl,
            enabled: online && !_loading,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              labelText: 'Search Open Food Facts',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: 'Search',
                icon: const Icon(Icons.search_rounded),
                onPressed: (online && !_loading) ? _search : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: text.bodyMedium?.copyWith(color: const Color(0xFFFF6B6B)),
              ),
            ),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Text(
                      _searched
                          ? 'No results. Try different words or add it manually.'
                          : 'Search for a food to see calories and protein.',
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(color: muted),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: _results.length,
                    itemBuilder: (context, i) {
                      final f = _results[i];
                      return _FoodTile(
                        food: f,
                        onTap: () => PortionSheet.show(
                          context,
                          food: f,
                          meal: widget.meal,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- Saved

class _SavedTab extends StatefulWidget {
  const _SavedTab({required this.meal});

  final Meal meal;

  @override
  State<_SavedTab> createState() => _SavedTabState();
}

class _SavedTabState extends State<_SavedTab> {
  final _ctrl = TextEditingController();
  List<Food> _foods = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final foods =
        await context.read<FoodController>().savedFoods(query: _ctrl.text);
    if (!mounted) return;
    setState(() {
      _foods = foods;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeController>().theme;
    final text = Theme.of(context).textTheme;
    final muted = t.textColor.withValues(alpha: 0.7);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          TextField(
            controller: _ctrl,
            onChanged: (_) => _load(),
            decoration: const InputDecoration(
              labelText: 'Filter recent and saved foods',
              prefixIcon: Icon(Icons.filter_list_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: (_loaded && _foods.isEmpty)
                ? Center(
                    child: Text(
                      'Nothing saved yet. Foods you log are kept here for '
                      'offline use.',
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(color: muted),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: _foods.length,
                    itemBuilder: (context, i) {
                      final f = _foods[i];
                      return Dismissible(
                        key: ValueKey('saved_${f.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_rounded),
                        ),
                        onDismissed: (_) {
                          setState(
                            () => _foods.removeWhere((x) => x.id == f.id),
                          );
                          context.read<FoodController>().deleteSavedFood(f.id!);
                        },
                        child: _FoodTile(
                          food: f,
                          onTap: () async {
                            await PortionSheet.show(
                              context,
                              food: f,
                              meal: widget.meal,
                            );
                            if (mounted) _load();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Manual

class _ManualTab extends StatefulWidget {
  const _ManualTab({required this.meal});

  final Meal meal;

  @override
  State<_ManualTab> createState() => _ManualTabState();
}

class _ManualTabState extends State<_ManualTab> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _grams = TextEditingController();
  final _kcal = TextEditingController();
  final _protein = TextEditingController();
  final _servings = TextEditingController(text: '1');
  bool _save = true;

  @override
  void dispose() {
    for (final c in [_name, _desc, _grams, _kcal, _protein, _servings]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  String? _required(String? v, {double min = 0, double max = 100000}) {
    final n = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
    if (n == null) return 'Enter a number';
    if (n < min || n > max) return 'Out of range';
    return null;
  }

  String? _optional(String? v, {double min = 0, double max = 100000}) {
    if ((v ?? '').trim().isEmpty) return null;
    return _required(v, min: min, max: max);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final desc = _desc.text.trim();
    final food = Food.create(
      name: _name.text.trim(),
      source: 'custom',
      servingG: _num(_grams),
      servingDesc: desc.isEmpty ? null : desc,
      kcalPerServing: _num(_kcal)!,
      proteinPerServing: _num(_protein) ?? 0,
    );
    final portion = food.byServings(_num(_servings)!);
    final messenger = ScaffoldMessenger.of(context);
    await context.read<FoodController>().addFood(
          food: food,
          portion: portion,
          meal: widget.meal,
          saveToFoods: _save,
        );
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text('Added ${food.name} to ${widget.meal.label}')),
    );
    _formKey.currentState!.reset();
    for (final c in [_name, _desc, _grams, _kcal, _protein]) {
      c.clear();
    }
    _servings.text = '1';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final numeric = const TextInputType.numberWithOptions(decimal: true);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          GlassCard(
            child: Column(
              children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _dec('Food name'),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Enter a name' : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _desc,
                        decoration: _dec('Serving', hint: 'e.g. 1 bowl'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _grams,
                        keyboardType: numeric,
                        decoration: _dec('Weight', suffix: 'g'),
                        validator: (v) => _optional(v, min: 1, max: 5000),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _kcal,
                        keyboardType: numeric,
                        decoration: _dec('Calories', suffix: 'kcal'),
                        validator: (v) => _required(v, min: 0, max: 5000),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _protein,
                        keyboardType: numeric,
                        decoration: _dec('Protein', suffix: 'g'),
                        validator: (v) => _optional(v, min: 0, max: 500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Calories and protein are for one serving.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _servings,
                  keyboardType: numeric,
                  decoration: _dec('Servings eaten', suffix: 'x'),
                  validator: (v) => _required(v, min: 0.1, max: 50),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Save to my foods'),
                  subtitle: const Text('Reuse it offline later'),
                  value: _save,
                  onChanged: (v) => setState(() => _save = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: Text('Add to ${widget.meal.label}'),
          ),
        ],
      ),
    );
  }
}

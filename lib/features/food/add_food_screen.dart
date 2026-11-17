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
  const AddFoodScreen({super.key, required this.initialMeal, this.date});

  final Meal initialMeal;

  /// Back-fill a past day. Defaults to today.
  final DateTime? date;

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  late Meal _meal = widget.initialMeal;

  bool get _isToday =>
      widget.date == null ||
      Fmt.dateKey(widget.date!) == Fmt.dateKey(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add food'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Search'),
              Tab(text: 'Saved'),
              Tab(text: 'Order'),
              Tab(text: 'Manual'),
            ],
          ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              if (!_isToday)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0x33FFB020),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x80FFB020)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.history_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text('Adding to ${Fmt.shortDate(widget.date!)}'),
                    ],
                  ),
                ),
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
                    _SearchTab(meal: _meal, date: widget.date),
                    _SavedTab(meal: _meal, date: widget.date),
                    _OrderTab(meal: _meal, date: widget.date),
                    _ManualTab(meal: _meal, date: widget.date),
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
  const _SearchTab({required this.meal, this.date});

  final Meal meal;
  final DateTime? date;

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
                          date: widget.date,
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
  const _SavedTab({required this.meal, this.date});

  final Meal meal;
  final DateTime? date;

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
                              date: widget.date,
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
  const _ManualTab({required this.meal, this.date});

  final Meal meal;
  final DateTime? date;

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
          date: widget.date,
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

// ----------------------------------------------------------------- Order

class _OrderItemDraft {
  _OrderItemDraft()
      : name = TextEditingController(),
        kcal = TextEditingController(),
        protein = TextEditingController(),
        qty = TextEditingController(text: '1');

  final TextEditingController name;
  final TextEditingController kcal;
  final TextEditingController protein;
  final TextEditingController qty;

  bool get isEmpty =>
      name.text.trim().isEmpty &&
      kcal.text.trim().isEmpty &&
      protein.text.trim().isEmpty;

  void dispose() {
    name.dispose();
    kcal.dispose();
    protein.dispose();
    qty.dispose();
  }
}

/// Restaurant order: type the items exactly as the menu lists them (name and
/// calories). Each item is logged separately and can be saved for reuse.
class _OrderTab extends StatefulWidget {
  const _OrderTab({required this.meal, this.date});

  final Meal meal;
  final DateTime? date;

  @override
  State<_OrderTab> createState() => _OrderTabState();
}

class _OrderTabState extends State<_OrderTab> {
  final _formKey = GlobalKey<FormState>();
  final _restaurant = TextEditingController();
  final _items = <_OrderItemDraft>[_OrderItemDraft()];
  // Removed rows are disposed with the tab (their TextFields live one more frame).
  final _trash = <_OrderItemDraft>[];
  bool _save = true;
  bool _busy = false;

  @override
  void dispose() {
    _restaurant.dispose();
    for (final i in _items) {
      i.dispose();
    }
    for (final i in _trash) {
      i.dispose();
    }
    super.dispose();
  }

  double? _n(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  double get _totalKcal => _items.fold(
        0.0,
        (s, i) => s + (_n(i.kcal) ?? 0) * (_n(i.qty) ?? 1),
      );

  double get _totalProtein => _items.fold(
        0.0,
        (s, i) => s + (_n(i.protein) ?? 0) * (_n(i.qty) ?? 1),
      );

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  void _removeItem(_OrderItemDraft i) {
    setState(() {
      if (_items.length == 1) {
        i.name.clear();
        i.kcal.clear();
        i.protein.clear();
        i.qty.text = '1';
      } else {
        _items.remove(i);
        _trash.add(i);
      }
    });
  }

  String? _numberOrEmpty(String? v, {required double max}) {
    if ((v ?? '').trim().isEmpty) return null;
    final n = double.tryParse(v!.trim().replaceAll(',', '.'));
    if (n == null) return 'Number';
    if (n < 0 || n > max) return 'Range';
    return null;
  }

  Future<void> _submit() async {
    final active = _items.where((i) => !i.isEmpty).toList();
    if (active.isEmpty) {
      _snack('Add at least one item.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      final restaurant = _restaurant.text.trim();
      final controller = context.read<FoodController>();
      var total = 0.0;
      for (final i in active) {
        final qty = _n(i.qty) ?? 1;
        final item = i.name.text.trim();
        final food = Food.create(
          name: restaurant.isEmpty ? item : '$item - $restaurant',
          brand: restaurant.isEmpty ? null : restaurant,
          source: 'custom',
          servingDesc: 'as listed',
          kcalPerServing: _n(i.kcal)!,
          proteinPerServing: _n(i.protein) ?? 0,
        );
        final portion = food.byServings(qty);
        total += portion.calories;
        await controller.addFood(
          food: food,
          portion: portion,
          meal: widget.meal,
          saveToFoods: _save,
          date: widget.date,
        );
      }
      if (!mounted) return;
      _snack('Order logged: ${active.length} item(s), ${total.round()} kcal.');
      setState(() {
        _restaurant.clear();
        _trash.addAll(_items);
        _items
          ..clear()
          ..add(_OrderItemDraft());
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeController>().theme;
    final text = Theme.of(context).textTheme;
    final muted = t.textColor.withValues(alpha: 0.7);
    const numeric = TextInputType.numberWithOptions(decimal: true);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _restaurant,
                  textCapitalization: TextCapitalization.words,
                  decoration: _dec('Restaurant (optional)', hint: 'e.g. Jollibee'),
                ),
                const SizedBox(height: 6),
                Text(
                  'Enter each item and the calories printed on the menu or '
                  'receipt.',
                  style: text.bodySmall?.copyWith(color: muted),
                ),
              ],
            ),
          ),
          for (var n = 0; n < _items.length; n++) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: t.glassFill,
                border: Border.all(color: t.glassBorder),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _items[n].name,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _dec('Item ${n + 1}', hint: 'e.g. Chickenjoy 1pc'),
                          onChanged: (_) => setState(() {}),
                          validator: (v) => (_items[n].isEmpty ||
                                  (v ?? '').trim().isNotEmpty)
                              ? null
                              : 'Enter a name',
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove item',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => _removeItem(_items[n]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _items[n].kcal,
                          keyboardType: numeric,
                          decoration: _dec('Calories', suffix: 'kcal'),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            if (_items[n].isEmpty) return null;
                            if ((v ?? '').trim().isEmpty) return 'Required';
                            return _numberOrEmpty(v, max: 5000);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _items[n].protein,
                          keyboardType: numeric,
                          decoration: _dec('Protein', suffix: 'g'),
                          onChanged: (_) => setState(() {}),
                          validator: (v) => _numberOrEmpty(v, max: 500),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _items[n].qty,
                          keyboardType: numeric,
                          decoration: _dec('Qty'),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            final q = double.tryParse(
                              (v ?? '').trim().replaceAll(',', '.'),
                            );
                            if (q == null || q <= 0 || q > 50) return '0.1-50';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => setState(() => _items.add(_OrderItemDraft())),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add another item'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order total',
                      style: text.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${_totalKcal.round()} kcal  |  '
                      '${_totalProtein.toStringAsFixed(0)} g protein',
                      style: text.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Save items to my foods'),
                  subtitle: const Text('Reorder them later, even offline'),
                  value: _save,
                  onChanged: (v) => setState(() => _save = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _submit,
            icon: const Icon(Icons.receipt_long_rounded),
            label: Text('Log order to ${widget.meal.label}'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    );
  }
}

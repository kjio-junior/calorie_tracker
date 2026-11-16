import '../core/utils/formatters.dart';

enum Meal {
  breakfast('Breakfast'),
  lunch('Lunch'),
  dinner('Dinner'),
  snack('Snacks');

  const Meal(this.label);
  final String label;
}

enum PortionMode { grams, servings }

/// The calories and protein for a chosen amount of a food.
class Portion {
  const Portion({
    required this.calories,
    required this.protein,
    required this.quantity,
    required this.label,
  });

  final double calories;
  final double protein;

  /// Grams or number of servings, depending on how it was entered.
  final double quantity;

  /// Human-readable amount, e.g. "150 g" or "2 x 1 slice".
  final String label;
}

class Food {
  const Food({
    this.id,
    required this.name,
    this.brand,
    required this.source,
    this.offCode,
    this.servingG,
    this.servingDesc,
    this.kcalPer100g,
    this.proteinPer100g,
    this.kcalPerServing,
    this.proteinPerServing,
  });

  final int? id;
  final String name;
  final String? brand;

  /// 'off' (Open Food Facts) or 'custom' (typed in by hand).
  final String source;
  final String? offCode;
  final double? servingG;
  final String? servingDesc;
  final double? kcalPer100g;
  final double? proteinPer100g;
  final double? kcalPerServing;
  final double? proteinPerServing;

  /// Fills in whichever of per-100g / per-serving is missing when the serving
  /// weight is known, so both entry modes work wherever possible.
  factory Food.create({
    required String name,
    String? brand,
    required String source,
    String? offCode,
    double? servingG,
    String? servingDesc,
    double? kcalPer100g,
    double? proteinPer100g,
    double? kcalPerServing,
    double? proteinPerServing,
  }) {
    var k100 = kcalPer100g;
    var p100 = proteinPer100g;
    var ks = kcalPerServing;
    var ps = proteinPerServing;
    final g = servingG;
    if (g != null && g > 0) {
      if (ks == null && k100 != null) ks = k100 * g / 100;
      if (ps == null && p100 != null) ps = p100 * g / 100;
      if (k100 == null && ks != null) k100 = ks * 100 / g;
      if (p100 == null && ps != null) p100 = ps * 100 / g;
    }
    return Food(
      name: name,
      brand: brand,
      source: source,
      offCode: offCode,
      servingG: (g != null && g > 0) ? g : null,
      servingDesc: servingDesc,
      kcalPer100g: k100,
      proteinPer100g: p100,
      kcalPerServing: ks,
      proteinPerServing: ps,
    );
  }

  /// Parses one product from Open Food Facts (legacy search or
  /// Search-a-licious). Energy is normalised to kcal: OFF's `energy_100g` is
  /// always kilojoules, so it is divided by 4.184 when no kcal value exists.
  /// Returns null when the product has no usable name or energy value.
  static Food? fromOff(Map<String, dynamic> j) {
    String? str(dynamic v) {
      if (v is String && v.trim().isNotEmpty) return v.trim();
      return null;
    }

    final name = str(j['product_name']) ?? str(j['product_name_en']);
    if (name == null) return null;

    final raw = j['nutriments'];
    final n = raw is Map ? raw : const {};
    double? val(String key) {
      final v = n[key];
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    var kcal100 = val('energy-kcal_100g');
    if (kcal100 == null) {
      final kj = val('energy_100g') ?? val('energy-kj_100g');
      if (kj != null) kcal100 = kj / 4.184;
    }
    if (kcal100 == null || kcal100 < 0 || kcal100 > 900) return null;

    var protein100 = val('proteins_100g');
    if (protein100 != null && (protein100 < 0 || protein100 > 100)) {
      protein100 = null;
    }

    double? servingG;
    final sq = j['serving_quantity'];
    if (sq is num) servingG = sq.toDouble();
    if (sq is String) servingG = double.tryParse(sq);
    final servingText = str(j['serving_size']);
    if ((servingG == null || servingG <= 0) && servingText != null) {
      final m = RegExp(r'(\d+(?:[.,]\d+)?)\s*g\b', caseSensitive: false)
          .firstMatch(servingText);
      if (m != null) {
        servingG = double.tryParse(m.group(1)!.replaceAll(',', '.'));
      }
    }
    if (servingG != null && (servingG <= 0 || servingG > 2000)) {
      servingG = null;
    }

    String? brand;
    final b = j['brands'];
    if (b is String && b.trim().isNotEmpty) {
      brand = b.split(',').first.trim();
    } else if (b is List && b.isNotEmpty) {
      brand = b.first.toString();
    }

    return Food.create(
      name: name,
      brand: brand,
      source: 'off',
      offCode: str(j['code']),
      servingG: servingG,
      servingDesc: servingText,
      kcalPer100g: kcal100,
      proteinPer100g: protein100,
    );
  }

  bool get canGrams => kcalPer100g != null;
  bool get canServings => kcalPerServing != null;

  String get servingLabel =>
      servingDesc ?? (servingG != null ? '${Fmt.amount(servingG!)} g' : 'serving');

  Portion byGrams(double g) => Portion(
        calories: kcalPer100g! * g / 100,
        protein: (proteinPer100g ?? 0) * g / 100,
        quantity: g,
        label: '${Fmt.amount(g)} g',
      );

  Portion byServings(double n) => Portion(
        calories: kcalPerServing! * n,
        protein: (proteinPerServing ?? 0) * n,
        quantity: n,
        label: n == 1 ? servingLabel : '${Fmt.amount(n)} x $servingLabel',
      );
}

class FoodLogEntry {
  const FoodLogEntry({
    this.id,
    required this.date,
    required this.meal,
    required this.name,
    this.servingDesc,
    required this.quantity,
    required this.calories,
    required this.protein,
    this.savedFoodId,
  });

  final int? id;
  final String date;
  final Meal meal;
  final String name;
  final String? servingDesc;
  final double quantity;
  final double calories;
  final double protein;
  final int? savedFoodId;
}

class DayTotal {
  const DayTotal({
    required this.date,
    required this.entries,
    required this.calories,
    required this.protein,
  });

  final String date;
  final int entries;
  final double calories;
  final double protein;
}

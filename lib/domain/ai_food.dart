import 'dart:convert';

import '../data/ai_service.dart' show AiException;

/// Instructions for estimating the nutrition of one described food.
const String kFoodEstimateSystemPrompt =
    'You are a careful nutrition database assistant. The user describes one '
    'food or dish and optionally its weight. Estimate the nutrition for the '
    'WHOLE portion described, using typical values (cooked weight unless the '
    'user says raw). If no weight is given, assume one typical serving and '
    'report that weight. Reply with ONLY a JSON object, with no markdown and '
    'no text before or after it, using exactly these keys: "name" (short, '
    'clean food name), "weight_g" (number, grams of the portion), "calories" '
    '(kcal, number), "protein_g", "carbs_g", "fat_g" (numbers), and "note" '
    '(one short sentence with the key assumption, max 18 words). Use '
    'realistic values; calories should roughly equal 4 x protein + 4 x carbs '
    '+ 9 x fat.';

String foodEstimatePrompt(String description, double? weightG) {
  final weight = weightG == null
      ? 'not given (assume a typical single serving)'
      : '${weightG.toStringAsFixed(weightG == weightG.roundToDouble() ? 0 : 1)} g';
  return 'Food: $description\nWeight: $weight\n\nReturn only the JSON object.';
}

/// Nutrition for the whole portion, as estimated by the AI.
class AiFoodEstimate {
  const AiFoodEstimate({
    required this.name,
    required this.weightG,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.note,
  });

  final String name;
  final double weightG;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final String note;

  static const _unreadable =
      'The AI answer could not be read. Try again or rephrase the food.';

  /// Reads the AI answer. Tolerates code fences and extra text around the
  /// JSON, and rejects numbers outside realistic ranges.
  static AiFoodEstimate parse(String raw, {required String fallbackName}) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start < 0 || end <= start) throw const AiException(_unreadable);

    final Object? decoded;
    try {
      decoded = jsonDecode(raw.substring(start, end + 1));
    } on FormatException {
      throw const AiException(_unreadable);
    }
    if (decoded is! Map) throw const AiException(_unreadable);
    // A fresh, non-nullable variable: the closure below cannot rely on the
    // type check done on `decoded` above.
    final Map data = decoded;

    double? read(String key) {
      final v = data[key];
      if (v is num) return v.toDouble();
      if (v is String) {
        return double.tryParse(v.replaceAll(RegExp(r'[^0-9.\-]'), ''));
      }
      return null;
    }

    final weight = read('weight_g');
    final calories = read('calories');
    final protein = read('protein_g');
    final carbs = read('carbs_g');
    final fat = read('fat_g');
    if (weight == null ||
        calories == null ||
        protein == null ||
        carbs == null ||
        fat == null ||
        weight < 1 ||
        weight > 5000 ||
        calories < 0 ||
        calories > 5000 ||
        protein < 0 ||
        protein > 1000 ||
        carbs < 0 ||
        carbs > 1000 ||
        fat < 0 ||
        fat > 1000) {
      throw const AiException(_unreadable);
    }

    final rawName = data['name'];
    var name = (rawName is String && rawName.trim().isNotEmpty)
        ? rawName.trim()
        : fallbackName.trim();
    if (name.length > 60) name = name.substring(0, 60);
    final rawNote = data['note'];

    return AiFoodEstimate(
      name: name,
      weightG: weight,
      calories: calories,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
      note: rawNote is String ? rawNote.trim() : '',
    );
  }
}

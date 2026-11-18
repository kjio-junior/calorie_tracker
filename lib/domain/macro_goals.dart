/// Daily macro goals derived from the calorie target.
///
/// Protein uses the user's own goal when the protein tracker is on, otherwise
/// 1.6 g per kg of body weight. Fat is about 27% of calories, and carbs get
/// the remaining calories. These are estimates, not medical advice.
class MacroGoals {
  const MacroGoals({
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final int protein;
  final int carbs;
  final int fat;

  static MacroGoals compute({
    required int calorieTarget,
    required double weightKg,
    int? proteinTarget,
  }) {
    final protein = proteinTarget ?? (weightKg * 1.6).round();
    final fat = (calorieTarget * 0.27 / 9).round();
    final carbKcal = calorieTarget - protein * 4 - fat * 9;
    final carbs = carbKcal > 0 ? (carbKcal / 4).round() : 0;
    return MacroGoals(protein: protein, carbs: carbs, fat: fat);
  }
}

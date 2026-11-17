import '../../domain/food.dart';

/// Picks the likeliest meal for the time of day.
Meal guessMeal([DateTime? now]) {
  final h = (now ?? DateTime.now()).hour;
  if (h < 10) return Meal.breakfast;
  if (h < 14) return Meal.lunch;
  if (h < 17) return Meal.snack;
  if (h < 21) return Meal.dinner;
  return Meal.snack;
}

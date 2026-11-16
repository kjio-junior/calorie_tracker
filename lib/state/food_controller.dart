import 'package:flutter/foundation.dart';

import '../core/utils/formatters.dart';
import '../data/food_repository.dart';
import '../data/weight_repository.dart';
import '../domain/food.dart';
import '../domain/streaks.dart';

/// Today's food log, totals and streaks, plus the saved-foods cache.
class FoodController extends ChangeNotifier {
  FoodController._(this._repo, this._weightRepo);

  final FoodRepository _repo;
  final WeightRepository _weightRepo;

  String _todayKey = Fmt.dateKey(DateTime.now());
  List<FoodLogEntry> _logs = [];
  StreakStats _streaks = StreakStats.empty;

  static Future<FoodController> load() async {
    final c = FoodController._(FoodRepository(), WeightRepository());
    await c.refreshToday();
    return c;
  }

  String get todayKey => _todayKey;
  List<FoodLogEntry> get logs => List.unmodifiable(_logs);
  StreakStats get streaks => _streaks;

  double get calories => _logs.fold(0.0, (s, e) => s + e.calories);
  double get protein => _logs.fold(0.0, (s, e) => s + e.protein);

  List<FoodLogEntry> logsFor(Meal m) =>
      _logs.where((e) => e.meal == m).toList();

  /// Also called when the app returns to the foreground, so the dashboard
  /// rolls over to the new day after midnight.
  Future<void> refreshToday() async {
    _todayKey = Fmt.dateKey(DateTime.now());
    _logs = await _repo.logsForDate(_todayKey);
    await _refreshStreaks();
    notifyListeners();
  }

  Future<void> _refreshStreaks() async {
    final days = await _repo.dayTotals();
    final targets = await _weightRepo.allTargets();
    _streaks = StreakService.compute(
      days: days,
      targets: targets,
      today: DateTime.now(),
    );
  }

  /// Logs [portion] of [food]. With [saveToFoods] the food is also cached in
  /// saved_foods (and bumped in "recent") so it works offline next time.
  Future<void> addFood({
    required Food food,
    required Portion portion,
    required Meal meal,
    bool saveToFoods = true,
  }) async {
    int? savedId;
    if (saveToFoods) {
      savedId = await _repo.saveFood(food);
      await _repo.markUsed(savedId);
    }
    await _repo.insertLog(
      FoodLogEntry(
        date: Fmt.dateKey(DateTime.now()),
        meal: meal,
        name: food.name,
        servingDesc: portion.label,
        quantity: portion.quantity,
        calories: portion.calories,
        protein: portion.protein,
        savedFoodId: savedId,
      ),
    );
    await refreshToday();
  }

  /// Removes the row from the list immediately (a swiped Dismissible must
  /// leave the tree in the same frame), then deletes it from SQLite.
  Future<void> deleteLog(FoodLogEntry e) async {
    _logs = _logs.where((l) => l.id != e.id).toList();
    notifyListeners();
    await _repo.deleteLog(e.id!);
    await refreshToday();
  }

  Future<void> restoreLog(FoodLogEntry e) async {
    await _repo.insertLog(e);
    await refreshToday();
  }

  Future<List<Food>> savedFoods({String query = ''}) =>
      _repo.savedFoods(query: query);

  Future<void> deleteSavedFood(int id) => _repo.deleteSavedFood(id);
}

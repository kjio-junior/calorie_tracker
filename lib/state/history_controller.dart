import 'package:flutter/foundation.dart';

import '../core/utils/formatters.dart';
import '../data/activity_repository.dart';
import '../data/food_repository.dart';
import '../data/history_repository.dart';
import '../data/weight_repository.dart';
import '../domain/activity.dart';
import '../domain/food.dart';
import 'activity_controller.dart';
import 'food_controller.dart';

class DayDetail {
  const DayDetail({
    required this.date,
    required this.food,
    required this.cardio,
    required this.sessions,
    required this.target,
  });

  final String date;
  final List<FoodLogEntry> food;
  final List<CardioEntry> cardio;
  final List<WorkoutSession> sessions;

  /// The targets in force on that day (null before the first record).
  final DailyTargetRecord? target;

  double get calories => food.fold(0.0, (s, e) => s + e.calories);
  double get protein => food.fold(0.0, (s, e) => s + e.protein);
  double get carbs => food.fold(0.0, (s, e) => s + e.carbs);
  double get fat => food.fold(0.0, (s, e) => s + e.fat);
  double get cardioBurned => cardio.fold(0.0, (s, e) => s + (e.calories ?? 0));
  double get workoutBurned =>
      sessions.fold(0.0, (s, e) => s + (e.estCalories ?? 0));
  double get burned => cardioBurned + workoutBurned;

  DayDetail copyWith({
    List<FoodLogEntry>? food,
    List<CardioEntry>? cardio,
    List<WorkoutSession>? sessions,
  }) =>
      DayDetail(
        date: date,
        food: food ?? this.food,
        cardio: cardio ?? this.cardio,
        sessions: sessions ?? this.sessions,
        target: target,
      );
}

/// The History screen: selected day, visible month, which days have data,
/// and edits/deletes for past entries. After every change the dashboard
/// controllers are refreshed so "today" stays consistent.
class HistoryController extends ChangeNotifier {
  HistoryController._(this._foodRepo, this._activityRepo, this._weightRepo,
      this._historyRepo, this._foodController, this._activityController);

  final FoodRepository _foodRepo;
  final ActivityRepository _activityRepo;
  final WeightRepository _weightRepo;
  final HistoryRepository _historyRepo;
  final FoodController _foodController;
  final ActivityController _activityController;

  late DateTime _selected;
  late DateTime _month;
  DayDetail? _detail;
  Set<String> _marked = {};

  static Future<HistoryController> load({
    required FoodController food,
    required ActivityController activity,
  }) async {
    final c = HistoryController._(
      FoodRepository(),
      ActivityRepository(),
      WeightRepository(),
      HistoryRepository(),
      food,
      activity,
    );
    final now = DateTime.now();
    c._selected = DateTime(now.year, now.month, now.day);
    c._month = DateTime(now.year, now.month);
    await c.refresh();
    return c;
  }

  DateTime get selected => _selected;
  DateTime get month => _month;
  DayDetail? get detail => _detail;
  Set<String> get marked => _marked;

  Future<void> select(DateTime d) async {
    _selected = DateTime(d.year, d.month, d.day);
    _month = DateTime(d.year, d.month);
    await refresh();
  }

  void showMonth(DateTime m) {
    _month = DateTime(m.year, m.month);
    notifyListeners();
  }

  Future<void> goToToday() => select(DateTime.now());

  Future<void> refresh() async {
    final key = Fmt.dateKey(_selected);
    final food = await _foodRepo.logsForDate(key);
    final cardio = await _activityRepo.cardioForDate(key);
    final sessions = await _activityRepo.sessionsForDate(key);
    final target = await _weightRepo.targetsFor(key);
    _marked = await _historyRepo.datesWithData();
    _detail = DayDetail(
      date: key,
      food: food,
      cardio: cardio,
      sessions: sessions,
      target: target,
    );
    notifyListeners();
  }

  Future<void> _afterChange() async {
    await refresh();
    await _foodController.refreshToday();
    await _activityController.refreshToday();
  }

  // ---- food ----

  Future<void> deleteFood(FoodLogEntry e) async {
    final d = _detail;
    if (d != null) {
      _detail = d.copyWith(food: d.food.where((x) => x.id != e.id).toList());
      notifyListeners();
    }
    await _foodRepo.deleteLog(e.id!);
    await _afterChange();
  }

  Future<void> restoreFood(FoodLogEntry e) async {
    await _foodRepo.insertLog(e);
    await _afterChange();
  }

  Future<void> updateFood(FoodLogEntry e) async {
    await _foodRepo.updateLog(e);
    await _afterChange();
  }

  // ---- cardio ----

  Future<void> deleteCardio(CardioEntry e) async {
    final d = _detail;
    if (d != null) {
      _detail = d.copyWith(cardio: d.cardio.where((x) => x.id != e.id).toList());
      notifyListeners();
    }
    await _activityRepo.deleteCardio(e.id!);
    await _afterChange();
  }

  Future<void> restoreCardio(CardioEntry e) async {
    await _activityRepo.insertCardio(e);
    await _afterChange();
  }

  // ---- strength ----

  Future<void> deleteSession(WorkoutSession s) async {
    final d = _detail;
    if (d != null) {
      _detail =
          d.copyWith(sessions: d.sessions.where((x) => x.id != s.id).toList());
      notifyListeners();
    }
    await _activityRepo.deleteSession(s.id!);
    await _afterChange();
  }

  Future<void> restoreSession(WorkoutSession s) async {
    await _activityRepo.saveSession(s);
    await _afterChange();
  }
}

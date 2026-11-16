import 'package:flutter/foundation.dart';

import '../core/utils/formatters.dart';
import '../data/activity_repository.dart';
import '../domain/activity.dart';

/// Today's cardio entries and strength sessions, plus calories burned.
class ActivityController extends ChangeNotifier {
  ActivityController._(this._repo);

  final ActivityRepository _repo;

  List<CardioEntry> _cardio = [];
  List<WorkoutSession> _sessions = [];

  static Future<ActivityController> load() async {
    final c = ActivityController._(ActivityRepository());
    await c.refreshToday();
    return c;
  }

  List<CardioEntry> get cardio => List.unmodifiable(_cardio);
  List<WorkoutSession> get sessions => List.unmodifiable(_sessions);

  double get cardioBurned => _cardio.fold(0.0, (s, e) => s + (e.calories ?? 0));
  double get workoutBurned =>
      _sessions.fold(0.0, (s, e) => s + (e.estCalories ?? 0));
  double get burnedToday => cardioBurned + workoutBurned;

  Future<void> refreshToday() async {
    final key = Fmt.dateKey(DateTime.now());
    _cardio = await _repo.cardioForDate(key);
    _sessions = await _repo.sessionsForDate(key);
    notifyListeners();
  }

  Future<void> addCardio(CardioEntry e) async {
    await _repo.insertCardio(e);
    await refreshToday();
  }

  /// Removed from the list immediately so a swiped Dismissible leaves the
  /// tree in the same frame.
  Future<void> deleteCardio(CardioEntry e) async {
    _cardio = _cardio.where((x) => x.id != e.id).toList();
    notifyListeners();
    await _repo.deleteCardio(e.id!);
    await refreshToday();
  }

  Future<void> restoreCardio(CardioEntry e) => addCardio(e);

  Future<void> saveWorkout(WorkoutSession s) async {
    await _repo.saveSession(s);
    await refreshToday();
  }

  Future<void> deleteWorkout(WorkoutSession s) async {
    _sessions = _sessions.where((x) => x.id != s.id).toList();
    notifyListeners();
    await _repo.deleteSession(s.id!);
    await refreshToday();
  }

  Future<void> restoreWorkout(WorkoutSession s) => saveWorkout(s);
}

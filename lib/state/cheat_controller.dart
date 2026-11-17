import 'package:flutter/foundation.dart';

import '../core/utils/formatters.dart';
import '../data/cheat_repository.dart';
import 'food_controller.dart';

/// Cheat days: on a cheat day the calorie limit is relaxed (maintenance or no
/// limit, see Settings), and calorie/protein streaks neither break nor grow.
class CheatController extends ChangeNotifier {
  CheatController._(this._repo, this._food);

  final CheatRepository _repo;
  final FoodController _food;
  Set<String> _days = {};

  static Future<CheatController> load({required FoodController food}) async {
    final c = CheatController._(CheatRepository(), food);
    c._days = await c._repo.allDays();
    return c;
  }

  Set<String> get days => _days;

  bool isCheat(String dateKey) => _days.contains(dateKey);

  bool get todayIsCheat => _days.contains(Fmt.dateKey(DateTime.now()));

  int get thisMonthCount {
    final now = DateTime.now();
    final prefix = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-';
    return _days.where((d) => d.startsWith(prefix)).length;
  }

  Future<void> toggle(DateTime d) async {
    final key = Fmt.dateKey(d);
    if (_days.contains(key)) {
      _days = {..._days}..remove(key);
      notifyListeners();
      await _repo.remove(key);
    } else {
      _days = {..._days, key};
      notifyListeners();
      await _repo.add(key);
    }
    // Streaks depend on cheat days, so recompute them.
    await _food.refreshToday();
  }
}

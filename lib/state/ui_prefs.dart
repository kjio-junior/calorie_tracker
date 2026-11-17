import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Module toggles and dashboard display options.
class UiPrefs extends ChangeNotifier {
  UiPrefs._(
    this._prefs, {
    required bool showStreaks,
    required bool cardioEnabled,
    required bool workoutsEnabled,
    required bool burnedAddsBack,
    required bool cheatUnlimited,
  })  : _showStreaks = showStreaks,
        _cardioEnabled = cardioEnabled,
        _workoutsEnabled = workoutsEnabled,
        _burnedAddsBack = burnedAddsBack,
        _cheatUnlimited = cheatUnlimited;

  static const _kStreaks = 'ui_show_streaks';
  static const _kCardio = 'ui_cardio_enabled';
  static const _kWorkouts = 'ui_workouts_enabled';
  static const _kAddBack = 'ui_burned_adds_back';
  static const _kCheatUnlimited = 'ui_cheat_unlimited';

  final SharedPreferences _prefs;
  bool _showStreaks;
  bool _cardioEnabled;
  bool _workoutsEnabled;
  bool _burnedAddsBack;
  bool _cheatUnlimited;

  static Future<UiPrefs> load() async {
    final p = await SharedPreferences.getInstance();
    return UiPrefs._(
      p,
      showStreaks: p.getBool(_kStreaks) ?? true,
      cardioEnabled: p.getBool(_kCardio) ?? true,
      workoutsEnabled: p.getBool(_kWorkouts) ?? true,
      // Off by default: burned calories are logged but do not raise your
      // food allowance, which keeps the deficit stricter.
      burnedAddsBack: p.getBool(_kAddBack) ?? false,
      // Off by default: a cheat day uses your maintenance calories as limit.
      cheatUnlimited: p.getBool(_kCheatUnlimited) ?? false,
    );
  }

  bool get showStreaks => _showStreaks;
  bool get cardioEnabled => _cardioEnabled;
  bool get workoutsEnabled => _workoutsEnabled;
  bool get burnedAddsBack => _burnedAddsBack;

  /// true = no calorie limit on cheat days, false = maintenance (TDEE).
  bool get cheatUnlimited => _cheatUnlimited;

  void setShowStreaks(bool v) {
    if (v == _showStreaks) return;
    _showStreaks = v;
    notifyListeners();
    _prefs.setBool(_kStreaks, v);
  }

  void setCardioEnabled(bool v) {
    if (v == _cardioEnabled) return;
    _cardioEnabled = v;
    notifyListeners();
    _prefs.setBool(_kCardio, v);
  }

  void setWorkoutsEnabled(bool v) {
    if (v == _workoutsEnabled) return;
    _workoutsEnabled = v;
    notifyListeners();
    _prefs.setBool(_kWorkouts, v);
  }

  void setBurnedAddsBack(bool v) {
    if (v == _burnedAddsBack) return;
    _burnedAddsBack = v;
    notifyListeners();
    _prefs.setBool(_kAddBack, v);
  }

  void setCheatUnlimited(bool v) {
    if (v == _cheatUnlimited) return;
    _cheatUnlimited = v;
    notifyListeners();
    _prefs.setBool(_kCheatUnlimited, v);
  }
}

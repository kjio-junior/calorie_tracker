import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/formatters.dart';
import '../data/weight_repository.dart';
import '../domain/calorie_engine.dart';
import '../domain/user_profile.dart';

/// Profile + weigh-ins + current targets. Every weight or profile change
/// recalculates BMR/TDEE/targets and stores today's targets in SQLite, while
/// earlier days keep the targets they were saved with.
class ProfileController extends ChangeNotifier {
  ProfileController._(this._prefs, this._repo);

  final SharedPreferences _prefs;
  final WeightRepository _repo;

  UserProfile? _profile;
  List<WeightEntry> _weights = [];
  NutritionTargets? _targets;

  static Future<ProfileController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final c = ProfileController._(prefs, WeightRepository());
    c._profile = UserProfile.load(prefs);
    c._weights = await c._repo.allWeights();
    c._recompute();
    return c;
  }

  bool get onboarded => _profile != null && _weights.isNotEmpty;
  UserProfile? get profile => _profile;
  List<WeightEntry> get weights => List.unmodifiable(_weights);
  NutritionTargets? get targets => _targets;
  WeightEntry? get latest => _weights.isEmpty ? null : _weights.last;

  double? get currentKg => latest?.weightKg;
  double get startKg => _profile?.startWeightKg ?? 0;

  /// Positive = lost, negative = gained.
  double get totalLostKg => startKg - (currentKg ?? startKg);

  Future<DailyTargetRecord?> targetsForDate(DateTime d) =>
      _repo.targetsFor(Fmt.dateKey(d));

  Future<void> completeOnboarding(UserProfile profile) async {
    await profile.save(_prefs);
    _profile = profile;
    await _repo.upsertWeight(
      Fmt.dateKey(DateTime.now()),
      profile.startWeightKg,
    );
    await _afterChange();
  }

  Future<void> logWeight(double kg, {DateTime? on}) async {
    await _repo.upsertWeight(Fmt.dateKey(on ?? DateTime.now()), kg);
    await _afterChange();
  }

  /// Deletes a weigh-in and recalculates targets. At least one weigh-in
  /// must remain, so deleting the last one is refused (returns false).
  Future<bool> deleteWeight(int id) async {
    if (_weights.length <= 1) return false;
    await _repo.deleteWeight(id);
    await _afterChange();
    return true;
  }

  Future<void> updateProfile(UserProfile profile) async {
    await profile.save(_prefs);
    _profile = profile;
    await _afterChange();
  }

  Future<void> _afterChange() async {
    _weights = await _repo.allWeights();
    _recompute();
    final t = _targets;
    final w = currentKg;
    if (t != null && w != null) {
      await _repo.upsertTargets(Fmt.dateKey(DateTime.now()), t, w);
    }
    notifyListeners();
  }

  void _recompute() {
    final p = _profile;
    final w = currentKg;
    _targets = (p != null && w != null) ? CalorieEngine.compute(p, w) : null;
  }
}

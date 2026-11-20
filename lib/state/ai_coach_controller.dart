import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/formatters.dart';
import '../data/ai_service.dart';
import '../data/ai_summary_repository.dart';
import '../data/food_repository.dart';
import '../domain/ai_food.dart';
import '../domain/coach_prompt.dart';

/// Free AI daily coach. API keys live in secure storage (never in the
/// database, preferences or backups). The latest summary is cached in SQLite
/// so it stays readable offline.
class AiCoachController extends ChangeNotifier {
  AiCoachController._(
    this._prefs,
    this._storage,
    this._service,
    this._repo,
    this._foodRepo,
    this._provider,
  );

  static const _kProvider = 'ai_provider';
  static String _kModel(AiProvider p) => 'ai_model_${p.name}';
  static String _kKey(AiProvider p) => 'ai_key_${p.name}';

  final SharedPreferences _prefs;
  final FlutterSecureStorage _storage;
  final AiService _service;
  final AiSummaryRepository _repo;
  final FoodRepository _foodRepo;

  AiProvider _provider;
  final Map<AiProvider, bool> _hasKey = {};
  AiSummaryRecord? _latest;
  bool _loading = false;
  String? _error;

  static Future<AiCoachController> load() async {
    final prefs = await SharedPreferences.getInstance();
    const storage = FlutterSecureStorage();
    final saved = prefs.getString(_kProvider);
    final provider = AiProvider.values.firstWhere(
      (p) => p.name == saved,
      orElse: () => AiProvider.gemini,
    );
    final c = AiCoachController._(
      prefs,
      storage,
      AiService(),
      AiSummaryRepository(),
      FoodRepository(),
      provider,
    );
    for (final p in AiProvider.values) {
      try {
        final v = await storage.read(key: _kKey(p));
        c._hasKey[p] = v != null && v.isNotEmpty;
      } catch (_) {
        c._hasKey[p] = false;
      }
    }
    c._latest = await c._repo.latest();
    return c;
  }

  AiProvider get provider => _provider;
  bool get loading => _loading;
  String? get error => _error;
  AiSummaryRecord? get latest => _latest;
  bool hasKey(AiProvider p) => _hasKey[p] ?? false;
  bool get ready => hasKey(_provider);

  String modelFor(AiProvider p) {
    final m = _prefs.getString(_kModel(p));
    return (m == null || m.trim().isEmpty) ? p.defaultModel : m.trim();
  }

  Future<void> setProvider(AiProvider p) async {
    _provider = p;
    _error = null;
    await _prefs.setString(_kProvider, p.name);
    notifyListeners();
  }

  Future<void> setModel(AiProvider p, String model) async {
    final m = model.trim();
    if (m.isEmpty || m == p.defaultModel) {
      await _prefs.remove(_kModel(p));
    } else {
      await _prefs.setString(_kModel(p), m);
    }
    notifyListeners();
  }

  Future<void> saveKey(AiProvider p, String key) async {
    await _storage.write(key: _kKey(p), value: key.trim());
    _hasKey[p] = key.trim().isNotEmpty;
    _error = null;
    notifyListeners();
  }

  Future<void> removeKey(AiProvider p) async {
    await _storage.delete(key: _kKey(p));
    _hasKey[p] = false;
    notifyListeners();
  }

  /// Returns null when the connection works, otherwise an error message.
  Future<String?> testConnection() async {
    try {
      final key = await _storage.read(key: _kKey(_provider));
      if (key == null || key.isEmpty) return 'Save an API key first.';
      await _service.generate(
        provider: _provider,
        model: modelFor(_provider),
        apiKey: key,
        system: 'Reply with one short word.',
        prompt: 'Say OK.',
      );
      return null;
    } on AiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Something went wrong: $e';
    }
  }

  /// Estimates calories, protein, carbs and fat for a food the user
  /// described (and optionally weighed), using the saved API key. Only the
  /// description and weight are sent to the provider.
  Future<AiFoodEstimate> estimateFood({
    required String description,
    double? weightG,
  }) async {
    final key = await _storage.read(key: _kKey(_provider));
    if (key == null || key.isEmpty) {
      throw const AiException('Add your API key in Settings first.');
    }
    final raw = await _service.generate(
      provider: _provider,
      model: modelFor(_provider),
      apiKey: key,
      system: kFoodEstimateSystemPrompt,
      prompt: foodEstimatePrompt(description, weightG),
      temperature: 0.2,
    );
    return AiFoodEstimate.parse(raw, fallbackName: description);
  }

  Future<void> generate(CoachSnapshot base) async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final key = await _storage.read(key: _kKey(_provider));
      if (key == null || key.isEmpty) {
        throw const AiException('Add your API key in Settings first.');
      }
      final snapshot = await _withWeek(base);
      final raw = await _service.generate(
        provider: _provider,
        model: modelFor(_provider),
        apiKey: key,
        system: kCoachSystemPrompt,
        prompt: snapshot.toPrompt(),
      );
      final clean = raw
          .replaceAll(RegExp(r'[*#`]'), '')
          .replaceAll(RegExp(r'\n{3,}'), '\n\n')
          .trim();
      if (clean.isEmpty) {
        throw const AiException('The AI returned an empty answer. Try again.');
      }
      final date = Fmt.dateKey(DateTime.now());
      await _repo.save(date, clean);
      _latest = AiSummaryRecord(date: date, text: clean);
    } on AiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Something went wrong: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Adds stats for the 7 days before today.
  Future<CoachSnapshot> _withWeek(CoachSnapshot base) async {
    final days = await _foodRepo.dayTotals();
    final today = DateTime.now();
    final keys = <String>{
      for (var i = 1; i <= 7; i++)
        Fmt.dateKey(
          DateTime(today.year, today.month, today.day)
              .subtract(Duration(days: i)),
        ),
    };
    final window = days.where((d) => keys.contains(d.date)).toList();
    if (window.isEmpty) {
      return base.withWeek(loggedDays: 0, avgKcal: null, avgProtein: null);
    }
    final kcal = window.fold(0.0, (s, d) => s + d.calories) / window.length;
    final protein = window.fold(0.0, (s, d) => s + d.protein) / window.length;
    return base.withWeek(
      loggedDays: window.length,
      avgKcal: kcal.round(),
      avgProtein: protein.round(),
    );
  }
}

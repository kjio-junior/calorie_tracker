import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../domain/food.dart';

class FoodSearchException implements Exception {
  const FoodSearchException(this.message, {this.serverError = false});

  final String message;

  /// True for 5xx / timeouts, where trying the fallback endpoint makes sense.
  final bool serverError;

  @override
  String toString() => message;
}

class _CacheEntry {
  _CacheEntry(this.foods) : at = DateTime.now();
  final List<Food> foods;
  final DateTime at;
}

/// Open Food Facts text search (free, no API key).
///
/// Open Food Facts asks every app to send a User-Agent of the form
/// "AppName/Version (ContactEmail)" and limits searches to 10 per minute per
/// IP, so this service identifies itself, caches results for 10 minutes and
/// keeps its own per-minute counter. Searches only run when the user submits.
class OpenFoodFactsService {
  OpenFoodFactsService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  // Replace the email below with your own address (Open Food Facts asks for it).
  static const _userAgent = 'CalorieTracker/1.0 (kevinduran1017@gmail.com)';
  static const _fields =
      'code,product_name,brands,nutriments,serving_size,serving_quantity';
  static const _maxSearchesPerMinute = 9;

  final _searchTimes = <DateTime>[];
  final _cache = <String, _CacheEntry>{};

  void dispose() => _client.close();

  Future<List<Food>> search(String query) async {
    final q = query.trim();
    if (q.length < 2) return const [];

    final key = q.toLowerCase();
    final cached = _cache[key];
    if (cached != null &&
        DateTime.now().difference(cached.at) < const Duration(minutes: 10)) {
      return cached.foods;
    }

    final now = DateTime.now();
    _searchTimes.removeWhere(
      (t) => now.difference(t) > const Duration(seconds: 60),
    );
    if (_searchTimes.length >= _maxSearchesPerMinute) {
      throw const FoodSearchException(
        'Too many searches in a minute. Wait a few seconds and try again.',
      );
    }
    _searchTimes.add(now);

    Map<String, dynamic> body;
    try {
      body = await _get(
        Uri.https('world.openfoodfacts.org', '/cgi/search.pl', {
          'search_terms': q,
          'search_simple': '1',
          'action': 'process',
          'json': '1',
          'page_size': '24',
          'fields': _fields,
        }),
      );
    } on FoodSearchException catch (e) {
      if (!e.serverError) rethrow;
      // Legacy endpoint is busy: fall back to Search-a-licious.
      body = await _get(
        Uri.https('search.openfoodfacts.org', '/search', {
          'q': q,
          'page_size': '24',
          'fields': _fields,
        }),
      );
    }

    final list = (body['products'] ?? body['hits']);
    final foods = <Food>[];
    final seen = <String>{};
    if (list is List) {
      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        final food = Food.fromOff(item);
        if (food == null) continue;
        final code = food.offCode;
        if (code != null && !seen.add(code)) continue;
        foods.add(food);
      }
    }
    _cache[key] = _CacheEntry(foods);
    return foods;
  }

  Future<Map<String, dynamic>> _get(Uri uri) async {
    try {
      final res = await _client.get(uri, headers: {
        'User-Agent': _userAgent,
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 15));

      if (res.statusCode == 429) {
        throw const FoodSearchException(
          'Open Food Facts is limiting searches right now. '
          'Try again in a minute.',
        );
      }
      if (res.statusCode >= 500) {
        throw const FoodSearchException(
          'Open Food Facts is busy right now.',
          serverError: true,
        );
      }
      if (res.statusCode != 200) {
        throw FoodSearchException('Search failed (HTTP ${res.statusCode}).');
      }
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FoodSearchException(
          'Unexpected response from Open Food Facts.',
        );
      }
      return decoded;
    } on TimeoutException {
      throw const FoodSearchException(
        'The search timed out.',
        serverError: true,
      );
    } on SocketException {
      throw const FoodSearchException(
        'Could not reach Open Food Facts. Check your connection.',
      );
    } on http.ClientException {
      throw const FoodSearchException(
        'Could not reach Open Food Facts. Check your connection.',
      );
    } on FormatException {
      throw const FoodSearchException(
        'Unexpected response from Open Food Facts.',
      );
    }
  }
}

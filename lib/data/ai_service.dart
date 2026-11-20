import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

enum AiProvider {
  gemini('Gemini', 'gemini-2.5-flash'),
  groq('Groq', 'llama-3.3-70b-versatile');

  const AiProvider(this.label, this.defaultModel);
  final String label;
  final String defaultModel;
}

class AiException implements Exception {
  const AiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Calls the free tiers of Google Gemini (AI Studio key) or Groq (OpenAI-
/// compatible API) with plain HTTP. Model names change over time, so the
/// model is a setting, not hard-coded.
class AiService {
  AiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<String> generate({
    required AiProvider provider,
    required String model,
    required String apiKey,
    required String system,
    required String prompt,
    double temperature = 0.7,
  }) {
    switch (provider) {
      case AiProvider.gemini:
        return _gemini(model, apiKey, system, prompt, temperature);
      case AiProvider.groq:
        return _groq(model, apiKey, system, prompt, temperature);
    }
  }

  Future<String> _gemini(
    String model,
    String apiKey,
    String system,
    String prompt,
    double temperature,
  ) async {
    final name = model.trim().replaceFirst(RegExp(r'^models/'), '');
    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$name:generateContent',
    );
    final json = await _post(
      uri,
      {'x-goog-api-key': apiKey, 'Content-Type': 'application/json'},
      jsonEncode({
        'systemInstruction': {
          'parts': [
            {'text': system},
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        // Generous limit: some Gemini models spend part of it on "thinking".
        'generationConfig': {
          'temperature': temperature,
          'maxOutputTokens': 1200,
        },
      }),
      name,
    );

    final buffer = StringBuffer();
    final candidates = json['candidates'];
    if (candidates is List && candidates.isNotEmpty) {
      final first = candidates.first;
      if (first is Map) {
        final content = first['content'];
        if (content is Map) {
          final parts = content['parts'];
          if (parts is List) {
            for (final p in parts) {
              if (p is Map && p['text'] is String) buffer.write(p['text']);
            }
          }
        }
      }
    }
    final out = buffer.toString().trim();
    if (out.isEmpty) {
      final feedback = json['promptFeedback'];
      if (feedback is Map && feedback['blockReason'] != null) {
        throw const AiException('The AI declined to answer this request.');
      }
      throw const AiException(
        'The AI returned no text. Try again, or pick another model.',
      );
    }
    return out;
  }

  Future<String> _groq(
    String model,
    String apiKey,
    String system,
    String prompt,
    double temperature,
  ) async {
    final name = model.trim();
    final json = await _post(
      Uri.https('api.groq.com', '/openai/v1/chat/completions'),
      {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      jsonEncode({
        'model': name,
        'messages': [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': prompt},
        ],
        'temperature': temperature,
        'max_tokens': 600,
      }),
      name,
    );

    final choices = json['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map) {
        final message = first['message'];
        if (message is Map && message['content'] is String) {
          final out = (message['content'] as String).trim();
          if (out.isNotEmpty) return out;
        }
      }
    }
    throw const AiException(
      'The AI returned no text. Try again, or pick another model.',
    );
  }

  Future<Map<String, dynamic>> _post(
    Uri uri,
    Map<String, String> headers,
    String body,
    String model,
  ) async {
    try {
      final res = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 40));
      if (res.statusCode != 200) {
        throw AiException(_describe(res.statusCode, res.body, model));
      }
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const AiException('Unexpected response from the AI service.');
      }
      return decoded;
    } on TimeoutException {
      throw const AiException('The AI took too long to answer. Try again.');
    } on SocketException {
      throw const AiException(
        'Could not reach the AI service. Check your connection.',
      );
    } on http.ClientException {
      throw const AiException(
        'Could not reach the AI service. Check your connection.',
      );
    } on FormatException {
      throw const AiException('Unexpected response from the AI service.');
    }
  }

  String _describe(int status, String body, String model) {
    String? detail;
    try {
      final j = jsonDecode(body);
      if (j is Map && j['error'] is Map) {
        final m = (j['error'] as Map)['message'];
        if (m is String) {
          detail = m.length > 160 ? '${m.substring(0, 160)}...' : m;
        }
      }
    } catch (_) {}

    switch (status) {
      case 400:
        if ((detail ?? '').toLowerCase().contains('api key')) {
          return 'Your API key was rejected. Check it in Settings.';
        }
        return 'The AI service rejected the request. ${detail ?? ''}'.trim();
      case 401:
      case 403:
        return 'Your API key was rejected or is not allowed to use this '
            'model. Check it in Settings.';
      case 404:
        return 'Model "$model" was not found. Change the model name in '
            'Settings.';
      case 429:
        return 'Free-tier limit reached. Try again in a minute, or tomorrow '
            'if the daily limit is used up.';
      default:
        if (status >= 500) {
          return 'The AI service is busy right now. Try again soon.';
        }
        return 'AI error (HTTP $status). ${detail ?? ''}'.trim();
    }
  }

  void dispose() => _client.close();
}

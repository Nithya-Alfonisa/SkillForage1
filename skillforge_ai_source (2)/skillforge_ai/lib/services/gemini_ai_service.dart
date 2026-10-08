import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/learning_state.dart';
import '../models/quiz_result.dart';
import 'ai_service.dart';

/// Builds the structured prompt sent to Gemini.
String buildRecommendationPrompt(
  LearningState s,
  List<QuizResult> recent,
) {
  String list(List<String> v) => v.isEmpty ? 'none yet' : v.join(', ');
  final quizzes = recent.isEmpty
      ? 'no quizzes taken yet'
      : recent
          .map((r) => '${r.topic}: ${r.correct}/${r.total} (${r.percent}%)')
          .join('; ');
  return 'You are an encouraging technical tutor inside a learning app.\n'
      'Learner profile:\n'
      '- Skill: ${s.skill}\n'
      '- Current topic: ${s.currentTopic}\n'
      '- Mastery: ${s.masteryPercent}%\n'
      '- Difficulty: ${s.difficulty}\n'
      '- Strengths: ${list(s.strengths)}\n'
      '- Weaknesses: ${list(s.weaknesses)}\n'
      '- Recent quiz performance: $quizzes\n\n'
      'Write the single best next learning step in at most two short '
      'sentences. Plain text only, no markdown, no lists.';
}

/// Gemini implementation of [AIService], calling the Generative Language REST
/// API directly over HTTPS.
///
/// The key is never stored in source: pass it at build time with
/// `--dart-define=GEMINI_API_KEY=...`. The model can be overridden with
/// `--dart-define=GEMINI_MODEL=...`.
class GeminiAIService implements AIService {
  GeminiAIService({
    String? apiKey,
    String? model,
    http.Client? client,
    this.timeout = const Duration(seconds: 12),
  })  : apiKey = apiKey ?? _envKey,
        model = model ?? (_envModel.isEmpty ? defaultModel : _envModel),
        _client = client ?? http.Client();

  static const String _envKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _envModel = String.fromEnvironment('GEMINI_MODEL');

  /// Verify this against Google's current model list before release.
  static const String defaultModel = 'gemini-2.5-flash';

  final String apiKey;
  final String model;
  final Duration timeout;
  final http.Client _client;

  @override
  bool get isConfigured => apiKey.trim().isNotEmpty;

  @override
  Future<String> getRecommendation(
    LearningState state, {
    List<QuizResult> recent = const [],
  }) async {
    if (!isConfigured) {
      throw const AIUnavailableException('No Gemini API key configured');
    }
    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$model:generateContent',
    );
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': buildRecommendationPrompt(state, recent)},
          ],
        },
      ],
      'generationConfig': {'temperature': 0.4, 'maxOutputTokens': 1024},
    });

    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': apiKey,
            },
            body: body,
          )
          .timeout(timeout);
      if (response.statusCode != 200) {
        throw AIUnavailableException('Gemini returned HTTP ${response.statusCode}');
      }
      return parseResponse(response.body);
    } on AIUnavailableException {
      rethrow;
    } on TimeoutException {
      throw const AIUnavailableException('Gemini request timed out');
    } catch (e) {
      throw AIUnavailableException('Gemini request failed: ${e.runtimeType}');
    }
  }

  /// Extracts and validates the text of a `generateContent` response.
  static String parseResponse(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List<dynamic>;
      final content = (candidates.first as Map<String, dynamic>)['content']
          as Map<String, dynamic>;
      final parts = content['parts'] as List<dynamic>;
      final text = parts
          .map((p) => (p as Map<String, dynamic>)['text'] as String? ?? '')
          .join()
          .trim();
      if (text.length < 10) {
        throw const AIUnavailableException('Gemini returned an empty answer');
      }
      return text.length > 400 ? '${text.substring(0, 397)}...' : text;
    } on AIUnavailableException {
      rethrow;
    } catch (_) {
      throw const AIUnavailableException('Gemini returned an invalid response');
    }
  }
}

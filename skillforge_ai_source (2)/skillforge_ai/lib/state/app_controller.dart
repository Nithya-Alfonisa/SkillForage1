import 'package:flutter/foundation.dart';

import '../data/content_repository.dart';
import '../models/learning_state.dart';
import '../models/quiz_result.dart';
import '../services/adaptive_learning_service.dart';
import '../services/ai_service.dart';
import '../services/gemini_ai_service.dart';

enum RecommendationStatus { idle, loading, ai, fallback }

/// Single source of truth for the learner's state and the current
/// recommendation. Screens listen to it; business rules live in
/// [AdaptiveLearningService].
class AppController extends ChangeNotifier {
  AppController({
    AIService? ai,
    this.adaptive = const AdaptiveLearningService(),
  }) : ai = ai ?? GeminiAIService();

  final AIService ai;
  final AdaptiveLearningService adaptive;

  LearningState? state;
  final List<QuizResult> history = [];

  RecommendationStatus status = RecommendationStatus.idle;
  Recommendation? rule;
  String recommendationText = '';
  String? fallbackReason;
  int _token = 0;

  void startSkill(SkillInfo skill) {
    state = adaptive.initialState(skill);
    history.clear();
    refreshRecommendation();
  }

  void reset() {
    _token++;
    state = null;
    history.clear();
    rule = null;
    recommendationText = '';
    status = RecommendationStatus.idle;
    notifyListeners();
  }

  void selectTopic(String topic) {
    final s = state;
    if (s == null || s.currentTopic == topic) return;
    state = s.copyWith(currentTopic: topic);
    refreshRecommendation();
  }

  QuizResult submitQuiz({
    required String topic,
    required int correct,
    required int total,
  }) {
    final s = state!;
    final outcome = adaptive.applyQuizResult(
      s,
      topic: topic,
      correct: correct,
      total: total,
    );
    state = outcome.state;
    history.add(outcome.result);
    refreshRecommendation();
    return outcome.result;
  }

  /// Recomputes the rule-based recommendation immediately, then asks the AI
  /// service to phrase a better one. Any AI failure falls back silently to the
  /// rule-based text, so the app never depends on connectivity.
  Future<void> refreshRecommendation() async {
    final s = state;
    if (s == null) return;
    final token = ++_token;
    final r = adaptive.recommend(s);
    rule = r;
    recommendationText = r.message;
    fallbackReason = null;
    status = ai.isConfigured
        ? RecommendationStatus.loading
        : RecommendationStatus.fallback;
    if (!ai.isConfigured) fallbackReason = 'Gemini API key not configured';
    notifyListeners();
    if (!ai.isConfigured) return;

    try {
      final recent = history.length > 3
          ? history.sublist(history.length - 3)
          : List<QuizResult>.of(history);
      final text = await ai.getRecommendation(s, recent: recent);
      if (token != _token) return;
      recommendationText = text;
      status = RecommendationStatus.ai;
    } on AIUnavailableException catch (e) {
      if (token != _token) return;
      recommendationText = r.message;
      fallbackReason = e.message;
      status = RecommendationStatus.fallback;
    } catch (_) {
      if (token != _token) return;
      recommendationText = r.message;
      fallbackReason = 'Unexpected AI error';
      status = RecommendationStatus.fallback;
    }
    notifyListeners();
  }
}

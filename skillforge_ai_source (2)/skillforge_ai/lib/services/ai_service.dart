import '../models/learning_state.dart';
import '../models/quiz_result.dart';

/// Thrown by an [AIService] whenever it cannot produce a usable answer
/// (no key, offline, timeout, HTTP error, malformed or empty response).
class AIUnavailableException implements Exception {
  const AIUnavailableException(this.message);
  final String message;

  @override
  String toString() => 'AIUnavailableException: $message';
}

/// Abstraction over any recommendation provider. The UI and controller depend
/// only on this interface, so Gemini can be swapped for another provider or a
/// mock without touching the screens.
abstract class AIService {
  /// Whether the service has what it needs (e.g. an API key) to even try.
  bool get isConfigured;

  /// Returns a short natural-language recommendation, or throws
  /// [AIUnavailableException].
  Future<String> getRecommendation(
    LearningState state, {
    List<QuizResult> recent = const [],
  });
}

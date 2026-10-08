import '../data/content_repository.dart';
import '../models/learning_activity.dart';
import '../models/learning_state.dart';
import '../models/quiz_question.dart';
import '../models/quiz_result.dart';

/// A next-step suggestion produced by the rule-based engine.
class Recommendation {
  const Recommendation({required this.message, required this.activity});
  final String message;
  final LearningActivity activity;
}

/// Result of applying a finished quiz to a [LearningState].
class QuizOutcome {
  const QuizOutcome({required this.state, required this.result});
  final LearningState state;
  final QuizResult result;
}

/// Deterministic, rule-based adaptive engine. No randomness, no I/O: the same
/// inputs always produce the same outputs, which makes it unit-testable.
class AdaptiveLearningService {
  const AdaptiveLearningService();

  static const double lowMastery = 0.4;
  static const double highMastery = 0.7;
  static const double highScore = 0.8;
  static const double mediumScore = 0.5;
  static const int quizLength = 5;

  /// Difficulty implied by a mastery value alone.
  String difficultyForMastery(double mastery) {
    if (mastery < lowMastery) return 'Beginner';
    if (mastery < highMastery) return 'Intermediate';
    return 'Advanced';
  }

  LearningState initialState(SkillInfo skill) => LearningState(
        skill: skill.title,
        currentTopic: skill.topics.first,
        mastery: 0.2,
        difficulty: 'Beginner',
      );

  // ------------------------------------------------------------------ quiz

  /// Picks up to [count] questions for [topic], nearest to [difficulty] first.
  /// Ties keep the authored order, so the result is fully deterministic.
  List<QuizQuestion> selectQuestions(String topic, String difficulty,
      {int count = quizLength}) {
    final all = ContentRepository.questionsFor(topic);
    final target = Difficulty.indexOf(difficulty);
    final indexed = [for (var i = 0; i < all.length; i++) (i, all[i])];
    indexed.sort((x, y) {
      final dx = (Difficulty.indexOf(x.$2.difficulty) - target).abs();
      final dy = (Difficulty.indexOf(y.$2.difficulty) - target).abs();
      return dx != dy ? dx.compareTo(dy) : x.$1.compareTo(y.$1);
    });
    final picked = indexed.take(count).map((e) => e.$2).toList();
    // Present easier questions first within the chosen set.
    final order = {for (var i = 0; i < all.length; i++) all[i]: i};
    picked.sort((a, b) {
      final d = Difficulty.indexOf(a.difficulty)
          .compareTo(Difficulty.indexOf(b.difficulty));
      return d != 0 ? d : order[a]!.compareTo(order[b]!);
    });
    return picked;
  }

  /// Applies a finished quiz to [state] and returns the updated state plus a
  /// summary of what changed.
  QuizOutcome applyQuizResult(
    LearningState state, {
    required String topic,
    required int correct,
    required int total,
  }) {
    final pct = total == 0 ? 0.0 : correct / total;

    // 1. Mastery
    final double delta;
    if (pct >= highScore) {
      delta = 0.20;
    } else if (pct >= mediumScore) {
      delta = 0.08;
    } else {
      delta = -0.05;
    }
    final mastery = _round2((state.mastery + delta).clamp(0.0, 1.0).toDouble());

    // 2. Score history for the topic
    final history = [...(state.topicScores[topic] ?? const <double>[]), pct];
    final scores = Map<String, List<double>>.from(state.topicScores)
      ..[topic] = history;

    // 3. Strengths / weaknesses
    final strengths = [...state.strengths];
    final weaknesses = [...state.weaknesses];
    final repeatedlyWeak = history.length >= 2 &&
        history[history.length - 1] < 0.7 &&
        history[history.length - 2] < 0.7;
    if (pct >= highScore) {
      weaknesses.remove(topic);
      if (!strengths.contains(topic)) strengths.add(topic);
    } else if (pct < mediumScore || repeatedlyWeak) {
      strengths.remove(topic);
      if (!weaknesses.contains(topic)) weaknesses.add(topic);
    }

    // 4. Difficulty
    final prev = Difficulty.indexOf(state.difficulty);
    final derived = Difficulty.indexOf(difficultyForMastery(mastery));
    final int next;
    if (pct >= highScore) {
      next = derived > prev + 1 ? derived : prev + 1; // always step up
    } else if (pct < mediumScore) {
      next = derived < prev - 1 ? derived : prev - 1; // always step down
    } else {
      next = prev; // maintain
    }
    final difficulty = Difficulty.at(next);

    // 5. Topic progression: advance only after a strong score.
    var currentTopic = topic;
    if (pct >= highScore) {
      final skill = ContentRepository.skillByTitle(state.skill);
      currentTopic = skill.nextTopic(topic) ?? topic;
    }

    final updated = state.copyWith(
      currentTopic: currentTopic,
      mastery: mastery,
      difficulty: difficulty,
      strengths: strengths,
      weaknesses: weaknesses,
      topicScores: scores,
    );
    final result = QuizResult(
      topic: topic,
      correct: correct,
      total: total,
      masteryBefore: state.mastery,
      masteryAfter: mastery,
      difficultyBefore: state.difficulty,
      difficultyAfter: difficulty,
    );
    return QuizOutcome(state: updated, result: result);
  }

  // -------------------------------------------------------- recommendations

  /// Decides the next activity and a plain-language explanation. Used both as
  /// the primary recommendation engine and as the offline fallback when the
  /// AI service is unavailable.
  Recommendation recommend(LearningState s) {
    final skill = ContentRepository.skillByTitle(s.skill);
    final weak = s.weaknesses.isEmpty ? null : s.weaknesses.first;
    final pct = s.masteryPercent;

    if (s.mastery < lowMastery) {
      final topic = weak ?? s.currentTopic;
      final activity = ContentRepository.learnActivity(topic, 'Beginner');
      final message = weak != null
          ? 'You are finding $weak difficult (mastery $pct%). Revise it with '
              '"${activity.title}", then retry the quiz.'
          : 'Your mastery is $pct%. Start with "${activity.title}" to build a '
              'solid foundation in $topic.';
      return Recommendation(message: message, activity: activity);
    }

    if (s.mastery < highMastery) {
      final activity =
          ContentRepository.quizActivity(s.currentTopic, s.difficulty);
      final message = weak != null
          ? 'Good progress ($pct%). Practise ${s.currentTopic} with a '
              '${s.difficulty} quiz, and revisit $weak when you can.'
          : 'Good progress ($pct%). Practise ${s.currentTopic} with a '
              '${s.difficulty} quiz to move towards Advanced.';
      return Recommendation(message: message, activity: activity);
    }

    final next = skill.nextTopic(s.currentTopic);
    if (s.strengths.contains(s.currentTopic) && next != null) {
      final activity = ContentRepository.quizActivity(next, s.difficulty);
      return Recommendation(
        message: 'Excellent ($pct%). You have mastered ${s.currentTopic}; '
            'take on a challenging $next quiz next.',
        activity: activity,
      );
    }
    final activity = ContentRepository.quizActivity(s.currentTopic, s.difficulty);
    return Recommendation(
      message: 'Excellent ($pct%). Try the Advanced ${s.currentTopic} '
          'questions to lock in your skills.',
      activity: activity,
    );
  }

  // ---------------------------------------------------------- result wording

  String performanceHeadline(QuizResult r) {
    final score = '${r.correct}/${r.total}';
    if (r.percentage >= highScore) return 'Great job! You scored $score.';
    if (r.percentage >= mediumScore) return 'Good effort! You scored $score.';
    return 'Keep going! You scored $score.';
  }

  String performanceDetail(QuizResult r) {
    if (r.percentage >= highScore) {
      return 'Your ${r.topic} fundamentals are strong. Mastery and difficulty '
          'have both stepped up.';
    }
    if (r.percentage >= mediumScore) {
      return 'You are getting there with ${r.topic}. Mastery rose a little and '
          'the difficulty stays the same.';
    }
    return '${r.topic} needs more revision. It has been added to your '
        'weaknesses and the difficulty has been eased.';
  }

  double _round2(double v) => (v * 100).round() / 100;
}

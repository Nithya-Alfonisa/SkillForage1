import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:skillforge_ai/data/content_repository.dart';
import 'package:skillforge_ai/models/learning_state.dart';
import 'package:skillforge_ai/models/quiz_result.dart';
import 'package:skillforge_ai/services/adaptive_learning_service.dart';
import 'package:skillforge_ai/services/ai_service.dart';
import 'package:skillforge_ai/services/gemini_ai_service.dart';
import 'package:skillforge_ai/services/join_engine.dart';
import 'package:skillforge_ai/services/quiz_session.dart';
import 'package:skillforge_ai/state/app_controller.dart';

class _FailingAI implements AIService {
  @override
  bool get isConfigured => true;

  @override
  Future<String> getRecommendation(LearningState state,
          {List<QuizResult> recent = const []}) async =>
      throw const AIUnavailableException('offline');
}

class _WorkingAI implements AIService {
  @override
  bool get isConfigured => true;

  @override
  Future<String> getRecommendation(LearningState state,
          {List<QuizResult> recent = const []}) async =>
      'Try a LEFT JOIN comparison exercise next.';
}

void main() {
  const engine = AdaptiveLearningService();

  LearningState base({double mastery = 0.2, String difficulty = 'Beginner'}) =>
      LearningState(
        skill: ContentRepository.sqlSkill,
        currentTopic: ContentRepository.joinsTopic,
        mastery: mastery,
        difficulty: difficulty,
      );

  group('LearningState', () {
    test('is created with the given values and sane defaults', () {
      final s = LearningState(skill: 'Python Core', currentTopic: 'Variables');
      expect(s.skill, 'Python Core');
      expect(s.currentTopic, 'Variables');
      expect(s.mastery, 0.0);
      expect(s.difficulty, 'Beginner');
      expect(s.strengths, isEmpty);
      expect(s.weaknesses, isEmpty);
    });

    test('clamps mastery into 0.0 - 1.0', () {
      expect(base(mastery: 1.7).mastery, 1.0);
      expect(base(mastery: -0.3).mastery, 0.0);
    });
  });

  group('Mastery update', () {
    test('high score raises mastery by 0.20', () {
      final o = engine.applyQuizResult(base(), topic: 'SQL JOINs', correct: 5, total: 5);
      expect(o.state.mastery, 0.4);
      expect(o.result.masteryBefore, 0.2);
      expect(o.result.masteryAfter, 0.4);
    });

    test('medium score raises mastery by 0.08', () {
      final o = engine.applyQuizResult(base(), topic: 'SQL JOINs', correct: 3, total: 5);
      expect(o.state.mastery, 0.28);
    });

    test('low score lowers mastery but never below zero', () {
      final o = engine.applyQuizResult(base(mastery: 0.02),
          topic: 'SQL JOINs', correct: 1, total: 5);
      expect(o.state.mastery, 0.0);
    });
  });

  group('Adaptive difficulty', () {
    test('difficultyForMastery follows the thresholds', () {
      expect(engine.difficultyForMastery(0.39), 'Beginner');
      expect(engine.difficultyForMastery(0.4), 'Intermediate');
      expect(engine.difficultyForMastery(0.69), 'Intermediate');
      expect(engine.difficultyForMastery(0.7), 'Advanced');
    });

    test('score >= 80% steps difficulty up', () {
      final o = engine.applyQuizResult(base(), topic: 'SQL JOINs', correct: 4, total: 5);
      expect(o.state.difficulty, 'Intermediate');
    });

    test('score 50-79% keeps difficulty', () {
      final o = engine.applyQuizResult(base(difficulty: 'Intermediate', mastery: 0.5),
          topic: 'SQL JOINs', correct: 3, total: 5);
      expect(o.state.difficulty, 'Intermediate');
    });

    test('score < 50% steps difficulty down', () {
      final o = engine.applyQuizResult(base(difficulty: 'Intermediate', mastery: 0.5),
          topic: 'SQL JOINs', correct: 1, total: 5);
      expect(o.state.difficulty, 'Beginner');
    });
  });

  group('Weakness and strength detection', () {
    test('a low score adds the topic to weaknesses', () {
      final o = engine.applyQuizResult(base(), topic: 'SQL JOINs', correct: 1, total: 5);
      expect(o.state.weaknesses, contains('SQL JOINs'));
      expect(o.state.strengths, isEmpty);
    });

    test('two consecutive mediocre scores are flagged as a weakness', () {
      final first = engine.applyQuizResult(base(), topic: 'SQL JOINs', correct: 3, total: 5);
      expect(first.state.weaknesses, isEmpty);
      final second =
          engine.applyQuizResult(first.state, topic: 'SQL JOINs', correct: 3, total: 5);
      expect(second.state.weaknesses, contains('SQL JOINs'));
    });

    test('a high score adds a strength, removes the weakness and advances topic', () {
      final weak = engine.applyQuizResult(base(), topic: 'SQL JOINs', correct: 0, total: 5);
      final strong =
          engine.applyQuizResult(weak.state, topic: 'SQL JOINs', correct: 5, total: 5);
      expect(strong.state.strengths, contains('SQL JOINs'));
      expect(strong.state.weaknesses, isNot(contains('SQL JOINs')));
      expect(strong.state.currentTopic, 'Filtering & Aggregation');
    });
  });

  group('Recommendations', () {
    test('mastery < 0.4 recommends a revision activity on the weakness', () {
      final s = base().copyWith(weaknesses: ['SQL JOINs']);
      final r = engine.recommend(s);
      expect(r.activity.type.name, 'visual');
      expect(r.message, contains('SQL JOINs'));
    });

    test('mastery 0.4 - 0.7 recommends practice questions', () {
      final r = engine.recommend(base(mastery: 0.5, difficulty: 'Intermediate'));
      expect(r.activity.type.name, 'quiz');
      expect(r.activity.difficulty, 'Intermediate');
    });

    test('mastery >= 0.7 with a strength recommends the next topic', () {
      final s = base(mastery: 0.8, difficulty: 'Advanced')
          .copyWith(strengths: ['SQL JOINs']);
      final r = engine.recommend(s);
      expect(r.activity.topic, 'Filtering & Aggregation');
      expect(r.activity.difficulty, 'Advanced');
    });

    test('is deterministic', () {
      final s = base(mastery: 0.55, difficulty: 'Intermediate');
      expect(engine.recommend(s).message, engine.recommend(s).message);
    });

    test('works for every skill', () {
      for (final skill in ContentRepository.skills) {
        final s = engine.initialState(skill);
        expect(engine.recommend(s).message, isNotEmpty);
        expect(engine.selectQuestions(skill.topics.first, s.difficulty), isNotEmpty);
        expect(ContentRepository.lessonFor(skill.topics.first) != null ||
            ContentRepository.hasVisualizer(skill.topics.first), isTrue);
      }
    });
  });

  group('Quiz scoring', () {
    test('QuizSession counts correct and incorrect answers', () {
      final qs = engine.selectQuestions('SQL JOINs', 'Beginner');
      final session = QuizSession(qs);
      expect(session.total, qs.length);
      for (var i = 0; i < qs.length; i++) {
        final wrong = (session.current.correctIndex + 1) % 4;
        session.select(i.isEven ? session.current.correctIndex : wrong);
        // A second tap on the same question must not change the score.
        session.select(session.current.correctIndex);
        session.next();
      }
      expect(session.answeredCount, qs.length);
      expect(session.correct, (qs.length / 2).ceil());
      expect(session.incorrect, qs.length - session.correct);
    });

    test('next() does nothing until the question is answered', () {
      final session = QuizSession(engine.selectQuestions('SQL JOINs', 'Beginner'));
      session.next();
      expect(session.index, 0);
    });

    test('question selection is ordered by closeness to difficulty', () {
      final qs = engine.selectQuestions('SQL JOINs', 'Advanced', count: 3);
      expect(qs.every((q) => q.difficulty == 'Advanced'), isTrue);
    });

    test('every question has 4 options and a valid answer', () {
      for (final skill in ContentRepository.skills) {
        for (final topic in skill.topics) {
          final qs = ContentRepository.questionsFor(topic);
          expect(qs, isNotEmpty, reason: topic);
          for (final q in qs) {
            expect(q.options.length, 4);
            expect(q.correctIndex, inInclusiveRange(0, 3));
            expect(q.explanation, isNotEmpty);
          }
        }
      }
    });
  });

  group('JOIN logic', () {
    test('INNER JOIN returns only matching rows', () {
      final rows = JoinEngine.inner(JoinData.students, JoinData.courses);
      expect(rows.map((r) => r.student!.name), ['Arun', 'Priya']);
      expect(rows.map((r) => r.course!.title), ['SQL', 'Python']);
      expect(rows.every((r) => r.matched), isTrue);
    });

    test('LEFT JOIN keeps every student and nulls the unmatched course', () {
      final rows = JoinEngine.leftJoin(JoinData.students, JoinData.courses);
      expect(rows.length, 3);
      final rahul = rows.last;
      expect(rahul.student!.name, 'Rahul');
      expect(rahul.course, isNull);
      expect(rows.where((r) => r.matched).length, 2);
    });

    test('generates the expected SQL', () {
      expect(JoinEngine.sql(JoinType.inner), contains('INNER JOIN Courses'));
      expect(JoinEngine.sql(JoinType.left), contains('LEFT JOIN Courses'));
    });
  });

  group('AI fallback', () {
    test('Gemini without a key throws AIUnavailableException', () async {
      final ai = GeminiAIService(apiKey: '');
      expect(ai.isConfigured, isFalse);
      await expectLater(
          ai.getRecommendation(base()), throwsA(isA<AIUnavailableException>()));
    });

    test('Gemini maps HTTP errors to AIUnavailableException', () async {
      final ai = GeminiAIService(
        apiKey: 'test-key',
        client: MockClient((_) async => http.Response('boom', 500)),
      );
      await expectLater(
          ai.getRecommendation(base()), throwsA(isA<AIUnavailableException>()));
    });

    test('Gemini maps invalid JSON to AIUnavailableException', () async {
      final ai = GeminiAIService(
        apiKey: 'test-key',
        client: MockClient((_) async => http.Response('not json', 200)),
      );
      await expectLater(
          ai.getRecommendation(base()), throwsA(isA<AIUnavailableException>()));
    });

    test('Gemini maps network exceptions to AIUnavailableException', () async {
      final ai = GeminiAIService(
        apiKey: 'test-key',
        client: MockClient((_) async => throw http.ClientException('no network')),
      );
      await expectLater(
          ai.getRecommendation(base()), throwsA(isA<AIUnavailableException>()));
    });

    test('Gemini parses a well-formed response', () async {
      const body =
          '{"candidates":[{"content":{"parts":[{"text":"Practise LEFT JOIN next."}]}}]}';
      final ai = GeminiAIService(
        apiKey: 'test-key',
        client: MockClient((_) async => http.Response(body, 200)),
      );
      expect(await ai.getRecommendation(base()), 'Practise LEFT JOIN next.');
    });

    test('prompt contains the structured learner state', () {
      final prompt = buildRecommendationPrompt(
        base(mastery: 0.62, difficulty: 'Intermediate')
            .copyWith(strengths: ['SQL JOINs'], weaknesses: ['Filtering & Aggregation']),
        const [],
      );
      expect(prompt, contains('SQL & Databases'));
      expect(prompt, contains('62%'));
      expect(prompt, contains('Intermediate'));
      expect(prompt, contains('Filtering & Aggregation'));
    });

    test('controller falls back to the rule engine when the AI fails', () async {
      final c = AppController(ai: _FailingAI());
      c.startSkill(ContentRepository.skills.first);
      await pumpEventQueue();
      expect(c.status, RecommendationStatus.fallback);
      expect(c.recommendationText, c.rule!.message);
      expect(c.recommendationText, isNotEmpty);
    });

    test('controller uses the AI text when the AI succeeds', () async {
      final c = AppController(ai: _WorkingAI());
      c.startSkill(ContentRepository.skills.first);
      await pumpEventQueue();
      expect(c.status, RecommendationStatus.ai);
      expect(c.recommendationText, 'Try a LEFT JOIN comparison exercise next.');
    });

    test('controller works with no AI key at all', () {
      final c = AppController(ai: GeminiAIService(apiKey: ''));
      c.startSkill(ContentRepository.skills.first);
      expect(c.status, RecommendationStatus.fallback);
      expect(c.recommendationText, isNotEmpty);
    });
  });
}

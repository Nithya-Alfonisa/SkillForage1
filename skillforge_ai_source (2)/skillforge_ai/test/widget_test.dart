import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillforge_ai/main.dart';
import 'package:skillforge_ai/models/learning_state.dart';
import 'package:skillforge_ai/models/quiz_result.dart';
import 'package:skillforge_ai/services/ai_service.dart';
import 'package:skillforge_ai/state/app_controller.dart';

class _OfflineAI implements AIService {
  @override
  bool get isConfigured => false;

  @override
  Future<String> getRecommendation(LearningState state,
          {List<QuizResult> recent = const []}) async =>
      throw const AIUnavailableException('offline');
}

Future<AppController> _openWorkspace(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(412, 915));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final controller = AppController(ai: _OfflineAI());
  await tester.pumpWidget(SkillForgeApp(controller: controller));
  await tester.tap(find.text('SQL & Databases'));
  await tester.pump();
  await tester.tap(find.text('Start Learning'));
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  testWidgets('onboarding shows three goals and gates the CTA', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(SkillForgeApp(controller: AppController(ai: _OfflineAI())));

    expect(find.text('Choose Your Learning Path'), findsOneWidget);
    expect(find.text('SQL & Databases'), findsOneWidget);
    expect(find.text('Python Core'), findsOneWidget);
    expect(find.text('Data Structures'), findsOneWidget);

    final button = tester.widget<FilledButton>(
        find.byWidgetPredicate((w) => w is FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('selecting a goal opens the workspace with that skill', (tester) async {
    final controller = await _openWorkspace(tester);
    expect(find.text('Welcome back!'), findsOneWidget);
    expect(controller.state!.skill, 'SQL & Databases');
    expect(find.text('Your current focus'), findsOneWidget);
    expect(find.text('AI recommendation'), findsOneWidget);
    expect(find.text('Offline engine'), findsOneWidget);
  });

  testWidgets('visualizer switches between INNER and LEFT JOIN', (tester) async {
    await _openWorkspace(tester);
    final open = find.byKey(const Key('open-visualizer'));
    await tester.scrollUntilVisible(open, 300,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(open);
    await tester.pumpAndSettle();

    expect(find.text('SQL JOIN Visualizer'), findsOneWidget);
    expect(find.text('NULL'), findsNothing); // INNER JOIN: no NULL cells

    await tester.tap(find.text('LEFT JOIN'));
    await tester.pumpAndSettle();
    final nullCell = find.text('NULL');
    await tester.scrollUntilVisible(nullCell, 300,
        scrollable: find.byType(Scrollable).first);
    expect(nullCell, findsWidgets);
    final sql = find.textContaining('LEFT JOIN Courses');
    await tester.scrollUntilVisible(sql, 300,
        scrollable: find.byType(Scrollable).first);
    expect(sql, findsOneWidget);
  });

  testWidgets('quiz flow updates mastery and shows results', (tester) async {
    final controller = await _openWorkspace(tester);
    final quick = find.byKey(const Key('quick-quiz'));
    await tester.scrollUntilVisible(quick, 300,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(quick);
    await tester.pumpAndSettle();

    final questions = controller.adaptive
        .selectQuestions(controller.state!.currentTopic, controller.state!.difficulty);
    for (var i = 0; i < questions.length; i++) {
      final answer = find.text(questions[i].correctAnswer);
      await tester.ensureVisible(answer);
      await tester.pump();
      await tester.tap(answer);
      await tester.pumpAndSettle();
      expect(find.text('Correct!'), findsOneWidget);

      final next = find.text(i == questions.length - 1 ? 'See results' : 'Next question');
      await tester.ensureVisible(next);
      await tester.pump();
      await tester.tap(next);
      await tester.pumpAndSettle();
    }

    expect(find.text('Quiz results'), findsOneWidget);
    expect(find.text('Great job! You scored 5/5.'), findsOneWidget);
    expect(controller.state!.mastery, 0.4);
    expect(controller.state!.difficulty, 'Intermediate');
    expect(controller.state!.strengths, contains('SQL JOINs'));
  });
}

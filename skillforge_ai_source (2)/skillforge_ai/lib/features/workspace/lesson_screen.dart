import 'package:flutter/material.dart';

import '../../data/content_repository.dart';
import '../../state/app_controller.dart';
import '../../widgets/common.dart';
import '../quiz/quiz_screen.dart';

/// Short built-in lesson used for topics that don't have a visualizer.
class LessonScreen extends StatelessWidget {
  const LessonScreen({super.key, required this.controller, required this.topic});
  final AppController controller;
  final String topic;

  @override
  Widget build(BuildContext context) {
    final lesson = ContentRepository.lessonFor(topic);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (lesson == null) {
      return Scaffold(
        appBar: AppBar(title: Text(topic)),
        body: EmptyState(
          icon: Icons.menu_book_rounded,
          title: 'No lesson available',
          message: 'There is no built-in lesson for $topic yet. You can still take the quiz.',
          actionLabel: 'Back',
          onAction: () => Navigator.of(context).pop(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: SafeArea(
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              const SectionHeader('Key ideas'),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final p in lesson.points)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(Icons.check_circle_outline_rounded,
                                  size: 20, color: scheme.primary),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(p,
                                  style: theme.textTheme.bodyLarge
                                      ?.copyWith(height: 1.4)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SectionHeader('Example'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.inverseSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SelectableText(
                  lesson.code,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    height: 1.5,
                    color: scheme.onInverseSurface,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.quiz_rounded),
                label: const Text('Test yourself with a quiz'),
                onPressed: () {
                  final difficulty =
                      controller.state?.difficulty ?? 'Beginner';
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => QuizScreen(
                        controller: controller,
                        topic: topic,
                        difficulty: difficulty,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

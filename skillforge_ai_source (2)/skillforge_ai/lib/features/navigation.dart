import 'package:flutter/material.dart';

import '../models/learning_activity.dart';
import '../state/app_controller.dart';
import 'quiz/quiz_screen.dart';
import 'visualizer/visualizer_screen.dart';
import 'workspace/lesson_screen.dart';

/// Opens whichever screen implements the given activity.
void openActivity(
  BuildContext context,
  AppController controller,
  LearningActivity activity,
) {
  final Route<void> route;
  switch (activity.type) {
    case ActivityType.visual:
      route = MaterialPageRoute<void>(
        builder: (_) => VisualizerScreen(controller: controller),
      );
    case ActivityType.lesson:
      route = MaterialPageRoute<void>(
        builder: (_) =>
            LessonScreen(controller: controller, topic: activity.topic),
      );
    case ActivityType.quiz:
      route = MaterialPageRoute<void>(
        builder: (_) => QuizScreen(
          controller: controller,
          topic: activity.topic,
          difficulty: activity.difficulty,
        ),
      );
  }
  Navigator.of(context).push(route);
}

/// The kinds of learning activity SkillForge AI can recommend.
enum ActivityType { visual, quiz, lesson }

/// Helpers for the three difficulty levels used across the app.
class Difficulty {
  Difficulty._();

  static const List<String> levels = ['Beginner', 'Intermediate', 'Advanced'];

  static int indexOf(String difficulty) {
    final i = levels.indexOf(difficulty);
    return i < 0 ? 0 : i;
  }

  static String at(int index) =>
      levels[index.clamp(0, levels.length - 1).toInt()];
}

/// A single item in the learning workspace (a visualizer, lesson or quiz).
class LearningActivity {
  const LearningActivity({
    required this.title,
    required this.type,
    required this.topic,
    required this.difficulty,
    this.description,
  });

  final String title;
  final ActivityType type;
  final String topic;
  final String difficulty;
  final String? description;
}

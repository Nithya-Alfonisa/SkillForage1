/// Immutable snapshot of what the learner knows. Every adaptive decision in the
/// app is a pure function of this object.
class LearningState {
  LearningState({
    required this.skill,
    required this.currentTopic,
    List<String> weaknesses = const [],
    List<String> strengths = const [],
    double mastery = 0.0,
    this.difficulty = 'Beginner',
    Map<String, List<double>> topicScores = const {},
  })  : weaknesses = List.unmodifiable(weaknesses),
        strengths = List.unmodifiable(strengths),
        mastery = mastery.clamp(0.0, 1.0).toDouble(),
        topicScores = Map.unmodifiable(topicScores);

  final String skill;
  final String currentTopic;
  final List<String> weaknesses;
  final List<String> strengths;

  /// 0.0 – 1.0
  final double mastery;

  /// "Beginner", "Intermediate" or "Advanced".
  final String difficulty;

  /// Quiz score history (0.0 – 1.0 per attempt) for each topic.
  final Map<String, List<double>> topicScores;

  int get masteryPercent => (mastery * 100).round();

  LearningState copyWith({
    String? skill,
    String? currentTopic,
    List<String>? weaknesses,
    List<String>? strengths,
    double? mastery,
    String? difficulty,
    Map<String, List<double>>? topicScores,
  }) {
    return LearningState(
      skill: skill ?? this.skill,
      currentTopic: currentTopic ?? this.currentTopic,
      weaknesses: weaknesses ?? this.weaknesses,
      strengths: strengths ?? this.strengths,
      mastery: mastery ?? this.mastery,
      difficulty: difficulty ?? this.difficulty,
      topicScores: topicScores ?? this.topicScores,
    );
  }
}

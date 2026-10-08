/// The outcome of one completed quiz, including how it changed the learner.
class QuizResult {
  const QuizResult({
    required this.topic,
    required this.correct,
    required this.total,
    required this.masteryBefore,
    required this.masteryAfter,
    required this.difficultyBefore,
    required this.difficultyAfter,
  });

  final String topic;
  final int correct;
  final int total;
  final double masteryBefore;
  final double masteryAfter;
  final String difficultyBefore;
  final String difficultyAfter;

  int get incorrect => total - correct;
  double get percentage => total == 0 ? 0.0 : correct / total;
  int get percent => (percentage * 100).round();
}

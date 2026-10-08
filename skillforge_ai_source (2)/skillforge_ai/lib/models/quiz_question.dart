class QuizQuestion {
  QuizQuestion({
    required this.topic,
    required this.difficulty,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  })  : assert(options.length == 4, 'Every question needs exactly 4 options'),
        assert(correctIndex >= 0 && correctIndex < 4);

  final String topic;
  final String difficulty;
  final String text;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  String get correctAnswer => options[correctIndex];
}

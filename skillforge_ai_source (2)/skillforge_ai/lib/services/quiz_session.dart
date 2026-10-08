import '../models/quiz_question.dart';

/// Pure quiz progress / scoring logic, independent of any widget.
class QuizSession {
  QuizSession(List<QuizQuestion> questions)
      : questions = List.unmodifiable(questions);

  final List<QuizQuestion> questions;
  int _index = 0;
  int? _selected;
  int _correct = 0;

  int get total => questions.length;
  int get index => _index;
  QuizQuestion get current => questions[_index];
  int? get selected => _selected;
  bool get answered => _selected != null;
  bool get isLast => _index == questions.length - 1;
  int get correct => _correct;
  int get answeredCount => _index + (answered ? 1 : 0);
  int get incorrect => answeredCount - _correct;

  /// Records an answer. Returns whether it was correct; ignored if the current
  /// question was already answered.
  bool select(int option) {
    if (answered) return option == current.correctIndex;
    _selected = option;
    final ok = option == current.correctIndex;
    if (ok) _correct++;
    return ok;
  }

  /// Moves to the next question (no-op if unanswered or already last).
  void next() {
    if (!answered || isLast) return;
    _index++;
    _selected = null;
  }
}

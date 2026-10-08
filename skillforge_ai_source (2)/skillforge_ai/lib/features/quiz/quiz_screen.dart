import 'package:flutter/material.dart';

import '../../models/quiz_question.dart';
import '../../services/quiz_session.dart';
import '../../state/app_controller.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.controller,
    required this.topic,
    required this.difficulty,
  });

  final AppController controller;
  final String topic;
  final String difficulty;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final QuizSession _session;

  @override
  void initState() {
    super.initState();
    _session = QuizSession(
      widget.controller.adaptive.selectQuestions(widget.topic, widget.difficulty),
    );
  }

  Future<void> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave this quiz?'),
        content: const Text('Your progress in this quiz will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  void _advance() {
    if (!_session.answered) return;
    if (_session.isLast) {
      final result = widget.controller.submitQuiz(
        topic: widget.topic,
        correct: _session.correct,
        total: _session.total,
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) =>
              ResultScreen(controller: widget.controller, result: result),
        ),
      );
    } else {
      setState(_session.next);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_session.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.topic)),
        body: EmptyState(
          icon: Icons.quiz_outlined,
          title: 'No questions yet',
          message: 'There are no quiz questions for ${widget.topic}.',
          actionLabel: 'Back to workspace',
          onAction: () => Navigator.of(context).pop(),
        ),
      );
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final q = _session.current;
    final progress = (_session.index + (_session.answered ? 1 : 0)) / _session.total;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.topic),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Exit quiz',
            onPressed: _confirmExit,
          ),
        ),
        body: SafeArea(
          child: ContentWidth(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    children: [
                      Row(
                        children: [
                          Text(
                            'Question ${_session.index + 1} of ${_session.total}',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          _Pill(q.difficulty, scheme.secondaryContainer),
                          const SizedBox(width: 8),
                          _Pill('Score ${_session.correct}/${_session.answeredCount}',
                              scheme.primaryContainer),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: progress),
                          duration: const Duration(milliseconds: 400),
                          builder: (_, v, __) => LinearProgressIndicator(
                            value: v,
                            minHeight: 8,
                            backgroundColor: scheme.surfaceContainerHighest,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppCard(
                        child: Text(
                          q.text,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700, height: 1.3),
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (var i = 0; i < q.options.length; i++) _option(q, i),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        alignment: Alignment.topCenter,
                        child: _session.answered
                            ? _Feedback(
                                question: q,
                                correct: _session.selected == q.correctIndex,
                              )
                            : const SizedBox(width: double.infinity),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: FilledButton(
                    onPressed: _session.answered ? _advance : null,
                    child: Text(_session.isLast ? 'See results' : 'Next question'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _option(QuizQuestion q, int i) {
    final scheme = Theme.of(context).colorScheme;
    final answered = _session.answered;
    final selected = _session.selected == i;
    final isCorrect = i == q.correctIndex;

    Color bg = Colors.white;
    Color border = scheme.outlineVariant;
    Color fg = scheme.onSurface;
    IconData? icon;
    if (answered && isCorrect) {
      bg = AppColors.successBg;
      border = AppColors.success;
      fg = AppColors.success;
      icon = Icons.check_circle_rounded;
    } else if (answered && selected) {
      bg = AppColors.errorBg;
      border = AppColors.error;
      fg = AppColors.error;
      icon = Icons.cancel_rounded;
    } else if (answered) {
      fg = scheme.onSurfaceVariant;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        label: 'Option ${String.fromCharCode(65 + i)}: ${q.options[i]}',
        child: Material(
          color: bg,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: border,
              width: answered && (isCorrect || selected) ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: answered ? null : () => setState(() => _session.select(i)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: fg.withOpacity(0.12),
                    child: Text(
                      String.fromCharCode(65 + i),
                      style: TextStyle(
                          color: fg, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      q.options[i],
                      style: TextStyle(
                          fontSize: 16, color: fg, fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (icon != null) Icon(icon, color: fg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
        child: Text(label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
      );
}

class _Feedback extends StatelessWidget {
  const _Feedback({required this.question, required this.correct});
  final QuizQuestion question;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = correct ? AppColors.success : AppColors.error;
    final bg = correct ? AppColors.successBg : AppColors.errorBg;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            correct ? 'Correct!' : 'Not quite',
            style: theme.textTheme.titleMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w800),
          ),
          if (!correct) ...[
            const SizedBox(height: 4),
            Text('Correct answer: ${question.correctAnswer}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: color, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 8),
          Text(question.explanation,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
        ],
      ),
    );
  }
}

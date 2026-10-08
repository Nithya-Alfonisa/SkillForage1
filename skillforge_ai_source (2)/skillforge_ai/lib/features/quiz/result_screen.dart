import 'package:flutter/material.dart';

import '../../models/quiz_result.dart';
import '../../state/app_controller.dart';
import '../../theme.dart';
import '../../widgets/ai_banner.dart';
import '../../widgets/common.dart';
import '../navigation.dart';
import 'quiz_screen.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.controller, required this.result});
  final AppController controller;
  final QuizResult result;

  void _backToWorkspace(BuildContext context) =>
      Navigator.of(context).popUntil((route) => route.isFirst);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final adaptive = controller.adaptive;
    final good = result.percentage >= 0.8;
    final mid = result.percentage >= 0.5 && !good;
    final accent = good
        ? AppColors.success
        : mid
            ? AppColors.warning
            : AppColors.error;
    final difficultyChanged = result.difficultyBefore != result.difficultyAfter;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backToWorkspace(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quiz results'),
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Back to workspace',
            onPressed: () => _backToWorkspace(context),
          ),
        ),
        body: SafeArea(
          child: ContentWidth(
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final state = controller.state;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                  children: [
                    AppCard(
                      child: Column(
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: result.percentage),
                                  duration: const Duration(milliseconds: 900),
                                  curve: Curves.easeOutCubic,
                                  builder: (_, v, __) => SizedBox(
                                    width: 120,
                                    height: 120,
                                    child: CircularProgressIndicator(
                                      value: v,
                                      strokeWidth: 10,
                                      color: accent,
                                      backgroundColor:
                                          scheme.surfaceContainerHighest,
                                    ),
                                  ),
                                ),
                                Text('${result.percent}%',
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: accent)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(adaptive.performanceHeadline(result),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Text(adaptive.performanceDetail(result),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                  color: scheme.onSurfaceVariant, height: 1.4)),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: _Stat('Total', '${result.total}',
                                    scheme.surfaceContainerHighest, scheme.onSurface),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _Stat('Correct', '${result.correct}',
                                    AppColors.successBg, AppColors.success),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _Stat('Incorrect', '${result.incorrect}',
                                    AppColors.errorBg, AppColors.error),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SectionHeader('What changed'),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mastery: ${(result.masteryBefore * 100).round()}% → ${(result.masteryAfter * 100).round()}%',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          MasteryBar(
                            from: result.masteryBefore,
                            value: result.masteryAfter,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const Icon(Icons.speed_rounded, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  difficultyChanged
                                      ? 'Difficulty: ${result.difficultyBefore} → ${result.difficultyAfter}'
                                      : 'Difficulty stays at ${result.difficultyAfter}',
                                  style: theme.textTheme.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          if (state != null) ...[
                            const SizedBox(height: 16),
                            Text('Strengths',
                                style: theme.textTheme.labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            TagWrap(
                              items: state.strengths,
                              emptyText: 'None yet.',
                              background: AppColors.successBg,
                              foreground: AppColors.success,
                              icon: Icons.trending_up_rounded,
                            ),
                            const SizedBox(height: 14),
                            Text('Needs revision',
                                style: theme.textTheme.labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            TagWrap(
                              items: state.weaknesses,
                              emptyText: 'None flagged.',
                              background: AppColors.warningBg,
                              foreground: AppColors.warning,
                              icon: Icons.flag_rounded,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SectionHeader('Recommended next step'),
                    AiBanner(controller: controller),
                    const SizedBox(height: 20),
                    if (controller.rule != null)
                      FilledButton.icon(
                        icon: Icon(activityIcon(controller.rule!.activity.type)),
                        label: Text(controller.rule!.activity.title),
                        onPressed: () => openActivity(
                            context, controller, controller.rule!.activity),
                      ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('Retake quiz'),
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => QuizScreen(
                            controller: controller,
                            topic: result.topic,
                            difficulty:
                                state?.difficulty ?? result.difficultyAfter,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => _backToWorkspace(context),
                      child: const Text('Back to workspace'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.bg, this.fg);
  final String label;
  final String value;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Text(value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: fg, fontWeight: FontWeight.w800)),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: fg, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

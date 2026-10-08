import 'package:flutter/material.dart';

import '../../data/content_repository.dart';
import '../../models/learning_activity.dart';
import '../../models/learning_state.dart';
import '../../state/app_controller.dart';
import '../../theme.dart';
import '../../widgets/ai_banner.dart';
import '../../widgets/common.dart';
import '../navigation.dart';
import '../onboarding/onboarding_screen.dart';
import '../quiz/quiz_screen.dart';
import '../visualizer/visualizer_screen.dart';

class WorkspaceScreen extends StatelessWidget {
  const WorkspaceScreen({super.key, required this.controller});
  final AppController controller;

  void _changePath(BuildContext context) {
    controller.reset();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => OnboardingScreen(controller: controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final state = controller.state;
        if (state == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('SkillForge AI')),
            body: EmptyState(
              icon: Icons.route_rounded,
              title: 'No learning path selected',
              message: 'Choose a skill to start your adaptive learning journey.',
              actionLabel: 'Choose a path',
              onAction: () => _changePath(context),
            ),
          );
        }
        final skill = ContentRepository.skillByTitle(state.skill);
        final rec = controller.rule;
        return Scaffold(
          appBar: AppBar(
            title: const Text('SkillForge AI'),
            actions: [
              IconButton(
                tooltip: 'Change learning path',
                icon: const Icon(Icons.swap_horiz_rounded),
                onPressed: () => _changePath(context),
              ),
            ],
          ),
          body: SafeArea(
            child: ContentWidth(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                children: [
                  _HeroCard(state: state),
                  const SizedBox(height: 14),
                  AiBanner(controller: controller),
                  if (rec != null) ...[
                    const SectionHeader('Recommended for you'),
                    _ActivityCard(
                      activity: rec.activity,
                      highlighted: true,
                      buttonLabel: 'Continue Learning',
                      onTap: () =>
                          openActivity(context, controller, rec.activity),
                    ),
                  ],
                  const SectionHeader('Strengths & weaknesses'),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Strengths',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        TagWrap(
                          items: state.strengths,
                          emptyText: 'None yet - score 80% or more on a quiz.',
                          background: AppColors.successBg,
                          foreground: AppColors.success,
                          icon: Icons.trending_up_rounded,
                        ),
                        const SizedBox(height: 16),
                        Text('Needs revision',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        TagWrap(
                          items: state.weaknesses,
                          emptyText: 'None - nothing flagged for revision.',
                          background: AppColors.warningBg,
                          foreground: AppColors.warning,
                          icon: Icons.flag_rounded,
                        ),
                      ],
                    ),
                  ),
                  SectionHeader('Topics in ${skill.title}'),
                  AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        for (final topic in skill.topics)
                          _TopicTile(
                            topic: topic,
                            state: state,
                            onTap: () => controller.selectTopic(topic),
                          ),
                      ],
                    ),
                  ),
                  const SectionHeader('Activities for this topic'),
                  _ActivityCard(
                    activity: ContentRepository.learnActivity(
                        state.currentTopic, state.difficulty),
                    buttonLabel: 'Open',
                    onTap: () => openActivity(
                      context,
                      controller,
                      ContentRepository.learnActivity(
                          state.currentTopic, state.difficulty),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ActivityCard(
                    activity: ContentRepository.quizActivity(
                        state.currentTopic, state.difficulty),
                    buttonLabel: 'Start quiz',
                    onTap: () => openActivity(
                      context,
                      controller,
                      ContentRepository.quizActivity(
                          state.currentTopic, state.difficulty),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          key: const Key('quick-quiz'),
                          icon: const Icon(Icons.quiz_rounded),
                          label: const Text('Take Quiz'),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => QuizScreen(
                                controller: controller,
                                topic: state.currentTopic,
                                difficulty: state.difficulty,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (state.skill == ContentRepository.sqlSkill) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            key: const Key('open-visualizer'),
                            icon: const Icon(Icons.hub_rounded),
                            label: const Text('Visualizer'),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    VisualizerScreen(controller: controller),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (controller.history.isNotEmpty) ...[
                    const SectionHeader('Last quiz'),
                    _LastQuizCard(controller: controller),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.state});
  final LearningState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome back!',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(state.skill,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 18),
          Text('Your current focus',
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(state.currentTopic,
              style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700, color: scheme.primary)),
          const SizedBox(height: 18),
          Row(
            children: [
              Text('Mastery: ${state.masteryPercent}%',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Chip(
                avatar: const Icon(Icons.speed_rounded, size: 18),
                label: Text('Difficulty: ${state.difficulty}'),
                side: BorderSide.none,
                backgroundColor: scheme.secondaryContainer,
              ),
            ],
          ),
          const SizedBox(height: 8),
          MasteryBar(value: state.mastery),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.activity,
    required this.buttonLabel,
    required this.onTap,
    this.highlighted = false,
  });

  final LearningActivity activity;
  final String buttonLabel;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      borderColor: highlighted ? scheme.primary : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(activityIcon(activity.type), color: scheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(activity.title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (activity.description != null) ...[
            const SizedBox(height: 10),
            Text(activity.description!,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant, height: 1.35)),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _MiniChip(activityLabel(activity.type)),
              _MiniChip(activity.topic),
              _MiniChip(activity.difficulty),
            ],
          ),
          const SizedBox(height: 14),
          highlighted
              ? FilledButton(onPressed: onTap, child: Text(buttonLabel))
              : OutlinedButton(onPressed: onTap, child: Text(buttonLabel)),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
    );
  }
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({
    required this.topic,
    required this.state,
    required this.onTap,
  });

  final String topic;
  final LearningState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isCurrent = topic == state.currentTopic;
    final IconData icon;
    final Color color;
    final String status;
    if (state.strengths.contains(topic)) {
      icon = Icons.check_circle_rounded;
      color = AppColors.success;
      status = 'Strength';
    } else if (state.weaknesses.contains(topic)) {
      icon = Icons.flag_rounded;
      color = AppColors.warning;
      status = 'Revise';
    } else if (isCurrent) {
      icon = Icons.play_circle_rounded;
      color = scheme.primary;
      status = 'Current';
    } else {
      icon = Icons.circle_outlined;
      color = scheme.outline;
      status = 'Not started';
    }
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(topic,
          style: TextStyle(
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500)),
      subtitle: Text(status),
      trailing: isCurrent
          ? Icon(Icons.keyboard_arrow_right_rounded, color: scheme.primary)
          : null,
    );
  }
}

class _LastQuizCard extends StatelessWidget {
  const _LastQuizCard({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final r = controller.history.last;
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        children: [
          Icon(Icons.history_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${r.topic}: ${r.correct}/${r.total} (${r.percent}%)',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  'Mastery ${(r.masteryBefore * 100).round()}% → ${(r.masteryAfter * 100).round()}%'
                  ' · ${r.difficultyBefore} → ${r.difficultyAfter}',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

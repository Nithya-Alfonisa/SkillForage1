import 'package:flutter/material.dart';

import '../../data/content_repository.dart';
import '../../state/app_controller.dart';
import '../../widgets/common.dart';
import '../workspace/workspace_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  SkillInfo? _selected;

  void _start() {
    final skill = _selected;
    if (skill == null) return;
    widget.controller.startSkill(skill);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => WorkspaceScreen(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: ContentWidth(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.bolt_rounded,
                              color: scheme.onPrimary, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Text('SkillForge AI',
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Choose Your Learning Path',
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800, height: 1.15),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pick a skill and SkillForge adapts the lessons, quizzes and difficulty to how you perform.',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    for (final skill in ContentRepository.skills) ...[
                      _GoalCard(
                        skill: skill,
                        selected: _selected?.id == skill.id,
                        onTap: () => setState(() => _selected = skill),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: FilledButton.icon(
                  onPressed: _selected == null ? null : _start,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Start Learning'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.skill,
    required this.selected,
    required this.onTap,
  });

  final SkillInfo skill;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: '${skill.title}. ${skill.description}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: selected ? scheme.primary : scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      skill.icon,
                      size: 28,
                      color: selected ? scheme.onPrimary : scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(skill.title,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(skill.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant, height: 1.35)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked,
                      key: ValueKey(selected),
                      color: selected ? scheme.primary : scheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

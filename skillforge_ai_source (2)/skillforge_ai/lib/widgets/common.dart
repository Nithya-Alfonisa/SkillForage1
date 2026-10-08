import 'package:flutter/material.dart';

import '../models/learning_activity.dart';

/// Rounded, outlined surface used for every card in the app.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(18),
    this.borderColor,
  });

  final Widget child;
  final Color? color;
  final EdgeInsets padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color ?? Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor ?? scheme.outlineVariant),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Centres content and limits its width so it looks right on tablets too.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = 640});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

/// A wrap of chips, or a muted message when the list is empty.
class TagWrap extends StatelessWidget {
  const TagWrap({
    super.key,
    required this.items,
    required this.emptyText,
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final List<String> items;
  final String emptyText;
  final Color background;
  final Color foreground;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        emptyText,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in items)
          Chip(
            avatar: Icon(icon, size: 18, color: foreground),
            label: Text(t),
            backgroundColor: background,
            side: BorderSide.none,
            labelStyle: TextStyle(color: foreground, fontWeight: FontWeight.w600),
          ),
      ],
    );
  }
}

/// Animated mastery progress bar with a percentage label.
class MasteryBar extends StatelessWidget {
  const MasteryBar({super.key, required this.value, this.from, this.height = 12});
  final double value;
  final double? from;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: from ?? 0.0, end: value),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Semantics(
        label: 'Mastery ${(v * 100).round()} percent',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: LinearProgressIndicator(
            value: v,
            minHeight: height,
            backgroundColor: scheme.surfaceContainerHighest,
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

IconData activityIcon(ActivityType type) {
  switch (type) {
    case ActivityType.visual:
      return Icons.hub_rounded;
    case ActivityType.quiz:
      return Icons.quiz_rounded;
    case ActivityType.lesson:
      return Icons.menu_book_rounded;
  }
}

String activityLabel(ActivityType type) {
  switch (type) {
    case ActivityType.visual:
      return 'Visual';
    case ActivityType.quiz:
      return 'Quiz';
    case ActivityType.lesson:
      return 'Lesson';
  }
}

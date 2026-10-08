import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import 'common.dart';

/// Shows the current recommendation and where it came from (Gemini or the
/// built-in offline engine).
class AiBanner extends StatelessWidget {
  const AiBanner({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final status = controller.status;
    final loading = status == RecommendationStatus.loading;

    final String source;
    switch (status) {
      case RecommendationStatus.ai:
        source = 'Gemini';
      case RecommendationStatus.loading:
        source = 'Asking Gemini…';
      case RecommendationStatus.fallback:
        source = 'Offline engine';
      case RecommendationStatus.idle:
        source = '';
    }

    return AppCard(
      color: scheme.primaryContainer,
      borderColor: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: scheme.onPrimaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI recommendation',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (source.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(source,
                      style: theme.textTheme.labelMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
              if (status == RecommendationStatus.fallback &&
                  controller.ai.isConfigured)
                IconButton(
                  tooltip: 'Retry AI recommendation',
                  onPressed: controller.refreshRecommendation,
                  icon: Icon(Icons.refresh, color: scheme.onPrimaryContainer),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (controller.recommendationText.isEmpty)
            Text('Recommendation unavailable right now.',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: scheme.onPrimaryContainer))
          else
            Text(
              controller.recommendationText,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: scheme.onPrimaryContainer,
                height: 1.4,
              ),
            ),
          if (loading) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(minHeight: 4),
            ),
          ],
          if (status == RecommendationStatus.fallback &&
              controller.fallbackReason != null) ...[
            const SizedBox(height: 8),
            Text(
              'Using the built-in adaptive engine (${controller.fallbackReason}).',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onPrimaryContainer),
            ),
          ],
        ],
      ),
    );
  }
}

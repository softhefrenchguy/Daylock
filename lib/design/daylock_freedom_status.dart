import 'package:flutter/material.dart';

import '../services/freedom_service.dart';
import 'daylock_scene.dart';
import 'daylock_theme.dart';
import 'daylock_widgets.dart';

/// The three Freedom conditions. Presentation only; no rules change here.
class FreedomConditions extends StatelessWidget {
  final FreedomEligibility eligibility;
  const FreedomConditions({super.key, required this.eligibility});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final gold = daylockGold(theme.brightness);
    Widget condition(String label, bool satisfied) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            satisfied
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            semanticLabel: satisfied ? 'Satisfied' : 'Remaining',
            size: 20,
            color: satisfied ? gold : scheme.outline,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium!.copyWith(height: 1.3),
            ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        condition(
          'Freedom Time · ${eligibility.settings.timeLabel}',
          eligibility.timeReached,
        ),
        condition(
          eligibility.hasEligibleCommitments
              ? '${eligibility.completedCount} / ${eligibility.eligibleCount} eligible commitments complete'
              : 'No eligible commitments — completion is required to earn Freedom.',
          eligibility.commitmentsCompleted,
        ),
        condition('Tomorrow’s plan committed', eligibility.tomorrowCommitted),
        if (!eligibility.currentPlans)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Today’s plan does not match the current local date.',
              style: theme.textTheme.bodySmall!.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

/// Full Freedom status card: a small landscape plus the conditions.
class DaylockFreedomStatus extends StatelessWidget {
  final FreedomEligibility eligibility;
  const DaylockFreedomStatus({super.key, required this.eligibility});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enabled = eligibility.settings.enabled;
    final waiting =
        enabled &&
        eligibility.currentPlans &&
        !eligibility.timeReached &&
        eligibility.commitmentsCompleted &&
        eligibility.tomorrowCommitted;
    final title = !enabled
        ? 'Freedom Control is off'
        : eligibility.earned
        ? 'Freedom earned'
        : waiting
        ? 'Waiting for Freedom Time'
        : 'Freedom not yet earned';
    final sky = SceneColors.of(theme);
    return AnimatedContainer(
      key: const ValueKey('freedom-status'),
      duration: daylockMotion(context),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DaylockScene(
            mood: eligibility.earned
                ? SceneMood.earned
                : enabled
                ? SceneMood.dawn
                : SceneMood.night,
            progress: eligibility.eligibleCount == 0
                ? 0
                : eligibility.completedCount / eligibility.eligibleCount,
            height: 132,
            ground: scheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: FractionallySizedBox(
                alignment: Alignment.topLeft,
                widthFactor: .68,
                child: Text(
                  title,
                  key: const ValueKey('freedom-title'),
                  style: theme.textTheme.titleLarge!.copyWith(
                    fontSize: 22,
                    height: 1.15,
                    color: sky.onSky,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (waiting)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'Available at ${eligibility.settings.timeLabel}',
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                FreedomConditions(eligibility: eligibility),
                const SizedBox(height: DaylockSpace.sm),
                if (!enabled)
                  Text(
                    'Enable Freedom Control in Settings.',
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                Text(
                  'App restrictions are configured in Settings.',
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

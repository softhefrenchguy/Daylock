import '../l10n/l10n.dart';

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
            semanticLabel: satisfied
                ? context.l10n.conditionSatisfied
                : context.l10n.conditionRemaining,
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
          context.l10n.freedomTimeAt(eligibility.settings.timeLabel),
          eligibility.timeReached,
        ),
        condition(
          eligibility.hasEligibleCommitments
              ? context.l10n.eligibleComplete(
                  eligibility.completedCount,
                  eligibility.eligibleCount,
                )
              : context.l10n.noEligibleRequired,
          eligibility.commitmentsCompleted,
        ),
        condition(
          context.l10n.tomorrowPlanCommittedCondition,
          eligibility.tomorrowCommitted,
        ),
        if (!eligibility.currentPlans)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              context.l10n.planDateMismatch,
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
        ? context.l10n.freedomControlOff
        : eligibility.earned
        ? context.l10n.freedomEarned
        : waiting
        ? context.l10n.waitingForFreedomTime
        : context.l10n.freedomNotYetEarned;
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
              padding: const EdgeInsetsDirectional.fromSTEB(18, 16, 18, 0),
              child: FractionallySizedBox(
                alignment: AlignmentDirectional.topStart,
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
            padding: const EdgeInsetsDirectional.fromSTEB(18, 4, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (waiting)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      context.l10n.availableAt(eligibility.settings.timeLabel),
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                FreedomConditions(eligibility: eligibility),
                const SizedBox(height: DaylockSpace.sm),
                if (!enabled)
                  Text(
                    context.l10n.enableFreedomInSettings,
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                Text(
                  context.l10n.todayRestrictionsInSettings,
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

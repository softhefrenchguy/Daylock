import 'package:flutter/material.dart';

import '../services/freedom_service.dart';
import 'daylock_palette.dart';
import 'daylock_widgets.dart';

/// Presentation of the existing eligibility result; no rules are changed here.
class DaylockFreedomStatus extends StatelessWidget {
  final FreedomEligibility eligibility;
  const DaylockFreedomStatus({super.key, required this.eligibility});

  @override
  Widget build(BuildContext context) {
    final colors = DaylockColors.of(context);
    final theme = Theme.of(context);
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
    final icon = eligibility.earned
        ? Icons.lock_open_rounded
        : waiting
        ? Icons.schedule_rounded
        : Icons.lock_outline_rounded;
    Widget condition(String label, bool satisfied) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            satisfied
                ? Icons.check_circle_outline_rounded
                : Icons.radio_button_unchecked_rounded,
            semanticLabel: satisfied ? 'Satisfied' : 'Remaining',
            size: 16,
            color: satisfied ? colors.statusAccent : colors.onStatusMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall!.copyWith(
                color: colors.onStatus,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
    return AnimatedContainer(
      key: const ValueKey('freedom-status'),
      duration: daylockMotion(context),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: eligibility.earned
            ? colors.completedSurface
            : colors.statusSurface,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              colors.statusAccent.withValues(
                alpha: eligibility.earned
                    ? .27
                    : waiting
                    ? .18
                    : .12,
              ),
              colors.statusSurface,
            ),
            eligibility.earned ? colors.completedSurface : colors.statusSurface,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: eligibility.earned
              ? colors.statusAccent
              : colors.statusOutline,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.statusAccent.withValues(
              alpha: eligibility.earned ? .16 : .06,
            ),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DaylockLabel('FREEDOM', color: colors.statusAccent),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      key: const ValueKey('freedom-title'),
                      style: theme.textTheme.titleMedium!.copyWith(
                        color: colors.onStatus,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (waiting)
                      Text(
                        'Available at ${eligibility.settings.timeLabel}',
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: colors.onStatusMuted,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ExcludeSemantics(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        colors.statusAccent.withValues(alpha: .38),
                        colors.statusAccent.withValues(alpha: .04),
                      ],
                    ),
                    border: Border.all(
                      color: colors.statusAccent.withValues(alpha: .35),
                    ),
                  ),
                  child: Icon(icon, color: colors.statusAccent, size: 27),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          condition(
            'Freedom Time \u00b7 ${eligibility.settings.timeLabel}',
            eligibility.timeReached,
          ),
          condition(
            eligibility.hasEligibleCommitments
                ? '${eligibility.completedCount} / ${eligibility.eligibleCount} eligible commitments complete'
                : 'No eligible commitments \u2014 completion is required to earn Freedom.',
            eligibility.commitmentsCompleted,
          ),
          condition(
            'Tomorrow\u2019s plan committed',
            eligibility.tomorrowCommitted,
          ),
          if (!eligibility.currentPlans)
            Text(
              'Today\u2019s plan does not match the current local date.',
              style: theme.textTheme.bodySmall!.copyWith(
                color: colors.onStatusMuted,
              ),
            ),
          if (!enabled)
            Text(
              'Enable Freedom Control in Settings.',
              style: theme.textTheme.bodySmall!.copyWith(
                color: colors.onStatusMuted,
              ),
            ),
          Text(
            'Instagram control is configured in Settings.',
            style: theme.textTheme.bodySmall!.copyWith(
              color: colors.onStatusMuted,
            ),
          ),
        ],
      ),
    );
  }
}

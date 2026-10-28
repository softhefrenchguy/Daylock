import 'package:flutter/material.dart';

import '../services/freedom_service.dart';
import 'daylock_palette.dart';
import 'daylock_widgets.dart';
import 'daylock_illustrations.dart';

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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            satisfied
                ? Icons.check_circle_outline_rounded
                : Icons.radio_button_unchecked_rounded,
            semanticLabel: satisfied ? 'Satisfied' : 'Remaining',
            size: 18,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: eligibility.earned
            ? colors.completedSurface
            : colors.statusSurface,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            if (theme.brightness == Brightness.dark)
              HSLColor.fromColor(colors.statusAccent)
                  .withLightness(eligibility.earned ? .24 : .19)
                  .withSaturation(
                    HSLColor.fromColor(colors.statusAccent).saturation * .85,
                  )
                  .toColor()
            else
              Color.alphaBlend(
                colors.statusAccent.withValues(alpha: .2),
                colors.statusSurface,
              ),
            eligibility.earned ? colors.completedSurface : colors.statusSurface,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: eligibility.earned
              ? colors.statusAccent
              : colors.statusAccent.withValues(alpha: .65),
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
          DaylockLabel('FREEDOM', color: colors.statusAccent),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final showArtBeside =
                  constraints.maxWidth >= 300 &&
                  MediaQuery.textScalerOf(context).scale(14) < 21;
              final artwork = SizedBox(
                width: 80,
                child: DaylockIllustration(
                  accent: colors.statusAccent,
                  lockIcon: icon,
                ),
              );
              final heading = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    key: const ValueKey('freedom-title'),
                    style: theme.textTheme.titleLarge!.copyWith(
                      fontSize: 19,
                      color: colors.onStatus,
                    ),
                  ),
                  if (waiting)
                    Text(
                      'Available at ${eligibility.settings.timeLabel}',
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: colors.onStatusMuted,
                      ),
                    ),
                  const SizedBox(height: 10),
                  condition(
                    'Freedom Time \u00b7 ${eligibility.settings.timeLabel}',
                    eligibility.timeReached,
                  ),
                ],
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showArtBeside)
                    Row(
                      children: [
                        Expanded(child: heading),
                        const SizedBox(width: 8),
                        artwork,
                      ],
                    )
                  else ...[
                    heading,
                    Center(child: artwork),
                  ],
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
                ],
              );
            },
          ),
          const SizedBox(height: 4),
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
            'App restrictions are configured in Settings.',
            style: theme.textTheme.bodySmall!.copyWith(
              color: colors.onStatusMuted,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../services/freedom_service.dart';
import 'daylock_palette.dart';
import 'daylock_theme.dart';
import 'daylock_widgets.dart';

class DaylockFreedomStatus extends StatelessWidget {
  final FreedomEligibility eligibility;
  const DaylockFreedomStatus({super.key, required this.eligibility});
  @override
  Widget build(BuildContext context) {
    final colors = DaylockColors.of(context);
    final text = Theme.of(context).textTheme;
    Widget condition(String label, bool satisfied) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            satisfied
                ? Icons.check_circle_outline_rounded
                : Icons.radio_button_unchecked_rounded,
            semanticLabel: satisfied ? 'Satisfied' : 'Remaining',
            size: 20,
            color: satisfied ? colors.statusAccent : colors.onStatusMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: text.bodyMedium!.copyWith(color: colors.onStatus),
            ),
          ),
        ],
      ),
    );
    return AnimatedContainer(
      key: const ValueKey('freedom-status'),
      duration: daylockMotion(context),
      width: double.infinity,
      padding: const EdgeInsets.all(DaylockSpace.lg),
      decoration: BoxDecoration(
        color: eligibility.earned
            ? colors.completedSurface
            : colors.statusSurface,
        borderRadius: BorderRadius.circular(DaylockSpace.radius),
        border: Border.all(color: colors.statusOutline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DaylockLabel('FREEDOM', color: colors.statusAccent),
          const SizedBox(height: 12),
          Text(
            !eligibility.settings.enabled
                ? 'Freedom Control is off'
                : eligibility.earned
                ? 'Freedom earned'
                : 'Freedom not yet earned',
            key: const ValueKey('freedom-title'),
            style: text.headlineLarge!.copyWith(
              fontSize: 28,
              color: colors.onStatus,
            ),
          ),
          const SizedBox(height: 12),
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
            Text(
              'Today’s plan does not match the current local date.',
              style: text.bodyMedium!.copyWith(color: colors.onStatusMuted),
            ),
          const SizedBox(height: 12),
          Text(
            'Instagram control is configured in Settings.',
            style: text.bodySmall!.copyWith(color: colors.onStatusMuted),
          ),
        ],
      ),
    );
  }
}

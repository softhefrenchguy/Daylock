import 'package:flutter/material.dart';

import '../models/commitment_progress.dart';
import 'journey_surface.dart';
import 'daylock_widgets.dart';

/// A projection of the existing plan progress and live stopwatch totals.
class DailyProgressCard extends StatelessWidget {
  final CommitmentProgress progress;
  final int recordedMilliseconds;
  const DailyProgressCard({
    super.key,
    required this.progress,
    required this.recordedMilliseconds,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final fraction = progress.fraction;
    final seconds = recordedMilliseconds ~/ 1000;
    final hours = seconds ~/ 3600;
    final minutes = seconds ~/ 60 % 60;
    final time = hours > 0
        ? '${hours}h ${minutes}m'
        : minutes > 0
        ? '${minutes}m ${seconds % 60}s'
        : '${seconds}s';
    final status = progress.isNeutral
        ? 'No eligible commitments yet'
        : progress.isComplete
        ? 'Day complete'
        : '${progress.remainingCount} remaining today';
    return JourneySurface(
      key: const ValueKey('daily-summary'),
      emphasized: true,
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 54,
                  height: 54,
                  child: CircularProgressIndicator(
                    value: fraction ?? 0,
                    strokeWidth: 6,
                    strokeCap: StrokeCap.round,
                    backgroundColor: colors.primary.withValues(alpha: .18),
                    valueColor: AlwaysStoppedAnimation(colors.primary),
                    semanticsLabel: fraction == null
                        ? 'No eligible commitments'
                        : 'Commitments complete',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              progress.isNeutral && progress.totalCount > 0
                                  ? 'No eligible commitments'
                                  : '${progress.completedCount} / ${progress.eligibleCount} complete',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            fraction == null && progress.totalCount > 0
                                ? '\u2014'
                                : '${((fraction ?? 0) * 100).round()}%',
                            style: theme.textTheme.titleMedium!.copyWith(
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                      if (fraction != null) ...[
                        const SizedBox(height: 7),
                        DaylockProgress(
                          value: fraction,
                          label: 'Commitment progress',
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 18, color: colors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$time recorded today',
                    key: const ValueKey('today-recorded-time'),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    status,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            if (progress.excusedCount > 0)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${progress.excusedCount} excused',
                  key: const ValueKey('today-excused-count'),
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

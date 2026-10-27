import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/journey_service.dart';

/// Displays the existing service's chronological buckets without inventing data.
class JourneyActivityStrip extends StatelessWidget {
  final List<JourneyBucket> buckets;
  final Color accent;
  const JourneyActivityStrip({
    super.key,
    required this.buckets,
    required this.accent,
  });
  bool get usesFocus => buckets.any((b) => b.summary.focusMilliseconds > 0);
  List<int> get values => buckets
      .map(
        (b) =>
            usesFocus ? b.summary.focusMilliseconds : b.summary.completedCount,
      )
      .toList();
  bool get hasActivity => values.any((v) => v > 0);

  String description(BuildContext context) {
    final locale = MaterialLocalizations.of(context);
    return 'Last 30 days, ${usesFocus ? 'recorded Focus' : 'completed commitments'}. ${[for (final bucket in buckets) '${locale.formatShortDate(bucket.from)} to ${locale.formatShortDate(bucket.through)}: ${usesFocus ? journeyFocusLabel(bucket.summary.focusMilliseconds) : bucket.summary.completedCount}'].join('; ')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!hasActivity) return const SizedBox.shrink();
    final amounts = values;
    final max = amounts.reduce(math.max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 28,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < amounts.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        widthFactor: .72,
                        child: Container(
                          key: ValueKey('activity-bar-$i'),
                          // A zero bucket has no bar; a positive measurement is never fabricated.
                          height: amounts[i] == 0
                              ? 0
                              : math.max(1, 28 * amounts[i] / max),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [accent, accent.withValues(alpha: .45)],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '30 days · ${usesFocus ? 'Focus' : 'completed'}',
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            fontSize: 9,
            height: 1.2,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

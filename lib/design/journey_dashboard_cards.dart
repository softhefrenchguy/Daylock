import 'package:flutter/material.dart';

import '../services/journey_service.dart';
import 'journey_surface.dart';

class JourneyProgressSummary extends StatelessWidget {
  final JourneySummary summary;
  final int highlights;
  const JourneyProgressSummary({
    super.key,
    required this.summary,
    required this.highlights,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    Color shiftedAccent(double degrees) {
      final base = HSLColor.fromColor(colors.primary);
      return base.withHue((base.hue + degrees) % 360).toColor();
    }

    Widget metric(
      String key,
      IconData icon,
      Color accent,
      String value,
      String label,
      String semantics,
    ) => Semantics(
      label: semantics,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accent, size: 21),
                const SizedBox(width: 6),
                Expanded(
                  child: Text.rich(
                    key: ValueKey(key),
                    TextSpan(
                      children: [
                        TextSpan(
                          text: value,
                          style: theme.textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall!.copyWith(
                fontSize: 11,
                height: 1.35,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
    final metrics = [
      metric(
        'journey-total-completed',
        Icons.check_circle_outline_rounded,
        colors.primary,
        '${summary.completedCount}',
        'completed\ncommitments',
        '${summary.completedCount} completed commitments',
      ),
      metric(
        'journey-total-focus',
        Icons.schedule_rounded,
        shiftedAccent(-40),
        journeyFocusLabel(summary.focusMilliseconds),
        'Time\nrecorded',
        '${journeyFocusLabel(summary.focusMilliseconds)} recorded time',
      ),
      metric(
        'journey-total-highlights',
        Icons.auto_awesome_outlined,
        shiftedAccent(160),
        '$highlights',
        'Highlights\nsaved',
        '$highlights saved Highlights',
      ),
    ];
    return JourneySurface(
      child: Padding(
        padding: EdgeInsets.zero,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = MediaQuery.textScalerOf(context).scale(14) > 20;
            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: metrics,
              );
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < metrics.length; i++) ...[
                    if (i > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: VerticalDivider(
                          width: 1,
                          color: colors.outlineVariant,
                        ),
                      ),
                    Expanded(child: metrics[i]),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class JourneyHistoryLinks extends StatelessWidget {
  final VoidCallback onDailyHistory;
  final VoidCallback? onPastChapters;
  const JourneyHistoryLinks({
    super.key,
    required this.onDailyHistory,
    this.onPastChapters,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget entry(
      String key,
      IconData icon,
      String title,
      String subtitle,
      VoidCallback? action,
    ) => Semantics(
      button: true,
      label: '$title. $subtitle',
      onTap: action,
      child: ExcludeSemantics(
        child: JourneySurface(
          key: ValueKey(key),
          radius: 16,
          onTap: action,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(icon, size: 24, color: theme.colorScheme.primary),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall!.copyWith(
                          fontSize: 10,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final daily = entry(
      'daily-history',
      Icons.calendar_month_outlined,
      'Daily history',
      'Your calendar and past days',
      onDailyHistory,
    );
    final chapters = entry(
      'past-chapters',
      Icons.inventory_2_outlined,
      'Past Chapters',
      'Archived Areas',
      onPastChapters,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 320 ||
            MediaQuery.textScalerOf(context).scale(14) > 20) {
          return Column(
            children: [daily, const SizedBox(height: 10), chapters],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: daily),
              const SizedBox(width: 10),
              Expanded(child: chapters),
            ],
          ),
        );
      },
    );
  }
}

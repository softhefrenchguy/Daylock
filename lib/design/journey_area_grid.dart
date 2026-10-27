import 'package:flutter/material.dart';

import '../models/area.dart';
import '../models/highlight.dart';
import '../services/journey_service.dart';
import 'daylock_areas.dart';
import 'journey_activity_strip.dart';
import 'journey_surface.dart';

/// Intrinsic row heights let large type grow instead of clipping grid cells.
class JourneyAreaGrid extends StatelessWidget {
  final List<Area> areas;
  final JourneyData data;
  final HighlightBook highlights;
  final ValueChanged<String> onAreaOpened;
  final bool compact;
  const JourneyAreaGrid({
    super.key,
    required this.areas,
    required this.data,
    required this.highlights,
    required this.onAreaOpened,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final largeText = MediaQuery.textScalerOf(context).scale(16) > 24;
      final columns = largeText && constraints.maxWidth < 560 ? 1 : 2;
      final width = (constraints.maxWidth - 10 * (columns - 1)) / columns;
      final minHeight = compact ? 100.0 : (width * .78).clamp(126.0, 170.0);
      final latest = <String, Highlight>{};
      for (final highlight in highlights.newestFirst) {
        if (highlight.areaId != null) {
          latest.putIfAbsent(highlight.areaId!, () => highlight);
        }
      }
      return Column(
        children: [
          for (var row = 0; row < areas.length; row += columns) ...[
            if (row > 0) const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var column = 0; column < columns; column++) ...[
                    if (column > 0) const SizedBox(width: 10),
                    Expanded(
                      child: row + column >= areas.length
                          ? const SizedBox.shrink()
                          : JourneyAreaTile(
                              key: ValueKey(
                                'journey-area-${areas[row + column].id}',
                              ),
                              area: areas[row + column],
                              summary: data.forArea(areas[row + column].id),
                              buckets: data.activity(
                                areas[row + column].id,
                                last30Days: true,
                              ),
                              latestHighlight: latest[areas[row + column].id],
                              minHeight: minHeight,
                              expandText: largeText,
                              compact: compact,
                              onTap: () => onAreaOpened(areas[row + column].id),
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      );
    },
  );
}

class JourneyAreaTile extends StatelessWidget {
  final Area area;
  final JourneySummary summary;
  final List<JourneyBucket> buckets;
  final Highlight? latestHighlight;
  final double minHeight;
  final bool expandText;
  final bool compact;
  final VoidCallback onTap;
  const JourneyAreaTile({
    super.key,
    required this.area,
    required this.summary,
    this.buckets = const [],
    this.latestHighlight,
    required this.minHeight,
    required this.expandText,
    this.compact = false,
    required this.onTap,
  });

  String get progress {
    if (summary.focusMilliseconds > 0) {
      return '${journeyFocusLabel(summary.focusMilliseconds)} Focus';
    }
    if (summary.completedCount > 0) {
      return '${summary.completedCount} completed';
    }
    if (summary.records.isEmpty && latestHighlight != null) {
      return latestHighlight!.title;
    }
    return summary.records.isEmpty ? 'Open space' : '0 completed';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = Color(area.colour);
    final chart = JourneyActivityStrip(
      buckets: buckets,
      accent: accent,
      key: ValueKey('area-activity-${area.id}'),
    );
    return Semantics(
      button: true,
      label:
          '${area.name}. $progress. ${chart.hasActivity ? '${chart.description(context)}. ' : ''}Open Area',
      onTap: onTap,
      child: ExcludeSemantics(
        child: JourneySurface(
          accent: accent,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: compact ? 6 : 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        areaIcons[area.icon] ?? areaIcons['life'],
                        color: accent,
                        size: 26,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          area.name,
                          maxLines: expandText ? null : 2,
                          overflow: expandText ? null : TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: colors.onSurfaceVariant,
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 4 : 8),
                  Text(
                    progress,
                    maxLines: expandText ? null : 2,
                    overflow: expandText ? null : TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                  if (summary.records.isEmpty && latestHighlight != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        'Latest Highlight',
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: colors.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  if (chart.hasActivity) ...[
                    SizedBox(height: compact ? 4 : 6),
                    chart,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

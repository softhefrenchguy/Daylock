import 'package:flutter/material.dart';

import '../models/area.dart';
import '../models/highlight.dart';
import '../services/journey_service.dart';
import 'daylock_areas.dart';

/// Intrinsic row heights let large type grow instead of clipping grid cells.
class JourneyAreaGrid extends StatelessWidget {
  final List<Area> areas;
  final JourneyData data;
  final HighlightBook highlights;
  final ValueChanged<String> onAreaOpened;
  const JourneyAreaGrid({
    super.key,
    required this.areas,
    required this.data,
    required this.highlights,
    required this.onAreaOpened,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final largeText = MediaQuery.textScalerOf(context).scale(16) > 24;
      final columns = largeText && constraints.maxWidth < 560 ? 1 : 2;
      final width = (constraints.maxWidth - 10 * (columns - 1)) / columns;
      final minHeight = (width * .78).clamp(126.0, 170.0);
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
                              latestHighlight: latest[areas[row + column].id],
                              minHeight: minHeight,
                              expandText: largeText,
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
  final Highlight? latestHighlight;
  final double minHeight;
  final bool expandText;
  final VoidCallback onTap;
  const JourneyAreaTile({
    super.key,
    required this.area,
    required this.summary,
    this.latestHighlight,
    required this.minHeight,
    required this.expandText,
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
    final radius = BorderRadius.circular(18);
    return Semantics(
      button: true,
      label: '${area.name}. $progress. Open Area',
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: Color.alphaBlend(
            accent.withValues(alpha: .09),
            colors.surfaceContainerLow,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: Color.alphaBlend(
                accent.withValues(alpha: .28),
                colors.outlineVariant,
              ),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: Padding(
                padding: const EdgeInsets.all(14),
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
                        const Spacer(),
                        Icon(
                          Icons.north_east_rounded,
                          size: 16,
                          color: colors.onSurfaceVariant,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      area.name,
                      maxLines: expandText ? null : 2,
                      overflow: expandText ? null : TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      progress,
                      maxLines: expandText ? null : 2,
                      overflow: expandText ? null : TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

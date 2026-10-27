import 'package:flutter/material.dart';

import '../design/journey_area_grid.dart';
import '../design/journey_featured_highlight.dart';
import '../models/area.dart';
import '../models/highlight.dart';
import '../services/journey_service.dart';

class JourneyScreen extends StatelessWidget {
  final AreaBook areas;
  final HighlightBook highlights;
  final JourneyData data;
  final ValueChanged<String> onAreaOpened;
  final ValueChanged<Highlight> onHighlightOpened;
  final ValueChanged<Highlight>? onHighlightEdited;
  final VoidCallback onAddHighlight, onAllHighlights, onDailyHistory;
  final VoidCallback? onPastChapters, onManageAreas;
  const JourneyScreen({
    super.key,
    required this.areas,
    required this.highlights,
    required this.data,
    required this.onAreaOpened,
    required this.onHighlightOpened,
    required this.onAddHighlight,
    required this.onAllHighlights,
    required this.onDailyHistory,
    this.onHighlightEdited,
    this.onPastChapters,
    this.onManageAreas,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = JourneySummary(data.records);
    Widget metric(String key, String value, String label, String semantics) =>
        Semantics(
          label: semantics,
          excludeSemantics: true,
          child: Text.rich(
            key: ValueKey(key),
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: theme.textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: ' $label',
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            key: const ValueKey('journey-content'),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Journey',
                      style: theme.textTheme.headlineLarge!.copyWith(
                        fontSize: 28,
                      ),
                    ),
                  ),
                  if (onManageAreas != null)
                    IconButton(
                      key: const ValueKey('journey-manage-areas'),
                      tooltip: 'Manage Areas',
                      onPressed: onManageAreas,
                      icon: const Icon(Icons.tune_rounded, size: 22),
                    ),
                ],
              ),
              Wrap(
                key: const ValueKey('journey-effort-summary'),
                spacing: 16,
                runSpacing: 4,
                children: [
                  metric(
                    'journey-total-completed',
                    '${summary.completedCount}',
                    'completed',
                    '${summary.completedCount} completed commitments',
                  ),
                  metric(
                    'journey-total-focus',
                    journeyFocusLabel(summary.focusMilliseconds),
                    'Focus',
                    '${journeyFocusLabel(summary.focusMilliseconds)} recorded Focus',
                  ),
                  metric(
                    'journey-total-highlights',
                    '${highlights.highlights.length}',
                    'Highlights',
                    '${highlights.highlights.length} Highlights',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              JourneyAreaGrid(
                key: const ValueKey('journey-area-grid'),
                areas: areas.active,
                data: data,
                highlights: highlights,
                onAreaOpened: onAreaOpened,
              ),
              const SizedBox(height: 8),
              JourneyFeaturedHighlight(
                highlights: highlights.newestFirst,
                areas: areas,
                onAdd: onAddHighlight,
                onAll: onAllHighlights,
                onOpened: onHighlightOpened,
                onEdited: onHighlightEdited,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    key: const ValueKey('daily-history'),
                    onPressed: onDailyHistory,
                    icon: const Icon(Icons.calendar_month_outlined, size: 18),
                    label: const Text('Daily history'),
                  ),
                  TextButton.icon(
                    key: const ValueKey('past-chapters'),
                    onPressed: onPastChapters,
                    icon: const Icon(Icons.inventory_2_outlined, size: 18),
                    label: const Text('Past Chapters'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

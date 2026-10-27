import 'package:flutter/material.dart';

import '../design/journey_area_grid.dart';
import '../design/journey_featured_highlight.dart';
import '../design/journey_dashboard_cards.dart';
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
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              theme.colorScheme.primary.withValues(alpha: .025),
              theme.colorScheme.surface,
            ),
            theme.colorScheme.surface,
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              key: const ValueKey('journey-content'),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Journey',
                        style: theme.textTheme.headlineLarge!.copyWith(
                          fontSize: 30,
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
                Text(
                  'Progress in the areas that matter',
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                JourneyProgressSummary(
                  key: const ValueKey('journey-effort-summary'),
                  summary: summary,
                  highlights: highlights.highlights.length,
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Your Areas',
                      style: theme.textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (onManageAreas != null)
                      TextButton(
                        onPressed: onManageAreas,
                        child: const Text('View all'),
                      ),
                  ],
                ),
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
                JourneyHistoryLinks(
                  onDailyHistory: onDailyHistory,
                  onPastChapters: onPastChapters,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../design/daylock_areas.dart';
import '../design/daylock_journey.dart';
import '../design/daylock_theme.dart';
import '../design/daylock_widgets.dart';
import '../models/area.dart';
import '../models/highlight.dart';
import '../services/journey_service.dart';

class AreaJourneyScreen extends StatefulWidget {
  final Area area;
  final AreaBook areas;
  final JourneyData data;
  final HighlightBook highlights;
  final ValueChanged<Highlight> onHighlightOpened;
  final ValueChanged<DateTime> onDayOpened;
  final VoidCallback onAddHighlight;
  const AreaJourneyScreen({
    super.key,
    required this.area,
    required this.areas,
    required this.data,
    required this.highlights,
    required this.onHighlightOpened,
    required this.onDayOpened,
    required this.onAddHighlight,
  });
  @override
  State<AreaJourneyScreen> createState() => _AreaJourneyScreenState();
}

class _AreaJourneyScreenState extends State<AreaJourneyScreen> {
  bool _last30 = true, _focus = false;
  @override
  Widget build(BuildContext context) {
    final summary = widget.data.forArea(widget.area.id, last30Days: _last30);
    final highlights = widget.highlights.newestFirst
        .where(
          (h) =>
              h.areaId == widget.area.id &&
              (!_last30 ||
                  (!h.date.isBefore(widget.data.last30Start) &&
                      !h.date.isAfter(widget.data.today))),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(widget.area.name)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              key: const ValueKey('area-journey-content'),
              padding: const EdgeInsets.all(DaylockSpace.lg),
              children: [
                AreaBadge(area: widget.area),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      key: const ValueKey('journey-last30'),
                      label: const Text('Last 30 days'),
                      selected: _last30,
                      onSelected: (_) => setState(() => _last30 = true),
                    ),
                    ChoiceChip(
                      key: const ValueKey('journey-alltime'),
                      label: const Text('All time'),
                      selected: !_last30,
                      onSelected: (_) => setState(() => _last30 = false),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  '${summary.completedCount} completed ${summary.completedCount == 1 ? 'commitment' : 'commitments'}',
                  key: const ValueKey('area-completed-count'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '${journeyFocusLabel(summary.focusMilliseconds)} recorded time',
                  key: const ValueKey('area-focus-time'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Stopwatch time records actual effort, including incomplete commitments.',
                ),
                const SizedBox(height: 24),
                const DaylockLabel('ACTIVITY OVER TIME'),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Commitments'),
                      selected: !_focus,
                      onSelected: (_) => setState(() => _focus = false),
                    ),
                    ChoiceChip(
                      label: const Text('Tracked time'),
                      selected: _focus,
                      onSelected: (_) => setState(() => _focus = true),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                JourneyActivityChart(
                  buckets: widget.data.activity(
                    widget.area.id,
                    last30Days: _last30,
                  ),
                  focus: _focus,
                  colour: Color(widget.area.colour),
                ),
                const SizedBox(height: 24),
                const DaylockLabel('HIGHLIGHTS'),
                if (highlights.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'A place for the moments you want to remember.',
                    ),
                  ),
                for (final highlight in highlights)
                  JourneyHighlightTile(
                    highlight: highlight,
                    areas: widget.areas,
                    onTap: () => widget.onHighlightOpened(highlight),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: widget.onAddHighlight,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Highlight'),
                  ),
                ),
                const SizedBox(height: 24),
                ExpansionTile(
                  key: const ValueKey('area-records'),
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Recorded commitments'),
                  subtitle: Text('${summary.records.length} records'),
                  children: [
                    if (summary.records.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Your recorded commitments will appear here.',
                        ),
                      ),
                    for (final record in summary.records)
                      ListTile(
                        key: ValueKey(
                          'journey-record-${record.date.toIso8601String()}-${record.taskIndex}',
                        ),
                        contentPadding: EdgeInsets.zero,
                        title: Text(record.task.name),
                        subtitle: Text(
                          '${MaterialLocalizations.of(context).formatMediumDate(record.date)} · ${record.task.outcome.label}'
                          '${record.task.accumulatedFocusMilliseconds > 0 ? ' · ${journeyFocusLabel(record.task.accumulatedFocusMilliseconds)} recorded' : ''}',
                        ),
                        onTap: () => widget.onDayOpened(record.date),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

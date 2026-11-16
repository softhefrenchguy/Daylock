import '../l10n/l10n.dart';

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
                      label: Text(context.l10n.last30Days),
                      selected: _last30,
                      onSelected: (_) => setState(() => _last30 = true),
                    ),
                    ChoiceChip(
                      key: const ValueKey('journey-alltime'),
                      label: Text(context.l10n.allTime),
                      selected: !_last30,
                      onSelected: (_) => setState(() => _last30 = false),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  context.l10n.completedCommitments(summary.completedCount),
                  key: const ValueKey('area-completed-count'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.recordedTime(
                    context.l10n.focusDuration(summary.focusMilliseconds),
                  ),
                  key: const ValueKey('area-focus-time'),
                ),
                const SizedBox(height: 8),
                Text(context.l10n.stopwatchExplainer),
                const SizedBox(height: 24),
                DaylockLabel(context.l10n.activityOverTime),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(context.l10n.commitments),
                      selected: !_focus,
                      onSelected: (_) => setState(() => _focus = false),
                    ),
                    ChoiceChip(
                      label: Text(context.l10n.trackedTime),
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
                const DaylockLabel('ACHIEVEMENTS'),
                if (highlights.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(context.l10n.achievementsPlace),
                  ),
                for (final highlight in highlights)
                  JourneyHighlightTile(
                    highlight: highlight,
                    areas: widget.areas,
                    onTap: () => widget.onHighlightOpened(highlight),
                  ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OutlinedButton.icon(
                    onPressed: widget.onAddHighlight,
                    icon: const Icon(Icons.add),
                    label: Text(context.l10n.addAchievement),
                  ),
                ),
                const SizedBox(height: 24),
                ExpansionTile(
                  key: const ValueKey('area-records'),
                  tilePadding: EdgeInsets.zero,
                  title: Text(context.l10n.recordedCommitments),
                  subtitle: Text(
                    context.l10n.recordsCount(summary.records.length),
                  ),
                  children: [
                    if (summary.records.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(context.l10n.recordsEmpty),
                      ),
                    for (final record in summary.records)
                      ListTile(
                        key: ValueKey(
                          'journey-record-${record.date.toIso8601String()}-${record.taskIndex}',
                        ),
                        contentPadding: EdgeInsets.zero,
                        title: Text(record.task.name),
                        subtitle: Text(
                          '${MaterialLocalizations.of(context).formatMediumDate(record.date)} · ${context.l10n.taskOutcome(record.task.outcome)}'
                          '${record.task.accumulatedFocusMilliseconds > 0 ? ' · ${context.l10n.durationRecorded(context.l10n.focusDuration(record.task.accumulatedFocusMilliseconds))}' : ''}',
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

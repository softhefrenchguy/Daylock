import 'package:flutter/material.dart';

import '../models/area.dart';
import '../models/highlight.dart';
import '../services/journey_service.dart';
import 'daylock_areas.dart';

class JourneyHighlightTile extends StatelessWidget {
  final Highlight highlight;
  final AreaBook areas;
  final VoidCallback onTap;
  const JourneyHighlightTile({
    super.key,
    required this.highlight,
    required this.areas,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final linked = areas.areas.where((a) => a.id == highlight.areaId);
    return ListTile(
      key: ValueKey('highlight-${highlight.id}'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.auto_awesome_outlined),
      title: Text(highlight.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            MaterialLocalizations.of(context).formatMediumDate(highlight.date),
          ),
          if (linked.isNotEmpty) AreaBadge(area: linked.single),
          if (highlight.areaId != null && linked.isEmpty)
            const Text('Area unavailable'),
        ],
      ),
      onTap: onTap,
    );
  }
}

class JourneyActivityChart extends StatelessWidget {
  final List<JourneyBucket> buckets;
  final bool focus;
  final Color colour;
  const JourneyActivityChart({
    super.key,
    required this.buckets,
    required this.focus,
    required this.colour,
  });
  @override
  Widget build(BuildContext context) {
    final values = [
      for (final b in buckets)
        focus ? b.summary.focusMilliseconds : b.summary.completedCount,
    ];
    final maximum = values.fold<int>(
      0,
      (max, value) => value > max ? value : max,
    );
    final local = MaterialLocalizations.of(context);
    String range(JourneyBucket b) =>
        '${local.formatShortDate(b.from)} – ${local.formatShortDate(b.through)}';
    String label(int i) =>
        '${range(buckets[i])}: ${focus ? '${journeyFocusLabel(values[i])} recorded time' : '${values[i]} completed commitments'}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (maximum == 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              focus
                  ? 'Recorded time will appear here.'
                  : 'Completed commitments will appear here.',
            ),
          ),
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < buckets.length; i++)
                Expanded(
                  child: Semantics(
                    label: label(i),
                    child: Tooltip(
                      message: label(i),
                      child: ExcludeSemantics(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: values[i] == 0
                                  ? 2
                                  : 8 + 110 * values[i] / maximum,
                              decoration: BoxDecoration(
                                color: values[i] == 0
                                    ? Theme.of(context)
                                          .colorScheme
                                          .outlineVariant
                                    : colour,
                                borderRadius: BorderRadius.circular(6),
                              ),
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
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 12,
          runSpacing: 4,
          children: [
            Text(local.formatShortDate(buckets.first.from)),
            Text(local.formatShortDate(buckets.last.through)),
          ],
        ),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Activity details'),
          children: [
            for (var i = 0; i < buckets.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(label(i)),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

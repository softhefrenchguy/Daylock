import 'package:flutter/material.dart';

import '../design/daylock_journey.dart';
import '../design/daylock_theme.dart';
import '../design/daylock_widgets.dart';
import '../models/area.dart';
import '../models/highlight.dart';
import '../services/journey_service.dart';

class JourneyScreen extends StatelessWidget {
  final AreaBook areas;
  final HighlightBook highlights;
  final JourneyData data;
  final ValueChanged<String> onAreaOpened;
  final ValueChanged<Highlight> onHighlightOpened;
  final VoidCallback onAddHighlight, onAllHighlights, onDailyHistory;
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
  });
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          key: const ValueKey('journey-content'),
          padding: const EdgeInsets.all(DaylockSpace.lg),
          children: [
            Text('Journey', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 4),
            Text(
              "What you've been building",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 28),
            const DaylockLabel('YOUR AREAS'),
            const SizedBox(height: 8),
            const Text('Across your recorded days'),
            const SizedBox(height: 16),
            for (final area in areas.active)
              JourneyAreaCard(
                key: ValueKey('journey-area-${area.id}'),
                area: area,
                summary: data.forArea(area.id),
                onTap: () => onAreaOpened(area.id),
              ),
            const SizedBox(height: 20),
            const DaylockLabel('RECENT HIGHLIGHTS'),
            const SizedBox(height: 8),
            if (highlights.highlights.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Big milestones, small firsts, memorable days. Keep the moments that matter to you.',
                ),
              ),
            for (final highlight in highlights.newestFirst.take(3))
              JourneyHighlightTile(
                highlight: highlight,
                areas: areas,
                onTap: () => onHighlightOpened(highlight),
              ),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('add-highlight'),
                  onPressed: onAddHighlight,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Highlight'),
                ),
                if (highlights.highlights.isNotEmpty)
                  TextButton(
                    key: const ValueKey('all-highlights'),
                    onPressed: onAllHighlights,
                    child: const Text('All Highlights'),
                  ),
              ],
            ),
            if (areas.areas.any((a) => a.isArchived)) ...[
              const SizedBox(height: 28),
              const DaylockLabel('PAST CHAPTERS'),
              const SizedBox(height: 8),
              const Text('Parts of your life, kept here to revisit.'),
              const SizedBox(height: 16),
              for (final area in areas.areas.where((a) => a.isArchived))
                JourneyAreaCard(
                  key: ValueKey('journey-area-${area.id}'),
                  area: area,
                  summary: data.forArea(area.id),
                  onTap: () => onAreaOpened(area.id),
                ),
            ],
            const SizedBox(height: 28),
            const Divider(),
            ListTile(
              key: const ValueKey('daily-history'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('Daily history'),
              subtitle: const Text(
                'Your calendar, commitments and recorded days',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: onDailyHistory,
            ),
          ],
        ),
      ),
    ),
  );
}

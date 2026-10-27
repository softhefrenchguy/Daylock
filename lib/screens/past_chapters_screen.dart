import 'package:flutter/material.dart';

import '../design/journey_area_grid.dart';
import '../models/area.dart';
import '../models/highlight.dart';
import '../services/journey_service.dart';

class PastChaptersScreen extends StatelessWidget {
  final AreaBook areas;
  final HighlightBook highlights;
  final JourneyData data;
  final ValueChanged<String> onAreaOpened;
  final VoidCallback onManageAreas;
  const PastChaptersScreen({
    super.key,
    required this.areas,
    required this.highlights,
    required this.data,
    required this.onAreaOpened,
    required this.onManageAreas,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Past Chapters')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                areas.areas.any((a) => a.isArchived)
                    ? 'Parts of your life, kept here to revisit.'
                    : 'Archived Areas will stay here, along with their history.',
              ),
              const SizedBox(height: 16),
              JourneyAreaGrid(
                areas: areas.areas.where((a) => a.isArchived).toList(),
                data: data,
                highlights: highlights,
                onAreaOpened: onAreaOpened,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onManageAreas,
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('Manage Areas'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

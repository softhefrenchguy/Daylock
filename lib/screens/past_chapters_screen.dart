import '../l10n/l10n.dart';

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
    appBar: AppBar(title: Text(context.l10n.pastChapters)),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                areas.areas.any((a) => a.isArchived)
                    ? context.l10n.pastChaptersIntro
                    : context.l10n.pastChaptersEmpty,
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
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: onManageAreas,
                  icon: const Icon(Icons.tune_rounded),
                  label: Text(context.l10n.manageAreas),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

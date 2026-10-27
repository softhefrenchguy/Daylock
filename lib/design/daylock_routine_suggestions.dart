import 'package:flutter/material.dart';

import '../models/routine.dart';
import '../models/area.dart';
import 'daylock_areas.dart';
import '../services/routine_service.dart';
import 'daylock_widgets.dart';

class DaylockRoutineSuggestions extends StatelessWidget {
  final List<RoutineSuggestion> suggestions;
  final AreaBook? areas;
  final void Function(RoutineSuggestion, RoutineAction) onAction;
  const DaylockRoutineSuggestions({
    super.key,
    required this.suggestions,
    this.areas,
    required this.onAction,
  });
  @override
  Widget build(BuildContext context) => ExpansionTile(
    key: const ValueKey('routine-suggestions'),
    expansionAnimationStyle: AnimationStyle(
      duration: daylockMotion(context),
      reverseDuration: daylockMotion(context),
    ),
    tilePadding: EdgeInsets.zero,
    childrenPadding: EdgeInsets.zero,
    title: const DaylockLabel('ROUTINE SUGGESTIONS'),
    subtitle: Text('${suggestions.length} available for tomorrow'),
    children: [
      for (final suggestion in suggestions)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                suggestion.routineName,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                suggestion.step.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (suggestion.step.focusTarget != null)
                Text(suggestion.step.focusTarget!),
              if (areas != null)
                AreaBadge(
                  area: areas!.forNewCommitment(suggestion.step.areaId),
                ),
              Wrap(
                spacing: 4,
                children: [
                  for (final action in RoutineAction.values)
                    TextButton(
                      key: ValueKey(
                        'routine-${action.name}-${suggestion.routineId}',
                      ),
                      onPressed: () => onAction(suggestion, action),
                      child: Text(switch (action) {
                        RoutineAction.accept => 'Accept',
                        RoutineAction.skip => 'Skip',
                        RoutineAction.dismiss => 'Dismiss',
                      }),
                    ),
                ],
              ),
              const Divider(),
            ],
          ),
        ),
    ],
  );
}

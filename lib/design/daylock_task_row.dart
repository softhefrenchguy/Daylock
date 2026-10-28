import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/area.dart';
import 'daylock_areas.dart';
import 'journey_surface.dart';

String stopwatchLabel(int milliseconds) {
  final seconds = milliseconds ~/ 1000;
  final hours = seconds ~/ 3600;
  final minutes = (seconds ~/ 60 % 60).toString().padLeft(2, '0');
  final remainder = (seconds % 60).toString().padLeft(2, '0');
  return hours > 0
      ? '${hours.toString().padLeft(2, '0')}:$minutes:$remainder'
      : '$minutes:$remainder';
}

class DaylockTaskRow extends StatelessWidget {
  final Task task;
  final Area? area;
  final DateTime currentTime;
  final VoidCallback onGoalChanged, onFocusToggled;
  final VoidCallback? onDetailsRequested;
  const DaylockTaskRow({
    super.key,
    required this.task,
    this.area,
    required this.currentTime,
    required this.onGoalChanged,
    required this.onFocusToggled,
    this.onDetailsRequested,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final elapsed = task.focusMillisecondsAt(currentTime);
    final timerAction = task.isFocusRunning
        ? 'Pause stopwatch'
        : elapsed > 0
        ? 'Resume stopwatch'
        : 'Start stopwatch';
    final accent = area == null ? colors.primary : Color(area!.colour);
    final areaLabel = area == null
        ? null
        : '${area!.name}${area!.isArchived ? ' (archived)' : ''}';
    return JourneySurface(
      accent: accent,
      emphasized: true,
      radius: 16,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (task.isExcused)
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                onTap: onDetailsRequested,
                leading: const Icon(Icons.shield_outlined),
                title: Text(task.name),
                subtitle: Text(
                  'Excused${areaLabel == null ? '' : ' \u00b7 $areaLabel'}',
                ),
                trailing: const Icon(Icons.more_horiz_rounded),
              )
            else
              CheckboxListTile(
                key: ValueKey('complete-${task.id}'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: task.isCompleted,
                activeColor: Color.lerp(accent, Colors.white, .3),
                checkColor: colors.surface,
                onChanged: (_) => onGoalChanged(),
                title: Row(
                  children: [
                    if (area != null) ...[
                      Icon(
                        areaIcons[area!.icon] ?? Icons.wb_sunny_outlined,
                        size: 28,
                        color: accent,
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.name,
                            style: theme.textTheme.titleMedium!.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 3),
                          if (task.isCompleted && elapsed > 0)
                            Wrap(
                              spacing: 8,
                              children: [
                                Text(
                                  stopwatchLabel(elapsed),
                                  key: ValueKey('stopwatch-time-${task.id}'),
                                  style: theme.textTheme.bodySmall,
                                ),
                                Text(
                                  'Recorded time',
                                  style: theme.textTheme.bodySmall!.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            )
                          else if (areaLabel != null)
                            Text(
                              areaLabel,
                              style: theme.textTheme.bodySmall!.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          if (task.focusTarget != null && !task.isCompleted)
                            Text(
                              task.focusTarget!,
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                secondary: onDetailsRequested == null
                    ? null
                    : IconButton(
                        tooltip: 'Actions for ${task.name}',
                        onPressed: onDetailsRequested,
                        icon: const Icon(Icons.more_horiz_rounded),
                      ),
              ),
            if (task.outcome == TaskOutcome.incomplete ||
                (task.isExcused && elapsed > 0))
              Padding(
                padding: const EdgeInsets.only(left: 14, right: 8),
                child: Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      stopwatchLabel(elapsed),
                      key: ValueKey('stopwatch-time-${task.id}'),
                      style:
                          (task.isFocusRunning
                                  ? theme.textTheme.headlineSmall
                                  : theme.textTheme.titleMedium)!
                              .copyWith(
                                color: task.isFocusRunning
                                    ? colors.onSurface
                                    : colors.onSurfaceVariant,
                                fontWeight: task.isFocusRunning
                                    ? FontWeight.bold
                                    : null,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                    ),
                    if (task.outcome == TaskOutcome.incomplete)
                      TextButton.icon(
                        key: ValueKey('stopwatch-toggle-${task.id}'),
                        onPressed: onFocusToggled,
                        icon: Icon(
                          task.isFocusRunning
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(timerAction),
                        style: TextButton.styleFrom(
                          backgroundColor: accent.withValues(
                            alpha: task.isFocusRunning ? .25 : .09,
                          ),
                          foregroundColor: colors.onSurface,
                        ),
                      )
                    else
                      Text('Recorded time', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

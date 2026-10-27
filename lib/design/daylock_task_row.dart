import 'package:flutter/material.dart';

import '../models/task.dart';
import 'daylock_theme.dart';
import 'daylock_palette.dart';

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
  final DateTime currentTime;
  final VoidCallback onGoalChanged, onFocusToggled;
  final VoidCallback? onDetailsRequested;
  const DaylockTaskRow({
    super.key,
    required this.task,
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
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: DaylockSpace.sm),
        decoration: BoxDecoration(
          color: task.isFocusRunning
              ? DaylockColors.of(context).focusActiveSurface
              : null,
          borderRadius: BorderRadius.circular(DaylockSpace.radius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.isExcused)
              ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: onDetailsRequested,
                leading: Icon(
                  Icons.shield_outlined,
                  color: colors.onSurfaceVariant,
                ),
                title: Text(task.name, style: theme.textTheme.titleLarge),
                subtitle: const Text('Excused'),
                trailing: const Icon(
                  Icons.more_horiz_rounded,
                  semanticLabel: 'Task details and actions',
                ),
              )
            else
              Material(
                color: Colors.transparent,
                child: CheckboxListTile(
                  key: ValueKey('complete-${task.id}'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    task.name,
                    style: theme.textTheme.titleLarge!.copyWith(
                      color: task.isCompleted
                          ? colors.onSurfaceVariant
                          : colors.onSurface,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  value: task.isCompleted,
                  onChanged: (_) => onGoalChanged(),
                ),
              ),
            if (task.focusTarget != null)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Text(
                  task.focusTarget!,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            if (task.outcome == TaskOutcome.incomplete || elapsed > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Semantics(
                      label: '${stopwatchLabel(elapsed)} recorded',
                      child: ExcludeSemantics(
                        child: Text(
                          stopwatchLabel(elapsed),
                          key: ValueKey('stopwatch-time-${task.id}'),
                          style: theme.textTheme.titleMedium!.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                    if (task.outcome == TaskOutcome.incomplete)
                      Semantics(
                        label:
                            '${task.isFocusRunning ? 'Pause' : 'Start'} stopwatch: ${task.name}',
                        child: TextButton.icon(
                          key: ValueKey('stopwatch-toggle-${task.id}'),
                          onPressed: onFocusToggled,
                          icon: Icon(
                            task.isFocusRunning
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                          label: Text(
                            task.isFocusRunning
                                ? 'Pause stopwatch'
                                : 'Start stopwatch',
                          ),
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

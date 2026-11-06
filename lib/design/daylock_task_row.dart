import 'package:flutter/material.dart';

import '../models/area.dart';
import '../models/task.dart';
import 'area_tones.dart';

String stopwatchLabel(int milliseconds) {
  final seconds = milliseconds ~/ 1000;
  final hours = seconds ~/ 3600;
  final minutes = (seconds ~/ 60 % 60).toString().padLeft(2, '0');
  final remainder = (seconds % 60).toString().padLeft(2, '0');
  return hours > 0
      ? '${hours.toString().padLeft(2, '0')}:$minutes:$remainder'
      : '$minutes:$remainder';
}

/// One commitment on Today. Only the round checkbox keeps it; tapping the row
/// opens its actions, so a stray tap can never complete a commitment.
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
    final scheme = theme.colorScheme;
    final elapsed = task.focusMillisecondsAt(currentTime);
    final timerAction = task.isFocusRunning
        ? 'Pause stopwatch'
        : elapsed > 0
        ? 'Resume stopwatch'
        : 'Start stopwatch';
    final tones = AreaTones.forContext(
      context,
      area == null ? scheme.primary : Color(area!.colour),
    );
    final areaLabel = area == null
        ? null
        : '${area!.name}${area!.isArchived ? ' (archived)' : ''}';
    final kept = task.isCompleted;
    final excused = task.isExcused;
    final muted = kept || excused;

    final details = <String>[
      ?areaLabel,
      if (kept) 'kept',
      if (excused) 'Excused',
    ];

    return InkWell(
      onTap: onDetailsRequested,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 2, 4),
        child: Row(
          children: [
            if (excused)
              SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.shield_outlined,
                  color: scheme.onSurfaceVariant,
                  semanticLabel: 'Excused',
                ),
              )
            else
              SizedBox(
                width: 48,
                height: 48,
                child: Transform.scale(
                  scale: 1.15,
                  child: Checkbox(
                    key: ValueKey('complete-${task.id}'),
                    value: kept,
                    onChanged: (_) => onGoalChanged(),
                    activeColor: tones.ink,
                    checkColor: tones.onInk,
                    side: BorderSide(color: tones.ink, width: 2),
                    semanticLabel: kept
                        ? 'Kept: ${task.name}'
                        : 'Keep ${task.name}',
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.name,
                      style: theme.textTheme.bodyLarge!.copyWith(
                        fontSize: 17,
                        height: 1.3,
                        color: muted
                            ? scheme.onSurfaceVariant
                            : scheme.onSurface,
                        decoration: kept ? TextDecoration.lineThrough : null,
                        decorationColor: scheme.outline,
                      ),
                    ),
                    if (details.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          details.join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall!.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: excused
                                ? scheme.onSurfaceVariant
                                : tones.ink,
                          ),
                        ),
                      ),
                    if (task.focusTarget != null && !kept && !excused)
                      Text(
                        task.focusTarget!,
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    if (task.outcome == TaskOutcome.incomplete &&
                        (elapsed > 0 || task.isFocusRunning))
                      Text(
                        stopwatchLabel(elapsed),
                        key: ValueKey('stopwatch-time-${task.id}'),
                        style: theme.textTheme.bodySmall!.copyWith(
                          fontSize: 13,
                          color: task.isFocusRunning
                              ? tones.ink
                              : scheme.onSurfaceVariant,
                          fontWeight: task.isFocusRunning
                              ? FontWeight.w700
                              : null,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    if (elapsed > 0 && muted)
                      Wrap(
                        spacing: 6,
                        children: [
                          Text(
                            stopwatchLabel(elapsed),
                            key: ValueKey('stopwatch-time-${task.id}'),
                            style: theme.textTheme.bodySmall!.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          Text(
                            'Recorded time',
                            style: theme.textTheme.bodySmall!.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            if (task.outcome == TaskOutcome.incomplete) ...[
              IconButton(
                key: ValueKey('stopwatch-toggle-${task.id}'),
                tooltip: timerAction,
                onPressed: onFocusToggled,
                style: task.isFocusRunning
                    ? IconButton.styleFrom(backgroundColor: tones.tint)
                    : null,
                color: task.isFocusRunning
                    ? tones.ink
                    : scheme.onSurfaceVariant,
                icon: Icon(
                  task.isFocusRunning
                      ? Icons.pause_rounded
                      : Icons.timer_outlined,
                  size: 22,
                ),
              ),
            ],
            if (onDetailsRequested != null)
              IconButton(
                tooltip: 'Actions for ${task.name}',
                onPressed: onDetailsRequested,
                color: scheme.onSurfaceVariant,
                icon: const Icon(Icons.more_vert_rounded, size: 22),
              ),
          ],
        ),
      ),
    );
  }
}

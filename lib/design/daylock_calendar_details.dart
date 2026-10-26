import 'package:flutter/material.dart';

import '../models/calendar_activity.dart';
import '../models/event.dart';
import '../models/task.dart';
import '../models/area.dart';
import 'daylock_areas.dart';
import 'daylock_plan_rows.dart';
import 'daylock_theme.dart';
import 'daylock_widgets.dart';

class DaylockCalendarCommitments extends StatelessWidget {
  final CalendarDayActivity activity;
  final AreaBook? areas;
  const DaylockCalendarCommitments({
    super.key,
    required this.activity,
    this.areas,
  });

  @override
  Widget build(BuildContext context) {
    if (activity.isFuture) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final tasks = activity.commitments;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: activity.isToday
              ? 'Today commitments, read-only. Manage commitments in Today.'
              : 'Commitment history, read-only',
          excludeSemantics: true,
          child: DaylockLabel(
            activity.isToday ? 'TODAY’S COMMITMENTS' : 'COMMITMENT HISTORY',
          ),
        ),
        const SizedBox(height: DaylockSpace.sm),
        if (!activity.isRecorded)
          Text(
            'No commitment history recorded.',
            style: theme.textTheme.bodyMedium,
          )
        else if (tasks.isEmpty)
          Text(
            activity.isToday
                ? 'No commitments for today.'
                : 'No commitments recorded. Neutral day.',
            style: theme.textTheme.bodyMedium,
          )
        else ...[
          if (activity.eligibleCount == 0)
            Text('No eligible commitments', style: theme.textTheme.bodyLarge)
          else
            Wrap(
              spacing: 16,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${activity.completionPercentage!.round()}%',
                  key: const ValueKey('calendar-completion-percentage'),
                  style: theme.textTheme.headlineLarge!.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  '${activity.completedCount} / ${activity.eligibleCount} complete',
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          if (activity.excusedCount > 0) ...[
            const SizedBox(height: 4),
            Text(
              '${activity.excusedCount} excused',
              key: const ValueKey('calendar-excused-count'),
              style: theme.textTheme.bodyMedium!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (activity.eligibleCount > 0) ...[
            const SizedBox(height: 12),
            DaylockProgress(
              value: activity.completedCount / activity.eligibleCount,
              label: 'Commitment completion for selected date',
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Recorded Focus: ${recordedFocusLabel(activity.focusMilliseconds)}',
            key: const ValueKey('calendar-recorded-focus'),
            style: theme.textTheme.bodyMedium!.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          for (final task in tasks) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Icon(
                      task.type == TaskType.goal
                          ? Icons.flag_outlined
                          : Icons.timelapse_rounded,
                      size: DaylockSpace.icon,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.name,
                          style: theme.textTheme.bodyLarge!.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                        Text(
                          '${task.type == TaskType.goal ? 'Goal' : 'Focus'} · ${task.outcome.label}',
                          style: theme.textTheme.bodySmall!.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (task.excuseReason != null)
                          Text(
                            'Reason: ${task.excuseReason}',
                            style: theme.textTheme.bodyMedium!.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        if (areas != null)
                          AreaBadge(area: areas!.resolve(task.areaId)),
                        if (task.type == TaskType.focus) ...[
                          Text(
                            '${recordedFocusLabel(task.accumulatedFocusMilliseconds)} / ${task.minimumFocusMinutes} min',
                            style: theme.textTheme.bodyMedium!.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (task.focusTarget != null)
                            Text(
                              task.focusTarget!,
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    task.isExcused
                        ? Icons.shield_outlined
                        : task.isCompleted
                        ? Icons.check_circle_outline_rounded
                        : Icons.radio_button_unchecked_rounded,
                    semanticLabel: task.isExcused
                        ? 'Excused'
                        : task.isCompleted
                        ? 'Completed'
                        : 'Incomplete',
                    size: DaylockSpace.icon,
                    color: task.isCompleted
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                ],
              ),
            ),
            const Divider(),
          ],
        ],
      ],
    );
  }
}

class DaylockCalendarEventRow extends StatelessWidget {
  final Event event;
  final DateTime date;
  final VoidCallback onView;
  final VoidCallback onDelete;
  const DaylockCalendarEventRow({
    super.key,
    required this.event,
    required this.date,
    required this.onView,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final row = Semantics(
      button: true,
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(8),
        child: DaylockPlanEventRow(
          event: event,
          date: date,
          minimumTimelineWidth: 220,
        ),
      ),
    );
    final actions = event.isExternal
        ? Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.lock_outline,
              size: DaylockSpace.icon,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              semanticLabel: 'Read-only cached event',
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Edit ${event.title}',
                icon: const Icon(Icons.edit_outlined),
                onPressed: onView,
              ),
              IconButton(
                tooltip: 'Delete ${event.title}',
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              ),
            ],
          );
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked =
                constraints.maxWidth < 340 ||
                MediaQuery.textScalerOf(context).scale(14) > 24;
            if (stacked && !event.isExternal) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  row,
                  Align(alignment: Alignment.centerRight, child: actions),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: row),
                actions,
              ],
            );
          },
        ),
        const Divider(),
      ],
    );
  }
}

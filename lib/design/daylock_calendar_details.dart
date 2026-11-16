import '../l10n/l10n.dart';

import 'package:flutter/material.dart';

import '../models/calendar_activity.dart';
import '../models/event.dart';
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
              ? context.l10n.calTodayReadOnly
              : context.l10n.calHistoryReadOnly,
          excludeSemantics: true,
          child: DaylockLabel(
            activity.isToday
                ? context.l10n.calTodayLabel
                : context.l10n.calHistoryLabel,
          ),
        ),
        const SizedBox(height: DaylockSpace.sm),
        if (!activity.isRecorded)
          Text(context.l10n.calNoHistory, style: theme.textTheme.bodyMedium)
        else if (tasks.isEmpty)
          Text(
            activity.isToday
                ? context.l10n.calNoCommitmentsToday
                : context.l10n.calNeutralDay,
            style: theme.textTheme.bodyMedium,
          )
        else ...[
          if (activity.eligibleCount == 0)
            Text(
              context.l10n.noEligibleCommitments,
              style: theme.textTheme.bodyLarge,
            )
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
                  context.l10n.keptOfEligible(
                    activity.completedCount,
                    activity.eligibleCount,
                  ),
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          if (activity.excusedCount > 0) ...[
            const SizedBox(height: 4),
            Text(
              context.l10n.excusedCount(activity.excusedCount),
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
              label: context.l10n.calCompletionLabel,
            ),
          ],
          const SizedBox(height: 12),
          Text(
            context.l10n.calRecordedTime(
              recordedFocusLabel(activity.focusMilliseconds, context.l10n),
            ),
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
                      Icons.flag_outlined,
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
                          context.l10n.calCommitmentOutcome(
                            context.l10n.taskOutcome(task.outcome),
                          ),
                          style: theme.textTheme.bodySmall!.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (task.excuseReason != null)
                          Text(
                            context.l10n.calReason(task.excuseReason!),
                            style: theme.textTheme.bodyMedium!.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        if (areas != null)
                          AreaBadge(area: areas!.resolve(task.areaId)),
                        if (task.accumulatedFocusMilliseconds > 0 ||
                            task.focusTarget != null) ...[
                          Text(
                            context.l10n.durationRecorded(
                              recordedFocusLabel(
                                task.accumulatedFocusMilliseconds,
                                context.l10n,
                              ),
                            ),
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
                        ? context.l10n.outcomeExcused
                        : task.isCompleted
                        ? context.l10n.outcomeCompleted
                        : context.l10n.outcomeIncomplete,
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
              semanticLabel: context.l10n.calReadOnlyCached,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: context.l10n.editNamed(event.title),
                icon: const Icon(Icons.edit_outlined),
                onPressed: onView,
              ),
              IconButton(
                tooltip: context.l10n.deleteNamed(event.title),
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
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: actions,
                  ),
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

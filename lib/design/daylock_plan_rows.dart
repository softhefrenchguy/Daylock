import 'package:flutter/material.dart';

import '../models/event.dart';
import '../models/task.dart';
import 'daylock_theme.dart';

// Descriptive type icons, never completion controls. No fixed row height.
class DaylockPlanTaskRow extends StatelessWidget {
  final Task task;
  const DaylockPlanTaskRow({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Commitment',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.check_box_outline_blank_rounded,
                  color: theme.colorScheme.primary,
                  size: DaylockSpace.icon,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          task.name,
                          style: theme.textTheme.bodyLarge!.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (task.focusTarget != null)
                    Text(
                      task.focusTarget!,
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DaylockPlanEventRow extends StatelessWidget {
  final Event event;
  final DateTime date;
  final double minimumTimelineWidth;
  const DaylockPlanEventRow({
    super.key,
    required this.event,
    required this.date,
    this.minimumTimelineWidth = 280,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = Text(
      event.timeLabelForDate(date),
      style: theme.textTheme.labelLarge!.copyWith(fontSize: 13),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event.title,
          style: theme.textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          event.source.label,
          style: theme.textTheme.bodySmall!.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DaylockSpace.sm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked =
              constraints.maxWidth < minimumTimelineWidth ||
              MediaQuery.textScalerOf(context).scale(13) > 20;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!stacked) ...[
                SizedBox(width: 88, child: time),
                const SizedBox(width: DaylockSpace.sm),
              ],
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                        width: 2,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.only(left: 12),
                  child: stacked
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [time, details],
                        )
                      : details,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/task.dart';
import 'daylock_theme.dart';
import 'daylock_palette.dart';
import 'daylock_widgets.dart';

class DaylockTaskRow extends StatelessWidget {
  final Task task;
  final DateTime currentTime;
  final VoidCallback onGoalChanged;
  final VoidCallback onFocusToggled;
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
    final semantic = DaylockColors.of(context);
    final completed = task.isCompleted;
    if (task.isExcused) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: onDetailsRequested,
        leading: Icon(Icons.shield_outlined, color: colors.onSurfaceVariant),
        title: Text(
          task.name,
          style: theme.textTheme.titleLarge!.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            task.type == TaskType.goal
                ? 'EXCUSED · GOAL'
                : 'EXCUSED · FOCUS · ${task.accumulatedFocusMilliseconds ~/ 60000} / ${task.minimumFocusMinutes} min',
            style: theme.textTheme.bodySmall!.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        trailing: const Icon(
          Icons.more_horiz_rounded,
          semanticLabel: 'Task details and actions',
        ),
      );
    }
    final title = AnimatedDefaultTextStyle(
      duration: daylockMotion(context),
      style: theme.textTheme.titleLarge!.copyWith(
        color: completed ? colors.onSurfaceVariant : colors.onSurface,
        decoration: completed && task.type == TaskType.goal
            ? TextDecoration.lineThrough
            : null,
      ),
      child: Text(task.name),
    );
    if (task.type == TaskType.goal) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: DaylockSpace.sm),
        child: CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: title,
          subtitle: const Padding(
            padding: EdgeInsets.only(top: DaylockSpace.xs),
            child: DaylockLabel('GOAL'),
          ),
          value: completed,
          onChanged: (value) {
            task.isCompleted = value!;
            onGoalChanged();
          },
        ),
      );
    }
    final elapsed = task.focusMillisecondsAt(currentTime);
    final minimum = task.minimumFocusMinutes! * 60000;
    final seconds = elapsed ~/ 1000;
    final hours = seconds ~/ 3600;
    final clock = hours > 0
        ? '${hours.toString().padLeft(2, '0')}:${(seconds ~/ 60 % 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}'
        : '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    return AnimatedContainer(
      duration: daylockMotion(context),
      margin: const EdgeInsets.symmetric(vertical: DaylockSpace.md),
      padding: const EdgeInsets.all(DaylockSpace.md),
      decoration: BoxDecoration(
        color: task.isFocusRunning
            ? semantic.focusActiveSurface
            : semantic.focusSurface,
        borderRadius: BorderRadius.circular(DaylockSpace.radius),
        border: Border.all(
          color: task.isFocusRunning ? colors.primary : colors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.center_focus_strong_rounded,
                size: DaylockSpace.icon,
                color: colors.primary,
              ),
              const SizedBox(width: DaylockSpace.sm),
              Expanded(
                child: DaylockLabel(
                  task.isFocusRunning ? 'FOCUS / RUNNING' : 'FOCUS',
                  color: colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: DaylockSpace.sm),
          title,
          if (task.focusTarget != null) ...[
            const SizedBox(height: DaylockSpace.xs),
            Text(
              task.focusTarget!,
              style: theme.textTheme.bodyMedium!.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: DaylockSpace.lg),
          // Do not announce a changing clock every second to screen readers.
          ExcludeSemantics(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                clock,
                style: theme.textTheme.headlineLarge!.copyWith(
                  fontSize: 40,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          Text(
            '${elapsed ~/ 60000} / ${task.minimumFocusMinutes} min',
            style: theme.textTheme.bodyMedium!.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DaylockSpace.md),
          DaylockProgress(
            value: elapsed / minimum,
            label: '${task.name} focus progress',
          ),
          const SizedBox(height: DaylockSpace.md),
          Semantics(
            label:
                '${completed
                    ? 'Completed'
                    : task.isFocusRunning
                    ? 'Pause focus'
                    : 'Start focus'}: ${task.name}',
            child: DaylockAction(
              label: completed
                  ? 'Complete'
                  : task.isFocusRunning
                  ? 'Pause'
                  : 'Start',
              icon: completed
                  ? Icons.check_rounded
                  : task.isFocusRunning
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              onPressed: completed ? null : onFocusToggled,
            ),
          ),
        ],
      ),
    );
  }
}

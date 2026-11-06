import 'package:flutter/material.dart';

import '../design/area_tones.dart';
import '../design/daylock_scene.dart';
import '../design/daylock_surfaces.dart';
import '../design/daylock_theme.dart';
import '../design/daylock_widgets.dart';
import '../models/area.dart';
import '../models/task.dart';

class TaskActionsSheet extends StatelessWidget {
  final Task task;
  final Area? area;
  final DateTime currentTime;
  final bool Function() canChange;
  const TaskActionsSheet({
    super.key,
    required this.task,
    this.area,
    required this.currentTime,
    required this.canChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    void choose(TaskOutcome outcome) {
      if (context.mounted &&
          canChange() &&
          ModalRoute.of(context)?.isCurrent == true) {
        Navigator.pop(context, outcome);
      }
    }

    final scheme = theme.colorScheme;
    final tones = AreaTones.forContext(
      context,
      area == null ? scheme.primary : Color(area!.colour),
    );
    final elapsed = task.focusMillisecondsAt(currentTime);
    final status = switch (task.outcome) {
      TaskOutcome.completed => 'Kept',
      TaskOutcome.excused => 'Excused',
      TaskOutcome.incomplete => 'Not kept yet',
    };
    Widget action({
      required Key key,
      required IconData icon,
      required Color color,
      required String label,
      required TaskOutcome outcome,
    }) => ListTile(
      key: key,
      minTileHeight: 60,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: DaylockIconTile(icon: icon, color: color),
      title: Text(label, style: theme.textTheme.bodyLarge),
      onTap: () => choose(outcome),
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          DaylockSpace.lg,
          0,
          DaylockSpace.lg,
          DaylockSpace.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(task.name, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(
              [
                if (area != null) area!.name,
                status,
                if (elapsed > 0) '${recordedFocusLabel(elapsed)} recorded',
              ].join(' · '),
              style: theme.textTheme.bodyMedium!.copyWith(
                color: area == null ? scheme.onSurfaceVariant : tones.ink,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (task.excuseReason != null) ...[
              const SizedBox(height: 14),
              Text(
                'Excuse reason',
                style: theme.textTheme.labelLarge!.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(task.excuseReason!, style: theme.textTheme.bodyLarge),
            ],
            const SizedBox(height: 18),
            DaylockGroup(
              color: Color.alphaBlend(
                scheme.onSurface.withValues(alpha: .04),
                scheme.surfaceContainerLow,
              ),
              children: [
                action(
                  key: const ValueKey('task-mark-completed'),
                  icon: Icons.check_rounded,
                  color: daylockGold(theme.brightness),
                  label: 'Mark completed',
                  outcome: TaskOutcome.completed,
                ),
                action(
                  key: const ValueKey('task-excuse'),
                  icon: Icons.shield_outlined,
                  color: DaylockHues.blue,
                  label: 'Excuse task',
                  outcome: TaskOutcome.excused,
                ),
                action(
                  key: const ValueKey('task-reset'),
                  icon: Icons.restart_alt_rounded,
                  color: DaylockHues.grey,
                  label: 'Reset to incomplete',
                  outcome: TaskOutcome.incomplete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ExcuseReasonDialog extends StatefulWidget {
  final bool Function() canChange;
  final String? initialReason;
  const ExcuseReasonDialog({
    super.key,
    required this.canChange,
    this.initialReason,
  });
  @override
  State<ExcuseReasonDialog> createState() => _ExcuseReasonDialogState();
}

class _ExcuseReasonDialogState extends State<ExcuseReasonDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _reason;
  @override
  void initState() {
    super.initState();
    _reason = TextEditingController(text: widget.initialReason);
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    if (!mounted ||
        !widget.canChange() ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    if (!_form.currentState!.validate()) return;
    Navigator.pop(context, _reason.text.trim());
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('Excuse commitment'),
    content: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What outside circumstance prevented you from completing it?',
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const ValueKey('excuse-reason'),
            controller: _reason,
            decoration: const InputDecoration(labelText: 'Reason'),
            maxLines: 3,
            maxLength: Task.maxExcuseReasonLength,
            textCapitalization: TextCapitalization.sentences,
            validator: (value) {
              final reason = value?.trim() ?? '';
              if (reason.isEmpty) return 'Enter a short reason.';
              // TextField counts graphemes; the persisted model bounds String
              // length. Check both so multi-code-unit text cannot bypass it.
              if (reason.length > Task.maxExcuseReasonLength) {
                return 'Please shorten this reason.';
              }
              return null;
            },
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const ValueKey('confirm-excuse'),
        onPressed: _submit,
        child: const Text('Excuse task'),
      ),
    ],
  );
}

import 'package:flutter/material.dart';

import '../design/daylock_theme.dart';
import '../design/daylock_widgets.dart';
import '../models/task.dart';

class TaskActionsSheet extends StatelessWidget {
  final Task task;
  final DateTime currentTime;
  final bool Function() canChange;
  const TaskActionsSheet({
    super.key,
    required this.task,
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

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DaylockSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.name, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            DaylockLabel(task.outcome.name.toUpperCase()),
            if (task.focusMillisecondsAt(currentTime) > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${recordedFocusLabel(task.focusMillisecondsAt(currentTime))} recorded',
              ),
            ],
            if (task.excuseReason != null) ...[
              const SizedBox(height: 16),
              const DaylockLabel('EXCUSE REASON'),
              const SizedBox(height: 4),
              Text(task.excuseReason!),
            ],
            const SizedBox(height: 16),
            ListTile(
              key: const ValueKey('task-mark-completed'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Mark completed'),
              onTap: () => choose(TaskOutcome.completed),
            ),
            ListTile(
              key: const ValueKey('task-excuse'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.shield_outlined),
              title: const Text('Excuse task'),
              onTap: () => choose(TaskOutcome.excused),
            ),
            ListTile(
              key: const ValueKey('task-reset'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.restart_alt_rounded),
              title: const Text('Reset to incomplete'),
              onTap: () => choose(TaskOutcome.incomplete),
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

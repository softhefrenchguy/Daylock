import 'package:flutter/material.dart';

import '../design/daylock_theme.dart';
import '../models/task.dart';

// The sheet returns a validated Task. MainApp still owns and persists the plan.
class CommitmentEditor extends StatefulWidget {
  final bool Function() canCreate;
  final Task? initialTask;
  final String heading, submitLabel;
  const CommitmentEditor({
    super.key,
    required this.canCreate,
    this.initialTask,
    this.heading = 'New commitment',
    this.submitLabel = 'Add commitment',
  });

  @override
  State<CommitmentEditor> createState() => _CommitmentEditorState();
}

class _CommitmentEditorState extends State<CommitmentEditor> {
  final _name = TextEditingController();
  final _minutes = TextEditingController();
  final _target = TextEditingController();
  TaskType _type = TaskType.goal;
  bool _submitted = false;
  int? get _minimum => int.tryParse(_minutes.text.trim());
  bool get _validDuration =>
      _type == TaskType.goal || (_minimum != null && _minimum! > 0);
  bool get _valid => _name.text.trim().isNotEmpty && _validDuration;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    if (task != null) {
      _name.text = task.name;
      _minutes.text = task.minimumFocusMinutes?.toString() ?? '';
      _target.text = task.focusTarget ?? '';
      _type = task.type;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _minutes.dispose();
    _target.dispose();
    super.dispose();
  }

  void _submit() {
    if (!mounted || _submitted || !widget.canCreate() || !_valid) return;
    _submitted = true;
    final task = Task(
      name: _name.text.trim(),
      type: _type,
      minimumFocusMinutes: _type == TaskType.focus ? _minimum : null,
      focusTarget: _type == TaskType.focus ? _target.text : null,
    );
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(task);
  }

  InputDecoration _field(String label, {String? error}) {
    final colors = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colors.outline),
    );
    return InputDecoration(
      labelText: label,
      errorText: error,
      filled: true,
      fillColor: colors.surfaceContainerLow,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.all(DaylockSpace.md),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      top: false,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          DaylockSpace.lg,
          DaylockSpace.md,
          DaylockSpace.lg,
          DaylockSpace.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.heading,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Close editor',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: DaylockSpace.md),
            LayoutBuilder(
              builder: (context, constraints) {
                void select(TaskType type) => setState(() => _type = type);
                if (constraints.maxWidth < 300 &&
                    MediaQuery.textScalerOf(context).scale(15) > 22) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final type in TaskType.values)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: DaylockSpace.sm,
                          ),
                          child: Semantics(
                            selected: type == _type,
                            inMutuallyExclusiveGroup: true,
                            child: OutlinedButton(
                              onPressed: () => select(type),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: type == _type
                                    ? Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                    : null,
                              ),
                              child: Text(
                                type == TaskType.goal ? 'Goal' : 'Focus',
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }
                return SegmentedButton<TaskType>(
                  expandedInsets: EdgeInsets.zero,
                  segments: const [
                    ButtonSegment(value: TaskType.goal, label: Text('Goal')),
                    ButtonSegment(value: TaskType.focus, label: Text('Focus')),
                  ],
                  selected: {_type},
                  onSelectionChanged: (selection) => select(selection.single),
                );
              },
            ),
            const SizedBox(height: DaylockSpace.md),
            TextField(
              key: const ValueKey('commitment-name'),
              controller: _name,
              enabled: true,
              decoration: _field('Commitment name'),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
            if (_type == TaskType.focus) ...[
              const SizedBox(height: DaylockSpace.md),
              TextField(
                key: const ValueKey('focus-minutes'),
                controller: _minutes,
                keyboardType: TextInputType.number,
                decoration: _field(
                  'Minimum minutes',
                  error: _minutes.text.isNotEmpty && !_validDuration
                      ? 'Enter a whole number greater than zero.'
                      : null,
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: DaylockSpace.md),
              TextField(
                key: const ValueKey('focus-target'),
                controller: _target,
                decoration: _field('Target (optional)'),
                onSubmitted: (_) => _submit(),
              ),
            ],
            const SizedBox(height: DaylockSpace.md),
            FilledButton.icon(
              key: const ValueKey('save-commitment'),
              onPressed: _valid ? _submit : null,
              icon: const Icon(Icons.add_rounded, size: DaylockSpace.icon),
              label: Text(widget.submitLabel),
            ),
          ],
        ),
      ),
    ),
  );
}

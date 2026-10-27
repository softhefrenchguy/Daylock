import 'package:flutter/material.dart';

import '../design/daylock_theme.dart';
import '../models/task.dart';
import '../models/area.dart';
import '../design/daylock_areas.dart';

// The sheet returns a validated Task. MainApp still owns and persists the plan.
class CommitmentEditor extends StatefulWidget {
  final bool Function() canCreate;
  final Task? initialTask;
  final AreaBook? areas;
  final String heading, submitLabel;
  const CommitmentEditor({
    super.key,
    required this.canCreate,
    this.initialTask,
    this.areas,
    this.heading = 'New commitment',
    this.submitLabel = 'Add commitment',
  });

  @override
  State<CommitmentEditor> createState() => _CommitmentEditorState();
}

class _CommitmentEditorState extends State<CommitmentEditor> {
  final _name = TextEditingController();
  bool _submitted = false;
  late final AreaBook _areas;
  late String _areaId;
  bool get _valid => _name.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _areas = widget.areas ?? AreaBook.initial();
    _areaId = _areas.resolve(task?.areaId).id;
    if (task != null) {
      _name.text = task.name;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (!mounted || _submitted || !widget.canCreate() || !_valid) return;
    _submitted = true;
    final old = widget.initialTask;
    final task = old == null
        ? Task(name: _name.text.trim(), areaId: _areaId)
        : Task.fromJson({
            ...old.toJson(),
            'name': _name.text.trim(),
            'areaId': _areaId,
          });
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
            const SizedBox(height: DaylockSpace.md),
            AreaSelector(
              book: _areas,
              selectedId: _areaId,
              onChanged: (id) => setState(() => _areaId = id),
            ),
            const SizedBox(height: DaylockSpace.sm),
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

import '../l10n/l10n.dart';

import 'package:flutter/material.dart';

import '../design/daylock_theme.dart';
import '../models/task.dart';
import '../models/area.dart';
import '../design/daylock_areas.dart';
import '../models/routine.dart';
import 'repeat_picker.dart';

// The sheet returns a validated Task. MainApp still owns and persists the plan.
class CommitmentEditor extends StatefulWidget {
  final bool Function() canCreate;
  final Task? initialTask;
  final AreaBook? areas;
  final String? heading, submitLabel;

  /// Shows the Repeat row when set: the plan date a new repeat starts from.
  final DateTime? repeatFrom;
  final RoutineSchedule? initialRepeat;

  /// Set when the task belongs to a multi-step rotation, which is managed in
  /// Routines rather than from a single commitment.
  final String? rotationName;

  /// Called just before the sheet closes, only if Repeat was changed.
  /// A null schedule means the user chose Never.
  final ValueChanged<RoutineSchedule?>? onRepeatChanged;
  const CommitmentEditor({
    super.key,
    required this.canCreate,
    this.initialTask,
    this.areas,
    this.heading,
    this.submitLabel,
    this.repeatFrom,
    this.initialRepeat,
    this.rotationName,
    this.onRepeatChanged,
  });

  @override
  State<CommitmentEditor> createState() => _CommitmentEditorState();
}

class _CommitmentEditorState extends State<CommitmentEditor> {
  final _name = TextEditingController();
  bool _submitted = false;
  late final AreaBook _areas;
  late String _areaId;
  RoutineSchedule? _repeat;
  bool _pickingRepeat = false;
  bool get _valid => _name.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _areas = widget.areas ?? AreaBook.initial();
    _areaId = _areas.resolve(task?.areaId).id;
    _repeat = widget.initialRepeat;
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
    if (!identical(_repeat, widget.initialRepeat)) {
      widget.onRepeatChanged?.call(_repeat);
    }
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(task);
  }

  Future<void> _chooseRepeat() async {
    final from = widget.repeatFrom;
    if (from == null || _pickingRepeat || _submitted) return;
    _pickingRepeat = true;
    final choice = await showRepeatPicker(
      context,
      initial: _repeat,
      from: from,
    );
    _pickingRepeat = false;
    if (mounted && choice != null) setState(() => _repeat = choice.schedule);
  }

  Widget _repeatRow(BuildContext context) {
    final theme = Theme.of(context);
    final rotation = widget.rotationName;
    final label = rotation != null
        ? '$rotation · ${context.l10n.repeatLabel(widget.initialRepeat ?? RoutineSchedule.daily())}'
        : _repeat == null
        ? context.l10n.repeatNever
        : context.l10n.repeatLabel(_repeat!);
    return ListTile(
      key: const ValueKey('commitment-repeat'),
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.repeat_rounded, color: theme.colorScheme.primary),
      title: Text(context.l10n.repeat),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            key: const ValueKey('commitment-repeat-label'),
            style: theme.textTheme.bodyLarge!.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (rotation != null) Text(context.l10n.partOfRotation),
        ],
      ),
      trailing: rotation == null
          ? const Icon(Icons.chevron_right_rounded)
          : null,
      onTap: rotation == null ? _chooseRepeat : null,
    );
  }

  InputDecoration _field(String label, {String? error}) => InputDecoration(
    labelText: label,
    hintText: context.l10n.commitmentHint,
    errorText: error,
    contentPadding: const EdgeInsets.all(18),
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      top: false,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsetsDirectional.fromSTEB(
          DaylockSpace.lg,
          0,
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
                    widget.heading ?? context.l10n.newCommitment,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.closeEditor,
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
              decoration: _field(context.l10n.commitmentName),
              style: Theme.of(context).textTheme.bodyLarge!
                  .copyWith(fontSize: 17),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 18),
            AreaSelector(
              book: _areas,
              selectedId: _areaId,
              onChanged: (id) => setState(() => _areaId = id),
            ),
            if (widget.repeatFrom != null) ...[
              const SizedBox(height: DaylockSpace.sm),
              _repeatRow(context),
            ],
            const SizedBox(height: DaylockSpace.lg),
            FilledButton.icon(
              key: const ValueKey('save-commitment'),
              onPressed: _valid ? _submit : null,
              icon: const Icon(Icons.add_rounded, size: DaylockSpace.icon),
              label: Text(widget.submitLabel ?? context.l10n.addCommitment),
            ),
          ],
        ),
      ),
    ),
  );
}

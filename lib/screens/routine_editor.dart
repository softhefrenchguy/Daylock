import 'package:flutter/material.dart';

import '../design/daylock_theme.dart';
import '../models/routine.dart';
import '../models/task.dart';
import '../models/area.dart';
import '../design/daylock_areas.dart';
import 'commitment_editor.dart';
import 'repeat_picker.dart';

class RoutineEditor extends StatefulWidget {
  final Routine? routine;
  final AreaBook? areas;

  /// The first plan date a new or changed schedule counts from.
  final DateTime? planningDate;
  const RoutineEditor({super.key, this.routine, this.areas, this.planningDate});
  @override
  State<RoutineEditor> createState() => _RoutineEditorState();
}

class _RoutineEditorState extends State<RoutineEditor> {
  late final TextEditingController _name;
  late final List<RoutineStep> _steps;
  bool _submitted = false;
  bool _openingStep = false;
  late RoutineSchedule _schedule;
  DateTime get _from {
    if (widget.planningDate != null) return widget.planningDate!;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.routine?.name);
    _steps = List.of(widget.routine?.steps ?? []);
    _schedule = widget.routine?.schedule ?? RoutineSchedule.daily(from: _from);
  }

  Future<void> _chooseSchedule() async {
    if (_openingStep || _submitted) return;
    _openingStep = true;
    final choice = await showRepeatPicker(
      context,
      initial: _schedule,
      from: _from,
      allowNever: false,
    );
    _openingStep = false;
    if (mounted && choice?.schedule != null) {
      setState(() => _schedule = choice!.schedule!);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _addStep([int? index]) async {
    if (_openingStep || _submitted) return;
    _openingStep = true;
    final old = index == null ? null : _steps[index];
    final task = await showModalBottomSheet<Task>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (sheetContext) => Theme(
        data: Theme.of(Navigator.of(sheetContext).context),
        child: CommitmentEditor(
          canCreate: () => mounted && !_submitted,
          initialTask: old?.toTask(),
          areas: widget.areas,
          heading: old == null ? 'New routine step' : 'Edit routine step',
          submitLabel: old == null ? 'Add step' : 'Save step',
        ),
      ),
    );
    _openingStep = false;
    if (mounted && task != null) {
      setState(() {
        final step = RoutineStep.fromTask(task, id: old?.id);
        if (index == null) {
          _steps.add(step);
        } else {
          _steps[index] = step;
        }
      });
    }
  }

  void _move(int index, int offset) {
    final destination = index + offset;
    if (destination < 0 || destination >= _steps.length) return;
    setState(() {
      final item = _steps.removeAt(index);
      _steps.insert(destination, item);
    });
  }

  void _save() {
    if (_submitted || _name.text.trim().isEmpty || _steps.isEmpty) return;
    _submitted = true;
    final old = widget.routine;
    final routine = old == null
        ? Routine(
            id: newRoutineId(),
            name: _name.text,
            steps: _steps,
            schedule: _schedule,
          )
        : old.edit(name: _name.text, steps: _steps, schedule: _schedule);
    Navigator.pop(context, routine);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.routine == null ? 'Create routine' : 'Edit routine'),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(DaylockSpace.lg),
        children: [
          TextField(
            key: const ValueKey('routine-name'),
            controller: _name,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Routine name'),
          ),
          const SizedBox(height: 8),
          ListTile(
            key: const ValueKey('routine-schedule'),
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.repeat_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Repeat'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _schedule.label,
                  key: const ValueKey('routine-schedule-label'),
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Next: ${_schedule.upcoming(_from).map(repeatDateLabel).join(' · ')}',
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _chooseSchedule,
          ),
          const SizedBox(height: 8),
          Text(
            _steps.length > 1
                ? 'A rotation: each due day adds the next step, in this order. A step you remove comes back next time.'
                : 'Each due day adds this to tomorrow’s plan automatically. Add more steps to make a rotation.',
          ),
          const SizedBox(height: 16),
          for (var index = 0; index < _steps.length; index++)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${index + 1}. ${_steps[index].name}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_steps[index].focusTarget != null)
                  Text(_steps[index].focusTarget!),
                if (widget.areas != null)
                  AreaBadge(area: widget.areas!.resolve(_steps[index].areaId)),
                Wrap(
                  children: [
                    IconButton(
                      tooltip: 'Edit step ${index + 1}',
                      onPressed: () => _addStep(index),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Move step ${index + 1} up',
                      onPressed: index == 0 ? null : () => _move(index, -1),
                      icon: const Icon(Icons.arrow_upward),
                    ),
                    IconButton(
                      tooltip: 'Move step ${index + 1} down',
                      onPressed: index == _steps.length - 1
                          ? null
                          : () => _move(index, 1),
                      icon: const Icon(Icons.arrow_downward),
                    ),
                    IconButton(
                      tooltip: 'Remove step ${index + 1}',
                      onPressed: () => setState(() => _steps.removeAt(index)),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
                const Divider(),
              ],
            ),
          OutlinedButton.icon(
            key: const ValueKey('add-routine-step'),
            onPressed: () => _addStep(),
            icon: const Icon(Icons.add),
            label: Text(
              _steps.isEmpty ? 'Add commitment' : 'Add rotation step',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey('save-routine'),
            onPressed: _name.text.trim().isEmpty || _steps.isEmpty
                ? null
                : _save,
            child: const Text('Save routine'),
          ),
        ],
      ),
    ),
  );
}

import 'package:flutter/material.dart';

import '../design/daylock_theme.dart';
import '../models/routine.dart';
import '../models/area.dart';
import 'repeat_picker.dart' show repeatDateLabel;
import 'routine_editor.dart';

class RoutinesScreen extends StatelessWidget {
  final RoutineBook book;
  final AreaBook? areas;

  /// The next plan a routine can land in (tomorrow). Defaults to tomorrow.
  final DateTime? planningDate;
  final ValueChanged<Routine> onSaved;
  final ValueChanged<String> onDeleted;
  const RoutinesScreen({
    super.key,
    required this.book,
    this.areas,
    this.planningDate,
    required this.onSaved,
    required this.onDeleted,
  });
  Future<void> _edit(BuildContext context, [Routine? routine]) async {
    final saved = await Navigator.of(context).push<Routine>(
      MaterialPageRoute(
        builder: (_) =>
            RoutineEditor(routine: routine, areas: areas, planningDate: _from),
      ),
    );
    if (context.mounted && saved != null) onSaved(saved);
  }

  DateTime get _from {
    if (planningDate != null) return planningDate!;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  String _summary(Routine routine) {
    final next = routine.schedule.nextDue(_from);
    final when = [
      routine.schedule.label,
      if (next != null)
        next == _from ? 'next: tomorrow' : 'next: ${repeatDateLabel(next)}',
    ].join(' · ');
    if (!routine.isRotation) return when;
    return '$when\n'
        '${routine.steps.length} steps · up next: ${routine.nextStep.name}';
  }

  Future<void> _delete(BuildContext context, Routine routine) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Delete routine?'),
        content: Text(
          'Stop repeating ${routine.name}? Commitments already in your plans and history stay.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (context.mounted && yes == true) onDeleted(routine.id);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Routines')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(DaylockSpace.lg),
        children: [
          const Text(
            'Routines add themselves to tomorrow’s plan on the days they’re due. Remove one from a plan to skip just that day. A rotation with several steps moves on only after a step stays in your plan.',
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            key: const ValueKey('create-routine'),
            onPressed: () => _edit(context),
            icon: const Icon(Icons.add),
            label: const Text('Create routine or rotation'),
          ),
          const SizedBox(height: 16),
          if (book.routines.isEmpty) const Text('No routines yet.'),
          for (final routine in book.routines) ...[
            ListTile(
              key: ValueKey('routine-${routine.id}'),
              contentPadding: EdgeInsets.zero,
              title: Text(
                routine.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              leading: const Icon(Icons.repeat_rounded),
              subtitle: Text(_summary(routine)),
              onTap: () => _edit(context, routine),
            ),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => _edit(context, routine),
                  child: const Text('Edit'),
                ),
                TextButton(
                  key: ValueKey('delete-routine-${routine.id}'),
                  onPressed: () => _delete(context, routine),
                  child: const Text('Delete'),
                ),
              ],
            ),
            const Divider(),
          ],
        ],
      ),
    ),
  );
}

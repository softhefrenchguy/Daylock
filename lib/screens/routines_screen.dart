import '../l10n/l10n.dart';

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

  String _summary(BuildContext context, Routine routine) {
    final next = routine.schedule.nextDue(_from);
    final when = [
      context.l10n.repeatLabel(routine.schedule),
      if (next != null)
        next == _from
            ? context.l10n.nextTomorrow
            : context.l10n.nextDate(repeatDateLabel(next)),
    ].join(' · ');
    if (!routine.isRotation) return when;
    return '$when\n'
        '${context.l10n.rotationSummary(routine.steps.length, routine.nextStep.name)}';
  }

  Future<void> _delete(BuildContext context, Routine routine) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(context.l10n.deleteRoutineTitle),
        content: Text(context.l10n.deleteRoutineBody(routine.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (context.mounted && yes == true) onDeleted(routine.id);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.routines)),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(DaylockSpace.lg),
        children: [
          Text(context.l10n.routinesIntro),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            key: const ValueKey('create-routine'),
            onPressed: () => _edit(context),
            icon: const Icon(Icons.add),
            label: Text(context.l10n.createRoutineOrRotation),
          ),
          const SizedBox(height: 16),
          if (book.routines.isEmpty) Text(context.l10n.noRoutinesYet),
          for (final routine in book.routines) ...[
            ListTile(
              key: ValueKey('routine-${routine.id}'),
              contentPadding: EdgeInsets.zero,
              title: Text(
                routine.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              leading: const Icon(Icons.repeat_rounded),
              subtitle: Text(_summary(context, routine)),
              onTap: () => _edit(context, routine),
            ),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => _edit(context, routine),
                  child: Text(context.l10n.edit),
                ),
                TextButton(
                  key: ValueKey('delete-routine-${routine.id}'),
                  onPressed: () => _delete(context, routine),
                  child: Text(context.l10n.delete),
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

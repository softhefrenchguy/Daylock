import 'package:flutter/material.dart';

import '../design/daylock_theme.dart';
import '../models/routine.dart';
import 'routine_editor.dart';

class RoutinesScreen extends StatelessWidget {
  final RoutineBook book;
  final ValueChanged<Routine> onSaved;
  final ValueChanged<String> onDeleted;
  const RoutinesScreen({
    super.key,
    required this.book,
    required this.onSaved,
    required this.onDeleted,
  });
  Future<void> _edit(BuildContext context, [Routine? routine]) async {
    final saved = await Navigator.of(context).push<Routine>(
      MaterialPageRoute(builder: (_) => RoutineEditor(routine: routine)),
    );
    if (context.mounted && saved != null) onSaved(saved);
  }

  Future<void> _delete(BuildContext context, Routine routine) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Delete routine?'),
        content: Text(
          'Remove ${routine.name}? Accepted commitments and historical plans will be kept.',
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
            'One suggestion per routine for each planning date. Accept or Skip advances the cycle. Dismiss keeps the same step for another day.',
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            key: const ValueKey('create-routine'),
            onPressed: () => _edit(context),
            icon: const Icon(Icons.add),
            label: const Text('Create routine'),
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
              subtitle: Text(
                '${routine.steps.length} steps · Next: ${routine.nextStep.name}',
              ),
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

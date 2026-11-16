import 'package:flutter/material.dart';

import '../design/daylock_surfaces.dart';
import '../design/daylock_theme.dart';
import '../design/daylock_widgets.dart';
import '../l10n/l10n.dart';
import '../models/daylock_state.dart';
import '../services/backup_service.dart';

/// Export everything to a file, or restore from one. Android's automatic
/// backup also covers Daylock; this is for moving phones or keeping a copy.
class BackupScreen extends StatefulWidget {
  final BackupFiles files;

  /// The current state, ready to save.
  final DaylockState Function() current;

  /// Replaces all Daylock data; returns false if it couldn't be saved.
  final Future<bool> Function(DaylockState) restore;
  final DateTime Function() now;
  const BackupScreen({
    super.key,
    required this.files,
    required this.current,
    required this.restore,
    required this.now,
  });

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _busy = false;

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _export() async {
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      final now = widget.now();
      final saved = await widget.files.save(
        DaylockBackup.fileName(now),
        DaylockBackup.encode(widget.current(), now),
      );
      if (saved) _say(l.backupSaved);
    } catch (_) {
      _say(l.backupFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      final text = await widget.files.open();
      if (text == null || !mounted) return;
      final DaylockState state;
      try {
        state = DaylockBackup.decode(text);
      } on BackupException catch (error) {
        _say(switch (error.problem) {
          BackupProblem.notDaylock => l.backupNotDaylock,
          BackupProblem.newerVersion => l.backupNewer,
          BackupProblem.damaged => l.backupDamaged,
        });
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(dialogContext.l10n.backupConfirmTitle),
          content: Text(dialogContext.l10n.backupConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(dialogContext.l10n.cancel),
            ),
            FilledButton(
              key: const ValueKey('backup-confirm-restore'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(dialogContext.l10n.backupReplace),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      _say(await widget.restore(state) ? l.backupRestored : l.backupFailed);
    } catch (_) {
      _say(l.backupFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final supported = widget.files.supported;
    return Scaffold(
      appBar: AppBar(title: Text(l.backupTitle)),
      body: ListView(
        padding: const EdgeInsets.all(DaylockSpace.lg),
        children: [
          DaylockGroup(
            children: [
              ListTile(
                leading: const Icon(Icons.cloud_done_outlined),
                title: Text(l.backupAutoTitle),
                subtitle: Text(l.backupAutoBody),
              ),
            ],
          ),
          const SizedBox(height: DaylockSpace.lg),
          DaylockLabel(l.backupFileLabel),
          const SizedBox(height: DaylockSpace.sm),
          if (!supported)
            Text(l.backupAndroidOnly, style: TextStyle(color: muted))
          else ...[
            Text(l.backupExportBody, style: TextStyle(color: muted)),
            const SizedBox(height: DaylockSpace.md),
            DaylockAction(
              key: const ValueKey('backup-export'),
              label: l.backupExport,
              icon: Icons.file_download_outlined,
              onPressed: _busy ? null : _export,
            ),
            const SizedBox(height: DaylockSpace.lg),
            Text(l.backupImportBody, style: TextStyle(color: muted)),
            const SizedBox(height: DaylockSpace.md),
            OutlinedButton.icon(
              key: const ValueKey('backup-import'),
              onPressed: _busy ? null : _import,
              icon: const Icon(Icons.restore_rounded),
              label: Text(l.backupImport),
            ),
          ],
        ],
      ),
    );
  }
}

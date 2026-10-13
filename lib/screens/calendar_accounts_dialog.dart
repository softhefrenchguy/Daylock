import 'package:flutter/material.dart';

import '../models/calendar_account.dart';
import '../models/calendar_cache.dart';
import '../services/calendar_failure.dart';

class CalendarAccountsDialog extends StatefulWidget {
  final CalendarCache cache;
  final bool Function(CalendarProviderType) canConnect;
  final Future<CalendarCache> Function(CalendarProviderType) onConnect;
  final Future<CalendarCache> Function(String) onDisconnect;
  final Future<CalendarCache> Function(String) onSynchronize;
  final bool Function(CalendarProviderType)? canReconnect;
  final Future<CalendarCache> Function(String)? onReconnect;
  final Future<CalendarCache> Function(ConnectedCalendar, bool)
  onVisibilityChanged;

  const CalendarAccountsDialog({
    super.key,
    required this.cache,
    required this.canConnect,
    required this.onConnect,
    required this.onDisconnect,
    required this.onSynchronize,
    this.canReconnect,
    this.onReconnect,
    required this.onVisibilityChanged,
  });

  @override
  State<CalendarAccountsDialog> createState() => _CalendarAccountsDialogState();
}

class _CalendarAccountsDialogState extends State<CalendarAccountsDialog> {
  late CalendarCache _cache;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cache = widget.cache;
  }

  Future<void> _run(Future<CalendarCache> Function() operation) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final cache = await operation();
      if (mounted) setState(() => _cache = cache);
    } catch (error) {
      // Avoid displaying provider exceptions, which may contain credentials.
      if (mounted) {
        setState(
          () => _error = error is CalendarFailure ? error.message : 'Could not update this account. Cached events are still available. Try again or reconnect.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect(CalendarAccount account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Disconnect account?'),
        content: Text(
          'Remove ${account.displayName} and its cached events from Daylock? Your external calendar will stay unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (mounted && confirmed == true) {
      await _run(() => widget.onDisconnect(account.id));
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      scrollable: true,
      title: const Text('Calendar accounts'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'External calendars are read-only. Cached events are available offline.',
              ),
              if (CalendarProviderType.values.any(
                (type) => !widget.canConnect(type),
              )) ...[
                const SizedBox(height: 12),
                const Text(
                  'Account sign-in is not available for the disabled providers in this version.',
                ),
              ],
              for (final type in CalendarProviderType.values)
                OutlinedButton(
                  onPressed: _busy || !widget.canConnect(type)
                      ? null
                      : () => _run(() => widget.onConnect(type)),
                  child: Text('Connect ${type.label}'),
                ),
              if (_cache.accounts.isEmpty) const Text('No connected accounts.'),
              for (final account in _cache.accounts) ...[
                const Divider(),
                Text(
                  account.provider.label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(account.displayName),
                if (account.email != null) Text(account.email!),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: _busy || !widget.canConnect(account.provider)
                          ? null
                          : () => _run(() => widget.onSynchronize(account.id)),
                      child: const Text('Sync now'),
                    ),
                    TextButton(
                      onPressed: _busy ? null : () => _disconnect(account),
                      child: const Text('Disconnect'),
                    ),
                    if (widget.canReconnect?.call(account.provider) == true &&
                        widget.onReconnect != null)
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => _run(() => widget.onReconnect!(account.id)),
                        child: const Text('Reconnect'),
                      ),
                  ],
                ),
                for (final calendar in _cache.calendars.where(
                  (c) => c.accountId == account.id,
                ))
                  CheckboxListTile(
                    key: ValueKey('calendar-visibility-${calendar.key}'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(calendar.name),
                    subtitle: Text(
                      calendar.lastSyncedAt == null
                          ? 'Not synced yet'
                          : 'Last synced ${MaterialLocalizations.of(context).formatShortDate(calendar.lastSyncedAt!.toLocal())} ${TimeOfDay.fromDateTime(calendar.lastSyncedAt!.toLocal()).format(context)}',
                    ),
                    value: calendar.isVisible,
                    onChanged: _busy
                        ? null
                        : (visible) => _run(
                            () =>
                                widget.onVisibilityChanged(calendar, visible!),
                          ),
                  ),
                if (!_cache.calendars.any((c) => c.accountId == account.id))
                  const Text('Sync to load this account’s calendars.'),
              ],
              if (_busy) const LinearProgressIndicator(),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    ),
  );
}

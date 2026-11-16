import '../l10n/l10n.dart';

import 'package:flutter/material.dart';

import '../design/daylock_widgets.dart';
import '../design/daylock_theme.dart';
import '../design/journey_surface.dart';
import '../models/notification_preferences.dart';
import '../services/notifications/notification_service.dart';

class NotificationSettingsSection extends StatelessWidget {
  final NotificationPreferences preferences;
  final ValueChanged<NotificationPreferences> onChanged;
  final NotificationService service;
  const NotificationSettingsSection({
    super.key,
    required this.preferences,
    required this.onChanged,
    required this.service,
  });

  Future<void> _time(BuildContext context, bool plan) async {
    final minute = plan ? preferences.planMinute : preferences.commitmentMinute;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
    );
    if (time == null || !context.mounted) return;
    final value = time.hour * 60 + time.minute;
    onChanged(
      plan
          ? preferences.copyWith(planMinute: value)
          : preferences.copyWith(commitmentMinute: value),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<NotificationStatus>(
    valueListenable: service.status,
    builder: (context, status, _) {
      final supported = status.scheduledDelivery;
      Widget toggle(
        String category,
        String title,
        bool value,
        ValueChanged<bool> changed,
      ) => SwitchListTile(
        key: ValueKey('notification-$category'),
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        value: supported && value,
        subtitle: status.blockedChannels.contains(category)
            ? Text(context.l10n.notifBlockedInSystem)
            : null,
        onChanged: supported ? changed : null,
      );
      Widget time(String key, int minute, bool enabled, bool plan) => ListTile(
        key: ValueKey('notification-$key-time'),
        contentPadding: EdgeInsets.zero,
        title: Text(
          '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}',
        ),
        trailing: const Icon(Icons.schedule_outlined),
        enabled: supported && enabled,
        onTap: supported && enabled ? () => _time(context, plan) : null,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DaylockLabel(context.l10n.notifLabel),
          const SizedBox(height: DaylockSpace.sm),
          Text(switch (status.permission) {
            NotificationPermission.allowed =>
              context.l10n.notifPermissionAllowed,
            NotificationPermission.denied => context.l10n.notifPermissionDenied,
            NotificationPermission.error => context.l10n.notifNeedsAttention,
            NotificationPermission.unknown => context.l10n.notifChecking,
            NotificationPermission.unsupported => context.l10n.notifUnavailable,
          }, key: const ValueKey('notification-status')),
          const SizedBox(height: DaylockSpace.sm),
          ExpansionTile(
            title: Text(context.l10n.notifPermissionHelp),
            tilePadding: EdgeInsets.zero,
            children: [Text(context.l10n.known(status.explanation))],
          ),
          if (supported) ...[
            const SizedBox(height: DaylockSpace.sm),
            OutlinedButton.icon(
              key: const ValueKey('notification-permission'),
              onPressed:
                  status.permission == NotificationPermission.allowed ||
                      status.askedBefore
                  ? service.openSettings
                  : service.requestPermission,
              icon: const Icon(Icons.notifications_outlined),
              label: Text(
                status.permission == NotificationPermission.allowed ||
                        status.askedBefore
                    ? context.l10n.notifOpenSettings
                    : context.l10n.setupAllowNotifications,
              ),
            ),
          ],
          const SizedBox(height: 12),
          JourneySurface(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: [
                  toggle(
                    'plan',
                    context.l10n.notifPlanTomorrow,
                    preferences.planTomorrow,
                    (v) => onChanged(preferences.copyWith(planTomorrow: v)),
                  ),
                  time(
                    'plan',
                    preferences.planMinute,
                    preferences.planTomorrow,
                    true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          JourneySurface(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: [
                  toggle(
                    'commitments',
                    context.l10n.notifCommitmentReminder,
                    preferences.commitments,
                    (v) => onChanged(preferences.copyWith(commitments: v)),
                  ),
                  time(
                    'commitments',
                    preferences.commitmentMinute,
                    preferences.commitments,
                    false,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          JourneySurface(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  toggle(
                    'freedom',
                    context.l10n.notifFreedom,
                    preferences.freedom,
                    (v) => onChanged(preferences.copyWith(freedom: v)),
                  ),
                  Text(context.l10n.notifFreedomHelp),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          JourneySurface(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  toggle(
                    'focus',
                    context.l10n.notifRunningStopwatch,
                    preferences.focus,
                    (v) => onChanged(preferences.copyWith(focus: v)),
                  ),
                  Text(context.l10n.notifRunningStopwatchHelp),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

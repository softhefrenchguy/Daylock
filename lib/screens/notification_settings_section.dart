import 'package:flutter/material.dart';

import '../design/daylock_widgets.dart';
import '../design/daylock_theme.dart';
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
            ? const Text('Blocked in Android system settings')
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
          const DaylockLabel('NOTIFICATIONS'),
          const SizedBox(height: DaylockSpace.sm),
          Text(switch (status.permission) {
            NotificationPermission.allowed => 'System permission: allowed',
            NotificationPermission.denied => 'System permission: not allowed',
            NotificationPermission.error =>
              'Notification setup needs attention',
            NotificationPermission.unknown => 'Checking system permission…',
            NotificationPermission.unsupported =>
              'Scheduled notifications unavailable',
          }, key: const ValueKey('notification-status')),
          const SizedBox(height: DaylockSpace.sm),
          Text(status.explanation),
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
                    ? 'Open notification settings'
                    : 'Allow notifications',
              ),
            ),
          ],
          toggle(
            'plan',
            'Plan Tomorrow',
            preferences.planTomorrow,
            (v) => onChanged(preferences.copyWith(planTomorrow: v)),
          ),
          time('plan', preferences.planMinute, preferences.planTomorrow, true),
          toggle(
            'commitments',
            'Commitment Reminder',
            preferences.commitments,
            (v) => onChanged(preferences.copyWith(commitments: v)),
          ),
          time(
            'commitments',
            preferences.commitmentMinute,
            preferences.commitments,
            false,
          ),
          toggle(
            'freedom',
            'Freedom Notifications',
            preferences.freedom,
            (v) => onChanged(preferences.copyWith(freedom: v)),
          ),
          const Text('Uses Freedom Time when Freedom Control is enabled.'),
          toggle(
            'focus',
            'Focus Timer Completion',
            preferences.focus,
            (v) => onChanged(preferences.copyWith(focus: v)),
          ),
        ],
      );
    },
  );
}

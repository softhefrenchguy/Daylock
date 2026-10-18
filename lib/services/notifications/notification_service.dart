import 'package:flutter/foundation.dart';

import '../../models/daylock_state.dart';
import '../../models/daily_plan.dart';
import '../freedom_service.dart';

enum NotificationPermission { unknown, allowed, denied, unsupported, error }

class NotificationStatus {
  final NotificationPermission permission;
  final bool scheduledDelivery, askedBefore;
  final String explanation;
  final Set<String> blockedChannels;
  const NotificationStatus({
    this.permission = NotificationPermission.unsupported,
    this.scheduledDelivery = false,
    this.askedBefore = false,
    this.explanation = 'Scheduled notifications are available on Android.',
    this.blockedChannels = const {},
  });
}

NotificationStatus webNotificationStatus({required bool browserApiAvailable}) =>
    NotificationStatus(
      explanation: browserApiAvailable
          ? 'This browser supports notifications, but scheduled reminders are unavailable here. Safari, closed tabs and installed PWAs cannot deliver these reminders without a push service. Use Daylock on Android for scheduled notifications.'
          : 'This browser cannot deliver Daylock notifications. Scheduled reminders are available in the Android app; web/PWA controls are disabled.',
    );

String notificationDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class NotificationTarget {
  final String screen;
  final String? date, taskName;
  final int? taskIndex;
  const NotificationTarget(
    this.screen, {
    this.date,
    this.taskIndex,
    this.taskName,
  });
  factory NotificationTarget.fromJson(Map<String, dynamic> json) =>
      NotificationTarget(
        json['screen'] == 'plan' ? 'plan' : 'today',
        date: json['date'] as String?,
        taskIndex: json['taskIndex'] as int?,
        taskName: json['taskName'] as String?,
      );
}

/// Notification-only mirror: no calendar credentials or excuse text. Today's
/// task order is immutable; a dated index AND name validate Focus taps.
Map<String, dynamic> notificationSnapshot(DaylockState state, DateTime now) {
  Map<String, dynamic> plan(DailyPlan value, {required bool allowTimers}) => {
    'date': notificationDate(value.date),
    'committed': value.isCommitted,
    'tasks': [
      for (final task in value.tasks)
        {
          'name': task.name,
          'outcome': task.outcome.name,
          'minimumMinutes': task.minimumFocusMinutes,
          'deadlineMs': allowTimers && task.isFocusRunning && !task.isCompleted
              ? task.focusStartedAt!.millisecondsSinceEpoch +
                    task.minimumFocusMinutes! * 60000 -
                    task.accumulatedFocusMilliseconds
              : null,
        },
    ],
  };
  final freedom = const FreedomService().evaluate(
    now: now,
    settings: state.freedomSettings,
    todayPlan: state.todayPlan,
    tomorrowPlan: state.tomorrowPlan,
  );
  return {
    'version': 1,
    'preferences': state.notificationPreferences.toJson(),
    'freedom': freedom.settings.toJson(),
    'today': plan(state.todayPlan, allowTimers: true),
    'tomorrow': plan(state.tomorrowPlan, allowTimers: false),
  };
}

/// Scheduling lives outside widgets. Implementations serialize writes and
/// fail closed while a planner save is in progress.
class NotificationService {
  final status = ValueNotifier(const NotificationStatus());
  void Function(NotificationTarget)? onTap;
  Future<void> start() async {}
  Future<void> refresh() async {}
  Future<void> requestPermission() async {}
  Future<void> openSettings() async {}
  Future<void> invalidate() async {}
  Future<void> synchronize(DaylockState state, DateTime now) async {}
  void dispose() => status.dispose();
}

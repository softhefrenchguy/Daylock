import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../models/daylock_state.dart';
import 'notification_service.dart';

NotificationService createNotificationService() =>
    Platform.isAndroid ? AndroidNotificationService() : NotificationService();

class AndroidNotificationService extends NotificationService {
  static const channel = MethodChannel('daylock/notifications');
  final FlutterLocalNotificationsPlugin plugin;
  Future<void> _pending = Future.value();
  bool _closed = false;
  AndroidNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : plugin = plugin ?? FlutterLocalNotificationsPlugin();

  Future<void> _serialize(Future<void> Function() action) {
    final next = _pending.then((_) async {
      if (_closed) return;
      try {
        await action();
      } catch (_) {
        if (!_closed) {
          status.value = const NotificationStatus(
            permission: NotificationPermission.error,
            scheduledDelivery: true,
            explanation:
                'Notifications could not be updated. Reopen Daylock to retry.',
          );
        }
      }
    });
    _pending = next;
    return next;
  }

  @override
  Future<void> start() => _serialize(() async {
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_daylock'),
      ),
    );
    channel.setMethodCallHandler((call) async {
      if (call.method == 'tap' && !_closed) _tap(call.arguments);
    });
    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()!;
    for (final entry in const {
      'plan': 'Plan Tomorrow',
      'commitments': 'Commitment reminders',
      'freedom': 'Freedom',
      'focus': 'Focus completion',
    }.entries) {
      await android.createNotificationChannel(
        AndroidNotificationChannel(
          'daylock_${entry.key}',
          entry.value,
          description: 'Daylock ${entry.value.toLowerCase()}',
          importance: Importance.defaultImportance,
        ),
      );
    }
    final tap = await channel.invokeMethod<String>('takeLaunchTap');
    if (tap != null) _tap(tap);
    await _readStatus();
  });

  void _tap(Object? raw) {
    try {
      onTap?.call(
        NotificationTarget.fromJson(
          jsonDecode(raw as String) as Map<String, dynamic>,
        ),
      );
    } catch (_) {
      /* Ignore malformed or unrelated launch payloads. */
    }
  }

  Future<void> _readStatus() async {
    final native = await channel.invokeMapMethod<String, dynamic>('status');
    if (_closed) return;
    status.value = NotificationStatus(
      permission: native?['allowed'] == true
          ? NotificationPermission.allowed
          : NotificationPermission.denied,
      scheduledDelivery: true,
      askedBefore: native?['askedBefore'] == true,
      blockedChannels: Set<String>.from(
        native?['blockedChannels'] as List? ?? [],
      ),
      explanation: 'Android reminders may be delayed by battery saving or Do Not Disturb. App preferences below are separate from system permission.',
    );
  }

  @override
  Future<void> refresh() => _serialize(() async {
    await channel.invokeMethod<void>('refresh');
    await _readStatus();
  });
  @override
  Future<void> requestPermission() => _serialize(() async {
    final native = await channel.invokeMapMethod<String, dynamic>('status');
    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()!;
    if (native?['askedBefore'] == true) {
      await android.openAppNotificationSettings();
    } else {
      // Persist before opening the dialog; never automatically re-prompt.
      await channel.invokeMethod<void>('markPermissionRequested');
      await android.requestNotificationsPermission();
    }
    await channel.invokeMethod<void>('refresh');
    await _readStatus();
  });
  @override
  Future<void> openSettings() => _serialize(() async {
    await plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()!
        .openAppNotificationSettings();
  });
  @override
  Future<void> invalidate() => _serialize(() async {
    await channel.invokeMethod<void>('invalidate');
  });
  @override
  Future<void> synchronize(DaylockState state, DateTime now) {
    // Encode before queuing: Tasks are mutable.
    final snapshot = jsonEncode(notificationSnapshot(state, now));
    return _serialize(() async {
      await channel.invokeMethod<void>('publish', snapshot);
      await _readStatus();
    });
  }

  @override
  void dispose() {
    _closed = true;
    channel.setMethodCallHandler(null);
    super.dispose();
  }
}

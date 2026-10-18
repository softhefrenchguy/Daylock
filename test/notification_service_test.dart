import 'dart:convert';

import 'package:daylock/services/notifications/notification_service.dart';
import 'package:daylock/services/notifications/notification_service_android.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_preferences_test.dart' show notificationFixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pluginChannel = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<String> calls;
  late bool asked;
  late bool allowed;
  late List<String> blocked;
  late AndroidNotificationService service;
  String? launchedPayload;
  Object? published;
  bool failPublish = false;
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    asked = false;
    allowed = false;
    blocked = [];
    calls = [];
    launchedPayload = null;
    published = null;
    failPublish = false;
    messenger.setMockMethodCallHandler(pluginChannel, (call) async {
      calls.add('plugin:${call.method}');
      if (call.method == 'requestNotificationsPermission') return false;
      if (call.method == 'initialize' ||
          call.method == 'openAppNotificationSettings') {
        return true;
      }
      return null;
    });
    messenger.setMockMethodCallHandler(AndroidNotificationService.channel, (
      call,
    ) async {
      calls.add('native:${call.method}');
      switch (call.method) {
        case 'status':
          return {
            'allowed': allowed,
            'askedBefore': asked,
            'blockedChannels': blocked,
          };
        case 'markPermissionRequested':
          asked = true;
        case 'takeLaunchTap':
          return launchedPayload;
        case 'publish':
          if (failPublish) throw PlatformException(code: 'FAILED');
          published = jsonDecode(call.arguments as String);
      }
      return null;
    });
    service = AndroidNotificationService();
  });
  tearDown(() {
    service.dispose();
    messenger.setMockMethodCallHandler(pluginChannel, null);
    messenger.setMockMethodCallHandler(
      AndroidNotificationService.channel,
      null,
    );
    debugDefaultTargetPlatformOverride = null;
  });
  test(
    'startup and resuming never ask permission; explicit decline is remembered',
    () async {
      await service.start();
      await service.refresh();
      expect(
        calls.where((c) => c.contains('requestNotificationsPermission')),
        isEmpty,
      );
      expect(service.status.value.permission, NotificationPermission.denied);
      await service.requestPermission();
      expect(asked, isTrue);
      expect(
        calls.indexOf('native:markPermissionRequested'),
        lessThan(calls.indexOf('plugin:requestNotificationsPermission')),
      );
      await service.refresh();
      await service.requestPermission();
      expect(
        calls.where((c) => c == 'plugin:requestNotificationsPermission'),
        hasLength(1),
      );
      expect(calls, contains('plugin:openAppNotificationSettings'));
    },
  );
  test(
    'permission revocation and individual channel blocks refresh separately',
    () async {
      allowed = true;
      blocked = ['focus'];
      await service.start();
      expect(service.status.value.permission, NotificationPermission.allowed);
      expect(service.status.value.blockedChannels, {'focus'});
      allowed = false;
      await service.refresh();
      expect(service.status.value.permission, NotificationPermission.denied);
    },
  );
  test('invalidate precedes frozen publication; failures are isolated and retryable', () async {
    await service.start();
    final state = notificationFixture();
    final invalidated = service.invalidate();
    final sync = service.synchronize(state, DateTime(2026, 10, 14));
    state.todayPlan.tasks.single.name = 'Later unsaved edit';
    await invalidated;
    await sync;
    expect(
      calls.indexOf('native:invalidate'),
      lessThan(calls.indexOf('native:publish')),
    );
    expect(
      (((published as Map)['today'] as Map)['tasks'] as List).single['name'],
      'Study maths',
    );
    failPublish = true;
    await service.synchronize(state, DateTime(2026, 10, 14));
    expect(service.status.value.permission, NotificationPermission.error);
    failPublish = false;
    allowed = true;
    await service.synchronize(state, DateTime(2026, 10, 14));
    expect(service.status.value.permission, NotificationPermission.allowed);
  });
  test(
    'cold launch payload is delivered once after channel initialization',
    () async {
      launchedPayload = jsonEncode({
        'screen': 'today',
        'date': '2026-10-14',
        'taskIndex': 0,
        'taskName': 'Study maths',
      });
      final taps = <NotificationTarget>[];
      service.onTap = taps.add;
      await service.start();
      await service.refresh();
      expect(taps, hasLength(1));
      expect(taps.single.taskIndex, 0);
      expect(taps.single.date, '2026-10-14');
    },
  );
}

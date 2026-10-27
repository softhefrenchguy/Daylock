import 'package:daylock/main.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/notification_preferences.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/screens/notification_settings_section.dart';
import 'package:daylock/screens/plan_screen.dart';
import 'package:daylock/screens/task_actions_sheet.dart';
import 'package:daylock/screens/today_screen.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:daylock/services/notifications/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'notification_preferences_test.dart' show notificationFixture;

class _Notifications extends NotificationService {
  final snapshots = <Map<String, dynamic>>[];
  int invalidations = 0, requests = 0;
  _Notifications({bool supported = true}) {
    status.value = supported
        ? const NotificationStatus(
            permission: NotificationPermission.denied,
            scheduledDelivery: true,
            explanation: 'App preferences are separate from permission.',
          )
        : webNotificationStatus(browserApiAvailable: false);
  }
  @override
  Future<void> invalidate() async {
    invalidations++;
  }

  @override
  Future<void> synchronize(DaylockState state, DateTime now) async {
    snapshots.add(notificationSnapshot(state, now));
  }

  @override
  Future<void> requestPermission() async {
    requests++;
  }
}

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );
  testWidgets(
    'all four preference switches remain independent of denied OS permission',
    (tester) async {
      var p = const NotificationPreferences();
      final service = _Notifications();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setState) => NotificationSettingsSection(
                  preferences: p,
                  onChanged: (v) => setState(() => p = v),
                  service: service,
                ),
              ),
            ),
          ),
        ),
      );
      for (final name in ['plan', 'commitments', 'freedom']) {
        final toggle = find.byKey(ValueKey('notification-$name'));
        await tester.ensureVisible(toggle);
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
      }
      expect(
        p.toJson(),
        const NotificationPreferences(
          planTomorrow: false,
          commitments: false,
          freedom: false,
          focus: true,
        ).toJson(),
      );
      expect(service.requests, 0);
      await tester.ensureVisible(
        find.byKey(const ValueKey('notification-permission')),
      );
      await tester.tap(find.byKey(const ValueKey('notification-permission')));
      await tester.pumpAndSettle();
      expect(service.requests, 1);
      service.dispose();
    },
  );
  testWidgets(
    'unsupported web controls are disabled and not displayed as active',
    (tester) async {
      final service = _Notifications(supported: false);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: NotificationSettingsSection(
                preferences: const NotificationPreferences(),
                onChanged: (_) => fail('Unsupported control changed'),
                service: service,
              ),
            ),
          ),
        ),
      );
      for (final tile in tester.widgetList<SwitchListTile>(
        find.byType(SwitchListTile),
      )) {
        expect(tile.onChanged, isNull);
        expect(tile.value, isFalse);
      }
      expect(
        find.byKey(const ValueKey('notification-permission')),
        findsNothing,
      );
      expect(find.text('Scheduled notifications unavailable'), findsOneWidget);
      service.dispose();
    },
  );
  testWidgets('custom Plan time is selected through the picker', (
    tester,
  ) async {
    var p = const NotificationPreferences();
    final service = _Notifications();
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, update) => NotificationSettingsSection(
                preferences: p,
                onChanged: (v) => update(() => p = v),
                service: service,
              ),
            ),
          ),
        ),
      ),
    );
    final time = find.byKey(const ValueKey('notification-plan-time'));
    await tester.ensureVisible(time);
    await tester.tap(time);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '21');
    await tester.enterText(fields.at(1), '15');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(p.planMinute, 1275);
    expect(p.commitmentMinute, 840);
    service.dispose();
  });
  testWidgets(
    'Focus start pause resume completion and excuse publish only after saves',
    (tester) async {
      var now = DateTime(2026, 10, 14, 12);
      await LocalStorage().save(
        notificationFixture(
          task: Task(
            name: 'Study',
            type: TaskType.focus,
            minimumFocusMinutes: 1,
          ),
        ),
      );
      final service = _Notifications();
      await tester.pumpWidget(
        MainApp(notificationService: service, now: () => now),
      );
      await tester.pumpAndSettle();
      Map task() =>
          ((service.snapshots.last['today'] as Map)['tasks'] as List).single
              as Map;
      void toggle() {
        final today = tester.widget<TodayScreen>(find.byType(TodayScreen));
        today.onFocusToggled(today.plan.tasks.single);
      }

      toggle();
      await tester.pumpAndSettle();
      expect(task()['deadlineMs'], isNull);
      now = now.add(const Duration(seconds: 20));
      toggle();
      await tester.pumpAndSettle();
      expect(task()['deadlineMs'], isNull);
      now = now.add(const Duration(seconds: 10));
      toggle();
      await tester.pumpAndSettle();
      expect(task()['deadlineMs'], isNull);
      now = now.add(const Duration(seconds: 40));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(task()['outcome'], 'incomplete');
      expect(
        (await LocalStorage().load())!.todayPlan.tasks.single.isCompleted,
        isFalse,
      );
      final today = tester.widget<TodayScreen>(find.byType(TodayScreen));
      today.onOutcomeChanged!(
        today.plan.tasks.single,
        TaskOutcome.excused,
        'Unexpected event',
      );
      await tester.pumpAndSettle();
      expect(task()['outcome'], 'excused');
      expect(task()['deadlineMs'], isNull);
      expect(service.invalidations, greaterThanOrEqualTo(4));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'notification taps open Plan or the matching Focus task and reject stale tasks',
    (tester) async {
      await LocalStorage().save(notificationFixture());
      final service = _Notifications();
      await tester.pumpWidget(
        MainApp(
          notificationService: service,
          now: () => DateTime(2026, 10, 14, 12),
        ),
      );
      await tester.pumpAndSettle();
      service.onTap!(const NotificationTarget('plan'));
      await tester.pumpAndSettle();
      expect(find.byType(PlanScreen), findsOneWidget);
      service.onTap!(
        const NotificationTarget(
          'today',
          date: '2026-10-14',
          taskIndex: 0,
          taskName: 'Study maths',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TaskActionsSheet), findsOneWidget);
      service.onTap!(
        const NotificationTarget(
          'today',
          date: '2026-10-13',
          taskIndex: 0,
          taskName: 'Study maths',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TaskActionsSheet), findsNothing);
      expect(find.byType(TodayScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

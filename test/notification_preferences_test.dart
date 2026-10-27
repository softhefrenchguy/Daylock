import 'dart:convert';

import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/freedom_settings.dart';
import 'package:daylock/models/notification_preferences.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:daylock/services/notifications/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

DaylockState notificationFixture({
  NotificationPreferences preferences = const NotificationPreferences(),
  Task? task,
}) => DaylockState(
  todayPlan: DailyPlan(
    date: DateTime(2026, 10, 14),
    isCommitted: true,
    tasks: [
      task ??
          Task(
            name: 'Study maths',
            type: TaskType.focus,
            minimumFocusMinutes: 45,
          ),
    ],
  ),
  tomorrowPlan: DailyPlan(
    date: DateTime(2026, 10, 15),
    tasks: [Task(name: 'Walk', type: TaskType.goal)],
  ),
  freedomSettings: const FreedomSettings(enabled: true),
  notificationPreferences: preferences,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );
  test(
    'notification defaults are independently enabled at 20:00 and 14:00',
    () {
      expect(const NotificationPreferences().toJson(), {
        'planTomorrow': true,
        'commitments': true,
        'freedom': true,
        'focus': true,
        'planMinute': 1200,
        'commitmentMinute': 840,
      });
    },
  );
  test('old v2 migration changes no existing planner fields', () async {
    final state = notificationFixture(
      task: Task(
        name: 'Excused',
        type: TaskType.goal,
        outcome: TaskOutcome.excused,
        excuseReason: 'Train cancelled',
      ),
    );
    final old = state.toJson()..remove('notificationPreferences');
    await SharedPreferencesAsync().setString(
      LocalStorage.stateKey,
      jsonEncode(old),
    );
    final restored = (await LocalStorage().load())!;
    expect(
      restored.notificationPreferences.toJson(),
      const NotificationPreferences().toJson(),
    );
    final migrated = jsonDecode(
      (await SharedPreferencesAsync().getString(LocalStorage.stateKey))!,
    ) as Map<String, dynamic>;
    expect(migrated..remove('notificationPreferences'), old);
  });
  test(
    'all toggle combinations and custom times persist and survive rollover',
    () async {
      for (var mask = 0; mask < 16; mask++) {
        final p = NotificationPreferences(
          planTomorrow: mask & 1 != 0,
          commitments: mask & 2 != 0,
          freedom: mask & 4 != 0,
          focus: mask & 8 != 0,
          planMinute: 1315,
          commitmentMinute: 615,
        );
        await LocalStorage().save(notificationFixture(preferences: p));
        final state = (await LocalStorage().load())!;
        expect(state.notificationPreferences.toJson(), p.toJson());
        expect(
          state
              .rollOver(DateTime(2026, 10, 15))
              .notificationPreferences
              .toJson(),
          p.toJson(),
        );
      }
    },
  );
  test(
    'malformed new preferences fail safely and do not replace saved state',
    () async {
      final raw = notificationFixture().toJson();
      (raw['notificationPreferences'] as Map)['planMinute'] = 1440;
      final encoded = jsonEncode(raw);
      await SharedPreferencesAsync().setString(LocalStorage.stateKey, encoded);
      await expectLater(LocalStorage().load(), throwsFormatException);
      expect(
        await SharedPreferencesAsync().getString(LocalStorage.stateKey),
        encoded,
      );
    },
  );
  test('snapshot uses persisted Focus start and accumulated duration without changing either', () {
    final start = DateTime.utc(2026, 10, 14, 12);
    final task = Task(
      name: 'Study',
      type: TaskType.focus,
      minimumFocusMinutes: 45,
      accumulatedFocusMilliseconds: 5 * 60000,
      focusStartedAt: start,
    );
    final state = notificationFixture(task: task);
    final before = state.toJson();
    final data = notificationSnapshot(state, start);
    final focus = ((data['today'] as Map)['tasks'] as List).single as Map;
    expect(
      focus['deadlineMs'],
      isNull,
    );
    expect(state.toJson(), before);
    task.pauseFocus(start.add(const Duration(minutes: 10)));
    expect(
      ((notificationSnapshot(state, start)['today'] as Map)['tasks'] as List)
          .single['deadlineMs'],
      isNull,
    );
    task.startFocus(start.add(const Duration(minutes: 20)));
    expect(
      ((notificationSnapshot(state, start)['today'] as Map)['tasks'] as List)
          .single['deadlineMs'],
      isNull,
    );
    task.changeOutcome(
      TaskOutcome.excused,
      now: start.add(const Duration(minutes: 21)),
      reason: 'Emergency',
    );
    final serialized = jsonEncode(notificationSnapshot(state, start));
    expect(serialized, isNot(contains('Emergency')));
    expect(serialized, isNot(contains('calendarCache')));
    expect(
      ((notificationSnapshot(state, start)['today'] as Map)['tasks'] as List)
          .single['deadlineMs'],
      isNull,
    );
  });
  test('web capabilities never claim closed-tab scheduling is supported', () {
    for (final available in [false, true]) {
      final status = webNotificationStatus(browserApiAvailable: available);
      expect(status.scheduledDelivery, isFalse);
      expect(status.permission, NotificationPermission.unsupported);
      expect(status.explanation, contains('Android'));
    }
  });
}

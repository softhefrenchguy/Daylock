import 'package:daylock/main.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/freedom_settings.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/services/freedom_service.dart';
import 'package:daylock/services/instagram_detection_bridge.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'instagram_detection_flow_test.dart' show RecordingBridge, resume;

final date = DateTime(2026, 10, 13, 18);
final tomorrowDate = DateTime(2026, 10, 14);
Task goal(String name, {bool complete = false}) =>
    Task(name: name, type: TaskType.goal, isCompleted: complete);

NativeFreedomInput payload(DailyPlan today, DailyPlan tomorrow) =>
    NativeFreedomInput.fromEligibility(
      today,
      const FreedomService().evaluate(
        now: date,
        settings: const FreedomSettings(enabled: true),
        todayPlan: today,
        tomorrowPlan: tomorrow,
      ),
      tomorrowPlan: tomorrow,
    );

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  test('Tomorrow summary is an immutable copy of saved counts, excluding excuses and private data', () {
    final tomorrow = DailyPlan(
      date: tomorrowDate,
      tasks: [
        goal('Private title', complete: true),
        Task(
          name: 'Sensitive',
          type: TaskType.goal,
          outcome: TaskOutcome.excused,
          excuseReason: 'Private reason',
        ),
        goal('Unfinished'),
      ],
      isCommitted: true,
    );
    final data = payload(DailyPlan(date: date, tasks: []), tomorrow).values;
    expect(data['tomorrowPlan'], {
      'date': '2026-10-14',
      'eligibleCount': 2,
      'completedCount': 1,
    });
    expect(data['tomorrowCommitted'], true);
    expect(data.toString(), isNot(contains('Private')));
    final summary = data['tomorrowPlan'] as Map;
    expect(() => summary.clear(), throwsUnsupportedError);
    tomorrow.tasks.last.isCompleted = true;
    expect(summary['completedCount'], 1);
    expect(data.containsKey('earned'), false);
    expect(data.containsKey('expiresAt'), false);
  });

  test('Focus deadline retains accumulated time and disappears after excuse, pause or completion', () {
    final focus = Task(
      name: 'Read',
      type: TaskType.focus,
      minimumFocusMinutes: 60,
      accumulatedFocusMilliseconds: 20 * 60000,
    )..startFocus(date);
    final today = DailyPlan(date: date, tasks: [focus]);
    final tomorrow = DailyPlan(date: tomorrowDate, tasks: []);
    expect(
      payload(today, tomorrow).values['focusCompletesAtMs'],
      isNull,
    );
    focus.changeOutcome(
      TaskOutcome.excused,
      now: date.add(const Duration(minutes: 10)),
      reason: 'Power cut',
    );
    expect(
      payload(today, tomorrow).values.containsKey('focusCompletesAtMs'),
      false,
    );
    expect(payload(today, tomorrow).values['eligibleCount'], 0);
    expect(focus.accumulatedFocusMilliseconds, 30 * 60000);
    focus.changeOutcome(
      TaskOutcome.incomplete,
      now: date.add(const Duration(minutes: 10)),
    );
    focus.startFocus(date.add(const Duration(minutes: 10)));
    expect(
      payload(today, tomorrow).values['focusCompletesAtMs'],
      isNull,
    );
    focus.changeOutcome(TaskOutcome.completed, now: date.add(const Duration(minutes: 40)));
    expect(payload(today, tomorrow).values['completedCount'], 1);
    expect(
      payload(today, tomorrow).values.containsKey('focusCompletesAtMs'),
      false,
    );
  });

  for (final minutes in [5, 30, 120]) {
    testWidgets(
      'Persisted native inputs need no Flutter heartbeat after $minutes minutes backgrounded',
      (tester) async {
        var now = date;
        final initial = DaylockState(
          todayPlan: DailyPlan(
            date: date,
            tasks: [goal('Walk')],
            isCommitted: true,
          ),
          tomorrowPlan: DailyPlan(
            date: tomorrowDate,
            tasks: [goal('Read')],
            isCommitted: true,
          ),
          freedomSettings: const FreedomSettings(enabled: true),
        );
        await tester.runAsync(() => LocalStorage().save(initial));
        final bridge = RecordingBridge();
        await tester.pumpWidget(
          MainApp(now: () => now, detectionBridge: bridge),
        );
        await tester.pumpAndSettle();
        for (final state in [
          AppLifecycleState.inactive,
          AppLifecycleState.hidden,
          AppLifecycleState.paused,
        ]) {
          tester.binding.handleAppLifecycleStateChanged(state);
        }
        await tester.pumpAndSettle();
        final count = bridge.publications;
        final latest = bridge.latest;
        now = date.add(Duration(minutes: minutes));
        await tester.pump(Duration(minutes: minutes));
        expect(bridge.publications, count);
        expect(bridge.latest, same(latest));
        expect(bridge.latest!['eligibleCount'], 1);
        expect(bridge.latest!['completedCount'], 0);
        expect(
          (await tester.runAsync(() => LocalStorage().load()))!.toJson(),
          initial.toJson(),
        );
        resume(tester);
        await tester.pumpAndSettle();
        expect(bridge.latest!['date'], '2026-10-13');
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'Resume after native midnight projection performs real rollover and history save',
    (tester) async {
      var now = date;
      final initial = DaylockState(
        todayPlan: DailyPlan(
          date: date,
          tasks: [goal('Yesterday', complete: true)],
          isCommitted: true,
        ),
        tomorrowPlan: DailyPlan(
          date: tomorrowDate,
          tasks: [goal('Next day')],
          isCommitted: true,
        ),
        freedomSettings: const FreedomSettings(enabled: true),
      );
      await tester.runAsync(() => LocalStorage().save(initial));
      final bridge = RecordingBridge();
      await tester.pumpWidget(MainApp(now: () => now, detectionBridge: bridge));
      await tester.pumpAndSettle();
      expect(bridge.latest!['tomorrowPlan'], {
        'date': '2026-10-14',
        'eligibleCount': 1,
        'completedCount': 0,
      });
      now = DateTime(2026, 10, 14, 0, 1);
      resume(tester);
      await tester.pumpAndSettle();
      expect(bridge.latest!['date'], '2026-10-14');
      expect(bridge.latest!['completedCount'], 0);
      expect(bridge.latest!['tomorrowCommitted'], false);
      expect(bridge.latest!['tomorrowPlan'], {
        'date': '2026-10-15',
        'eligibleCount': 0,
        'completedCount': 0,
      });
      final saved = (await tester.runAsync(() => LocalStorage().load()))!;
      expect(saved.todayPlan.tasks.single.name, 'Next day');
      expect(saved.history.forDate(date)!.tasks.single.isCompleted, true);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

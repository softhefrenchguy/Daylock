import 'package:daylock/models/stopwatch_stamp.dart';

import 'navigation_helpers.dart';

import 'package:daylock/main.dart';
import 'package:daylock/design/daylock_task_row.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/screens/today_screen.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'plan_test_helpers.dart';

import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('Plan creates unified commitments with no required time', (
    tester,
  ) async {
    await tester.pumpWidget(MainApp(now: () => DateTime(2026, 10, 7, 12)));
    await tester.pumpAndSettle();
    await _navigate(tester, 'Plan');
    for (final title in ['Read']) {
      await openCommitmentEditor(tester);
      expect(find.text('Goal'), findsNothing);
      expect(find.text('Focus'), findsNothing);
      expect(find.byKey(const ValueKey('focus-minutes')), findsNothing);
      await enterPlanText(
        tester,
        find.byKey(const ValueKey('commitment-name')),
        title,
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Add commitment'));
      await tester.pumpAndSettle();
    }
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    final commit = find.widgetWithText(FilledButton, 'COMMIT THURSDAY');
    await tester.ensureVisible(commit);
    await tester.tap(commit);
    await confirmPlanCommit(tester);
    final saved = (await LocalStorage().load())!;
    expect(saved.tomorrowPlan.isCommitted, isTrue);
    expect(saved.tomorrowPlan.tasks.map((t) => t.name), ['Read']);
    expect(
      saved.tomorrowPlan.tasks.every(
        (t) =>
            t.minimumFocusMinutes == null &&
            t.accumulatedFocusMilliseconds == 0,
      ),
      isTrue,
    );
    expect(find.byType(TextField), findsNothing);
    expect(find.byKey(const ValueKey('open-commitment-editor')), findsNothing);
  });

  testWidgets(
    'Legacy Focus completes immediately and running completion saves uncapped time',
    (tester) async {
      var now = DateTime(2026, 10, 7, 12);
      await _seed(tester, now, [
        Task(name: 'Read', type: TaskType.focus, minimumFocusMinutes: 1),
      ]);
      await tester.pumpWidget(MainApp(now: () => now));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Read'));
      await tester.pumpAndSettle();
      var task = (await LocalStorage().load())!.todayPlan.tasks.single;
      expect(task.isCompleted, isTrue);
      expect(task.accumulatedFocusMilliseconds, 0);
      await tester.tap(find.text('Read'));
      await tester.pumpAndSettle();
      await _tapFocus(tester, 'Read');
      await tester.pumpAndSettle();
      now = now.add(const Duration(minutes: 2, seconds: 23));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('02:23'), findsOneWidget);
      expect(find.text('0 / 1 complete'), findsOneWidget);
      await tester.tap(find.text('Read'));
      await tester.pumpAndSettle();
      task = (await LocalStorage().load())!.todayPlan.tasks.single;
      expect(task.isCompleted, isTrue);
      expect(task.isFocusRunning, isFalse);
      expect(task.accumulatedFocusMilliseconds, 143000);
      now = now.add(const Duration(hours: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('02:23'), findsOneWidget);
    },
  );

  testWidgets(
    'Starting a second timer pauses the first and navigation keeps it running',
    (tester) async {
      var now = DateTime(2026, 10, 7, 12);
      await _seed(tester, now, [
        Task(name: 'Read', type: TaskType.focus, minimumFocusMinutes: 60),
        Task(name: 'Study'),
        Task(name: 'Walk', type: TaskType.goal),
      ]);
      await tester.pumpWidget(MainApp(now: () => now));
      await tester.pumpAndSettle();
      await _tapFocus(tester, 'Read');
      await tester.pump();
      now = now.add(const Duration(minutes: 23));
      await _tapFocus(tester, 'Study');
      await tester.pump();
      var saved = (await LocalStorage().load())!;
      expect(
        saved.todayPlan.tasks.first.accumulatedFocusMilliseconds,
        23 * 60000,
      );
      expect(
        saved.todayPlan.tasks.where((task) => task.isFocusRunning),
        hasLength(1),
      );
      expect(saved.todayPlan.tasks[1].isFocusRunning, isTrue);
      expect(find.text('23:00'), findsOneWidget);
      await _navigate(tester, 'Calendar');
      now = now.add(const Duration(minutes: 10));
      await tester.pump(const Duration(seconds: 1));
      await _navigate(tester, 'Today');
      expect(find.text('10:00'), findsOneWidget);
      await tester.ensureVisible(find.text('Walk'));
      await tester.tap(find.text('Walk'));
      await tester.pump();
      expect(find.text('1 / 3 complete'), findsOneWidget);
      await _tapFocus(tester, 'Study');
      await tester.pumpAndSettle();
      saved = (await LocalStorage().load())!;
      expect(saved.todayPlan.tasks.any((task) => task.isFocusRunning), isFalse);
      expect(saved.todayPlan.tasks[1].accumulatedFocusMilliseconds, 10 * 60000);
    },
  );

  testWidgets('Background time counts without automatic completion on resume', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 7, 12);
    await _seed(tester, now, [
      Task(name: 'Read', type: TaskType.focus, minimumFocusMinutes: 60),
    ]);
    await tester.pumpWidget(MainApp(now: () => now));
    await tester.pumpAndSettle();
    await _tapFocus(tester, 'Read');
    await tester.pump();
    _background(tester);
    now = now.add(const Duration(minutes: 23));
    _resume(tester);
    await tester.pump();
    expect(find.text('23:00'), findsOneWidget);
    expect(find.text('Pause stopwatch'), findsOneWidget);
    _background(tester);
    now = now.add(const Duration(hours: 2));
    _resume(tester);
    await tester.pumpAndSettle();
    expect(find.text('0 / 1 complete'), findsOneWidget);
    final saved = (await LocalStorage().load())!;
    expect(
      saved.todayPlan.tasks.single.accumulatedFocusMilliseconds,
      143 * 60000,
    );
    expect(saved.todayPlan.tasks.single.isFocusRunning, isTrue);
    expect(find.text('02:23:00'), findsOneWidget);
  });

  testWidgets(
    'A running timestamp survives recreation, paused time does not grow',
    (tester) async {
      var now = DateTime(2026, 10, 7, 12);
      await _seed(tester, now, [
        Task(name: 'Read', type: TaskType.focus, minimumFocusMinutes: 60),
      ]);
      await tester.pumpWidget(MainApp(now: () => now));
      await tester.pumpAndSettle();
      await _tapFocus(tester, 'Read');
      await tester.pump();
      expect(
        (await LocalStorage().load())!.todayPlan.tasks.single.focusStartedAt,
        now.toUtc(),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      now = now.add(const Duration(minutes: 23));
      await tester.pumpWidget(MainApp(now: () => now));
      await tester.pumpAndSettle();
      expect(find.text('23:00'), findsOneWidget);
      await _tapFocus(tester, 'Read');
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      now = now.add(const Duration(hours: 1));
      await tester.pumpWidget(MainApp(now: () => now));
      await tester.pumpAndSettle();
      expect(find.text('23:00'), findsOneWidget);
      expect(find.text('Start stopwatch'), findsOneWidget);
    },
  );

  testWidgets('Unverifiable persisted timer pauses without inventing time', (
    tester,
  ) async {
    final start = DateTime(2026, 10, 7, 12);
    final task = Task(name: 'Read', accumulatedFocusMilliseconds: 5000)
      ..startFocus(start);
    await _seed(tester, start, [task]);
    await tester.pumpWidget(
      MainApp(now: () => start.add(const Duration(hours: 1))),
    );
    await tester.pumpAndSettle();
    final saved = (await LocalStorage().load())!.todayPlan.tasks.single;
    expect(saved.isCompleted, isFalse);
    expect(saved.isFocusRunning, isFalse);
    expect(saved.accumulatedFocusMilliseconds, 5000);
  });

  testWidgets(
    'A failed stopwatch save retains the durable state and retry saves the pending transition',
    (tester) async {
      var now = DateTime(2026, 10, 7, 12);
      await _seed(tester, now, [Task(name: 'Read')]);
      final storage = _FailingStopwatchStorage();
      await tester.pumpWidget(MainApp(now: () => now, storage: storage));
      await tester.pumpAndSettle();
      storage.fail = true;
      await _tapFocus(tester, 'Read');
      await tester.pumpAndSettle();
      expect(find.text('Could not save your changes.'), findsOneWidget);
      expect(
        (await LocalStorage().load())!.todayPlan.tasks.single.isFocusRunning,
        isFalse,
      );
      now = now.add(const Duration(seconds: 10));
      await _tapFocus(tester, 'Read');
      await tester.pumpAndSettle();
      expect(
        (await LocalStorage().load())!.todayPlan.tasks.single.isFocusRunning,
        isFalse,
      );
      storage.fail = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(
        (await LocalStorage().load())!.todayPlan.tasks.single.isFocusRunning,
        isTrue,
      );
      await _tapFocus(tester, 'Read');
      await tester.pumpAndSettle();
      expect(
        (await LocalStorage().load())!
            .todayPlan
            .tasks
            .single
            .accumulatedFocusMilliseconds,
        10000,
      );
    },
  );

  testWidgets(
    'Rollover discards the old day timer and promotes the locked Focus plan',
    (tester) async {
      var now = DateTime(2026, 10, 7, 23, 59);
      final state = DaylockState(
        todayPlan: DailyPlan(
          date: now,
          tasks: [
            Task(
              name: 'Old focus',
              type: TaskType.focus,
              minimumFocusMinutes: 60,
            ),
          ],
          isCommitted: true,
        ),
        tomorrowPlan: DailyPlan(
          date: DateTime(2026, 10, 8),
          tasks: [
            Task(
              name: 'New focus',
              type: TaskType.focus,
              minimumFocusMinutes: 1,
            ),
          ],
          isCommitted: true,
        ),
      );
      await tester.runAsync(() => LocalStorage().save(state));
      await tester.pumpWidget(MainApp(now: () => now));
      await tester.pumpAndSettle();
      final oldScreen = tester.widget<TodayScreen>(find.byType(TodayScreen));
      await _tapFocus(tester, 'Old focus');
      await tester.pump();
      _background(tester);
      now = DateTime(2026, 10, 8, 0, 2);
      _resume(tester);
      await tester.pumpAndSettle();
      expect(find.text('Old focus'), findsNothing);
      expect(find.text('New focus'), findsOneWidget);
      oldScreen.onFocusToggled(state.todayPlan.tasks.single);
      await tester.pumpAndSettle();
      final saved = (await LocalStorage().load())!;
      expect(saved.todayPlan.isCommitted, isTrue);
      expect(saved.todayPlan.tasks.single.isFocusRunning, isFalse);
      expect(saved.todayPlan.tasks.single.accumulatedFocusMilliseconds, 0);
      expect(saved.tomorrowPlan.tasks, isEmpty);
      expect(saved.tomorrowPlan.isCommitted, isFalse);
    },
  );

  testWidgets('Restore repairs multiple running Focus timers to one', (
    tester,
  ) async {
    final start = DateTime(2026, 10, 7, 12);
    final tasks = [
      Task(name: 'Read', type: TaskType.focus, minimumFocusMinutes: 60),
      Task(name: 'Study'),
    ];
    for (final task in tasks) {
      task.bindStopwatchClock(
        () => StopwatchStamp(
          start.toUtc(),
          start.millisecondsSinceEpoch,
          'injected-test-clock',
        ),
      );
      task.startFocus(start);
    }
    await _seed(tester, start, tasks);
    await tester.pumpWidget(
      MainApp(now: () => start.add(const Duration(minutes: 10))),
    );
    await tester.pumpAndSettle();
    final saved = (await LocalStorage().load())!;
    expect(
      saved.todayPlan.tasks.where((task) => task.isFocusRunning),
      hasLength(1),
    );
    expect(saved.todayPlan.tasks.last.accumulatedFocusMilliseconds, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}

Finder _action(String name) => find.descendant(
  of: find.widgetWithText(DaylockTaskRow, name),
  matching: find.byType(TextButton),
);

Future<void> _tapFocus(WidgetTester tester, String name) async {
  await tester.ensureVisible(_action(name));
  await tester.tap(_action(name));
}

Future<void> _seed(WidgetTester tester, DateTime date, List<Task> tasks) =>
    tester.runAsync(
      () => LocalStorage().save(
        DaylockState(
          todayPlan: DailyPlan(date: date, tasks: tasks, isCommitted: true),
          tomorrowPlan: DailyPlan(
            date: DateTime(date.year, date.month, date.day + 1),
            tasks: [],
          ),
        ),
      ),
    );

Future<void> _navigate(WidgetTester tester, String label) async {
  await navigateApp(tester, label);
}

void _background(WidgetTester tester) {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

void _resume(WidgetTester tester) {
  for (final state in [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

class _FailingStopwatchStorage extends LocalStorage {
  bool fail = false;
  @override
  Future<void> save(DaylockState state) async {
    if (fail) throw StateError('Simulated interrupted save');
    await super.save(state);
  }
}

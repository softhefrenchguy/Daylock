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

  testWidgets(
    'Focus planning validates duration and persists an optional target',
    (tester) async {
      await tester.pumpWidget(MainApp(now: () => DateTime(2026, 10, 7, 12)));
      await tester.pumpAndSettle();
      await _navigate(tester, 'Plan');
      expect(find.byKey(const ValueKey('focus-minutes')), findsNothing);
      await openCommitmentEditor(tester);
      await tester.ensureVisible(find.text('Focus'));
      await tester.tap(find.text('Focus'));
      await tester.pumpAndSettle();
      await enterPlanText(
        tester,
        find.byKey(const ValueKey('commitment-name')),
        'Read',
      );
      for (final value in ['', '0', '-5', '1.5', 'abc']) {
        await enterPlanText(
          tester,
          find.byKey(const ValueKey('focus-minutes')),
          value,
        );
        await tester.pump();
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Add commitment'),
              )
              .onPressed,
          isNull,
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();
      }
      expect((await LocalStorage().load())!.tomorrowPlan.tasks, isEmpty);
      await enterPlanText(
        tester,
        find.byKey(const ValueKey('focus-minutes')),
        '60',
      );
      await enterPlanText(
        tester,
        find.byKey(const ValueKey('focus-target')),
        '  Finish Chapter 7  ',
      );
      await tester.pump();
      final add = find.widgetWithText(FilledButton, 'Add commitment');
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      final saved = (await LocalStorage().load())!;
      expect(saved.tomorrowPlan.tasks.single.minimumFocusMinutes, 60);
      expect(saved.tomorrowPlan.tasks.single.focusTarget, 'Finish Chapter 7');
      expect(saved.todayPlan.tasks, isEmpty);
      expect(find.text('60 min'), findsOneWidget);
      expect(find.text('Finish Chapter 7'), findsOneWidget);
      expect(find.byKey(const ValueKey('focus-minutes')), findsNothing);
    },
  );

  testWidgets(
    'Goal selection ignores Focus fields; commit locks all Focus inputs',
    (tester) async {
      await tester.pumpWidget(MainApp(now: () => DateTime(2026, 10, 7, 12)));
      await tester.pumpAndSettle();
      await _navigate(tester, 'Plan');
      await openCommitmentEditor(tester);
      await tester.ensureVisible(find.text('Focus'));
      await tester.tap(find.text('Focus'));
      await tester.pump();
      await enterPlanText(
        tester,
        find.byKey(const ValueKey('focus-minutes')),
        '0',
      );
      await openCommitmentEditor(tester);
      await tester.ensureVisible(find.text('Goal'));
      await tester.tap(find.text('Goal'));
      await tester.pump();
      await enterPlanText(
        tester,
        find.byKey(const ValueKey('commitment-name')),
        'Walk',
      );
      await tester.pump();
      await tester.ensureVisible(find.text('Add commitment'));
      await tester.tap(find.text('Add commitment'));
      await tester.pumpAndSettle();
      await openCommitmentEditor(tester);
      await tester.ensureVisible(find.text('Focus'));
      await tester.tap(find.text('Focus'));
      await tester.pump();
      await enterPlanText(
        tester,
        find.byKey(const ValueKey('commitment-name')),
        'Read',
      );
      await enterPlanText(
        tester,
        find.byKey(const ValueKey('focus-minutes')),
        '1',
      );
      await tester.pump();
      await tester.ensureVisible(find.text('Add commitment'));
      await tester.tap(find.text('Add commitment'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 2; i++) {
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
      }
      final commit = find.widgetWithText(FilledButton, 'COMMIT THURSDAY');
      await tester.ensureVisible(commit);
      await tester.tap(commit);
      await confirmPlanCommit(tester);
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Add commitment'), findsNothing);
      final saved = (await LocalStorage().load())!;
      expect(saved.tomorrowPlan.isCommitted, isTrue);
      expect(saved.tomorrowPlan.tasks.first.type, TaskType.goal);
      expect(saved.tomorrowPlan.tasks.first.minimumFocusMinutes, isNull);
      expect(saved.tomorrowPlan.tasks.last.focusTarget, isNull);
    },
  );

  testWidgets(
    'Focus has no checkbox, pauses accurately, and completes only at its minimum',
    (tester) async {
      var now = DateTime(2026, 10, 7, 12);
      await _seed(tester, now, [
        Task(
          name: 'Read',
          type: TaskType.focus,
          minimumFocusMinutes: 1,
          focusTarget: 'Finish Chapter 7',
        ),
      ]);
      await tester.pumpWidget(MainApp(now: () => now));
      await tester.pumpAndSettle();
      expect(find.byType(CheckboxListTile), findsNothing);
      expect(find.text('0 / 1 min'), findsOneWidget);
      expect(find.text('Finish Chapter 7'), findsOneWidget);
      await tester.tap(find.text('Read'));
      await tester.pumpAndSettle();
      expect(find.text('0 / 1 complete'), findsOneWidget);
      await _tapFocus(tester, 'Read');
      await tester.pump();
      now = now.add(const Duration(seconds: 23));
      await tester.pump(const Duration(seconds: 1));
      await _tapFocus(tester, 'Read');
      await tester.pumpAndSettle();
      var saved = (await LocalStorage().load())!;
      expect(saved.todayPlan.tasks.single.accumulatedFocusMilliseconds, 23000);
      expect(saved.todayPlan.tasks.single.isFocusRunning, isFalse);
      now = now.add(const Duration(hours: 2));
      await tester.pump(const Duration(seconds: 1));
      expect(
        (await LocalStorage().load())!
            .todayPlan
            .tasks
            .single
            .accumulatedFocusMilliseconds,
        23000,
      );
      await _tapFocus(tester, 'Read');
      await tester.pump();
      now = now.add(const Duration(seconds: 36));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('0 / 1 complete'), findsOneWidget);
      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('1 / 1 complete'), findsOneWidget);
      expect(find.text('1 / 1 min'), findsOneWidget);
      expect(find.text('Finish Chapter 7'), findsOneWidget);
      expect(tester.widget<FilledButton>(_action('Read')).onPressed, isNull);
      saved = (await LocalStorage().load())!;
      expect(saved.todayPlan.tasks.single.isCompleted, isTrue);
      expect(saved.todayPlan.tasks.single.focusStartedAt, isNull);
    },
  );

  testWidgets(
    'Starting a second timer pauses the first and navigation keeps it running',
    (tester) async {
      var now = DateTime(2026, 10, 7, 12);
      await _seed(tester, now, [
        Task(name: 'Read', type: TaskType.focus, minimumFocusMinutes: 60),
        Task(name: 'Study', type: TaskType.focus, minimumFocusMinutes: 60),
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
      expect(find.text('23 / 60 min'), findsOneWidget);
      await _navigate(tester, 'Calendar');
      now = now.add(const Duration(minutes: 10));
      await tester.pump(const Duration(seconds: 1));
      await _navigate(tester, 'Today');
      expect(find.text('10 / 60 min'), findsOneWidget);
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

  testWidgets('Background time counts and completion is reconciled on resume', (
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
    expect(find.text('23 / 60 min'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);
    _background(tester);
    now = now.add(const Duration(hours: 2));
    _resume(tester);
    await tester.pumpAndSettle();
    expect(find.text('1 / 1 complete'), findsOneWidget);
    final saved = (await LocalStorage().load())!;
    expect(
      saved.todayPlan.tasks.single.accumulatedFocusMilliseconds,
      60 * 60000,
    );
    expect(saved.todayPlan.tasks.single.isFocusRunning, isFalse);
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
      expect(find.text('23 / 60 min'), findsOneWidget);
      await _tapFocus(tester, 'Read');
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      now = now.add(const Duration(hours: 1));
      await tester.pumpWidget(MainApp(now: () => now));
      await tester.pumpAndSettle();
      expect(find.text('23 / 60 min'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
    },
  );

  testWidgets(
    'A timer reaching its minimum while closed is completed and saved at launch',
    (tester) async {
      final start = DateTime(2026, 10, 7, 12);
      final task = Task(
        name: 'Read',
        type: TaskType.focus,
        minimumFocusMinutes: 1,
      );
      task.startFocus(start);
      await _seed(tester, start, [task]);
      await tester.pumpWidget(
        MainApp(now: () => start.add(const Duration(hours: 1))),
      );
      await tester.pumpAndSettle();
      expect(find.text('Complete'), findsOneWidget);
      final saved = (await LocalStorage().load())!;
      expect(saved.todayPlan.tasks.single.isCompleted, isTrue);
      expect(saved.todayPlan.tasks.single.focusStartedAt, isNull);
      expect(saved.todayPlan.tasks.single.accumulatedFocusMilliseconds, 60000);
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
      Task(name: 'Study', type: TaskType.focus, minimumFocusMinutes: 60),
    ];
    for (final task in tasks) {
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
    expect(saved.todayPlan.tasks.last.accumulatedFocusMilliseconds, 10 * 60000);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}

Finder _action(String name) => find.descendant(
  of: find.widgetWithText(DaylockTaskRow, name),
  matching: find.byType(FilledButton),
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
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
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

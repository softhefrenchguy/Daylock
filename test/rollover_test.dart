import 'dart:async';

import 'package:daylock/main.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/screens/plan_screen.dart';
import 'package:daylock/screens/today_screen.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'plan_test_helpers.dart';

import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('Same calendar date is unchanged, including completion and lock', () {
    final state = _state(DateTime(2026, 10, 7));
    expect(state.rollOver(DateTime(2026, 10, 7, 23, 59)), same(state));
    expect(state.todayPlan.tasks.single.isCompleted, isTrue);
    expect(state.tomorrowPlan.isCommitted, isTrue);
  });

  test(
    'A committed tomorrow plan becomes Today without changing its tasks',
    () {
      final state = _state(DateTime(2026, 10, 7));
      final rolled = state.rollOver(DateTime(2026, 10, 8, 0, 1));
      expect(rolled.todayPlan, same(state.tomorrowPlan));
      expect(rolled.todayPlan.isCommitted, isTrue);
      expect(rolled.todayPlan.tasks.single.name, 'Tomorrow task');
      expect(rolled.todayPlan.tasks.single.type, TaskType.focus);
      expect(rolled.todayPlan.tasks.single.isCompleted, isFalse);
      _expectFreshTomorrow(rolled, DateTime(2026, 10, 9));
      expect(rolled.rollOver(DateTime(2026, 10, 8, 23)), same(rolled));
    },
  );

  test('An uncommitted draft is promoted to the new current date', () {
    final state = _state(DateTime(2026, 10, 7), committed: false);
    final rolled = state.rollOver(DateTime(2026, 10, 8));
    expect(rolled.todayPlan, same(state.tomorrowPlan));
    expect(rolled.todayPlan.date, DateTime(2026, 10, 8));
    expect(rolled.todayPlan.isCommitted, isFalse);
    expect(rolled.todayPlan.tasks.single.name, 'Tomorrow task');
    _expectFreshTomorrow(rolled, DateTime(2026, 10, 9));
  });

  test('An empty uncommitted tomorrow still advances Today', () {
    final state = _state(DateTime(2026, 10, 7), committed: false);
    state.tomorrowPlan.tasks.clear();
    final rolled = state.rollOver(DateTime(2026, 10, 8));
    expect(rolled.todayPlan.date, DateTime(2026, 10, 8));
    expect(rolled.todayPlan.tasks, isEmpty);
    expect(rolled.todayPlan.isCommitted, isFalse);
    _expectFreshTomorrow(rolled, DateTime(2026, 10, 9));
  });

  for (final daysMissed in [2, 10, 60]) {
    test(
      '$daysMissed missed days discard stale commitments and use actual dates',
      () {
        final state = _state(DateTime(2026, 10, 7));
        final date = DateTime(2026, 10, 7 + daysMissed);
        final rolled = state.rollOver(date);
        expect(rolled.todayPlan.date, date);
        expect(rolled.todayPlan.tasks, isEmpty);
        expect(rolled.todayPlan.isCommitted, isFalse);
        _expectFreshTomorrow(
          rolled,
          DateTime(date.year, date.month, date.day + 1),
        );
      },
    );
  }

  final boundaries = <String, (DateTime, DateTime)>{
    'month boundary': (
      DateTime(2026, 4, 30, 23, 59),
      DateTime(2026, 5, 1, 0, 1),
    ),
    'year boundary': (
      DateTime(2026, 12, 31, 23, 59),
      DateTime(2027, 1, 1, 0, 1),
    ),
    'into leap day': (
      DateTime(2028, 2, 28, 23, 59),
      DateTime(2028, 2, 29, 0, 1),
    ),
    'out of leap day': (
      DateTime(2028, 2, 29, 23, 59),
      DateTime(2028, 3, 1, 0, 1),
    ),
    'non-leap February': (
      DateTime(2026, 2, 28, 23, 59),
      DateTime(2026, 3, 1, 0, 1),
    ),
    'spring DST date': (
      DateTime(2026, 3, 29, 23, 59),
      DateTime(2026, 3, 30, 0, 1),
    ),
    'autumn DST date': (
      DateTime(2026, 10, 25, 23, 59),
      DateTime(2026, 10, 26, 0, 1),
    ),
  };
  for (final entry in boundaries.entries) {
    test(
      'Promotes tomorrow across ${entry.key}, regardless of time-of-day',
      () {
        final (previousDate, now) = entry.value;
        final state = _state(previousDate);
        final rolled = state.rollOver(now);
        expect(rolled.todayPlan, same(state.tomorrowPlan));
        expect(rolled.todayPlan.date, DateTime(now.year, now.month, now.day));
        _expectFreshTomorrow(
          rolled,
          DateTime(now.year, now.month, now.day + 1),
        );
      },
    );
  }

  test('A tomorrow plan with the wrong date is never promoted', () {
    final state = DaylockState(
      todayPlan: DailyPlan(date: DateTime(2026, 10, 7), tasks: []),
      tomorrowPlan: DailyPlan(
        date: DateTime(2026, 10, 5),
        tasks: [Task(name: 'Stale task', type: TaskType.goal)],
        isCommitted: true,
      ),
    );
    final rolled = state.rollOver(DateTime(2026, 10, 8));
    expect(rolled.todayPlan.date, DateTime(2026, 10, 8));
    expect(rolled.todayPlan.tasks, isEmpty);
    _expectFreshTomorrow(rolled, DateTime(2026, 10, 9));
  });

  test('A backwards clock change does not discard a saved plan', () {
    final state = _state(DateTime(2026, 10, 7));
    expect(state.rollOver(DateTime(2026, 10, 6)), same(state));
  });

  testWidgets('Same-day launch retains the saved plan and lock', (
    tester,
  ) async {
    final state = _state(DateTime(2026, 10, 7));
    final storage = LocalStorage();
    await tester.runAsync(() => LocalStorage().save(state));
    await tester.pumpWidget(
      MainApp(storage: storage, now: () => DateTime(2026, 10, 7, 23, 59)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Yesterday task'), findsOneWidget);
    expect(find.text('1 / 1 complete'), findsOneWidget);
    final saved = (await storage.load())!;
    expect(saved.toJson(), state.toJson());
  });

  testWidgets(
    'One-day launch promotes committed tomorrow and persists before use',
    (tester) async {
      final storage = LocalStorage();
      await tester.runAsync(
        () => LocalStorage().save(_state(DateTime(2026, 12, 31))),
      );
      var now = DateTime(2027, 1, 1, 0, 1);
      await tester.pumpWidget(MainApp(storage: storage, now: () => now));
      await tester.pumpAndSettle();
      expect(find.text('Tomorrow task'), findsOneWidget);
      expect(find.text('Yesterday task'), findsNothing);
      expect(find.text('FRIDAY 1 JANUARY'), findsOneWidget);
      expect(
        tester.widget<TodayScreen>(find.byType(TodayScreen)).plan.isCommitted,
        isTrue,
      );
      final saved = (await LocalStorage().load())!;
      expect(saved.todayPlan.date, DateTime(2027, 1, 1));
      expect(saved.todayPlan.tasks.single.name, 'Tomorrow task');
      _expectFreshTomorrow(saved, DateTime(2027, 1, 2));

      await tester.tap(find.text('Tomorrow task'));
      await tester.pumpAndSettle();
      expect(find.text('1 / 1 complete'), findsOneWidget);
      await tester.tap(find.text('Tomorrow task'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start stopwatch'));
      now = now.add(const Duration(minutes: Task.legacyFocusMinutes));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('0 / 1 complete'), findsOneWidget);
      await tester.tap(find.text('Tomorrow task'));
      await tester.pumpAndSettle();
      expect(find.text('1 / 1 complete'), findsOneWidget);
      await _openPlan(tester);
      expect(find.text('No commitments planned yet.'), findsOneWidget);
      expect(find.byKey(const ValueKey('commitment-name')), findsNothing);
    },
  );

  testWidgets(
    'Multiple missed days launch with empty current plans and persist',
    (tester) async {
      await tester.runAsync(
        () => LocalStorage().save(_state(DateTime(2026, 10, 7))),
      );
      await tester.pumpWidget(MainApp(now: () => DateTime(2026, 10, 20)));
      await tester.pumpAndSettle();
      expect(find.byType(CheckboxListTile), findsNothing);
      expect(find.text('TUESDAY 20 OCTOBER'), findsOneWidget);
      final saved = (await LocalStorage().load())!;
      expect(saved.todayPlan.date, DateTime(2026, 10, 20));
      expect(saved.todayPlan.tasks, isEmpty);
      _expectFreshTomorrow(saved, DateTime(2026, 10, 21));
    },
  );

  testWidgets('Resume after midnight rolls over once and survives relaunch', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 7, 23, 59);
    final storage = LocalStorage();
    await tester.runAsync(() => LocalStorage().save(_state(now)));
    await tester.pumpWidget(MainApp(storage: storage, now: () => now));
    await tester.pumpAndSettle();
    await _openPlan(tester);
    expect(find.text("Tomorrow's plan is committed."), findsOneWidget);

    _backgroundApp(tester);
    now = DateTime(2026, 10, 8, 0, 1);
    _resumeApp(tester);
    await tester.pumpAndSettle();
    expect(find.text("Tomorrow's plan is committed."), findsNothing);
    expect(find.text('No commitments planned yet.'), findsOneWidget);
    expect(find.byKey(const ValueKey('commitment-name')), findsNothing);
    var saved = (await storage.load())!;
    expect(saved.todayPlan.date, DateTime(2026, 10, 8));
    expect(saved.todayPlan.isCommitted, isTrue);
    _expectFreshTomorrow(saved, DateTime(2026, 10, 9));

    // A second resume on the same date must not promote the new empty draft.
    _backgroundApp(tester);
    _resumeApp(tester);
    await tester.pumpAndSettle();
    saved = (await storage.load())!;
    expect(saved.todayPlan.tasks.single.name, 'Tomorrow task');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(MainApp(now: () => now));
    await tester.pumpAndSettle();
    expect(find.text('Tomorrow task'), findsOneWidget);
    expect(find.text('THURSDAY 8 OCTOBER'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Resume clears the previous draft form and rejects its callbacks',
    (tester) async {
      var now = DateTime(2026, 10, 7, 23, 59);
      await tester.runAsync(
        () => LocalStorage().save(_state(now, committed: false)),
      );
      await tester.pumpWidget(MainApp(now: () => now));
      await tester.pumpAndSettle();
      await _openPlan(tester);
      await enterPlanText(
        tester,
        find.byKey(const ValueKey('commitment-name')),
        'Unfinished old draft',
      );
      await tester.pump();
      final earlierPlan = tester.widget<PlanScreen>(find.byType(PlanScreen));

      _backgroundApp(tester);
      now = DateTime(2026, 10, 8, 0, 1);
      _resumeApp(tester);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('commitment-name')), findsNothing);
      earlierPlan.onTaskCreated(
        Task(name: 'Late old draft', type: TaskType.goal),
      );
      await tester.pumpAndSettle();
      expect(find.text('Late old draft'), findsNothing);

      await enterPlanText(
        tester,
        find.byKey(const ValueKey('commitment-name')),
        'New tomorrow draft',
      );
      await tester.pump();
      await tester.ensureVisible(find.text('Add commitment'));
      await tester.tap(find.text('Add commitment'));
      await tester.pumpAndSettle();
      earlierPlan.onCommitTomorrow();
      await tester.pumpAndSettle();
      final saved = (await LocalStorage().load())!;
      expect(saved.todayPlan.tasks.single.name, 'Tomorrow task');
      expect(saved.todayPlan.isCommitted, isFalse);
      expect(saved.tomorrowPlan.tasks.single.name, 'New tomorrow draft');
      expect(saved.tomorrowPlan.isCommitted, isFalse);
    },
  );

  testWidgets(
    'Rollover dismisses confirmation and rejects its retained action',
    (tester) async {
      var now = DateTime(2026, 10, 7, 23, 59);
      await tester.runAsync(
        () => LocalStorage().save(_state(now, committed: false)),
      );
      await tester.pumpWidget(MainApp(now: () => now));
      await tester.pumpAndSettle();
      await _openPlan(tester);
      await tester.tap(find.text('COMMIT THURSDAY'));
      await tester.pumpAndSettle();
      final oldConfirm = tester
          .widget<FilledButton>(find.byKey(const ValueKey('confirm-commit')))
          .onPressed!;
      expect(find.byType(AlertDialog), findsOneWidget);
      _backgroundApp(tester);
      now = DateTime(2026, 10, 8, 0, 1);
      _resumeApp(tester);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      oldConfirm();
      await tester.pumpAndSettle();
      final saved = (await LocalStorage().load())!;
      expect(saved.todayPlan.date, DateTime(2026, 10, 8));
      expect(saved.todayPlan.isCommitted, isFalse);
      _expectFreshTomorrow(saved, DateTime(2026, 10, 9));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Resume during loading still applies the current calendar date', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 7, 23, 59);
    await tester.runAsync(() => LocalStorage().save(_state(now)));
    final storage = _DelayedLoadStorage();
    await tester.pumpWidget(MainApp(storage: storage, now: () => now));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    _backgroundApp(tester);
    now = DateTime(2026, 10, 8, 0, 1);
    _resumeApp(tester);
    storage.ready.complete();
    await tester.pumpAndSettle();
    expect(find.text('Tomorrow task'), findsOneWidget);
    expect(find.text('THURSDAY 8 OCTOBER'), findsOneWidget);
    expect((await storage.load())!.todayPlan.date, DateTime(2026, 10, 8));
  });
}

DaylockState _state(DateTime today, {bool committed = true}) => DaylockState(
  todayPlan: DailyPlan(
    date: today,
    tasks: [
      Task(name: 'Yesterday task', type: TaskType.goal, isCompleted: true),
    ],
    isCommitted: true,
  ),
  tomorrowPlan: DailyPlan(
    date: DateTime(today.year, today.month, today.day + 1),
    tasks: [Task(name: 'Tomorrow task', type: TaskType.focus)],
    isCommitted: committed,
  ),
);

void _expectFreshTomorrow(DaylockState state, DateTime date) {
  expect(state.tomorrowPlan.date, date);
  expect(state.tomorrowPlan.tasks, isEmpty);
  expect(state.tomorrowPlan.isCommitted, isFalse);
}

Future<void> _openPlan(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Plan'),
    ),
  );
  await tester.pumpAndSettle();
}

void _backgroundApp(WidgetTester tester) {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

void _resumeApp(WidgetTester tester) {
  for (final state in [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

class _DelayedLoadStorage extends LocalStorage {
  final ready = Completer<void>();

  @override
  Future<DaylockState?> load() async {
    await ready.future;
    return super.load();
  }
}

import 'navigation_helpers.dart';

import 'dart:convert';

import 'package:daylock/design/daylock_calendar.dart';
import 'package:daylock/design/daylock_palette.dart';
import 'package:daylock/design/daylock_task_row.dart';
import 'package:daylock/design/daylock_theme.dart';
import 'package:daylock/main.dart';
import 'package:daylock/models/calendar_account.dart';
import 'package:daylock/models/calendar_activity.dart';
import 'package:daylock/models/calendar_cache.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/event.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/screens/task_actions_sheet.dart';
import 'package:daylock/screens/today_screen.dart';
import 'package:daylock/services/calendar_credentials.dart';
import 'package:daylock/services/calendar_service.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'calendar_test_fixtures.dart';

final _date = DateTime(2026, 10, 13, 10);
Task _goal(String name, {bool completed = false, bool excused = false}) => Task(
  name: name,
  type: TaskType.goal,
  isCompleted: completed,
  outcome: excused ? TaskOutcome.excused : null,
  excuseReason: excused ? 'Buyer did not arrive.' : null,
);
DaylockState _state(List<Task> tasks) => DaylockState(
  todayPlan: DailyPlan(date: _date, tasks: tasks, isCommitted: true),
  tomorrowPlan: DailyPlan(
    date: DateTime(2026, 10, 14),
    tasks: [_goal('Tomorrow commitment')],
    isCommitted: true,
  ),
);

Future<void> _seed(WidgetTester tester, List<Task> tasks) =>
    tester.runAsync(() => LocalStorage().save(_state(tasks)));
Future<DaylockState> _saved(WidgetTester tester) async =>
    (await tester.runAsync<DaylockState?>(() => LocalStorage().load()))!;
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _actions(WidgetTester tester, String title) async {
  final finder = find.text(title);
  await tester.ensureVisible(finder);
  await tester.longPress(finder);
  await tester.pumpAndSettle();
}

Future<void> _excuse(
  WidgetTester tester,
  String title, {
  String reason = 'Buyer did not arrive.',
}) async {
  await _actions(tester, title);
  await _tap(tester, find.byKey(const ValueKey('task-excuse')));
  await tester.enterText(find.byKey(const ValueKey('excuse-reason')), reason);
  await _tap(tester, find.byKey(const ValueKey('confirm-excuse')));
}

Future<void> _page(WidgetTester tester, String name) =>
    navigateApp(tester, name);
void _resume(WidgetTester tester) {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  testWidgets(
    'Long press does not complete Goal; excuses validate, count separately and can be reversed',
    (tester) async {
      await _seed(tester, [
        _goal('Done 1', completed: true),
        _goal('Done 2', completed: true),
        _goal('Done 3', completed: true),
        _goal('Sell car'),
      ]);
      await tester.pumpWidget(MainApp(now: () => _date));
      await tester.pumpAndSettle();
      await _actions(tester, 'Sell car');
      expect(
        (await _saved(tester)).todayPlan.tasks.last.outcome,
        TaskOutcome.incomplete,
      );
      expect(find.text('Mark completed'), findsOneWidget);
      expect(find.text('Reset to incomplete'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('task-excuse')));
      await _tap(tester, find.byKey(const ValueKey('confirm-excuse')));
      expect(find.text('Enter a short reason.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('excuse-reason')),
        '   ',
      );
      await _tap(tester, find.byKey(const ValueKey('confirm-excuse')));
      expect(find.text('Enter a short reason.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('excuse-reason')),
        '  Buyer did not arrive.  ',
      );
      await _tap(tester, find.byKey(const ValueKey('confirm-excuse')));
      expect(find.text('3 / 3 complete'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('1 excused'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsNWidgets(3));
      final excused = (await _saved(tester)).todayPlan.tasks.last;
      expect(excused.outcome, TaskOutcome.excused);
      expect(excused.excuseReason, 'Buyer did not arrive.');
      await _tap(tester, find.text('Sell car'));
      expect(find.text('EXCUSE REASON'), findsOneWidget);
      expect(find.text('Buyer did not arrive.'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('task-reset')));
      expect(find.text('3 / 4 complete'), findsOneWidget);
      expect((await _saved(tester)).todayPlan.tasks.last.excuseReason, isNull);
      await _tap(tester, find.text('Sell car'));
      expect(find.text('4 / 4 complete'), findsOneWidget);
      await _actions(tester, 'Sell car');
      await _tap(tester, find.byKey(const ValueKey('task-reset')));
      await _actions(tester, 'Sell car');
      await _tap(tester, find.byKey(const ValueKey('task-mark-completed')));
      expect(
        (await _saved(tester)).todayPlan.tasks.last.outcome,
        TaskOutcome.completed,
      );
    },
  );

  testWidgets('Cancelled excuse keeps saved data and the original outcome', (
    tester,
  ) async {
    await _seed(tester, [_goal('Sell car')]);
    await tester.pumpWidget(MainApp(now: () => _date));
    await tester.pumpAndSettle();
    final before = (await _saved(tester)).toJson();
    await _actions(tester, 'Sell car');
    await _tap(tester, find.byKey(const ValueKey('task-excuse')));
    await tester.enterText(
      find.byKey(const ValueKey('excuse-reason')),
      'Not yet confirmed.',
    );
    await _tap(tester, find.text('Cancel'));
    expect((await _saved(tester)).toJson(), before);
    expect(find.text('0 / 1 complete'), findsOneWidget);
  });

  testWidgets(
    'Multi-code-unit reasons are validated before changing or saving an outcome',
    (tester) async {
      await _seed(tester, [_goal('Sell car')]);
      await tester.pumpWidget(MainApp(now: () => _date));
      await tester.pumpAndSettle();
      await _actions(tester, 'Sell car');
      await _tap(tester, find.byKey(const ValueKey('task-excuse')));
      await tester.enterText(
        find.byKey(const ValueKey('excuse-reason')),
        String.fromCharCode(0x1F697) * 130,
      );
      await _tap(tester, find.byKey(const ValueKey('confirm-excuse')));
      expect(find.text('Please shorten this reason.'), findsOneWidget);
      expect(
        (await _saved(tester)).todayPlan.tasks.single.outcome,
        TaskOutcome.incomplete,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Two completed, one incomplete, one excused displays 67 percent',
    (tester) async {
      await _seed(tester, [
        _goal('Done 1', completed: true),
        _goal('Done 2', completed: true),
        _goal('Pending'),
        _goal('Sell car', excused: true),
      ]);
      await tester.pumpWidget(MainApp(now: () => _date));
      await tester.pumpAndSettle();
      expect(find.text('2 / 3 complete'), findsOneWidget);
      expect(find.text('67%'), findsOneWidget);
      expect(find.text('1 excused'), findsOneWidget);
      expect(find.text('Day complete'), findsNothing);
      expect(find.text('2 / 3 eligible commitments complete'), findsOneWidget);
    },
  );

  testWidgets(
    'All excused is neutral in Today and Calendar, retains history reasons and Focus time',
    (tester) async {
      var now = _date;
      final focus = Task(
        name: 'Focus',
        type: TaskType.focus,
        outcome: TaskOutcome.excused,
        excuseReason: 'Library closed.',
        minimumFocusMinutes: 60,
        accumulatedFocusMilliseconds: 1380500,
      );
      await _seed(tester, [_goal('Sell car', excused: true), focus]);
      await tester.pumpWidget(MainApp(now: () => now));
      await tester.pumpAndSettle();
      expect(find.text('No eligible commitments'), findsOneWidget);
      expect(
        find.textContaining('completion is required to earn Freedom'),
        findsOneWidget,
      );
      expect(find.text('Day complete'), findsNothing);
      expect(find.text('100%'), findsNothing);
      expect(find.text('0%'), findsNothing);
      expect(find.text('2 excused'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsNothing);
      expect(find.text('Start'), findsNothing);
      now = DateTime(2026, 10, 14, 8);
      _resume(tester);
      await tester.pumpAndSettle();
      final saved = await _saved(tester);
      expect(
        saved.history.forDate(_date)!.summary.completionPercentage,
        isNull,
      );
      expect(
        saved.history.forDate(_date)!.summary.accumulatedFocusMilliseconds,
        1380500,
      );
      await _page(tester, 'Calendar');
      await _tap(tester, find.byKey(const ValueKey('calendar-day-2026-10-13')));
      expect(find.text('No eligible commitments'), findsOneWidget);
      expect(find.text('2 excused'), findsOneWidget);
      expect(find.text('Goal · Excused'), findsOneWidget);
      expect(find.text('Focus · Excused'), findsOneWidget);
      expect(find.text('Reason: Buyer did not arrive.'), findsOneWidget);
      expect(find.text('Reason: Library closed.'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('calendar-completion-percentage')),
        findsNothing,
      );
      final fill = tester.widget<Material>(
        find.byKey(const ValueKey('heatmap-fill-2026-10-13')),
      );
      expect(
        fill.color,
        DaylockHeatmapPalette(DaylockTheme.dark.colorScheme)
            .background(HeatmapIntensity.neutral),
      );
      expect((await _saved(tester)).history.toJson(), saved.history.toJson());
    },
  );

  testWidgets(
    'Excusing active Focus persists exact time, stops timer and survives reopen; reset resumes earned progress',
    (tester) async {
      var now = _date;
      await _seed(tester, [
        Task(
          name: 'Study',
          type: TaskType.focus,
          minimumFocusMinutes: 60,
          accumulatedFocusMilliseconds: 1001,
        ),
      ]);
      await tester.pumpWidget(MainApp(now: () => now));
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Start'));
      now = now.add(const Duration(milliseconds: 23500));
      await tester.pump(const Duration(seconds: 1));
      await _actions(tester, 'Study');
      expect(
        tester
            .widget<ListTile>(find.byKey(const ValueKey('task-mark-completed')))
            .onTap,
        isNull,
      );
      await _tap(tester, find.byKey(const ValueKey('task-excuse')));
      await tester.enterText(
        find.byKey(const ValueKey('excuse-reason')),
        'Power cut.',
      );
      await _tap(tester, find.byKey(const ValueKey('confirm-excuse')));
      var task = (await _saved(tester)).todayPlan.tasks.single;
      expect(task.outcome, TaskOutcome.excused);
      expect(task.accumulatedFocusMilliseconds, 24501);
      expect(task.isFocusRunning, isFalse);
      now = now.add(const Duration(hours: 2));
      _resume(tester);
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(MainApp(now: () => now));
      await tester.pumpAndSettle();
      task = (await _saved(tester)).todayPlan.tasks.single;
      expect(task.accumulatedFocusMilliseconds, 24501);
      expect(task.outcome, TaskOutcome.excused);
      await _tap(tester, find.text('Study'));
      await _tap(tester, find.byKey(const ValueKey('task-reset')));
      await _tap(tester, find.text('Start'));
      now = now.add(const Duration(milliseconds: 499));
      await _tap(tester, find.text('Pause'));
      expect(
        (await _saved(tester))
            .todayPlan
            .tasks
            .single
            .accumulatedFocusMilliseconds,
        25000,
      );
    },
  );

  testWidgets(
    'Excusing one timer does not stop another Focus timer; one-timer rule remains intact',
    (tester) async {
      var now = _date;
      await _seed(tester, [
        Task(name: 'Study', type: TaskType.focus, minimumFocusMinutes: 60),
        Task(name: 'Read', type: TaskType.focus, minimumFocusMinutes: 60),
      ]);
      await tester.pumpWidget(MainApp(now: () => now));
      await tester.pumpAndSettle();
      final first = find.descendant(
        of: find.byWidgetPredicate(
          (widget) => widget is DaylockTaskRow && widget.task.name == 'Study',
        ),
        matching: find.text('Start'),
      );
      await _tap(tester, first);
      now = now.add(const Duration(minutes: 5));
      await _excuse(tester, 'Read', reason: 'Appointment cancelled.');
      final saved = await _saved(tester);
      expect(saved.todayPlan.tasks.first.isFocusRunning, isTrue);
      expect(saved.todayPlan.tasks.last.outcome, TaskOutcome.excused);
      await tester.pumpWidget(
        const SizedBox.shrink(),
      ); // Dispose the active refresh timer.
    },
  );

  testWidgets(
    'Rollover dismisses a pending excuse and rejects its retained submit action',
    (tester) async {
      var now = _date;
      await _seed(tester, [_goal('Sell car')]);
      await tester.pumpWidget(MainApp(now: () => now));
      await tester.pumpAndSettle();
      await _actions(tester, 'Sell car');
      await _tap(tester, find.byKey(const ValueKey('task-excuse')));
      await tester.enterText(
        find.byKey(const ValueKey('excuse-reason')),
        'Buyer did not arrive.',
      );
      final submit = tester
          .widget<FilledButton>(find.byKey(const ValueKey('confirm-excuse')))
          .onPressed!;
      now = DateTime(2026, 10, 14, 8);
      _resume(tester);
      await tester.pumpAndSettle();
      expect(find.byType(ExcuseReasonDialog), findsNothing);
      expect(find.text('Tomorrow commitment'), findsOneWidget);
      final before = (await _saved(tester)).toJson();
      // The obsolete route has been removed; callbacks must be harmless after dispose.
      // Invoking the old action tests the guard without changing the archived task.
      submit();
      await tester.pumpAndSettle();
      expect((await _saved(tester)).toJson(), before);
      expect(
        (await _saved(tester)).history.forDate(_date)!.tasks.single.outcome,
        TaskOutcome.incomplete,
      );
    },
  );

  testWidgets(
    'Excuse persistence preserves external calendars, events, credentials and locked tomorrow',
    (tester) async {
      final accounts = [
        for (final type in CalendarProviderType.values) testAccount(type),
      ];
      final cache = CalendarCache(
        accounts: accounts,
        calendars: accounts.map(testCalendar),
        events: accounts.map(testExternal),
      );
      final state = DaylockState(
        todayPlan: _state([_goal('Sell car')]).todayPlan,
        tomorrowPlan: _state([]).tomorrowPlan,
        calendarCache: cache,
        events: [Event(id: 'local', title: 'Lesson', date: _date)],
      );
      final credentials = MemoryCredentials();
      for (final account in accounts) {
        await credentials.write(
          account.id,
          CalendarCredentials(accessToken: 'existing-private-token'),
        );
      }
      final tokens = Map.of(credentials.values);
      await tester.runAsync(() => LocalStorage().save(state));
      await tester.pumpWidget(
        MainApp(
          now: () => _date,
          calendarService: CalendarService(credentials: credentials),
        ),
      );
      await tester.pumpAndSettle();
      await _excuse(tester, 'Sell car');
      final saved = await _saved(tester);
      expect(
        saved.events.map((event) => event.toJson()),
        state.events.map((event) => event.toJson()),
      );
      expect(saved.calendarCache.toJson(), cache.toJson());
      expect(saved.tomorrowPlan.toJson(), state.tomorrowPlan.toJson());
      expect(credentials.values, tokens);
      final raw = (await tester.runAsync<String?>(
        () => SharedPreferencesAsync().getString(LocalStorage.stateKey),
      ))!;
      expect(jsonDecode(raw)['todayPlan']['tasks'][0]['outcome'], 'excused');
      expect(raw, isNot(contains('existing-private-token')));
    },
  );

  testWidgets(
    'A failed excuse save reports Retry and preserves the previous save until retry succeeds',
    (tester) async {
      await _seed(tester, [_goal('Sell car')]);
      final storage = _FailingStorage();
      await tester.pumpWidget(MainApp(now: () => _date, storage: storage));
      await tester.pumpAndSettle();
      await _excuse(tester, 'Sell car');
      expect(find.text('Could not save your changes.'), findsOneWidget);
      expect(
        (await _saved(tester)).todayPlan.tasks.single.outcome,
        TaskOutcome.incomplete,
      );
      storage.fail = false;
      await _tap(tester, find.text('Retry'));
      final task = (await _saved(tester)).todayPlan.tasks.single;
      expect(task.outcome, TaskOutcome.excused);
      expect(task.excuseReason, 'Buyer did not arrive.');
    },
  );

  for (final colour in ColourTheme.values) {
    for (final brightness in Brightness.values) {
      testWidgets(
        '$colour $brightness distinguishes excuses and supports 320px/large text actions',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(320, 640);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final plan = _state([
            _goal(
              'A long excused commitment title that wraps on a small phone',
              excused: true,
            ),
          ]).todayPlan;
          await tester.pumpWidget(
            MaterialApp(
              theme: DaylockTheme.forPalette(colour, brightness),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(2),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: Scaffold(
                body: StatefulBuilder(
                  builder: (context, rebuild) => TodayScreen(
                    plan: plan,
                    currentTime: _date,
                    onTaskChanged: () => rebuild(() {}),
                    onFocusToggled: (_) {},
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(CheckboxListTile), findsNothing);
          expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
          await _actions(tester, plan.tasks.single.name);
          expect(find.text('Buyer did not arrive.'), findsOneWidget);
          await _tap(tester, find.byKey(const ValueKey('task-excuse')));
          tester.view.viewInsets = const FakeViewPadding(bottom: 200);
          addTearDown(tester.view.resetViewInsets);
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const ValueKey('excuse-reason')),
            'Updated short reason.',
          );
          await _tap(tester, find.byKey(const ValueKey('confirm-excuse')));
          tester.view.resetViewInsets();
          await tester.pumpAndSettle();
          expect(plan.tasks.single.excuseReason, 'Updated short reason.');
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

class _FailingStorage extends LocalStorage {
  bool fail = true;
  @override
  Future<void> save(DaylockState state) async {
    if (fail) throw StateError('Storage unavailable');
    await super.save(state);
  }
}

import 'package:daylock/design/daylock_theme.dart';
import 'package:daylock/main.dart';
import 'package:daylock/models/area.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/freedom_settings.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/screens/today_screen.dart';
import 'package:daylock/services/freedom_service.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'navigation_helpers.dart';

final day = DateTime(2026, 10, 27, 19);
Widget today(DailyPlan plan, {double scale = 1, bool enabled = true}) =>
    MaterialApp(
      theme: DaylockTheme.dark,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, update) => TodayScreen(
            plan: plan,
            currentTime: day,
            areas: AreaBook.initial(),
            onTaskChanged: () => update(() {}),
            onFocusToggled: (task) => update(() {
              if (task.isFocusRunning) {
                task.pauseFocus(day);
              } else {
                for (final other in plan.tasks) {
                  other.pauseFocus(day);
                }
                task.startFocus(day);
              }
            }),
            freedomEligibility: const FreedomService().evaluate(
              now: day,
              settings: FreedomSettings(enabled: enabled),
              todayPlan: plan,
              tomorrowPlan: DailyPlan(
                date: DateTime(2026, 10, 28),
                tasks: [],
                isCommitted: true,
              ),
            ),
          ),
        ),
      ),
    );
Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );
  for (final count in [0, 1, 3]) {
    testWidgets('$count commitments are visible without an expansion control', (
      tester,
    ) async {
      final plan = DailyPlan(
        date: day,
        tasks: [for (var i = 0; i < count; i++) Task(name: 'Task $i')],
      );
      await tester.pumpWidget(today(plan));
      await tester.pumpAndSettle();
      for (var i = 0; i < count; i++) {
        expect(find.text('Task $i'), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('today-expand')), findsNothing);
      expect(find.byKey(const ValueKey('freedom-status')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'Running item outside first three remains visible; expand and collapse keep timer and order',
    (tester) async {
      final tasks = [for (var i = 0; i < 5; i++) Task(name: 'Task $i')];
      tasks[4].startFocus(day.subtract(const Duration(minutes: 2)));
      final plan = DailyPlan(date: day, tasks: tasks);
      await tester.pumpWidget(today(plan));
      await tester.pumpAndSettle();
      expect(find.text('Task 0'), findsOneWidget);
      expect(find.text('Task 1'), findsOneWidget);
      expect(find.text('Task 2'), findsNothing);
      expect(find.text('Task 3'), findsNothing);
      expect(find.text('Task 4'), findsOneWidget);
      expect(find.text('02:00'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('today-expand')));
      expect(find.text('Task 2'), findsOneWidget);
      expect(find.text('Task 3'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('today-expand')));
      expect(tasks[4].isFocusRunning, isTrue);
      expect(tasks[4].accumulatedFocusMilliseconds, 0);
      await tap(tester, find.byKey(ValueKey('complete-${tasks[4].id}')));
      expect(tasks[4].isCompleted, isTrue);
      expect(tasks[4].accumulatedFocusMilliseconds, 120000);
      expect(find.text('1 / 5 complete'), findsOneWidget);
      expect(find.text('Task 2'), findsOneWidget);
      expect(find.text('Task 4'), findsNothing);
    },
  );
  for (final enabled in [false, true]) {
    testWidgets(
      'Permanent Freedom card shows actual conditions when enabled=$enabled',
      (tester) async {
        final plan = DailyPlan(
          date: day,
          tasks: [Task(name: 'Read', isCompleted: true)],
        );
        await tester.pumpWidget(today(plan, enabled: enabled));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('freedom-status')), findsOneWidget);
        expect(
          find.text(enabled ? 'Freedom earned' : 'Freedom Control is off'),
          findsOneWidget,
        );
        expect(find.textContaining('Freedom Time'), findsOneWidget);
        expect(
          find.text('1 / 1 eligible commitments complete'),
          findsOneWidget,
        );
        expect(find.textContaining('plan committed'), findsOneWidget);
        expect(find.byKey(const ValueKey('freedom-dialog')), findsNothing);
      },
    );
  }
  testWidgets(
    'The permanent Freedom card updates when time reaches the threshold',
    (tester) async {
      var now = DateTime(2026, 10, 27, 17, 59);
      final plan = DailyPlan(
        date: now,
        tasks: [Task(name: 'Read', isCompleted: true)],
      );
      late StateSetter refresh;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, update) {
                refresh = update;
                return TodayScreen(
                  plan: plan,
                  currentTime: now,
                  onTaskChanged: () {},
                  onFocusToggled: (_) {},
                  freedomEligibility: const FreedomService().evaluate(
                    now: now,
                    settings: const FreedomSettings(enabled: true),
                    todayPlan: plan,
                    tomorrowPlan: DailyPlan(
                      date: DateTime(2026, 10, 28),
                      tasks: [],
                      isCommitted: true,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Waiting for Freedom Time'), findsOneWidget);
      refresh(() => now = DateTime(2026, 10, 27, 18));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('Freedom earned'), findsOneWidget);
    },
  );

  testWidgets(
    'Draft editing and removal persist, while commitment locks actions',
    (tester) async {
      final archived = Area.create(
        name: 'Old Area',
        icon: 'work',
        colour: Area.defaultColour,
        now: day,
      );
      final areas = AreaBook.initial(createdAt: day)
          .upsert(archived)
          .archive(archived.id, true);
      final task = Task(
        areaId: archived.id,
        name: 'Original',
        minimumFocusMinutes: 5,
        focusTarget: 'Legacy target',
      );
      final state = DaylockState(
        areas: areas,
        todayPlan: DailyPlan(date: day, tasks: []),
        tomorrowPlan: DailyPlan(date: DateTime(2026, 10, 28), tasks: [task]),
      );
      await LocalStorage().save(state);
      await tester.pumpWidget(MainApp(now: () => day));
      await tester.pumpAndSettle();
      await navigateApp(tester, 'Plan');
      await tap(tester, find.byKey(const ValueKey('plan-task-actions-0')));
      await tap(tester, find.text('Edit commitment'));
      await tester.enterText(
        find.byKey(const ValueKey('commitment-name')),
        'Edited',
      );
      await tester.pump();
      await tap(tester, find.text('Save changes'));
      var saved = (await LocalStorage().load())!.tomorrowPlan.tasks.single;
      expect(saved.id, task.id);
      expect(saved.name, 'Edited');
      expect(saved.focusTarget, 'Legacy target');
      expect(saved.areaId, archived.id);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const ValueKey('plan-task-actions-0')));
      await tap(tester, find.text('Remove commitment'));
      await tap(
        tester,
        find.byKey(const ValueKey('confirm-remove-commitment')),
      );
      expect((await LocalStorage().load())!.tomorrowPlan.tasks, isEmpty);
      expect(find.text('No commitments planned yet.'), findsOneWidget);
      saved = Task(name: 'Locked');
      await tester.pumpWidget(const SizedBox.shrink());
      await LocalStorage().save(
        DaylockState(
          todayPlan: state.todayPlan,
          tomorrowPlan: DailyPlan(
            date: DateTime(2026, 10, 28),
            tasks: [saved],
            isCommitted: true,
          ),
        ),
      );
      await tester.pumpWidget(MainApp(now: () => day));
      await tester.pumpAndSettle();
      await navigateApp(tester, 'Plan');
      expect(find.byKey(const ValueKey('plan-task-actions-0')), findsNothing);
      expect(
        find.byKey(const ValueKey('open-commitment-editor')),
        findsNothing,
      );
      expect(find.text('Committed'), findsOneWidget);
    },
  );
  for (final brightness in Brightness.values) {
    for (final scale in [1.0, 2.0, 3.0]) {
      testWidgets('Today supports 320px and $scale text in $brightness', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 568);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final task = Task(
          name: 'A long commitment that wraps over several lines',
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: brightness == Brightness.dark
                ? DaylockTheme.dark
                : DaylockTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: TodayScreen(
                plan: DailyPlan(date: day, tasks: [task]),
                currentTime: day,
                areas: AreaBook.initial(),
                onTaskChanged: () {},
                onFocusToggled: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(ValueKey('stopwatch-toggle-${task.id}')),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}

import 'package:daylock/main.dart';
import 'package:daylock/design/daylock_areas.dart';
import 'package:daylock/design/daylock_calendar_details.dart';
import 'package:daylock/models/area.dart';
import 'package:daylock/models/calendar_activity.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/plan_history.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/screens/areas_screen.dart';
import 'package:daylock/screens/commitment_editor.dart';
import 'package:daylock/screens/plan_screen.dart';
import 'package:daylock/screens/settings_screen.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'plan_test_helpers.dart';

final date = DateTime(2026, 10, 26, 12);
final health = Area.create(
  name: 'Health',
  icon: 'health',
  colour: 0xff348e88,
  now: date,
);
AreaBook get book => AreaBook.initial(createdAt: date).upsert(health);
Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> page(WidgetTester tester) async {
  await tap(
    tester,
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Plan'),
    ),
  );
}

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  testWidgets(
    'Settings manager creates custom Area, renames default, archives and restores',
    (tester) async {
      await tester.pumpWidget(MainApp(now: () => date));
      await tester.pumpAndSettle();
      await tap(tester, find.byTooltip('Settings'));
      expect(find.byType(SettingsScreen), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('manage-areas')));
      expect(
        find.byKey(const ValueKey('archive-area-${Area.defaultId}')),
        findsNothing,
      );
      await tap(tester, find.byKey(const ValueKey('area-${Area.defaultId}')));
      await tester.enterText(
        find.byKey(const ValueKey('area-name')),
        'My life',
      );
      await tap(tester, find.byKey(const ValueKey('area-icon-home')));
      await tap(tester, find.byKey(const ValueKey('area-colour-Blue')));
      await tap(tester, find.byKey(const ValueKey('save-area')));
      await tap(tester, find.byKey(const ValueKey('create-area')));
      await tester.enterText(find.byKey(const ValueKey('area-name')), 'Health');
      await tap(tester, find.byKey(const ValueKey('area-icon-health')));
      await tap(tester, find.byKey(const ValueKey('area-colour-Teal')));
      await tap(tester, find.byKey(const ValueKey('save-area')));
      var saved = (await LocalStorage().load())!;
      expect(saved.areas.defaultArea.name, 'My life');
      expect(saved.areas.defaultArea.icon, 'home');
      expect(saved.areas.defaultArea.colour, areaColours['Blue']);
      final custom = saved.areas.areas.singleWhere((a) => !a.isDefault);
      expect(custom.icon, 'health');
      expect(custom.colour, areaColours['Teal']);
      await tap(tester, find.byKey(ValueKey('archive-area-${custom.id}')));
      expect(
        (await LocalStorage().load())!.areas.resolve(custom.id).isArchived,
        isTrue,
      );
      await tap(tester, find.byKey(ValueKey('archive-area-${custom.id}')));
      saved = (await LocalStorage().load())!;
      expect(saved.areas.resolve(custom.id).isArchived, isFalse);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(MainApp(now: () => date));
      await tester.pumpAndSettle();
      await page(tester);
      final restored = tester
          .widget<PlanScreen>(find.byType(PlanScreen))
          .areas!;
      expect(restored.toJson(), saved.areas.toJson());
    },
  );

  for (final type in TaskType.values) {
    testWidgets(
      'New ${type.name} defaults to Life and accepts active Area selection',
      (tester) async {
        final plan = DailyPlan(date: date, tasks: []);
        final archived = Area.create(
          name: 'Old',
          icon: 'work',
          colour: Area.defaultColour,
          now: date,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PlanScreen(
                plan: plan,
                areas: book.upsert(archived).archive(archived.id, true),
                onTaskCreated: plan.tasks.add,
                onCommitTomorrow: () {},
              ),
            ),
          ),
        );
        await openCommitmentEditor(tester);
        expect(
          tester.widget<AreaSelector>(find.byType(AreaSelector)).selectedId,
          Area.defaultId,
        );
        await tester.enterText(
          find.byKey(const ValueKey('commitment-name')),
          'Walk',
        );
        await tap(tester, find.byKey(const ValueKey('select-area')));
        expect(
          find.byKey(ValueKey('choose-area-${archived.id}')),
          findsNothing,
        );
        await tap(tester, find.byKey(ValueKey('choose-area-${health.id}')));
        await tap(tester, find.byKey(const ValueKey('save-commitment')));
        expect(plan.tasks.single.areaId, health.id);
        expect(plan.tasks.single.type, TaskType.goal);
        expect(plan.tasks.single.isCompleted, isFalse);
      },
    );
  }

  testWidgets(
    'Routine editor remembers Area for accepted suggestions; Plan edits only the instance',
    (tester) async {
      await LocalStorage().save(
        DaylockState(
          areas: book,
          todayPlan: DailyPlan(date: date, tasks: []),
          tomorrowPlan: DailyPlan(date: DateTime(2026, 10, 27), tasks: []),
        ),
      );
      await tester.pumpWidget(MainApp(now: () => date));
      await tester.pumpAndSettle();
      await tap(tester, find.byTooltip('Settings'));
      await tap(tester, find.byKey(const ValueKey('manage-routines')));
      await tap(tester, find.byKey(const ValueKey('create-routine')));
      await tester.enterText(
        find.byKey(const ValueKey('routine-name')),
        'Movement',
      );
      await tap(tester, find.byKey(const ValueKey('add-routine-step')));
      await tester.enterText(
        find.byKey(const ValueKey('commitment-name')),
        'Walk',
      );
      await tap(tester, find.byKey(const ValueKey('select-area')));
      await tap(tester, find.byKey(ValueKey('choose-area-${health.id}')));
      await tap(tester, find.byKey(const ValueKey('save-commitment')));
      await tap(tester, find.byKey(const ValueKey('save-routine')));
      final routine = (await LocalStorage().load())!.routines.routines.single;
      expect(routine.steps.single.areaId, health.id);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await page(tester);
      await tap(tester, find.byKey(const ValueKey('routine-suggestions')));
      await tap(tester, find.byKey(ValueKey('routine-accept-${routine.id}')));
      expect(
        (await LocalStorage().load())!.tomorrowPlan.tasks.single.areaId,
        health.id,
      );
      await tap(tester, find.byKey(const ValueKey('edit-task-area-0')));
      await tap(
        tester,
        find.byKey(const ValueKey('choose-area-${Area.defaultId}')),
      );
      final saved = (await LocalStorage().load())!;
      expect(saved.tomorrowPlan.tasks.single.areaId, Area.defaultId);
      expect(saved.routines.routines.single.steps.single.areaId, health.id);
    },
  );

  testWidgets(
    'Plan Area edit persists without resetting state; stale callbacks cannot edit locked plan',
    (tester) async {
      final task = Task(
        name: 'Read',
        type: TaskType.focus,
        minimumFocusMinutes: 5,
        accumulatedFocusMilliseconds: 300000,
      );
      await LocalStorage().save(
        DaylockState(
          areas: book,
          todayPlan: DailyPlan(date: date, tasks: []),
          tomorrowPlan: DailyPlan(date: DateTime(2026, 10, 27), tasks: [task]),
        ),
      );
      await tester.pumpWidget(MainApp(now: () => date));
      await tester.pumpAndSettle();
      await page(tester);
      final before = tester.widget<PlanScreen>(find.byType(PlanScreen));
      final original = before.plan.tasks.single;
      final execution = original.toJson()..remove('areaId');
      await tap(tester, find.byKey(const ValueKey('edit-task-area-0')));
      await tap(tester, find.byKey(ValueKey('choose-area-${health.id}')));
      var saved = (await LocalStorage().load())!;
      expect(saved.tomorrowPlan.tasks.single.areaId, health.id);
      expect(
        saved.tomorrowPlan.tasks.single.toJson()..remove('areaId'),
        execution,
      );
      expect(
        identical(
          original,
          tester.widget<PlanScreen>(find.byType(PlanScreen)).plan.tasks.single,
        ),
        isTrue,
      );
      before.onCommitTomorrow();
      await tester.pumpAndSettle();
      before.onTaskAreaChanged!(original, Area.defaultId);
      await tester.pumpAndSettle();
      saved = (await LocalStorage().load())!;
      expect(saved.tomorrowPlan.isCommitted, isTrue);
      expect(saved.tomorrowPlan.tasks.single.areaId, health.id);
      expect(find.byKey(const ValueKey('edit-task-area-0')), findsNothing);
    },
  );

  testWidgets(
    'Rollover closes Area picker and rejects stale editing callback',
    (tester) async {
      var now = date;
      await LocalStorage().save(
        DaylockState(
          areas: book,
          todayPlan: DailyPlan(date: date, tasks: []),
          tomorrowPlan: DailyPlan(
            date: DateTime(2026, 10, 27),
            tasks: [Task(name: 'Walk', type: TaskType.goal)],
          ),
        ),
      );
      await tester.pumpWidget(MainApp(now: () => now));
      await tester.pumpAndSettle();
      await page(tester);
      final before = tester.widget<PlanScreen>(find.byType(PlanScreen));
      final task = before.plan.tasks.single;
      await tap(tester, find.byKey(const ValueKey('edit-task-area-0')));
      now = DateTime(2026, 10, 27, 12);
      before.onTaskAreaChanged!(task, health.id);
      await tester.pumpAndSettle();
      expect(find.byType(AreaChoices), findsNothing);
      expect(task.areaId, Area.defaultId);
      final saved = (await LocalStorage().load())!;
      expect(saved.todayPlan.tasks.single.areaId, Area.defaultId);
      expect(saved.tomorrowPlan.tasks, isEmpty);
    },
  );

  testWidgets('Archived Area remains visible in read-only history', (
    tester,
  ) async {
    final oldDate = DateTime(2026, 10, 25);
    final history = PlanHistory.empty.archive(
      DailyPlan(
        date: oldDate,
        tasks: [
          Task(
            name: 'Walk',
            type: TaskType.goal,
            areaId: health.id,
            isCompleted: true,
          ),
        ],
      ),
    );
    final activity = CalendarDayActivity.forDate(
      date: oldDate,
      currentTime: date,
      todayPlan: DailyPlan(date: date, tasks: []),
      history: history,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DaylockCalendarCommitments(
              activity: activity,
              areas: book.archive(health.id, true),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Health (archived)'), findsOneWidget);
    expect(find.byType(AreaSelector), findsNothing);
  });

  for (final scale in [1.0, 2.0, 3.0]) {
    testWidgets(
      'Area editor and commitment selector fit narrow screen at scale $scale',
      (tester) async {
        tester.view.physicalSize = const Size(320, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const Scaffold(body: AreaEditor()),
          ),
        );
        await tester.enterText(
          find.byKey(const ValueKey('area-name')),
          'Personal wellbeing and meaningful relationships',
        );
        await tester.ensureVisible(find.byKey(const ValueKey('save-area')));
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: CommitmentEditor(
                canCreate: () => true,
                areas: book.upsert(
                  health.copyWith(
                    name: 'Personal wellbeing and meaningful relationships',
                  ),
                ),
                initialTask: Task(
                  name: 'Walk',
                  type: TaskType.goal,
                  areaId: health.id,
                ),
              ),
            ),
          ),
        );
        await tap(tester, find.byKey(const ValueKey('select-area')));
        await tester.ensureVisible(
          find.byKey(ValueKey('choose-area-${health.id}')),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
  }
}

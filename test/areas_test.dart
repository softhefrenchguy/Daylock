import 'dart:convert';

import 'package:daylock/models/area.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/freedom_settings.dart';
import 'package:daylock/models/plan_history.dart';
import 'package:daylock/models/routine.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/services/freedom_service.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:daylock/services/routine_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final date = DateTime(2026, 10, 26, 18);
Area health() =>
    Area.create(name: 'Health', icon: 'health', colour: 0xff348e88, now: date);
DaylockState state({
  AreaBook? areas,
  List<Task>? tasks,
  RoutineBook? routines,
}) => DaylockState(
  areas: areas,
  routines: routines ?? RoutineBook.empty,
  todayPlan: DailyPlan(date: date, tasks: tasks ?? [], isCommitted: true),
  tomorrowPlan: DailyPlan(
    date: DateTime(2026, 10, 27),
    tasks: [],
    isCommitted: true,
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  test('Life persists exactly once across restarts and rollover', () async {
    final initial = AreaBook.initial(createdAt: date);
    await LocalStorage().save(state(areas: initial));
    for (var i = 0; i < 3; i++) {
      final saved = (await LocalStorage().load())!;
      expect(saved.areas.areas, hasLength(1));
      expect(saved.areas.defaultArea.name, 'Life');
      expect(saved.areas.defaultArea.createdAt, date.toUtc());
      expect(
        saved.rollOver(DateTime(2026, 10, 27)).areas.toJson(),
        initial.toJson(),
      );
    }
  });

  test(
    'Rename and appearance edits preserve IDs, timestamp and references',
    () async {
      final custom = health();
      var book = AreaBook.initial(createdAt: date).upsert(custom);
      final defaultId = book.defaultArea.id;
      book = book.upsert(
        book.defaultArea.copyWith(
          name: 'Everything',
          icon: 'home',
          colour: 0xff528cce,
        ),
      );
      book = book.upsert(custom.copyWith(name: 'Wellbeing'));
      await LocalStorage().save(
        state(
          areas: book,
          tasks: [Task(name: 'Walk', type: TaskType.goal, areaId: custom.id)],
        ),
      );
      final saved = (await LocalStorage().load())!;
      expect(saved.areas.defaultArea.id, defaultId);
      expect(saved.areas.resolve(null).name, 'Everything');
      expect(
        saved.areas.resolve(saved.todayPlan.tasks.single.areaId).name,
        'Wellbeing',
      );
      expect(saved.areas.resolve(custom.id).createdAt, custom.createdAt);
      expect(health().id, isNot(custom.id));
    },
  );

  test('Default cannot be archived, removed, replaced or duplicated', () {
    final book = AreaBook.initial(createdAt: date);
    expect(() => book.archive(Area.defaultId, true), throwsFormatException);
    expect(() => AreaBook([]), throwsFormatException);
    expect(
      () => AreaBook([book.defaultArea, book.defaultArea]),
      throwsFormatException,
    );
    expect(
      () => Area(
        id: 'other',
        name: 'Other',
        icon: 'life',
        colour: Area.defaultColour,
        createdAt: date,
        isDefault: true,
      ),
      throwsFormatException,
    );
    expect(
      () => book.upsert(
        AreaBook.initial(createdAt: date.add(const Duration(days: 1)))
            .defaultArea,
      ),
      throwsStateError,
    );
  });

  test(
    'Archive and restore retain historical associations and outcomes',
    () async {
      final custom = health();
      final task = Task(
        name: 'Walk',
        type: TaskType.goal,
        areaId: custom.id,
        isCompleted: true,
      );
      final history = PlanHistory.empty.archive(
        DailyPlan(date: date, tasks: [task], isCommitted: true),
      );
      final before = history.toJson();
      var book = AreaBook.initial().upsert(custom).archive(custom.id, true);
      expect(book.active.map((a) => a.id), [Area.defaultId]);
      expect(book.resolve(custom.id).isArchived, isTrue);
      expect(book.forNewCommitment(custom.id).id, Area.defaultId);
      final snapshot = state(areas: book).toJson()..['history'] = before;
      await LocalStorage().save(DaylockState.fromJson(snapshot));
      final saved = (await LocalStorage().load())!;
      expect(saved.history.toJson(), before);
      expect(saved.areas.resolve(custom.id).name, 'Health');
      book = saved.areas.archive(custom.id, false);
      expect(book.forNewCommitment(custom.id).id, custom.id);
      expect(history.toJson(), before);
    },
  );

  test(
    'Old v2 save migrates once without adding area IDs to history or routines',
    () async {
      final completed = Task(
        name: 'Done',
        type: TaskType.goal,
        areaId: null,
        isCompleted: true,
      );
      final focus = Task(
        name: 'Read',
        type: TaskType.focus,
        areaId: null,
        minimumFocusMinutes: 5,
        accumulatedFocusMilliseconds: 300000,
      );
      final excused = Task(
        name: 'Rest',
        type: TaskType.goal,
        areaId: null,
        outcome: TaskOutcome.excused,
        excuseReason: 'Ill',
      );
      final routine = Routine(
        id: 'old',
        name: 'Old routine',
        steps: [
          RoutineStep(
            id: 'step',
            name: 'Read',
            type: TaskType.goal,
            areaId: null,
          ),
        ],
      );
      final old = state(
        tasks: [completed, focus, excused],
        routines: RoutineBook([routine]),
      ).toJson()..remove('areas');
      old['history'] = PlanHistory.empty
          .archive(
            DailyPlan(
              date: DateTime(2026, 10, 25),
              tasks: [completed, focus, excused],
              isCommitted: true,
            ),
          )
          .toJson();
      final preferences = SharedPreferencesAsync();
      await preferences.setString(LocalStorage.stateKey, jsonEncode(old));
      final migrated = (await LocalStorage(now: () => date).load())!;
      final stored = jsonDecode(
        (await preferences.getString(LocalStorage.stateKey))!,
      ) as Map;
      for (final key in old.keys) {
        expect(
          stored[key],
          old[key],
          reason: '$key must survive additive migration',
        );
      }
      expect(
        migrated.todayPlan.tasks.map((t) => t.areaId),
        everyElement(isNull),
      );
      expect(migrated.todayPlan.tasks.map((t) => t.outcome), [
        TaskOutcome.completed,
        TaskOutcome.completed,
        TaskOutcome.excused,
      ]);
      expect(migrated.areas.resolve(null).id, Area.defaultId);
      final raw = await preferences.getString(LocalStorage.stateKey);
      await LocalStorage(now: () => date.add(const Duration(days: 1))).load();
      expect(await preferences.getString(LocalStorage.stateKey), raw);
    },
  );

  test(
    'Missing, malformed and unknown IDs safely resolve to renamed default',
    () {
      var book = AreaBook.initial();
      book = book.upsert(book.defaultArea.copyWith(name: 'My life'));
      for (final id in [null, '', ' ', 42, {}, 'missing']) {
        final json = Task(name: 'Goal', type: TaskType.goal).toJson()
          ..['areaId'] = id;
        final task = Task.fromJson(json);
        expect(book.resolve(task.areaId).name, 'My life');
        final historical = HistoricalTask.fromJson(json);
        expect(book.resolve(historical.areaId).id, Area.defaultId);
        final step = RoutineStep.fromJson(
          RoutineStep(id: 'step', name: 'Goal', type: TaskType.goal).toJson()
            ..['areaId'] = id,
        );
        expect(book.resolve(step.areaId).id, Area.defaultId);
      }
      expect(Task(name: 'New', type: TaskType.goal).areaId, Area.defaultId);
    },
  );

  test('Changing only Area preserves completion, running Focus and historical snapshot', () {
    final task = Task(
      name: 'Read',
      type: TaskType.focus,
      accumulatedFocusMilliseconds: 12000,
      focusStartedAt: date,
      minimumFocusMinutes: 30,
      focusTarget: 'Chapter 1',
    );
    final before = task.toJson()..remove('areaId');
    final history = HistoricalTask.capture(task, date, settleFocus: false);
    task.areaId = health().id;
    expect(task.toJson()..remove('areaId'), before);
    expect(history.areaId, Area.defaultId);
    expect(history.accumulatedFocusMilliseconds, 12000);
  });

  test(
    'Routine inheritance survives restart and instance edits stay detached',
    () async {
      final custom = health();
      final areas = AreaBook.initial().upsert(custom);
      final step = RoutineStep(
        id: 'walk',
        name: 'Walk',
        type: TaskType.goal,
        areaId: custom.id,
      );
      final routines = RoutineBook([
        Routine(id: 'health', name: 'Daily', steps: [step]),
      ]);
      await LocalStorage().save(state(areas: areas, routines: routines));
      final saved = (await LocalStorage().load())!;
      const service = RoutineService();
      final result = service.resolve(
        saved.routines,
        service.suggestions(saved.routines, date).single,
        RoutineAction.accept,
        date,
        areas: saved.areas,
      );
      expect(result.task!.areaId, custom.id);
      final history = HistoricalTask.capture(result.task!, date);
      result.task!.areaId = Area.defaultId;
      expect(saved.routines.routines.single.steps.single.areaId, custom.id);
      expect(history.areaId, custom.id);
      final next = date.add(const Duration(days: 1));
      expect(
        service.suggestions(result.book, next).single.step.areaId,
        custom.id,
      );
      final changed = result.book.upsert(
        result.book.routines.single.edit(
          name: 'Daily',
          steps: [
            RoutineStep(
              id: 'walk',
              name: 'Walk',
              type: TaskType.goal,
              areaId: Area.defaultId,
            ),
          ],
        ),
      );
      expect(
        service.suggestions(changed, next).single.step.areaId,
        Area.defaultId,
      );
      expect(history.areaId, custom.id);
    },
  );

  test('Archived routine assignment falls back for acceptance, restore resumes inheritance', () {
    final custom = health();
    final areas = AreaBook.initial().upsert(custom).archive(custom.id, true);
    final routines = RoutineBook([
      Routine(
        id: 'r',
        name: 'Routine',
        steps: [
          RoutineStep(
            id: 's',
            name: 'Step',
            type: TaskType.goal,
            areaId: custom.id,
          ),
        ],
      ),
    ]);
    const service = RoutineService();
    final suggestion = service.suggestions(routines, date).single;
    expect(
      service
          .resolve(
            routines,
            suggestion,
            RoutineAction.accept,
            date,
            areas: areas,
          )
          .task!
          .areaId,
      Area.defaultId,
    );
    expect(
      service
          .resolve(
            routines,
            suggestion,
            RoutineAction.accept,
            date,
            areas: areas.archive(custom.id, false),
          )
          .task!
          .areaId,
      custom.id,
    );
    expect(routines.routines.single.steps.single.areaId, custom.id);
    for (final action in [RoutineAction.skip, RoutineAction.dismiss]) {
      final result = service.resolve(
        routines,
        suggestion,
        action,
        date,
        areas: areas,
      );
      expect(result.task, isNull);
      expect(
        result.book.routines.single.decisions.values.single.action,
        action,
      );
    }
  });

  test('Area assignments do not alter Freedom eligibility', () {
    final tasks = [
      Task(name: 'Done', type: TaskType.goal, isCompleted: true),
      Task(
        name: 'Excused',
        type: TaskType.goal,
        outcome: TaskOutcome.excused,
        excuseReason: 'Ill',
      ),
    ];
    final plans = state(tasks: tasks);
    FreedomEligibility evaluate() => const FreedomService().evaluate(
      now: date,
      settings: const FreedomSettings(enabled: true),
      todayPlan: plans.todayPlan,
      tomorrowPlan: plans.tomorrowPlan,
    );
    for (final id in [null, Area.defaultId, health().id, 'missing']) {
      for (final task in tasks) {
        task.areaId = id;
      }
      final result = evaluate();
      expect(result.earned, isTrue);
      expect(result.completedCount, 1);
      expect(result.eligibleCount, 1);
    }
    tasks.first.isCompleted = false;
    expect(evaluate().earned, isFalse);
  });

  test('Malformed Area collection fails safely without overwriting saved user data', () async {
    final raw = jsonEncode(
      state(
        tasks: [Task(name: 'Keep me', type: TaskType.goal)],
      ).toJson()..['areas'] = [],
    );
    final preferences = SharedPreferencesAsync();
    await preferences.setString(LocalStorage.stateKey, raw);
    await expectLater(LocalStorage().load(), throwsFormatException);
    expect(await preferences.getString(LocalStorage.stateKey), raw);
  });
}

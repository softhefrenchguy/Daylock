import 'dart:convert';

import 'package:daylock/design/appearance_preferences.dart';
import 'package:daylock/design/daylock_palette.dart';
import 'package:daylock/models/calendar_account.dart';
import 'package:daylock/models/calendar_activity.dart';
import 'package:daylock/models/calendar_cache.dart';
import 'package:daylock/models/commitment_progress.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/event.dart';
import 'package:daylock/models/plan_history.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/services/appearance_storage.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'calendar_test_fixtures.dart';

final _now = DateTime(2026, 10, 13, 10);
Task _goal(TaskOutcome outcome) => Task(
  name: 'Sell car',
  type: TaskType.goal,
  outcome: outcome,
  excuseReason: outcome == TaskOutcome.excused ? 'Buyer did not arrive.' : null,
);
DailyPlan _plan(List<Task> tasks, {DateTime? date}) =>
    DailyPlan(date: date ?? _now, tasks: tasks, isCommitted: true);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  for (final outcome in TaskOutcome.values) {
    test(
      'Goal $outcome survives JSON and keeps completion separate from excuses',
      () {
        final goal = _goal(outcome);
        final restored = Task.fromJson(
          jsonDecode(jsonEncode(goal.toJson())) as Map<String, dynamic>,
        );
        expect(restored.outcome, outcome);
        expect(restored.isCompleted, outcome == TaskOutcome.completed);
        expect(restored.isEligible, outcome != TaskOutcome.excused);
        expect(restored.excuseReason, goal.excuseReason);
        expect(restored.toJson(), goal.toJson());
      },
    );
  }

  test('Goals support completion, excuses, reset and normal checkbox completion after reversal', () {
    final goal = _goal(TaskOutcome.incomplete);
    goal.isCompleted = true;
    expect(goal.outcome, TaskOutcome.completed);
    goal.changeOutcome(
      TaskOutcome.excused,
      now: _now,
      reason: '  Buyer did not arrive.  ',
    );
    expect(goal.excuseReason, 'Buyer did not arrive.');
    expect(goal.isCompleted, isFalse);
    goal.changeOutcome(TaskOutcome.incomplete, now: _now);
    expect(goal.excuseReason, isNull);
    expect(goal.isEligible, isTrue);
    goal.isCompleted = true;
    expect(goal.outcome, TaskOutcome.completed);
  });

  test('Invalid reasons never change the existing outcome or interrupt a running Focus session', () {
    final task = Task(
      name: 'Study',
      type: TaskType.focus,
      minimumFocusMinutes: 60,
    );
    task.startFocus(_now);
    final before = task.toJson();
    for (final reason in [null, '', '   ', 'x' * 241]) {
      expect(
        () => task.changeOutcome(
          TaskOutcome.excused,
          now: _now.add(const Duration(minutes: 5)),
          reason: reason,
        ),
        throwsFormatException,
      );
      expect(task.toJson(), before);
    }
  });

  for (final completed in [2, 3]) {
    test(
      '$completed completed plus one excused uses three eligible commitments',
      () {
        final progress = _plan([
          for (var i = 0; i < 3; i++)
            _goal(
              i < completed ? TaskOutcome.completed : TaskOutcome.incomplete,
            ),
          _goal(TaskOutcome.excused),
        ]).progress;
        expect(progress.totalCount, 4);
        expect(progress.eligibleCount, 3);
        expect(progress.excusedCount, 1);
        expect(progress.completedCount, completed);
        expect(progress.percentage, closeTo(completed / 3 * 100, .00001));
        expect(progress.isComplete, completed == 3);
      },
    );
  }

  test('All excused and empty plans are neutral, with no division or false completion', () {
    for (final tasks in [
      <Task>[],
      [_goal(TaskOutcome.excused), _goal(TaskOutcome.excused)],
    ]) {
      final progress = _plan(tasks).progress;
      expect(progress.eligibleCount, 0);
      expect(progress.completedCount, 0);
      expect(progress.fraction, isNull);
      expect(progress.percentage, isNull);
      expect(progress.isComplete, isFalse);
      expect(progress.isNeutral, isTrue);
    }
    expect(
      CommitmentProgress.fromOutcomes([TaskOutcome.incomplete]).percentage,
      0,
    );
  });

  test('Excusing running Focus settles exact elapsed time and never accrues after excuse or restart', () {
    final task = Task(
      name: 'Study',
      type: TaskType.focus,
      minimumFocusMinutes: 60,
      accumulatedFocusMilliseconds: 1001,
    );
    task.startFocus(_now);
    task.changeOutcome(
      TaskOutcome.excused,
      now: _now.add(const Duration(milliseconds: 23500)),
      reason: 'Power cut.',
    );
    expect(task.accumulatedFocusMilliseconds, 24501);
    expect(task.focusStartedAt, isNull);
    expect(task.isCompleted, isFalse);
    task.startFocus(_now.add(const Duration(hours: 1)));
    expect(task.isFocusRunning, isFalse);
    final restored = Task.fromJson(task.toJson());
    expect(
      restored.focusMillisecondsAt(_now.add(const Duration(days: 5))),
      24501,
    );
    restored.changeOutcome(
      TaskOutcome.incomplete,
      now: _now.add(const Duration(days: 5)),
    );
    restored.startFocus(_now.add(const Duration(days: 5)));
    restored.pauseFocus(_now.add(const Duration(days: 5, milliseconds: 499)));
    expect(restored.accumulatedFocusMilliseconds, 25000);
    expect(restored.excuseReason, isNull);
  });

  test('Focus completion cannot bypass minimum; resetting retains earned time and completion resumes safely', () {
    final task = Task(
      name: 'Study',
      type: TaskType.focus,
      minimumFocusMinutes: 1,
    );
    expect(
      () => task.changeOutcome(TaskOutcome.completed, now: _now),
      throwsStateError,
    );
    expect(() => task.isCompleted = true, throwsStateError);
    task.startFocus(_now);
    task.finishFocusIfDue(_now.add(const Duration(minutes: 1)));
    expect(task.outcome, TaskOutcome.completed);
    task.changeOutcome(
      TaskOutcome.excused,
      now: _now,
      reason: 'Appointment cancelled.',
    );
    expect(task.outcome, TaskOutcome.excused);
    expect(task.accumulatedFocusMilliseconds, 60000);
    task.changeOutcome(TaskOutcome.incomplete, now: _now);
    final restored = Task.fromJson(task.toJson());
    expect(restored.outcome, TaskOutcome.incomplete);
    expect(restored.accumulatedFocusMilliseconds, 60000);
    restored.startFocus(_now);
    expect(restored.outcome, TaskOutcome.completed);
    expect(restored.isFocusRunning, isFalse);
  });

  test('Excusing Focus near or beyond midnight cannot overwrite its archived outcome', () {
    final task = Task(
      name: 'Study',
      type: TaskType.focus,
      minimumFocusMinutes: 60,
      focusStartedAt: DateTime(2026, 10, 13, 23, 50),
    );
    final before = task.toJson();
    final state = DaylockState(
      todayPlan: _plan([task]),
      tomorrowPlan: _plan([], date: DateTime(2026, 10, 14)),
    );
    final rolled = state.rollOver(DateTime(2026, 10, 14, 8));
    task.changeOutcome(
      TaskOutcome.excused,
      now: DateTime(2026, 10, 14, 8),
      reason: 'Changed too late.',
    );
    final past = rolled.history.forDate(_now)!.tasks.single;
    expect(past.outcome, TaskOutcome.incomplete);
    expect(past.accumulatedFocusMilliseconds, 600000);
    expect(past.excuseReason, isNull);
    expect(before['focusStartedAt'], isNotNull);
  });

  test('Rollover archives final outcomes, reason and exact Focus while snapshots stay immutable', () {
    final focus = Task(
      name: 'Study',
      type: TaskType.focus,
      minimumFocusMinutes: 60,
      accumulatedFocusMilliseconds: 23000123,
    );
    focus.changeOutcome(
      TaskOutcome.excused,
      now: _now,
      reason: 'Class cancelled.',
    );
    final today = _plan([
      _goal(TaskOutcome.completed),
      _goal(TaskOutcome.incomplete),
      focus,
    ]);
    final rolled = DaylockState(
      todayPlan: today,
      tomorrowPlan: _plan([], date: DateTime(2026, 10, 14)),
    ).rollOver(DateTime(2026, 10, 14));
    final past = rolled.history.forDate(_now)!;
    expect(past.summary.commitmentCount, 3);
    expect(past.summary.eligibleCount, 2);
    expect(past.summary.excusedCount, 1);
    expect(past.summary.completionPercentage, 50);
    expect(past.tasks.last.excuseReason, 'Class cancelled.');
    expect(past.summary.accumulatedFocusMilliseconds, 23000123);
    focus.changeOutcome(TaskOutcome.incomplete, now: _now);
    expect(past.tasks.last.outcome, TaskOutcome.excused);
    expect(past.tasks.last.excuseReason, 'Class cancelled.');
    expect(
      PlanHistory.fromJson(rolled.history.toJson()).toJson(),
      rolled.history.toJson(),
    );
  });

  test('Calendar and history share eligible percentages; all excused is neutral, incomplete remains zero', () {
    final history = PlanHistory.empty
        .archive(
          _plan([
            _goal(TaskOutcome.completed),
            _goal(TaskOutcome.excused),
          ], date: DateTime(2026, 10, 10)),
        )
        .archive(
          _plan([_goal(TaskOutcome.excused)], date: DateTime(2026, 10, 11)),
        )
        .archive(
          _plan([
            _goal(TaskOutcome.incomplete),
            _goal(TaskOutcome.excused),
          ], date: DateTime(2026, 10, 12)),
        );
    for (final entry in {
      10: HeatmapIntensity.complete,
      11: HeatmapIntensity.neutral,
      12: HeatmapIntensity.zero,
    }.entries) {
      final activity = CalendarDayActivity.forDate(
        date: DateTime(2026, 10, entry.key),
        currentTime: _now,
        history: history,
      );
      expect(activity.intensity, entry.value);
      expect(
        activity.completionPercentage,
        history.summaryForDate(activity.date)!.completionPercentage,
      );
    }
    expect(history.summaryForDate(DateTime(2026, 10, 11))!.isNeutral, isTrue);
    expect(history.forDate(DateTime(2026, 10, 9)), isNull);
  });

  for (final type in TaskType.values) {
    for (final completed in [false, true]) {
      test(
        'Legacy $type completed=$completed migrates without changing its outcome or time',
        () {
          final json = {
            'name': 'Legacy',
            'type': type.name,
            'isCompleted': completed,
            if (type == TaskType.focus) ...{
              'minimumFocusMinutes': 60,
              'accumulatedFocusMilliseconds': completed ? 3600000 : 12345,
            },
          };
          final restored = Task.fromJson(json);
          expect(
            restored.outcome,
            completed ? TaskOutcome.completed : TaskOutcome.incomplete,
          );
          expect(restored.excuseReason, isNull);
          if (type == TaskType.focus) {
            expect(
              restored.accumulatedFocusMilliseconds,
              json['accumulatedFocusMilliseconds'],
            );
          }
        },
      );
    }
  }

  test('Existing live and historical tasks migrate in-place without touching events, accounts or appearance', () async {
    final accounts = [
      for (final type in CalendarProviderType.values) testAccount(type),
    ];
    final cache = CalendarCache(
      accounts: accounts,
      calendars: accounts.map(testCalendar),
      events: accounts.map(testExternal),
    );
    final state = DaylockState(
      todayPlan: _plan([
        _goal(TaskOutcome.completed),
        Task(
          name: 'Running',
          type: TaskType.focus,
          minimumFocusMinutes: 60,
          accumulatedFocusMilliseconds: 12345,
          focusStartedAt: _now,
        ),
      ]),
      tomorrowPlan: _plan([
        _goal(TaskOutcome.incomplete),
      ], date: DateTime(2026, 10, 14)),
      history: PlanHistory.empty.archive(
        _plan([_goal(TaskOutcome.completed)], date: DateTime(2026, 10, 12)),
      ),
      events: [Event(id: 'local', title: 'Lesson', date: _now)],
      calendarCache: cache,
    );
    final old = state.toJson();
    for (final plan in [
      old['todayPlan'],
      old['tomorrowPlan'],
      ...old['history'] as List,
    ]) {
      for (final task in (plan as Map)['tasks'] as List) {
        (task as Map).remove('outcome');
        task.remove('excuseReason');
      }
    }
    final prefs = SharedPreferencesAsync();
    await prefs.setString(LocalStorage.stateKey, jsonEncode(old));
    await AppearanceStorage().save(
      const AppearancePreferences(
        mode: AppearanceMode.system,
        colour: ColourTheme.forest,
      ),
    );
    final appearance = await prefs.getString(AppearanceStorage.key);
    await prefs.setString('unrelated', 'retain');
    final restored = (await LocalStorage().load())!;
    expect(restored.toJson(), state.toJson());
    expect(
      jsonDecode((await prefs.getString(LocalStorage.stateKey))!),
      state.toJson(),
    );
    expect(await prefs.getString(AppearanceStorage.key), appearance);
    expect(await prefs.getString('unrelated'), 'retain');
    expect((await LocalStorage().load())!.toJson(), state.toJson());
  });

  test('Mixed old/new task records migrate while preserving existing excuses and their history', () async {
    final state = DaylockState(
      todayPlan: _plan([
        _goal(TaskOutcome.excused),
        _goal(TaskOutcome.completed),
      ]),
      tomorrowPlan: _plan([], date: DateTime(2026, 10, 14)),
      history: PlanHistory.empty.archive(
        _plan([_goal(TaskOutcome.excused)], date: DateTime(2026, 10, 12)),
      ),
    );
    final json = state.toJson();
    final task = json['todayPlan']['tasks'][1] as Map;
    task.remove('outcome');
    task.remove('excuseReason');
    await SharedPreferencesAsync().setString(
      LocalStorage.stateKey,
      jsonEncode(json),
    );
    expect((await LocalStorage().load())!.toJson(), state.toJson());
  });

  test('Outcome migration write failure retains the original save and retries safely', () async {
    final state = DaylockState(
      todayPlan: _plan([_goal(TaskOutcome.completed)]),
      tomorrowPlan: _plan([], date: DateTime(2026, 10, 14)),
    );
    final json = state.toJson();
    for (final task in json['todayPlan']['tasks'] as List) {
      (task as Map).remove('outcome');
      task.remove('excuseReason');
    }
    final original = jsonEncode(json);
    final prefs = SharedPreferencesAsync();
    await prefs.setString(LocalStorage.stateKey, original);
    var fail = true;
    final storage = LocalStorage(
      preferences: _FailingPreferences(prefs, () => fail),
    );
    await expectLater(storage.load(), throwsStateError);
    expect(await prefs.getString(LocalStorage.stateKey), original);
    fail = false;
    expect((await storage.load())!.toJson(), state.toJson());
  });

  test('v1 migration retains legacy completed Focus, Goal outcomes and the original backup', () async {
    final raw = jsonEncode({
      'tasks': [
        {'name': 'Done goal', 'type': 'goal', 'isCompleted': true},
        {'name': 'Legacy Focus', 'type': 'focus', 'isCompleted': true},
      ],
      'tomorrowTasks': [
        {'name': 'Pending', 'type': 'goal', 'isCompleted': false},
      ],
      'isTomorrowCommitted': true,
    });
    final prefs = SharedPreferencesAsync();
    await prefs.setString(LocalStorage.legacyStateKey, raw);
    final saved = (await LocalStorage(now: () => _now).load())!;
    expect(saved.todayPlan.tasks.map((task) => task.outcome), [
      TaskOutcome.completed,
      TaskOutcome.completed,
    ]);
    expect(
      saved.todayPlan.tasks.last.accumulatedFocusMilliseconds,
      Task.legacyFocusMinutes * 60000,
    );
    expect(saved.tomorrowPlan.tasks.single.outcome, TaskOutcome.incomplete);
    expect(saved.tomorrowPlan.isCommitted, isTrue);
    expect(await prefs.getString(LocalStorage.legacyStateKey), raw);
    expect(saved.history.plans, isEmpty);
  });

  test('Invalid outcome, absent reason, contradictory completion or running excused timer never resets raw data', () async {
    final state = DaylockState(
      todayPlan: _plan([_goal(TaskOutcome.incomplete)]),
      tomorrowPlan: _plan([], date: DateTime(2026, 10, 14)),
    );
    for (final task in [
      {..._goal(TaskOutcome.incomplete).toJson(), 'outcome': 'unknown'},
      {..._goal(TaskOutcome.excused).toJson(), 'excuseReason': '  '},
      {..._goal(TaskOutcome.excused).toJson(), 'isCompleted': true},
      {
        ...Task(
          name: 'Focus',
          type: TaskType.focus,
          outcome: TaskOutcome.excused,
          excuseReason: 'Cancelled.',
        ).toJson(),
        'focusStartedAt': _now.toUtc().toIso8601String(),
      },
    ]) {
      final json = state.toJson();
      json['todayPlan']['tasks'] = [task];
      final raw = jsonEncode(json);
      final prefs = SharedPreferencesAsync();
      await prefs.setString(LocalStorage.stateKey, raw);
      await expectLater(LocalStorage().load(), throwsA(isA<Exception>()));
      expect(await prefs.getString(LocalStorage.stateKey), raw);
    }
  });
}

class _FailingPreferences extends SharedPreferencesAsync {
  final SharedPreferencesAsync delegate;
  final bool Function() shouldFail;
  _FailingPreferences(this.delegate, this.shouldFail);
  @override
  Future<String?> getString(String key) => delegate.getString(key);
  @override
  Future<void> setString(String key, String value) async {
    if (shouldFail()) throw StateError('Storage unavailable');
    await delegate.setString(key, value);
  }
}

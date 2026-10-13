import 'dart:convert';

import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/plan_history.dart';
import 'package:daylock/models/task.dart';
import 'package:flutter_test/flutter_test.dart';

final _date = DateTime(2026, 10, 7);
DailyPlan _plan(DateTime date, {bool committed = true, List<Task>? tasks}) =>
    DailyPlan(
      date: date,
      isCommitted: committed,
      tasks:
          tasks ?? [Task(name: 'Walk', type: TaskType.goal, isCompleted: true)],
    );
DaylockState _state({bool committed = true, List<Task>? todayTasks}) =>
    DaylockState(
      todayPlan: _plan(_date, tasks: todayTasks),
      tomorrowPlan: _plan(
        DateTime(2026, 10, 8),
        committed: committed,
        tasks: [
          Task(
            name: 'Read',
            type: TaskType.focus,
            minimumFocusMinutes: 60,
            focusTarget: 'Chapter 7',
          ),
        ],
      ),
    );

void main() {
  test('History preserves task requirements, recorded completion and fractional milliseconds', () {
    final plan = _plan(
      _date,
      tasks: [
        Task(name: 'Walk', type: TaskType.goal, isCompleted: true),
        Task(name: 'Apply', type: TaskType.goal),
        Task(
          name: 'Read',
          type: TaskType.focus,
          minimumFocusMinutes: 60,
          focusTarget: 'Chapter 7',
          accumulatedFocusMilliseconds: 23 * 60000 + 15234,
        ),
      ],
    );
    final history = PlanHistory.empty.archive(plan);
    final past = history.forDate(_date)!;
    expect(past.date, _date);
    expect(past.isCommitted, isTrue);
    expect(past.tasks.map((task) => task.type), [
      TaskType.goal,
      TaskType.goal,
      TaskType.focus,
    ]);
    expect(past.tasks.last.minimumFocusMinutes, 60);
    expect(past.tasks.last.focusTarget, 'Chapter 7');
    expect(past.summary.commitmentCount, 3);
    expect(past.summary.completedCount, 1);
    expect(past.summary.completionPercentage, closeTo(100 / 3, .0001));
    expect(past.summary.accumulatedFocusMilliseconds, 23 * 60000 + 15234);
    final restored = PlanHistory.fromJson(
      jsonDecode(jsonEncode(history.toJson())) as List,
    );
    expect(restored.toJson(), history.toJson());
  });

  test('History is detached from live plans and returns immutable records and collections', () {
    final plan = _plan(_date);
    final history = PlanHistory.empty.archive(plan);
    plan.tasks.first.name = 'Changed';
    plan.tasks.first.isCompleted = false;
    plan.isCommitted = false;
    plan.tasks.clear();
    final past = history.forDate(_date)!;
    expect(past.tasks.single.name, 'Walk');
    expect(past.tasks.single.isCompleted, isTrue);
    expect(past.isCommitted, isTrue);
    expect(() => past.tasks.clear(), throwsUnsupportedError);
    expect(() => history.plans.clear(), throwsUnsupportedError);
    expect(() => history.summaries().clear(), throwsUnsupportedError);
    expect(
      () => (past.tasks.single as dynamic).isCompleted = false,
      throwsNoSuchMethodError,
    );
    final json = history.toJson();
    (json.single['tasks'] as List).clear();
    expect(past.tasks, hasLength(1));
  });

  test(
    'A repeated date cannot duplicate or overwrite its original snapshot',
    () {
      final plan = _plan(_date);
      final original = PlanHistory.empty.archive(plan);
      plan.tasks.first.isCompleted = false;
      final repeated = original.archive(plan);
      expect(repeated, same(original));
      expect(repeated.plans, hasLength(1));
      expect(repeated.summaryForDate(_date)!.completionPercentage, 100);
    },
  );

  test('Known empty days are neutral and unknown dates have no record', () {
    final history = PlanHistory.empty.archive(_plan(_date, tasks: []));
    final empty = history.summaryForDate(_date)!;
    expect(empty.isNeutral, isTrue);
    expect(empty.commitmentCount, 0);
    expect(empty.completedCount, 0);
    expect(empty.completionFraction, isNull);
    expect(empty.completionPercentage, isNull);
    expect(history.forDate(DateTime(2026, 10, 6)), isNull);
    expect(history.summaryForDate(DateTime(2026, 10, 8)), isNull);
  });

  test(
    'Queries normalise calendar dates, sort records and use inclusive ranges',
    () {
      var history = PlanHistory.empty;
      for (final day in [9, 7, 8]) {
        history = history.archive(_plan(DateTime(2026, 10, day)));
      }
      expect(history.plans.map((plan) => plan.date.day), [7, 8, 9]);
      expect(history.forDate(DateTime(2026, 10, 8, 23, 59))!.date.day, 8);
      expect(
        history
            .summaries(
              from: DateTime(2026, 10, 8, 18),
              through: DateTime(2026, 10, 9),
            )
            .map((s) => s.date.day),
        [8, 9],
      );
      expect(history.summaries(from: DateTime(2026, 10, 10)), isEmpty);
    },
  );

  test('Same-day and backwards-date checks do not archive or alter plans', () {
    final state = _state();
    expect(state.rollOver(DateTime(2026, 10, 7, 23, 59)), same(state));
    expect(state.rollOver(DateTime(2026, 10, 6)), same(state));
    expect(state.history.plans, isEmpty);
  });

  test(
    'One-day rollover archives Today before promoting the real tomorrow plan',
    () {
      final state = _state();
      final rolled = state.rollOver(DateTime(2026, 10, 8));
      expect(rolled.todayPlan, same(state.tomorrowPlan));
      expect(rolled.history.plans.map((plan) => plan.date), [_date]);
      expect(rolled.history.summaryForDate(_date)!.completionPercentage, 100);
      expect(rolled.history.forDate(DateTime(2026, 10, 8)), isNull);
      expect(rolled.rollOver(DateTime(2026, 10, 8, 20)), same(rolled));
      final next = rolled.rollOver(DateTime(2026, 10, 9));
      expect(next.history.plans.map((plan) => plan.date.day), [7, 8]);
      expect(
        next.history
            .forDate(DateTime(2026, 10, 8))!
            .tasks
            .single
            .minimumFocusMinutes,
        60,
      );
    },
  );

  for (final gap in [2, 10, 1000]) {
    test(
      '$gap missed days preserve known Today and committed tomorrow but never backfill gaps',
      () {
        final rolled = _state().rollOver(DateTime(2026, 10, 7 + gap));
        expect(rolled.history.plans.map((plan) => plan.date.day), [7, 8]);
        expect(
          rolled.history.summaryForDate(DateTime(2026, 10, 8))!.completedCount,
          0,
        );
        expect(
          rolled.history
              .summaryForDate(DateTime(2026, 10, 8))!
              .accumulatedFocusMilliseconds,
          0,
        );
        expect(rolled.history.forDate(DateTime(2026, 10, 9)), isNull);
        expect(rolled.todayPlan.tasks, isEmpty);
        expect(rolled.todayPlan.date, DateTime(2026, 10, 7 + gap));
        expect(rolled.tomorrowPlan.isCommitted, isFalse);
      },
    );
  }

  test('An expired uncommitted draft never becomes fabricated historical commitments', () {
    final rolled = _state(committed: false).rollOver(DateTime(2026, 10, 20));
    expect(rolled.history.plans, hasLength(1));
    expect(rolled.history.forDate(DateTime(2026, 10, 8)), isNull);
  });

  test(
    'An uncommitted plan actually executed as Today retains its true state',
    () {
      final today = _plan(_date, committed: false);
      final state = DaylockState(
        todayPlan: today,
        tomorrowPlan: _plan(DateTime(2026, 10, 8), tasks: []),
      );
      final archived = state
          .rollOver(DateTime(2026, 10, 8))
          .history
          .forDate(_date)!;
      expect(archived.isCommitted, isFalse);
      expect(archived.tasks.single.isCompleted, isTrue);
    },
  );

  test('Interrupted Focus is credited only until local midnight, preserving exact milliseconds', () {
    final start = DateTime(2026, 10, 7, 23, 50, 10, 250);
    final task = Task(
      name: 'Read',
      type: TaskType.focus,
      minimumFocusMinutes: 60,
      accumulatedFocusMilliseconds: 20 * 60000 + 500,
    )..startFocus(start);
    final old = task.toJson();
    final state = _state(todayTasks: [task]);
    final rolled = state.rollOver(DateTime(2026, 10, 20, 9));
    final past = rolled.history.forDate(_date)!.tasks.single;
    final expected =
        20 * 60000 +
        500 +
        DateTime(2026, 10, 8).toUtc().difference(start.toUtc()).inMilliseconds;
    expect(past.accumulatedFocusMilliseconds, expected);
    expect(past.isCompleted, isFalse);
    expect(past.toJson()['focusStartedAt'], isNull);
    expect(task.toJson(), old);
  });

  test('Focus completed before midnight is complete, regardless of its target text', () {
    final task = Task(
      name: 'Read',
      type: TaskType.focus,
      minimumFocusMinutes: 5,
      focusTarget: 'Unfinished chapter',
    )..startFocus(DateTime(2026, 10, 7, 23, 50));
    final rolled = _state(todayTasks: [task])
        .rollOver(DateTime(2026, 10, 8, 7));
    final past = rolled.history.forDate(_date)!;
    expect(past.tasks.single.accumulatedFocusMilliseconds, 5 * 60000);
    expect(past.tasks.single.isCompleted, isTrue);
    expect(past.summary.completionPercentage, 100);
  });

  test('Paused Focus gains no time and a start timestamp after the boundary gains no time', () {
    final task = Task(
      name: 'Paused',
      type: TaskType.focus,
      minimumFocusMinutes: 60,
      accumulatedFocusMilliseconds: 23456,
    );
    final future = Task(
      name: 'Clock changed',
      type: TaskType.focus,
      minimumFocusMinutes: 60,
      accumulatedFocusMilliseconds: 12345,
      focusStartedAt: DateTime(2026, 10, 8, 1),
    );
    final past = _state(todayTasks: [task, future])
        .rollOver(DateTime(2026, 10, 9))
        .history
        .forDate(_date)!;
    expect(past.tasks.map((task) => task.accumulatedFocusMilliseconds), [
      23456,
      12345,
    ]);
    expect(past.summary.accumulatedFocusMilliseconds, 35801);
  });

  test('Missed committed drafts preserve saved Focus time without inferring execution', () {
    final state = _state();
    state.tomorrowPlan.tasks.single.accumulatedFocusMilliseconds = 12345;
    state.tomorrowPlan.tasks.single.focusStartedAt = DateTime(
      2026,
      10,
      7,
      22,
    ).toUtc();
    final rolled = state.rollOver(DateTime(2026, 10, 20));
    final task = rolled.history.forDate(DateTime(2026, 10, 8))!.tasks.single;
    expect(task.accumulatedFocusMilliseconds, 12345);
    expect(task.isCompleted, isFalse);
  });

  for (final date in [
    DateTime(2026, 4, 30),
    DateTime(2026, 12, 31),
    DateTime(2028, 2, 29),
    DateTime(2026, 3, 29),
    DateTime(2026, 10, 25),
  ]) {
    test(
      'Focus archive uses the actual calendar midnight at ${date.toIso8601String()}',
      () {
        final next = DateTime(date.year, date.month, date.day + 1);
        final task = Task(
          name: 'Focus',
          type: TaskType.focus,
          minimumFocusMinutes: 2000,
        )..startFocus(date);
        final state = DaylockState(
          todayPlan: _plan(date, tasks: [task]),
          tomorrowPlan: _plan(next, tasks: []),
        );
        final archived = state
            .rollOver(next.add(const Duration(hours: 8)))
            .history
            .forDate(date)!;
        expect(
          archived.tasks.single.accumulatedFocusMilliseconds,
          next.toUtc().difference(date.toUtc()).inMilliseconds,
        );
        expect(archived.date, date);
      },
    );
  }

  test('Duplicate records, invalid calendar dates and running historical timers fail validation', () {
    final json = PlanHistory.empty.archive(_plan(_date)).toJson().single;
    expect(() => PlanHistory.fromJson([json, json]), throwsFormatException);
    expect(
      () => PlanHistory.fromJson([
        {...json, 'date': '2026-02-30'},
      ]),
      throwsFormatException,
    );
    final running = Task(name: 'Focus', type: TaskType.focus)
      ..startFocus(_date);
    expect(
      () => PlanHistory.fromJson([
        {
          ...json,
          'tasks': [running.toJson()],
        },
      ]),
      throwsFormatException,
    );
  });
}

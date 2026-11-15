import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/routine.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/services/routine_service.dart';
import 'package:flutter_test/flutter_test.dart';

// A Wednesday.
final date = DateTime(2026, 10, 14);
const service = RoutineService();
DateTime day(int offset) => DateTime(date.year, date.month, date.day + offset);
DailyPlan draft(DateTime date, [List<Task>? tasks]) =>
    DailyPlan(date: date, tasks: tasks ?? []);
Routine cycle({String id = 'workout', RoutineSchedule? schedule}) => Routine(
  id: id,
  name: 'Training',
  schedule: schedule,
  steps: [
    for (final name in ['Push', 'Pull', 'Legs', 'Conditioning'])
      RoutineStep(id: name, name: name, type: TaskType.goal),
  ],
);

void main() {
  group('RoutineSchedule', () {
    test('Every N days is fixed to the calendar from its start', () {
      final every2 = RoutineSchedule.everyDays(2, from: date);
      expect(
        [for (var i = 0; i < 7; i++) every2.isDue(day(i))],
        [true, false, true, false, true, false, true],
      );
      expect(every2.isDue(day(-2)), isFalse, reason: 'never before its start');
      expect(every2.upcoming(day(1)), [day(2), day(4), day(6)]);
      expect(every2.label, 'Every 2 days');
    });

    test('Intervals count calendar days across DST and month/year ends', () {
      // Europe and US DST changes, a leap day and New Year.
      final every3 = RoutineSchedule.everyDays(3, from: DateTime(2026, 3, 27));
      expect(every3.isDue(DateTime(2026, 3, 30)), isTrue);
      expect(every3.isDue(DateTime(2026, 4, 2)), isTrue);
      final every7 = RoutineSchedule.everyDays(7, from: DateTime(2027, 12, 29));
      expect(every7.isDue(DateTime(2028, 1, 5)), isTrue);
      expect(every7.isDue(DateTime(2028, 3, 1)), isTrue);
      expect(
        calendarDaysBetween(DateTime(2028, 2, 28), DateTime(2028, 3, 1)),
        2,
      );
    });

    test('Weekdays match chosen days and read naturally', () {
      final mwf = RoutineSchedule.onWeekdays({5, 1, 3});
      expect(mwf.isDue(date), isTrue); // Wednesday
      expect(mwf.isDue(day(1)), isFalse);
      expect(mwf.upcoming(day(1)), [day(2), day(5), day(7)]);
      expect(mwf.label, 'Mon, Wed, Fri');
      expect(RoutineSchedule.onWeekdays({1, 2, 3, 4, 5}).label, 'Weekdays');
      expect(RoutineSchedule.onWeekdays({6, 7}).label, 'Weekends');
      expect(RoutineSchedule.onWeekdays({1, 2, 3, 4, 5, 6, 7}).label, 'Daily');
      expect(RoutineSchedule.daily().label, 'Daily');
    });

    test('Round trips and rejects invalid rules', () {
      for (final schedule in [
        RoutineSchedule.everyDays(5, from: date),
        RoutineSchedule.onWeekdays({2, 4}),
      ]) {
        final restored = RoutineSchedule.fromJson(schedule.toJson());
        expect(restored.toJson(), schedule.toJson());
        expect(restored.sameRule(schedule), isTrue);
      }
      expect(
        () => RoutineSchedule.everyDays(0, from: date),
        throwsFormatException,
      );
      expect(
        () => RoutineSchedule.everyDays(31, from: date),
        throwsFormatException,
      );
      expect(() => RoutineSchedule.onWeekdays({}), throwsFormatException);
      expect(() => RoutineSchedule.onWeekdays({8}), throwsFormatException);
      expect(
        () => RoutineSchedule.fromJson({'kind': 'monthly'}),
        throwsFormatException,
      );
    });
  });

  test('Due routines are added once to the draft and rotations wrap', () {
    var book = RoutineBook([cycle()]);
    for (var offset = 0; offset < 5; offset++) {
      final plan = draft(day(offset));
      final applied = service.apply(book, plan);
      expect(
        applied.added.single.name,
        ['Push', 'Pull', 'Legs', 'Conditioning'][offset % 4],
      );
      expect(applied.added.single.routineId, 'workout');
      expect(applied.added.single.outcome, TaskOutcome.incomplete);
      plan.tasks.addAll(applied.added);
      expect(service.apply(applied.book, plan).changed, isFalse);
      // Even if the task is later removed, a decided date is not re-added.
      expect(service.apply(applied.book, draft(day(offset))).changed, isFalse);
      book = applied.book;
    }
    expect(book.routines.single.nextStep.name, 'Pull');
  });

  test('Only due dates get the routine and committed plans are untouched', () {
    final book = RoutineBook([
      cycle(schedule: RoutineSchedule.everyDays(2, from: date)),
    ]);
    expect(service.apply(book, draft(day(1))).changed, isFalse);
    expect(service.apply(book, draft(day(2))).added.single.name, 'Push');
    final locked = DailyPlan(date: date, tasks: [], isCommitted: true);
    expect(service.apply(book, locked).changed, isFalse);
    expect(locked.tasks, isEmpty);
  });

  test('Removing a rotation step brings the same step back next time', () {
    final book = RoutineBook([
      cycle(schedule: RoutineSchedule.onWeekdays({1, 3, 5})),
    ]);
    final wed = service.apply(book, draft(date));
    expect(wed.added.single.name, 'Push');
    final removed = wed.book.routines.single.remove(date);
    expect(
      removed.decisions[routineDateKey(date)]!.action,
      RoutineAction.removed,
    );
    expect(removed.nextStep.name, 'Push');
    final fri = service.apply(RoutineBook([removed]), draft(day(2)));
    expect(fri.added.single.name, 'Push');
    // Undo puts it back and moves the rotation on again.
    final restored = removed.restore(date);
    expect(restored.nextStep.name, 'Pull');
    expect(
      restored.decisions[routineDateKey(date)]!.action,
      RoutineAction.added,
    );
    expect(restored.remove(day(9)), same(restored), reason: 'no decision');
  });

  test(
    'Focus definition retains minimum and target but copies no execution state',
    () {
      final original = Task(
        name: 'Read',
        type: TaskType.focus,
        minimumFocusMinutes: 45,
        focusTarget: 'Finish Chapter 7',
        accumulatedFocusMilliseconds: 9 * 60000,
      );
      final step = RoutineStep.fromTask(original, id: 'read');
      final book = RoutineBook([
        Routine(id: 'study', name: 'Study', steps: [step]),
      ]);
      final added = service.apply(book, draft(date)).added.single;
      expect(added.type, TaskType.focus);
      expect(added.minimumFocusMinutes, 45);
      expect(added.focusTarget, 'Finish Chapter 7');
      expect(added.accumulatedFocusMilliseconds, 0);
      expect(added.isFocusRunning, isFalse);
      expect(identical(original, added), isFalse);
      added.name = 'One-day rename';
      expect(step.name, 'Read');
    },
  );

  test('A task already linked to the routine is never duplicated', () {
    final routine = cycle();
    final plan = draft(date, [routine.nextStep.toTask(routineId: routine.id)]);
    expect(service.apply(RoutineBook([routine]), plan).changed, isFalse);
  });

  test('Independent routines are each added on their own date', () {
    final book = RoutineBook([
      cycle(),
      cycle(id: 'second', schedule: RoutineSchedule.onWeekdays({4})),
    ]);
    expect(service.apply(book, draft(date)).added, hasLength(1));
    expect(service.apply(book, draft(day(1))).added, hasLength(2));
  });

  test('Editing/reordering preserves next-step identity and dated choices', () {
    final routine = cycle().add(date);
    final edit = routine.edit(
      name: 'Renamed',
      steps: routine.steps.reversed.toList(),
      schedule: RoutineSchedule.onWeekdays({2}),
    );
    expect(edit.nextStep.name, 'Pull');
    expect(edit.revision, 1);
    expect(edit.decisions, routine.decisions);
    expect(edit.schedule.label, 'Tue');
    final removed = edit.edit(
      name: edit.name,
      steps: edit.steps.where((step) => step.name != 'Pull').toList(),
    );
    expect(removed.nextStepIndex, 0);
    expect(removed.nextStep.name, 'Conditioning');
    expect(removed.schedule.label, 'Tue', reason: 'kept when not changed');
  });

  test('Old decisions are pruned so saved data stays small', () {
    var routine = cycle();
    for (var i = 0; i < 90; i++) {
      routine = routine.add(day(i));
    }
    expect(
      routine.decisions.length,
      lessThanOrEqualTo(Routine.decisionRetentionDays + 1),
    );
  });

  test('Routines saved before schedules load as daily with old choices', () {
    final legacy = {
      'id': 'old',
      'name': 'Old',
      'steps': [
        {'id': 'a', 'name': 'A', 'type': 'goal'},
      ],
      'nextStepIndex': 0,
      'revision': 3,
      'decisions': {
        '2026-10-13': {'action': 'accept', 'stepId': 'a'},
        '2026-10-14': {'action': 'skip', 'stepId': 'a'},
        '2026-10-15': {'action': 'dismiss', 'stepId': 'a'},
      },
    };
    final routine = Routine.fromJson(legacy);
    expect(routine.schedule.isDaily, isTrue);
    expect(routine.decisions.values.map((d) => d.action), [
      RoutineAction.added,
      RoutineAction.removed,
      RoutineAction.removed,
    ]);
    // A date the old flow already handled is not filled in again.
    final book = RoutineBook([routine]);
    expect(service.apply(book, draft(date)).changed, isFalse);
    expect(service.apply(book, draft(DateTime(2026, 10, 16))).changed, isTrue);
  });

  test(
    'Definitions, progress and choices round trip with immutable collections',
    () {
      final book = RoutineBook([
        cycle(schedule: RoutineSchedule.everyDays(3, from: date)).add(date),
      ]);
      final restored = RoutineBook.fromJson(book.toJson());
      expect(restored.toJson(), book.toJson());
      expect(() => restored.routines.clear(), throwsUnsupportedError);
      expect(
        () => restored.routines.single.steps.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => restored.routines.single.decisions.clear(),
        throwsUnsupportedError,
      );
    },
  );

  test('Reject empty definitions, invalid durations, duplicate identities and bad cursor', () {
    expect(
      () => RoutineStep(
        id: 'focus',
        name: 'Focus',
        type: TaskType.focus,
        minimumFocusMinutes: 0,
      ),
      throwsFormatException,
    );
    expect(
      () => RoutineStep(id: 'goal', name: ' ', type: TaskType.goal),
      throwsFormatException,
    );
    expect(
      () => Routine(id: 'r', name: 'Empty', steps: []),
      throwsFormatException,
    );
    expect(
      () => Routine(
        id: 'r',
        name: 'Bad cursor',
        steps: cycle().steps,
        nextStepIndex: 4,
      ),
      throwsFormatException,
    );
    expect(
      () => Routine(
        id: 'r',
        name: 'Duplicates',
        steps: [cycle().steps.first, cycle().steps.first],
      ),
      throwsFormatException,
    );
    expect(() => RoutineBook([cycle(), cycle()]), throwsFormatException);
    expect(
      () => Routine(
        id: 'r',
        name: 'Bad decision',
        steps: cycle().steps,
        decisions: {
          '2026-02-30': const RoutineDecision(
            action: RoutineAction.added,
            stepId: 'Push',
          ),
        },
      ),
      throwsFormatException,
    );
  });

  test('Rollover keeps progress and the next draft gets the next step', () {
    final book = RoutineBook([cycle().add(date)]);
    final state = DaylockState(
      todayPlan: DailyPlan(date: DateTime(2026, 10, 13), tasks: []),
      tomorrowPlan: DailyPlan(
        date: date,
        tasks: [cycle().nextStep.toTask(routineId: 'workout')],
      ),
      routines: book,
    );
    for (final next in [
      DateTime(2026, 10, 14),
      DateTime(2026, 11, 10),
      DateTime(2027),
    ]) {
      final rolled = state.rollOver(next);
      expect(rolled.routines, same(book));
      expect(
        service.apply(rolled.routines, rolled.tomorrowPlan).added.single.name,
        'Pull',
      );
    }
  });
}

import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/routine.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/services/routine_service.dart';
import 'package:flutter_test/flutter_test.dart';

final date = DateTime(2026, 10, 14);
const service = RoutineService();
Routine cycle({String id = 'workout'}) => Routine(
  id: id,
  name: 'Training',
  steps: [
    for (final name in ['Push', 'Pull', 'Legs', 'Conditioning'])
      RoutineStep(id: name, name: name, type: TaskType.goal),
  ],
);

void main() {
  test(
    'Accept advances the ordered cycle and wraps, never adds automatically',
    () {
      var book = RoutineBook([cycle()]);
      for (var offset = 0; offset < 5; offset++) {
        final day = DateTime(date.year, date.month, date.day + offset);
        final suggestion = service.suggestions(book, day).single;
        expect(
          suggestion.step.name,
          ['Push', 'Pull', 'Legs', 'Conditioning'][offset % 4],
        );
        final result = service.resolve(
          book,
          suggestion,
          RoutineAction.accept,
          day,
        );
        expect(result.changed, isTrue);
        expect(result.task!.name, suggestion.step.name);
        expect(result.task!.outcome, TaskOutcome.incomplete);
        expect(service.suggestions(result.book, day), isEmpty);
        expect(book.routines.single.decisions, hasLength(offset));
        book = result.book;
      }
      expect(book.routines.single.nextStep.name, 'Pull');
    },
  );

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
      final accepted = service
          .resolve(
            book,
            service.suggestions(book, date).single,
            RoutineAction.accept,
            date,
          )
          .task!;
      expect(accepted.type, TaskType.focus);
      expect(accepted.minimumFocusMinutes, 45);
      expect(accepted.focusTarget, 'Finish Chapter 7');
      expect(accepted.accumulatedFocusMilliseconds, 0);
      expect(accepted.isFocusRunning, isFalse);
      expect(accepted.isCompleted, isFalse);
      expect(identical(original, accepted), isFalse);
      accepted.name = 'Changed accepted task';
      expect(step.name, 'Read');
    },
  );

  test('Skip advances one step without creating any commitment', () {
    final book = RoutineBook([cycle()]);
    final result = service.resolve(
      book,
      service.suggestions(book, date).single,
      RoutineAction.skip,
      date,
    );
    expect(result.changed, isTrue);
    expect(result.task, isNull);
    expect(result.book.routines.single.nextStep.name, 'Pull');
    expect(
      result.book.routines.single.decisions[routineDateKey(date)]!.action,
      RoutineAction.skip,
    );
    expect(service.suggestions(result.book, date), isEmpty);
  });

  test(
    'Dismiss hides this planning date and offers the same step on the next',
    () {
      final book = RoutineBook([cycle()]);
      final result = service.resolve(
        book,
        service.suggestions(book, date).single,
        RoutineAction.dismiss,
        date,
      );
      expect(result.changed, isTrue);
      expect(result.task, isNull);
      expect(result.book.routines.single.nextStep.name, 'Push');
      expect(service.suggestions(result.book, date), isEmpty);
      expect(
        service
            .suggestions(result.book, DateTime(2026, 10, 15))
            .single
            .step
            .name,
        'Push',
      );
    },
  );

  test('Unanswered suggestions and missed dates never advance a cycle', () {
    final book = RoutineBook([cycle()]);
    for (final offset in [0, 1, 20, 365]) {
      expect(
        service
            .suggestions(book, DateTime(2026, 10, 14 + offset))
            .single
            .step
            .name,
        'Push',
      );
    }
    expect(book.routines.single.decisions, isEmpty);
    expect(book.routines.single.nextStepIndex, 0);
  });

  for (final action in RoutineAction.values) {
    test(
      'Repeated ${action.name} and accept cannot duplicate or advance twice',
      () {
        final book = RoutineBook([cycle()]);
        final suggestion = service.suggestions(book, date).single;
        final first = service.resolve(book, suggestion, action, date);
        final restored = RoutineBook.fromJson(first.book.toJson());
        for (final repeated in RoutineAction.values) {
          final result = service.resolve(restored, suggestion, repeated, date);
          expect(result.changed, isFalse);
          expect(result.task, isNull);
          expect(result.book, same(restored));
        }
        expect(restored.routines.single.decisions, hasLength(1));
      },
    );
  }

  test(
    'Old date, edited definition and deleted routine reject stale actions',
    () {
      final book = RoutineBook([cycle()]);
      final suggestion = service.suggestions(book, date).single;
      final edited = book.upsert(
        book.routines.single.edit(
          name: 'Updated',
          steps: book.routines.single.steps,
        ),
      );
      for (final pair in [
        (book, DateTime(2026, 10, 15)),
        (edited, date),
        (book.remove('workout'), date),
      ]) {
        final result = service.resolve(
          pair.$1,
          suggestion,
          RoutineAction.accept,
          pair.$2,
        );
        expect(result.changed, isFalse);
        expect(result.task, isNull);
      }
    },
  );

  test('Independent routines can each be accepted once on a date', () {
    final book = RoutineBook([cycle(), cycle(id: 'second')]);
    final choices = service.suggestions(book, date);
    final first = service.resolve(
      book,
      choices.first,
      RoutineAction.accept,
      date,
    );
    final second = service.resolve(
      first.book,
      choices.last,
      RoutineAction.skip,
      date,
    );
    expect(first.task, isNotNull);
    expect(second.task, isNull);
    expect(service.suggestions(second.book, date), isEmpty);
    expect(second.book.routines.map((routine) => routine.nextStepIndex), [
      1,
      1,
    ]);
  });

  test('Editing/reordering preserves next-step identity and dated choices', () {
    final routine = cycle().decide(date, RoutineAction.accept);
    final edit = routine.edit(
      name: 'Renamed',
      steps: routine.steps.reversed.toList(),
    );
    expect(edit.nextStep.name, 'Pull');
    expect(edit.revision, 1);
    expect(edit.decisions, routine.decisions);
    final removed = edit.edit(
      name: edit.name,
      steps: edit.steps.where((step) => step.name != 'Pull').toList(),
    );
    expect(removed.nextStepIndex, 0);
    expect(removed.nextStep.name, 'Conditioning');
  });

  test(
    'Definitions, progress and choices round trip with immutable collections',
    () {
      final book = RoutineBook([cycle().decide(date, RoutineAction.skip)]);
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
      expect(
        () => service.suggestions(restored, DateTime(2026, 10, 15)).clear(),
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
      () => RoutineStep(id: 'focus', name: 'Focus', type: TaskType.focus),
      throwsFormatException,
    );
    expect(
      () => RoutineStep(id: 'goal', name: ' ', type: TaskType.goal),
      throwsFormatException,
    );
    expect(
      () => RoutineStep(
        id: 'goal',
        name: 'Goal',
        type: TaskType.goal,
        minimumFocusMinutes: 1,
      ),
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
            action: RoutineAction.accept,
            stepId: 'Push',
          ),
        },
      ),
      throwsFormatException,
    );
  });

  test('Rollover and multiple missed days preserve progress without inventing decisions', () {
    final book = RoutineBook([cycle().decide(date, RoutineAction.accept)]);
    final state = DaylockState(
      todayPlan: DailyPlan(date: DateTime(2026, 10, 13), tasks: []),
      tomorrowPlan: DailyPlan(date: date, tasks: [cycle().nextStep.toTask()]),
      routines: book,
    );
    for (final next in [
      DateTime(2026, 10, 14),
      DateTime(2026, 11, 10),
      DateTime(2027),
    ]) {
      final rolled = state.rollOver(next);
      expect(rolled.routines, same(book));
      expect(rolled.routines.routines.single.decisions, hasLength(1));
      expect(
        service
            .suggestions(rolled.routines, rolled.tomorrowPlan.date)
            .single
            .step
            .name,
        'Pull',
      );
    }
  });
}

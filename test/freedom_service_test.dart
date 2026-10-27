import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/freedom_settings.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/services/freedom_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

final date = DateTime(2026, 10, 13);
const enabled = FreedomSettings(enabled: true);

Task goal({bool complete = true}) =>
    Task(name: 'Goal', type: TaskType.goal, isCompleted: complete);
Task excused() => Task(
  name: 'Unavailable',
  type: TaskType.goal,
  outcome: TaskOutcome.excused,
  excuseReason: 'Buyer did not arrive',
);
FreedomEligibility evaluate({
  DateTime? now,
  FreedomSettings settings = enabled,
  List<Task>? tasks,
  bool committed = true,
  DateTime? todayDate,
  DateTime? tomorrowDate,
}) => const FreedomService().evaluate(
  now: now ?? DateTime(2026, 10, 13, 18),
  settings: settings,
  todayPlan: DailyPlan(date: todayDate ?? date, tasks: tasks ?? [goal()]),
  tomorrowPlan: DailyPlan(
    date: tomorrowDate ?? DateTime(2026, 10, 14),
    tasks: [],
    isCommitted: committed,
  ),
);

void main() {
  test('Settings default to opt-in control with 18:00 and round trip', () {
    const defaults = FreedomSettings();
    expect(defaults.enabled, isFalse);
    expect(defaults.timeLabel, '18:00');
    final changed = defaults.copyWith(enabled: true, hour: 21, minute: 5);
    expect(
      FreedomSettings.fromJson(changed.toJson()).toJson(),
      changed.toJson(),
    );
    expect(changed.timeLabel, '21:05');
    expect(defaults.toJson(), {'enabled': false, 'hour': 18, 'minute': 0});
  });

  for (final value in [
    const FreedomSettings(hour: -1),
    const FreedomSettings(hour: 24),
    const FreedomSettings(minute: -1),
    const FreedomSettings(minute: 60),
  ]) {
    test('Invalid time ${value.hour}:${value.minute} is rejected', () {
      expect(value.toJson, throwsFormatException);
      expect(
        () => FreedomSettings.fromJson({
          'enabled': true,
          'hour': value.hour,
          'minute': value.minute,
        }),
        throwsFormatException,
      );
    });
  }

  test('Time boundary is inclusive and compares local clock minutes', () {
    expect(
      evaluate(now: DateTime(2026, 10, 13, 17, 59, 59, 999)).earned,
      isFalse,
    );
    expect(evaluate(now: DateTime(2026, 10, 13, 18)).earned, isTrue);
    expect(evaluate(now: DateTime(2026, 10, 13, 23, 59)).earned, isTrue);
    expect(
      evaluate(
        now: date,
        settings: const FreedomSettings(enabled: true, hour: 0),
      ).earned,
      isTrue,
    );
    expect(
      evaluate(
        now: DateTime(2026, 10, 13, 18, 29),
        settings: const FreedomSettings(enabled: true, minute: 30),
      ).earned,
      isFalse,
    );
    expect(
      evaluate(
        now: DateTime(2026, 10, 13, 18, 30),
        settings: const FreedomSettings(enabled: true, minute: 30),
      ).earned,
      isTrue,
    );
  });

  test('Disabled control never earns even if all conditions are satisfied', () {
    final status = evaluate(settings: const FreedomSettings());
    expect(status.conditionsSatisfied, isTrue);
    expect(status.earned, isFalse);
  });

  test(
    'Incomplete Today and uncommitted tomorrow independently prevent earning',
    () {
      expect(
        evaluate(tasks: [goal(complete: false)]).commitmentsCompleted,
        isFalse,
      );
      expect(evaluate(tasks: [goal(complete: false)]).earned, isFalse);
      expect(evaluate(committed: false).tomorrowCommitted, isFalse);
      expect(evaluate(committed: false).earned, isFalse);
      expect(evaluate().earned, isTrue);
    },
  );

  test('Excuses are excluded without being counted as completed', () {
    final satisfied = evaluate(tasks: [goal(), goal(), goal(), excused()]);
    expect(satisfied.completedCount, 3);
    expect(satisfied.eligibleCount, 3);
    expect(satisfied.earned, isTrue);
    final pending = evaluate(
      tasks: [goal(), goal(), goal(complete: false), excused()],
    );
    expect(pending.completedCount, 2);
    expect(pending.eligibleCount, 3);
    expect(pending.earned, isFalse);
  });

  for (final tasks in [
    <Task>[],
    [excused(), excused()],
  ]) {
    test(
      '${tasks.isEmpty ? "Empty" : "All-excused"} day is explicitly ineligible',
      () {
        final status = evaluate(tasks: tasks);
        expect(status.eligibleCount, 0);
        expect(status.hasEligibleCommitments, isFalse);
        expect(status.commitmentsCompleted, isFalse);
        expect(status.conditionsSatisfied, isFalse);
        expect(status.earned, isFalse);
      },
    );
  }

  test('Manual completion earns Freedom independently of elapsed time; excuse remains ineligible', () {
    final focus = Task(
      name: 'Read',
      type: TaskType.focus,
      minimumFocusMinutes: 30,
    );
    expect(evaluate(tasks: [focus]).earned, isFalse);
    focus.accumulatedFocusMilliseconds = 30 * 60000;
    expect(evaluate(tasks: [focus]).earned, isFalse);
    focus.isCompleted = true;
    expect(evaluate(tasks: [focus]).earned, isTrue);
    focus.changeOutcome(
      TaskOutcome.excused,
      now: date,
      reason: 'Book unavailable',
    );
    expect(focus.accumulatedFocusMilliseconds, 30 * 60000);
    expect(evaluate(tasks: [focus]).earned, isFalse);
  });

  test('Only correctly dated Today and next-day committed plan qualify', () {
    expect(evaluate(todayDate: DateTime(2026, 10, 12)).earned, isFalse);
    expect(evaluate(todayDate: DateTime(2026, 10, 14)).currentPlans, isFalse);
    expect(evaluate(tomorrowDate: DateTime(2026, 10, 15)).earned, isFalse);
    expect(
      const FreedomService()
          .evaluate(
            now: DateTime(2026, 10, 13, 19),
            settings: enabled,
            todayPlan: DailyPlan(date: date, tasks: [goal()]),
          )
          .earned,
      isFalse,
    );
  });

  test('Reevaluation uses changed local timezone and civil dates', () {
    tzdata.initializeTimeZones();
    final instant = DateTime.utc(2026, 10, 13, 15);
    final doha = tz.TZDateTime.from(instant, tz.getLocation('Asia/Qatar'));
    final london = tz.TZDateTime.from(instant, tz.getLocation('Europe/London'));
    expect(evaluate(now: doha).earned, isTrue);
    expect(evaluate(now: london).timeReached, isFalse);
    final auckland = tz.TZDateTime.from(
      instant,
      tz.getLocation('Pacific/Auckland'),
    );
    expect(evaluate(now: auckland).currentPlans, isFalse);
    // UTC input is interpreted using the device zone rather than UTC wall time.
    expect(
      evaluate(now: instant).earned,
      evaluate(now: instant.toLocal()).earned,
    );
  });

  test('Rollover invalidates previously earned status and preserves configured time', () {
    final state = DaylockState(
      todayPlan: DailyPlan(date: date, tasks: [goal()]),
      tomorrowPlan: DailyPlan(
        date: DateTime(2026, 10, 14),
        tasks: [goal()],
        isCommitted: true,
      ),
      freedomSettings: enabled,
    );
    final rolled = state.rollOver(DateTime(2026, 10, 14, 18));
    final status = const FreedomService().evaluate(
      now: DateTime(2026, 10, 14, 18),
      settings: rolled.freedomSettings,
      todayPlan: rolled.todayPlan,
      tomorrowPlan: rolled.tomorrowPlan,
    );
    expect(status.currentPlans, isTrue);
    expect(status.commitmentsCompleted, isTrue);
    expect(status.tomorrowCommitted, isFalse);
    expect(status.earned, isFalse);
    expect(rolled.freedomSettings, same(enabled));
  });
}

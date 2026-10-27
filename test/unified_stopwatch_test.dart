import 'dart:convert';

import 'package:daylock/models/area.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/stopwatch_stamp.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/services/commitment_stopwatches.dart';
import 'package:daylock/services/journey_service.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:daylock/services/stopwatch_clock.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class FakeStopwatchClock extends StopwatchClock {
  DateTime wall = DateTime(2026, 10, 27, 12);
  int elapsed = 10000000;
  String boot = 'boot-1';
  FakeStopwatchClock() : super(android: false);
  @override
  StopwatchStamp get current => StopwatchStamp(wall.toUtc(), elapsed, boot);
  void advance(Duration duration, {bool wallToo = true}) {
    elapsed += duration.inMilliseconds;
    if (wallToo) wall = wall.add(duration);
  }
}

DaylockState stateAt(FakeStopwatchClock clock, List<Task> tasks) =>
    DaylockState(
      todayPlan: DailyPlan(date: clock.wall, tasks: tasks, isCommitted: true),
      tomorrowPlan: DailyPlan(
        date: DateTime(clock.wall.year, clock.wall.month, clock.wall.day + 1),
        tasks: [],
      ),
    );
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );
  for (final type in TaskType.values) {
    test('$type start pause resume tracks actual uncapped milliseconds', () {
      final clock = FakeStopwatchClock();
      final task = Task(name: 'Read', type: type);
      final state = stateAt(clock, [task]);
      final timers = CommitmentStopwatches(clock);
      timers.toggle(state, task);
      clock.advance(const Duration(milliseconds: 23001));
      timers.toggle(state, task);
      clock.advance(const Duration(hours: 2));
      expect(task.focusMillisecondsAt(clock.wall), 23001);
      timers.toggle(state, task);
      clock.advance(const Duration(hours: 3, milliseconds: 999));
      timers.toggle(state, task);
      expect(task.accumulatedFocusMilliseconds, 10824000);
      expect(task.isCompleted, isFalse);
    });
    for (final outcome in [TaskOutcome.completed, TaskOutcome.excused]) {
      test('$type $outcome stops running time and retains it on reset', () {
        final clock = FakeStopwatchClock();
        final task = Task(name: 'Read', type: type);
        final state = stateAt(clock, [task]);
        CommitmentStopwatches(clock).toggle(state, task);
        clock.advance(const Duration(seconds: 7));
        task.changeOutcome(outcome, now: clock.wall, reason: 'Ill');
        clock.advance(const Duration(hours: 2));
        task.startFocus(clock.wall);
        expect(task.isFocusRunning, isFalse);
        expect(task.focusMillisecondsAt(clock.wall), 7000);
        task.changeOutcome(TaskOutcome.incomplete, now: clock.wall);
        expect(task.accumulatedFocusMilliseconds, 7000);
        expect(task.isFocusRunning, isFalse);
      });
    }
    test('$type completing without stopwatch records zero', () {
      final task = Task(name: 'Read', type: type)..isCompleted = true;
      expect(task.accumulatedFocusMilliseconds, 0);
      expect(Task.fromJson(task.toJson()).isCompleted, isTrue);
    });
  }
  test('Rapid switches partition elapsed time and survive serialization', () {
    final clock = FakeStopwatchClock();
    var state = stateAt(clock, [Task(name: 'A'), Task(name: 'B')]);
    final timers = CommitmentStopwatches(clock);
    for (var i = 0; i < 100; i++) {
      timers.toggle(state, state.todayPlan.tasks[i % 2]);
      clock.advance(const Duration(milliseconds: 37));
      state = DaylockState.fromJson(state.toJson());
      timers.reconcile(state, recovering: true);
      expect(
        state.todayPlan.tasks.where((t) => t.isFocusRunning),
        hasLength(1),
      );
    }
    timers.toggle(state, state.todayPlan.tasks.last);
    expect(
      state.todayPlan.tasks.fold<int>(
        0,
        (sum, t) => sum + t.accumulatedFocusMilliseconds,
      ),
      3700,
    );
  });
  for (final wallShift in [
    const Duration(hours: -4),
    const Duration(hours: 4),
  ]) {
    test('Same boot process restoration ignores wall shift $wallShift', () {
      final clock = FakeStopwatchClock();
      var state = stateAt(clock, [Task(name: 'A')]);
      final timers = CommitmentStopwatches(clock);
      timers.toggle(state, state.todayPlan.tasks.single);
      clock.advance(const Duration(seconds: 11));
      timers.checkpoint(state);
      state = DaylockState.fromJson(state.toJson());
      clock.advance(const Duration(minutes: 23));
      clock.wall = clock.wall.add(wallShift);
      timers.reconcile(state, recovering: true);
      final task = state.todayPlan.tasks.single;
      expect(task.focusMillisecondsAt(clock.wall), 1391000);
      timers.toggle(state, task);
      timers.reconcile(state, recovering: true);
      expect(task.accumulatedFocusMilliseconds, 1391000);
    });
  }
  for (final invalid in [
    'reboot',
    'future-monotonic',
    'malformed',
    'missing',
  ]) {
    test('$invalid pauses uncertain segment and keeps checkpoint', () {
      final clock = FakeStopwatchClock();
      var state = stateAt(clock, [Task(name: 'A')]);
      final timers = CommitmentStopwatches(clock);
      timers.toggle(state, state.todayPlan.tasks.single);
      clock.advance(const Duration(seconds: 10));
      timers.checkpoint(state);
      final json = state.toJson();
      final taskJson = (json['todayPlan'] as Map)['tasks'][0] as Map;
      if (invalid == 'reboot') clock.boot = 'boot-2';
      if (invalid == 'future-monotonic') clock.elapsed = 1;
      if (invalid == 'malformed') taskJson['stopwatchAnchor'] = {'elapsed': -1};
      if (invalid == 'missing') taskJson.remove('stopwatchAnchor');
      state = DaylockState.fromJson(json);
      timers.reconcile(state, recovering: true);
      expect(state.todayPlan.tasks.single.isFocusRunning, isFalse);
      expect(state.todayPlan.tasks.single.accumulatedFocusMilliseconds, 10000);
    });
  }
  test('Legacy wall-only recovery is bounded, preserves IDs, and credits only one timer', () {
    final clock = FakeStopwatchClock();
    final old = {
      'id': 'existing',
      'name': 'Legacy',
      'type': 'focus',
      'isCompleted': false,
      'minimumFocusMinutes': 1,
      'accumulatedFocusMilliseconds': 7000,
      'focusStartedAt': clock.wall
          .subtract(const Duration(minutes: 3))
          .toUtc()
          .toIso8601String(),
    };
    final state = stateAt(clock, [
      Task.fromJson(old),
      Task.fromJson({...old, 'id': 'second'}),
    ]);
    final timers = CommitmentStopwatches(clock);
    timers.reconcile(state, recovering: true);
    expect(state.todayPlan.tasks.first.id, 'existing');
    expect(state.todayPlan.tasks.first.accumulatedFocusMilliseconds, 187000);
    expect(state.todayPlan.tasks.first.isCompleted, isFalse);
    expect(state.todayPlan.tasks.last.accumulatedFocusMilliseconds, 7000);
    expect(state.todayPlan.tasks.last.isFocusRunning, isFalse);
    timers.reconcile(state, recovering: true);
    expect(state.todayPlan.tasks.first.accumulatedFocusMilliseconds, 187000);
  });
  for (final offset in [const Duration(hours: 1), const Duration(hours: -25)]) {
    test('Invalid legacy start $offset cannot fabricate time', () {
      final clock = FakeStopwatchClock();
      final task = Task.fromJson({
        'name': 'Old',
        'type': 'focus',
        'isCompleted': false,
        'focusStartedAt': clock.wall.add(offset).toIso8601String(),
        'accumulatedFocusMilliseconds': 9000,
      });
      CommitmentStopwatches(clock)
          .reconcile(stateAt(clock, [task]), recovering: true);
      expect(task.isFocusRunning, isFalse);
      expect(task.accumulatedFocusMilliseconds, 9000);
    });
  }
  test('Tomorrow anchors are discarded and stale tasks cannot be started', () {
    final clock = FakeStopwatchClock();
    final state = stateAt(clock, [Task(name: 'A')]);
    final future = Task(name: 'Tomorrow', accumulatedFocusMilliseconds: 500)
      ..startFocus(clock.wall);
    state.tomorrowPlan.tasks.add(future);
    final timers = CommitmentStopwatches(clock);
    timers.toggle(state, future);
    expect(future.isFocusRunning, isFalse);
    expect(future.accumulatedFocusMilliseconds, 500);
    expect(state.todayPlan.tasks.single.isFocusRunning, isFalse);
  });
  test('Midnight caps elapsed time; backwards wall jump cannot invent old-day hours', () {
    final clock = FakeStopwatchClock()..wall = DateTime(2026, 10, 27, 23, 59);
    final state = stateAt(clock, [Task(name: 'A')]);
    CommitmentStopwatches(clock).toggle(state, state.todayPlan.tasks.single);
    clock.advance(const Duration(minutes: 5));
    final rolled = state.rollOver(clock.wall);
    expect(
      rolled.history.plans.single.tasks.single.accumulatedFocusMilliseconds,
      60000,
    );
    expect(rolled.history.plans.single.tasks.single.isCompleted, isFalse);
    clock.wall = clock.wall.add(const Duration(days: 1));
    expect(
      state.todayPlan.tasks.single.millisecondsAtBoundary(
        DateTime(2026, 10, 28),
      ),
      0,
    );
  });
  test('Journey includes Goal, legacy Focus, incomplete and excused actual effort once', () {
    final clock = FakeStopwatchClock();
    final state = stateAt(clock, [
      Task(name: 'Goal', accumulatedFocusMilliseconds: 10000),
      Task(
        name: 'Focus',
        type: TaskType.focus,
        accumulatedFocusMilliseconds: 20000,
        isCompleted: true,
      ),
      Task(
        name: 'Excused',
        outcome: TaskOutcome.excused,
        excuseReason: 'Ill',
        accumulatedFocusMilliseconds: 30000,
      ),
    ]);
    CommitmentStopwatches(clock).toggle(state, state.todayPlan.tasks.first);
    clock.advance(const Duration(seconds: 5));
    final data = JourneyData(
      areas: state.areas,
      history: state.history,
      todayPlan: state.todayPlan,
      now: clock.wall,
    );
    expect(data.forArea(Area.defaultId).focusMilliseconds, 65000);
    expect(data.forArea(Area.defaultId).completedCount, 1);
    expect(state.todayPlan.tasks.first.accumulatedFocusMilliseconds, 10000);
    final archived = state.history.archive(state.todayPlan);
    final again = JourneyData(
      areas: state.areas,
      history: archived,
      todayPlan: state.todayPlan,
      now: clock.wall,
    );
    expect(again.records, hasLength(3));
    expect(again.forArea(Area.defaultId).focusMilliseconds, 65000);
  });
  test('Migration backs up exact JSON once and preserves historical records and IDs', () async {
    final clock = FakeStopwatchClock();
    final original = stateAt(clock, [
      Task(name: 'Goal'),
      Task(
        name: 'Focus',
        type: TaskType.focus,
        isCompleted: true,
        accumulatedFocusMilliseconds: 12000,
      ),
    ]);
    final raw = original.toJson();
    raw['history'] = original.history.archive(original.todayPlan).toJson();
    for (final task in (raw['todayPlan'] as Map)['tasks'] as List) {
      (task as Map).remove('id');
      task.remove('stopwatchVersion');
    }
    final json = jsonEncode(raw);
    final preferences = SharedPreferencesAsync();
    await preferences.setString(LocalStorage.stateKey, json);
    final storage = LocalStorage();
    final migrated = (await storage.load())!;
    expect(await preferences.getString(LocalStorage.beforeStopwatchKey), json);
    expect(migrated.todayPlan.tasks.first.id, 'legacy-2026-10-27-0');
    expect(migrated.todayPlan.tasks.last.accumulatedFocusMilliseconds, 12000);
    expect(migrated.todayPlan.tasks.last.isCompleted, isTrue);
    expect(migrated.history.toJson(), raw['history']);
    final again = (await storage.load())!;
    expect(again.toJson(), migrated.toJson());
    expect(await preferences.getString(LocalStorage.beforeStopwatchKey), json);
  });
  test('Android clock samples boot-scoped monotonic time and tolerates unavailable bridge', () async {
    const channel = MethodChannel('test/stopwatch');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => {'elapsedMs': 999000, 'bootCount': 4},
    );
    final clock = StopwatchClock(android: true, channel: channel);
    await clock.synchronize();
    expect(clock.current.session, 'android-boot-4');
    expect(clock.current.elapsedMilliseconds, greaterThanOrEqualTo(999000));
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(code: 'unavailable'),
    );
    await clock.synchronize();
    expect(clock.current.session, 'android-boot-4');
    messenger.setMockMethodCallHandler(channel, null);
  });
  test(
    'A bridge unavailable at startup cannot change clock sessions mid-timer',
    () async {
      const channel = MethodChannel('test/unavailable-stopwatch');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => throw PlatformException(code: 'unavailable'),
      );
      final clock = StopwatchClock(android: true, channel: channel);
      await clock.synchronize();
      final session = clock.current.session;
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => {'elapsedMs': 999000, 'bootCount': 4},
      );
      await clock.synchronize();
      expect(clock.current.session, session);
      messenger.setMockMethodCallHandler(channel, null);
    },
  );
}

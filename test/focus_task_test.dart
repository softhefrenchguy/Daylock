import 'dart:convert';

import 'package:daylock/models/task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Focus uses timestamps and preserves fractions across pauses', () {
    final task = Task(
      name: 'Read',
      type: TaskType.focus,
      minimumFocusMinutes: 1,
    );
    final start = DateTime.utc(2026, 10, 7, 12);
    task.startFocus(start);
    expect(
      task.focusMillisecondsAt(start.add(const Duration(milliseconds: 23500))),
      23500,
    );
    task.pauseFocus(start.add(const Duration(milliseconds: 23500)));
    expect(
      task.focusMillisecondsAt(start.add(const Duration(hours: 5))),
      23500,
    );
    task.startFocus(start.add(const Duration(hours: 5)));
    task.pauseFocus(start.add(const Duration(hours: 5, milliseconds: 500)));
    expect(task.accumulatedFocusMilliseconds, 24000);
    expect(task.isCompleted, isFalse);
  });

  test('Legacy minimum never completes or caps a stopwatch', () {
    final task = Task(
      name: 'Read',
      type: TaskType.focus,
      minimumFocusMinutes: 1,
    );
    final start = DateTime.utc(2026, 10, 7, 12);
    task.startFocus(start);
    final end = start.add(const Duration(hours: 2));
    expect(task.finishFocusIfDue(end), isFalse);
    expect(task.isCompleted, isFalse);
    task.changeOutcome(TaskOutcome.completed, now: end);
    expect(task.accumulatedFocusMilliseconds, 7200000);
    expect(task.isCompleted, isTrue);
    expect(task.isFocusRunning, isFalse);
    task.startFocus(end);
    expect(task.isFocusRunning, isFalse);
  });

  test(
    'JSON preserves a running start timestamp, progress, minimum, and target',
    () {
      final start = DateTime.utc(2026, 10, 7, 12);
      final task = Task(
        name: 'Read',
        type: TaskType.focus,
        minimumFocusMinutes: 60,
        focusTarget: '  Finish Chapter 7  ',
        accumulatedFocusMilliseconds: 23 * 60000,
      );
      task.startFocus(start);
      final restored = Task.fromJson(
        jsonDecode(jsonEncode(task.toJson())) as Map<String, dynamic>,
      );
      expect(restored.minimumFocusMinutes, 60);
      expect(restored.focusTarget, 'Finish Chapter 7');
      expect(restored.focusStartedAt, start);
      expect(restored.focusStartedAt!.isUtc, isTrue);
      expect(
        restored.focusMillisecondsAt(start.add(const Duration(minutes: 10))),
        33 * 60000,
      );
    },
  );

  test('Old Focus data gains a minimum and retains existing completion', () {
    for (final completed in [false, true]) {
      final task = Task.fromJson({
        'name': 'Legacy focus',
        'type': 'focus',
        'isCompleted': completed,
      });
      expect(task.minimumFocusMinutes, Task.legacyFocusMinutes);
      expect(task.isCompleted, completed);
      expect(task.accumulatedFocusMilliseconds, 0);
      expect(task.focusStartedAt, isNull);
    }
  });

  test('Manual completion survives with zero tracked time', () {
    final task = Task.fromJson({
      'name': 'Focus',
      'type': 'focus',
      'isCompleted': true,
      'minimumFocusMinutes': 1,
      'accumulatedFocusMilliseconds': 0,
    });
    expect(task.isCompleted, isTrue);
  });

  test('Invalid Focus durations are rejected by the model', () {
    for (final duration in [0, -1]) {
      expect(
        () => Task(
          name: 'Focus',
          type: TaskType.focus,
          minimumFocusMinutes: duration,
        ),
        throwsFormatException,
      );
    }
  });

  test('A backwards timestamp never subtracts accumulated time', () {
    final task = Task(
      name: 'Read',
      type: TaskType.focus,
      minimumFocusMinutes: 1,
      accumulatedFocusMilliseconds: 20000,
    );
    final start = DateTime.utc(2026, 10, 7, 12);
    task.startFocus(start);
    task.pauseFocus(start.subtract(const Duration(hours: 1)));
    expect(task.accumulatedFocusMilliseconds, 20000);
  });

  test(
    'Goals still support manual completion and do not start focus timers',
    () {
      final task = Task(name: 'Gym', type: TaskType.goal);
      task.isCompleted = true;
      task.startFocus(DateTime.now());
      expect(task.isCompleted, isTrue);
      expect(task.isFocusRunning, isFalse);
      expect(Task.fromJson(task.toJson()).isCompleted, isTrue);
    },
  );
}

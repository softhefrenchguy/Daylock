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

  test(
    'Only duration completes Focus, and completion stops at the minimum',
    () {
      final task = Task(
        name: 'Read',
        type: TaskType.focus,
        minimumFocusMinutes: 1,
        focusTarget: 'Finish Chapter 7',
      );
      final start = DateTime.utc(2026, 10, 7, 12);
      expect(() => task.isCompleted = true, throwsStateError);
      task.startFocus(start);
      expect(
        task.finishFocusIfDue(start.add(const Duration(seconds: 59))),
        isFalse,
      );
      expect(task.isCompleted, isFalse);
      expect(
        task.finishFocusIfDue(start.add(const Duration(hours: 2))),
        isTrue,
      );
      expect(task.accumulatedFocusMilliseconds, 60000);
      expect(task.isCompleted, isTrue);
      expect(task.isFocusRunning, isFalse);
      task.startFocus(start.add(const Duration(hours: 3)));
      expect(task.isFocusRunning, isFalse);
    },
  );

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
      expect(
        task.accumulatedFocusMilliseconds,
        completed ? Task.legacyFocusMinutes * 60000 : 0,
      );
      expect(task.focusStartedAt, isNull);
    }
  });

  test(
    'New Focus data cannot use a saved manual completion flag to bypass time',
    () {
      final task = Task.fromJson({
        'name': 'Focus',
        'type': 'focus',
        'isCompleted': true,
        'minimumFocusMinutes': 1,
        'accumulatedFocusMilliseconds': 0,
      });
      expect(task.isCompleted, isFalse);
    },
  );

  test('Invalid Focus durations are rejected by the model', () {
    for (final duration in [0, -1]) {
      expect(
        () => Task(
          name: 'Focus',
          type: TaskType.focus,
          minimumFocusMinutes: duration,
        ),
        throwsArgumentError,
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

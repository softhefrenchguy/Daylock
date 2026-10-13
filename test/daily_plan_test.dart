import 'dart:convert';

import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'A plan represents a calendar date without a time or UTC conversion',
    () {
      final plan = DailyPlan(
        date: DateTime.utc(2026, 10, 7, 23, 59),
        tasks: [],
      );
      expect(plan.date, DateTime(2026, 10, 7));
      expect(plan.date.hour, 0);
      expect(plan.isCommitted, isFalse);
      expect(plan.toJson()['date'], '2026-10-07');
    },
  );

  test('JSON preserves date, lock, task types, names, and completion', () {
    final plan = DailyPlan(
      date: DateTime(2028, 2, 29),
      tasks: [
        Task(name: 'Gym', type: TaskType.goal, isCompleted: true),
        Task(name: 'Study', type: TaskType.focus),
      ],
      isCommitted: true,
    );
    final restored = DailyPlan.fromJson(
      jsonDecode(jsonEncode(plan.toJson())) as Map<String, dynamic>,
    );
    expect(restored.toJson(), plan.toJson());
    expect(restored.date, DateTime(2028, 2, 29));
    expect(restored.tasks, isNot(same(plan.tasks)));
    expect(restored.tasks.first, isNot(same(plan.tasks.first)));
  });

  for (final invalidDate in [
    '2026-02-30',
    '2026-13-01',
    '2026-00-01',
    '2026-10-00',
    '2026-10-07T00:00:00Z',
    '2026-1-7',
    'not a date',
  ]) {
    test(
      'Rejects invalid calendar date $invalidDate instead of normalizing it',
      () {
        expect(
          () => DailyPlan.fromJson({
            'date': invalidDate,
            'tasks': [],
            'isCommitted': false,
          }),
          throwsFormatException,
        );
      },
    );
  }

  test('Unknown state versions are rejected', () {
    expect(() => DaylockState.fromJson({'version': 99}), throwsFormatException);
  });
}

import 'dart:math' as math;

import 'package:daylock/design/daylock_calendar.dart';
import 'package:daylock/design/daylock_palette.dart';
import 'package:daylock/design/daylock_theme.dart';
import 'package:daylock/models/calendar_activity.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/plan_history.dart';
import 'package:daylock/models/task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 10, 8, 10, 15);
Task _goal({bool complete = false}) =>
    Task(name: 'Goal', type: TaskType.goal, isCompleted: complete);

void main() {
  test('Five completion bands include exact zero and preserve boundary percentages', () {
    expect(commitmentIntensity(0, 0), HeatmapIntensity.neutral);
    expect(commitmentIntensity(0, 4), HeatmapIntensity.zero);
    expect(commitmentIntensity(1, 4), HeatmapIntensity.low);
    expect(commitmentIntensity(1, 3), HeatmapIntensity.medium);
    expect(commitmentIntensity(2, 4), HeatmapIntensity.medium);
    expect(commitmentIntensity(3, 4), HeatmapIntensity.high);
    expect(commitmentIntensity(99, 100), HeatmapIntensity.high);
    expect(commitmentIntensity(4, 4), HeatmapIntensity.complete);
    for (final counts in [(1, 0), (-1, 4), (1, -1), (5, 4)]) {
      expect(
        () => commitmentIntensity(counts.$1, counts.$2),
        throwsArgumentError,
      );
    }
  });

  test('Missing history and recorded empty days are neutral; recorded incomplete commitments are zero', () {
    final empty = DateTime(2026, 10, 5);
    final zero = DateTime(2026, 10, 6);
    final history = PlanHistory.empty
        .archive(DailyPlan(date: empty, tasks: []))
        .archive(DailyPlan(date: zero, tasks: [_goal()]));
    CalendarDayActivity activity(DateTime date) => CalendarDayActivity.forDate(
      date: date,
      currentTime: _now,
      history: history,
    );
    expect(activity(empty).isRecorded, isTrue);
    expect(activity(empty).completionPercentage, isNull);
    expect(activity(empty).intensity, HeatmapIntensity.neutral);
    expect(activity(DateTime(2026, 10, 4)).isRecorded, isFalse);
    expect(activity(DateTime(2026, 10, 4)).intensity, HeatmapIntensity.neutral);
    expect(activity(zero).completionPercentage, 0);
    expect(activity(zero).intensity, HeatmapIntensity.zero);
  });

  test('Past projection retains exact Focus and completion, and never mutates immutable history', () {
    final date = DateTime(2026, 10, 7);
    final history = PlanHistory.empty.archive(
      DailyPlan(
        date: date,
        isCommitted: true,
        tasks: [
          _goal(complete: true),
          Task(
            name: 'Study',
            type: TaskType.focus,
            minimumFocusMinutes: 60,
            focusTarget: 'Chapter 7',
            accumulatedFocusMilliseconds: 1380123,
          ),
        ],
      ),
    );
    final before = history.toJson();
    final activity = CalendarDayActivity.forDate(
      date: DateTime(2026, 10, 7, 23),
      currentTime: _now,
      history: history,
    );
    expect(activity.date, date);
    expect(activity.completedCount, 1);
    expect(activity.completionPercentage, 50);
    expect(activity.focusMilliseconds, 1380123);
    expect(activity.commitments.last.focusTarget, 'Chapter 7');
    expect(() => activity.commitments.clear(), throwsUnsupportedError);
    expect(history.toJson(), before);
  });

  test('Today uses a detached live snapshot; elapsed Focus is projected without pausing or completing live tasks', () {
    final focus = Task(
      name: 'Study',
      type: TaskType.focus,
      minimumFocusMinutes: 60,
      accumulatedFocusMilliseconds: 1000,
      focusStartedAt: DateTime(2026, 10, 8, 10),
    );
    final plan = DailyPlan(date: _now, tasks: [_goal(complete: true), focus]);
    final before = plan.toJson();
    final history = PlanHistory.empty.archive(DailyPlan(date: _now, tasks: []));
    final activity = CalendarDayActivity.forDate(
      date: _now,
      currentTime: _now,
      history: history,
      todayPlan: plan,
    );
    expect(activity.isToday, isTrue);
    expect(activity.isRecorded, isTrue);
    expect(activity.completionPercentage, 50);
    expect(activity.focusMilliseconds, 901000);
    expect(plan.toJson(), before);
    focus.name = 'Changed live name';
    expect(activity.commitments.last.name, 'Study');
  });

  test('Future dates stay neutral even with stored records and cannot display tomorrow as Today', () {
    final future = DateTime(2026, 10, 9);
    final plan = DailyPlan(date: future, tasks: [_goal(complete: true)]);
    final history = PlanHistory.empty.archive(plan);
    final activity = CalendarDayActivity.forDate(
      date: future,
      currentTime: _now,
      history: history,
      todayPlan: plan,
    );
    expect(activity.isFuture, isTrue);
    expect(activity.isRecorded, isFalse);
    expect(activity.intensity, HeatmapIntensity.neutral);
    expect(activity.commitments, isEmpty);
    final today = CalendarDayActivity.forDate(
      date: _now,
      currentTime: _now,
      history: history,
      todayPlan: plan,
    );
    expect(today.intensity, HeatmapIntensity.neutral);
    expect(today.commitments, isEmpty);
  });

  for (final colour in ColourTheme.values) {
    for (final brightness in Brightness.values) {
      test(
        '${colour.name} $brightness has six distinct tones with readable date text',
        () {
          final palette = DaylockHeatmapPalette(
            DaylockTheme.forPalette(colour, brightness).colorScheme,
          );
          expect(
            HeatmapIntensity.values.map(palette.background).toSet(),
            hasLength(6),
          );
          for (final intensity in HeatmapIntensity.values) {
            final background = palette.background(intensity).computeLuminance();
            final ink = palette.foreground(intensity).computeLuminance();
            final contrast =
                (math.max(background, ink) + .05) /
                (math.min(background, ink) + .05);
            expect(contrast, greaterThanOrEqualTo(4.5), reason: intensity.name);
          }
        },
      );
    }
  }
}

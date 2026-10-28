import 'navigation_helpers.dart';

import 'package:daylock/main.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/event.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/screens/calendar_screen.dart';
import 'package:daylock/screens/plan_screen.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'plan_test_helpers.dart';

import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final _today = DateTime(2026, 10, 8, 9);

Future<void> _navigate(WidgetTester tester, String page) =>
    navigateApp(tester, page);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _selectDay(WidgetTester tester, int day) async {
  await _tap(
    tester,
    find.byKey(
      ValueKey('calendar-day-2026-10-${day.toString().padLeft(2, '0')}'),
    ),
  );
}

Future<void> _enter(WidgetTester tester, String field, String text) async {
  final finder = find.byKey(ValueKey('event-$field'));
  await tester.ensureVisible(finder);
  await tester.enterText(finder, text);
  await tester.pump();
}

DaylockState _state({List<Event> events = const [], bool locked = false}) =>
    DaylockState(
      todayPlan: DailyPlan(
        date: _today,
        tasks: [Task(name: 'Gym', type: TaskType.goal)],
        isCommitted: true,
      ),
      tomorrowPlan: DailyPlan(
        date: DateTime(2026, 10, 9),
        tasks: [
          Task(name: 'Read', type: TaskType.focus, minimumFocusMinutes: 60),
        ],
        isCommitted: locked,
      ),
      events: events,
    );

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets(
    'Calendar creates, filters, edits, moves, restores, and confirms deletion of events',
    (tester) async {
      await tester.runAsync(
        () => LocalStorage().save(
          _state(
            events: [Event(id: 'other', title: 'Check-up', date: _today)],
          ),
        ),
      );
      await tester.pumpWidget(MainApp(now: () => _today));
      await tester.pumpAndSettle();
      await _navigate(tester, 'Calendar');
      expect(find.text('Check-up'), findsOneWidget);
      await _selectDay(tester, 9);
      expect(find.text('Check-up'), findsNothing);
      expect(find.text('No events scheduled.'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('calendar-add-event')));
      await _enter(tester, 'title', ' Driving lesson ');
      await _enter(tester, 'start', '14:00');
      await _enter(tester, 'end', '16:00');
      await _enter(tester, 'notes', ' Bring licence ');
      await _tap(tester, find.text('Save event'));
      expect(find.text('Driving lesson'), findsOneWidget);
      expect(find.text('14:00–16:00'), findsOneWidget);
      var saved = (await tester.runAsync<DaylockState?>(
        () => LocalStorage().load(),
      ))!;
      final lesson = saved.events.singleWhere(
        (event) => event.title == 'Driving lesson',
      );
      expect(lesson.date, DateTime(2026, 10, 9));
      expect(saved.todayPlan.tasks, hasLength(1));
      expect(saved.tomorrowPlan.tasks, hasLength(1));

      await _tap(tester, find.byTooltip('Edit Driving lesson'));
      await _enter(tester, 'title', 'Driving practice');
      await _enter(tester, 'start', '15:00');
      await _enter(tester, 'end', '17:00');
      await _enter(tester, 'notes', 'New location');
      await _tap(tester, find.byKey(const ValueKey('event-date')));
      await _tap(
        tester,
        find.descendant(
          of: find.byType(DatePickerDialog),
          matching: find.text('10'),
        ),
      );
      await _tap(tester, find.text('OK'));
      await _tap(tester, find.text('Save event'));
      expect(find.text('Driving lesson'), findsNothing);
      expect(find.text('Driving practice'), findsOneWidget);
      saved = (await tester.runAsync<DaylockState?>(
        () => LocalStorage().load(),
      ))!;
      expect(saved.events, hasLength(2));
      final updated = saved.events.singleWhere(
        (event) => event.id == lesson.id,
      );
      expect(updated.title, 'Driving practice');
      expect(updated.date, DateTime(2026, 10, 10));
      expect(updated.timeLabel, '15:00–17:00');
      expect(updated.notes, 'New location');
      await _selectDay(tester, 9);
      expect(find.text('Driving practice'), findsNothing);

      // Recreating MainApp reads persisted edits rather than retaining widget state.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(MainApp(now: () => _today));
      await tester.pumpAndSettle();
      await _navigate(tester, 'Calendar');
      await _selectDay(tester, 10);
      expect(find.text('Driving practice'), findsOneWidget);
      await _tap(tester, find.byTooltip('Delete Driving practice'));
      expect(find.text('Delete event?'), findsOneWidget);
      await _tap(tester, find.text('Cancel'));
      expect(find.text('Driving practice'), findsOneWidget);
      expect(
        (await tester.runAsync<DaylockState?>(() => LocalStorage().load()))!
            .events,
        hasLength(2),
      );
      await _tap(tester, find.byTooltip('Delete Driving practice'));
      await _tap(tester, find.widgetWithText(FilledButton, 'Delete'));
      expect(find.text('Driving practice'), findsNothing);
      expect(find.text('No events scheduled.'), findsOneWidget);
      saved = (await tester.runAsync<DaylockState?>(
        () => LocalStorage().load(),
      ))!;
      expect(saved.events.single.id, 'other');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(MainApp(now: () => _today));
      await tester.pumpAndSettle();
      await _navigate(tester, 'Calendar');
      await _selectDay(tester, 10);
      expect(find.text('No events scheduled.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Editor validates title and times, allows all-day events, and cancels safely',
    (tester) async {
      await tester.pumpWidget(MainApp(now: () => _today));
      await tester.pumpAndSettle();
      await _navigate(tester, 'Calendar');
      await _tap(tester, find.byKey(const ValueKey('calendar-add-event')));
      await _enter(tester, 'title', ' ');
      await _tap(tester, find.text('Save event'));
      expect(find.text('Enter a title.'), findsOneWidget);
      await _enter(tester, 'title', 'Birthday');
      await _enter(tester, 'start', '24:00');
      await _tap(tester, find.text('Save event'));
      expect(find.text('Use HH:mm (00:00–23:59).'), findsOneWidget);
      await _enter(tester, 'start', '14:00');
      await _enter(tester, 'end', '13:00');
      await _tap(tester, find.text('Save event'));
      expect(find.text('End must be after start.'), findsOneWidget);
      expect(
        (await tester.runAsync<DaylockState?>(() => LocalStorage().load()))!
            .events,
        isEmpty,
      );
      await _enter(tester, 'start', '');
      await _enter(tester, 'end', '');
      await _tap(tester, find.text('Save event'));
      expect(find.text('All day'), findsOneWidget);
      await _tap(tester, find.text('Birthday'));
      await _enter(tester, 'title', 'Cancelled edit');
      await _tap(tester, find.text('Cancel'));
      expect(find.text('Birthday'), findsOneWidget);
      expect(
        (await tester.runAsync<DaylockState?>(() => LocalStorage().load()))!
            .events
            .single
            .title,
        'Birthday',
      );
      await _tap(tester, find.byKey(const ValueKey('calendar-add-event')));
      await _enter(tester, 'title', 'Cancelled creation');
      await _tap(tester, find.text('Cancel'));
      expect(
        (await tester.runAsync<DaylockState?>(() => LocalStorage().load()))!
            .events,
        hasLength(1),
      );
    },
  );

  testWidgets(
    'Plan separates tomorrow events from commitments and keeps completion independent',
    (tester) async {
      await tester.runAsync(
        () => LocalStorage().save(
          _state(
            events: [
              Event(id: 'today', title: 'Today event', date: _today),
              Event(
                id: 'lesson',
                title: 'Driving lesson',
                date: DateTime(2026, 10, 9),
                startTime: EventTime(10, 0),
                endTime: EventTime(12, 0),
              ),
              Event(
                id: 'later',
                title: 'Later event',
                date: DateTime(2026, 10, 10),
              ),
            ],
          ),
        ),
      );
      await tester.pumpWidget(MainApp(now: () => _today));
      await tester.pumpAndSettle();
      expect(find.text('0 / 1 complete'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsOneWidget);
      expect(find.text('Today event'), findsNothing);
      await tester.tap(find.text('Gym'));
      await tester.pumpAndSettle();
      expect(find.text('1 / 1 complete'), findsOneWidget);
      expect(find.text('Day complete'), findsOneWidget);
      await _navigate(tester, 'Plan');
      expect(find.text('Driving lesson'), findsOneWidget);
      expect(find.text('Today event'), findsNothing);
      expect(find.text('Later event'), findsNothing);
      expect(
        tester.getTopLeft(find.text('SCHEDULE')).dy,
        lessThan(tester.getTopLeft(find.text('Commitments')).dy),
      );
      expect(
        tester
            .widget<PlanScreen>(find.byType(PlanScreen))
            .plan
            .tasks
            .single
            .name,
        'Read',
      );
      expect(find.byType(CheckboxListTile), findsNothing);
      final commit = find.widgetWithText(FilledButton, 'COMMIT FRIDAY');
      await _tap(tester, commit);
      await confirmPlanCommit(tester);
      expect(find.text("Tomorrow's plan is committed."), findsOneWidget);
      expect(find.byKey(const ValueKey('commitment-name')), findsNothing);

      // Scheduled information remains editable; it cannot unlock commitments.
      await _navigate(tester, 'Calendar');
      await _selectDay(tester, 9);
      await _tap(tester, find.byTooltip('Edit Driving lesson'));
      await _enter(tester, 'title', 'Rescheduled lesson');
      await _tap(tester, find.text('Save event'));
      await _navigate(tester, 'Plan');
      expect(find.text('Rescheduled lesson'), findsOneWidget);
      expect(find.text("Tomorrow's plan is committed."), findsOneWidget);
      expect(
        tester.widget<PlanScreen>(find.byType(PlanScreen)).plan.tasks,
        hasLength(1),
      );
      await _navigate(tester, 'Today');
      expect(find.text('1 / 1 complete'), findsOneWidget);
      final saved = (await tester.runAsync<DaylockState?>(
        () => LocalStorage().load(),
      ))!;
      expect(saved.todayPlan.tasks.single.isCompleted, isTrue);
      expect(saved.tomorrowPlan.isCommitted, isTrue);
      expect(saved.tomorrowPlan.tasks.single.type, TaskType.focus);
      expect(saved.events, hasLength(3));
    },
  );

  testWidgets('Events alone cannot enable committing an empty tomorrow plan', (
    tester,
  ) async {
    await tester.runAsync(
      () => LocalStorage().save(
        DaylockState(
          todayPlan: DailyPlan(date: _today, tasks: []),
          tomorrowPlan: DailyPlan(date: DateTime(2026, 10, 9), tasks: []),
          events: [
            Event(id: 'x', title: 'Lesson', date: DateTime(2026, 10, 9)),
          ],
        ),
      ),
    );
    await tester.pumpWidget(MainApp(now: () => _today));
    await tester.pumpAndSettle();
    expect(find.text('0 / 0 complete'), findsOneWidget);
    await _navigate(tester, 'Plan');
    expect(find.text('Lesson'), findsOneWidget);
    expect(find.text('No commitments planned yet.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'COMMIT FRIDAY'),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets(
    'Resume rollover preserves events and updates tomorrow schedule without creating tasks',
    (tester) async {
      var now = _today;
      await tester.runAsync(
        () => LocalStorage().save(
          _state(
            locked: true,
            events: [
              Event(
                id: 'friday',
                title: 'Friday event',
                date: DateTime(2026, 10, 9),
              ),
              Event(
                id: 'saturday',
                title: 'Saturday event',
                date: DateTime(2026, 10, 10),
              ),
            ],
          ),
        ),
      );
      await tester.pumpWidget(MainApp(now: () => now));
      await tester.pumpAndSettle();
      await _navigate(tester, 'Plan');
      expect(find.text('Friday event'), findsOneWidget);
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      now = DateTime(2026, 10, 9, 8);
      for (final state in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pumpAndSettle();
      expect(find.text('Friday event'), findsNothing);
      expect(find.text('Saturday event'), findsOneWidget);
      expect(find.text('No commitments planned yet.'), findsOneWidget);
      await _navigate(tester, 'Today');
      expect(find.text('Read'), findsOneWidget);
      expect(find.text('0 / 1 complete'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsOneWidget);
      final saved = (await tester.runAsync<DaylockState?>(
        () => LocalStorage().load(),
      ))!;
      expect(saved.todayPlan.date, DateTime(2026, 10, 9));
      expect(saved.events, hasLength(2));
      await _navigate(tester, 'Calendar');
      expect(
        tester.widget<CalendarScreen>(find.byType(CalendarScreen)).events,
        hasLength(2),
      );
    },
  );
}

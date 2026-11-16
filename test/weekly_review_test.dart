import 'package:daylock/main.dart';
import 'package:daylock/models/area.dart';
import 'package:daylock/models/break_entry.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/notification_preferences.dart';
import 'package:daylock/models/plan_history.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/services/journey_service.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:daylock/services/notifications/notification_service.dart';
import 'package:daylock/services/weekly_review.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'notification_preferences_test.dart' show notificationFixture;

final _created = DateTime(2026, 9, 1);
final _areas = AreaBook([
  AreaBook.initial(createdAt: _created).defaultArea,
  Area(
    id: 'body',
    name: 'Body',
    icon: 'fitness',
    colour: 0xff348e88,
    createdAt: _created,
  ),
  Area(
    id: 'mind',
    name: 'Mind',
    icon: 'learning',
    colour: 0xff9473c6,
    createdAt: _created,
  ),
]);

DailyPlan _day(DateTime date, List<(String, String, TaskOutcome)> tasks) =>
    DailyPlan(
      date: date,
      isCommitted: true,
      tasks: [
        for (final (name, area, outcome) in tasks)
          Task(name: name, areaId: area)..changeOutcome(
            outcome,
            now: date,
            reason: outcome == TaskOutcome.excused ? 'Sick' : null,
          ),
      ],
    );

class _Notifications extends NotificationService {
  @override
  Future<void> invalidate() async {}
  @override
  Future<void> synchronize(DaylockState state, DateTime now) async {}
  @override
  Future<void> requestPermission() async {}
}

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  test('the week covers seven days ending today', () {
    final today = DateTime(2026, 11, 15);
    var history = PlanHistory.empty;
    // Inside the week: a fully kept day, a partly kept day, an excused day.
    history = history.archive(
      _day(DateTime(2026, 11, 10), [
        ('Run', 'body', TaskOutcome.completed),
        ('Gym', 'body', TaskOutcome.completed),
      ]),
    );
    history = history.archive(
      _day(DateTime(2026, 11, 12), [
        ('Run', 'body', TaskOutcome.completed),
        ('Read', 'body', TaskOutcome.incomplete),
      ]),
    );
    history = history.archive(
      _day(DateTime(2026, 11, 13), [('Run', 'body', TaskOutcome.excused)]),
    );
    // Before the week: ignored.
    history = history.archive(
      _day(DateTime(2026, 11, 8), [('Read', 'mind', TaskOutcome.completed)]),
    );
    final data = JourneyData(
      areas: _areas,
      history: history,
      todayPlan: DailyPlan(date: today, tasks: []),
      now: DateTime(2026, 11, 15, 19),
    );
    final review = WeeklyReview.of(
      data,
      _areas,
      breaks: [
        BreakEntry(
          at: DateTime(2026, 11, 14, 13),
          app: 'Instagram',
          reason: 'x',
        ),
        BreakEntry(
          at: DateTime(2026, 11, 1, 13),
          app: 'Instagram',
          reason: 'old',
        ),
      ],
    );
    expect(review.from, DateTime(2026, 11, 9));
    expect(review.through, DateTime(2026, 11, 15));
    expect(review.daysPlanned, 3);
    expect(review.daysKept, 1);
    expect(review.kept, 3);
    expect(review.eligible, 4);
    expect(review.topArea!.id, 'body');
    expect(review.topAreaKept, 3);
    expect(
      review.quietAreas.map((a) => a.id),
      containsAll(['mind', Area.defaultId]),
    );
    expect(review.breaks, 1);
    expect(review.isEmpty, isFalse);
  });

  test('settings saved before the weekly review turn it on', () {
    final old = const NotificationPreferences().toJson()..remove('weekly');
    expect(NotificationPreferences.fromJson(old).weekly, isTrue);
    final off = const NotificationPreferences(weekly: false);
    expect(NotificationPreferences.fromJson(off.toJson()).weekly, isFalse);
  });

  test('a review notification target survives parsing', () {
    expect(NotificationTarget.fromJson({'screen': 'review'}).screen, 'review');
    expect(NotificationTarget.fromJson({'screen': 'other'}).screen, 'today');
  });

  testWidgets('the Sunday notification and the Journey card open the review', (
    tester,
  ) async {
    await LocalStorage().save(notificationFixture());
    final service = _Notifications();
    await tester.pumpWidget(
      MainApp(
        notificationService: service,
        now: () => DateTime(2026, 10, 18, 19, 30),
      ),
    );
    await tester.pumpAndSettle();
    service.onTap!(const NotificationTarget('review'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('weekly-review')), findsOneWidget);
    expect(find.text('Your week'), findsOneWidget);

    // Plan tomorrow closes the review and goes to the Plan tab.
    await tester.ensureVisible(find.byKey(const ValueKey('weekly-plan')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('weekly-plan')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('weekly-review')), findsNothing);
    expect(find.byKey(const ValueKey('plan-sky')), findsOneWidget);

    await tester.tap(find.text('Journey'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('journey-week')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('weekly-review')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

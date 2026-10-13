import 'package:daylock/main.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/services/calendar_failure.dart';
import 'package:daylock/services/calendar_service.dart';
import 'package:daylock/services/google_calendar_provider.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'calendar_test_fixtures.dart';
import 'google_calendar_test_fixtures.dart';

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _page(WidgetTester tester, String name) => _tap(
  tester,
  find.descendant(of: find.byType(NavigationBar), matching: find.text(name)),
);

Future<DaylockState> _saved(WidgetTester tester) async =>
    (await tester.runAsync<DaylockState?>(() => LocalStorage().load()))!;

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  testWidgets(
    'Google sync, calendar selection, permission recovery and offline restart preserve plans',
    (tester) async {
      final now = DateTime(2026, 10, 8, 9);
      final auth = TestGoogleAuth();
      final credentials = MemoryCredentials();
      final provider = GoogleCalendarProvider(
        auth: auth,
        client: MockClient((request) async {
          if (request.url.path.endsWith('calendarList')) {
            return googlePage(
              'calendar#calendarList',
              items: [googleCalendar()],
            );
          }
          return googlePage(
            'calendar#events',
            items: [
              {
                'id': 'scheduled',
                'summary': 'Google lesson',
                'start': {'date': '2026-10-09'},
                'end': {'date': '2026-10-10'},
              },
            ],
          );
        }),
      );
      final service = CalendarService(
        credentials: credentials,
        providers: [provider],
      );
      await tester.pumpWidget(
        MainApp(now: () => now, calendarService: service),
      );
      await tester.pumpAndSettle();
      await _page(tester, 'Calendar');
      await _tap(tester, find.byTooltip('Calendar accounts'));
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Connect Google Calendar'),
            )
            .onPressed,
        isNotNull,
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Connect Microsoft Personal'),
            )
            .onPressed,
        isNull,
      );
      await _tap(tester, find.text('Connect Google Calendar'));
      await _tap(tester, find.text('Sync now'));
      final cache = (await _saved(tester)).calendarCache;
      final visibility = find.byKey(
        ValueKey('calendar-visibility-${cache.calendars.single.key}'),
      );
      await _tap(tester, visibility);
      expect((await _saved(tester)).calendarCache.visibleEvents, isEmpty);
      await _tap(tester, visibility);
      final beforeFailure = (await _saved(tester)).toJson();
      auth.failure = const CalendarFailure(CalendarFailureKind.authorization);
      await _tap(tester, find.text('Sync now'));
      expect(find.text(auth.failure!.message), findsOneWidget);
      expect((await _saved(tester)).toJson(), beforeFailure);
      auth.failure = null;
      await _tap(tester, find.text('Reconnect'));
      expect(auth.expected!.id, cache.accounts.single.id);
      expect(find.textContaining('permission has expired'), findsNothing);
      expect(
        (await _saved(tester)).calendarCache.events.single.title,
        'Google lesson',
      );
      await _tap(tester, find.text('Done'));
      await _page(tester, 'Plan');
      expect(find.textContaining('Google lesson'), findsOneWidget);
      expect((await _saved(tester)).todayPlan.tasks, isEmpty);
      expect((await _saved(tester)).tomorrowPlan.tasks, isEmpty);
      await _page(tester, 'Today');
      expect(find.text('0 / 0 complete'), findsOneWidget);
      // Reopening with no connected network/provider still displays the cache.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MainApp(
          now: () => now,
          calendarService: CalendarService(credentials: credentials),
        ),
      );
      await tester.pumpAndSettle();
      await _page(tester, 'Plan');
      expect(find.textContaining('Google lesson'), findsOneWidget);
      await _page(tester, 'Calendar');
      await _tap(tester, find.byKey(const ValueKey('calendar-day-2026-10-09')));
      expect(find.text('Google lesson'), findsOneWidget);
      expect(find.byTooltip('Edit Google lesson'), findsNothing);
      expect(find.byTooltip('Delete Google lesson'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

import 'package:daylock/main.dart';
import 'package:daylock/models/calendar_account.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/event.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/services/calendar_failure.dart';
import 'package:daylock/services/calendar_service.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:daylock/services/microsoft_calendar_auth.dart';
import 'package:daylock/services/microsoft_calendar_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'calendar_test_fixtures.dart';
import 'microsoft_calendar_test_fixtures.dart';

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
    'Microsoft personal/work controls, offline cache and read-only schedules preserve Google/local data and locked commitments',
    (tester) async {
      final now = DateTime(2026, 10, 8, 9);
      final tomorrow = DateTime(2026, 10, 9);
      final google = testAccount(CalendarProviderType.google);
      final original = DaylockState(
        todayPlan: DailyPlan(
          date: now,
          tasks: [Task(name: 'My goal', type: TaskType.goal)],
        ),
        tomorrowPlan: DailyPlan(
          date: tomorrow,
          isCommitted: true,
          tasks: [
            Task(name: 'Read', type: TaskType.focus, minimumFocusMinutes: 60),
          ],
        ),
        events: [Event(id: 'local', title: 'Driving lesson', date: tomorrow)],
        calendarCache: testCache(
          google,
          events: [testExternal(google, title: 'Google lesson')],
        ),
      );
      await tester.runAsync(() => LocalStorage().save(original));
      final native = TestAppAuth();
      final auth = NativeMicrosoftCalendarAuth(
        config: const MicrosoftCalendarConfig(clientId: microsoftTestClient),
        appAuth: native,
        now: () => microsoftTestNow,
      );
      final credentials = MemoryCredentials();
      var denied = false;
      final client = MockClient((request) async {
        final work = request.headers['Authorization']!.contains('work-user');
        if (denied && work) {
          return http.Response('Private organizational diagnostic', 403);
        }
        if (request.url.path.endsWith('/calendars')) {
          return graphPage([graphCalendar()]);
        }
        return graphPage([
          graphAllDay(
            id: 'same-remote-id',
            title: work ? 'Teams lesson' : 'Outlook lesson',
          ),
        ]);
      });
      final service = CalendarService(
        credentials: credentials,
        providers: [
          for (final type in [
            CalendarProviderType.microsoftPersonal,
            CalendarProviderType.microsoftWorkSchool,
          ])
            MicrosoftCalendarProvider(type: type, auth: auth, client: client),
        ],
      );
      await tester.pumpWidget(
        MainApp(now: () => now, calendarService: service),
      );
      await tester.pumpAndSettle();
      await _page(tester, 'Calendar');
      await _tap(tester, find.byTooltip('Calendar accounts'));
      for (final label in [
        'Connect Microsoft Personal',
        'Connect Microsoft Work/School',
      ]) {
        expect(
          tester
              .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, label),
              )
              .onPressed,
          isNotNull,
        );
      }
      await _tap(tester, find.text('Connect Microsoft Personal'));
      await _tap(tester, find.text('Sync now').last);
      native.selected = microsoftAccount(
        type: CalendarProviderType.microsoftWorkSchool,
        subject: 'work-user',
      );
      await _tap(tester, find.text('Connect Microsoft Work/School'));
      await _tap(tester, find.text('Sync now').last);
      var state = await _saved(tester);
      expect(state.calendarCache.accounts, hasLength(3));
      expect(state.calendarCache.events, hasLength(3));
      expect(state.todayPlan.toJson(), original.todayPlan.toJson());
      expect(state.tomorrowPlan.toJson(), original.tomorrowPlan.toJson());
      expect(state.events.single.toJson(), original.events.single.toJson());
      expect(credentials.values, hasLength(2));

      // A permission failure neither removes events nor changes any planner state.
      final beforeFailure = state.toJson();
      denied = true;
      await _tap(tester, find.text('Sync now').last);
      const failure = CalendarFailure(
        CalendarFailureKind.authorization,
        isMicrosoft: true,
      );
      expect(find.text(failure.message), findsOneWidget);
      expect((await _saved(tester)).toJson(), beforeFailure);
      denied = false;
      await _tap(tester, find.text('Reconnect').last);
      expect(
        native.authorizations.last.serviceConfiguration!.authorizationEndpoint,
        contains(microsoftTestTenant),
      );
      await _tap(tester, find.text('Sync now').last);
      state = await _saved(tester);
      final personal = state.calendarCache.calendars.firstWhere(
        (c) => c.accountId == microsoftAccount().id,
      );
      final visibility = find.byKey(
        ValueKey('calendar-visibility-${personal.key}'),
      );
      await _tap(tester, visibility);
      expect((await _saved(tester)).calendarCache.visibleEvents, hasLength(2));
      await _tap(tester, visibility);
      await _tap(tester, find.text('Done'));
      await _page(tester, 'Plan');
      for (final title in [
        'Driving lesson',
        'Google lesson',
        'Outlook lesson',
        'Teams lesson',
      ]) {
        expect(find.textContaining(title), findsOneWidget);
      }
      expect(find.text("Tomorrow's plan is committed."), findsOneWidget);
      expect(find.textContaining('Microsoft Work/School'), findsOneWidget);
      expect(find.textContaining('Microsoft Personal'), findsOneWidget);
      await _page(tester, 'Today');
      expect(find.text('0 / 1 complete'), findsOneWidget);
      expect(find.text('Teams lesson'), findsNothing);

      // Reopen offline without OAuth adapters: all three accounts' cache survives.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MainApp(
          now: () => now,
          calendarService: CalendarService(credentials: credentials),
        ),
      );
      await tester.pumpAndSettle();
      await _page(tester, 'Plan');
      expect(find.textContaining('Teams lesson'), findsOneWidget);
      await _page(tester, 'Calendar');
      await _tap(tester, find.byKey(const ValueKey('calendar-day-2026-10-09')));
      for (final title in ['Outlook lesson', 'Teams lesson']) {
        expect(find.text(title), findsOneWidget);
        expect(find.byTooltip('Edit $title'), findsNothing);
        expect(find.byTooltip('Delete $title'), findsNothing);
      }
      expect(find.byTooltip('Edit Driving lesson'), findsOneWidget);
      await _tap(tester, find.byTooltip('Calendar accounts'));
      await _tap(tester, find.text('Disconnect').at(1));
      expect(find.text('Disconnect account?'), findsOneWidget);
      await _tap(tester, find.widgetWithText(FilledButton, 'Disconnect'));
      final disconnected = await _saved(tester);
      expect(disconnected.calendarCache.accounts.map((a) => a.id), [
        google.id,
        native.selected.id,
      ]);
      expect(
        disconnected.calendarCache.events.map((e) => e.title),
        containsAll(['Google lesson', 'Teams lesson']),
      );
      expect(
        disconnected.calendarCache.events.any(
          (e) => e.title == 'Outlook lesson',
        ),
        isFalse,
      );
      expect(credentials.values.keys, [native.selected.id]);
      expect(
        disconnected.tomorrowPlan.toJson(),
        original.tomorrowPlan.toJson(),
      );
      expect(disconnected.todayPlan.toJson(), original.todayPlan.toJson());
      expect(disconnected.events.single.id, 'local');
      await _tap(tester, find.text('Done'));
      await tester.pumpWidget(const SizedBox());
    },
  );
}

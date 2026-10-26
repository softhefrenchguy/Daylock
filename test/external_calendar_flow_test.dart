import 'navigation_helpers.dart';

import 'package:daylock/main.dart';
import 'package:daylock/models/calendar_account.dart';
import 'package:daylock/models/calendar_cache.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/event.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/screens/calendar_screen.dart';
import 'package:daylock/screens/event_editor.dart';
import 'package:daylock/services/calendar_service.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'calendar_test_fixtures.dart';

final _now = DateTime(2026, 10, 8, 9);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _navigate(WidgetTester tester, String page) =>
    navigateApp(tester, page);
Future<void> _tomorrow(WidgetTester tester) =>
    _tap(tester, find.byKey(const ValueKey('calendar-day-2026-10-09')));
Future<DaylockState> _saved(WidgetTester tester) async =>
    (await tester.runAsync<DaylockState?>(() => LocalStorage().load()))!;

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('Without OAuth configuration account controls remain disabled', (
    tester,
  ) async {
    await tester.pumpWidget(MainApp(now: () => _now));
    await tester.pumpAndSettle();
    await _navigate(tester, 'Calendar');
    await _tap(tester, find.byTooltip('Calendar accounts'));
    for (final provider in CalendarProviderType.values) {
      final button = find.widgetWithText(
        OutlinedButton,
        'Connect ${provider.label}',
      );
      expect(button, findsOneWidget);
      expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
    }
    expect(find.text('No connected accounts.'), findsOneWidget);
    expect(
      find.text(
        'Account sign-in is not available for the disabled providers in this version.',
      ),
      findsOneWidget,
    );
    await _tap(tester, find.text('Done'));
    expect((await _saved(tester)).calendarCache.accounts, isEmpty);
  });

  testWidgets(
    'Cached events from all providers are displayed offline, read-only, and independent of commitments',
    (tester) async {
      final accounts = [
        for (final type in CalendarProviderType.values) testAccount(type),
      ];
      final cache = CalendarCache(
        accounts: accounts,
        calendars: accounts.map(testCalendar),
        events: accounts.map(
          (account) =>
              testExternal(account, title: '${account.provider.label} meeting'),
        ),
      );
      final state = DaylockState(
        todayPlan: DailyPlan(
          date: _now,
          tasks: [Task(name: 'Gym', type: TaskType.goal)],
        ),
        tomorrowPlan: DailyPlan(
          date: DateTime(2026, 10, 9),
          tasks: [Task(name: 'Read', type: TaskType.focus)],
          isCommitted: true,
        ),
        events: [
          Event(
            id: 'local',
            title: 'Local lesson',
            date: DateTime(2026, 10, 9),
          ),
        ],
        calendarCache: cache,
      );
      final service = CalendarService(credentials: MemoryCredentials());
      await tester.runAsync(() => LocalStorage().save(state));
      await tester.pumpWidget(
        MainApp(now: () => _now, calendarService: service),
      );
      await tester.pumpAndSettle();
      expect(find.text('0 / 1 complete'), findsOneWidget);
      await _navigate(tester, 'Calendar');
      await _tomorrow(tester);
      expect(find.text('Local lesson'), findsOneWidget);
      for (final account in accounts) {
        expect(find.text('${account.provider.label} meeting'), findsOneWidget);
        expect(find.text(account.provider.eventSource.label), findsOneWidget);
        expect(
          find.byTooltip('Edit ${account.provider.label} meeting'),
          findsNothing,
        );
        expect(
          find.byTooltip('Delete ${account.provider.label} meeting'),
          findsNothing,
        );
      }
      expect(find.byIcon(Icons.lock_outline), findsNWidgets(3));
      final event = cache.events.first;
      await _tap(tester, find.text(event.title));
      expect(find.text('Read-only · cached event'), findsOneWidget);
      expect(find.text('https://example.test/meeting'), findsOneWidget);
      expect(find.text(cache.sourceLabel(event)), findsOneWidget);
      expect(find.byType(EventEditor), findsNothing);
      await _tap(tester, find.text('Close'));

      // UI callbacks also reject attempts to mutate external events directly.
      final screen = tester.widget<CalendarScreen>(find.byType(CalendarScreen));
      screen.onEventDeleted(event);
      screen.onEventSaved(event);
      screen.onEventSaved(
        Event(id: event.id, title: 'Forged local edit', date: event.date),
      );
      await tester.pumpAndSettle();
      expect((await _saved(tester)).toJson(), state.toJson());
      await _navigate(tester, 'Plan');
      for (final account in accounts) {
        expect(
          find.textContaining('${account.provider.label} meeting'),
          findsOneWidget,
        );
        expect(find.text(account.provider.eventSource.label), findsOneWidget);
      }
      expect(find.text("Tomorrow's plan is committed."), findsOneWidget);
      expect(find.byKey(const ValueKey('commitment-name')), findsNothing);
      await _navigate(tester, 'Today');
      await _tap(tester, find.text('Gym'));
      expect(find.text('1 / 1 complete'), findsOneWidget);
      expect(find.text('Day complete'), findsOneWidget);
      expect((await _saved(tester)).calendarCache.events, hasLength(3));

      // A fresh app instance still displays the cache without credentials/providers.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        MainApp(now: () => _now, calendarService: service),
      );
      await tester.pumpAndSettle();
      await _navigate(tester, 'Calendar');
      await _tomorrow(tester);
      expect(find.byIcon(Icons.lock_outline), findsNWidgets(3));
    },
  );

  testWidgets(
    'Account actions connect through an injected provider, sync, persist visibility, and disconnect safely',
    (tester) async {
      final provider = TestCalendarProvider(CalendarProviderType.google);
      final credentials = MemoryCredentials();
      final service = CalendarService(
        credentials: credentials,
        providers: [provider],
        now: () => _now,
      );
      await tester.pumpWidget(
        MainApp(now: () => _now, calendarService: service),
      );
      await tester.pumpAndSettle();
      await _navigate(tester, 'Calendar');
      await _tap(tester, find.byTooltip('Calendar accounts'));
      await _tap(tester, find.text('Connect Google Calendar'));
      final account = provider.nextAccount!;
      expect(find.text('Alex'), findsOneWidget);
      expect(credentials.values, hasLength(1));
      await _tap(tester, find.text('Sync now'));
      expect((await _saved(tester)).calendarCache.events, hasLength(1));
      final visibility = find.byKey(
        ValueKey('calendar-visibility-${testCalendar(account).key}'),
      );
      expect(tester.widget<CheckboxListTile>(visibility).value, isTrue);
      await _tap(tester, visibility);
      await _tap(tester, find.text('Done'));
      await _tomorrow(tester);
      expect(find.text('Remote meeting'), findsNothing);
      await _navigate(tester, 'Plan');
      expect(find.textContaining('Remote meeting'), findsNothing);
      expect((await _saved(tester)).calendarCache.events, hasLength(1));
      expect((await _saved(tester)).calendarCache.visibleEvents, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        MainApp(now: () => _now, calendarService: service),
      );
      await tester.pumpAndSettle();
      await _navigate(tester, 'Calendar');
      await _tap(tester, find.byTooltip('Calendar accounts'));
      expect(tester.widget<CheckboxListTile>(visibility).value, isFalse);
      await _tap(tester, visibility);
      await _tap(tester, find.text('Done'));
      await _tomorrow(tester);
      expect(find.text('Remote meeting'), findsOneWidget);

      // An offline sync reports failure without losing the visible cache.
      provider.failFetch = true;
      await _tap(tester, find.byTooltip('Calendar accounts'));
      await _tap(tester, find.text('Sync now'));
      expect(
        find.textContaining('Could not update this account.'),
        findsOneWidget,
      );
      expect((await _saved(tester)).calendarCache.events, hasLength(1));
      await _tap(tester, find.widgetWithText(TextButton, 'Disconnect'));
      expect(find.text('Disconnect account?'), findsOneWidget);
      await _tap(tester, find.text('Cancel'));
      expect((await _saved(tester)).calendarCache.accounts, hasLength(1));
      await _tap(tester, find.widgetWithText(TextButton, 'Disconnect'));
      await _tap(tester, find.widgetWithText(FilledButton, 'Disconnect'));
      expect(find.text('No connected accounts.'), findsOneWidget);
      await _tap(tester, find.text('Done'));
      expect(find.text('Remote meeting'), findsNothing);
      expect(credentials.values, isEmpty);
      final saved = await _saved(tester);
      expect(saved.calendarCache.accounts, isEmpty);
      expect(saved.calendarCache.events, isEmpty);
      expect(saved.todayPlan.tasks, isEmpty);
      expect(saved.tomorrowPlan.tasks, isEmpty);
    },
  );
}

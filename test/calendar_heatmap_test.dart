import 'navigation_helpers.dart';

import 'package:daylock/design/daylock_calendar.dart';
import 'package:daylock/design/daylock_palette.dart';
import 'package:daylock/design/daylock_theme.dart';
import 'package:daylock/main.dart';
import 'package:daylock/models/calendar_account.dart';
import 'package:daylock/models/calendar_cache.dart';
import 'package:daylock/models/calendar_activity.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/event.dart';
import 'package:daylock/models/plan_history.dart';
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

final _now = DateTime(2026, 10, 8, 10, 15);
Task _goal(String name, {bool done = false}) =>
    Task(name: name, type: TaskType.goal, isCompleted: done);

PlanHistory _history() => PlanHistory.empty
    .archive(
      DailyPlan(
        date: DateTime(2026, 10, 2),
        isCommitted: true,
        tasks: [_goal('Unfinished goal')],
      ),
    )
    .archive(DailyPlan(date: DateTime(2026, 10, 3), tasks: []))
    .archive(
      DailyPlan(
        date: DateTime(2026, 10, 4),
        isCommitted: true,
        tasks: [
          _goal('Historical goal', done: true),
          Task(
            name: 'Historical focus',
            type: TaskType.focus,
            minimumFocusMinutes: 60,
            focusTarget: 'Finish Chapter 7',
            accumulatedFocusMilliseconds: 1380123,
          ),
        ],
      ),
    )
    .archive(
      DailyPlan(
        date: DateTime(2026, 10, 5),
        tasks: [_goal('Finished goal', done: true)],
      ),
    )
    .archive(
      DailyPlan(
        date: DateTime(2026, 10, 6),
        tasks: [for (var i = 0; i < 4; i++) _goal('Goal $i', done: i == 0)],
      ),
    )
    .archive(
      DailyPlan(
        date: DateTime(2026, 10, 7),
        tasks: [for (var i = 0; i < 3; i++) _goal('Goal $i', done: i < 2)],
      ),
    );

DailyPlan _today() => DailyPlan(
  date: _now,
  isCommitted: true,
  tasks: [
    _goal('Today goal', done: true),
    Task(
      name: 'Live focus',
      type: TaskType.focus,
      minimumFocusMinutes: 60,
      accumulatedFocusMilliseconds: 120000,
      focusStartedAt: DateTime(2026, 10, 8, 9, 55),
    ),
  ],
);

CalendarCache _cache() {
  final accounts = [
    for (final type in CalendarProviderType.values) testAccount(type),
  ];
  return CalendarCache(
    accounts: accounts,
    calendars: accounts.map(testCalendar),
    events: accounts.map(
      (account) =>
          testExternal(account, title: '${account.provider.label} event'),
    ),
  );
}

CalendarScreen _screen({
  DailyPlan? today,
  PlanHistory? history,
  CalendarCache? cache,
  List<Event>? events,
}) => CalendarScreen(
  initialDate: _now,
  todayPlan: today ?? _today(),
  history: history ?? _history(),
  events: events ?? const [],
  calendarCache: cache,
  onEventSaved: (_) {},
  onEventDeleted: (_) {},
);

void _phone(WidgetTester tester, {double width = 390, double height = 844}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app(
  Widget screen, {
  ColourTheme colour = ColourTheme.violet,
  Brightness brightness = Brightness.dark,
  double scale = 1,
  bool reduceMotion = false,
}) => MaterialApp(
  theme: DaylockTheme.forPalette(colour, brightness),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(scale),
      disableAnimations: reduceMotion,
    ),
    child: child!,
  ),
  home: Scaffold(body: screen),
);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _day(
  WidgetTester tester,
  int day, {
  int month = 10,
  int year = 2026,
}) => _tap(
  tester,
  find.byKey(
    ValueKey('calendar-day-${calendarDateKey(DateTime(year, month, day))}'),
  ),
);

Material _fill(WidgetTester tester, int day) => tester.widget<Material>(
  find.byKey(
    ValueKey('heatmap-fill-2026-10-${day.toString().padLeft(2, '0')}'),
  ),
);

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  testWidgets(
    'Monthly grid distinguishes unknown, empty, zero, five levels, Today and future',
    (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(_screen()));
      await tester.pumpAndSettle();
      final palette = DaylockHeatmapPalette(DaylockTheme.dark.colorScheme);
      for (final entry in {
        1: HeatmapIntensity.neutral,
        2: HeatmapIntensity.zero,
        3: HeatmapIntensity.neutral,
        4: HeatmapIntensity.medium,
        5: HeatmapIntensity.complete,
        6: HeatmapIntensity.low,
        7: HeatmapIntensity.high,
        8: HeatmapIntensity.medium,
        9: HeatmapIntensity.neutral,
      }.entries) {
        expect(_fill(tester, entry.key).color, palette.background(entry.value));
      }
      expect(
        find.byKey(const ValueKey('calendar-day-2026-10-31')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('calendar-day-2026-10-32')),
        findsNothing,
      );
      final todayShape = _fill(tester, 8).shape! as RoundedRectangleBorder;
      expect(todayShape.side.width, 2);
      expect(
        todayShape.side.color,
        palette.foreground(HeatmapIntensity.medium),
      );
      expect(
        (_fill(tester, 9).shape! as RoundedRectangleBorder).side,
        BorderSide.none,
      );
      expect(
        tester
            .widget<Semantics>(
              find.byKey(const ValueKey('calendar-day-2026-10-08')),
            )
            .properties
            .selected,
        isTrue,
      );
      await _day(tester, 4);
      expect(
        tester
            .widget<Semantics>(
              find.byKey(const ValueKey('calendar-day-2026-10-04')),
            )
            .properties
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<Semantics>(
              find.byKey(const ValueKey('calendar-day-2026-10-08')),
            )
            .properties
            .selected,
        isFalse,
      );
      expect((_fill(tester, 8).shape! as RoundedRectangleBorder).side.width, 2);
      final todayOutline = tester.widget<AnimatedContainer>(
        find.byKey(const ValueKey('calendar-outline-2026-10-08')),
      );
      expect(
        ((todayOutline.decoration! as BoxDecoration).border! as Border)
            .top
            .color,
        DaylockTheme.dark.colorScheme.primary,
      );
      final selectedOutline = tester.widget<AnimatedContainer>(
        find.byKey(const ValueKey('calendar-outline-2026-10-04')),
      );
      expect(
        ((selectedOutline.decoration! as BoxDecoration).border! as Border)
            .top
            .color,
        DaylockTheme.dark.colorScheme.onSurface,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Past selection shows exact historical completion, Focus and read-only commitments',
    (tester) async {
      _phone(tester);
      final history = _history();
      final before = history.toJson();
      await tester.pumpWidget(_app(_screen(history: history)));
      await tester.pumpAndSettle();
      await _day(tester, 4);
      expect(find.text('1 / 2 complete'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('Historical goal'), findsOneWidget);
      expect(find.text('Historical focus'), findsOneWidget);
      expect(find.text('Commitment · Completed'), findsOneWidget);
      expect(find.text('Commitment · Incomplete'), findsOneWidget);
      expect(find.text('23 min recorded'), findsOneWidget);
      expect(find.text('Recorded time: 23 min'), findsOneWidget);
      expect(find.text('Finish Chapter 7'), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.text('Start'), findsNothing);
      expect(find.text('Pause'), findsNothing);
      expect(history.toJson(), before);
      await _day(tester, 3);
      expect(
        find.text('No commitments recorded. Neutral day.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('calendar-completion-percentage')),
        findsNothing,
      );
      await _day(tester, 1);
      expect(find.text('No commitment history recorded.'), findsOneWidget);
      await _day(tester, 2);
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('calendar-completion-percentage')),
            )
            .data,
        '0%',
      );
      expect(history.toJson(), before);
    },
  );

  testWidgets(
    'Today projects live elapsed time without exposing controls; future has only schedule',
    (tester) async {
      _phone(tester);
      final today = _today();
      final before = today.toJson();
      await tester.pumpWidget(_app(_screen(today: today)));
      await tester.pumpAndSettle();
      expect(find.text('1 / 2 complete'), findsOneWidget);
      expect(find.text('Recorded time: 22 min'), findsOneWidget);
      expect(find.text('Today goal'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsNothing);
      expect(find.text('Start'), findsNothing);
      expect(today.toJson(), before);
      await _day(tester, 9);
      expect(find.text('Today goal'), findsNothing);
      expect(
        find.byKey(const ValueKey('calendar-completion-percentage')),
        findsNothing,
      );
      expect(find.text('COMMITMENT HISTORY'), findsNothing);
      expect(find.text('No events scheduled.'), findsOneWidget);
    },
  );

  testWidgets(
    'Month navigation preserves a valid day, including leap/year boundaries, and Today returns home',
    (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(_screen()));
      await tester.pumpAndSettle();
      await _day(tester, 31);
      await _tap(tester, find.byTooltip('Next month'));
      expect(find.text('November 2026'), findsOneWidget);
      expect(
        tester
            .widget<Semantics>(
              find.byKey(const ValueKey('calendar-day-2026-11-30')),
            )
            .properties
            .selected,
        isTrue,
      );
      await _tap(tester, find.byTooltip('Next month'));
      await _tap(tester, find.byTooltip('Next month'));
      expect(find.text('January 2027'), findsOneWidget);
      await _tap(tester, find.widgetWithText(TextButton, 'Today'));
      expect(find.text('October 2026'), findsOneWidget);
      expect(
        tester
            .widget<Semantics>(
              find.byKey(const ValueKey('calendar-day-2026-10-08')),
            )
            .properties
            .selected,
        isTrue,
      );
      await tester.pumpWidget(
        _app(
          CalendarScreen(
            key: const ValueKey('leap'),
            initialDate: DateTime(2028, 2, 29),
            events: const [],
            onEventSaved: (_) {},
            onEventDeleted: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('calendar-day-2028-02-29')),
        findsOneWidget,
      );
      await _tap(tester, find.byTooltip('Next month'));
      expect(find.text('March 2028'), findsOneWidget);
      await _tap(tester, find.byTooltip('Previous month'));
      expect(
        find.byKey(const ValueKey('calendar-day-2028-02-29')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Visible local, Google and both Microsoft sources have dots and concise labels, with full read-only details',
    (tester) async {
      _phone(tester);
      final cache = _cache();
      final local = Event(
        id: 'local',
        title: 'Local lesson',
        date: DateTime(2026, 10, 9),
        startTime: EventTime(14, 0),
      );
      await tester.pumpWidget(
        _app(_screen(cache: cache, events: [local, ...cache.visibleEvents])),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('calendar-events-2026-10-09')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('calendar-events-2026-10-08')),
        findsNothing,
      );
      await _day(tester, 9);
      expect(find.text('Local'), findsOneWidget);
      expect(find.text('Google Calendar'), findsOneWidget);
      expect(find.text('Microsoft Personal'), findsOneWidget);
      expect(find.text('Microsoft Work/School'), findsOneWidget);
      expect(find.textContaining('@example.test'), findsNothing);
      expect(find.byIcon(Icons.lock_outline), findsNWidgets(3));
      expect(find.byTooltip('Edit Local lesson'), findsOneWidget);
      for (final event in cache.events) {
        expect(find.byTooltip('Edit ${event.title}'), findsNothing);
        expect(find.byTooltip('Delete ${event.title}'), findsNothing);
      }
      await _tap(tester, find.text(cache.events.first.title));
      expect(find.text(cache.sourceLabel(cache.events.first)), findsOneWidget);
      expect(find.text('https://example.test/meeting'), findsOneWidget);
      expect(find.text('Meeting notes'), findsOneWidget);
      expect(find.byType(EventEditor), findsNothing);
      await _tap(tester, find.text('Close'));
      final hidden = cache.setVisibility(
        cache.calendars.first.accountId,
        cache.calendars.first.id,
        false,
      );
      await tester.pumpWidget(
        _app(_screen(cache: hidden, events: hidden.visibleEvents.toList())),
      );
      await tester.pumpAndSettle();
      expect(find.text(cache.events.first.title), findsNothing);
      expect(find.byIcon(Icons.lock_outline), findsNWidgets(2));
      expect(cache.events, hasLength(3));
    },
  );

  testWidgets(
    'Multi-day timed and all-day events indicate each overlapping date without inventing activity',
    (tester) async {
      _phone(tester);
      final account = testAccount(CalendarProviderType.google);
      final events = [
        Event.externalTimed(
          source: EventSource.google,
          accountId: account.id,
          calendarId: 'primary',
          externalEventId: 'overnight',
          title: 'Overnight meeting',
          startsAtUtc: DateTime(2026, 10, 9, 23).toUtc(),
          endsAtUtc: DateTime(2026, 10, 10, 1).toUtc(),
        ),
        Event.externalAllDay(
          source: EventSource.google,
          accountId: account.id,
          calendarId: 'primary',
          externalEventId: 'all-day',
          title: 'Conference',
          date: DateTime(2026, 10, 11),
          endDateExclusive: DateTime(2026, 10, 13),
        ),
      ];
      await tester.pumpWidget(_app(_screen(events: events)));
      await tester.pumpAndSettle();
      for (final day in [9, 10, 11, 12]) {
        expect(
          find.byKey(
            ValueKey(
              'calendar-events-2026-10-${day.toString().padLeft(2, '0')}',
            ),
          ),
          findsOneWidget,
        );
        expect(
          _fill(tester, day).color,
          DaylockHeatmapPalette(DaylockTheme.dark.colorScheme)
              .background(HeatmapIntensity.neutral),
        );
      }
      expect(
        find.byKey(const ValueKey('calendar-events-2026-10-13')),
        findsNothing,
      );
      await _day(tester, 10);
      expect(find.text('Earlier–01:00'), findsOneWidget);
      expect(find.text('Overnight meeting'), findsOneWidget);
      await _day(tester, 12);
      expect(find.text('Conference'), findsOneWidget);
      expect(find.text('All day'), findsOneWidget);
    },
  );

  for (final colour in ColourTheme.values) {
    for (final brightness in Brightness.values) {
      testWidgets(
        '${colour.name} $brightness colours heatmap, details and events',
        (tester) async {
          _phone(tester);
          await tester.pumpWidget(
            _app(
              _screen(
                events: [Event(id: 'x', title: 'Appointment', date: _now)],
              ),
              colour: colour,
              brightness: brightness,
            ),
          );
          await tester.pumpAndSettle();
          final scheme = DaylockTheme.forPalette(
            colour,
            brightness,
          ).colorScheme;
          expect(_fill(tester, 5).color, scheme.primary);
          expect(_fill(tester, 9).color, scheme.surfaceContainerLow);
          await _day(tester, 4);
          expect(
            tester
                .widget<Text>(
                  find.byKey(const ValueKey('calendar-completion-percentage')),
                )
                .style!
                .color,
            scheme.primary,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'Immediate palette and System brightness switching retain month and selected date',
    (tester) async {
      _phone(tester);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      Widget app(ColourTheme colour) => MaterialApp(
        theme: DaylockTheme.forPalette(colour, Brightness.light),
        darkTheme: DaylockTheme.forPalette(colour, Brightness.dark),
        themeMode: ThemeMode.system,
        home: Scaffold(body: _screen()),
      );
      await tester.pumpWidget(app(ColourTheme.violet));
      await tester.pumpAndSettle();
      await _day(tester, 4);
      await tester.pumpWidget(app(ColourTheme.forest));
      await tester.pumpAndSettle();
      expect(
        _fill(tester, 5).color,
        DaylockTheme.forPalette(
          ColourTheme.forest,
          Brightness.dark,
        ).colorScheme.primary,
      );
      expect(find.text('Historical focus'), findsOneWidget);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(
        _fill(tester, 5).color,
        DaylockTheme.forPalette(
          ColourTheme.forest,
          Brightness.light,
        ).colorScheme.primary,
      );
      expect(find.text('Historical focus'), findsOneWidget);
    },
  );

  for (final scale in [1.0, 2.0, 3.0]) {
    testWidgets(
      '320px Calendar supports $scale text with wrapping details, account controls and event actions',
      (tester) async {
        _phone(tester, width: 320, height: 640);
        final cache = _cache();
        final screen = CalendarScreen(
          initialDate: _now,
          todayPlan: _today(),
          history: _history(),
          calendarCache: cache,
          calendarService: CalendarService(credentials: MemoryCredentials()),
          onCalendarCacheChanged: (updated) async => updated,
          events: [
            Event(
              id: 'long',
              title: 'A long appointment title that should wrap clearly on a small phone',
              date: DateTime(2026, 10, 4),
            ),
          ],
          onEventSaved: (_) {},
          onEventDeleted: (_) {},
        );
        await tester.pumpWidget(_app(screen, scale: scale, reduceMotion: true));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _day(tester, 4);
        expect(find.text('Historical focus'), findsOneWidget);
        await _tap(
          tester,
          find.byTooltip(
            'Edit A long appointment title that should wrap clearly on a small phone',
          ),
        );
        expect(find.byType(EventEditor), findsOneWidget);
        await _tap(tester, find.text('Cancel'));
        await _tap(tester, find.byTooltip('Calendar accounts'));
        expect(find.text('Calendar accounts'), findsOneWidget);
        await _tap(tester, find.text('Done'));
        await _tap(tester, find.byTooltip('Next month'));
        expect(find.text('November 2026'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Calendar viewing preserves saved state and events do not affect historical or Today completion',
    (tester) async {
      _phone(tester);
      final cache = _cache();
      final state = DaylockState(
        todayPlan: DailyPlan(date: _now, tasks: [_goal('Today goal')]),
        tomorrowPlan: DailyPlan(date: DateTime(2026, 10, 9), tasks: []),
        history: _history(),
        calendarCache: cache,
        events: [
          Event(
            id: 'past',
            title: 'Past appointment',
            date: DateTime(2026, 10, 4),
          ),
        ],
      );
      await tester.runAsync(() => LocalStorage().save(state));
      await tester.pumpWidget(
        MainApp(
          now: () => _now,
          calendarService: CalendarService(credentials: MemoryCredentials()),
        ),
      );
      await tester.pumpAndSettle();
      await navigateApp(tester, 'Calendar');
      expect(find.text('0 / 1 complete'), findsOneWidget);
      await _day(tester, 4);
      expect(find.text('1 / 2 complete'), findsOneWidget);
      expect(find.text('Past appointment'), findsOneWidget);
      await _day(tester, 9);
      expect(
        find.byKey(const ValueKey('calendar-completion-percentage')),
        findsNothing,
      );
      final saved = (await tester.runAsync<DaylockState?>(
        () => LocalStorage().load(),
      ))!;
      expect(saved.toJson(), state.toJson());
    },
  );

  testWidgets(
    'Resume rollover updates today outline and exposes the archived selected day',
    (tester) async {
      _phone(tester);
      var now = _now;
      await tester.runAsync(
        () => LocalStorage().save(
          DaylockState(
            todayPlan: DailyPlan(
              date: now,
              tasks: [_goal('Today goal', done: true)],
            ),
            tomorrowPlan: DailyPlan(
              date: DateTime(2026, 10, 9),
              tasks: [],
              isCommitted: true,
            ),
          ),
        ),
      );
      await tester.pumpWidget(MainApp(now: () => now));
      await tester.pumpAndSettle();
      await navigateApp(tester, 'Calendar');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      now = DateTime(2026, 10, 9, 8);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('COMMITMENT HISTORY'), findsOneWidget);
      expect(find.text('Today goal'), findsOneWidget);
      expect(
        (_fill(tester, 8).shape! as RoundedRectangleBorder).side,
        BorderSide.none,
      );
      expect((_fill(tester, 9).shape! as RoundedRectangleBorder).side.width, 2);
      await _tap(tester, find.widgetWithText(TextButton, 'Today'));
      expect(find.text('No commitments for today.'), findsOneWidget);
      expect(
        (await tester.runAsync<DaylockState?>(() => LocalStorage().load()))!
            .history
            .plans,
        hasLength(1),
      );
    },
  );
}

import 'navigation_helpers.dart';

import 'package:daylock/design/daylock_calendar.dart';
import 'package:daylock/design/daylock_palette.dart';
import 'package:daylock/design/daylock_theme.dart';
import 'package:daylock/main.dart';
import 'package:daylock/models/calendar_activity.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/plan_history.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/screens/calendar_month_picker.dart';
import 'package:daylock/screens/calendar_screen.dart';
import 'package:daylock/services/calendar_service.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'calendar_test_fixtures.dart';

final _today = DateTime(2026, 10, 8, 10);

void _phone(WidgetTester tester, {double width = 390, double height = 844}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app({
  DateTime? now,
  ColourTheme colour = ColourTheme.violet,
  Brightness brightness = Brightness.dark,
  double scale = 1,
  bool reduced = false,
}) {
  final date = now ?? _today;
  return MaterialApp(
    theme: DaylockTheme.forPalette(colour, brightness),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale),
        disableAnimations: reduced,
      ),
      child: child!,
    ),
    home: Scaffold(
      body: CalendarScreen(
        initialDate: date,
        todayPlan: DailyPlan(
          date: date,
          tasks: [Task(name: 'Today goal', type: TaskType.goal)],
        ),
        events: const [],
        onEventSaved: (_) {},
        onEventDeleted: (_) {},
        calendarService: CalendarService(credentials: MemoryCredentials()),
        onCalendarCacheChanged: (cache) async => cache,
      ),
    ),
  );
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _pick(WidgetTester tester, int year, int month) async {
  await _tap(tester, find.byKey(const ValueKey('open-calendar-month-picker')));
  await tester.enterText(
    find.byKey(const ValueKey('calendar-picker-year')),
    '$year',
  );
  await _tap(tester, find.byKey(ValueKey('calendar-picker-month-$month')));
  await _tap(tester, find.byKey(const ValueKey('calendar-picker-select')));
}

void _selected(WidgetTester tester, DateTime date) {
  final cell = find.byKey(ValueKey('calendar-day-${calendarDateKey(date)}'));
  expect(tester.widget<Semantics>(cell).properties.selected, isTrue);
}

Future<void> _swipe(WidgetTester tester, double dx) async {
  final grid = find.byKey(const ValueKey('calendar-month-swipe'));
  await tester.ensureVisible(grid);
  await tester.drag(grid, Offset(dx, 0));
  await tester.pumpAndSettle();
}

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  testWidgets(
    'Account management is a labelled 48px header icon and opens existing controls',
    (tester) async {
      _phone(tester);
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_app());
        await tester.pumpAndSettle();
        final accounts = find.byKey(const ValueKey('calendar-accounts'));
        expect(tester.getSize(accounts), const Size(48, 48));
        expect(
          tester.getTopLeft(accounts).dy,
          tester.getTopLeft(find.text('Calendar')).dy,
        );
        expect(tester.getTopLeft(accounts).dx, greaterThan(300));
        expect(
          tester.getSemantics(accounts).label,
          contains('Calendar accounts'),
        );
        expect(find.text('Calendar accounts'), findsNothing);
        await _tap(tester, find.byTooltip('Calendar accounts'));
        expect(find.text('Calendar accounts'), findsOneWidget);
        expect(find.text('No connected accounts.'), findsOneWidget);
        await _tap(tester, find.text('Done'));
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'Arrows cross December/January, clamp a 31st to leap day and retain date selection',
    (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(now: DateTime(2027, 12, 31)));
      await tester.pumpAndSettle();
      await _tap(tester, find.byTooltip('Next month'));
      expect(find.text('January 2028'), findsOneWidget);
      _selected(tester, DateTime(2028, 1, 31));
      await _tap(tester, find.byTooltip('Next month'));
      _selected(tester, DateTime(2028, 2, 29));
      await _tap(tester, find.byTooltip('Previous month'));
      _selected(tester, DateTime(2028, 1, 29));
      await _tap(tester, find.byKey(const ValueKey('calendar-day-2028-01-15')));
      _selected(tester, DateTime(2028, 1, 15));
      expect(find.text('No events scheduled.'), findsOneWidget);
    },
  );

  testWidgets(
    'Left/right swipes navigate one month and share arrow/picker day clamping',
    (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(now: DateTime(2027, 12, 31)));
      await tester.pumpAndSettle();
      await _swipe(tester, -180);
      expect(find.text('January 2028'), findsOneWidget);
      _selected(tester, DateTime(2028, 1, 31));
      await _swipe(tester, -180);
      _selected(tester, DateTime(2028, 2, 29));
      await _swipe(tester, 180);
      _selected(tester, DateTime(2028, 1, 29));
      await _pick(tester, 2027, 2);
      _selected(tester, DateTime(2027, 2, 28));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Taps, small horizontal motion, vertical scroll and diagonal scroll do not switch month',
    (tester) async {
      _phone(tester, height: 640);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('calendar-day-2026-10-15')));
      _selected(tester, DateTime(2026, 10, 15));
      await _swipe(tester, 30);
      expect(find.text('October 2026'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('calendar-day-2026-10-08')));
      final page = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byKey(const ValueKey('calendar-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      final before = page.position.pixels;
      await tester.drag(
        find.byKey(const ValueKey('calendar-month-swipe')),
        const Offset(0, -150),
      );
      await tester.pumpAndSettle();
      expect(page.position.pixels, greaterThan(before));
      expect(find.text('October 2026'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('calendar-month-swipe')),
      );
      await tester.drag(
        find.byKey(const ValueKey('calendar-month-swipe')),
        const Offset(-30, -150),
      );
      await tester.pumpAndSettle();
      expect(find.text('October 2026'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Month/year picker starts from visible month, supports direct jumps and Today restores details',
    (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      await _tap(tester, find.byTooltip('Next month'));
      await _tap(
        tester,
        find.byKey(const ValueKey('open-calendar-month-picker')),
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('calendar-picker-year')),
            )
            .controller!
            .text,
        '2026',
      );
      final november = find.byKey(const ValueKey('calendar-picker-month-11'));
      expect(
        tester.widget<TextButton>(november).style!.backgroundColor!.resolve({}),
        DaylockTheme.dark.colorScheme.primary,
      );
      await tester.enterText(
        find.byKey(const ValueKey('calendar-picker-year')),
        '2001',
      );
      await _tap(tester, find.byKey(const ValueKey('calendar-picker-month-1')));
      await _tap(tester, find.byKey(const ValueKey('calendar-picker-select')));
      expect(find.text('January 2001'), findsOneWidget);
      _selected(tester, DateTime(2001, 1, 8));
      expect(find.text('No commitment history recorded.'), findsOneWidget);
      await _tap(tester, find.widgetWithText(TextButton, 'Today'));
      expect(find.text('October 2026'), findsOneWidget);
      _selected(tester, DateTime(2026, 10, 8));
      expect(find.text('Today goal'), findsOneWidget);
    },
  );

  testWidgets(
    'Picker validates years, steps them, cancels safely and supports full existing date domain',
    (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      await _tap(
        tester,
        find.byKey(const ValueKey('open-calendar-month-picker')),
      );
      for (final value in ['', '0', '10000']) {
        await tester.enterText(
          find.byKey(const ValueKey('calendar-picker-year')),
          value,
        );
        await _tap(
          tester,
          find.byKey(const ValueKey('calendar-picker-select')),
        );
        expect(find.text('Enter a year from 1 to 9999.'), findsOneWidget);
        expect(find.byType(CalendarMonthPicker), findsOneWidget);
      }
      await tester.enterText(
        find.byKey(const ValueKey('calendar-picker-year')),
        '2026',
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.byTooltip('Next year'));
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('calendar-picker-year')),
            )
            .controller!
            .text,
        '2027',
      );
      await _tap(tester, find.byTooltip('Previous year'));
      await _tap(tester, find.text('Cancel'));
      _selected(tester, DateTime(2026, 10, 8));
      await _pick(tester, 1, 1);
      _selected(tester, DateTime(1, 1, 8));
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.chevron_left_rounded).first,
            )
            .onPressed,
        isNull,
      );
      await _pick(tester, 9999, 12);
      _selected(tester, DateTime(9999, 12, 8));
      expect(
        tester
            .widget<IconButton>(
              find
                  .widgetWithIcon(IconButton, Icons.chevron_right_rounded)
                  .first,
            )
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Compact legend retains neutral/zero/full tooltips and Today+selected use two separate rings',
    (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      expect(find.text('Less'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
      expect(find.text('Neutral'), findsNothing);
      expect(
        find.byTooltip(
          'Neutral: no eligible commitments, missing history or future date',
        ),
        findsOneWidget,
      );
      expect(
        find.byTooltip('Recorded commitments: 0 percent complete'),
        findsOneWidget,
      );
      expect(find.byTooltip('100 percent complete'), findsOneWidget);
      final outline = tester.widget<AnimatedContainer>(
        find.byKey(const ValueKey('calendar-outline-2026-10-08')),
      );
      expect(
        ((outline.decoration! as BoxDecoration).border! as Border).top.color,
        DaylockTheme.dark.colorScheme.onSurface,
      );
      final fill = tester.widget<Material>(
        find.byKey(const ValueKey('heatmap-fill-2026-10-08')),
      );
      expect((fill.shape! as RoundedRectangleBorder).side.width, 2);
      expect(
        (fill.shape! as RoundedRectangleBorder).side.color,
        DaylockHeatmapPalette(DaylockTheme.dark.colorScheme)
            .foreground(HeatmapIntensity.zero),
      );
      final cell = find.byKey(const ValueKey('calendar-day-2026-10-08'));
      expect(tester.getSize(cell).height, 48);
      expect(tester.getSize(cell).width, greaterThanOrEqualTo(48));
    },
  );

  for (final reduced in [false, true]) {
    testWidgets('Month fade respects reduced motion: $reduced', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(reduced: reduced));
      await tester.pumpAndSettle();
      final switcher = tester.widget<AnimatedSwitcher>(
        find.byKey(const ValueKey('calendar-month-transition')),
      );
      expect(
        switcher.duration,
        reduced ? Duration.zero : const Duration(milliseconds: 220),
      );
      await _swipe(tester, -180);
      _selected(tester, DateTime(2026, 11, 8));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Large-text grid pans to offscreen dates and edge swipes still navigate month',
    (tester) async {
      _phone(tester, width: 320, height: 640);
      await tester.pumpWidget(_app(scale: 3, reduced: true));
      await tester.pumpAndSettle();
      final grid = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byKey(const ValueKey('calendar-grid-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(grid.position.maxScrollExtent, greaterThan(0));
      await _swipe(tester, -120);
      expect(grid.position.pixels, greaterThan(0));
      expect(find.text('October 2026'), findsOneWidget);
      // Reach the far edge, then deliberately swipe beyond it.
      grid.position.jumpTo(grid.position.maxScrollExtent);
      await tester.pumpAndSettle();
      await _swipe(tester, -180);
      expect(find.text('November 2026'), findsOneWidget);
      await _swipe(tester, 180); // New month starts at its leading edge.
      expect(find.text('October 2026'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final scale in [1.0, 2.0, 3.0]) {
    testWidgets(
      '320px picker supports $scale text, keyboard, scrolling month choices and Schedule action',
      (tester) async {
        _phone(tester, width: 320, height: 640);
        await tester.pumpWidget(_app(scale: scale, reduced: true));
        await tester.pumpAndSettle();
        await _tap(
          tester,
          find.byKey(const ValueKey('open-calendar-month-picker')),
        );
        await tester.enterText(
          find.byKey(const ValueKey('calendar-picker-year')),
          '2028',
        );
        tester.view.viewInsets = const FakeViewPadding(bottom: 200);
        await tester.pumpAndSettle();
        await _tap(
          tester,
          find.byKey(const ValueKey('calendar-picker-month-2')),
        );
        await _tap(
          tester,
          find.byKey(const ValueKey('calendar-picker-select')),
        );
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        _selected(tester, DateTime(2028, 2, 8));
        expect(
          find.text('Events are separate from commitments.'),
          findsNothing,
        );
        final add = find.byKey(const ValueKey('calendar-add-event'));
        await tester.ensureVisible(add);
        expect(tester.widget<TextButton>(add).onPressed, isNotNull);
        expect(tester.getSize(add).height, greaterThanOrEqualTo(48));
        expect(tester.takeException(), isNull);
        addTearDown(tester.view.resetViewInsets);
      },
    );
  }

  for (final colour in ColourTheme.values) {
    for (final brightness in Brightness.values) {
      testWidgets(
        '${colour.name} $brightness styles picker and retains selected month when rebuilt',
        (tester) async {
          _phone(tester);
          await tester.pumpWidget(_app(colour: colour, brightness: brightness));
          await tester.pumpAndSettle();
          await _tap(
            tester,
            find.byKey(const ValueKey('open-calendar-month-picker')),
          );
          final month = tester.widget<TextButton>(
            find.byKey(const ValueKey('calendar-picker-month-10')),
          );
          final scheme = DaylockTheme.forPalette(
            colour,
            brightness,
          ).colorScheme;
          expect(month.style!.backgroundColor!.resolve({}), scheme.primary);
          expect(month.style!.foregroundColor!.resolve({}), scheme.onPrimary);
          await _tap(tester, find.text('Cancel'));
          await _pick(tester, 2028, 2);
          _selected(tester, DateTime(2028, 2, 8));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'Open picker follows palette and System changes without losing edited year or month',
    (tester) async {
      _phone(tester);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      Widget app(ColourTheme colour) => MaterialApp(
        theme: DaylockTheme.forPalette(colour, Brightness.light),
        darkTheme: DaylockTheme.forPalette(colour, Brightness.dark),
        themeMode: ThemeMode.system,
        home: Scaffold(
          body: CalendarScreen(
            initialDate: _today,
            events: const [],
            onEventSaved: (_) {},
            onEventDeleted: (_) {},
          ),
        ),
      );
      await tester.pumpWidget(app(ColourTheme.violet));
      await tester.pumpAndSettle();
      await _tap(
        tester,
        find.byKey(const ValueKey('open-calendar-month-picker')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('calendar-picker-year')),
        '2040',
      );
      await _tap(
        tester,
        find.byKey(const ValueKey('calendar-picker-month-12')),
      );
      await tester.pumpWidget(app(ColourTheme.forest));
      await tester.pumpAndSettle();
      final december = find.byKey(const ValueKey('calendar-picker-month-12'));
      expect(
        tester.widget<TextButton>(december).style!.backgroundColor!.resolve({}),
        DaylockTheme.forPalette(
          ColourTheme.forest,
          Brightness.dark,
        ).colorScheme.primary,
      );
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextButton>(december).style!.backgroundColor!.resolve({}),
        DaylockTheme.forPalette(
          ColourTheme.forest,
          Brightness.light,
        ).colorScheme.primary,
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('calendar-picker-year')),
            )
            .controller!
            .text,
        '2040',
      );
      await _tap(tester, find.byKey(const ValueKey('calendar-picker-select')));
      _selected(tester, DateTime(2040, 12, 8));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Jumping months and local event editing preserve history, current plans and saved data',
    (tester) async {
      _phone(tester);
      final history = PlanHistory.empty.archive(
        DailyPlan(
          date: DateTime(2026, 10, 7),
          tasks: [
            Task(
              name: 'Historical goal',
              type: TaskType.goal,
              isCompleted: true,
            ),
          ],
        ),
      );
      final state = DaylockState(
        todayPlan: DailyPlan(
          date: _today,
          tasks: [Task(name: 'Today goal', type: TaskType.goal)],
        ),
        tomorrowPlan: DailyPlan(
          date: DateTime(2026, 10, 9),
          tasks: [Task(name: 'Locked goal', type: TaskType.goal)],
          isCommitted: true,
        ),
        history: history,
      );
      await tester.runAsync(() => LocalStorage().save(state));
      await tester.pumpWidget(MainApp(now: () => _today));
      await tester.pumpAndSettle();
      await navigateApp(tester, 'Calendar');
      await _pick(tester, 2016, 2);
      _selected(tester, DateTime(2016, 2, 8));
      await _tap(tester, find.byKey(const ValueKey('calendar-add-event')));
      await tester.enterText(
        find.byKey(const ValueKey('event-title')),
        'Past appointment',
      );
      await _tap(tester, find.text('Save event'));
      await _tap(tester, find.byTooltip('Edit Past appointment'));
      await tester.enterText(
        find.byKey(const ValueKey('event-title')),
        'Edited appointment',
      );
      await _tap(tester, find.text('Save event'));
      final saved = (await tester.runAsync<DaylockState?>(
        () => LocalStorage().load(),
      ))!;
      expect(saved.events.single.date, DateTime(2016, 2, 8));
      expect(saved.events.single.title, 'Edited appointment');
      expect(saved.history.toJson(), state.history.toJson());
      expect(saved.todayPlan.toJson(), state.todayPlan.toJson());
      expect(saved.tomorrowPlan.toJson(), state.tomorrowPlan.toJson());
      expect(find.text('No commitment history recorded.'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('calendar-completion-percentage')),
        findsNothing,
      );
    },
  );
}

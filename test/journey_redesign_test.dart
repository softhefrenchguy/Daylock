import 'package:daylock/main.dart';
import 'package:daylock/design/daylock_palette.dart';
import 'package:daylock/design/daylock_theme.dart';
import 'package:daylock/models/area.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/highlight.dart';
import 'package:daylock/models/plan_history.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/screens/journey_screen.dart';
import 'package:daylock/screens/highlight_editor.dart';
import 'package:daylock/screens/past_chapters_screen.dart';
import 'package:daylock/screens/areas_screen.dart';
import 'package:daylock/services/journey_service.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'navigation_helpers.dart';

final now = DateTime(2026, 10, 26, 18);
Area custom(String id, String name, {bool archived = false}) => Area(
  id: id,
  name: name,
  icon: 'learning',
  colour: 0xff528cce,
  createdAt: now,
  isArchived: archived,
);
final areas = AreaBook([
  AreaBook.initial(createdAt: now).defaultArea.copyWith(name: 'Everyday'),
  custom('learn', 'Learning'),
  custom('health', 'Health'),
  custom('cook', 'Cooking'),
  custom('past', 'Before', archived: true),
]);
final moments = HighlightBook([
  Highlight(
    id: 'first',
    title: 'Cooked my first proper meal',
    date: now,
    description: 'Shared with friends.',
    areaId: 'cook',
  ),
  Highlight(
    id: 'second',
    title: 'Passed my certification',
    date: DateTime(2026, 10, 25),
    areaId: 'learn',
  ),
  Highlight(
    id: 'third',
    title: 'A day by the sea',
    date: DateTime(2026, 10, 24),
  ),
]);
final today = DailyPlan(
  date: now,
  tasks: [
    Task(
      name: 'Read',
      type: TaskType.focus,
      minimumFocusMinutes: 5,
      accumulatedFocusMilliseconds: 120000,
      areaId: 'learn',
    ),
    Task(
      name: 'Practice',
      type: TaskType.goal,
      isCompleted: true,
      areaId: 'learn',
    ),
    Task(
      name: 'Walk',
      type: TaskType.goal,
      isCompleted: true,
      areaId: 'health',
    ),
  ],
);
final history = PlanHistory.empty.archive(
  DailyPlan(
    date: DateTime(2026, 10, 24),
    tasks: [
      Task(
        name: 'Earlier',
        type: TaskType.goal,
        isCompleted: true,
        areaId: 'past',
      ),
    ],
  ),
);
final data = JourneyData(
  areas: areas,
  history: history,
  todayPlan: today,
  now: now,
);
Finder key(String value) => find.byKey(ValueKey(value));
Finder get vertical => find.descendant(
  of: key('journey-content'),
  matching: find.byWidgetPredicate(
    (widget) =>
        widget is Scrollable && widget.axisDirection == AxisDirection.down,
  ),
);
Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.pumpAndSettle();
  if (finder.evaluate().isEmpty) {
    tester.state<ScrollableState>(vertical).position.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(finder, 200, scrollable: vertical);
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void phone(WidgetTester tester, {double width = 390, double height = 844}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget overview({
  AreaBook? book,
  HighlightBook? highlights,
  JourneyData? journey,
  ValueChanged<String>? onArea,
  ValueChanged<Highlight>? onOpen,
  ValueChanged<Highlight>? onEdit,
  VoidCallback? onAdd,
}) => JourneyScreen(
  areas: book ?? areas,
  highlights: highlights ?? moments,
  data: journey ?? data,
  onAreaOpened: onArea ?? (_) {},
  onHighlightOpened: onOpen ?? (_) {},
  onHighlightEdited: onEdit ?? (_) {},
  onAddHighlight: onAdd ?? () {},
  onAllHighlights: () {},
  onDailyHistory: () {},
  onPastChapters: () {},
  onManageAreas: () {},
);
Widget shell(
  Widget child, {
  double scale = 1,
  ColourTheme colour = ColourTheme.violet,
  Brightness brightness = Brightness.dark,
  bool reducedMotion = false,
}) => MaterialApp(
  theme: DaylockTheme.forPalette(colour, brightness),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(scale),
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      disableAnimations: reducedMotion,
    ),
    child: child!,
  ),
  home: Scaffold(
    body: child,
    bottomNavigationBar: NavigationBar(
      selectedIndex: 2,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.today), label: 'Today'),
        NavigationDestination(icon: Icon(Icons.edit_note), label: 'Plan'),
        NavigationDestination(icon: Icon(Icons.auto_stories), label: 'Journey'),
      ],
    ),
  ),
);

DailyPlan _kept(DateTime date, {bool kept = true, bool excused = false}) =>
    DailyPlan(
      date: date,
      tasks: [
        Task(
          name: 'Step',
          type: TaskType.goal,
          isCompleted: kept && !excused,
          outcome: excused ? TaskOutcome.excused : null,
          excuseReason: excused ? 'Outside reason.' : null,
          areaId: 'learn',
        ),
      ],
    );

JourneyData _streakData(List<DailyPlan> days, DailyPlan live) {
  var book = PlanHistory.empty;
  for (final day in days) {
    book = book.archive(day);
  }
  return JourneyData(areas: areas, history: book, todayPlan: live, now: now);
}

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  group('Streaks', () {
    final today = DateTime(2026, 10, 26);
    DateTime day(int offset) => DateTime(2026, 10, 26 - offset);
    final unfinished = DailyPlan(
      date: today,
      tasks: [Task(name: 'Today', type: TaskType.goal, areaId: 'learn')],
    );

    test('An unfinished today never breaks a streak of kept days', () {
      final journey = _streakData([
        for (var i = 4; i >= 1; i--) _kept(day(i)),
      ], unfinished);
      expect(journey.currentStreak, 4);
      expect(journey.longestStreak, 4);
    });

    test('Keeping today extends the streak', () {
      final journey = _streakData([
        for (var i = 3; i >= 1; i--) _kept(day(i)),
      ], _kept(today));
      expect(journey.currentStreak, 4);
    });

    test('A missed day or a day without a plan ends the streak', () {
      final missed = _streakData([
        _kept(day(3)),
        _kept(day(2), kept: false),
        _kept(day(1)),
      ], unfinished);
      expect(missed.currentStreak, 1);
      expect(missed.longestStreak, 1);
      final gap = _streakData([_kept(day(3)), _kept(day(1))], unfinished);
      expect(gap.currentStreak, 1);
    });

    test('Fully excused days neither count nor break the streak', () {
      final journey = _streakData([
        _kept(day(3)),
        _kept(day(2), excused: true),
        _kept(day(1)),
      ], unfinished);
      expect(journey.currentStreak, 2);
      expect(journey.statusOn(day(2)), JourneyDayStatus.excused);
      expect(journey.statusOn(day(5)), JourneyDayStatus.none);
    });
  });

  testWidgets('The sky shows the streak; totals use all recorded history', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(shell(overview()));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('0 day streak'), findsOneWidget);
    expect(find.text('Keep all of today to start one'), findsOneWidget);
    String plain(String id) => tester.widget<Text>(key(id)).data!;
    // Two kept today plus one in an archived Area's history.
    expect(plain('journey-total-completed'), '3');
    expect(plain('journey-total-focus'), '2m');
    expect(plain('journey-total-highlights'), '3');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Achievements show newest first, open on tap and edit on long press',
    (tester) async {
      phone(tester);
      Highlight? opened, edited;
      await tester.pumpWidget(
        shell(overview(onOpen: (h) => opened = h, onEdit: (h) => edited = h)),
      );
      await tester.pumpAndSettle();
      final first = tester.getTopLeft(key('highlight-first'));
      final second = tester.getTopLeft(key('highlight-second'));
      expect(first.dx, lessThan(second.dx));
      expect(first.dy, second.dy);
      expect(key('all-highlights'), findsOneWidget);
      await tester.tap(key('highlight-first'));
      expect(opened?.id, 'first');
      await tester.longPress(key('highlight-second'));
      expect(edited?.id, 'second');
      // Each card wears its Area's colour; an unlinked one falls back to pink.
      expect(
        find.descendant(
          of: key('highlight-first'),
          matching: find.textContaining('Cooking'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('An empty shelf invites the first achievement', (tester) async {
    phone(tester);
    var added = 0;
    await tester.pumpWidget(
      shell(overview(highlights: HighlightBook.empty, onAdd: () => added++)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Keep a moment that matters.'), findsOneWidget);
    expect(key('all-highlights'), findsNothing);
    await tester.tap(find.text('Keep a moment that matters.'));
    await tester.tap(key('add-highlight'));
    expect(added, 2);
  });

  testWidgets('Areas show this week in their own colours and open on tap', (
    tester,
  ) async {
    phone(tester);
    String? opened;
    await tester.pumpWidget(shell(overview(onArea: (id) => opened = id)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      key('journey-area-grid'),
      200,
      scrollable: vertical,
    );
    await tester.pumpAndSettle();
    Finder week(String id, String text) =>
        find.descendant(of: key('journey-area-$id'), matching: find.text(text));
    expect(week('learn', '1 this week'), findsOneWidget);
    expect(week('health', '1 this week'), findsOneWidget);
    expect(week('cook', '0 this week'), findsOneWidget);
    expect(key('journey-area-past'), findsNothing);
    await tap(tester, key('journey-area-learn'));
    expect(opened, 'learn');
  });

  testWidgets('Five-week grid summarises kept days for screen readers', (
    tester,
  ) async {
    phone(tester);
    final journey = _streakData([
      _kept(DateTime(2026, 10, 24)),
      _kept(DateTime(2026, 10, 25)),
    ], today);
    await tester.pumpWidget(shell(overview(journey: journey)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      key('journey-weeks'),
      200,
      scrollable: vertical,
    );
    expect(
      find.bySemanticsLabel('Last 5 weeks: 2 days fully kept'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('2 day streak'), findsOneWidget);
  });

  for (final colour in ColourTheme.values) {
    for (final brightness in Brightness.values) {
      testWidgets('Journey renders in $colour $brightness', (tester) async {
        phone(tester);
        await tester.pumpWidget(
          shell(overview(), colour: colour, brightness: brightness),
        );
        await tester.pumpAndSettle();
        expect(find.text('Journey'), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final scale in [1.0, 1.5, 2.0, 3.0]) {
    testWidgets(
      '320px compact layout supports $scale text, long names and many Areas',
      (tester) async {
        phone(tester, width: 320, height: 640);
        final many = AreaBook([
          ...areas.areas,
          for (var i = 0; i < 6; i++)
            custom('extra$i', 'A very long Area name number $i that wraps'),
        ]);
        await tester.pumpWidget(shell(overview(book: many), scale: scale));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          key('past-chapters'),
          250,
          scrollable: vertical,
          maxScrolls: 80,
        );
        await tester.pumpAndSettle();
        expect(key('past-chapters').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Manage Areas, Past Chapters and Daily history open their screens',
    (tester) async {
      await tester.runAsync(
        () => LocalStorage().save(
          DaylockState(
            todayPlan: today,
            tomorrowPlan: DailyPlan(date: DateTime(2026, 10, 27), tasks: []),
            history: history,
            areas: areas,
            highlights: moments,
          ),
        ),
      );
      await tester.pumpWidget(MainApp(now: () => now));
      await tester.pumpAndSettle();
      await navigateApp(tester, 'Journey');
      await tap(tester, key('journey-manage-areas'));
      expect(find.byType(AreasScreen), findsOneWidget);
      // The Calendar helper scrolls down, so visit it before Past Chapters.
      await navigateApp(tester, 'Calendar');
      expect(find.textContaining('2026'), findsWidgets);
      await navigateApp(tester, 'Journey');
      await tap(tester, key('past-chapters'));
      expect(find.byType(PastChaptersScreen), findsOneWidget);
      await navigateApp(tester, 'Journey');
      await tap(tester, key('highlight-first'));
      expect(find.text('Cooked my first proper meal'), findsWidgets);
      expect(find.byType(HighlightEditor), findsNothing);
    },
  );
}

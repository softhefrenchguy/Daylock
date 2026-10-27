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

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );
  testWidgets(
    'Four configured Areas form two columns with featured Highlight visible before scrolling',
    (tester) async {
      phone(tester);
      await tester.pumpWidget(shell(overview()));
      await tester.pumpAndSettle();
      final tiles = [
        for (final area in areas.active)
          tester.getRect(key('journey-area-${area.id}')),
      ];
      expect(tiles[0].top, tiles[1].top);
      expect(tiles[2].top, tiles[3].top);
      expect(tiles[0].left, tiles[2].left);
      expect(tiles[1].left, greaterThan(tiles[0].right));
      expect(tiles[0].width / tiles[0].height, inInclusiveRange(.7, 1.5));
      final card = tester.getRect(key('featured-highlights'));
      expect(
        card.bottom,
        lessThanOrEqualTo(tester.getRect(find.byType(NavigationBar)).top),
      );
      expect(key('highlight-first').hitTestable(), findsOneWidget);
      expect(find.text('Everyday'), findsOneWidget);
      expect(key('journey-area-past'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Summary uses existing totals including archived history; Goal time is never inferred',
    (tester) async {
      await tester.pumpWidget(shell(overview()));
      expect(
        tester
            .widget<Text>(key('journey-total-completed'))
            .textSpan!
            .toPlainText(),
        '3 completed',
      );
      expect(
        tester.widget<Text>(key('journey-total-focus')).textSpan!.toPlainText(),
        '2 min Focus',
      );
      expect(
        tester
            .widget<Text>(key('journey-total-highlights'))
            .textSpan!
            .toPlainText(),
        '3 Highlights',
      );
      expect(
        find.descendant(
          of: key('journey-area-learn'),
          matching: find.text('2 min Focus'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: key('journey-area-health'),
          matching: find.text('1 completed'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Quiet empty Area and Highlight-only Area use distinct meaningful indicators; tiles navigate',
    (tester) async {
      String? opened;
      await tester.pumpWidget(shell(overview(onArea: (id) => opened = id)));
      expect(
        find.descendant(
          of: key('journey-area-${Area.defaultId}'),
          matching: find.text('Open space'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: key('journey-area-cook'),
          matching: find.text(moments.highlights.first.title),
        ),
        findsOneWidget,
      );
      expect(find.text('Your story here is just beginning.'), findsNothing);
      await tap(tester, key('journey-area-cook'));
      expect(opened, 'cook');
      await tester.pumpWidget(
        shell(
          overview(
            journey: JourneyData(
              areas: areas,
              history: PlanHistory.empty,
              todayPlan: DailyPlan(
                date: now,
                tasks: [
                  Task(
                    name: 'Try a recipe',
                    type: TaskType.goal,
                    areaId: 'cook',
                  ),
                ],
              ),
              now: now,
            ),
          ),
        ),
      );
      expect(
        find.descendant(
          of: key('journey-area-cook'),
          matching: find.text('0 completed'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Featured Highlights swipe, show position, open and edit the selected record',
    (tester) async {
      phone(tester);
      String? opened, edited;
      await tester.pumpWidget(
        shell(
          overview(onOpen: (h) => opened = h.id, onEdit: (h) => edited = h.id),
        ),
      );
      expect(find.text('1 / 3'), findsOneWidget);
      await tester.drag(key('featured-highlights'), const Offset(-340, 0));
      await tester.pumpAndSettle();
      expect(find.text('2 / 3'), findsOneWidget);
      await tap(tester, key('edit-featured-highlight'));
      expect(edited, 'second');
      await tap(tester, key('highlight-second'));
      expect(opened, 'second');
      await tap(tester, key('next-highlight'));
      expect(find.text('3 / 3'), findsOneWidget);
      expect(
        tester.widget<IconButton>(key('next-highlight')).onPressed,
        isNull,
      );
      await tap(tester, key('previous-highlight'));
      expect(find.text('2 / 3'), findsOneWidget);
    },
  );

  testWidgets(
    'Selection survives rebuilds and date reordering, then safely handles deletion and new Highlights',
    (tester) async {
      phone(tester);
      final source = ValueNotifier(moments);
      addTearDown(source.dispose);
      String? edited;
      await tester.pumpWidget(
        shell(
          ValueListenableBuilder<HighlightBook>(
            valueListenable: source,
            builder: (_, book, _) =>
                overview(highlights: book, onEdit: (h) => edited = h.id),
          ),
        ),
      );
      await tap(tester, key('next-highlight'));
      source.value = HighlightBook(moments.highlights);
      await tester.pumpAndSettle();
      expect(find.text('2 / 3'), findsOneWidget);
      source.value = source.value.upsert(
        Highlight(
          id: 'second',
          title: 'Edited milestone',
          date: DateTime(2026, 10, 27),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 / 3'), findsOneWidget);
      await tap(tester, key('edit-featured-highlight'));
      expect(edited, 'second');
      source.value = source.value.remove('second');
      await tester.pumpAndSettle();
      expect(find.text('1 / 2'), findsOneWidget);
      source.value = source.value.upsert(
        Highlight(
          id: 'added',
          title: 'Remembered an earlier moment',
          date: DateTime(2020),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('3 / 3'), findsOneWidget);
      await tap(tester, key('edit-featured-highlight'));
      expect(edited, 'added');
      source.value = source.value.remove('added');
      await tester.pumpAndSettle();
      expect(find.text('2 / 2'), findsOneWidget);
      source.value = HighlightBook.empty;
      await tester.pumpAndSettle();
      expect(key('empty-highlights'), findsOneWidget);
      source.value = HighlightBook([
        Highlight(id: 'new', title: 'New moment', date: now),
      ]);
      await tester.pumpAndSettle();
      expect(key('highlight-new').hitTestable(), findsOneWidget);
      expect(key('highlight-position'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Empty Highlights offer Add and All without an empty carousel', (
    tester,
  ) async {
    var added = false;
    await tester.pumpWidget(
      shell(
        overview(highlights: HighlightBook.empty, onAdd: () => added = true),
      ),
    );
    expect(find.text('Keep a moment that matters.'), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
    await tap(tester, key('add-highlight'));
    expect(added, isTrue);
    expect(key('all-highlights'), findsOneWidget);
  });

  testWidgets(
    'Direct edit, manage Areas, Past Chapters and Daily history retain existing flows',
    (tester) async {
      await LocalStorage().save(
        DaylockState(
          areas: areas,
          highlights: moments,
          todayPlan: today,
          tomorrowPlan: DailyPlan(
            date: DateTime(2026, 10, 27),
            tasks: [],
            isCommitted: true,
          ),
          history: history,
        ),
      );
      await tester.pumpWidget(MainApp(now: () => now));
      await tester.pumpAndSettle();
      await navigateApp(tester, 'Journey');
      await tap(tester, key('edit-featured-highlight'));
      expect(find.byType(HighlightEditor), findsOneWidget);
      await tester.enterText(key('highlight-title'), 'A meal to remember');
      await tap(tester, key('save-highlight'));
      expect(
        (await LocalStorage().load())!.highlights.highlights.first.title,
        'A meal to remember',
      );
      await tap(tester, key('journey-manage-areas'));
      expect(find.byType(AreasScreen), findsOneWidget);
      await navigateApp(tester, 'Journey');
      await tap(tester, key('past-chapters'));
      expect(find.byType(PastChaptersScreen), findsOneWidget);
      expect(key('journey-area-past'), findsOneWidget);
      expect(key('journey-area-learn'), findsNothing);
      await navigateApp(tester, 'Calendar');
      final saved = (await LocalStorage().load())!;
      expect(saved.history.toJson(), history.toJson());
      expect(saved.tomorrowPlan.isCommitted, isTrue);
    },
  );

  for (final colour in ColourTheme.values) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'Configured colours and readable theme text in $colour $brightness',
        (tester) async {
          phone(tester);
          await tester.pumpWidget(
            shell(overview(), colour: colour, brightness: brightness),
          );
          await tester.pumpAndSettle();
          final icon = tester
              .widgetList<Icon>(
                find.descendant(
                  of: key('journey-area-learn'),
                  matching: find.byType(Icon),
                ),
              )
              .first;
          expect(icon.color, Color(areas.resolve('learn').colour));
          await tap(tester, key('next-highlight'));
          expect(find.text('2 / 3'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final scale in [1.0, 1.5, 2.0, 3.0]) {
    testWidgets(
      '320px compact layout supports $scale text, long names and many Areas',
      (tester) async {
        phone(tester, width: 320, height: 640);
        var book = areas.upsert(
          areas.defaultArea.copyWith(
            name: 'Personal relationships and meaningful experiences',
          ),
        );
        for (var i = 0; i < 7; i++) {
          book = book.upsert(custom('more-$i', 'An additional Area $i'));
        }
        await tester.pumpWidget(shell(overview(book: book), scale: scale));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          key('journey-area-${Area.defaultId}'),
          180,
          scrollable: vertical,
        );
        await tester.pumpAndSettle();
        final first = tester.getRect(key('journey-area-${Area.defaultId}'));
        final second = tester.getRect(key('journey-area-learn'));
        expect(
          scale > 1.5 ? second.top > first.top : second.top == first.top,
          isTrue,
        );
        await tester.scrollUntilVisible(
          key('daily-history'),
          220,
          scrollable: vertical,
          maxScrolls: 80,
        );
        await tester.pumpAndSettle();
        expect(key('daily-history').hitTestable(), findsOneWidget);
        await tap(tester, key('next-highlight'));
        expect(find.text('2 / 3'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Carousel buttons work with reduced motion and expose selected position semantics',
    (tester) async {
      phone(tester);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(shell(overview(), reducedMotion: true));
      await tap(tester, key('next-highlight'));
      expect(find.bySemanticsLabel('Highlight 2 of 3'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('.*Open Area')), findsNWidgets(4));
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
}

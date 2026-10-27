import 'package:daylock/main.dart';
import 'package:daylock/design/daylock_theme.dart';
import 'package:daylock/design/daylock_palette.dart';
import 'package:daylock/design/daylock_journey.dart';
import 'package:daylock/models/area.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/highlight.dart';
import 'package:daylock/models/plan_history.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/screens/area_journey_screen.dart';
import 'package:daylock/screens/calendar_screen.dart';
import 'package:daylock/screens/journey_screen.dart';
import 'package:daylock/screens/highlight_editor.dart';
import 'package:daylock/screens/plan_screen.dart';
import 'package:daylock/services/journey_service.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'navigation_helpers.dart';

final now = DateTime(2026, 10, 26, 18);
final area = Area.create(
  name: 'Learning',
  icon: 'learning',
  colour: Area.defaultColour,
  now: now,
);
final book = AreaBook.initial(createdAt: now).upsert(area);
final milestone = Highlight.create(
  title: 'Passed my certification',
  date: now,
  description: 'A new chapter',
  areaId: area.id,
);
DaylockState fixture({bool archived = false}) => DaylockState(
  areas: archived ? book.archive(area.id, true) : book,
  highlights: HighlightBook([milestone]),
  todayPlan: DailyPlan(date: now, tasks: []),
  tomorrowPlan: DailyPlan(
    date: DateTime(2026, 10, 27),
    tasks: [Task(name: 'Tomorrow', type: TaskType.goal)],
    isCommitted: true,
  ),
  history: PlanHistory.empty.archive(
    DailyPlan(
      date: DateTime(2026, 10, 25),
      tasks: [
        Task(
          name: 'Read chapter',
          type: TaskType.focus,
          minimumFocusMinutes: 30,
          accumulatedFocusMilliseconds: 1800000,
          areaId: area.id,
        ),
        Task(
          name: 'Practice',
          type: TaskType.goal,
          outcome: TaskOutcome.excused,
          excuseReason: 'Unavailable',
          areaId: area.id,
        ),
      ],
    ),
  ),
);
Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.pumpAndSettle();
  if (finder.evaluate().isEmpty) {
    final scrollable = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(
      finder,
      220,
      scrollable: scrollable,
      maxScrolls: 60,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> launch(WidgetTester tester, [DaylockState? state]) async {
  if (state != null) await LocalStorage().save(state);
  await tester.pumpWidget(MainApp(now: () => now));
  await tester.pumpAndSettle();
  await navigateApp(tester, 'Journey');
}

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );
  testWidgets(
    'Three destinations and empty Journey lead to fully preserved Calendar',
    (tester) async {
      await launch(tester);
      expect(
        tester
            .widgetList<NavigationDestination>(
              find.byType(NavigationDestination),
            )
            .map((d) => d.label),
        ['Today', 'Plan', 'Journey'],
      );
      expect(
        find.byKey(const ValueKey('journey-effort-summary')),
        findsOneWidget,
      );
      expect(find.text('Life'), findsOneWidget);
      expect(find.text('Open space'), findsOneWidget);
      expect(find.text('Keep a moment that matters.'), findsOneWidget);
      await navigateApp(tester, 'Calendar');
      expect(find.byType(CalendarScreen), findsOneWidget);
      expect(find.byTooltip('Calendar accounts'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(JourneyScreen), findsOneWidget);
    },
  );

  testWidgets(
    'Area detail counts, Focus, range and selected-day history preserve locked plans',
    (tester) async {
      final initial = fixture();
      await launch(tester, initial);
      await tap(tester, find.byKey(ValueKey('journey-area-${area.id}')));
      expect(find.text('1 completed commitment'), findsOneWidget);
      expect(find.text('30 min recorded Focus'), findsOneWidget);
      expect(find.byType(JourneyActivityChart), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('journey-alltime')));
      await tap(tester, find.byKey(const ValueKey('area-records')));
      await tap(tester, find.text('Read chapter'));
      expect(find.byType(CalendarScreen), findsOneWidget);
      expect(find.text('Read chapter'), findsOneWidget);
      expect(find.text('Sunday, October 25, 2026'), findsOneWidget);
      expect(
        (await LocalStorage().load())!.history.toJson(),
        initial.history.toJson(),
      );
      await navigateApp(tester, 'Plan');
      final plan = tester.widget<PlanScreen>(find.byType(PlanScreen));
      expect(plan.plan.isCommitted, isTrue);
      expect(find.byKey(const ValueKey('edit-task-area-0')), findsNothing);
      expect(
        (await LocalStorage().load())!.tomorrowPlan.toJson(),
        initial.tomorrowPlan.toJson(),
      );
    },
  );

  testWidgets(
    'Highlight without an Area creates, edits date and description, survives restart, and deletes with confirmation',
    (tester) async {
      await launch(tester);
      await tap(tester, find.byKey(const ValueKey('add-highlight')));
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('save-highlight')))
            .onPressed,
        isNull,
      );
      await tester.enterText(
        find.byKey(const ValueKey('highlight-title')),
        'Cooked my first meal',
      );
      await tester.enterText(
        find.byKey(const ValueKey('highlight-description')),
        'Shared it with friends',
      );
      await tap(tester, find.byKey(const ValueKey('save-highlight')));
      var saved = (await LocalStorage().load())!.highlights.highlights.single;
      expect(saved.areaId, isNull);
      final id = saved.id;
      await tap(tester, find.byKey(ValueKey('highlight-$id')));
      expect(find.text('Shared it with friends'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('edit-highlight')));
      await tester.enterText(
        find.byKey(const ValueKey('highlight-title')),
        'Cooked a proper meal',
      );
      await tap(tester, find.byKey(const ValueKey('highlight-date')));
      await tap(tester, find.text('25').last);
      await tap(tester, find.text('OK'));
      await tap(tester, find.byKey(const ValueKey('save-highlight')));
      saved = (await LocalStorage().load())!.highlights.highlights.single;
      expect(saved.id, id);
      expect(saved.date, DateTime(2026, 10, 25));
      await tester.pumpWidget(const SizedBox());
      await launch(tester);
      await tap(tester, find.byKey(ValueKey('highlight-$id')));
      expect(find.text('Cooked a proper meal'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('delete-highlight')));
      await tap(tester, find.text('Keep Highlight'));
      expect(
        (await LocalStorage().load())!.highlights.highlights,
        hasLength(1),
      );
      await tap(tester, find.byKey(const ValueKey('delete-highlight')));
      await tap(tester, find.byKey(const ValueKey('confirm-delete-highlight')));
      expect((await LocalStorage().load())!.highlights.highlights, isEmpty);
      expect(find.byType(JourneyScreen), findsOneWidget);
    },
  );

  testWidgets(
    'Optional Area selection and unknown Highlight links remain usable',
    (tester) async {
      final original = fixture().toJson()
        ..['highlights'] = HighlightBook([
          Highlight.create(title: 'Travel', date: now, areaId: 'missing'),
        ]).toJson();
      await launch(tester, DaylockState.fromJson(original));
      expect(find.textContaining('Area unavailable'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('add-highlight')));
      await tester.enterText(
        find.byKey(const ValueKey('highlight-title')),
        'Learned a new language',
      );
      await tap(tester, find.byKey(const ValueKey('highlight-link-area')));
      await tap(tester, find.byKey(const ValueKey('select-area')));
      await tap(tester, find.byKey(ValueKey('choose-area-${area.id}')));
      await tap(tester, find.byKey(const ValueKey('save-highlight')));
      final saved = (await LocalStorage().load())!;
      expect(saved.highlights.highlights.last.areaId, area.id);
      await tap(tester, find.byKey(const ValueKey('all-highlights')));
      expect(find.text('Travel'), findsOneWidget);
      expect(find.text('Learned a new language'), findsOneWidget);
    },
  );

  testWidgets(
    'Past Chapter retains records and Highlights; restore returns it to active Areas',
    (tester) async {
      final initial = fixture(archived: true);
      await launch(tester, initial);
      await tap(tester, find.byKey(const ValueKey('past-chapters')));
      await tap(tester, find.byKey(ValueKey('journey-area-${area.id}')));
      expect(
        tester
            .widget<AreaJourneyScreen>(find.byType(AreaJourneyScreen))
            .area
            .isArchived,
        isTrue,
      );
      expect(find.text('1 completed commitment'), findsOneWidget);
      await tap(tester, find.byKey(ValueKey('highlight-${milestone.id}')));
      expect(find.text('A new chapter'), findsOneWidget);
      await navigateApp(tester, 'Today');
      await tap(tester, find.byTooltip('Settings'));
      await tap(tester, find.byKey(const ValueKey('manage-areas')));
      await tap(tester, find.byKey(ValueKey('archive-area-${area.id}')));
      await navigateApp(tester, 'Journey');
      final journey = tester.widget<JourneyScreen>(find.byType(JourneyScreen));
      expect(journey.areas.active.map((a) => a.id), contains(area.id));
      expect(find.text('PAST CHAPTERS'), findsNothing);
      expect(journey.data.forArea(area.id).completedCount, 1);
      final saved = (await LocalStorage().load())!;
      expect(saved.history.toJson(), initial.history.toJson());
      expect(saved.highlights.toJson(), initial.highlights.toJson());
    },
  );

  testWidgets(
    'Highlight cancellation writes nothing; failed save retains prior data and Retry persists once',
    (tester) async {
      final initial = fixture();
      await LocalStorage().save(initial);
      final storage = _FailingStorage();
      await tester.pumpWidget(MainApp(storage: storage, now: () => now));
      await tester.pumpAndSettle();
      await navigateApp(tester, 'Journey');
      await tap(tester, find.byKey(const ValueKey('add-highlight')));
      await tester.enterText(
        find.byKey(const ValueKey('highlight-title')),
        'A memorable day',
      );
      await tap(tester, find.byTooltip('Close editor'));
      expect((await LocalStorage().load())!.toJson(), initial.toJson());
      await tap(tester, find.byKey(const ValueKey('add-highlight')));
      await tester.enterText(
        find.byKey(const ValueKey('highlight-title')),
        'A memorable day',
      );
      await tap(tester, find.byKey(const ValueKey('save-highlight')));
      expect(find.text('Could not save your changes.'), findsOneWidget);
      expect((await LocalStorage().load())!.toJson(), initial.toJson());
      storage.fail = false;
      await tap(tester, find.text('Retry'));
      final saved = (await LocalStorage().load())!;
      expect(saved.highlights.highlights, hasLength(2));
      expect(saved.todayPlan.toJson(), initial.todayPlan.toJson());
      expect(saved.tomorrowPlan.toJson(), initial.tomorrowPlan.toJson());
      expect(saved.freedomSettings.toJson(), initial.freedomSettings.toJson());
    },
  );

  testWidgets(
    'Highlight editor supports large text and keyboard with optional Area',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: DaylockTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              viewInsets: const EdgeInsets.only(bottom: 220),
            ),
            child: child!,
          ),
          home: Scaffold(
            resizeToAvoidBottomInset: false,
            body: HighlightEditor(areas: book, now: now),
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('highlight-title')),
        'A long and meaningful personal achievement',
      );
      await tap(tester, find.byKey(const ValueKey('highlight-link-area')));
      await tap(tester, find.byKey(const ValueKey('select-area')));
      await tap(tester, find.byKey(ValueKey('choose-area-${area.id}')));
      final save = find.byKey(const ValueKey('save-highlight'));
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      expect(save.hitTestable(), findsOneWidget);
      expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

  for (final brightness in Brightness.values) {
    for (final scale in [1.0, 2.0, 3.0]) {
      testWidgets(
        'Journey and Area detail fit 320px at $scale in $brightness',
        (tester) async {
          tester.view.physicalSize = const Size(320, 720);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final snapshot = fixture();
          final longArea = area.copyWith(
            name: 'Learning and personal creative exploration',
          );
          final longBook = book.upsert(longArea);
          final data = JourneyData(
            areas: longBook,
            history: snapshot.history,
            todayPlan: snapshot.todayPlan,
            now: now,
          );
          Widget shell(Widget child) => MaterialApp(
            theme: DaylockTheme.forPalette(ColourTheme.violet, brightness),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: child,
          );
          await tester.pumpWidget(
            shell(
              Scaffold(
                body: JourneyScreen(
                  areas: longBook,
                  highlights: snapshot.highlights,
                  data: data,
                  onAreaOpened: (_) {},
                  onHighlightOpened: (_) {},
                  onAddHighlight: () {},
                  onAllHighlights: () {},
                  onDailyHistory: () {},
                ),
              ),
            ),
          );
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('daily-history')),
            220,
            scrollable: find.descendant(
              of: find.byKey(const ValueKey('journey-content')),
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Scrollable &&
                    widget.axisDirection == AxisDirection.down,
              ),
            ),
            maxScrolls: 40,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(
            shell(
              AreaJourneyScreen(
                area: longArea,
                areas: longBook,
                data: data,
                highlights: snapshot.highlights,
                onHighlightOpened: (_) {},
                onDayOpened: (_) {},
                onAddHighlight: () {},
              ),
            ),
          );
          await tester.scrollUntilVisible(
            find.byType(JourneyActivityChart),
            220,
            maxScrolls: 40,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('area-records')),
            220,
            maxScrolls: 40,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

class _FailingStorage extends LocalStorage {
  bool fail = true;
  @override
  Future<void> save(DaylockState state) =>
      fail ? Future.error(StateError('Test save failure')) : super.save(state);
}

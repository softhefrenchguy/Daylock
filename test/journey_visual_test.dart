import 'dart:convert';

import 'package:daylock/design/highlight_illustration.dart';
import 'package:daylock/design/journey_activity_strip.dart';
import 'package:daylock/main.dart';
import 'package:daylock/models/area.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/highlight.dart';
import 'package:daylock/models/highlight_illustration.dart';
import 'package:daylock/models/plan_history.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/services/journey_service.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:daylock/screens/highlight_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'journey_redesign_test.dart' as fixture;
import 'navigation_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  for (final scale in [1.0, 3.0]) {
    testWidgets(
      'Long Highlight text and illustration picker fit 320px at $scale',
      (tester) async {
        fixture.phone(tester, width: 320, height: 640);
        final title = List.filled(12, 'Milestone').join(' ');
        final highlights = HighlightBook([
          Highlight(
            id: 'long',
            title: title,
            date: fixture.now,
            description: List.filled(200, 'A memory.').join(' '),
          ),
        ]);
        await tester.pumpWidget(
          fixture.shell(fixture.overview(highlights: highlights), scale: scale),
        );
        await tester.scrollUntilVisible(
          fixture.key('featured-highlights'),
          200,
          scrollable: fixture.vertical,
        );
        await tester.pumpAndSettle();
        expect(fixture.key('highlight-illustration-long'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(
          fixture.shell(
            HighlightEditor(
              areas: fixture.areas,
              highlight: highlights.highlights.single,
              now: fixture.now,
            ),
            scale: scale,
          ),
        );
        await fixture.tap(tester, fixture.key('select-highlight-illustration'));
        await fixture.tap(tester, fixture.key('highlight-icon-travel'));
        await tester.ensureVisible(fixture.key('save-highlight'));
        await tester.pumpAndSettle();
        expect(fixture.key('save-highlight').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final sample in <String, String>{
    'Got my DRIVING licence!': 'driving',
    'Passed my certification exam': 'award',
    'Cooked my first meal': 'cooking',
    'Holiday flight booked': 'travel',
    'New strength record at the gym': 'fitness',
    'A quiet afternoon': 'celebration',
  }.entries) {
    test('Offline illustration suggestion: ${sample.key}', () {
      expect(resolveHighlightIllustration(title: sample.key), sample.value);
      expect(resolveHighlightIllustration(title: sample.key), sample.value);
    });
  }
  test(
    'Explicit, title, Area and generic priority; whole words and unknown IDs',
    () {
      expect(
        resolveHighlightIllustration(
          title: 'Driving exam',
          explicitIcon: 'cooking',
          areaIcon: 'fitness',
        ),
        'cooking',
      );
      expect(
        resolveHighlightIllustration(
          title: 'Driving exam',
          areaIcon: 'fitness',
        ),
        'driving',
      );
      expect(
        resolveHighlightIllustration(
          title: 'A quiet afternoon',
          areaIcon: 'health',
        ),
        'health',
      );
      expect(
        resolveHighlightIllustration(
          title: 'A quiet afternoon',
          areaIcon: 'missing',
        ),
        'celebration',
      );
      expect(
        resolveHighlightIllustration(
          title: 'Carpet installed',
          areaIcon: 'home',
        ),
        'home',
      );
      expect(
        resolveHighlightIllustration(
          title: 'A new car',
          explicitIcon: 'future-icon',
        ),
        'driving',
      );
      expect(
        resolveHighlightIllustration(title: 'يوم جميل', areaIcon: 'life'),
        'life',
      );
    },
  );
  test(
    'Legacy Highlights and unknown optional artwork metadata remain readable',
    () {
      final legacy = fixture.moments.highlights.first.toJson();
      expect(legacy.containsKey('illustrationIcon'), isFalse);
      final old = Highlight.fromJson(legacy);
      expect(old.illustrationIcon, isNull);
      expect(old.toJson(), legacy);
      final future = Highlight.fromJson({
        ...legacy,
        'illustrationIcon': 'future-icon',
      });
      expect(future.toJson()['illustrationIcon'], 'future-icon');
      expect(
        Highlight.fromJson({...legacy, 'illustrationIcon': 42})
            .illustrationIcon,
        isNull,
      );
    },
  );
  test('Explicit artwork survives storage, title changes and rollover without touching history', () async {
    final original = Highlight.create(
      title: 'Driving licence',
      date: fixture.now,
      areaId: 'cook',
      illustrationIcon: 'award',
    );
    final state = DaylockState(
      todayPlan: fixture.today,
      tomorrowPlan: DailyPlan(date: DateTime(2026, 10, 27), tasks: []),
      areas: fixture.areas,
      history: fixture.history,
      highlights: HighlightBook([original]),
    );
    await LocalStorage().save(state);
    final loaded = (await LocalStorage().load())!;
    expect(loaded.highlights.highlights.single.illustrationIcon, 'award');
    final edited = Highlight(
      id: original.id,
      title: 'Cooked a meal',
      date: original.date,
      areaId: original.areaId,
      illustrationIcon: loaded.highlights.highlights.single.illustrationIcon,
    );
    final updated = DaylockState.fromJson({
      ...loaded.toJson(),
      'highlights': [edited.toJson()],
    });
    await LocalStorage().save(updated);
    final restarted = (await LocalStorage().load())!;
    expect(
      resolveHighlightIllustration(
        title: restarted.highlights.highlights.single.title,
        explicitIcon: restarted.highlights.highlights.single.illustrationIcon,
      ),
      'award',
    );
    expect(restarted.history.toJson(), state.history.toJson());
    expect(restarted.areas.toJson(), state.areas.toJson());
    expect(restarted.todayPlan.toJson(), state.todayPlan.toJson());
    expect(
      restarted
          .rollOver(DateTime(2026, 10, 27))
          .highlights
          .highlights
          .single
          .illustrationIcon,
      'award',
    );
  });
  test(
    'Loading older saved state does not rewrite or discard existing Highlights',
    () async {
      final state = DaylockState(
        todayPlan: fixture.today,
        tomorrowPlan: DailyPlan(date: DateTime(2026, 10, 27), tasks: []),
        areas: fixture.areas,
        history: fixture.history,
        highlights: fixture.moments,
      );
      final encoded = jsonEncode(state.toJson());
      await SharedPreferencesAsync().setString(LocalStorage.stateKey, encoded);
      final loaded = (await LocalStorage().load())!;
      expect(loaded.highlights.toJson(), fixture.moments.toJson());
      expect(
        await SharedPreferencesAsync().getString(LocalStorage.stateKey),
        encoded,
      );
    },
  );

  testWidgets(
    'Area charts show exact real 30-day buckets; empty and Highlight-only Areas have no bars',
    (tester) async {
      fixture.phone(tester);
      await tester.pumpWidget(fixture.shell(fixture.overview()));
      await tester.pumpAndSettle();
      final focus = tester.widget<JourneyActivityStrip>(
        fixture.key('area-activity-learn'),
      );
      final goals = tester.widget<JourneyActivityStrip>(
        fixture.key('area-activity-health'),
      );
      expect(focus.usesFocus, isTrue);
      expect(focus.values.fold<int>(0, (sum, n) => sum + n), 120000);
      expect(goals.usesFocus, isFalse);
      expect(goals.values.fold<int>(0, (sum, n) => sum + n), 1);
      expect(fixture.key('area-activity-cook'), findsNothing);
      expect(fixture.key('area-activity-${Area.defaultId}'), findsNothing);
      for (var i = 0; i < focus.values.length; i++) {
        final bar = find.descendant(
          of: fixture.key('area-activity-learn'),
          matching: fixture.key('activity-bar-$i'),
        );
        expect(tester.getSize(bar).height, focus.values[i] == 0 ? 0 : 28);
      }
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Old effort remains in totals but never creates recent activity bars',
    (tester) async {
      final history = PlanHistory.empty.archive(
        DailyPlan(
          date: DateTime(2026, 8, 1),
          tasks: [
            Task(
              name: 'Earlier study',
              type: TaskType.focus,
              areaId: 'learn',
              accumulatedFocusMilliseconds: 60000,
            ),
          ],
        ),
      );
      final data = JourneyData(
        areas: fixture.areas,
        history: history,
        todayPlan: DailyPlan(date: fixture.now, tasks: []),
        now: fixture.now,
      );
      await tester.pumpWidget(fixture.shell(fixture.overview(journey: data)));
      expect(
        find.descendant(
          of: fixture.key('journey-area-learn'),
          matching: find.text('1 min recorded'),
        ),
        findsOneWidget,
      );
      expect(find.byType(JourneyActivityStrip), findsNothing);
    },
  );
  testWidgets(
    'Decorative artwork handles unassigned, unknown and Area-linked Highlights',
    (tester) async {
      fixture.phone(tester);
      final highlights = HighlightBook([
        Highlight(id: 'a', title: 'An ordinary delight', date: fixture.now),
        Highlight(
          id: 'b',
          title: 'A new perspective',
          date: fixture.now,
          areaId: 'learn',
        ),
        Highlight(
          id: 'c',
          title: 'A new perspective',
          date: fixture.now,
          areaId: 'missing',
        ),
      ]);
      await tester.pumpWidget(
        fixture.shell(fixture.overview(highlights: highlights)),
      );
      await tester.pumpAndSettle();
      String artwork(String id) => tester
          .widget<HighlightIllustration>(
            fixture.key('highlight-illustration-$id'),
          )
          .iconId;
      expect(artwork('a'), 'celebration');
      await fixture.tap(tester, fixture.key('next-highlight'));
      expect(artwork('b'), 'learning');
      await fixture.tap(tester, fixture.key('next-highlight'));
      expect(artwork('c'), 'celebration');
      expect(find.textContaining('Area unavailable'), findsOneWidget);
    },
  );
  testWidgets(
    'Create, override, edit and reset artwork through the existing persistence flow',
    (tester) async {
      fixture.phone(tester);
      await LocalStorage().save(
        DaylockState(
          todayPlan: fixture.today,
          tomorrowPlan: DailyPlan(date: DateTime(2026, 10, 27), tasks: []),
          areas: fixture.areas,
          history: fixture.history,
        ),
      );
      await tester.pumpWidget(MainApp(now: () => fixture.now));
      await tester.pumpAndSettle();
      await navigateApp(tester, 'Journey');
      await fixture.tap(tester, fixture.key('add-highlight'));
      await tester.enterText(fixture.key('highlight-title'), 'Driving licence');
      await fixture.tap(tester, fixture.key('select-highlight-illustration'));
      await fixture.tap(tester, fixture.key('highlight-icon-award'));
      await fixture.tap(tester, fixture.key('save-highlight'));
      var saved = (await LocalStorage().load())!;
      expect(saved.highlights.highlights.single.illustrationIcon, 'award');
      final id = saved.highlights.highlights.single.id;
      await fixture.tap(tester, fixture.key('edit-featured-highlight'));
      await tester.enterText(fixture.key('highlight-title'), 'Cooked a meal');
      await fixture.tap(tester, fixture.key('save-highlight'));
      saved = (await LocalStorage().load())!;
      expect(saved.highlights.highlights.single.id, id);
      expect(saved.highlights.highlights.single.illustrationIcon, 'award');
      await fixture.tap(tester, fixture.key('edit-featured-highlight'));
      await fixture.tap(tester, fixture.key('select-highlight-illustration'));
      await fixture.tap(tester, fixture.key('highlight-icon-automatic'));
      await fixture.tap(tester, fixture.key('save-highlight'));
      saved = (await LocalStorage().load())!;
      expect(saved.highlights.highlights.single.illustrationIcon, isNull);
      expect(
        tester
            .widget<HighlightIllustration>(
              fixture.key('highlight-illustration-$id'),
            )
            .iconId,
        'cooking',
      );
      expect(saved.history.toJson(), fixture.history.toJson());
      expect(saved.todayPlan.toJson(), fixture.today.toJson());
      await tester.pumpWidget(const SizedBox());
    },
  );
}

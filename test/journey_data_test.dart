import 'dart:convert';

import 'package:daylock/models/area.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/highlight.dart';
import 'package:daylock/models/plan_history.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/services/journey_service.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final now = DateTime(2026, 10, 26, 18);
final study = Area.create(
  name: 'Learning',
  icon: 'learning',
  colour: Area.defaultColour,
  now: now,
);
AreaBook get areas => AreaBook.initial(createdAt: now).upsert(study);
Task goal({
  String? areaId = Area.defaultId,
  TaskOutcome outcome = TaskOutcome.completed,
}) => Task(
  name: 'Goal',
  type: TaskType.goal,
  areaId: areaId,
  outcome: outcome,
  excuseReason: outcome == TaskOutcome.excused ? 'Unavailable' : null,
);
Task focus(
  int milliseconds, {
  TaskOutcome outcome = TaskOutcome.incomplete,
  DateTime? started,
}) => Task(
  name: 'Read',
  type: TaskType.focus,
  minimumFocusMinutes: 1,
  areaId: study.id,
  accumulatedFocusMilliseconds: milliseconds,
  outcome: outcome,
  focusStartedAt: started,
  excuseReason: outcome == TaskOutcome.excused ? 'Unavailable' : null,
);
DaylockState state({
  HighlightBook highlights = HighlightBook.empty,
  PlanHistory history = PlanHistory.empty,
}) => DaylockState(
  areas: areas,
  highlights: highlights,
  history: history,
  todayPlan: DailyPlan(date: now, tasks: [goal()], isCommitted: true),
  tomorrowPlan: DailyPlan(
    date: DateTime(2026, 10, 27),
    tasks: [goal()],
    isCommitted: true,
  ),
);
JourneyData data({
  PlanHistory history = PlanHistory.empty,
  List<Task> live = const [],
  AreaBook? book,
  DateTime? clock,
}) => JourneyData(
  areas: book ?? areas,
  history: history,
  todayPlan: DailyPlan(date: clock ?? now, tasks: live),
  now: clock ?? now,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  test('Counts completed outcomes only; Goals never invent Focus time', () {
    final tasks = [
      goal(),
      goal(areaId: study.id),
      goal(areaId: study.id, outcome: TaskOutcome.excused),
      goal(areaId: study.id, outcome: TaskOutcome.incomplete),
      focus(120000, outcome: TaskOutcome.completed),
      focus(15000),
      focus(5000, outcome: TaskOutcome.excused),
    ];
    final result = data(live: tasks);
    expect(result.forArea(Area.defaultId).completedCount, 1);
    expect(result.forArea(Area.defaultId).focusMilliseconds, 0);
    expect(result.forArea(study.id).completedCount, 2);
    expect(result.forArea(study.id).focusMilliseconds, 140000);
    expect(result.forArea(study.id).records, hasLength(6));
  });

  test('Snapshot wins duplicate date and future records never contribute', () {
    final history = PlanHistory.empty
        .archive(
          DailyPlan(
            date: now,
            tasks: [focus(60000, outcome: TaskOutcome.completed)],
          ),
        )
        .archive(
          DailyPlan(
            date: DateTime(2026, 10, 27),
            tasks: [focus(999999, outcome: TaskOutcome.completed)],
          ),
        );
    final before = history.toJson();
    final result = data(
      history: history,
      live: [
        goal(areaId: study.id),
        focus(120000),
      ],
    );
    expect(result.forArea(study.id).completedCount, 1);
    expect(result.forArea(study.id).focusMilliseconds, 60000);
    expect(result.records, hasLength(1));
    expect(history.toJson(), before);
  });

  test('Same-name commitments are distinct, running time is not extrapolated or mutated', () {
    final running = focus(
      12000,
      started: now.subtract(const Duration(minutes: 10)),
    );
    final before = running.toJson();
    final history = PlanHistory.empty.archive(
      DailyPlan(date: DateTime(2026, 10, 25), tasks: [goal(), goal()]),
    );
    final result = data(history: history, live: [goal(), running]);
    expect(result.forArea(Area.defaultId).completedCount, 3);
    expect(result.forArea(study.id).focusMilliseconds, 12000);
    expect(running.toJson(), before);
    expect(
      result.records.map((r) => '${r.date}:${r.taskIndex}').toSet(),
      hasLength(4),
    );
  });

  test('Legacy and unknown references resolve to renamed default; archived identity survives restore', () {
    var book = areas
        .upsert(areas.defaultArea.copyWith(name: 'Everyday'))
        .archive(study.id, true);
    final old = PlanHistory.empty.archive(
      DailyPlan(
        date: DateTime(2026, 10, 25),
        tasks: [
          goal(areaId: null),
          goal(areaId: 'unavailable'),
          goal(areaId: study.id),
        ],
      ),
    );
    final before = old.toJson();
    expect(
      data(
        history: old,
        book: book,
      ).forArea(book.defaultArea.id).completedCount,
      2,
    );
    expect(data(history: old, book: book).forArea(study.id).completedCount, 1);
    book = book.archive(study.id, false);
    expect(data(history: old, book: book).forArea(study.id).completedCount, 1);
    expect(old.toJson(), before);
  });

  test('30 days includes today and 29 prior calendar dates; all-time buckets conserve totals', () {
    var history = PlanHistory.empty;
    for (final date in [
      DateTime(2025, 1, 1),
      DateTime(2026, 9, 26),
      DateTime(2026, 9, 27),
      DateTime(2026, 10, 25),
    ]) {
      history = history.archive(
        DailyPlan(
          date: date,
          tasks: [focus(60000, outcome: TaskOutcome.completed)],
        ),
      );
    }
    final result = data(
      history: history,
      live: [focus(60000, outcome: TaskOutcome.completed)],
    );
    expect(result.last30Start, DateTime(2026, 9, 27));
    expect(result.forArea(study.id, last30Days: true).completedCount, 3);
    expect(result.forArea(study.id).completedCount, 5);
    for (final last30 in [true, false]) {
      final buckets = result.activity(study.id, last30Days: last30);
      expect(buckets.length, lessThanOrEqualTo(8));
      expect(
        buckets.fold<int>(0, (sum, b) => sum + b.summary.completedCount),
        last30 ? 3 : 5,
      );
      expect(
        buckets.fold<int>(0, (sum, b) => sum + b.summary.focusMilliseconds),
        (last30 ? 3 : 5) * 60000,
      );
      expect(buckets.last.through, DateTime(2026, 10, 26));
      for (var i = 1; i < buckets.length; i++) {
        final prior = buckets[i - 1].through;
        expect(
          buckets[i].from,
          DateTime(prior.year, prior.month, prior.day + 1),
        );
      }
    }
  });

  test('Empty data and sub-minute Focus are honest', () {
    final result = data();
    expect(result.records, isEmpty);
    expect(result.forArea(Area.defaultId).completedCount, 0);
    expect(result.activity(Area.defaultId, last30Days: false), isNotEmpty);
    expect(journeyFocusLabel(0), '0 min');
    expect(journeyFocusLabel(1234), '<1 min');
    expect(journeyFocusLabel(3660000), '1 hr 1 min');
  });

  test('Highlight CRUD, nullable Area and archived associations persist through restart and rollover', () async {
    final personal = Highlight.create(
      title: ' First proper meal ',
      date: now,
      description: ' With friends ',
    );
    final linked = Highlight.create(
      title: 'Passed certification',
      date: DateTime(2026, 10, 25),
      areaId: study.id,
    );
    final initial = state(highlights: HighlightBook([personal, linked]));
    await LocalStorage().save(initial);
    var restored = (await LocalStorage().load())!;
    expect(restored.highlights.highlights.first.title, 'First proper meal');
    expect(restored.highlights.highlights.first.areaId, isNull);
    expect(restored.highlights.highlights.first.description, 'With friends');
    final revised = Highlight(
      id: linked.id,
      title: 'Celebrated certification',
      date: now,
      description: 'A milestone',
      areaId: study.id,
    );
    final updated = restored.toJson()
      ..['highlights'] = restored.highlights
          .upsert(revised)
          .remove(personal.id)
          .toJson()
      ..['areas'] = restored.areas.archive(study.id, true).toJson();
    await LocalStorage().save(DaylockState.fromJson(updated));
    restored = (await LocalStorage().load())!;
    expect(restored.highlights.highlights.single.toJson(), revised.toJson());
    expect(restored.areas.resolve(revised.areaId).isArchived, isTrue);
    expect(
      restored.rollOver(DateTime(2026, 10, 27)).highlights.toJson(),
      restored.highlights.toJson(),
    );
    expect(restored.todayPlan.toJson(), initial.todayPlan.toJson());
    expect(restored.tomorrowPlan.toJson(), initial.tomorrowPlan.toJson());
  });

  test('Phase 1 migration adds only Highlights and is idempotent', () async {
    final original = state(
      history: PlanHistory.empty.archive(
        DailyPlan(date: DateTime(2026, 10, 25), tasks: [goal(areaId: null)]),
      ),
    ).toJson()..remove('highlights');
    final preferences = SharedPreferencesAsync();
    await preferences.setString(LocalStorage.stateKey, jsonEncode(original));
    final loaded = (await LocalStorage().load())!;
    expect(loaded.highlights.highlights, isEmpty);
    final saved = jsonDecode(
      (await preferences.getString(LocalStorage.stateKey))!,
    ) as Map;
    for (final key in original.keys) {
      expect(saved[key], original[key], reason: key);
    }
    final raw = await preferences.getString(LocalStorage.stateKey);
    await LocalStorage().load();
    expect(await preferences.getString(LocalStorage.stateKey), raw);
  });

  test('Missing Area links remain personal records instead of being assigned to Life', () {
    for (final id in [null, '', 22, 'missing']) {
      final json = Highlight.create(title: 'Trip', date: now).toJson()
        ..['areaId'] = id;
      final restored = Highlight.fromJson(json);
      expect(restored.areaId, id == 'missing' ? 'missing' : null);
    }
  });

  test(
    'Invalid Highlights fail safely without overwriting existing save',
    () async {
      final personal = Highlight.create(title: 'Trip', date: now);
      expect(() => HighlightBook([personal, personal]), throwsFormatException);
      expect(
        () => Highlight.create(title: ' ', date: now),
        throwsFormatException,
      );
      expect(
        () => Highlight.fromJson(personal.toJson()..['date'] = '2026-02-30'),
        throwsFormatException,
      );
      final raw = jsonEncode(
        state().toJson()..['highlights'] = [personal.toJson()..['title'] = ''],
      );
      final preferences = SharedPreferencesAsync();
      await preferences.setString(LocalStorage.stateKey, raw);
      await expectLater(LocalStorage().load(), throwsFormatException);
      expect(await preferences.getString(LocalStorage.stateKey), raw);
    },
  );
}

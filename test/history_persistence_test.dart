import 'dart:convert';

import 'package:daylock/design/appearance_preferences.dart';
import 'package:daylock/design/daylock_palette.dart';
import 'package:daylock/main.dart';
import 'package:daylock/models/calendar_account.dart';
import 'package:daylock/models/calendar_cache.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/event.dart';
import 'package:daylock/models/plan_history.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/screens/today_screen.dart';
import 'package:daylock/services/appearance_storage.dart';
import 'package:daylock/services/calendar_credentials.dart';
import 'package:daylock/services/calendar_service.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'calendar_test_fixtures.dart';

final _day = DateTime(2026, 10, 7);
DaylockState _state({PlanHistory history = PlanHistory.empty}) {
  final accounts = [
    for (final provider in CalendarProviderType.values) testAccount(provider),
  ];
  return DaylockState(
    history: history,
    todayPlan: DailyPlan(
      date: _day,
      isCommitted: true,
      tasks: [
        Task(name: 'Done goal', type: TaskType.goal, isCompleted: true),
        Task(
          name: 'Interrupted focus',
          type: TaskType.focus,
          minimumFocusMinutes: 30,
          focusTarget: 'Finish the chapter',
          accumulatedFocusMilliseconds: 4001,
          focusStartedAt: DateTime(2026, 10, 7, 23, 50),
        ),
      ],
    ),
    tomorrowPlan: DailyPlan(
      date: DateTime(2026, 10, 8),
      isCommitted: true,
      tasks: [Task(name: 'Next day goal', type: TaskType.goal)],
    ),
    events: [
      Event(
        id: 'local',
        title: 'Lesson',
        date: DateTime(2026, 10, 8),
        startTime: EventTime(10, 0),
      ),
    ],
    calendarCache: CalendarCache(
      accounts: accounts,
      calendars: [
        for (final account in accounts)
          testCalendar(
            account,
            visible: account.provider != CalendarProviderType.microsoftPersonal,
          ),
      ],
      events: [for (final account in accounts) testExternal(account)],
    ),
  );
}

Future<DaylockState> _saved(WidgetTester tester) async =>
    (await tester.runAsync<DaylockState?>(() => LocalStorage().load()))!;
void _resume(WidgetTester tester) {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  test('Existing v2 data migrates only an empty history without changing real plans or other storage', () async {
    final prefs = SharedPreferencesAsync();
    final state = _state();
    final old = state.toJson()..remove('history');
    await prefs.setString(LocalStorage.stateKey, jsonEncode(old));
    const appearance = AppearancePreferences(
      mode: AppearanceMode.system,
      colour: ColourTheme.ocean,
    );
    await AppearanceStorage().save(appearance);
    final appearanceBefore = await prefs.getString(AppearanceStorage.key);
    await prefs.setString('unrelated', 'keep');
    final credentials = MemoryCredentials();
    for (final account in state.calendarCache.accounts) {
      await credentials.write(
        account.id,
        CalendarCredentials(
          accessToken: 'private-access',
          refreshToken: 'private-refresh',
        ),
      );
    }
    final tokens = Map.of(credentials.values);
    final restored = (await LocalStorage().load())!;
    expect(restored.history.plans, isEmpty);
    expect(restored.toJson(), {...old, 'history': []});
    expect(
      restored.todayPlan.tasks.last.focusStartedAt,
      state.todayPlan.tasks.last.focusStartedAt,
    );
    expect(restored.todayPlan.tasks.last.accumulatedFocusMilliseconds, 4001);
    expect((await LocalStorage().load())!.toJson(), restored.toJson());
    expect(
      jsonDecode((await prefs.getString(LocalStorage.stateKey))!),
      restored.toJson(),
    );
    expect(await prefs.getString(AppearanceStorage.key), appearanceBefore);
    expect(await prefs.getString('unrelated'), 'keep');
    expect(credentials.values, tokens);
    expect(jsonEncode(restored.toJson()), isNot(contains('private-')));
  });

  test(
    'Undated v1 migration preserves the backup and never invents past history',
    () async {
      final prefs = SharedPreferencesAsync();
      final old = jsonEncode({
        'tasks': [
          Task(
            name: 'Original goal',
            type: TaskType.goal,
            isCompleted: true,
          ).toJson(),
        ],
        'tomorrowTasks': [
          Task(
            name: 'Original focus',
            type: TaskType.focus,
            minimumFocusMinutes: 45,
            focusTarget: 'Chapter 2',
          ).toJson(),
        ],
        'isTomorrowCommitted': true,
      });
      await prefs.setString(LocalStorage.legacyStateKey, old);
      final restored = (await LocalStorage(now: () => _day).load())!;
      expect(restored.history.plans, isEmpty);
      expect(restored.todayPlan.date, _day);
      expect(restored.todayPlan.tasks.single.isCompleted, isTrue);
      expect(restored.tomorrowPlan.tasks.single.minimumFocusMinutes, 45);
      expect(restored.tomorrowPlan.isCommitted, isTrue);
      expect(await prefs.getString(LocalStorage.legacyStateKey), old);
      expect(
        jsonDecode((await prefs.getString(LocalStorage.stateKey))!)['history'],
        isEmpty,
      );
    },
  );

  test('Migration write failure leaves the original real save intact and retries safely', () async {
    final prefs = SharedPreferencesAsync();
    final original = jsonEncode(_state().toJson()..remove('history'));
    await prefs.setString(LocalStorage.stateKey, original);
    var writesFail = true;
    final failing = _FailingPreferences(prefs, () => writesFail);
    final storage = LocalStorage(preferences: failing);
    await expectLater(storage.load(), throwsStateError);
    expect(await prefs.getString(LocalStorage.stateKey), original);
    writesFail = false;
    final restored = (await storage.load())!;
    expect(restored.history.plans, isEmpty);
    expect(restored.todayPlan.toJson(), _state().todayPlan.toJson());
    expect(restored.calendarCache.toJson(), _state().calendarCache.toJson());
  });

  test(
    'Malformed or duplicate history does not reset or overwrite any saved data',
    () async {
      final prefs = SharedPreferencesAsync();
      final record = PlanHistory.empty
          .archive(DailyPlan(date: DateTime(2026, 10, 6), tasks: []))
          .toJson()
          .single;
      for (final bad in [
        null,
        {},
        [record, record],
        [
          {...record, 'date': '2026-02-30'},
        ],
      ]) {
        final original = jsonEncode({..._state().toJson(), 'history': bad});
        await prefs.setString(LocalStorage.stateKey, original);
        await expectLater(LocalStorage().load(), throwsA(anything));
        expect(await prefs.getString(LocalStorage.stateKey), original);
      }
    },
  );

  test('Multiple missed days persist only known records across later rollovers and new storage instances', () async {
    final rolled = _state().rollOver(DateTime(2026, 10, 20));
    await LocalStorage().save(rolled);
    var restored = (await LocalStorage().load())!;
    expect(restored.history.plans.map((plan) => plan.date.day), [7, 8]);
    expect(restored.history.forDate(DateTime(2026, 10, 19)), isNull);
    expect(restored.history.summaryForDate(_day)!.completionPercentage, 50);
    expect(
      restored.history.summaryForDate(_day)!.accumulatedFocusMilliseconds,
      604001,
    );
    expect(
      restored.history
          .summaryForDate(DateTime(2026, 10, 8))!
          .completionPercentage,
      0,
    );
    await LocalStorage().save(restored.rollOver(DateTime(2026, 10, 21)));
    restored = (await LocalStorage().load())!;
    expect(restored.history.plans.map((plan) => plan.date.day), [7, 8, 20]);
    expect(
      restored.history.summaryForDate(DateTime(2026, 10, 20))!.isNeutral,
      isTrue,
    );
    expect(restored.calendarCache.toJson(), _state().calendarCache.toJson());
    expect(restored.events.single.toJson(), _state().events.single.toJson());
  });

  testWidgets(
    'Launch, completion, resume and subsequent restart preserve all history, calendars, tokens and appearance',
    (tester) async {
      var now = DateTime(2026, 10, 8, 8);
      final prior = PlanHistory.empty.archive(
        DailyPlan(
          date: DateTime(2026, 10, 6),
          isCommitted: true,
          tasks: [
            Task(name: 'Earlier goal', type: TaskType.goal, isCompleted: true),
          ],
        ),
      );
      final original = _state(history: prior);
      final credentials = MemoryCredentials();
      for (final account in original.calendarCache.accounts) {
        await credentials.write(
          account.id,
          CalendarCredentials(accessToken: 'existing-${account.provider.name}'),
        );
      }
      final tokens = Map.of(credentials.values);
      final service = CalendarService(credentials: credentials);
      const appearance = AppearancePreferences(
        mode: AppearanceMode.light,
        colour: ColourTheme.forest,
      );
      await tester.runAsync(() => AppearanceStorage().save(appearance));
      final appearanceRaw = await tester.runAsync<String?>(
        () => SharedPreferencesAsync().getString(AppearanceStorage.key),
      );
      await tester.runAsync(() => LocalStorage().save(original));
      await tester.pumpWidget(
        MainApp(now: () => now, calendarService: service),
      );
      await tester.pumpAndSettle();
      var saved = await _saved(tester);
      expect(saved.history.plans.map((plan) => plan.date.day), [6, 7]);
      expect(
        saved.history.summaryForDate(_day)!.accumulatedFocusMilliseconds,
        604001,
      );
      expect(saved.history.summaryForDate(_day)!.completionPercentage, 50);
      await tester.tap(find.text('Next day goal'));
      await tester.pumpAndSettle();
      expect((await _saved(tester)).history.toJson(), saved.history.toJson());
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MainApp(now: () => now, calendarService: service),
      );
      await tester.pumpAndSettle();
      expect((await _saved(tester)).history.toJson(), saved.history.toJson());
      now = DateTime(2026, 10, 9, 8);
      _resume(tester);
      await tester.pumpAndSettle();
      saved = await _saved(tester);
      expect(saved.history.plans.map((plan) => plan.date.day), [6, 7, 8]);
      expect(
        saved.history
            .summaryForDate(DateTime(2026, 10, 8))!
            .completionPercentage,
        100,
      );
      now = DateTime(2026, 10, 10, 8);
      _resume(tester);
      await tester.pumpAndSettle();
      saved = await _saved(tester);
      expect(saved.history.plans.map((plan) => plan.date.day), [6, 7, 8, 9]);
      expect(
        saved.history
            .summaryForDate(DateTime(2026, 10, 9))!
            .completionPercentage,
        isNull,
      );
      expect(saved.calendarCache.toJson(), original.calendarCache.toJson());
      expect(saved.events.single.toJson(), original.events.single.toJson());
      expect(credentials.values, tokens);
      expect(
        await tester.runAsync<String?>(
          () => SharedPreferencesAsync().getString(AppearanceStorage.key),
        ),
        appearanceRaw,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MainApp(now: () => now, calendarService: service),
      );
      await tester.pumpAndSettle();
      expect((await _saved(tester)).history.toJson(), saved.history.toJson());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Resume freezes an interrupted live Focus timer at midnight and never credits the new day',
    (tester) async {
      var now = DateTime(2026, 10, 7, 23, 50);
      await tester.runAsync(() => LocalStorage().save(_state()));
      await tester.pumpWidget(
        MainApp(
          now: () => now,
          calendarService: CalendarService(credentials: MemoryCredentials()),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TodayScreen>(find.byType(TodayScreen))
            .plan
            .tasks
            .last
            .isFocusRunning,
        isTrue,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      now = DateTime(2026, 10, 8, 8);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      final saved = await _saved(tester);
      expect(
        saved.history.forDate(_day)!.tasks.last.accumulatedFocusMilliseconds,
        604001,
      );
      expect(saved.history.forDate(_day)!.tasks.last.isCompleted, isFalse);
      expect(saved.todayPlan.date, DateTime(2026, 10, 8));
      expect(saved.todayPlan.tasks.single.name, 'Next day goal');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'A failed rollover save retains the old save and recovers without duplicate archives',
    (tester) async {
      final original = _state();
      await tester.runAsync(() => LocalStorage().save(original));
      final prefs = SharedPreferencesAsync();
      final raw = await tester.runAsync<String?>(
        () => prefs.getString(LocalStorage.stateKey),
      );
      final storage = _FailingStorage();
      await tester.pumpWidget(
        MainApp(storage: storage, now: () => DateTime(2026, 10, 8)),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Could not load your saved commitments.'),
        findsOneWidget,
      );
      expect(
        await tester.runAsync<String?>(
          () => prefs.getString(LocalStorage.stateKey),
        ),
        raw,
      );
      storage.fail = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      final saved = await _saved(tester);
      expect(saved.history.plans, hasLength(1));
      expect(
        saved.history.forDate(_day)!.tasks.last.accumulatedFocusMilliseconds,
        604001,
      );
      expect(saved.calendarCache.toJson(), original.calendarCache.toJson());
      expect(find.text('Next day goal'), findsOneWidget);
    },
  );

  testWidgets(
    'Fresh install creates no history before tracking; an observed empty day later archives as neutral',
    (tester) async {
      var now = DateTime(2026, 10, 8);
      await tester.pumpWidget(MainApp(now: () => now));
      await tester.pumpAndSettle();
      expect((await _saved(tester)).history.plans, isEmpty);
      now = DateTime(2026, 10, 9);
      _resume(tester);
      await tester.pumpAndSettle();
      final saved = await _saved(tester);
      expect(saved.history.plans.map((plan) => plan.date), [
        DateTime(2026, 10, 8),
      ]);
      expect(
        saved.history.summaryForDate(DateTime(2026, 10, 8))!.isNeutral,
        isTrue,
      );
      expect(saved.history.forDate(DateTime(2026, 10, 7)), isNull);
    },
  );
}

class _FailingPreferences extends SharedPreferencesAsync {
  final SharedPreferencesAsync delegate;
  final bool Function() shouldFail;
  _FailingPreferences(this.delegate, this.shouldFail);
  @override
  Future<String?> getString(String key) => delegate.getString(key);
  @override
  Future<void> setString(String key, String value) async {
    if (shouldFail()) throw StateError('Storage unavailable');
    await delegate.setString(key, value);
  }
}

class _FailingStorage extends LocalStorage {
  bool fail = true;
  @override
  Future<void> save(DaylockState state) async {
    if (fail) throw StateError('Storage unavailable');
    await super.save(state);
  }
}

import 'dart:convert';

import 'package:daylock/design/appearance_preferences.dart';
import 'package:daylock/design/daylock_palette.dart';
import 'package:daylock/models/calendar_account.dart';
import 'package:daylock/models/calendar_cache.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/event.dart';
import 'package:daylock/models/freedom_settings.dart';
import 'package:daylock/models/plan_history.dart';
import 'package:daylock/models/routine.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/services/appearance_storage.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:daylock/services/routine_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final date = DateTime(2026, 10, 13);
DaylockState fixture() {
  final accounts = [
    for (final provider in CalendarProviderType.values)
      CalendarAccount(
        provider: provider,
        providerAccountId: provider.name,
        displayName: provider.name,
      ),
  ];
  return DaylockState(
    todayPlan: DailyPlan(
      date: date,
      isCommitted: true,
      tasks: [
        Task(name: 'Finished', type: TaskType.goal, isCompleted: true),
        Task(
          name: 'Excused Focus',
          type: TaskType.focus,
          minimumFocusMinutes: 30,
          accumulatedFocusMilliseconds: 123456,
          outcome: TaskOutcome.excused,
          excuseReason: 'Power failure',
        ),
      ],
    ),
    tomorrowPlan: DailyPlan(
      date: DateTime(2026, 10, 14),
      tasks: [Task(name: 'Draft', type: TaskType.goal)],
    ),
    history: PlanHistory.empty.archive(
      DailyPlan(
        date: DateTime(2026, 10, 12),
        isCommitted: true,
        tasks: [
          Task(name: 'Historical goal', type: TaskType.goal, isCompleted: true),
        ],
      ),
    ),
    events: [Event(id: 'local', title: 'Appointment', date: date)],
    calendarCache: CalendarCache(
      accounts: accounts,
      calendars: [
        for (final account in accounts)
          ConnectedCalendar(
            accountId: account.id,
            id: 'main',
            name: 'Main',
            isVisible: false,
          ),
      ],
      events: [
        for (final account in accounts)
          Event.externalTimed(
            title: 'Meeting',
            source: account.provider.eventSource,
            accountId: account.id,
            calendarId: 'main',
            externalEventId: 'event',
            startsAtUtc: DateTime.utc(2026, 10, 13, 10),
            endsAtUtc: DateTime.utc(2026, 10, 13, 11),
          ),
      ],
    ),
    freedomSettings: const FreedomSettings(enabled: true, hour: 20, minute: 15),
    routines: RoutineBook([
      Routine(
        id: 'routine',
        name: 'Study',
        steps: [
          RoutineStep(
            id: 'first',
            name: 'Read',
            type: TaskType.focus,
            minimumFocusMinutes: 45,
            focusTarget: 'Chapter 7',
          ),
          RoutineStep(id: 'second', name: 'Review', type: TaskType.goal),
        ],
      ),
    ]),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  test(
    'Round trip preserves new preferences, definitions and all existing data',
    () async {
      final state = fixture();
      await AppearanceStorage().save(
        const AppearancePreferences(
          mode: AppearanceMode.system,
          colour: ColourTheme.forest,
        ),
      );
      await LocalStorage().save(state);
      final restored = (await LocalStorage().load())!;
      expect(restored.toJson(), state.toJson());
      expect(restored.todayPlan.tasks.last.excuseReason, 'Power failure');
      expect(
        restored.todayPlan.tasks.last.accumulatedFocusMilliseconds,
        123456,
      );
      expect(restored.calendarCache.accounts, hasLength(3));
      expect(
        restored.calendarCache.calendars.every(
          (calendar) => !calendar.isVisible,
        ),
        isTrue,
      );
      expect((await AppearanceStorage().load()).colour, ColourTheme.forest);
      expect((await AppearanceStorage().load()).mode, AppearanceMode.system);
    },
  );

  test(
    'Older v2 saves gain safe defaults and preserve every existing collection',
    () async {
      final old = fixture().toJson()
        ..remove('freedomSettings')
        ..remove('routines');
      await SharedPreferencesAsync().setString(
        LocalStorage.stateKey,
        jsonEncode(old),
      );
      final restored = (await LocalStorage().load())!;
      expect(
        restored.freedomSettings.toJson(),
        const FreedomSettings().toJson(),
      );
      expect(restored.routines.routines, isEmpty);
      final canonical = restored.toJson()
        ..remove('freedomSettings')
        ..remove('routines');
      expect(canonical, old);
      final saved = jsonDecode(
        (await SharedPreferencesAsync().getString(LocalStorage.stateKey))!,
      ) as Map;
      expect(saved['freedomSettings'], const FreedomSettings().toJson());
      expect(saved['routines'], isEmpty);
      expect(saved['history'], old['history']);
      expect(saved['calendarCache'], old['calendarCache']);
      expect((await LocalStorage().load())!.toJson(), restored.toJson());
    },
  );

  test(
    'Legacy migration retains completed commitments and original backup',
    () async {
      final old = jsonEncode({
        'tasks': [
          Task(name: 'Done', type: TaskType.goal, isCompleted: true).toJson(),
        ],
        'tomorrowTasks': [Task(name: 'Next', type: TaskType.goal).toJson()],
        'isTomorrowCommitted': true,
      });
      await SharedPreferencesAsync().setString(
        LocalStorage.legacyStateKey,
        old,
      );
      final restored = (await LocalStorage(now: () => date).load())!;
      expect(restored.todayPlan.tasks.single.isCompleted, isTrue);
      expect(restored.tomorrowPlan.isCommitted, isTrue);
      expect(restored.routines.routines, isEmpty);
      expect(restored.freedomSettings.enabled, isFalse);
      expect(
        await SharedPreferencesAsync().getString(LocalStorage.legacyStateKey),
        old,
      );
    },
  );

  for (final invalid in [
    {'field': 'freedomSettings', 'value': null},
    {
      'field': 'freedomSettings',
      'value': {'enabled': true, 'hour': 24, 'minute': 0},
    },
    {'field': 'routines', 'value': null},
    {
      'field': 'routines',
      'value': [{}],
    },
  ]) {
    test(
      'Malformed ${invalid['field']} fails without overwriting existing save',
      () async {
        final original = fixture().toJson()
          ..[invalid['field'] as String] = invalid['value'];
        final raw = jsonEncode(original);
        await SharedPreferencesAsync().setString(LocalStorage.stateKey, raw);
        await expectLater(LocalStorage().load(), throwsA(anything));
        expect(
          await SharedPreferencesAsync().getString(LocalStorage.stateKey),
          raw,
        );
      },
    );
  }

  test('Accepted task and decision restore together, prevent duplicate and survive rollovers', () async {
    final state = fixture();
    const service = RoutineService();
    final suggestion = service
        .suggestions(state.routines, state.tomorrowPlan.date)
        .single;
    final result = service.resolve(
      state.routines,
      suggestion,
      RoutineAction.accept,
      state.tomorrowPlan.date,
    );
    state.tomorrowPlan.tasks.add(result.task!);
    final accepted = DaylockState(
      todayPlan: state.todayPlan,
      tomorrowPlan: state.tomorrowPlan,
      events: state.events,
      calendarCache: state.calendarCache,
      history: state.history,
      freedomSettings: state.freedomSettings,
      routines: result.book,
    );
    await LocalStorage().save(accepted);
    final restarted = (await LocalStorage().load())!;
    expect(restarted.tomorrowPlan.tasks, hasLength(2));
    expect(restarted.tomorrowPlan.tasks.last.minimumFocusMinutes, 45);
    expect(
      service
          .resolve(
            restarted.routines,
            suggestion,
            RoutineAction.accept,
            restarted.tomorrowPlan.date,
          )
          .changed,
      isFalse,
    );
    final next = restarted.rollOver(DateTime(2026, 10, 14));
    await LocalStorage().save(next);
    final again = (await LocalStorage().load())!;
    expect(again.todayPlan.tasks.last.name, 'Read');
    expect(
      service
          .suggestions(again.routines, again.tomorrowPlan.date)
          .single
          .step
          .name,
      'Review',
    );
    expect(again.freedomSettings.timeLabel, '20:15');
    expect(again.events.single.title, 'Appointment');
    expect(again.calendarCache.toJson(), state.calendarCache.toJson());
    expect(again.history.toJson(), next.history.toJson());
  });
}

import 'dart:convert';

import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/event.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

DaylockState _state({List<Event> events = const []}) => DaylockState(
  todayPlan: DailyPlan(
    date: DateTime(2026, 10, 8),
    isCommitted: true,
    tasks: [
      Task(name: 'Gym', type: TaskType.goal, isCompleted: true),
      Task(
        name: 'Study',
        type: TaskType.focus,
        minimumFocusMinutes: 60,
        accumulatedFocusMilliseconds: 120000,
        focusStartedAt: DateTime.utc(2026, 10, 8, 9),
      ),
    ],
  ),
  tomorrowPlan: DailyPlan(
    date: DateTime(2026, 10, 9),
    isCommitted: true,
    tasks: [Task(name: 'Walk', type: TaskType.goal)],
  ),
  events: events,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('Local storage preserves events alongside dates, locking, and focus progress', () async {
    final state = _state(
      events: [
        Event(
          id: 'lesson',
          title: 'Driving lesson',
          date: DateTime(2026, 10, 10),
          startTime: EventTime(14, 0),
          endTime: EventTime(16, 0),
          notes: 'Bring licence',
        ),
        Event(id: 'all', title: 'Birthday', date: DateTime(2026, 12, 31)),
      ],
    );
    await LocalStorage().save(state);
    final restored = (await LocalStorage().load())!;
    expect(restored.toJson(), state.toJson());
  });

  test(
    'Pre-calendar v2 saves gain empty events without changing either plan',
    () async {
      final previous = _state().toJson()..remove('events');
      final prefs = SharedPreferencesAsync();
      await prefs.setString(LocalStorage.stateKey, jsonEncode(previous));
      final restored = (await LocalStorage().load())!;
      expect(restored.events, isEmpty);
      expect(restored.toJson(), {...previous, 'events': []});
      expect(
        jsonDecode((await prefs.getString(LocalStorage.stateKey))!),
        restored.toJson(),
      );
      expect((await LocalStorage().load())!.toJson(), restored.toJson());
    },
  );

  test(
    'Legacy v1 migration receives empty events and preserves its backup',
    () async {
      final legacy = jsonEncode({
        'tasks': [
          Task(name: 'Gym', type: TaskType.goal, isCompleted: true).toJson(),
        ],
        'tomorrowTasks': [Task(name: 'Study', type: TaskType.focus).toJson()],
        'isTomorrowCommitted': true,
      });
      final prefs = SharedPreferencesAsync();
      await prefs.setString(LocalStorage.legacyStateKey, legacy);
      final restored = (await LocalStorage(now: () => DateTime(2026, 10, 8))
          .load())!;
      expect(restored.events, isEmpty);
      expect(restored.todayPlan.tasks.single.isCompleted, isTrue);
      expect(restored.tomorrowPlan.isCommitted, isTrue);
      expect(await prefs.getString(LocalStorage.legacyStateKey), legacy);
      expect(
        (jsonDecode((await prefs.getString(LocalStorage.stateKey))!)
            as Map)['events'],
        isEmpty,
      );
    },
  );

  test(
    'Malformed events fail loading without resetting or overwriting the save',
    () async {
      final prefs = SharedPreferencesAsync();
      final saved = jsonEncode({
        ..._state().toJson(),
        'events': [
          {'id': 'x', 'title': 'Bad date', 'date': '2026-02-30'},
        ],
      });
      await prefs.setString(LocalStorage.stateKey, saved);
      await expectLater(LocalStorage().load(), throwsFormatException);
      expect(await prefs.getString(LocalStorage.stateKey), saved);
      final invalidCollection = jsonEncode({
        ..._state().toJson(),
        'events': null,
      });
      await prefs.setString(LocalStorage.stateKey, invalidCollection);
      await expectLater(LocalStorage().load(), throwsA(isA<TypeError>()));
      expect(await prefs.getString(LocalStorage.stateKey), invalidCollection);
    },
  );

  test('Single and multiple day rollovers preserve events without promoting them to tasks', () async {
    final state = _state(
      events: [
        Event(
          id: 'lesson',
          title: 'Driving lesson',
          date: DateTime(2026, 10, 9),
        ),
      ],
    );
    for (final date in [DateTime(2026, 10, 9), DateTime(2026, 10, 12)]) {
      final rolled = state.rollOver(date);
      expect(rolled.events.single.toJson(), state.events.single.toJson());
      expect(
        rolled.todayPlan.tasks.any((task) => task.name == 'Driving lesson'),
        isFalse,
      );
      expect(rolled.tomorrowPlan.tasks, isEmpty);
      await LocalStorage().save(rolled);
      expect((await LocalStorage().load())!.events.single.id, 'lesson');
    }
  });

  test('Development reset also removes scheduled events', () async {
    await LocalStorage().save(
      _state(
        events: [Event(id: 'x', title: 'Lesson', date: DateTime(2026, 10, 10))],
      ),
    );
    await LocalStorage().reset();
    expect(await LocalStorage().load(), isNull);
  });
}

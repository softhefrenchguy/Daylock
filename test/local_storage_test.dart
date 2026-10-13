import 'dart:async';
import 'dart:convert';

import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('No saved state is distinct from a saved empty plan', () async {
    final storage = LocalStorage();
    expect(await storage.load(), isNull);
    await storage.save(
      DaylockState(
        todayPlan: DailyPlan(
          date: DateTime(2026, 10, 7),
          tasks: [],
          isCommitted: true,
        ),
        tomorrowPlan: DailyPlan(date: DateTime(2026, 10, 8), tasks: []),
      ),
    );

    final restored = (await LocalStorage().load())!;
    expect(restored.todayPlan.tasks, isEmpty);
    expect(restored.tomorrowPlan.tasks, isEmpty);
    expect(restored.tomorrowPlan.isCommitted, isFalse);
  });

  test('Reset clears both Daylock keys, including corrupt data, and preserves other preferences', () async {
    final preferences = SharedPreferencesAsync();
    await preferences.setString(LocalStorage.stateKey, '{broken current save');
    await preferences.setString(LocalStorage.legacyStateKey, '{broken backup');
    await preferences.setString('unrelated.preference', 'keep');
    await LocalStorage().reset();
    expect(await preferences.getString(LocalStorage.stateKey), isNull);
    expect(await preferences.getString(LocalStorage.legacyStateKey), isNull);
    expect(await preferences.getString('unrelated.preference'), 'keep');
    expect(await LocalStorage().load(), isNull);
    await LocalStorage().reset();
    expect(await LocalStorage().load(), isNull);
  });

  test(
    'Reset waits for pending writes so an earlier save cannot restore old data',
    () async {
      final preferences = _DelayedPreferences();
      SharedPreferencesAsyncPlatform.instance = preferences;
      final storage = LocalStorage();
      final save = storage.save(
        DaylockState(
          todayPlan: DailyPlan(
            date: DateTime(2026, 10, 7),
            tasks: [Task(name: 'Old commitment', type: TaskType.goal)],
          ),
          tomorrowPlan: DailyPlan(date: DateTime(2026, 10, 8), tasks: []),
        ),
      );
      final reset = storage.reset();
      await Future<void>.delayed(Duration.zero);
      expect(preferences.writes, hasLength(1));
      preferences.writes.single.complete();
      await Future.wait([save, reset]);
      expect(await storage.load(), isNull);
    },
  );

  test(
    'Round trip preserves completion, both task types, and the lock',
    () async {
      await LocalStorage().save(
        DaylockState(
          todayPlan: DailyPlan(
            date: DateTime(2026, 10, 7),
            isCommitted: true,
            tasks: [
              Task(name: 'Gym', type: TaskType.goal, isCompleted: true),
              Task(name: 'Study', type: TaskType.focus),
            ],
          ),
          tomorrowPlan: DailyPlan(
            date: DateTime(2026, 10, 8),
            tasks: [
              Task(name: 'Walk', type: TaskType.goal),
              Task(name: 'Read', type: TaskType.focus),
            ],
            isCommitted: true,
          ),
        ),
      );

      final restored = (await LocalStorage().load())!;
      expect(restored.todayPlan.tasks.map((task) => task.name), [
        'Gym',
        'Study',
      ]);
      expect(restored.todayPlan.tasks.map((task) => task.isCompleted), [
        true,
        false,
      ]);
      expect(restored.todayPlan.tasks.map((task) => task.type), [
        TaskType.goal,
        TaskType.focus,
      ]);
      expect(restored.tomorrowPlan.tasks.map((task) => task.name), [
        'Walk',
        'Read',
      ]);
      expect(restored.tomorrowPlan.tasks.map((task) => task.type), [
        TaskType.goal,
        TaskType.focus,
      ]);
      expect(
        restored.tomorrowPlan.tasks.every((task) => !task.isCompleted),
        isTrue,
      );
      expect(restored.tomorrowPlan.isCommitted, isTrue);
    },
  );

  test('Rapid saves capture each snapshot and write in order', () async {
    final preferences = _DelayedPreferences();
    SharedPreferencesAsyncPlatform.instance = preferences;
    final storage = LocalStorage();
    final task = Task(name: 'Gym', type: TaskType.goal);
    final firstSave = storage.save(
      DaylockState(
        todayPlan: DailyPlan(
          date: DateTime(2026, 10, 7),
          tasks: [task],
          isCommitted: true,
        ),
        tomorrowPlan: DailyPlan(date: DateTime(2026, 10, 8), tasks: []),
      ),
    );
    task.isCompleted = true;
    final lastSave = storage.save(
      DaylockState(
        todayPlan: DailyPlan(
          date: DateTime(2026, 10, 7),
          tasks: [task],
          isCommitted: true,
        ),
        tomorrowPlan: DailyPlan(
          date: DateTime(2026, 10, 8),
          tasks: [],
          isCommitted: true,
        ),
      ),
    );

    await Future<void>.delayed(Duration.zero);
    expect(preferences.writes, hasLength(1));
    final firstJson =
        jsonDecode(preferences.snapshots.first) as Map<String, dynamic>;
    expect(
      (firstJson['todayPlan']['tasks'] as List).first['isCompleted'],
      isFalse,
    );
    preferences.writes.first.complete();
    await firstSave;
    await Future<void>.delayed(Duration.zero);
    expect(preferences.writes, hasLength(2));
    preferences.writes.last.complete();
    await lastSave;

    final restored = (await LocalStorage().load())!;
    expect(restored.todayPlan.tasks.single.isCompleted, isTrue);
    expect(restored.tomorrowPlan.isCommitted, isTrue);
  });

  test(
    'A failed save reports the error and does not block later saves',
    () async {
      final preferences = _FailOncePreferences();
      SharedPreferencesAsyncPlatform.instance = preferences;
      final storage = LocalStorage();
      final state = DaylockState(
        todayPlan: DailyPlan(
          date: DateTime(2026, 10, 7),
          tasks: [],
          isCommitted: true,
        ),
        tomorrowPlan: DailyPlan(date: DateTime(2026, 10, 8), tasks: []),
      );

      await expectLater(storage.save(state), throwsStateError);
      await storage.save(state);
      expect((await LocalStorage().load())!.todayPlan.tasks, isEmpty);
    },
  );

  test('Malformed saved data is not silently reset or overwritten', () async {
    final preferences = SharedPreferencesAsync();
    await preferences.setString(LocalStorage.stateKey, '{broken');
    await expectLater(LocalStorage().load(), throwsFormatException);
    expect(await preferences.getString(LocalStorage.stateKey), '{broken');
  });

  for (final committed in [false, true]) {
    test(
      'Migrates legacy tasks and lock=$committed once, retaining the backup',
      () async {
        final preferences = SharedPreferencesAsync();
        final legacyJson = jsonEncode({
          'tasks': [
            Task(name: 'Gym', type: TaskType.goal, isCompleted: true).toJson(),
            Task(name: 'Study', type: TaskType.focus).toJson(),
          ],
          'tomorrowTasks': [
            Task(name: 'Walk', type: TaskType.goal).toJson(),
            Task(name: 'Read', type: TaskType.focus).toJson(),
          ],
          'isTomorrowCommitted': committed,
        });
        await preferences.setString(LocalStorage.legacyStateKey, legacyJson);
        final storage = LocalStorage(now: () => DateTime(2026, 12, 31, 23, 59));
        final migrated = (await storage.load())!;
        expect(migrated.todayPlan.date, DateTime(2026, 12, 31));
        expect(migrated.tomorrowPlan.date, DateTime(2027, 1, 1));
        expect(migrated.todayPlan.isCommitted, isTrue);
        expect(migrated.todayPlan.tasks.map((task) => task.isCompleted), [
          true,
          false,
        ]);
        expect(migrated.tomorrowPlan.tasks.map((task) => task.type), [
          TaskType.goal,
          TaskType.focus,
        ]);
        expect(migrated.tomorrowPlan.isCommitted, committed);
        expect(
          await preferences.getString(LocalStorage.legacyStateKey),
          legacyJson,
        );
        final v2Json = jsonDecode(
          (await preferences.getString(LocalStorage.stateKey))!,
        ) as Map<String, dynamic>;
        expect(v2Json['version'], 2);
        expect(v2Json.containsKey('tasks'), isFalse);

        // A later launch uses v2, retaining its dates and any post-migration edits.
        migrated.todayPlan.tasks.first.isCompleted = false;
        await storage.save(migrated);
        final reopened = (await LocalStorage(now: () => DateTime(2030, 8, 20))
            .load())!;
        expect(reopened.todayPlan.date, DateTime(2026, 12, 31));
        expect(reopened.tomorrowPlan.date, DateTime(2027, 1, 1));
        expect(reopened.todayPlan.tasks.first.isCompleted, isFalse);
        expect(reopened.tomorrowPlan.isCommitted, committed);
      },
    );
  }

  test(
    'Migrates empty legacy lists across leap day without sample tasks',
    () async {
      await SharedPreferencesAsync().setString(
        LocalStorage.legacyStateKey,
        jsonEncode({
          'tasks': [],
          'tomorrowTasks': [],
          'isTomorrowCommitted': false,
        }),
      );
      final migrated = (await LocalStorage(now: () => DateTime(2028, 2, 28))
          .load())!;
      expect(migrated.todayPlan.date, DateTime(2028, 2, 28));
      expect(migrated.tomorrowPlan.date, DateTime(2028, 2, 29));
      expect(migrated.todayPlan.tasks, isEmpty);
      expect(migrated.tomorrowPlan.tasks, isEmpty);
    },
  );

  test('A failed migration write keeps v1 intact and can be retried', () async {
    final preferences = SharedPreferencesAsync();
    final legacyJson = jsonEncode({
      'tasks': [],
      'tomorrowTasks': [
        Task(name: 'Locked plan', type: TaskType.focus).toJson(),
      ],
      'isTomorrowCommitted': true,
    });
    await preferences.setString(LocalStorage.legacyStateKey, legacyJson);
    final failingStorage = LocalStorage(
      preferences: _MigrationFailurePreferences(preferences),
    );
    await expectLater(failingStorage.load(), throwsStateError);
    expect(await preferences.getString(LocalStorage.stateKey), isNull);
    expect(
      await preferences.getString(LocalStorage.legacyStateKey),
      legacyJson,
    );
    final retried = (await LocalStorage().load())!;
    expect(retried.tomorrowPlan.isCommitted, isTrue);
    expect(retried.tomorrowPlan.tasks.single.name, 'Locked plan');
  });

  test(
    'Malformed legacy data is not overwritten or partially migrated',
    () async {
      final preferences = SharedPreferencesAsync();
      final legacyJson = jsonEncode({
        'tasks': [],
        'tomorrowTasks': [Task(name: 'Draft', type: TaskType.goal).toJson()],
        'isTomorrowCommitted': 'invalid',
      });
      await preferences.setString(LocalStorage.legacyStateKey, legacyJson);
      await expectLater(LocalStorage().load(), throwsA(isA<TypeError>()));
      expect(await preferences.getString(LocalStorage.stateKey), isNull);
      expect(
        await preferences.getString(LocalStorage.legacyStateKey),
        legacyJson,
      );
    },
  );

  test('Invalid v2 does not fall back to a stale v1 backup', () async {
    final preferences = SharedPreferencesAsync();
    final legacyJson = jsonEncode({
      'tasks': [],
      'tomorrowTasks': [],
      'isTomorrowCommitted': false,
    });
    await preferences.setString(LocalStorage.legacyStateKey, legacyJson);
    await preferences.setString(
      LocalStorage.stateKey,
      jsonEncode({'version': 99}),
    );
    await expectLater(LocalStorage().load(), throwsFormatException);
    expect(
      await preferences.getString(LocalStorage.stateKey),
      jsonEncode({'version': 99}),
    );
    expect(
      await preferences.getString(LocalStorage.legacyStateKey),
      legacyJson,
    );
  });
}

class _MigrationFailurePreferences extends SharedPreferencesAsync {
  final SharedPreferencesAsync delegate;

  _MigrationFailurePreferences(this.delegate);

  @override
  Future<String?> getString(String key) => delegate.getString(key);

  @override
  Future<void> setString(String key, String value) async {
    throw StateError('Storage unavailable');
  }
}

final class _DelayedPreferences extends InMemorySharedPreferencesAsync {
  _DelayedPreferences() : super.empty();

  final writes = <Completer<void>>[];
  final snapshots = <String>[];

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) async {
    final gate = Completer<void>();
    writes.add(gate);
    snapshots.add(value);
    await gate.future;
    return super.setString(key, value, options);
  }
}

final class _FailOncePreferences extends InMemorySharedPreferencesAsync {
  _FailOncePreferences() : super.empty();

  bool _shouldFail = true;

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) async {
    if (_shouldFail) {
      _shouldFail = false;
      throw StateError('Storage unavailable');
    }
    return super.setString(key, value, options);
  }
}

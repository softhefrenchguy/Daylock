import 'dart:convert';

import 'package:daylock/main.dart' as app;
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:daylock/services/calendar_credentials.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    FlutterSecureStorage.setMockInitialValues({
      '${SecureCalendarCredentialStore.keyPrefix}old-account':
          '{"accessToken":"test-token"}',
      'unrelated.secret': 'keep',
    });
  });

  testWidgets(
    'Startup preserves saves normally and resets them only with the debug flag',
    (tester) async {
      const resetRequested = bool.fromEnvironment('DAYLOCK_RESET_LOCAL_DATA');
      final now = DateTime.now();
      final preferences = SharedPreferencesAsync();
      final oldState = DaylockState(
        todayPlan: DailyPlan(
          date: now,
          tasks: [
            Task(name: 'Go to the gym', type: TaskType.goal, isCompleted: true),
            Task(name: 'Study Pega', type: TaskType.focus),
            Task(name: 'Apply for internship', type: TaskType.goal),
            Task(name: 'User-created commitment', type: TaskType.goal),
          ],
          isCommitted: true,
        ),
        tomorrowPlan: DailyPlan(
          date: DateTime(now.year, now.month, now.day + 1),
          tasks: [
            Task(name: 'User-created tomorrow plan', type: TaskType.goal),
          ],
          isCommitted: true,
        ),
      );
      final backup = jsonEncode({
        'tasks': [],
        'tomorrowTasks': [],
        'isTomorrowCommitted': false,
      });
      await tester.runAsync(() async {
        await preferences.setString('unrelated.preference', 'keep');
        await preferences.setString(LocalStorage.legacyStateKey, backup);
        await LocalStorage().save(oldState);
      });

      // Exercise the actual production entry point, including its debug-only gate.
      await app.main();
      await tester.pumpAndSettle();
      final saved = (await LocalStorage().load())!;
      expect(await preferences.getString('unrelated.preference'), 'keep');
      expect(
        await const FlutterSecureStorage().read(key: 'unrelated.secret'),
        'keep',
      );
      expect(
        await SecureCalendarCredentialStore().read('old-account'),
        resetRequested ? isNull : isNotNull,
      );
      if (resetRequested) {
        expect(saved.todayPlan.tasks, isEmpty);
        expect(saved.tomorrowPlan.tasks, isEmpty);
        expect(saved.tomorrowPlan.isCommitted, isFalse);
        expect(
          await preferences.getString(LocalStorage.legacyStateKey),
          isNull,
        );
        expect(find.text('Go to the gym'), findsNothing);
        expect(find.text('0 / 0 complete'), findsOneWidget);
      } else {
        expect(saved.toJson(), oldState.toJson());
        expect(
          await preferences.getString(LocalStorage.legacyStateKey),
          backup,
        );
        expect(find.text('Go to the gym'), findsOneWidget);
        expect(find.text('User-created commitment'), findsOneWidget);
      }
    },
  );
}

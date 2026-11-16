import 'dart:convert';

import 'package:daylock/main.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/services/backup_service.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:daylock/services/notifications/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'notification_preferences_test.dart' show notificationFixture;

class _Files extends BackupFiles {
  String? saved, savedName, toOpen;
  @override
  bool get supported => true;
  @override
  Future<bool> save(String name, String content) async {
    savedName = name;
    saved = content;
    return true;
  }

  @override
  Future<String?> open() async => toOpen;
}

class _Notifications extends NotificationService {
  @override
  Future<void> invalidate() async {}
  @override
  Future<void> synchronize(DaylockState state, DateTime now) async {}
  @override
  Future<void> requestPermission() async {}
}

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  test('a backup round-trips the whole state', () {
    final state = notificationFixture();
    final text = DaylockBackup.encode(state, DateTime.utc(2026, 11, 16));
    final json = jsonDecode(text) as Map;
    expect(json['app'], 'daylock');
    expect(json['format'], DaylockBackup.format);
    expect(
      jsonEncode(DaylockBackup.decode(text).toJson()),
      jsonEncode(state.toJson()),
    );
    expect(
      DaylockBackup.fileName(DateTime(2026, 3, 5)),
      'daylock-backup-2026-03-05.json',
    );
  });

  test('other files, newer formats and damaged backups are refused', () {
    Matcher problem(BackupProblem p) =>
        throwsA(isA<BackupException>().having((e) => e.problem, 'problem', p));
    expect(
      () => DaylockBackup.decode('not json'),
      problem(BackupProblem.notDaylock),
    );
    expect(
      () => DaylockBackup.decode('{"app":"other","state":{}}'),
      problem(BackupProblem.notDaylock),
    );
    expect(
      () => DaylockBackup.decode('{"app":"daylock","format":99,"state":{}}'),
      problem(BackupProblem.newerVersion),
    );
    expect(
      () => DaylockBackup.decode(
        '{"app":"daylock","format":1,"state":{"version":2}}',
      ),
      problem(BackupProblem.damaged),
    );
  });

  testWidgets('Settings exports a backup and restores one after confirming', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await LocalStorage().save(notificationFixture());
    final files = _Files();
    await tester.pumpWidget(
      MainApp(
        notificationService: _Notifications(),
        backupFiles: files,
        now: () => DateTime(2026, 10, 14, 12),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-settings')));
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('settings-backup'));
    await tester.scrollUntilVisible(card, 200);
    await tester.tap(card);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('backup-export')));
    await tester.pumpAndSettle();
    expect(files.savedName, 'daylock-backup-2026-10-14.json');
    expect(find.text('Backup saved.'), findsOneWidget);
    final exported = DaylockBackup.decode(files.saved!);
    expect(exported.todayPlan.tasks.single.name, 'Study maths');

    // Restore a backup whose plan for today differs.
    final other = DaylockState.fromJson(exported.toJson());
    final restored = DaylockState(
      todayPlan: DailyPlan(
        date: other.todayPlan.date,
        isCommitted: true,
        tasks: [Task(name: 'Restored task')],
      ),
      tomorrowPlan: other.tomorrowPlan,
      freedomSettings: other.freedomSettings,
    );
    files.toOpen = DaylockBackup.encode(restored, DateTime(2026, 10, 14));
    await tester.tap(find.byKey(const ValueKey('backup-import')));
    await tester.pumpAndSettle();
    expect(find.text('Replace your Daylock data?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('backup-confirm-restore')));
    await tester.pumpAndSettle();
    expect(find.text('Backup restored.'), findsOneWidget);
    final saved = await tester.runAsync(() => LocalStorage().load());
    expect(saved!.todayPlan.tasks.single.name, 'Restored task');

    // A non-Daylock file changes nothing.
    files.toOpen = '{"hello": true}';
    await tester.tap(find.byKey(const ValueKey('backup-import')));
    await tester.pumpAndSettle();
    expect(find.text('That file isn’t a Daylock backup.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

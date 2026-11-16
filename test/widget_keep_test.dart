import 'package:daylock/main.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:daylock/services/notifications/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'notification_preferences_test.dart' show notificationFixture;

class _Notifications extends NotificationService {
  @override
  Future<void> invalidate() async {}
  @override
  Future<void> synchronize(DaylockState state, DateTime now) async {}
  @override
  Future<void> requestPermission() async {}
}

NotificationTarget _keep({
  String date = '2026-10-14',
  int index = 0,
  String name = 'Study maths',
}) => NotificationTarget(
  'today',
  date: date,
  taskIndex: index,
  taskName: name,
  action: 'keep',
);

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  testWidgets('a widget tap keeps that commitment, with Undo', (tester) async {
    await LocalStorage().save(notificationFixture());
    final service = _Notifications();
    await tester.pumpWidget(
      MainApp(
        notificationService: service,
        now: () => DateTime(2026, 10, 14, 12),
      ),
    );
    await tester.pumpAndSettle();
    Future<Task> saved() async =>
        (await tester.runAsync(() => LocalStorage().load()))!
            .todayPlan
            .tasks
            .single;

    // Another day, a renamed task or a missing index change nothing.
    for (final stale in [
      _keep(date: '2026-10-13'),
      _keep(name: 'Something else'),
      _keep(index: 4),
    ]) {
      service.onTap!(stale);
      await tester.pumpAndSettle();
      expect((await saved()).isCompleted, isFalse);
    }

    service.onTap!(_keep());
    await tester.pumpAndSettle();
    expect(find.text('Kept: Study maths'), findsOneWidget);
    expect((await saved()).isCompleted, isTrue);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect((await saved()).isCompleted, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

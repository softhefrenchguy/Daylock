import 'package:daylock/main.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/onboarding_steps.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:daylock/services/notifications/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../tool/store_screenshot_state.dart' as sample;

class _Notifications extends NotificationService {
  @override
  Future<void> invalidate() async {}
  @override
  Future<void> synchronize(DaylockState state, DateTime now) async {}
  @override
  Future<void> requestPermission() async {}
}

/// Every screen a person reaches in normal use, at the given text scale.
Future<List<String>> _visit(WidgetTester tester) async {
  final visited = <String>[];
  Future<void> check(String name) async {
    await tester.pumpAndSettle();
    visited.add(name);
    await expectLater(
      tester,
      meetsGuideline(androidTapTargetGuideline),
      reason: name,
    );
    await expectLater(
      tester,
      meetsGuideline(labeledTapTargetGuideline),
      reason: name,
    );
    expect(tester.takeException(), isNull, reason: name);
  }

  final nav = find.byType(NavigationBar);
  await check('today');
  await tester.tap(find.descendant(of: nav, matching: find.text('Plan')));
  await check('plan');
  await tester.tap(find.descendant(of: nav, matching: find.text('Journey')));
  await check('journey');
  final week = find.byKey(const ValueKey('journey-week'));
  await tester.scrollUntilVisible(
    week,
    200,
    scrollable: find
        .descendant(
          of: find.byKey(const ValueKey('journey-content')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.ensureVisible(week);
  await tester.pumpAndSettle();
  await tester.tap(week);
  await check('weekly review');
  await tester.pageBack();
  await tester.pumpAndSettle();
  await tester.tap(find.descendant(of: nav, matching: find.text('Today')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('open-settings')));
  await check('settings');
  final backup = find.byKey(const ValueKey('settings-backup'));
  await tester.scrollUntilVisible(backup, 200);
  await tester.tap(backup);
  await check('backup');
  await tester.pageBack();
  await tester.pumpAndSettle();
  final tour = find.byKey(const ValueKey('settings-tour'));
  await tester.scrollUntilVisible(tour, 200);
  await tester.tap(tour);
  await check('tour');
  return visited;
}

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'main screens meet tap target and label guidelines at ${scale}x text',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2340);
        tester.view.devicePixelRatio = 2.75;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final handle = tester.ensureSemantics();
        await tester.runAsync(() async {
          await LocalStorage().save(sample.state(earned: false));
          await LocalStorage().saveOnboardingStep(OnboardingSteps.complete);
        });
        await tester.pumpWidget(
          MainApp(
            notificationService: _Notifications(),
            now: () => DateTime(2026, 11, 13, 20, 30),
          ),
        );
        final visited = await _visit(tester);
        expect(visited, hasLength(7));
        handle.dispose();
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}

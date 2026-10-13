import 'package:daylock/main.dart';
import 'package:daylock/design/daylock_plan_rows.dart';
import 'package:daylock/screens/today_screen.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'plan_test_helpers.dart';

import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets(
    'A fresh install stays empty until a Plan commitment rolls into Today',
    (tester) async {
      var now = DateTime(2026, 10, 7, 12);
      await tester.pumpWidget(MainApp(now: () => now));
      await tester.pumpAndSettle();
      expect(find.text('0 / 0 complete'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsNothing);
      expect(
        tester.widget<TodayScreen>(find.byType(TodayScreen)).plan.tasks,
        isEmpty,
      );

      var saved = (await LocalStorage().load())!;
      expect(saved.todayPlan.date, DateTime(2026, 10, 7));
      expect(saved.todayPlan.tasks, isEmpty);
      expect(saved.tomorrowPlan.date, DateTime(2026, 10, 8));
      expect(saved.tomorrowPlan.tasks, isEmpty);
      expect(saved.tomorrowPlan.isCommitted, isFalse);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(MainApp(now: () => now));
      await tester.pumpAndSettle();
      expect(find.text('0 / 0 complete'), findsOneWidget);
      await _navigate(tester, 'Plan');
      expect(find.text('No commitments planned yet.'), findsOneWidget);
      final commit = find.widgetWithText(FilledButton, 'COMMIT THURSDAY');
      expect(tester.widget<FilledButton>(commit).onPressed, isNull);

      await enterPlanText(
        tester,
        find.byKey(const ValueKey('commitment-name')),
        'My first goal',
      );
      await tester.pump();
      await tester.ensureVisible(find.text('Add commitment'));
      await tester.tap(find.text('Add commitment'));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(DaylockPlanTaskRow, 'My first goal'),
        findsOneWidget,
      );
      saved = (await LocalStorage().load())!;
      expect(saved.todayPlan.tasks, isEmpty);
      expect(saved.tomorrowPlan.tasks.single.name, 'My first goal');
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      await tester.ensureVisible(commit);
      await tester.tap(commit);
      await confirmPlanCommit(tester);
      await tester.pumpAndSettle();
      await _navigate(tester, 'Today');
      expect(find.text('0 / 0 complete'), findsOneWidget);

      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      now = DateTime(2026, 10, 8, 8);
      for (final state in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(CheckboxListTile, 'My first goal'),
        findsOneWidget,
      );
      expect(find.text('0 / 1 complete'), findsOneWidget);
      saved = (await LocalStorage().load())!;
      expect(saved.todayPlan.tasks.single.name, 'My first goal');
      expect(saved.todayPlan.isCommitted, isTrue);
      expect(saved.tomorrowPlan.tasks, isEmpty);
      expect(saved.tomorrowPlan.isCommitted, isFalse);
    },
  );
}

Future<void> _navigate(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

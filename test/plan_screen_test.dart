import 'navigation_helpers.dart';

import 'package:daylock/main.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/screens/plan_screen.dart';
import 'package:daylock/screens/commitment_editor.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'fixtures.dart';
import 'plan_test_helpers.dart';

final _now = DateTime(2026, 10, 8, 12);

Future<void> _page(WidgetTester tester, String label) =>
    navigateApp(tester, label);

Future<void> _add(
  WidgetTester tester,
  String name, {
  bool focus = false,
}) async {
  await openCommitmentEditor(tester);
  if (focus) {
    await tester.tap(find.text('Focus'));
    await tester.pumpAndSettle();
    await enterPlanText(
      tester,
      find.byKey(const ValueKey('focus-minutes')),
      '60',
    );
  }
  await enterPlanText(
    tester,
    find.byKey(const ValueKey('commitment-name')),
    name,
  );
  await tester.pump();
  final add = find.byKey(const ValueKey('save-commitment'));
  await tester.ensureVisible(add);
  await tester.tap(add);
  await tester.pumpAndSettle();
}

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  testWidgets(
    'Empty Plan has a collapsed editor and disabled weekday commit action',
    (tester) async {
      await tester.pumpWidget(MainApp(now: () => _now));
      await tester.pumpAndSettle();
      await _page(tester, 'Plan');
      final commit = find.widgetWithText(FilledButton, 'COMMIT FRIDAY');
      expect(tester.widget<FilledButton>(commit).onPressed, isNull);
      expect(commit.hitTestable(), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('+ Add commitment'), findsOneWidget);
      tester.widget<PlanScreen>(find.byType(PlanScreen)).onCommitTomorrow();
      await tester.pump();
      expect(
        tester.widget<PlanScreen>(find.byType(PlanScreen)).plan.isCommitted,
        isFalse,
      );
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets(
    'Sheet rejects blank names and can be cancelled without creating a task',
    (tester) async {
      final plan = DailyPlan(date: _now, tasks: []);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlanScreen(
              plan: plan,
              onTaskCreated: plan.tasks.add,
              onCommitTomorrow: () {},
            ),
          ),
        ),
      );
      await openCommitmentEditor(tester);
      final save = find.byKey(const ValueKey('save-commitment'));
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      await enterPlanText(
        tester,
        find.byKey(const ValueKey('commitment-name')),
        '   ',
      );
      await tester.pump();
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(plan.tasks, isEmpty);
      await tester.tap(find.byTooltip('Close editor'));
      await tester.pumpAndSettle();
      expect(find.byType(CommitmentEditor), findsNothing);
      expect(plan.tasks, isEmpty);
    },
  );

  for (final type in TaskType.values) {
    testWidgets(
      'Creates trimmed ${type.name} in tomorrow only and closes the sheet',
      (tester) async {
        await tester.runAsync(
          () => LocalStorage().save(existingCommitments(_now)),
        );
        await tester.pumpWidget(MainApp(now: () => _now));
        await tester.pumpAndSettle();
        await _page(tester, 'Plan');
        await _add(tester, '  Read a chapter  ', focus: type == TaskType.focus);
        expect(find.byType(CommitmentEditor), findsNothing);
        expect(find.text('Read a chapter'), findsOneWidget);
        final saved = (await LocalStorage().load())!;
        expect(saved.tomorrowPlan.tasks.single.type, type);
        expect(saved.tomorrowPlan.tasks.single.name, 'Read a chapter');
        expect(saved.tomorrowPlan.tasks.single.isCompleted, isFalse);
        expect(saved.todayPlan.tasks, hasLength(3));
        await _page(tester, 'Calendar');
        await _page(tester, 'Today');
        expect(find.text('Read a chapter'), findsNothing);
        expect(find.text('0 / 3 complete'), findsOneWidget);
        await _page(tester, 'Plan');
        expect(find.text('Read a chapter'), findsOneWidget);
        expect(find.byType(TextField), findsNothing);
      },
    );
  }

  testWidgets(
    'Confirmation can cancel; confirming locks both types and preserves Today',
    (tester) async {
      await tester.runAsync(
        () => LocalStorage().save(existingCommitments(_now)),
      );
      await tester.pumpWidget(MainApp(now: () => _now));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Existing goal'));
      await tester.pumpAndSettle();
      await _page(tester, 'Plan');
      await _add(tester, 'Take a walk');
      await _add(tester, 'Read a chapter', focus: true);
      final earlier = tester.widget<PlanScreen>(find.byType(PlanScreen));
      await tester.tap(find.text('COMMIT FRIDAY'));
      await tester.pumpAndSettle();
      expect(earlier.plan.isCommitted, isFalse);
      expect(find.text('Commit tomorrow?'), findsOneWidget);
      await tester.tap(find.text('Keep planning'));
      await tester.pumpAndSettle();
      expect(earlier.plan.isCommitted, isFalse);
      expect(find.text('+ Add commitment'), findsOneWidget);
      await tester.tap(find.text('COMMIT FRIDAY'));
      await confirmPlanCommit(tester);
      expect(find.text("Tomorrow's plan is committed."), findsOneWidget);
      expect(find.text('+ Add commitment'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('COMMIT FRIDAY'), findsNothing);
      earlier.onTaskCreated(Task(name: 'Late addition', type: TaskType.goal));
      earlier.onCommitTomorrow();
      await tester.pumpAndSettle();
      expect(find.text('Late addition'), findsNothing);
      expect(earlier.plan.tasks, hasLength(2));
      await _page(tester, 'Today');
      expect(find.text('1 / 3 complete'), findsOneWidget);
      await _page(tester, 'Plan');
      expect(find.text("Tomorrow's plan is committed."), findsOneWidget);
      final saved = (await LocalStorage().load())!;
      expect(saved.tomorrowPlan.isCommitted, isTrue);
      expect(saved.tomorrowPlan.tasks, hasLength(2));
      expect(tester.takeException(), isNull);
    },
  );
}

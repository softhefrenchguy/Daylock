import 'dart:convert';

import 'package:daylock/main.dart';
import 'package:daylock/design/daylock_plan_rows.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/screens/plan_screen.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'plan_test_helpers.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'fixtures.dart';

DateTime _testNow = DateTime(2026, 10, 7, 12);

void main() {
  setUp(() {
    _testNow = DateTime(2026, 10, 7, 12);
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('Checking, adding, and committing survive app recreation', (
    tester,
  ) async {
    await tester.runAsync(
      () => LocalStorage().save(existingCommitments(_testNow)),
    );
    await tester.pumpWidget(MainApp(now: () => _testNow));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Existing goal'));
    await tester.pumpAndSettle();

    await _openPlan(tester);
    await enterPlanText(
      tester,
      find.byKey(const ValueKey('commitment-name')),
      'Take a walk',
    );
    await tester.pump();
    await tester.ensureVisible(find.text('Add commitment'));
    await tester.tap(find.text('Add commitment'));
    await tester.pumpAndSettle();
    await openCommitmentEditor(tester);
    await tester.ensureVisible(find.text('Focus'));
    await tester.tap(find.text('Focus'));
    await tester.pump();
    await enterPlanText(
      tester,
      find.byKey(const ValueKey('focus-minutes')),
      '60',
    );
    await enterPlanText(
      tester,
      find.byKey(const ValueKey('commitment-name')),
      'Read a chapter',
    );
    await tester.pump();
    await tester.ensureVisible(find.text('Add commitment'));
    await tester.tap(find.text('Add commitment'));
    await tester.pumpAndSettle();

    await _reopenApp(tester);
    expect(find.text('1 / 3 complete'), findsOneWidget);
    expect(
      tester
          .widget<CheckboxListTile>(
            find.widgetWithText(CheckboxListTile, 'Existing goal'),
          )
          .value,
      isTrue,
    );
    expect(find.text('Take a walk'), findsNothing);
    await _openPlan(tester);
    expect(
      find.widgetWithText(DaylockPlanTaskRow, 'Take a walk'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(DaylockPlanTaskRow, 'Read a chapter'),
      findsOneWidget,
    );
    expect(
      tester.widget<PlanScreen>(find.byType(PlanScreen)).plan.isCommitted,
      isFalse,
    );
    expect(find.byKey(const ValueKey('commitment-name')), findsNothing);

    final commitButton = find.ancestor(
      of: find.textContaining(RegExp(r'^COMMIT ')),
      matching: find.byType(FilledButton),
    );
    await tester.ensureVisible(commitButton);
    await tester.tap(commitButton);
    await confirmPlanCommit(tester);
    await tester.pumpAndSettle();
    await _reopenApp(tester);

    expect(find.text('1 / 3 complete'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNWidgets(2));
    await _openPlan(tester);
    expect(find.text("Tomorrow's plan is committed."), findsOneWidget);
    expect(find.byType(DaylockPlanTaskRow), findsNWidgets(2));
    expect(find.byKey(const ValueKey('commitment-name')), findsNothing);
    expect(find.byType(SegmentedButton<TaskType>), findsNothing);

    final restored = (await LocalStorage().load())!;
    expect(restored.tomorrowPlan.isCommitted, isTrue);
    expect(
      restored.todayPlan.tasks
          .singleWhere((task) => task.name == 'Existing goal')
          .isCompleted,
      isTrue,
    );
    expect(restored.tomorrowPlan.tasks.map((task) => task.type), [
      TaskType.goal,
      TaskType.focus,
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Saved empty lists do not get replaced with sample tasks', (
    tester,
  ) async {
    await tester.runAsync(
      () => LocalStorage().save(
        DaylockState(
          todayPlan: DailyPlan(
            date: DateTime(2026, 10, 7),
            tasks: [],
            isCommitted: true,
          ),
          tomorrowPlan: DailyPlan(date: DateTime(2026, 10, 8), tasks: []),
        ),
      ),
    );
    await tester.pumpWidget(MainApp(now: () => _testNow));
    await tester.pumpAndSettle();
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(find.text('0 / 0 complete'), findsOneWidget);
  });

  testWidgets('Broken data stays intact and load can be retried', (
    tester,
  ) async {
    final preferences = SharedPreferencesAsync();
    await tester.runAsync(
      () => preferences.setString(LocalStorage.stateKey, '{broken'),
    );
    await tester.pumpWidget(MainApp(now: () => _testNow));
    await tester.pumpAndSettle();
    expect(find.text('Could not load your saved commitments.'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(
      await tester.runAsync(() => preferences.getString(LocalStorage.stateKey)),
      '{broken',
    );

    await tester.runAsync(
      () => LocalStorage().save(
        DaylockState(
          todayPlan: DailyPlan(
            date: DateTime(2026, 10, 7),
            isCommitted: true,
            tasks: [
              Task(
                name: 'Recovered task',
                type: TaskType.focus,
                accumulatedFocusMilliseconds: Task.legacyFocusMinutes * 60000,
              ),
            ],
          ),
          tomorrowPlan: DailyPlan(
            date: DateTime(2026, 10, 8),
            tasks: [Task(name: 'Locked draft', type: TaskType.goal)],
            isCommitted: true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Recovered task'), findsOneWidget);
    expect(find.text('1 / 1 complete'), findsOneWidget);
    await _openPlan(tester);
    expect(find.text('Locked draft'), findsOneWidget);
    expect(find.text("Tomorrow's plan is committed."), findsOneWidget);
  });

  testWidgets('Legacy state restores completion and the locked tomorrow plan', (
    tester,
  ) async {
    await tester.runAsync(
      () => SharedPreferencesAsync().setString(
        LocalStorage.legacyStateKey,
        jsonEncode({
          'tasks': [
            Task(
              name: 'Legacy today',
              type: TaskType.goal,
              isCompleted: true,
            ).toJson(),
          ],
          'tomorrowTasks': [
            Task(name: 'Legacy tomorrow', type: TaskType.focus).toJson(),
          ],
          'isTomorrowCommitted': true,
        }),
      ),
    );
    await tester.pumpWidget(MainApp(now: () => _testNow));
    await tester.pumpAndSettle();
    expect(find.text('Legacy today'), findsOneWidget);
    expect(find.text('1 / 1 complete'), findsOneWidget);
    expect(find.text('Existing goal'), findsNothing);
    await _openPlan(tester);
    expect(find.text('Legacy tomorrow'), findsOneWidget);
    expect(find.text("Tomorrow's plan is committed."), findsOneWidget);
    expect(find.byKey(const ValueKey('commitment-name')), findsNothing);
    await _reopenApp(tester);
    expect(find.text('1 / 1 complete'), findsOneWidget);
    await _openPlan(tester);
    expect(find.text('Legacy tomorrow'), findsOneWidget);
    expect(
      tester.widget<PlanScreen>(find.byType(PlanScreen)).plan.isCommitted,
      isTrue,
    );
  });

  testWidgets('Screens keep saved date labels on same-day reopening', (
    tester,
  ) async {
    _testNow = DateTime(2020, 12, 31, 16);
    await tester.runAsync(
      () => LocalStorage().save(
        DaylockState(
          todayPlan: DailyPlan(
            date: DateTime(2020, 12, 31),
            tasks: [Task(name: 'Dated today', type: TaskType.goal)],
            isCommitted: true,
          ),
          tomorrowPlan: DailyPlan(
            date: DateTime(2021, 1, 1),
            tasks: [Task(name: 'Dated tomorrow', type: TaskType.focus)],
          ),
        ),
      ),
    );
    await tester.pumpWidget(MainApp(now: () => _testNow));
    await tester.pumpAndSettle();
    expect(find.text('THURSDAY 31 DECEMBER'), findsOneWidget);
    await tester.tap(find.text('Dated today'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 1 complete'), findsOneWidget);
    await _openPlan(tester);
    expect(find.text('COMMIT FRIDAY'), findsOneWidget);
    expect(find.text('Dated tomorrow'), findsOneWidget);
    await tester.ensureVisible(find.text('COMMIT FRIDAY'));
    await tester.tap(find.text('COMMIT FRIDAY'));
    await confirmPlanCommit(tester);
    await tester.pumpAndSettle();
    expect(find.text("Tomorrow's plan is committed."), findsOneWidget);

    await _reopenApp(tester);
    expect(find.text('THURSDAY 31 DECEMBER'), findsOneWidget);
    expect(find.text('1 / 1 complete'), findsOneWidget);
    await _openPlan(tester);
    expect(find.text('COMMIT FRIDAY'), findsNothing);
    expect(
      tester.widget<PlanScreen>(find.byType(PlanScreen)).plan.isCommitted,
      isTrue,
    );
    final saved = (await LocalStorage().load())!;
    expect(saved.todayPlan.date, DateTime(2020, 12, 31));
    expect(saved.tomorrowPlan.date, DateTime(2021, 1, 1));
    expect(saved.todayPlan.tasks.single.isCompleted, isTrue);
  });
}

Future<void> _openPlan(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Plan'),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _reopenApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  await tester.pumpWidget(MainApp(now: () => _testNow));
  await tester.pumpAndSettle();
}

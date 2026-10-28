import 'dart:convert';

import 'package:daylock/design/daylock_illustrations.dart';

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:daylock/design/daylock_theme.dart';
import 'package:daylock/design/daylock_widgets.dart';
import 'package:daylock/models/area.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/freedom_settings.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/screens/today_screen.dart';
import 'package:daylock/screens/plan_screen.dart';
import 'package:daylock/services/freedom_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final at = DateTime(2026, 10, 27, 17);
FreedomEligibility eligibility(
  DailyPlan plan, {
  bool enabled = true,
  bool tomorrow = true,
  DateTime? now,
}) => const FreedomService().evaluate(
  now: now ?? at,
  settings: FreedomSettings(enabled: enabled),
  todayPlan: plan,
  tomorrowPlan: DailyPlan(
    date: DateTime(2026, 10, 28),
    tasks: [],
    isCommitted: tomorrow,
  ),
);
Widget screen(DailyPlan plan, FreedomEligibility freedom, {DateTime? now}) =>
    MaterialApp(
      theme: DaylockTheme.dark,
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, update) => TodayScreen(
            plan: plan,
            currentTime: now ?? at,
            areas: AreaBook.initial(),
            freedomEligibility: freedom,
            onTaskChanged: () => update(() {}),
            onFocusToggled: (task) => update(() {
              if (task.isFocusRunning) {
                task.pauseFocus(now ?? at);
              } else {
                for (final other in plan.tasks) {
                  other.pauseFocus(now ?? at);
                }
                task.startFocus(now ?? at);
              }
            }),
          ),
        ),
      ),
    );
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final config = File('.dart_tool/package_config.json').absolute;
    final packages =
        (jsonDecode(await config.readAsString()) as Map)['packages'] as List;
    final flutter = packages.cast<Map>().singleWhere(
      (entry) => entry['name'] == 'flutter',
    );
    final sdk = Directory.fromUri(
      config.uri.resolve(flutter['rootUri'] as String),
    ).parent.parent;
    final font = File(
      '${sdk.path}/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
    );
    await (FontLoader(
      'Roboto',
    )..addFont(font.readAsBytes().then(ByteData.sublistView))).load();
  });
  testWidgets(
    'Dashboard sums live, paused, completed and excused actual time once',
    (tester) async {
      final running = Task(name: 'Running', accumulatedFocusMilliseconds: 20000)
        ..startFocus(at.subtract(const Duration(seconds: 10)));
      final plan = DailyPlan(
        date: at,
        tasks: [
          running,
          Task(name: 'Paused', accumulatedFocusMilliseconds: 10000),
          Task(
            name: 'Done',
            isCompleted: true,
            accumulatedFocusMilliseconds: 30000,
          ),
          Task(
            name: 'Excused',
            outcome: TaskOutcome.excused,
            excuseReason: 'Ill',
            accumulatedFocusMilliseconds: 40000,
          ),
        ],
      );
      await tester.pumpWidget(screen(plan, eligibility(plan)));
      await tester.pumpAndSettle();
      expect(find.text('1m 50s recorded today'), findsOneWidget);
      expect(find.text('1 / 3 complete'), findsOneWidget);
      expect(plan.tasks.first.accumulatedFocusMilliseconds, 20000);
      expect(find.byKey(const ValueKey('freedom-status')), findsOneWidget);
      expect(find.text('Pause stopwatch'), findsOneWidget);
      expect(find.text('Resume stopwatch'), findsOneWidget);
    },
  );
  for (final mode in ['disabled', 'locked', 'waiting', 'earned']) {
    testWidgets('Freedom $mode is permanently presented using eligibility', (
      tester,
    ) async {
      final completed = mode == 'waiting' || mode == 'earned';
      final plan = DailyPlan(
        date: at,
        tasks: [Task(name: 'Read', isCompleted: completed)],
      );
      final now = mode == 'earned' ? DateTime(2026, 10, 27, 19) : at;
      await tester.pumpWidget(
        screen(
          plan,
          eligibility(plan, enabled: mode != 'disabled', now: now),
          now: now,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('freedom-status')), findsOneWidget);
      final title = switch (mode) {
        'disabled' => 'Freedom Control is off',
        'locked' => 'Freedom not yet earned',
        'waiting' => 'Waiting for Freedom Time',
        _ => 'Freedom earned',
      };
      expect(find.text(title), findsOneWidget);
      expect(find.textContaining('Freedom Time'), findsWidgets);
      expect(
        find.textContaining('eligible commitments complete'),
        findsOneWidget,
      );
      expect(find.textContaining('plan committed'), findsOneWidget);
      if (mode == 'waiting') {
        expect(find.text('Available at 18:00'), findsOneWidget);
      }
      if (mode == 'earned') {
        expect(find.text('100%'), findsOneWidget);
        expect(find.text('Day complete'), findsOneWidget);
      }
    });
  }
  testWidgets(
    'Unstarted and paused commitments offer distinct start and resume controls',
    (tester) async {
      final plan = DailyPlan(
        date: at,
        tasks: [
          Task(name: 'New'),
          Task(name: 'Paused', accumulatedFocusMilliseconds: 12000),
        ],
      );
      await tester.pumpWidget(screen(plan, eligibility(plan)));
      await tester.pumpAndSettle();
      expect(find.text('Start stopwatch'), findsOneWidget);
      expect(find.text('Resume stopwatch'), findsOneWidget);
      await tester.tap(
        find.byKey(ValueKey('stopwatch-toggle-${plan.tasks[1].id}')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pause stopwatch'), findsOneWidget);
      expect(plan.tasks[1].isFocusRunning, isTrue);
    },
  );
  testWidgets(
    'Three commitments and the Freedom card fit above navigation at 390 by 844',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final first = Task(name: 'Study')..startFocus(at);
      final plan = DailyPlan(
        date: at,
        tasks: [
          first,
          Task(name: 'Exercise'),
          Task(name: 'Read', isCompleted: true),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: DaylockTheme.dark,
          home: Scaffold(
            bottomNavigationBar: NavigationBar(
              destinations: const [
                NavigationDestination(icon: Icon(Icons.today), label: 'Today'),
                NavigationDestination(icon: Icon(Icons.edit), label: 'Plan'),
              ],
            ),
            body: TodayScreen(
              plan: plan,
              currentTime: at,
              areas: AreaBook.initial(),
              freedomEligibility: eligibility(plan),
              onTaskChanged: () {},
              onFocusToggled: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getBottomRight(find.byKey(const ValueKey('freedom-status'))).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.byType(NavigationBar)).dy),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Empty draft displays an illustrated empty state and disabled commit',
    (tester) async {
      final plan = DailyPlan(date: DateTime(2026, 10, 28), tasks: []);
      await tester.pumpWidget(
        MaterialApp(
          theme: DaylockTheme.dark,
          home: Scaffold(
            body: PlanScreen(
              plan: plan,
              onTaskCreated: (_) {},
              onCommitTomorrow: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No commitments planned yet.'), findsOneWidget);
      expect(find.byType(DaylockIllustration), findsOneWidget);
      expect(
        find.byKey(const ValueKey('open-commitment-editor')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('open-commitment-editor')),
            )
            .onPressed,
        isNotNull,
      );
      expect(
        tester
            .widget<DaylockAction>(
              find.byKey(const ValueKey('commit-tomorrow')),
            )
            .onPressed,
        isNull,
      );
    },
  );
}

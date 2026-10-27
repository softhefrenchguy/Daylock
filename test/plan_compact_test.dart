import 'package:daylock/design/daylock_palette.dart';
import 'package:daylock/design/daylock_plan_rows.dart';
import 'package:daylock/design/daylock_theme.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/event.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/screens/commitment_editor.dart';
import 'package:daylock/screens/plan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'plan_test_helpers.dart';

final _date = DateTime(2026, 10, 9);

Widget _screen(
  DailyPlan plan, {
  double scale = 1,
  List<Event> events = const [],
}) => MaterialApp(
  theme: DaylockTheme.forPalette(ColourTheme.forest, Brightness.dark),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
    child: child!,
  ),
  home: Scaffold(
    body: StatefulBuilder(
      builder: (context, refresh) => PlanScreen(
        key: ValueKey(plan.date),
        plan: plan,
        events: events,
        onTaskCreated: (task) => refresh(() => plan.tasks.add(task)),
        onCommitTomorrow: () => refresh(() => plan.isCommitted = true),
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: 1,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.today_outlined), label: 'Today'),
        NavigationDestination(
          icon: Icon(Icons.edit_note_outlined),
          label: 'Plan',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          label: 'Calendar',
        ),
      ],
    ),
  ),
);

void _phone(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 640);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
}

Finder _contentScroll() => find.descendant(
  of: find.byKey(const ValueKey('plan-content')),
  matching: find.byType(Scrollable),
);

void main() {
  testWidgets(
    'Schedule is directly below one dated header, before commitments',
    (tester) async {
      _phone(tester);
      final plan = DailyPlan(
        date: _date,
        tasks: [Task(name: 'Walk', type: TaskType.goal)],
      );
      await tester.pumpWidget(
        _screen(
          plan,
          events: [
            Event(
              id: 'lesson',
              title: 'Driving lesson',
              date: _date,
              startTime: EventTime(10, 0),
              endTime: EventTime(12, 0),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('SCHEDULE')).dy,
        lessThan(tester.getTopLeft(find.text('COMMITMENTS')).dy),
      );
      expect(find.textContaining('Tomorrow ·'), findsOneWidget);
      expect(find.text('PREPARING TOMORROW'), findsNothing);
      expect(find.text('10:00–12:00'), findsOneWidget);
      expect(find.text('Local'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('+ Add commitment'), findsOneWidget);
      final footer = tester.getRect(
        find.byKey(const ValueKey('plan-commit-bar')),
      );
      expect(
        footer.bottom,
        lessThanOrEqualTo(tester.getRect(find.byType(NavigationBar)).top),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Short Goal and Focus rows stay compact; long titles grow naturally',
    (tester) async {
      final short = Task(name: 'Walk', type: TaskType.goal);
      final focus = Task(
        name: 'Read',
        type: TaskType.focus,
        minimumFocusMinutes: 60,
      );
      final long = Task(
        name: 'Complete the application for the engineering internship before tomorrow evening',
        type: TaskType.goal,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: DaylockTheme.dark,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 280,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DaylockPlanTaskRow(
                      key: const ValueKey('short'),
                      task: short,
                    ),
                    DaylockPlanTaskRow(
                      key: const ValueKey('focus'),
                      task: focus,
                    ),
                    DaylockPlanTaskRow(key: const ValueKey('long'), task: long),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      final goalHeight = tester
          .getSize(find.byKey(const ValueKey('short')))
          .height;
      expect(goalHeight, lessThanOrEqualTo(48));
      expect(
        tester.getSize(find.byKey(const ValueKey('focus'))).height,
        lessThanOrEqualTo(48),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('long'))).height,
        greaterThan(goalHeight),
      );
      expect(find.text('60 min'), findsNothing);
      expect(find.text('GOAL · COMPLETE ONCE'), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '150 commitments render lazily and final row stays above persistent commit bar',
    (tester) async {
      _phone(tester);
      final plan = DailyPlan(
        date: _date,
        tasks: [
          for (var index = 0; index < 150; index++)
            Task(name: 'Commitment $index', type: TaskType.goal),
        ],
      );
      final snapshot = plan.toJson();
      await tester.pumpWidget(_screen(plan));
      await tester.pumpAndSettle();
      final commit = find.widgetWithText(FilledButton, 'COMMIT FRIDAY');
      final before = tester.getRect(commit);
      expect(commit.hitTestable(), findsOneWidget);
      expect(find.byType(DaylockPlanTaskRow).evaluate().length, lessThan(25));
      await tester.scrollUntilVisible(
        find.text('Commitment 149'),
        500,
        scrollable: _contentScroll(),
        maxScrolls: 30,
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(commit), before);
      expect(
        tester.getBottomRight(find.text('Commitment 149')).dy,
        lessThanOrEqualTo(
          tester.getTopLeft(find.byKey(const ValueKey('plan-commit-bar'))).dy,
        ),
      );
      expect(plan.toJson(), snapshot);
      await tester.tap(commit);
      await tester.pumpAndSettle();
      expect(plan.isCommitted, isFalse);
      await tester.tap(find.text('Keep planning'));
      await tester.pumpAndSettle();
      expect(plan.isCommitted, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Long schedule remains informational and does not enable committing an empty plan',
    (tester) async {
      _phone(tester);
      final plan = DailyPlan(date: _date, tasks: []);
      await tester.pumpWidget(
        _screen(
          plan,
          events: [
            for (var index = 0; index < 80; index++)
              Event(
                id: 'event-$index',
                title: 'Appointment $index',
                date: _date,
              ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DaylockPlanEventRow).evaluate().length, lessThan(20));
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'COMMIT FRIDAY'),
            )
            .onPressed,
        isNull,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('open-commitment-editor')),
        500,
        scrollable: _contentScroll(),
        maxScrolls: 30,
      );
      await tester.pumpAndSettle();
      expect(plan.tasks, isEmpty);
      await openCommitmentEditor(tester);
      expect(find.byType(CommitmentEditor), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final scale in [1.0, 2.0, 3.0]) {
    testWidgets(
      '320px editor keeps Focus controls above keyboard at ${scale}x text',
      (tester) async {
        _phone(tester);
        final plan = DailyPlan(date: _date, tasks: []);
        await tester.pumpWidget(_screen(plan, scale: scale));
        await openCommitmentEditor(tester);
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        await tester.pumpAndSettle();
        await enterPlanText(
          tester,
          find.byKey(const ValueKey('commitment-name')),
          'Read',
        );
        await tester.pumpAndSettle();
        final save = find.byKey(const ValueKey('save-commitment'));
        await tester.ensureVisible(save);
        await tester.pumpAndSettle();
        expect(tester.getBottomRight(save).dy, lessThanOrEqualTo(360));
        expect(save.hitTestable(), findsOneWidget);
        await tester.tap(save);
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        expect(find.byType(CommitmentEditor), findsNothing);
        expect(plan.tasks.single.minimumFocusMinutes, isNull);
        expect(plan.tasks.single.focusTarget, isNull);
        expect(
          find.widgetWithText(FilledButton, 'COMMIT FRIDAY').hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Large-text confirmation and committed footer remain usable with keyboard insets',
    (tester) async {
      _phone(tester);
      final plan = DailyPlan(
        date: _date,
        tasks: [Task(name: 'Walk', type: TaskType.goal)],
      );
      await tester.pumpWidget(_screen(plan, scale: 3));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('COMMIT FRIDAY'));
      await tester.tap(find.text('COMMIT FRIDAY'));
      await tester.pumpAndSettle();
      final cancel = find.text('Keep planning');
      await tester.ensureVisible(cancel);
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      expect(plan.isCommitted, isFalse);
      await tester.tap(find.text('COMMIT FRIDAY'));
      await confirmPlanCommit(tester);
      expect(plan.isCommitted, isTrue);
      expect(
        find.byKey(const ValueKey('open-commitment-editor')),
        findsNothing,
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Your commitments are locked.'));
      final footer = tester.getRect(
        find.byKey(const ValueKey('plan-commit-bar')),
      );
      expect(footer.top, greaterThanOrEqualTo(0));
      expect(find.byType(TextField), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Repeated sheet submission adds once and keeps the app route open',
    (tester) async {
      final plan = DailyPlan(date: _date, tasks: []);
      await tester.pumpWidget(_screen(plan));
      await openCommitmentEditor(tester);
      await enterPlanText(
        tester,
        find.byKey(const ValueKey('commitment-name')),
        'Read',
      );
      final submit = tester
          .widget<TextField>(find.byKey(const ValueKey('commitment-name')))
          .onSubmitted!;
      submit('Read');
      submit('Read');
      await tester.pumpAndSettle();
      expect(plan.tasks, hasLength(1));
      expect(find.byType(PlanScreen), findsOneWidget);
      expect(find.byType(CommitmentEditor), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Dismissed editor rejects a retained submit callback', (
    tester,
  ) async {
    final plan = DailyPlan(date: _date, tasks: []);
    await tester.pumpWidget(_screen(plan));
    await openCommitmentEditor(tester);
    await enterPlanText(
      tester,
      find.byKey(const ValueKey('commitment-name')),
      'Unfinished',
    );
    final submit = tester
        .widget<TextField>(find.byKey(const ValueKey('commitment-name')))
        .onSubmitted!;
    await tester.tap(find.byTooltip('Close editor'));
    await tester.pumpAndSettle();
    submit('Unfinished');
    await tester.pumpAndSettle();
    expect(plan.tasks, isEmpty);
    expect(find.byType(CommitmentEditor), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

import 'package:daylock/design/daylock_palette.dart';
import 'package:daylock/design/daylock_plan_rows.dart';
import 'package:daylock/design/daylock_theme.dart';
import 'package:daylock/models/calendar_account.dart';
import 'package:daylock/models/calendar_cache.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/event.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/screens/plan_screen.dart';
import 'package:daylock/screens/commitment_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'plan_test_helpers.dart';

final _date = DateTime(2026, 10, 9);

DailyPlan _plan({bool locked = false}) => DailyPlan(
  date: _date,
  isCommitted: locked,
  tasks: [
    Task(name: 'Move your body', type: TaskType.goal),
    Task(
      name: 'Read deeply',
      type: TaskType.focus,
      minimumFocusMinutes: 60,
      focusTarget: 'Finish Chapter 7',
    ),
  ],
);

Widget _screen(
  DailyPlan plan, {
  ColourTheme colour = ColourTheme.violet,
  Brightness brightness = Brightness.dark,
  ThemeMode? mode,
  double scale = 1,
  List<Event> events = const [],
  CalendarCache? cache,
}) => MaterialApp(
  theme: DaylockTheme.forPalette(colour, Brightness.light),
  darkTheme: DaylockTheme.forPalette(colour, Brightness.dark),
  themeMode:
      mode ??
      (brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light),
  themeAnimationDuration: Duration.zero,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
    child: child!,
  ),
  home: Scaffold(
    body: StatefulBuilder(
      builder: (context, refresh) => PlanScreen(
        plan: plan,
        events: events,
        calendarCache: cache,
        onTaskCreated: (task) => refresh(() => plan.tasks.add(task)),
        onCommitTomorrow: () => refresh(() {
          if (plan.tasks.isNotEmpty) plan.isCommitted = true;
        }),
      ),
    ),
  ),
);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  for (final colour in ColourTheme.values) {
    for (final brightness in Brightness.values) {
      for (final locked in [false, true]) {
        testWidgets(
          '${colour.name} ${brightness.name} Plan ${locked ? 'committed' : 'draft'} uses semantic theme roles',
          (tester) async {
            final plan = _plan(locked: locked);
            final snapshot = plan.toJson();
            await tester.pumpWidget(
              _screen(plan, colour: colour, brightness: brightness),
            );
            await tester.pumpAndSettle();
            expect(find.textContaining('Tomorrow ·'), findsOneWidget);
            expect(
              find.text(
                'Tomorrow · ${MaterialLocalizations.of(tester.element(find.byType(PlanScreen))).formatFullDate(_date)}',
              ),
              findsOneWidget,
            );
            expect(find.byType(TextField), findsNothing);
            expect(find.byType(DaylockPlanTaskRow), findsNWidgets(2));
            expect(find.text('60 min'), findsOneWidget);
            expect(find.text('Finish Chapter 7'), findsOneWidget);
            expect(find.byType(Checkbox), findsNothing);
            final expected = DaylockTheme.forPalette(colour, brightness);
            expect(
              Theme.of(tester.element(find.byType(PlanScreen))).colorScheme,
              expected.colorScheme,
            );
            final icons = tester.widgetList<Icon>(
              find.descendant(
                of: find.byType(DaylockPlanTaskRow),
                matching: find.byType(Icon),
              ),
            );
            expect(
              icons.every((icon) => icon.color == expected.colorScheme.primary),
              isTrue,
            );
            if (locked) {
              expect(find.byType(TextField), findsNothing);
              expect(find.text('Add commitment'), findsNothing);
              expect(
                find.byKey(const ValueKey('commit-tomorrow')),
                findsNothing,
              );
              final panel = tester.widget<Container>(
                find.byKey(const ValueKey('committed-plan')),
              );
              expect(
                (panel.decoration as BoxDecoration).color,
                expected.extension<DaylockColors>()!.statusSurface,
              );
            } else {
              final commit = find.widgetWithText(FilledButton, 'COMMIT FRIDAY');
              await tester.ensureVisible(commit);
              expect(tester.widget<FilledButton>(commit).onPressed, isNotNull);
              final size = tester.getSize(commit);
              expect(size.height, greaterThanOrEqualTo(52));
              expect(size.width, greaterThan(300));
            }
            expect(plan.toJson(), snapshot);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets(
    'Theme switching and System appearance retain unfinished Focus inputs',
    (tester) async {
      final plan = _plan();
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpWidget(_screen(plan));
      await openCommitmentEditor(tester);
      await _tap(tester, find.text('Focus'));
      await enterPlanText(
        tester,
        find.byKey(const ValueKey('commitment-name')),
        'Study Pega',
      );
      await enterPlanText(
        tester,
        find.byKey(const ValueKey('focus-minutes')),
        '45',
      );
      await enterPlanText(
        tester,
        find.byKey(const ValueKey('focus-target')),
        'Finish module',
      );
      for (final colour in ColourTheme.values) {
        for (final brightness in Brightness.values) {
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          await tester.pumpWidget(
            _screen(plan, colour: colour, mode: ThemeMode.system),
          );
          await tester.pumpAndSettle();
          expect(
            Theme.of(tester.element(find.byType(PlanScreen))).colorScheme,
            DaylockTheme.forPalette(colour, brightness).colorScheme,
          );
          expect(
            Theme.of(tester.element(find.byType(CommitmentEditor))).colorScheme,
            DaylockTheme.forPalette(colour, brightness).colorScheme,
          );
          expect(
            tester
                .widget<TextField>(
                  find.byKey(const ValueKey('commitment-name')),
                )
                .controller!
                .text,
            'Study Pega',
          );
          expect(
            tester
                .widget<TextField>(find.byKey(const ValueKey('focus-minutes')))
                .controller!
                .text,
            '45',
          );
          expect(
            tester
                .widget<TextField>(find.byKey(const ValueKey('focus-target')))
                .controller!
                .text,
            'Finish module',
          );
        }
      }
      await _tap(tester, find.text('Add commitment'));
      expect(plan.tasks.last.name, 'Study Pega');
      expect(plan.tasks.last.minimumFocusMinutes, 45);
      expect(plan.tasks.last.focusTarget, 'Finish module');
      expect(plan.isCommitted, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  for (final brightness in Brightness.values) {
    for (final scale in [1.0, 2.0, 3.0]) {
      testWidgets(
        '320px ${brightness.name} Plan supports ${scale}x text, wrapped rows and committing',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(320, 640);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final plan = _plan();
          plan.tasks.first.name =
              'Complete the application for the engineering internship';
          await tester.pumpWidget(
            _screen(plan, brightness: brightness, scale: scale),
          );
          await tester.pumpAndSettle();
          await openCommitmentEditor(tester);
          await _tap(tester, find.text('Focus'));
          await enterPlanText(
            tester,
            find.byKey(const ValueKey('commitment-name')),
            'Practice',
          );
          await enterPlanText(
            tester,
            find.byKey(const ValueKey('focus-minutes')),
            '0',
          );
          await tester.pumpAndSettle();
          expect(
            find.text('Enter a whole number greater than zero.'),
            findsOneWidget,
          );
          expect(
            tester
                .widget<FilledButton>(
                  find.widgetWithText(FilledButton, 'Add commitment'),
                )
                .onPressed,
            isNull,
          );
          await enterPlanText(
            tester,
            find.byKey(const ValueKey('focus-minutes')),
            '30',
          );
          await tester.pumpAndSettle();
          await _tap(tester, find.text('Add commitment'));
          expect(plan.tasks.last.minimumFocusMinutes, 30);
          await tester.pump(const Duration(seconds: 4));
          await tester.pumpAndSettle();
          await _tap(tester, find.text('COMMIT FRIDAY'));
          await confirmPlanCommit(tester);
          expect(plan.isCommitted, isTrue);
          expect(find.byType(TextField), findsNothing);
          expect(find.text('Your commitments are locked.'), findsOneWidget);
          expect(plan.tasks, hasLength(3));
          await tester.scrollUntilVisible(
            find.text('Practice'),
            300,
            scrollable: find.descendant(
              of: find.byKey(const ValueKey('plan-content')),
              matching: find.byType(Scrollable),
            ),
          );
          await tester.ensureVisible(
            find.byKey(const ValueKey('committed-plan')),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'Empty committed Plan remains locked without a form or commit action',
    (tester) async {
      final plan = DailyPlan(date: _date, tasks: [], isCommitted: true);
      await tester.pumpWidget(_screen(plan));
      await tester.pumpAndSettle();
      expect(find.text('No commitments planned yet.'), findsOneWidget);
      expect(find.text('No scheduled events for tomorrow.'), findsOneWidget);
      expect(find.text("Tomorrow's plan is committed."), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
      expect(plan.isCommitted, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Schedule uses concise provider labels, date filtering and no external editing or completion',
    (tester) async {
      final accounts = [
        for (final provider in CalendarProviderType.values)
          CalendarAccount(
            provider: provider,
            providerAccountId: 'remote-${provider.name}',
            displayName: 'A very long account name',
            email: 'long.email.address@example.test',
          ),
      ];
      final calendars = [
        for (final account in accounts)
          ConnectedCalendar(
            accountId: account.id,
            id: 'technical-calendar-id',
            name: 'Main',
          ),
      ];
      final events = [
        for (final account in accounts)
          Event.externalAllDay(
            source: account.provider.eventSource,
            accountId: account.id,
            calendarId: 'technical-calendar-id',
            externalEventId: 'meeting',
            title: '${account.provider.name} meeting',
            date: _date,
            endDateExclusive: DateTime(2026, 10, 10),
          ),
      ];
      final cache = CalendarCache(
        accounts: accounts,
        calendars: calendars,
        events: events,
      );
      final plan = DailyPlan(date: _date, tasks: []);
      await tester.pumpWidget(
        _screen(
          plan,
          cache: cache,
          events: [
            ...cache.visibleEvents,
            Event(
              id: 'local',
              title: 'Driving lesson',
              date: _date,
              startTime: EventTime(10, 0),
              endTime: EventTime(12, 0),
            ),
            Event(
              id: 'another-day',
              title: 'Not tomorrow',
              date: DateTime(2026, 10, 11),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('10:00–12:00'), findsOneWidget);
      expect(find.text('Driving lesson'), findsOneWidget);
      expect(find.text('Local'), findsOneWidget);
      for (final account in accounts) {
        expect(find.text(account.provider.eventSource.label), findsOneWidget);
      }
      expect(find.textContaining('@example.test'), findsNothing);
      expect(find.textContaining('technical-calendar-id'), findsNothing);
      expect(find.text('Not tomorrow'), findsNothing);
      expect(find.byType(DaylockPlanEventRow), findsNWidgets(4));
      expect(find.byType(Checkbox), findsNothing);
      expect(find.byTooltip('Edit Driving lesson'), findsNothing);
      expect(find.text('0'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'COMMIT FRIDAY'),
            )
            .onPressed,
        isNull,
      );
      expect(plan.tasks, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}

import 'dart:async';

import 'package:daylock/design/daylock_task_row.dart';
import 'package:daylock/design/daylock_theme.dart';
import 'package:daylock/design/daylock_widgets.dart';
import 'package:daylock/design/appearance_preferences.dart';
import 'package:daylock/services/appearance_storage.dart';
import 'package:daylock/main.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/screens/today_screen.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final _date = DateTime(2026, 10, 8, 9);

Widget _screen({
  required List<Task> tasks,
  Brightness brightness = Brightness.light,
  double scale = 1,
  bool reducedMotion = false,
  VoidCallback? onPlan,
}) => MaterialApp(
  theme: DaylockTheme.light,
  darkTheme: DaylockTheme.dark,
  themeMode: brightness == Brightness.light ? ThemeMode.light : ThemeMode.dark,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(scale),
      disableAnimations: reducedMotion,
    ),
    child: child!,
  ),
  home: Scaffold(
    body: StatefulBuilder(
      builder: (context, refresh) => TodayScreen(
        plan: DailyPlan(date: _date, tasks: tasks),
        currentTime: _date,
        onTaskChanged: () => refresh(() {}),
        onSettingsRequested: () {},
        onPlanRequested: onPlan,
        onFocusToggled: (task) => refresh(() {
          if (task.isFocusRunning) {
            task.pauseFocus(_date);
          } else {
            task.startFocus(_date);
          }
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
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  test('Design colors have accessible contrast in both themes', () {
    for (final theme in [DaylockTheme.light, DaylockTheme.dark]) {
      final colors = theme.colorScheme;
      for (final pair in [
        (colors.onSurface, colors.surface),
        (colors.onSurfaceVariant, colors.surface),
        (colors.primary, colors.surface),
        (colors.onPrimary, colors.primary),
        (DaylockTheme.highlight, const Color(0xFF211A2E)),
        (DaylockTheme.lightBackground, const Color(0xFF302245)),
      ]) {
        final a = pair.$1.computeLuminance();
        final b = pair.$2.computeLuminance();
        expect(
          ((a > b ? a : b) + 0.05) / ((a > b ? b : a) + 0.05),
          greaterThanOrEqualTo(4.5),
        );
      }
    }
    expect(DaylockTheme.light.scaffoldBackgroundColor, const Color(0xFFF8F6FC));
    expect(DaylockTheme.dark.scaffoldBackgroundColor, const Color(0xFF171321));
  });

  testWidgets(
    'System brightness applies during loading and follows changes after launch',
    (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final storage = _DelayedStorage();
      await tester.runAsync(
        () => AppearanceStorage().save(
          const AppearancePreferences(mode: AppearanceMode.system),
        ),
      );
      await tester.pumpWidget(MainApp(storage: storage, now: () => _date));
      await tester.pump();
      expect(find.text('Getting your day ready.'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        Theme.of(tester.element(find.byType(DaylockLoadState))).brightness,
        Brightness.dark,
      );
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.system);
      storage.ready.complete();
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(TodayScreen))).brightness,
        Brightness.dark,
      );
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(TodayScreen))).brightness,
        Brightness.light,
      );
      await _tap(tester, find.text('Plan tomorrow'));
      expect(find.text('No commitments planned yet.'), findsOneWidget);
    },
  );

  testWidgets('Empty Today stays neutral and explains Freedom eligibility', (
    tester,
  ) async {
    var openPlan = false;
    await tester.pumpWidget(_screen(tasks: [], onPlan: () => openPlan = true));
    await tester.pumpAndSettle();
    expect(find.text('A clear day.'), findsOneWidget);
    expect(find.text('0 / 0 complete'), findsOneWidget);
    expect(find.text('Day complete'), findsNothing);
    expect(find.textContaining('18:00'), findsOneWidget);
    expect(find.text('Freedom Control is off'), findsOneWidget);
    expect(find.textContaining('No eligible commitments'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNothing);
    await _tap(tester, find.text('Plan tomorrow'));
    expect(openPlan, isTrue);
  });

  testWidgets(
    'Goal completion animates progress and updates Freedom conditions',
    (tester) async {
      final goal = Task(name: 'Take a walk', type: TaskType.goal);
      await tester.pumpWidget(_screen(tasks: [goal]));
      await tester.pumpAndSettle();
      expect(find.text('Freedom Control is off'), findsOneWidget);
      expect(find.text('0 / 1 eligible commitments complete'), findsOneWidget);
      await _tap(tester, find.text('Take a walk'));
      expect(goal.isCompleted, isTrue);
      expect(find.text('1 / 1 complete'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Day complete'), findsOneWidget);
      expect(find.text('1 / 1 eligible commitments complete'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        1,
      );
      await _tap(tester, find.text('Take a walk'));
      expect(goal.isCompleted, isFalse);
      expect(find.text('Day complete'), findsNothing);
    },
  );

  testWidgets(
    'Focus shows elapsed seconds, target and a large accessible control without a checkbox',
    (tester) async {
      final focus = Task(
        name: 'Read',
        type: TaskType.focus,
        minimumFocusMinutes: 60,
        focusTarget: 'Finish Chapter 7',
        accumulatedFocusMilliseconds: 23 * 60000 + 12000,
      );
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_screen(tasks: [focus]));
      await tester.pumpAndSettle();
      expect(find.text('23:12'), findsOneWidget);
      expect(find.text('23 / 60 min'), findsOneWidget);
      expect(find.text('Finish Chapter 7'), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
      final control = find.widgetWithText(FilledButton, 'Start');
      await tester.ensureVisible(control);
      expect(tester.getSize(control).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(control).width, greaterThan(200));
      expect(find.bySemanticsLabel(RegExp('Start focus: Read')), findsWidgets);
      await _tap(tester, control);
      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('FOCUS / RUNNING'), findsOneWidget);
      expect(focus.isCompleted, isFalse);
      await _tap(tester, find.widgetWithText(FilledButton, 'Pause'));
      expect(focus.isFocusRunning, isFalse);
      semantics.dispose();
    },
  );

  testWidgets(
    'Completed Focus is disabled and reduced motion skips progress/completion animations',
    (tester) async {
      final focus = Task(
        name: 'Read',
        type: TaskType.focus,
        minimumFocusMinutes: 1,
        accumulatedFocusMilliseconds: 60000,
      );
      await tester.pumpWidget(_screen(tasks: [focus], reducedMotion: true));
      await tester.pump();
      final control = find.widgetWithText(FilledButton, 'Complete');
      expect(tester.widget<FilledButton>(control).onPressed, isNull);
      expect(find.text('Day complete'), findsOneWidget);
      for (final animation in tester.widgetList<TweenAnimationBuilder<double>>(
        find.byType(TweenAnimationBuilder<double>),
      )) {
        expect(animation.duration, Duration.zero);
      }
      for (final indicator in tester.widgetList<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      )) {
        expect(indicator.value, 1);
      }
    },
  );

  for (final brightness in Brightness.values) {
    for (final scale in [1.0, 1.6, 2.0]) {
      testWidgets(
        'Small screen and long commitments remain usable at $scale text scale in $brightness',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(320, 568);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          final tasks = [
            Task(
              name: 'A long goal commitment that wraps over several lines',
              type: TaskType.goal,
            ),
            Task(
              name: 'Study a complicated chapter and practice the examples',
              type: TaskType.focus,
              minimumFocusMinutes: 180,
              accumulatedFocusMilliseconds: 75 * 60000,
              focusTarget: 'An optional target that should stay readable when the text is enlarged',
            ),
            Task(name: 'Another goal', type: TaskType.goal),
          ];
          await tester.pumpWidget(
            _screen(tasks: tasks, brightness: brightness, scale: scale),
          );
          await tester.pumpAndSettle();
          await _tap(tester, find.widgetWithText(FilledButton, 'Start'));
          await _tap(tester, find.widgetWithText(FilledButton, 'Pause'));
          await _tap(tester, find.text('Another goal'));
          expect(tasks.last.isCompleted, isTrue);
          tasks[1].accumulatedFocusMilliseconds = 180 * 60000;
          await tester.pumpWidget(
            _screen(tasks: tasks, brightness: brightness, scale: scale),
          );
          await tester.pumpAndSettle();
          final completedControl = find.widgetWithText(
            FilledButton,
            'Complete',
          );
          await tester.ensureVisible(completedControl);
          expect(
            tester.widget<FilledButton>(completedControl).onPressed,
            isNull,
          );
          await tester.ensureVisible(
            find.byKey(const ValueKey('freedom-status')),
          );
          expect(tester.takeException(), isNull);
          expect(find.byType(DaylockTaskRow), findsNWidgets(3));
        },
      );
    }
  }
}

class _DelayedStorage extends LocalStorage {
  final ready = Completer<void>();
  @override
  Future<DaylockState?> load() async {
    await ready.future;
    return null;
  }

  @override
  Future<void> save(DaylockState state) async {}
}

import 'package:daylock/design/daylock_freedom_status.dart';
import 'package:daylock/design/appearance_preferences.dart';
import 'package:daylock/design/daylock_palette.dart';
import 'package:daylock/design/daylock_theme.dart';
import 'package:daylock/main.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/freedom_settings.dart';
import 'package:daylock/models/routine.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/screens/plan_screen.dart';
import 'package:daylock/screens/routine_editor.dart';
import 'package:daylock/screens/routines_screen.dart';
import 'package:daylock/screens/settings_screen.dart';
import 'package:daylock/services/freedom_service.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:daylock/services/routine_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'plan_test_helpers.dart';

final _date = DateTime(2026, 10, 13, 18);
Task _goal(String name, {bool completed = false}) =>
    Task(name: name, type: TaskType.goal, isCompleted: completed);
RoutineBook _book() => RoutineBook([
  Routine(
    id: 'training',
    name: 'Training',
    steps: [
      RoutineStep(id: 'push', name: 'Push', type: TaskType.goal),
      RoutineStep(
        id: 'pull',
        name: 'Pull',
        type: TaskType.focus,
        minimumFocusMinutes: 35,
        focusTarget: 'Technique practice',
      ),
    ],
  ),
]);
DaylockState _state({
  bool tomorrowCommitted = true,
  bool freedomEnabled = true,
  List<Task>? todayTasks,
  bool routines = false,
}) => DaylockState(
  todayPlan: DailyPlan(
    date: _date,
    isCommitted: true,
    tasks: todayTasks ?? [_goal('Today goal', completed: true)],
  ),
  tomorrowPlan: DailyPlan(
    date: DateTime(2026, 10, 14),
    tasks: [_goal('Tomorrow goal')],
    isCommitted: tomorrowCommitted,
  ),
  freedomSettings: FreedomSettings(enabled: freedomEnabled),
  routines: routines ? _book() : RoutineBook.empty,
);
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.pumpAndSettle();
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .last,
      maxScrolls: 40,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _key(String key) => find.byKey(ValueKey(key));
Future<void> _page(WidgetTester tester, String label) => _tap(
  tester,
  find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
);
Future<DaylockState> _saved(WidgetTester tester) async =>
    (await tester.runAsync<DaylockState?>(() => LocalStorage().load()))!;
Future<void> _seed(WidgetTester tester, DaylockState state) =>
    tester.runAsync(() => LocalStorage().save(state));
void _resume(WidgetTester tester) {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  testWidgets(
    'Settings enables Freedom and chooses a persisted local time without changing plans',
    (tester) async {
      final state = _state(freedomEnabled: false);
      await _seed(tester, state);
      await tester.pumpWidget(MainApp(now: () => _date));
      await tester.pumpAndSettle();
      expect(find.text('Freedom Control is off'), findsOneWidget);
      await _tap(tester, find.byTooltip('Settings'));
      await _tap(tester, _key('freedom-enabled'));
      expect(
        tester.widget<SwitchListTile>(_key('freedom-enabled')).value,
        isTrue,
      );
      await _tap(tester, _key('freedom-time'));
      await _tap(tester, find.byIcon(Icons.keyboard_outlined));
      final fields = find.descendant(
        of: find.byType(TimePickerDialog),
        matching: find.byType(TextField),
      );
      final use24Hour = MediaQuery.alwaysUse24HourFormatOf(
        tester.element(find.byType(TimePickerDialog)),
      );
      await tester.enterText(fields.at(0), use24Hour ? '19' : '7');
      await tester.enterText(fields.at(1), '30');
      await _tap(tester, find.text('OK'));
      final saved = await _saved(tester);
      expect(saved.freedomSettings.enabled, isTrue);
      expect(saved.freedomSettings.minute, 30);
      expect(saved.freedomSettings.hour, 19);
      expect(saved.todayPlan.toJson(), state.todayPlan.toJson());
      expect(saved.tomorrowPlan.toJson(), state.tomorrowPlan.toJson());
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(MainApp(now: () => _date));
      await tester.pumpAndSettle();
      await _tap(tester, find.byTooltip('Settings'));
      expect(
        tester
            .widget<SettingsScreen>(find.byType(SettingsScreen))
            .freedomSettings
            .toJson(),
        saved.freedomSettings.toJson(),
      );
      await _tap(tester, _key('freedom-enabled'));
      expect((await _saved(tester)).freedomSettings.enabled, isFalse);
    },
  );

  testWidgets(
    'Clock boundary and clock moving back update Freedom with no active timer',
    (tester) async {
      var now = DateTime(2026, 10, 13, 17, 59, 59);
      await _seed(tester, _state());
      await tester.pumpWidget(MainApp(now: () => now));
      await tester.pumpAndSettle();
      expect(find.text('Freedom not yet earned'), findsOneWidget);
      now = _date;
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Freedom earned'), findsOneWidget);
      expect(
        find.text('Instagram control is configured in Settings.'),
        findsOneWidget,
      );
      now = DateTime(2026, 10, 13, 17);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Freedom not yet earned'), findsOneWidget);
    },
  );

  testWidgets(
    'Resume uses the current timezone and rolls over at the new local date',
    (tester) async {
      tzdata.initializeTimeZones();
      final instant = DateTime.utc(2026, 10, 13, 15);
      DateTime now = tz.TZDateTime.from(instant, tz.getLocation('Asia/Qatar'));
      await _seed(tester, _state());
      await tester.pumpWidget(MainApp(now: () => now));
      await tester.pumpAndSettle();
      expect(find.text('Freedom earned'), findsOneWidget);
      now = tz.TZDateTime.from(instant, tz.getLocation('Europe/London'));
      _resume(tester);
      await tester.pumpAndSettle();
      expect(find.text('Freedom not yet earned'), findsOneWidget);
      now = tz.TZDateTime.from(instant, tz.getLocation('Pacific/Auckland'));
      _resume(tester);
      await tester.pumpAndSettle();
      final saved = await _saved(tester);
      expect(saved.todayPlan.date, DateTime(2026, 10, 14));
      expect(saved.tomorrowPlan.isCommitted, isFalse);
      expect(saved.freedomSettings.enabled, isTrue);
      expect(find.text('Freedom not yet earned'), findsOneWidget);
    },
  );

  testWidgets(
    'Completing Today and committing tomorrow update eligibility immediately',
    (tester) async {
      await _seed(
        tester,
        _state(tomorrowCommitted: false, todayTasks: [_goal('Today goal')]),
      );
      await tester.pumpWidget(MainApp(now: () => _date));
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Today goal'));
      expect(find.text('Freedom not yet earned'), findsOneWidget);
      await _page(tester, 'Plan');
      await _tap(tester, _key('commit-tomorrow'));
      await confirmPlanCommit(tester);
      await _page(tester, 'Today');
      expect(find.text('Freedom earned'), findsOneWidget);
      await _tap(tester, find.text('Today goal'));
      expect(find.text('Freedom not yet earned'), findsOneWidget);
    },
  );

  testWidgets(
    'Excusing remaining commitment earns Freedom but all-excused is neutral',
    (tester) async {
      await _seed(
        tester,
        _state(
          todayTasks: [_goal('Done', completed: true), _goal('Unavailable')],
        ),
      );
      await tester.pumpWidget(MainApp(now: () => _date));
      await tester.pumpAndSettle();
      expect(find.text('Freedom not yet earned'), findsOneWidget);
      await tester.longPress(find.text('Unavailable'));
      await tester.pumpAndSettle();
      await _tap(tester, _key('task-excuse'));
      await tester.enterText(_key('excuse-reason'), 'Buyer did not arrive');
      await _tap(tester, _key('confirm-excuse'));
      expect(find.text('Freedom earned'), findsOneWidget);
      expect(find.text('1 / 1 eligible commitments complete'), findsOneWidget);
      await tester.longPress(find.text('Done'));
      await tester.pumpAndSettle();
      await _tap(tester, _key('task-excuse'));
      await tester.enterText(_key('excuse-reason'), 'Not possible');
      await _tap(tester, _key('confirm-excuse'));
      expect(find.text('Freedom not yet earned'), findsOneWidget);
      expect(
        find.textContaining('completion is required to earn Freedom'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'A background Focus session updates Freedom when its minimum is earned',
    (tester) async {
      var now = _date;
      await _seed(
        tester,
        _state(
          todayTasks: [
            Task(name: 'Read', type: TaskType.focus, minimumFocusMinutes: 1),
          ],
        ),
      );
      await tester.pumpWidget(MainApp(now: () => now));
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Start'));
      expect(find.text('Freedom not yet earned'), findsOneWidget);
      now = now.add(const Duration(minutes: 2));
      _resume(tester);
      await tester.pumpAndSettle();
      expect(find.text('Freedom earned'), findsOneWidget);
      final task = (await _saved(tester)).todayPlan.tasks.single;
      expect(task.isCompleted, isTrue);
      expect(task.isFocusRunning, isFalse);
      expect(task.accumulatedFocusMilliseconds, 60000);
    },
  );

  testWidgets(
    'Accept creates tomorrow only, rejects duplicates and next date advances the cycle',
    (tester) async {
      var now = _date;
      await _seed(tester, _state(tomorrowCommitted: false, routines: true));
      await tester.pumpWidget(MainApp(now: () => now));
      await tester.pumpAndSettle();
      await _page(tester, 'Plan');
      expect(find.text('Push'), findsNothing);
      await _tap(tester, find.text('ROUTINE SUGGESTIONS'));
      expect(find.text('Push'), findsOneWidget);
      final oldScreen = tester.widget<PlanScreen>(find.byType(PlanScreen));
      final suggestion = oldScreen.routineSuggestions.single;
      await _tap(tester, _key('routine-accept-training'));
      oldScreen.onRoutineAction!(suggestion, RoutineAction.accept);
      await tester.pumpAndSettle();
      final saved = await _saved(tester);
      expect(saved.tomorrowPlan.tasks.map((task) => task.name), [
        'Tomorrow goal',
        'Push',
      ]);
      expect(saved.todayPlan.tasks.single.name, 'Today goal');
      expect(saved.tomorrowPlan.isCommitted, isFalse);
      expect(saved.routines.routines.single.nextStep.name, 'Pull');
      expect(find.byKey(const ValueKey('routine-suggestions')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(MainApp(now: () => now));
      await tester.pumpAndSettle();
      await _page(tester, 'Plan');
      expect(_key('routine-suggestions'), findsNothing);
      now = DateTime(2026, 10, 14, 18);
      _resume(tester);
      await tester.pumpAndSettle();
      await _tap(tester, find.text('ROUTINE SUGGESTIONS'));
      expect(find.text('Pull'), findsOneWidget);
      expect(find.textContaining('35 min'), findsOneWidget);
      expect(find.text('Technique practice'), findsOneWidget);
      await _tap(tester, _key('routine-accept-training'));
      final next = await _saved(tester);
      expect(next.tomorrowPlan.tasks.single.type, TaskType.focus);
      expect(next.tomorrowPlan.tasks.single.minimumFocusMinutes, 35);
      expect(next.tomorrowPlan.tasks.single.focusTarget, 'Technique practice');
      expect(next.tomorrowPlan.tasks.single.accumulatedFocusMilliseconds, 0);
    },
  );

  for (final action in [RoutineAction.skip, RoutineAction.dismiss]) {
    testWidgets(
      '${action.name} hides only this date and never creates a commitment',
      (tester) async {
        var now = _date;
        await _seed(tester, _state(tomorrowCommitted: false, routines: true));
        await tester.pumpWidget(MainApp(now: () => now));
        await tester.pumpAndSettle();
        await _page(tester, 'Plan');
        await _tap(tester, find.text('ROUTINE SUGGESTIONS'));
        await _tap(tester, _key('routine-${action.name}-training'));
        final saved = await _saved(tester);
        expect(saved.tomorrowPlan.tasks.map((task) => task.name), [
          'Tomorrow goal',
        ]);
        expect(saved.tomorrowPlan.isCommitted, isFalse);
        now = DateTime(2026, 10, 14, 18);
        _resume(tester);
        await tester.pumpAndSettle();
        await _tap(tester, find.text('ROUTINE SUGGESTIONS'));
        expect(
          find.text(action == RoutineAction.skip ? 'Pull' : 'Push'),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets(
    'Committed plan hides routine actions and rejects a retained accept callback',
    (tester) async {
      await _seed(tester, _state(tomorrowCommitted: false, routines: true));
      await tester.pumpWidget(MainApp(now: () => _date));
      await tester.pumpAndSettle();
      await _page(tester, 'Plan');
      final old = tester.widget<PlanScreen>(find.byType(PlanScreen));
      await _tap(tester, _key('commit-tomorrow'));
      await confirmPlanCommit(tester);
      old.onRoutineAction!(old.routineSuggestions.single, RoutineAction.accept);
      await tester.pumpAndSettle();
      expect(_key('routine-suggestions'), findsNothing);
      final saved = await _saved(tester);
      expect(saved.tomorrowPlan.tasks, hasLength(1));
      expect(saved.routines.routines.single.nextStep.name, 'Push');
      expect(saved.routines.routines.single.decisions, isEmpty);
    },
  );

  testWidgets('Rollover rejects a retained suggestion for yesterday’s draft', (
    tester,
  ) async {
    var now = _date;
    await _seed(tester, _state(tomorrowCommitted: false, routines: true));
    await tester.pumpWidget(MainApp(now: () => now));
    await tester.pumpAndSettle();
    await _page(tester, 'Plan');
    final old = tester.widget<PlanScreen>(find.byType(PlanScreen));
    now = DateTime(2026, 10, 14);
    old.onRoutineAction!(old.routineSuggestions.single, RoutineAction.accept);
    await tester.pumpAndSettle();
    final saved = await _saved(tester);
    expect(saved.tomorrowPlan.tasks, isEmpty);
    expect(saved.routines.routines.single.nextStep.name, 'Push');
    expect(saved.routines.routines.single.decisions, isEmpty);
  });

  testWidgets(
    'Settings creates ordered Goal/Focus routine, edits, reorders and confirms deletion',
    (tester) async {
      await _seed(tester, _state(tomorrowCommitted: false));
      await tester.pumpWidget(MainApp(now: () => _date));
      await tester.pumpAndSettle();
      await _tap(tester, find.byTooltip('Settings'));
      await _tap(tester, _key('manage-routines'));
      await _tap(tester, _key('create-routine'));
      expect(
        tester.widget<FilledButton>(_key('save-routine')).onPressed,
        isNull,
      );
      await tester.enterText(_key('routine-name'), 'Reading cycle');
      await _tap(tester, _key('add-routine-step'));
      await tester.enterText(_key('commitment-name'), 'Visit library');
      await _tap(tester, _key('save-commitment'));
      await _tap(tester, _key('add-routine-step'));
      await _tap(tester, find.text('Focus'));
      await tester.enterText(_key('commitment-name'), 'Read book');
      await tester.enterText(_key('focus-minutes'), '0');
      expect(
        tester.widget<FilledButton>(_key('save-commitment')).onPressed,
        isNull,
      );
      await tester.enterText(_key('focus-minutes'), '25');
      await tester.enterText(_key('focus-target'), 'Chapter 7');
      await _tap(tester, _key('save-commitment'));
      await _tap(tester, find.byTooltip('Move step 2 up'));
      await _tap(tester, _key('save-routine'));
      expect(find.byType(RoutinesScreen), findsOneWidget);
      final routine = (await _saved(tester)).routines.routines.single;
      expect(routine.steps.map((step) => step.name), [
        'Read book',
        'Visit library',
      ]);
      expect(routine.steps.first.minimumFocusMinutes, 25);
      expect(routine.steps.first.focusTarget, 'Chapter 7');
      await _tap(tester, find.text('Edit'));
      await _tap(tester, find.byTooltip('Edit step 1'));
      expect(
        tester.widget<TextField>(_key('focus-minutes')).controller!.text,
        '25',
      );
      await tester.enterText(_key('focus-minutes'), '40');
      await _tap(tester, _key('save-commitment'));
      await _tap(tester, _key('save-routine'));
      expect(
        (await _saved(tester))
            .routines
            .routines
            .single
            .steps
            .first
            .minimumFocusMinutes,
        40,
      );
      await _tap(tester, _key('delete-routine-${routine.id}'));
      await _tap(tester, find.text('Cancel'));
      expect((await _saved(tester)).routines.routines, hasLength(1));
      await _tap(tester, _key('delete-routine-${routine.id}'));
      await _tap(
        tester,
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Delete'),
        ),
      );
      expect((await _saved(tester)).routines.routines, isEmpty);
      expect((await _saved(tester)).tomorrowPlan.tasks, hasLength(1));
    },
  );

  testWidgets(
    'Deleting a routine keeps its accepted commitment and later history',
    (tester) async {
      var now = _date;
      await _seed(tester, _state(tomorrowCommitted: false, routines: true));
      await tester.pumpWidget(MainApp(now: () => now));
      await tester.pumpAndSettle();
      await _page(tester, 'Plan');
      await _tap(tester, find.text('ROUTINE SUGGESTIONS'));
      await _tap(tester, _key('routine-accept-training'));
      await _page(tester, 'Today');
      await _tap(tester, find.byTooltip('Settings'));
      await _tap(tester, _key('manage-routines'));
      await _tap(tester, _key('delete-routine-training'));
      await _tap(
        tester,
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Delete'),
        ),
      );
      expect(
        (await _saved(tester)).tomorrowPlan.tasks.map((task) => task.name),
        ['Tomorrow goal', 'Push'],
      );
      now = DateTime(2026, 10, 14);
      _resume(tester);
      await tester.pumpAndSettle();
      now = DateTime(2026, 10, 15);
      _resume(tester);
      await tester.pumpAndSettle();
      final saved = await _saved(tester);
      expect(saved.routines.routines, isEmpty);
      expect(
        saved.history
            .forDate(DateTime(2026, 10, 14))!
            .tasks
            .map((task) => task.name),
        ['Tomorrow goal', 'Push'],
      );
    },
  );

  testWidgets(
    'Failed routine save leaves the prior save intact and Retry saves the choice once',
    (tester) async {
      final initial = _state(tomorrowCommitted: false, routines: true);
      await _seed(tester, initial);
      final storage = _FailingStorage();
      await tester.pumpWidget(MainApp(storage: storage, now: () => _date));
      await tester.pumpAndSettle();
      await _page(tester, 'Plan');
      await _tap(tester, find.text('ROUTINE SUGGESTIONS'));
      await _tap(tester, _key('routine-accept-training'));
      expect(find.text('Could not save your changes.'), findsOneWidget);
      expect((await _saved(tester)).toJson(), initial.toJson());
      storage.fail = false;
      await _tap(tester, find.text('Retry'));
      final saved = await _saved(tester);
      expect(saved.tomorrowPlan.tasks.map((task) => task.name), [
        'Tomorrow goal',
        'Push',
      ]);
      expect(saved.routines.routines.single.decisions, hasLength(1));
      expect(saved.routines.routines.single.nextStep.name, 'Pull');
    },
  );

  testWidgets('Freedom Settings remains usable at 320px and 200 percent text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var settings = const FreedomSettings();
    await tester.pumpWidget(
      MaterialApp(
        theme: DaylockTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: StatefulBuilder(
          builder: (context, update) => SettingsScreen(
            preferences: const AppearancePreferences(),
            onChanged: (_) {},
            freedomSettings: settings,
            onFreedomChanged: (value) => update(() => settings = value),
            onRoutinesRequested: () {},
          ),
        ),
      ),
    );
    await _tap(tester, _key('freedom-enabled'));
    expect(settings.enabled, isTrue);
    await _tap(tester, _key('manage-routines'));
    expect(tester.takeException(), isNull);
  });

  for (final colour in ColourTheme.values) {
    for (final brightness in Brightness.values) {
      testWidgets(
        '$colour $brightness Freedom and routine suggestions fit narrow large-text screens',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(320, 740));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final state = _state(tomorrowCommitted: false, routines: true);
          final eligibility = const FreedomService().evaluate(
            now: _date,
            settings: state.freedomSettings,
            todayPlan: state.todayPlan,
            tomorrowPlan: state.tomorrowPlan,
          );
          await tester.pumpWidget(
            MaterialApp(
              theme: DaylockTheme.forPalette(colour, brightness),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(2.2),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: DaylockFreedomStatus(eligibility: eligibility),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Freedom not yet earned'), findsOneWidget);
          await tester.pumpWidget(
            MaterialApp(
              theme: DaylockTheme.forPalette(colour, brightness),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(2.2),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: Scaffold(
                body: PlanScreen(
                  plan: state.tomorrowPlan,
                  routineSuggestions: const RoutineService().suggestions(
                    state.routines,
                    state.tomorrowPlan.date,
                  ),
                  onRoutineAction: (_, _) {},
                  onTaskCreated: (_) {},
                  onCommitTomorrow: () {},
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await _tap(tester, find.text('ROUTINE SUGGESTIONS'));
          await _tap(tester, _key('routine-accept-training'));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'Routines management and editor support large text and keyboard insets',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: DaylockTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              viewInsets: const EdgeInsets.only(bottom: 220),
            ),
            child: child!,
          ),
          home: RoutinesScreen(
            book: _book(),
            onSaved: (_) {},
            onDeleted: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Edit'));
      expect(find.byType(RoutineEditor), findsOneWidget);
      await _tap(tester, _key('add-routine-step'));
      await tester.enterText(
        _key('commitment-name'),
        'A long readable suggestion with a wrapped title',
      );
      await _tap(tester, _key('save-commitment'));
      await _tap(tester, _key('save-routine'));
      expect(find.byType(RoutineEditor), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

class _FailingStorage extends LocalStorage {
  bool fail = true;
  @override
  Future<void> save(DaylockState state) {
    if (fail) return Future.error(StateError('Test save failure'));
    return super.save(state);
  }
}

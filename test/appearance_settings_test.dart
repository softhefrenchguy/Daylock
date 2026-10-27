import 'package:daylock/design/appearance_preferences.dart';
import 'package:daylock/design/daylock_palette.dart';
import 'package:daylock/design/daylock_theme.dart';
import 'package:daylock/main.dart';
import 'package:daylock/models/calendar_account.dart';
import 'package:daylock/models/calendar_cache.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/event.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/screens/settings_screen.dart';
import 'package:daylock/screens/today_screen.dart';
import 'package:daylock/services/appearance_storage.dart';
import 'package:daylock/services/calendar_credentials.dart';
import 'package:daylock/services/calendar_service.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'calendar_test_fixtures.dart';

final _now = DateTime(2026, 10, 8, 9);
Finder _choice(String name) => find.byKey(ValueKey(name));
ThemeData _theme(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(SettingsScreen)));
Future<void> _tap(
  WidgetTester tester,
  Finder finder, {
  bool running = false,
}) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  if (running) {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  } else {
    await tester.pumpAndSettle();
  }
}

Future<DaylockState> _saved(WidgetTester tester) async =>
    (await tester.runAsync<DaylockState?>(() => LocalStorage().load()))!;
Future<AppearancePreferences> _preferences(WidgetTester tester) async =>
    (await tester.runAsync<AppearancePreferences>(
      () => AppearanceStorage().load(),
    ))!;

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  testWidgets(
    'Fresh app defaults Dark/Violet even when the device is Light; Settings keeps the three tabs',
    (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpWidget(MainApp(now: () => _now));
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(TodayScreen))).brightness,
        Brightness.dark,
      );
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).destinations,
        hasLength(3),
      );
      await _tap(tester, find.byTooltip('Settings'));
      final settings = tester.widget<SettingsScreen>(
        find.byType(SettingsScreen),
      );
      expect(settings.preferences, const AppearancePreferences());
      for (final colour in ColourTheme.values) {
        expect(_choice('colour-${colour.name}'), findsOneWidget);
      }
      expect(find.byType(AppearancePreview), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
    },
  );

  testWidgets(
    'All palettes update the open preview and root theme, then persist after recreation without modifying saved data',
    (tester) async {
      final accounts = [
        for (final type in CalendarProviderType.values) testAccount(type),
      ];
      final state = DaylockState(
        todayPlan: DailyPlan(
          date: _now,
          isCommitted: true,
          tasks: [Task(name: 'Walk', type: TaskType.goal)],
        ),
        tomorrowPlan: DailyPlan(
          date: DateTime(2026, 10, 9),
          isCommitted: true,
          tasks: [
            Task(name: 'Read', type: TaskType.focus, minimumFocusMinutes: 60),
          ],
        ),
        events: [
          Event(
            id: 'local',
            title: 'Driving lesson',
            date: DateTime(2026, 10, 9),
          ),
        ],
        calendarCache: CalendarCache(
          accounts: accounts,
          calendars: [for (final account in accounts) testCalendar(account)],
          events: [for (final account in accounts) testExternal(account)],
        ),
      );
      final credentials = MemoryCredentials();
      for (final account in accounts) {
        await credentials.write(
          account.id,
          CalendarCredentials(accessToken: 'existing-${account.provider.name}'),
        );
      }
      final existingTokens = Map.of(credentials.values);
      final service = CalendarService(credentials: credentials);
      await tester.runAsync(() => LocalStorage().save(state));
      final rawBefore = await tester.runAsync<String?>(
        () => SharedPreferencesAsync().getString(LocalStorage.stateKey),
      );
      await tester.pumpWidget(
        MainApp(now: () => _now, calendarService: service),
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.byTooltip('Settings'));
      await _tap(tester, _choice('appearance-light'));
      for (final colour in ColourTheme.values) {
        await _tap(tester, _choice('colour-${colour.name}'));
        final expected = DaylockTheme.forPalette(colour, Brightness.light);
        expect(_theme(tester).colorScheme, expected.colorScheme);
        expect(
          _theme(tester).extension<DaylockColors>()!.statusSurface,
          expected.extension<DaylockColors>()!.statusSurface,
        );
        final preview = tester.widget<Container>(
          find.byKey(const ValueKey('appearance-preview')),
        );
        expect(
          (preview.decoration as BoxDecoration).color,
          expected.colorScheme.surface,
        );
        expect((await _preferences(tester)).colour, colour);
      }
      expect((await _saved(tester)).toJson(), state.toJson());
      expect(
        await tester.runAsync<String?>(
          () => SharedPreferencesAsync().getString(LocalStorage.stateKey),
        ),
        rawBefore,
      );
      expect(credentials.values, existingTokens);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MainApp(now: () => _now, calendarService: service),
      );
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(TodayScreen))).colorScheme,
        DaylockTheme.forPalette(ColourTheme.mono, Brightness.light).colorScheme,
      );
      await _tap(tester, find.byTooltip('Settings'));
      expect(
        tester.widget<SettingsScreen>(find.byType(SettingsScreen)).preferences,
        const AppearancePreferences(
          mode: AppearanceMode.light,
          colour: ColourTheme.mono,
        ),
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      await _tap(
        tester,
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Plan'),
        ),
      );
      expect(find.text("Tomorrow's plan is committed."), findsOneWidget);
      expect(find.textContaining('Driving lesson'), findsOneWidget);
      expect(find.textContaining('Remote meeting'), findsNWidgets(3));
    },
  );

  testWidgets(
    'System tracks device changes; explicit Dark/Light ignore them; System survives restart',
    (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpWidget(MainApp(now: () => _now));
      await tester.pumpAndSettle();
      await _tap(tester, find.byTooltip('Settings'));
      await _tap(tester, _choice('appearance-system'));
      expect(_theme(tester).brightness, Brightness.light);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      expect(_theme(tester).brightness, Brightness.dark);
      await _tap(tester, _choice('appearance-light'));
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      expect(_theme(tester).brightness, Brightness.light);
      await _tap(tester, _choice('appearance-dark'));
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(_theme(tester).brightness, Brightness.dark);
      await _tap(tester, _choice('appearance-system'));
      await _tap(tester, _choice('colour-ocean'));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(MainApp(now: () => _now));
      await tester.pumpAndSettle();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.system,
      );
      expect(
        Theme.of(tester.element(find.byType(TodayScreen))).colorScheme,
        DaylockTheme.forPalette(
          ColourTheme.ocean,
          Brightness.light,
        ).colorScheme,
      );
    },
  );

  testWidgets(
    'Appearance changes preserve a running Focus session and Today still completes Goals',
    (tester) async {
      var now = _now;
      await tester.runAsync(
        () => LocalStorage().save(
          DaylockState(
            todayPlan: DailyPlan(
              date: now,
              tasks: [
                Task(
                  name: 'Read',
                  type: TaskType.focus,
                  minimumFocusMinutes: 60,
                ),
                Task(name: 'Walk', type: TaskType.goal),
              ],
            ),
            tomorrowPlan: DailyPlan(
              date: DateTime(2026, 10, 9),
              tasks: [],
              isCommitted: true,
            ),
          ),
        ),
      );
      await tester.pumpWidget(MainApp(now: () => now));
      await tester.pumpAndSettle();
      await _tap(
        tester,
        find.widgetWithText(TextButton, 'Start stopwatch').first,
        running: true,
      );
      final startedAt = (await _saved(tester))
          .todayPlan
          .tasks
          .first
          .focusStartedAt;
      await _tap(tester, find.byTooltip('Settings'), running: true);
      await _tap(tester, _choice('colour-forest'), running: true);
      await _tap(tester, _choice('appearance-light'), running: true);
      now = now.add(const Duration(minutes: 23));
      await tester.pump(const Duration(seconds: 1));
      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.text('23:00'), findsOneWidget);
      expect(find.text('Pause stopwatch'), findsOneWidget);
      expect(
        (await _saved(tester)).todayPlan.tasks.first.focusStartedAt,
        startedAt,
      );
      await _tap(tester, find.widgetWithText(TextButton, 'Pause stopwatch'));
      await _tap(tester, find.text('Walk'));
      final saved = await _saved(tester);
      expect(
        saved.todayPlan.tasks.first.accumulatedFocusMilliseconds,
        23 * 60000,
      );
      expect(saved.todayPlan.tasks.last.isCompleted, isTrue);
      expect(saved.tomorrowPlan.isCommitted, isTrue);
      expect(find.text('1 / 2 complete'), findsOneWidget);
    },
  );

  testWidgets(
    'Appearance read/write failures do not block plans; retry saves the latest choice',
    (tester) async {
      final storage = _UnavailableAppearanceStorage();
      await tester.pumpWidget(
        MainApp(now: () => _now, appearanceStorage: storage),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TodayScreen), findsOneWidget);
      await _tap(tester, find.byTooltip('Settings'));
      await _tap(tester, _choice('colour-rose'));
      expect(
        _theme(tester).colorScheme.primary,
        DaylockTheme.forPalette(
          ColourTheme.rose,
          Brightness.dark,
        ).colorScheme.primary,
      );
      expect(find.text('Could not save appearance settings.'), findsOneWidget);
      await _tap(tester, _choice('colour-ocean'));
      storage.unavailable = false;
      await _tap(tester, find.text('Retry').first);
      expect(storage.saved!.colour, ColourTheme.ocean);
      expect(tester.takeException(), isNull);
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'Settings at 320px/200% text supports every choice and reduced motion in $brightness',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var preferences = AppearancePreferences(
          mode: brightness == Brightness.dark
              ? AppearanceMode.dark
              : AppearanceMode.light,
        );
        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, update) => MaterialApp(
              theme: DaylockTheme.forPalette(preferences.colour, brightness),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(2),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: SettingsScreen(
                preferences: preferences,
                onChanged: (value) => update(() => preferences = value),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final mode in AppearanceMode.values) {
          await _tap(tester, _choice('appearance-${mode.name}'));
          expect(preferences.mode, mode);
        }
        for (final colour in ColourTheme.values) {
          await _tap(tester, _choice('colour-${colour.name}'));
          expect(preferences.colour, colour);
        }
        await tester.ensureVisible(find.byType(AppearancePreview));
        final preview = find.descendant(
          of: find.byType(AppearancePreview),
          matching: find.byType(TweenAnimationBuilder<double>),
        );
        expect(
          tester.widget<TweenAnimationBuilder<double>>(preview).duration,
          Duration.zero,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Main theme switching respects the system reduced-motion setting',
    (tester) async {
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(MainApp(now: () => _now));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<MaterialApp>(find.byType(MaterialApp))
            .themeAnimationDuration,
        const Duration(milliseconds: 220),
      );
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      await tester.pump();
      await _tap(tester, find.byTooltip('Settings'));
      await _tap(tester, _choice('colour-ember'));
      expect(
        tester
            .widget<MaterialApp>(find.byType(MaterialApp))
            .themeAnimationDuration,
        Duration.zero,
      );
      expect(
        _theme(tester).colorScheme.primary,
        DaylockTheme.forPalette(
          ColourTheme.ember,
          Brightness.dark,
        ).colorScheme.primary,
      );
    },
  );
}

class _UnavailableAppearanceStorage extends AppearanceStorage {
  bool unavailable = true;
  AppearancePreferences? saved;
  @override
  Future<AppearancePreferences> load() async =>
      throw StateError('Storage unavailable');
  @override
  Future<void> save(AppearancePreferences preferences) async {
    if (unavailable) throw StateError('Storage unavailable');
    saved = preferences;
  }
}

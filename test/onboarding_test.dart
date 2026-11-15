import 'package:daylock/main.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/models/onboarding_steps.dart';
import 'package:daylock/screens/onboarding_screen.dart';
import 'package:daylock/screens/journey_screen.dart';
import 'package:daylock/services/instagram_detection_bridge.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:daylock/services/notifications/notification_service.dart';
import 'package:daylock/screens/app_tour.dart';
import 'package:daylock/screens/plan_screen.dart';
import 'package:daylock/screens/today_screen.dart';
import 'package:daylock/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class TutorialBridge extends InstagramDetectionBridge {
  TutorialBridge() : super(android: false);
  int appSettingsOpened = 0;
  @override
  Future<void> openAppSettings() async {
    appSettingsOpened++;
  }

  @override
  Future<void> refresh() async {}
  @override
  Future<List<InstalledRestrictedApp>> loadInstalledApps() async => [];
  @override
  Future<void> testRestrictedApp(String packageName) async {}
}

InstagramDetectionStatus ready({
  DateTime? detected,
  String? restriction,
  String? lock,
  bool enabled = true,
  bool xiaomi = false,
}) => InstagramDetectionStatus(
  supported: true,
  xiaomiDevice: xiaomi,
  enabled: enabled,
  connected: enabled,
  blockingEnabled: true,
  selectedPackages: const {'com.instagram.android'},
  freedomState: 'notEarned',
  lastDetectedAt: detected,
  lastDetectedPackage: 'com.instagram.android',
  lastRestriction: restriction,
  lastLockLaunch: lock,
);

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  test('Setup progress survives a new storage instance and never erases planner data', () async {
    final storage = LocalStorage();
    await storage.save(
      DaylockState(
        todayPlan: DailyPlan(
          date: DateTime.now(),
          tasks: [Task(name: 'Keep this')],
          isCommitted: true,
        ),
        tomorrowPlan: DailyPlan(
          date: DateTime.now().add(const Duration(days: 1)),
          tasks: [],
        ),
      ),
    );
    await storage.saveOnboardingStep(3);
    expect(await LocalStorage().loadOnboardingStep(), 3);
    await storage.saveOnboardingStep(OnboardingSteps.complete);
    expect(await LocalStorage().loadOnboardingStep(), OnboardingSteps.complete);
    expect((await storage.load())!.todayPlan.tasks.single.name, 'Keep this');
  });

  test('Old setup progress starts the added feature tour and preserves Xiaomi confirmation', () async {
    final preferences = SharedPreferencesAsync();
    final storage = LocalStorage();
    for (final oldStep in [4, 5, 6]) {
      await preferences.setInt('daylock.onboarding.v2', oldStep);
      expect(await storage.loadOnboardingStep(), OnboardingSteps.overview);
    }
    await preferences.setInt('daylock.onboarding.v2', 2);
    expect(await storage.loadOnboardingStep(), 2);
    await storage.saveOnboardingPowerReviewed(true);
    await storage.saveOnboardingStep(OnboardingSteps.complete);
    expect(await LocalStorage().loadOnboardingStep(), OnboardingSteps.complete);
    expect(await LocalStorage().loadOnboardingPowerReviewed(), isTrue);
  });

  testWidgets(
    'Startup forces revised tutorial for fresh and existing users, resumes progress and honors completion',
    (tester) async {
      final storage = LocalStorage();
      final notifications = NotificationService();
      await tester.pumpWidget(
        MainApp(
          storage: storage,
          notificationService: notifications,
          onboardingEnabled: true,
          now: () => DateTime(2026, 11, 5),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Take Back Control'), findsOneWidget);
      notifications.onTap?.call(const NotificationTarget('plan'));
      await tester.pumpAndSettle();
      expect(find.text('Take Back Control'), findsOneWidget);
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      expect(await storage.loadOnboardingStep(), 1);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        MainApp(
          storage: storage,
          onboardingEnabled: true,
          now: () => DateTime(2026, 11, 5),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Set Up App Blocking'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await storage.reset();
      await SharedPreferencesAsync().setInt('daylock.onboarding.v1', 6);
      await storage.save(
        DaylockState(
          todayPlan: DailyPlan(
            date: DateTime.now(),
            tasks: [],
            isCommitted: true,
          ),
          tomorrowPlan: DailyPlan(
            date: DateTime.now().add(const Duration(days: 1)),
            tasks: [],
          ),
        ),
      );
      await tester.pumpWidget(
        MainApp(
          storage: storage,
          onboardingEnabled: true,
          now: () => DateTime(2026, 11, 5),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Take Back Control'), findsOneWidget);
      expect(await storage.loadOnboardingStep(), 0);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await storage.saveOnboardingStep(OnboardingSteps.complete);
      await tester.pumpWidget(
        MainApp(
          storage: storage,
          onboardingEnabled: true,
          now: () => DateTime(2026, 11, 5),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  Future<void> mount(
    WidgetTester tester,
    TutorialBridge bridge,
    int step,
    List<int> saved,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          bridge: bridge,
          notifications: NotificationService(),
          initialStep: step,
          saveStep: (step) async {
            saved.add(step);
          },
          hasGoal: () => true,
          createGoal: (_) async => true,
          enableFreedom: () async {},
          onExit: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Ready offers the tour, which walks the real Today, Plan and Journey and preserves data',
    (tester) async {
      final storage = LocalStorage();
      final date = DateTime(2026, 11, 5);
      await storage.save(
        DaylockState(
          todayPlan: DailyPlan(
            date: date,
            tasks: [Task(name: 'Keep today')],
            isCommitted: true,
          ),
          tomorrowPlan: DailyPlan(
            date: date.add(const Duration(days: 1)),
            tasks: [Task(name: 'Keep tomorrow')],
          ),
        ),
      );
      final original = (await storage.load())!.toJson();
      await storage.saveOnboardingStep(OnboardingSteps.ready);
      await tester.pumpWidget(
        MainApp(storage: storage, now: () => date, onboardingEnabled: true),
      );
      await tester.pumpAndSettle();
      expect(find.text('Take a quick tour'), findsOneWidget);
      await tester.tap(find.text('Take the tour'));
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(await storage.loadOnboardingStep(), OnboardingSteps.complete);

      final bubble = find.byKey(const ValueKey('app-tour'));
      Future<void> next() async {
        await tester.tap(find.byKey(const ValueKey('tour-next')));
        await tester.pumpAndSettle();
      }

      expect(find.text('This is your day'), findsOneWidget);
      expect(find.text('1 of ${daylockTour.length}'), findsOneWidget);
      expect(find.byType(TodayScreen), findsOneWidget);
      // Back is hidden on the first stop; the app behind can't be tapped.
      expect(find.byKey(const ValueKey('tour-back')), findsNothing);
      await tester.tap(find.text('Keep today'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('This is your day'), findsOneWidget);
      await next();
      expect(find.text('Today’s commitments'), findsOneWidget);
      await next();
      await next();
      expect(find.text('Plan tomorrow'), findsOneWidget);
      expect(find.byType(PlanScreen), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('tour-back')));
      await tester.pumpAndSettle();
      expect(find.text('Freedom'), findsWidgets);
      expect(find.byType(TodayScreen), findsOneWidget);
      for (var i = 2; i < 6; i++) {
        await next();
      }
      expect(find.text('Your Journey'), findsOneWidget);
      expect(find.byType(JourneyScreen), findsOneWidget);
      await next();
      await next();
      expect(find.text('Settings'), findsWidgets);
      expect(find.text('Done'), findsOneWidget);
      await next();
      expect(bubble, findsNothing);
      expect(find.byType(TodayScreen), findsOneWidget);
      expect((await tester.runAsync(() => storage.load()))!.toJson(), original);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Skip the tour finishes setup; Settings can start it later', (
    tester,
  ) async {
    final storage = LocalStorage();
    await storage.save(
      DaylockState(
        todayPlan: DailyPlan(
          date: DateTime(2026, 11, 5),
          tasks: [],
          isCommitted: true,
        ),
        tomorrowPlan: DailyPlan(
          date: DateTime(2026, 11, 6),
          tasks: [Task(name: 'First step')],
        ),
      ),
    );
    await storage.saveOnboardingStep(OnboardingSteps.ready);
    await tester.pumpWidget(
      MainApp(
        storage: storage,
        now: () => DateTime(2026, 11, 5),
        onboardingEnabled: true,
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('setup-skip-tour')));
    await tester.tap(find.byKey(const ValueKey('setup-skip-tour')));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byKey(const ValueKey('app-tour')), findsNothing);
    expect(await storage.loadOnboardingStep(), OnboardingSteps.complete);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    final tour = find.byKey(const ValueKey('settings-tour'));
    await tester.scrollUntilVisible(tour, 200);
    await tester.tap(tour);
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsNothing);
    expect(find.text('This is your day'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tour-skip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('app-tour')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Tour bubble stays usable at 320px with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => Stack(
              children: [
                const Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    key: ValueKey('today-sky'),
                    width: 320,
                    height: 200,
                  ),
                ),
                Positioned.fill(
                  child: AppTourOverlay(
                    index: 0,
                    searchRoot: () => context,
                    onShowPage: (_) {},
                    onNext: () {},
                    onBack: () {},
                    onClose: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Next').hitTestable(), findsOneWidget);
    expect(find.text('Skip tour').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final blocking in [true, false]) {
    testWidgets(
      'Progress saved on a retired tour page resumes at the next real page (blocking: $blocking)',
      (tester) async {
        final bridge = TutorialBridge()
          ..status.value = ready(enabled: blocking);
        await mount(tester, bridge, OnboardingSteps.routines, []);
        expect(
          find.text(blocking ? "You're Almost Ready!" : "You're All Set!"),
          findsOneWidget,
        );
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'Tutorial goal uses the real tomorrow editor and survives leaving setup',
    (tester) async {
      final storage = LocalStorage();
      final date = DateTime(2026, 11, 5);
      await storage.save(
        DaylockState(
          todayPlan: DailyPlan(date: date, tasks: [], isCommitted: true),
          tomorrowPlan: DailyPlan(
            date: date.add(const Duration(days: 1)),
            tasks: [],
          ),
        ),
      );
      await storage.saveOnboardingStep(3);
      await tester.pumpWidget(
        MainApp(storage: storage, now: () => date, onboardingEnabled: true),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Create a commitment'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create a commitment'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('commitment-name')),
        'Read ten pages',
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Add commitment'));
      await tester.tap(find.text('Add commitment'));
      await tester.pumpAndSettle();
      final state = (await tester.runAsync(() => storage.load()))!;
      expect(state.todayPlan.tasks, isEmpty);
      expect(state.tomorrowPlan.tasks.single.name, 'Read ten pages');
      await tester.tap(find.byTooltip('Save & leave'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Run Setup Tutorial'));
      await tester.tap(find.text('Run Setup Tutorial'));
      await tester.pumpAndSettle();
      expect(find.text('Take Back Control'), findsOneWidget);
      expect(
        (await tester.runAsync(() => storage.load()))!.tomorrowPlan.tasks,
        hasLength(1),
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Committed tomorrow plan cannot be changed by tutorial', (
    tester,
  ) async {
    final storage = LocalStorage();
    final date = DateTime(2026, 11, 5);
    await storage.save(
      DaylockState(
        todayPlan: DailyPlan(date: date, tasks: [], isCommitted: true),
        tomorrowPlan: DailyPlan(
          date: date.add(const Duration(days: 1)),
          tasks: [Task(name: 'Existing goal')],
          isCommitted: true,
        ),
      ),
    );
    await storage.saveOnboardingStep(3);
    await tester.pumpWidget(
      MainApp(storage: storage, now: () => date, onboardingEnabled: true),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Create a commitment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create a commitment'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('commitment-name')), findsNothing);
    expect(
      find.textContaining('Tomorrow’s plan is already committed.'),
      findsOneWidget,
    );
    expect(
      (await tester.runAsync(() => storage.load()))!
          .tomorrowPlan
          .tasks
          .single
          .name,
      'Existing goal',
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Xiaomi power guidance requires a durable user confirmation and opens app-specific Settings',
    (tester) async {
      final storage = LocalStorage();
      final bridge = TutorialBridge()..status.value = ready(xiaomi: true);
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            bridge: bridge,
            notifications: NotificationService(),
            initialStep: 1,
            saveStep: (_) async {},
            hasGoal: () => true,
            createGoal: (_) async => true,
            enableFreedom: () async {},
            onExit: () {},
            savePowerReviewed: storage.saveOnboardingPowerReviewed,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Xiaomi / Poco: keep blocking active'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(find.byKey(const ValueKey('setup-app-power')));
      await tester.tap(find.byKey(const ValueKey('setup-app-power')));
      await tester.pumpAndSettle();
      expect(bridge.appSettingsOpened, 1);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('setup-power-reviewed')),
      );
      await tester.tap(find.byKey(const ValueKey('setup-power-reviewed')));
      await tester.pumpAndSettle();
      expect(await storage.loadOnboardingPowerReviewed(), isTrue);
      expect(await LocalStorage().loadOnboardingPowerReviewed(), isTrue);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
            .onPressed,
        isNotNull,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Accessibility is optional: setup continues without it and skips blocking steps',
    (tester) async {
      final bridge = TutorialBridge()..status.value = ready(enabled: false);
      final saved = <int>[];
      await mount(tester, bridge, 1, saved);
      expect(
        find.byKey(const ValueKey('setup-blocking-optional')),
        findsOneWidget,
      );
      expect(find.text('Accessibility access · optional'), findsOneWidget);
      await tester.tap(find.text('Continue without blocking'));
      await tester.pumpAndSettle();
      // Choosing apps is skipped; Back returns to the permission step.
      expect(saved, [3]);
      expect(find.text('Set Your First Commitment'), findsOneWidget);
      await tester.tap(find.byTooltip('Previous step'));
      await tester.pumpAndSettle();
      expect(saved, [3, 1]);
      expect(find.text('Set Up App Blocking'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Without blocking, setup skips the test and can finish', (
    tester,
  ) async {
    final bridge = TutorialBridge()..status.value = ready(enabled: false);
    final saved = <int>[];
    await mount(tester, bridge, 3, saved);
    expect(find.text('Step 3 of 4'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(saved, [OnboardingSteps.ready]);
    expect(find.text('App blocking is off'), findsOneWidget);
    await tester.tap(find.text('Go to Daylock'));
    await tester.pumpAndSettle();
    expect(saved, [OnboardingSteps.ready, OnboardingSteps.complete]);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Connecting Accessibility updates the step live', (tester) async {
    final bridge = TutorialBridge()..status.value = ready(enabled: false);
    final saved = <int>[];
    await mount(tester, bridge, 1, saved);
    expect(find.text('Continue without blocking'), findsOneWidget);
    bridge.status.value = ready();
    await tester.pumpAndSettle();
    expect(find.text('Continue without blocking'), findsNothing);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(saved, [2]);
    expect(find.text('Choose Your Distractions'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Historical lock success does not finish setup; fresh confirmed evidence does',
    (tester) async {
      final bridge = TutorialBridge()
        ..status.value = ready(
          detected: DateTime(2020),
          restriction: 'lock_shown',
          lock: 'shown',
        );
      final saved = <int>[];
      await mount(tester, bridge, OnboardingSteps.test, saved);
      // Unverified: the test can be skipped but never reports success.
      expect(find.text('Finish Setup'), findsNothing);
      expect(find.text('Skip test for now'), findsOneWidget);
      await tester.ensureVisible(find.text('Test a selected app'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test a selected app'));
      await tester.pump();
      bridge.status.value = ready(
        detected: DateTime.now(),
        restriction: 'lock_launch_requested',
        lock: 'requested_unconfirmed',
      );
      await tester.pump();
      expect(find.text('Finish Setup'), findsNothing);
      bridge.status.value = ready(
        detected: DateTime.now(),
        restriction: 'lock_shown',
        lock: 'shown',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finish Setup'));
      await tester.pumpAndSettle();
      expect(saved, [OnboardingSteps.ready]);
      expect(find.text("You're All Set!"), findsOneWidget);
      await tester.tap(find.text('Go to Daylock'));
      await tester.pumpAndSettle();
      expect(saved, [OnboardingSteps.ready, OnboardingSteps.complete]);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Small screen and large text keep controls scrollable and exit available',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final bridge = TutorialBridge();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: OnboardingScreen(
            bridge: bridge,
            notifications: NotificationService(),
            saveStep: (_) async {},
            createGoal: (_) async => true,
            hasGoal: () => false,
            enableFreedom: () async {},
            onExit: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Save & leave'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Tour transitions ignore double taps and Skip fades out before closing',
    (tester) async {
      final storage = LocalStorage();
      await storage.save(
        DaylockState(
          todayPlan: DailyPlan(
            date: DateTime(2026, 11, 5),
            tasks: [Task(name: 'Keep today')],
            isCommitted: true,
          ),
          tomorrowPlan: DailyPlan(
            date: DateTime(2026, 11, 6),
            tasks: [Task(name: 'Keep tomorrow')],
          ),
        ),
      );
      await storage.saveOnboardingStep(OnboardingSteps.ready);
      await tester.pumpWidget(
        MainApp(
          storage: storage,
          now: () => DateTime(2026, 11, 5),
          onboardingEnabled: true,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take the tour'));
      await tester.pumpAndSettle();
      expect(find.text('1 of ${daylockTour.length}'), findsOneWidget);
      final next = find.byKey(const ValueKey('tour-next'));
      await tester.tap(next);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tap(next, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('2 of ${daylockTour.length}'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('tour-skip')));
      await tester.pump(const Duration(milliseconds: 60));
      // Still on screen while it fades out.
      expect(find.byKey(const ValueKey('app-tour')), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('app-tour')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

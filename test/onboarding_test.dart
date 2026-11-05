import 'package:daylock/main.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/screens/onboarding_screen.dart';
import 'package:daylock/services/instagram_detection_bridge.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:daylock/services/notifications/notification_service.dart';
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
    await storage.saveOnboardingStep(6);
    expect(await LocalStorage().loadOnboardingStep(), 6);
    expect((await storage.load())!.todayPlan.tasks.single.name, 'Keep this');
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
      await storage.saveOnboardingStep(6);
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

  testWidgets('Permission step waits for actual connection and updates live', (
    tester,
  ) async {
    final bridge = TutorialBridge()..status.value = ready(enabled: false);
    final saved = <int>[];
    await mount(tester, bridge, 1, saved);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
          .onPressed,
      isNull,
    );
    bridge.status.value = ready();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
          .onPressed,
      isNotNull,
    );
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
      await mount(tester, bridge, 4, saved);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Finish Setup'),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Test a selected app'));
      await tester.pump();
      bridge.status.value = ready(
        detected: DateTime.now(),
        restriction: 'lock_launch_requested',
        lock: 'requested_unconfirmed',
      );
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Finish Setup'),
            )
            .onPressed,
        isNull,
      );
      bridge.status.value = ready(
        detected: DateTime.now(),
        restriction: 'lock_shown',
        lock: 'shown',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finish Setup'));
      await tester.pumpAndSettle();
      expect(saved, [5]);
      expect(find.text("You're All Set!"), findsOneWidget);
      await tester.tap(find.text('Go to Daylock'));
      await tester.pumpAndSettle();
      expect(saved, [5, 6]);
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
}

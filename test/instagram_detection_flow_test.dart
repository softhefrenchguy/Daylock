import 'dart:async';

import 'package:daylock/design/daylock_palette.dart';
import 'package:daylock/design/daylock_theme.dart';
import 'package:daylock/main.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/freedom_settings.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/screens/instagram_detection_section.dart';
import 'package:daylock/services/instagram_detection_bridge.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final date = DateTime(2026, 10, 13, 18);
DaylockState state() => DaylockState(
  todayPlan: DailyPlan(
    date: date,
    tasks: [Task(name: 'Walk', type: TaskType.goal, isCompleted: true)],
    isCommitted: true,
  ),
  tomorrowPlan: DailyPlan(
    date: DateTime(2026, 10, 14),
    tasks: [Task(name: 'Read', type: TaskType.goal)],
    isCommitted: true,
  ),
  freedomSettings: const FreedomSettings(enabled: true),
);
Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void resume(WidgetTester tester) {
  for (final lifecycle in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(lifecycle);
  }
}

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  testWidgets(
    'Saved Freedom state publishes without changing any planner fields',
    (tester) async {
      final initial = state();
      await tester.runAsync(() => LocalStorage().save(initial));
      final bridge = RecordingBridge();
      await tester.pumpWidget(
        MainApp(now: () => date, detectionBridge: bridge),
      );
      await tester.pumpAndSettle();
      expect(bridge.latest!['completedCount'], 1);
      expect(bridge.latest!['eligibleCount'], 1);
      expect(bridge.latest!['tomorrowCommitted'], isTrue);
      expect(bridge.latest!['tomorrowPlan'], {
        'date': '2026-10-14',
        'eligibleCount': 1,
        'completedCount': 0,
      });
      expect(bridge.latest!['enabled'], isTrue);
      expect(
        (await tester.runAsync(() => LocalStorage().load()))!.toJson(),
        initial.toJson(),
      );
      await tap(tester, find.byTooltip('Settings'));
      await tap(tester, find.byKey(const ValueKey('settings-freedom')));
      await tap(tester, find.byKey(const ValueKey('settings-diagnostics')));
      expect(find.byType(InstagramDetectionSection), findsOneWidget);
      expect(find.text('Accessibility service: disabled'), findsOneWidget);
    },
  );
  testWidgets(
    'Changes invalidate immediately and are not published until saved',
    (tester) async {
      await tester.runAsync(() => LocalStorage().save(state()));
      final storage = HeldStorage();
      final bridge = RecordingBridge();
      await tester.pumpWidget(
        MainApp(storage: storage, now: () => date, detectionBridge: bridge),
      );
      await tester.pumpAndSettle();
      expect(bridge.latest, isNotNull);
      storage.waiting = Completer<void>();
      await tap(tester, find.text('Walk'));
      expect(bridge.latest, isNull);
      await tester.pump(const Duration(seconds: 2));
      expect(bridge.latest, isNull);
      storage.waiting!.complete();
      await tester.pumpAndSettle();
      expect(bridge.latest!['completedCount'], 0);
      expect(bridge.latest!['eligibleCount'], 1);
    },
  );
  testWidgets(
    'Failed planner save leaves native eligibility unknown until Retry succeeds',
    (tester) async {
      await tester.runAsync(() => LocalStorage().save(state()));
      final storage = HeldStorage()..fail = true;
      final bridge = RecordingBridge();
      await tester.pumpWidget(
        MainApp(storage: storage, now: () => date, detectionBridge: bridge),
      );
      await tester.pumpAndSettle();
      await tap(tester, find.text('Walk'));
      expect(find.text('Could not save your changes.'), findsOneWidget);
      expect(bridge.latest, isNull);
      await tester.pump(const Duration(seconds: 2));
      expect(bridge.latest, isNull);
      storage.fail = false;
      await tap(tester, find.text('Retry'));
      expect(bridge.latest!['completedCount'], 0);
    },
  );
  testWidgets(
    'Resume publishes new dated plans and reads latest service status',
    (tester) async {
      var now = date;
      await tester.runAsync(() => LocalStorage().save(state()));
      final bridge = RecordingBridge();
      await tester.pumpWidget(MainApp(now: () => now, detectionBridge: bridge));
      await tester.pumpAndSettle();
      final refreshed = bridge.refreshCount;
      now = DateTime(2026, 10, 14, 18);
      resume(tester);
      await tester.pumpAndSettle();
      expect(bridge.refreshCount, greaterThan(refreshed));
      expect(bridge.latest!['date'], '2026-10-14');
      expect(bridge.latest!['completedCount'], 0);
      expect(bridge.latest!['tomorrowCommitted'], isFalse);
    },
  );
  testWidgets(
    'Invalid planner data invalidates cache and is never overwritten',
    (tester) async {
      final bridge = RecordingBridge();
      await tester.pumpWidget(
        MainApp(
          storage: BrokenStorage(),
          now: () => date,
          detectionBridge: bridge,
        ),
      );
      await tester.pumpAndSettle();
      expect(bridge.latest, isNull);
      expect(bridge.invalidations, greaterThan(0));
      expect(bridge.publications, 0);
    },
  );
  testWidgets(
    'Disclosure must be agreed to before opening Android Settings; opening does not enable service',
    (tester) async {
      final bridge = RecordingBridge();
      await bridge.start();
      await tester.pumpWidget(
        MaterialApp(
          theme: DaylockTheme.dark,
          home: Scaffold(
            body: SingleChildScrollView(
              child: InstagramDetectionSection(bridge: bridge),
            ),
          ),
        ),
      );
      await tap(
        tester,
        find.byKey(const ValueKey('open-accessibility-settings')),
      );
      expect(find.text('Instagram detection permission'), findsOneWidget);
      expect(
        find.textContaining('does not read screen content'),
        findsOneWidget,
      );
      await tap(tester, find.text('Cancel'));
      expect(bridge.settingsOpened, 0);
      await tap(
        tester,
        find.byKey(const ValueKey('open-accessibility-settings')),
      );
      await tap(tester, find.byKey(const ValueKey('agree-detection')));
      expect(bridge.settingsOpened, 1);
      expect(find.text('Accessibility service: disabled'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await bridge.close();
    },
  );
  testWidgets(
    'Enabled, connected, revoked and stale statuses stay distinct from historical earned detection',
    (tester) async {
      final bridge = RecordingBridge();
      await bridge.start();
      await tester.pumpWidget(
        MaterialApp(
          theme: DaylockTheme.dark,
          home: Scaffold(
            body: SingleChildScrollView(
              child: InstagramDetectionSection(bridge: bridge),
            ),
          ),
        ),
      );
      bridge.status.value = const InstagramDetectionStatus(
        supported: true,
        enabled: true,
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('waiting for Android'), findsOneWidget);
      bridge.status.value = InstagramDetectionStatus(
        supported: true,
        enabled: true,
        connected: true,
        lastDetectedAt: date,
        freedomAtDetection: 'earned',
        freedomState: 'earned',
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Accessibility service: enabled and connected'),
        findsOneWidget,
      );
      expect(find.textContaining('Last Instagram detection:'), findsOneWidget);
      bridge.status.value = InstagramDetectionStatus(
        supported: true,
        enabled: false,
        connected: false,
        lastDetectedAt: date,
        freedomAtDetection: 'earned',
        freedomState: 'unknown',
        freedomReason: 'date_changed',
      );
      await tester.pumpAndSettle();
      expect(find.text('Accessibility service: disabled'), findsOneWidget);
      expect(find.text('Freedom at that detection: Earned'), findsOneWidget);
      expect(
        find.textContaining('Current native Freedom state: Unknown'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      await bridge.close();
    },
  );
  for (final colour in ColourTheme.values) {
    testWidgets('$colour detection and disclosure fit 320px with large text', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final bridge = RecordingBridge();
      await bridge.start();
      await tester.pumpWidget(
        MaterialApp(
          theme: DaylockTheme.forPalette(colour, Brightness.dark),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: InstagramDetectionSection(bridge: bridge),
            ),
          ),
        ),
      );
      await tap(
        tester,
        find.byKey(const ValueKey('open-accessibility-settings')),
      );
      await tap(tester, find.byKey(const ValueKey('agree-detection')));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await bridge.close();
    });
  }
}

class RecordingBridge extends InstagramDetectionBridge {
  Map<String, Object>? latest;
  int publications = 0, invalidations = 0, settingsOpened = 0, refreshCount = 0;
  RecordingBridge() : super(android: false);
  @override
  Future<void> start() async {
    status.value = const InstagramDetectionStatus(supported: true);
  }

  @override
  Future<void> publishSnapshot(
    NativeFreedomInput input, {
    bool force = false,
  }) async {
    latest = input.values;
    publications++;
  }

  @override
  Future<void> invalidateSnapshot() async {
    latest = null;
    invalidations++;
  }

  @override
  Future<void> refresh() async {
    refreshCount++;
  }

  @override
  Future<void> openAccessibilitySettings() async {
    settingsOpened++;
  }
}

class HeldStorage extends LocalStorage {
  Completer<void>? waiting;
  bool fail = false;
  @override
  Future<void> save(DaylockState state) async {
    final copy = DaylockState.fromJson(state.toJson());
    if (waiting != null) await waiting!.future;
    if (fail) throw StateError('Test write failure');
    await super.save(copy);
  }
}

class BrokenStorage extends LocalStorage {
  @override
  Future<DaylockState?> load() async =>
      throw const FormatException('Broken planner save');
  @override
  Future<void> save(DaylockState state) async =>
      throw StateError('Must not replace bad save');
}

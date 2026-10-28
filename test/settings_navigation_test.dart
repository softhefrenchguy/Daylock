import 'package:daylock/design/appearance_preferences.dart';
import 'package:daylock/design/daylock_theme.dart';
import 'package:daylock/models/freedom_settings.dart';
import 'package:daylock/models/notification_preferences.dart';
import 'package:daylock/screens/settings_screen.dart';
import 'package:daylock/services/instagram_detection_bridge.dart';
import 'package:daylock/services/notifications/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Bridge extends InstagramDetectionBridge {
  int refreshes = 0, opened = 0;
  _Bridge() : super(android: false) {
    status.value = const InstagramDetectionStatus(
      supported: true,
      enabled: true,
      connected: true,
      freedomState: 'notEarned',
      lastRestriction: 'lock_launch_requested',
    );
  }
  @override
  Future<List<InstalledRestrictedApp>> loadInstalledApps() async => [
    const InstalledRestrictedApp(
      packageName: 'com.instagram.android',
      name: 'Instagram',
    ),
  ];
  @override
  Future<void> setBlockingEnabled(bool enabled) async {
    status.value = InstagramDetectionStatus(
      supported: true,
      enabled: true,
      connected: true,
      blockingEnabled: enabled,
      freedomState: 'notEarned',
      lastRestriction: 'lock_launch_requested',
    );
  }

  @override
  Future<void> refresh() async {
    refreshes++;
  }

  @override
  Future<void> openAccessibilitySettings() async {
    opened++;
  }
}

Future<void> tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> back(WidgetTester tester) async {
  await tester.pageBack();
  await tester.pumpAndSettle();
}

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'Every Settings destination and escape route works at ${scale}x text',
      (tester) async {
        tester.view.physicalSize = Size(scale == 1 ? 390 : 320, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final bridge = _Bridge();
        final notifications = NotificationService();
        notifications.status.value = const NotificationStatus(
          permission: NotificationPermission.denied,
          scheduledDelivery: true,
          explanation: 'Permission is controlled by Android.',
        );
        var freedom = const FreedomSettings();
        var appearance = const AppearancePreferences();
        var prefs = const NotificationPreferences();
        var routinesOpened = 0, areasOpened = 0;
        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, update) => MaterialApp(
              theme: DaylockTheme.dark,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: SettingsScreen(
                preferences: appearance,
                onChanged: (v) => update(() => appearance = v),
                freedomSettings: freedom,
                onFreedomChanged: (v) => update(() => freedom = v),
                onAreasRequested: () => areasOpened++,
                onRoutinesRequested: () => routinesOpened++,
                routineCount: 3,
                areaCount: 4,
                detectionBridge: bridge,
                notificationService: notifications,
                notificationPreferences: prefs,
                onNotificationsChanged: (v) => update(() => prefs = v),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(SettingsNavigationCard), findsNWidgets(5));
        if (scale == 1) {
          expect(
            tester
                .getBottomRight(find.byKey(const ValueKey('settings-about')))
                .dy,
            lessThan(844),
          );
        }
        await tap(tester, 'settings-freedom');
        await tap(tester, 'freedom-enabled');
        expect(freedom.enabled, isTrue);
        expect(bridge.status.value.blockingEnabled, isFalse);
        await tap(tester, 'settings-restricted');
        expect(find.text('Instagram'), findsOneWidget);
        await tap(tester, 'instagram-blocking-enabled');
        expect(bridge.status.value.blockingEnabled, isFalse);
        await tap(tester, 'confirm-instagram-blocking');
        expect(bridge.status.value.blockingEnabled, isTrue);
        expect(freedom.enabled, isTrue);
        await tap(tester, 'instagram-blocking-enabled');
        expect(bridge.status.value.blockingEnabled, isFalse);
        await back(tester);
        await tap(tester, 'settings-diagnostics');
        expect(find.text('Service connected'), findsOneWidget);
        expect(find.textContaining('display not yet confirmed'), findsNothing);
        await tap(tester, 'detection-details');
        expect(
          find.textContaining('display not yet confirmed'),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('instagram-last-detection')),
          findsOneWidget,
        );
        await tap(tester, 'refresh-detection');
        expect(bridge.refreshes, 1);
        await tap(tester, 'open-accessibility-settings');
        expect(bridge.opened, 0);
        await tap(tester, 'agree-detection');
        expect(bridge.opened, 1);
        await back(tester);
        await back(tester);
        await tap(tester, 'settings-planning');
        expect(find.text('3 routines'), findsOneWidget);
        await tap(tester, 'manage-routines');
        expect(routinesOpened, 1);
        await back(tester);
        await tap(tester, 'settings-appearance');
        await tap(tester, 'manage-areas');
        expect(areasOpened, 1);
        // Back stays visible even after scrolling to the last setting.
        expect(find.byTooltip('Back').hitTestable(), findsOneWidget);
        await back(tester);
        await tap(tester, 'settings-notifications');
        final oldPlan = prefs.planTomorrow;
        await tap(tester, 'notification-plan');
        expect(prefs.planTomorrow, !oldPlan);
        expect(
          notifications.status.value.permission,
          NotificationPermission.denied,
        );
        await back(tester);
        await tap(tester, 'settings-about');
        expect(find.text('Keep your word.'), findsOneWidget);
        await back(tester);
        expect(find.byType(SettingsNavigationCard), findsNWidgets(5));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await bridge.close();
      },
    );
  }
}

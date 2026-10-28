import 'dart:async';

import 'package:daylock/design/daylock_theme.dart';
import 'package:daylock/screens/restricted_apps_section.dart';
import 'package:daylock/screens/settings_screen.dart';
import 'package:daylock/services/instagram_detection_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'instagram_detection_bridge_test.dart' show statusMap;

const sampleApps = [
  InstalledRestrictedApp(packageName: 'test.video', name: 'YouTube'),
  InstalledRestrictedApp(packageName: 'test.social', name: 'Instagram'),
  InstalledRestrictedApp(packageName: 'test.browser', name: 'Chrome'),
];

class PickerBridge extends InstagramDetectionBridge {
  final selected = <String>{};
  var failDiscovery = false;
  Completer<void>? hold;
  List<InstalledRestrictedApp> apps = sampleApps;
  PickerBridge() : super(android: false) {
    update();
  }
  void update({String? error}) => status.value = InstagramDetectionStatus(
    supported: true,
    blockingEnabled: true,
    enabled: false,
    selectedPackages: Set.of(selected),
    selectionError: error,
  );
  @override
  Future<List<InstalledRestrictedApp>> loadInstalledApps() async {
    if (failDiscovery) throw StateError('PackageManager unavailable');
    return apps;
  }

  @override
  Future<void> setRestrictedApp(String packageName, bool value) async {
    await hold?.future;
    if (value) {
      selected.add(packageName);
    } else {
      selected.remove(packageName);
    }
    update();
  }
}

Future<void> tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> mount(
  WidgetTester tester,
  PickerBridge bridge, {
  double scale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: DaylockTheme.dark,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: SettingsPage(
        title: 'Restricted Apps',
        children: [
          RestrictedAppsSection(bridge: bridge, onMasterChanged: (_) async {}),
        ],
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Search and alphabetical sorting use real display names with stable tie breaking', () {
    expect(filterRestrictedApps(sampleApps, '').map((e) => e.name), [
      'Chrome',
      'Instagram',
      'YouTube',
    ]);
    expect(
      filterRestrictedApps(sampleApps, '  INSTA ').single.packageName,
      'test.social',
    );
    expect(filterRestrictedApps(sampleApps, 'absent'), isEmpty);
  });
  testWidgets(
    'Empty selections, search, multiple toggles and native readback survive widget recreation',
    (tester) async {
      final bridge = PickerBridge();
      await mount(tester, bridge);
      expect(find.text('0 SELECTED'), findsOneWidget);
      expect(find.textContaining('No apps selected yet.'), findsOneWidget);
      await tap(tester, 'restricted-app-test.browser');
      await tap(tester, 'restricted-app-test.social');
      expect(bridge.selected, {'test.browser', 'test.social'});
      expect(find.text('2 SELECTED'), findsOneWidget);
      expect(
        find.textContaining('Waiting for Accessibility access.'),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('restricted-app-search')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('restricted-app-search')),
        'tube',
      );
      await tester.pumpAndSettle();
      expect(find.text('Chrome'), findsNothing);
      expect(find.text('YouTube'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('restricted-app-search')),
        'no matches',
      );
      await tester.pumpAndSettle();
      expect(find.text('No matching apps.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await mount(tester, bridge);
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const ValueKey('restricted-app-test.social')),
            )
            .value,
        isTrue,
      );
      await tester.pumpWidget(const SizedBox());
      await bridge.close();
    },
  );
  testWidgets(
    'Rapid selection changes show immediate feedback and settle to latest saved choice',
    (tester) async {
      final bridge = PickerBridge()..hold = Completer<void>();
      await mount(tester, bridge);
      await tap(tester, 'restricted-app-test.social');
      expect(find.text('1 SELECTED'), findsOneWidget);
      expect(bridge.selected, isEmpty);
      await tap(tester, 'restricted-app-test.social');
      expect(find.text('0 SELECTED'), findsOneWidget);
      bridge.hold!.complete();
      await tester.pumpAndSettle();
      expect(bridge.selected, isEmpty);
      expect(find.text('Saving selection…'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await bridge.close();
    },
  );
  testWidgets(
    'Discovery failure does not overwrite selections; retry reloads installed apps',
    (tester) async {
      final bridge = PickerBridge()..failDiscovery = true;
      bridge.selected.add('test.social');
      bridge.update();
      await mount(tester, bridge);
      expect(
        find.textContaining('Could not load installed apps.'),
        findsOneWidget,
      );
      expect(find.text('1 SELECTED'), findsOneWidget);
      bridge.failDiscovery = false;
      await tester.tap(find.text('Retry app discovery'));
      await tester.pumpAndSettle();
      expect(find.text('Instagram'), findsOneWidget);
      bridge.apps = [];
      bridge.selected.clear();
      bridge.update();
      await tap(tester, 'refresh-apps');
      expect(
        find.textContaining('No supported launchable apps'),
        findsOneWidget,
      );
      expect(find.text('0 SELECTED'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await bridge.close();
    },
  );
  for (final scale in [1.0, 2.0, 3.0]) {
    testWidgets('Picker remains usable at 320px and ${scale}x text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final bridge = PickerBridge();
      await mount(tester, bridge, scale: scale);
      await tap(tester, 'restricted-app-test.video');
      expect(bridge.selected, {'test.video'});
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await bridge.close();
    });
  }

  test('Platform channel serializes package deltas, preserves Freedom/master, and reloads native selections', () async {
    const method = MethodChannel('test/multi_apps');
    const event = EventChannel('test/multi_apps/events');
    const eventControl = MethodChannel('test/multi_apps/events');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final selected = <String>{};
    var revision = 1;
    Map<String, dynamic> status() => {
      ...statusMap(freedom: 'earned'),
      'blockingEnabled': false,
      'selectedPackages': selected.toList(),
      'selectionRevision': revision,
    };
    messenger.setMockMethodCallHandler(eventControl, (_) async => null);
    messenger.setMockMethodCallHandler(method, (call) async {
      if (call.method == 'setRestrictedApp') {
        final args = call.arguments as Map;
        if (args['selected'] == true) {
          selected.add(args['packageName'] as String);
        } else {
          selected.remove(args['packageName']);
        }
        revision++;
      }
      if (call.method == 'getInstalledApps') {
        return {
          'status': status(),
          'apps': [
            {
              'packageName': 'test.social',
              'name': 'Instagram',
              'icon': Uint8List.fromList([1, 2, 3]),
            },
          ],
        };
      }
      return status();
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(method, null);
      messenger.setMockMethodCallHandler(eventControl, null);
    });
    var bridge = InstagramDetectionBridge(
      methods: method,
      events: event,
      android: true,
    );
    await bridge.start();
    final apps = await bridge.loadInstalledApps();
    expect(apps.single.icon, [1, 2, 3]);
    await Future.wait([
      bridge.setRestrictedApp('test.social', true),
      bridge.setRestrictedApp('test.video', true),
      bridge.setRestrictedApp('test.social', false),
    ]);
    expect(bridge.status.value.selectedPackages, {'test.video'});
    expect(bridge.status.value.blockingEnabled, isFalse);
    expect(bridge.status.value.freedomState, 'earned');
    await bridge.close();
    bridge = InstagramDetectionBridge(
      methods: method,
      events: event,
      android: true,
    );
    await bridge.start();
    expect(bridge.status.value.selectedPackages, {'test.video'});
    await bridge.close();
  });
}

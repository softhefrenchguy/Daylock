import 'package:daylock/design/appearance_preferences.dart';
import 'package:daylock/design/daylock_palette.dart';
import 'package:daylock/design/daylock_theme.dart';
import 'package:daylock/screens/instagram_detection_section.dart';
import 'package:daylock/services/instagram_detection_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'instagram_detection_bridge_test.dart' show input, statusMap;

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

// Widget tests exercise consent and rendering; channel persistence is tested above.
class SettingsBridge extends InstagramDetectionBridge {
  SettingsBridge(this.onChoice) : super(android: false) {
    status.value = InstagramDetectionStatus.fromMap(
      statusMap(freedom: 'notEarned'),
    );
  }
  final void Function(bool) onChoice;
  @override
  Future<void> setBlockingEnabled(bool enabled) async {
    onChoice(enabled);
    status.value = InstagramDetectionStatus.fromMap({
      ...statusMap(freedom: 'notEarned'),
      'blockingEnabled': enabled,
      'lastRestriction': 'home_only',
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const methods = MethodChannel('test/daylock_blocking');
  const events = EventChannel('test/daylock_blocking/events');
  const eventMethods = MethodChannel('test/daylock_blocking/events');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late bool storedChoice;
  late List<MethodCall> calls;
  setUp(() {
    storedChoice = false;
    calls = [];
    messenger.setMockMethodCallHandler(methods, (call) async {
      calls.add(call);
      if (call.method == 'setBlockingEnabled') {
        storedChoice = (call.arguments as Map)['enabled'] as bool;
      }
      return {
        ...statusMap(freedom: 'notEarned'),
        'blockingEnabled': storedChoice,
        'lastRestriction': 'home_only',
      };
    });
    messenger.setMockMethodCallHandler(eventMethods, (_) async => null);
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(methods, null);
    messenger.setMockMethodCallHandler(eventMethods, null);
  });
  InstagramDetectionBridge bridge() =>
      InstagramDetectionBridge(methods: methods, events: events, android: true);

  test(
    'Legacy detector status defaults blocking off without altering Freedom',
    () {
      final status = InstagramDetectionStatus.fromMap(statusMap());
      expect(status.blockingEnabled, isFalse);
      expect(status.freedomState, 'earned');
    },
  );
  test('Blocking setting is separate, read back from native and restored on a new bridge', () async {
    final service = bridge();
    await service.start();
    await service.setBlockingEnabled(true);
    expect(service.status.value.blockingEnabled, isTrue);
    expect(service.status.value.freedomState, 'notEarned');
    expect(calls.last.arguments, {'enabled': true});
    await service.publishSnapshot(input());
    expect(
      (calls.last.arguments as Map).containsKey('blockingEnabled'),
      isFalse,
    );
    await service.close();
    final restarted = bridge();
    await restarted.start();
    expect(restarted.status.value.blockingEnabled, isTrue);
    await restarted.setBlockingEnabled(false);
    expect(storedChoice, isFalse);
    await restarted.close();
  });
  test('Native failure keeps the last known choice and never reports a verified restriction', () async {
    final service = bridge();
    await service.start();
    await service.setBlockingEnabled(true);
    messenger.setMockMethodCallHandler(
      methods,
      (_) async => throw PlatformException(code: 'FAILED'),
    );
    await service.setBlockingEnabled(false);
    expect(service.status.value.blockingEnabled, isTrue);
    expect(service.status.value.error, isNotNull);
    expect(service.status.value.freedomState, 'unknown');
    await service.close();
  });
  for (final colour in ColourTheme.values) {
    test(
      '$colour native lock appearance uses both central palettes and System mode',
      () async {
        final service = bridge();
        await service.start();
        await service.publishAppearance(
          AppearancePreferences(colour: colour, mode: AppearanceMode.system),
        );
        final map = calls.last.arguments as Map;
        expect(calls.last.method, 'publishAppearance');
        expect(map['mode'], 'system');
        for (final brightness in Brightness.values) {
          final palette = DaylockTheme.forPalette(
            colour,
            brightness,
          ).colorScheme;
          final variant = map[brightness.name] as Map;
          expect(variant['background'], palette.surface.toARGB32());
          expect(variant['accent'], palette.primary.toARGB32());
          expect(variant['foreground'], palette.onSurface.toARGB32());
          expect(variant['onAccent'], palette.onPrimary.toARGB32());
        }
        await service.close();
      },
    );
  }
  testWidgets(
    'Enabling requires explicit consent; cancelling does nothing; disabling is immediate',
    (tester) async {
      final service = SettingsBridge((value) => storedChoice = value);
      await tester.pumpWidget(
        MaterialApp(
          theme: DaylockTheme.dark,
          home: Scaffold(
            body: SingleChildScrollView(
              child: InstagramDetectionSection(bridge: service),
            ),
          ),
        ),
      );
      final toggle = find.byKey(const ValueKey('instagram-blocking-enabled'));
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
      await tap(tester, toggle);
      expect(find.text('Enable app restrictions?'), findsOneWidget);
      await tap(tester, find.text('Cancel'));
      expect(storedChoice, isFalse);
      await tap(tester, toggle);
      await tap(
        tester,
        find.byKey(const ValueKey('confirm-instagram-blocking')),
      );
      await tester.pumpAndSettle();
      expect(storedChoice, isTrue);
      expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
      await tap(tester, toggle);
      expect(find.byType(AlertDialog), findsNothing);
      await tester.pumpAndSettle();
      expect(storedChoice, isFalse);
      await tester.pumpWidget(const SizedBox());
      await service.close();
    },
  );
  testWidgets(
    'Settings distinguishes ready, earned, control off, unknown, revoked and Home-only fallback',
    (tester) async {
      final service = SettingsBridge((value) => storedChoice = value);
      await tester.pumpWidget(
        MaterialApp(
          theme: DaylockTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: InstagramDetectionSection(bridge: service),
            ),
          ),
        ),
      );
      const cases = [
        ('notEarned', true, 'App restrictions ready'),
        ('earned', true, 'Selected apps allowed — Freedom earned'),
        ('disabled', true, 'Selected apps allowed — Freedom Control is off'),
        ('unknown', true, 'Blocking paused'),
        ('notEarned', false, 'waiting for Accessibility'),
      ];
      for (final item in cases) {
        service.status.value = InstagramDetectionStatus(
          supported: true,
          enabled: item.$2,
          connected: item.$2,
          blockingEnabled: true,
          freedomState: item.$1,
          lastRestriction: 'lock_launch_unconfirmed',
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<Text>(
                find.byKey(const ValueKey('instagram-blocking-status')),
              )
              .data,
          contains(item.$3),
        );
        expect(
          find.textContaining('lock screen was not confirmed'),
          findsOneWidget,
        );
      }
      service.status.value = const InstagramDetectionStatus(
        supported: true,
        blockingEnabled: true,
        error: 'Native unavailable',
      );
      await tester.pumpAndSettle();
      expect(find.text('App restriction status unavailable'), findsOneWidget);
      expect(find.text('Turn blocking off'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await service.close();
    },
  );
  testWidgets(
    'Lock launch and notification statuses never claim a confirmed visible screen',
    (tester) async {
      final service = SettingsBridge((value) => storedChoice = value);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: InstagramDetectionSection(bridge: service),
            ),
          ),
        ),
      );
      const messages = {
        'lock_launch_requested': 'display not yet confirmed',
        'lock_fallback_posted': 'Android controls its delivery',
        'lock_fallback_unavailable': 'App restriction notices channel',
      };
      for (final entry in messages.entries) {
        service.status.value = InstagramDetectionStatus(
          supported: true,
          enabled: true,
          connected: true,
          blockingEnabled: true,
          freedomState: 'notEarned',
          lastRestriction: entry.key,
        );
        await tester.pumpAndSettle();
        expect(find.textContaining(entry.value), findsOneWidget);
        expect(find.textContaining('lock screen shown.'), findsNothing);
        expect(find.textContaining('Home requested'), findsNothing);
      }
      await tester.pumpWidget(const SizedBox());
      await service.close();
    },
  );
  testWidgets(
    'Blocking consent is usable at narrow width with 200 percent text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final service = SettingsBridge((value) => storedChoice = value);
      await tester.pumpWidget(
        MaterialApp(
          theme: DaylockTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: InstagramDetectionSection(bridge: service),
            ),
          ),
        ),
      );
      await tap(
        tester,
        find.byKey(const ValueKey('instagram-blocking-enabled')),
      );
      await tap(
        tester,
        find.byKey(const ValueKey('confirm-instagram-blocking')),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(storedChoice, isTrue);
      await tester.pumpWidget(const SizedBox());
      await service.close();
    },
  );
}

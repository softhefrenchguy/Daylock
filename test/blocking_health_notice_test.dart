import 'package:daylock/screens/blocking_health_notice.dart';
import 'package:daylock/services/instagram_detection_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

InstagramDetectionStatus status({
  bool enabled = true,
  bool connected = true,
  bool blocking = true,
  bool xiaomi = false,
  Set<String> apps = const {'com.instagram.android'},
}) => InstagramDetectionStatus(
  supported: true,
  enabled: enabled,
  connected: enabled && connected,
  blockingEnabled: blocking,
  xiaomiDevice: xiaomi,
  selectedPackages: apps,
);

void main() {
  final notice = find.byKey(const ValueKey('blocking-health-notice'));

  Future<(ValueNotifier<InstagramDetectionStatus>, List<String>)> pump(
    WidgetTester tester,
    InstagramDetectionStatus initial,
  ) async {
    final value = ValueNotifier(initial);
    final opened = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlockingHealthNotice(
            status: value,
            onOpenAccessibility: () => opened.add('accessibility'),
            onOpenAppInfo: () => opened.add('app-info'),
          ),
        ),
      ),
    );
    return (value, opened);
  }

  testWidgets('A service Android stopped is reported after the grace period', (
    tester,
  ) async {
    final (_, opened) = await pump(
      tester,
      status(connected: false, xiaomi: true),
    );
    expect(notice, findsNothing, reason: 'normal start-up must not flash it');
    await tester.pump(const Duration(seconds: 3));
    expect(notice, findsOneWidget);
    expect(find.text('App blocking has stopped'), findsOneWidget);
    expect(find.textContaining('Autostart'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('blocking-health-accessibility')),
    );
    await tester.tap(find.byKey(const ValueKey('blocking-health-app-info')));
    expect(opened, ['accessibility', 'app-info']);
  });

  testWidgets(
    'Reconnecting hides the notice; a quick reconnect never shows it',
    (tester) async {
      final (value, _) = await pump(tester, status(connected: false));
      await tester.pump(const Duration(seconds: 1));
      value.value = status();
      await tester.pump(const Duration(seconds: 5));
      expect(notice, findsNothing);

      value.value = status(connected: false);
      await tester.pump(const Duration(seconds: 3));
      expect(notice, findsOneWidget);
      expect(
        find.byKey(const ValueKey('blocking-health-app-info')),
        findsNothing,
      );
      value.value = status();
      await tester.pump();
      expect(notice, findsNothing);
    },
  );

  testWidgets('Accessibility switched off is reported as blocking off', (
    tester,
  ) async {
    await pump(tester, status(enabled: false));
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('App blocking is off'), findsOneWidget);
  });

  test('Only warns when blocking is actually set up', () {
    expect(BlockingHealthNotice.needsAttention(status()), isFalse);
    expect(
      BlockingHealthNotice.needsAttention(
        status(connected: false, blocking: false),
      ),
      isFalse,
    );
    expect(
      BlockingHealthNotice.needsAttention(status(connected: false, apps: {})),
      isFalse,
    );
    expect(
      BlockingHealthNotice.needsAttention(
        const InstagramDetectionStatus(), // web / unsupported
      ),
      isFalse,
    );
    expect(
      BlockingHealthNotice.needsAttention(status(connected: false)),
      isTrue,
    );
  });
}

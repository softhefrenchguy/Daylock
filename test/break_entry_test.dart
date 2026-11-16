import 'package:daylock/models/break_entry.dart';
import 'package:daylock/screens/journey_screen.dart';
import 'package:daylock/services/instagram_detection_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'journey_redesign_test.dart' show areas, data, moments, now;

Map<String, Object?> _break(DateTime at, String reason) => {
  'date': '${at.year}-${at.month}-${at.day}',
  'at': at.millisecondsSinceEpoch,
  'app': 'Instagram',
  'package': 'com.instagram.android',
  'reason': reason,
};

Widget _journey(List<BreakEntry> breaks) => MaterialApp(
  home: Scaffold(
    body: JourneyScreen(
      areas: areas,
      highlights: moments,
      data: data,
      breaks: breaks,
      onAreaOpened: (_) {},
      onHighlightOpened: (_) {},
      onAddHighlight: () {},
      onAllHighlights: () {},
      onDailyHistory: () {},
    ),
  ),
);

void main() {
  test('breaks are read from the native status, skipping bad entries', () {
    final status = InstagramDetectionStatus.fromMap({
      'supported': true,
      'enabled': true,
      'freedom': {'state': 'notEarned', 'reason': 'conditions_remaining'},
      'breakRemainingMs': 600000,
      'breaks': [
        _break(DateTime(2026, 10, 25, 14, 20), 'Reply to my sister'),
        {'at': 'not a time', 'reason': 'x'},
        null,
      ],
    });
    expect(status.breaks, hasLength(1));
    expect(status.breaks.single.reason, 'Reply to my sister');
    expect(status.breaks.single.app, 'Instagram');
    expect(status.breakRemaining, const Duration(minutes: 10));
    expect(const InstagramDetectionStatus().breaks, isEmpty);
  });

  test('recent breaks are the last 30 days, newest first', () {
    final all = [
      BreakEntry(
        at: now.subtract(const Duration(days: 40)),
        app: 'A',
        reason: 'old',
      ),
      BreakEntry(
        at: now.subtract(const Duration(days: 2)),
        app: 'B',
        reason: 'b',
      ),
      BreakEntry(
        at: now.subtract(const Duration(hours: 3)),
        app: 'C',
        reason: 'c',
      ),
    ];
    expect(BreakEntry.recent(all, now).map((b) => b.reason), ['c', 'b']);
  });

  testWidgets('Journey lists recent breaks with their reasons', (tester) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _journey([
        BreakEntry(
          at: now.subtract(const Duration(days: 1)),
          app: 'Instagram',
          reason: 'Reply to my sister',
        ),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('journey-breaks')), findsOneWidget);
    expect(find.text('Breaks'), findsOneWidget);
    expect(find.text('“Reply to my sister”'), findsOneWidget);
    expect(find.textContaining('Instagram · '), findsOneWidget);
  });

  testWidgets('Journey has no Breaks section without recent breaks', (
    tester,
  ) async {
    await tester.pumpWidget(
      _journey([
        BreakEntry(
          at: now.subtract(const Duration(days: 60)),
          app: 'Instagram',
          reason: 'Long ago',
        ),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('journey-breaks')), findsNothing);
  });
}

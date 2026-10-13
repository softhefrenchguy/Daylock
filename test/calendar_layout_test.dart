import 'package:daylock/models/calendar_cache.dart';
import 'package:daylock/models/calendar_account.dart';
import 'package:daylock/models/event.dart';
import 'package:daylock/screens/calendar_screen.dart';
import 'package:daylock/services/calendar_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'calendar_test_fixtures.dart';

void main() {
  for (final pixelRatio in [2.625, 2.75, 3.25, 3.0]) {
    testWidgets(
      'Calendar lays out and navigates at Android pixel ratio $pixelRatio',
      (tester) async {
        // 1080 physical pixels / 2.625 produces a fractional logical width. The
        // original full-width picker trips the sliver precision assertion here.
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = pixelRatio;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final today = DateTime(2026, 10, 8);
        final account = testAccount(CalendarProviderType.google);
        final remote = testExternal(account, date: DateTime(2026, 10, 9, 10));
        final cache = testCache(account, events: [remote]);
        final local = Event(
          id: 'local',
          title: 'Local appointment',
          date: today,
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(platform: TargetPlatform.android),
            home: Scaffold(
              body: CalendarScreen(
                initialDate: today,
                events: [local, remote],
                calendarCache: cache,
                calendarService: CalendarService(
                  credentials: MemoryCredentials(),
                ),
                onCalendarCacheChanged: (CalendarCache updated) async =>
                    updated,
                onEventSaved: (_) {},
                onEventDeleted: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Local appointment'), findsOneWidget);
        expect(find.text('Remote meeting'), findsNothing);

        await tester.tap(find.byTooltip('Next month'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('November 2026'), findsOneWidget);
        await tester.tap(find.byTooltip('Previous month'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const ValueKey('calendar-day-2026-10-09')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Local appointment'), findsNothing);
        expect(find.text('Remote meeting'), findsOneWidget);
        expect(find.byTooltip('Edit Remote meeting'), findsNothing);
        expect(find.byTooltip('Delete Remote meeting'), findsNothing);

        await tester.tap(find.byTooltip('Calendar accounts'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Calendar accounts'), findsOneWidget);
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Recompute the grid width when the device rotates, preserving selection.
        tester.view.physicalSize = const Size(2400, 1080);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Remote meeting'), findsOneWidget);
        await tester.tap(find.byTooltip('Next month'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('November 2026'), findsOneWidget);
      },
    );
  }
}

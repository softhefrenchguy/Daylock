import 'dart:io';
import 'dart:convert';

import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/highlight.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/services/journey_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'journey_redesign_test.dart' as fixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // Real Android font metrics matter for viewport fit; Ahem deliberately has
    // square glyphs. Resolve Flutter's bundled font without a machine-local path.
    final config = File('.dart_tool/package_config.json').absolute;
    final packages =
        (jsonDecode(await config.readAsString()) as Map)['packages'] as List;
    final flutter = packages.cast<Map>().singleWhere(
      (entry) => entry['name'] == 'flutter',
    );
    final sdk = Directory.fromUri(
      config.uri.resolve(flutter['rootUri'] as String),
    ).parent.parent;
    final font = File(
      '${sdk.path}/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
    );
    await (FontLoader(
      'Roboto',
    )..addFont(font.readAsBytes().then(ByteData.sublistView))).load();
  });

  for (final sample in [
    (width: 360.0, height: 800.0, count: 1),
    (width: 390.0, height: 844.0, count: 1),
    (width: 390.0, height: 844.0, count: 3),
    (width: 412.0, height: 892.0, count: 3),
  ]) {
    testWidgets(
      'Complete overview fits ${sample.width}x${sample.height} with ${sample.count} Highlights',
      (tester) async {
        fixture.phone(tester, width: sample.width, height: sample.height);
        final data = JourneyData(
          areas: fixture.areas,
          history: fixture.history,
          todayPlan: DailyPlan(
            date: fixture.now,
            tasks: [
              Task(
                name: 'Recorded study',
                type: TaskType.focus,
                areaId: 'learn',
                accumulatedFocusMilliseconds: (9 * 60 + 27) * 60000,
              ),
              ...fixture.today.tasks.where((t) => t.type == TaskType.goal),
            ],
          ),
          now: fixture.now,
        );
        await tester.pumpWidget(
          fixture.shell(
            fixture.overview(
              journey: data,
              highlights: HighlightBook(
                fixture.moments.highlights.take(sample.count),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final navigationTop = tester.getRect(find.byType(NavigationBar)).top;
        for (final id in [
          'featured-highlights',
          'daily-history',
          'past-chapters',
        ]) {
          final entry = fixture.key(id);
          expect(
            tester.getRect(entry).bottom,
            lessThanOrEqualTo(navigationTop),
            reason: id,
          );
          expect(entry.hitTestable(), findsOneWidget);
        }
        final scroll = tester.state<ScrollableState>(fixture.vertical).position;
        expect(scroll.pixels, 0);
        expect(scroll.maxScrollExtent, lessThanOrEqualTo(.5));
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final largeText in [false, true]) {
    testWidgets(
      'Overflow remains scrollable for ${largeText ? 'large text and more Areas' : 'a smaller screen'}',
      (tester) async {
        fixture.phone(tester, width: 320, height: 568);
        var areas = fixture.areas;
        if (largeText) {
          for (var i = 0; i < 5; i++) {
            areas = areas.upsert(fixture.custom('extra-$i', 'Extra Area $i'));
          }
        }
        await tester.pumpWidget(
          fixture.shell(
            fixture.overview(book: areas),
            scale: largeText ? 2 : 1,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .state<ScrollableState>(fixture.vertical)
              .position
              .maxScrollExtent,
          greaterThan(0),
        );
        await tester.scrollUntilVisible(
          fixture.key('past-chapters'),
          200,
          scrollable: fixture.vertical,
          maxScrolls: 80,
        );
        await tester.pumpAndSettle();
        expect(fixture.key('past-chapters').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

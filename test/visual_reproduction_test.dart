import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daylock/design/daylock_task_row.dart';
import 'package:daylock/design/daylock_theme.dart';
import 'package:daylock/design/journey_surface.dart';

import '../tool/visual_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final config = File('.dart_tool/package_config.json').absolute;
    final packages =
        (jsonDecode(await config.readAsString()) as Map)['packages'] as List;
    final flutter = packages.cast<Map>().singleWhere(
      (p) => p['name'] == 'flutter',
    );
    final sdk = Directory.fromUri(
      config.uri.resolve(flutter['rootUri'] as String),
    ).parent.parent;
    await (FontLoader('MaterialIcons')..addFont(
          File(
            '${sdk.path}/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
          ).readAsBytes().then(ByteData.sublistView),
        ))
        .load();
    await (FontLoader('Roboto')..addFont(
          File(
            '${sdk.path}/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
          ).readAsBytes().then(ByteData.sublistView),
        ))
        .load();
  });
  const names = [
    'today-completed',
    'today-running',
    'plan-empty',
    'plan-populated',
    'journey',
  ];
  for (var state = 0; state < names.length; state++) {
    testWidgets('${names[state]} renders at reference proportions', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(VisualFixture(initialState: state));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (state == 0) {
        expect(
          tester
              .widget<CircularProgressIndicator>(
                find.byType(CircularProgressIndicator),
              )
              .value,
          1,
        );
        for (final row in find.byType(DaylockTaskRow).evaluate()) {
          expect(
            tester.getSize(find.byWidget(row.widget)).height,
            lessThan(86),
          );
        }
      }
      if (state < 2) {
        expect(
          tester
              .getBottomRight(find.byKey(const ValueKey('freedom-status')))
              .dy,
          lessThanOrEqualTo(tester.getTopLeft(find.byType(NavigationBar)).dy),
        );
      }
      if (const bool.fromEnvironment('CAPTURE_VISUALS')) {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('visual-capture')),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('docs/images/visual-reproduction')
              .create(recursive: true);
          await File(
            'docs/images/visual-reproduction/${names[state]}-widget.png',
          ).writeAsBytes(png!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }
  for (final state in [0, 2, 4]) {
    testWidgets('Overview $state fits with Android system insets', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      await tester.pumpWidget(VisualFixture(initialState: state));
      await tester.pumpAndSettle();
      final bottom = state == 0
          ? find.byKey(const ValueKey('freedom-status'))
          : state == 2
          ? find.ancestor(
              of: find.text('No commitments planned yet.'),
              matching: find.byType(JourneySurface),
            )
          : find.byKey(const ValueKey('daily-history'));
      final limit = state == 2
          ? find.byKey(const ValueKey('plan-commit-bar'))
          : find.byType(NavigationBar);
      expect(
        tester.getBottomRight(bottom).dy,
        lessThanOrEqualTo(tester.getTopLeft(limit).dy),
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'Changing an Area colour retints completed cards without rewriting the task',
    (tester) async {
      final task = fixtureToday().tasks.first;
      final original = jsonEncode(task.toJson());
      final area = fixtureAreas.resolve(task.areaId).copyWith(isArchived: true);
      Future<void> show(Color color) => tester.pumpWidget(
        MaterialApp(
          theme: DaylockTheme.dark,
          home: Scaffold(
            body: DaylockTaskRow(
              task: task,
              area: area.copyWith(colour: color.toARGB32()),
              currentTime: fixtureNow,
              onGoalChanged: () {},
              onFocusToggled: () {},
            ),
          ),
        ),
      );
      for (final color in [Colors.green, Colors.blue]) {
        await show(color);
        expect(
          tester.widget<JourneySurface>(find.byType(JourneySurface)).accent,
          Color(color.toARGB32()),
        );
        expect(jsonEncode(task.toJson()), original);
      }
    },
  );
}

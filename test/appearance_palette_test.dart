import 'package:daylock/design/daylock_palette.dart';
import 'package:daylock/design/daylock_theme.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/screens/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return ((x > y ? x : y) + 0.05) / ((x > y ? y : x) + 0.05);
}

void main() {
  for (final colour in ColourTheme.values) {
    for (final brightness in Brightness.values) {
      test(
        '$colour $brightness coordinates all surfaces and retains accessible contrast',
        () {
          final theme = DaylockTheme.forPalette(colour, brightness);
          final scheme = theme.colorScheme;
          final semantic = theme.extension<DaylockColors>()!;
          for (final pair in [
            (scheme.onSurface, scheme.surface),
            (scheme.onSurfaceVariant, scheme.surface),
            (scheme.onSurface, scheme.surfaceContainerLow),
            (scheme.onSurfaceVariant, scheme.surfaceContainerLow),
            (scheme.primary, scheme.surface),
            (scheme.onPrimary, scheme.primary),
            (scheme.onSurface, semantic.focusActiveSurface),
            (scheme.onSurfaceVariant, semantic.focusActiveSurface),
            (scheme.primary, semantic.focusActiveSurface),
            (semantic.statusAccent, semantic.statusSurface),
            (semantic.onStatus, semantic.statusSurface),
            (semantic.onStatusMuted, semantic.statusSurface),
            (semantic.onStatusMuted, semantic.completedSurface),
            (scheme.error, scheme.surface),
          ]) {
            expect(
              _contrast(pair.$1, pair.$2),
              greaterThanOrEqualTo(4.5),
              reason: '$colour $brightness: ${pair.$1} on ${pair.$2}',
            );
          }
          expect(scheme.surface, isNot(scheme.surfaceContainerLow));
          expect(theme.dividerTheme.color, scheme.outlineVariant);
          expect(theme.progressIndicatorTheme.color, scheme.primary);
          expect(
            theme.navigationBarTheme.iconTheme!.resolve({
              WidgetState.selected,
            })!.color,
            scheme.primary,
          );
          expect(
            identical(theme, DaylockTheme.forPalette(colour, brightness)),
            isTrue,
          );
        },
      );

      testWidgets(
        'Today responds to $colour $brightness and retains Goal/Focus controls',
        (tester) async {
          final now = DateTime(2026, 10, 8, 9);
          final goal = Task(name: 'Walk', type: TaskType.goal);
          final focus = Task(
            name: 'Read',
            type: TaskType.focus,
            minimumFocusMinutes: 60,
            accumulatedFocusMilliseconds: 23 * 60000,
          );
          var started = false;
          final theme = DaylockTheme.forPalette(colour, brightness);
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: Scaffold(
                body: StatefulBuilder(
                  builder: (context, update) => TodayScreen(
                    plan: DailyPlan(date: now, tasks: [goal, focus]),
                    currentTime: now,
                    onTaskChanged: () => update(() {}),
                    onFocusToggled: (_) => started = true,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('Walk'));
          await tester.pumpAndSettle();
          expect(goal.isCompleted, isTrue);
          expect(find.text('1 / 2 complete'), findsOneWidget);
          expect(find.byType(Checkbox), findsNWidgets(2));
          expect(find.text('23:00'), findsOneWidget);
          final button = find.byKey(ValueKey('stopwatch-toggle-${focus.id}'));
          await tester.ensureVisible(button);
          await tester.tap(button);
          expect(started, isTrue);
          expect(focus.isCompleted, isFalse);
          await tester.tap(find.byKey(const ValueKey('freedom-indicator')));
          await tester.pumpAndSettle();
          final status = tester.widget<AnimatedContainer>(
            find.byKey(const ValueKey('freedom-status')),
          );
          expect(
            (status.decoration as BoxDecoration).color,
            theme.extension<DaylockColors>()!.statusSurface,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  test('Every palette changes background, surfaces, borders and status, not only the accent', () {
    for (final brightness in Brightness.values) {
      final themes = ColourTheme.values
          .map((c) => DaylockTheme.forPalette(c, brightness))
          .toList();
      for (final colors in [
        themes.map((t) => t.colorScheme.surface),
        themes.map((t) => t.colorScheme.surfaceContainerLow),
        themes.map((t) => t.colorScheme.outlineVariant),
        themes.map((t) => t.extension<DaylockColors>()!.statusSurface),
      ]) {
        expect(colors.toSet(), hasLength(6));
      }
    }
    final violet = DaylockTheme.dark;
    expect(violet.colorScheme.surface, const Color(0xFF171321));
    expect(violet.colorScheme.primary, const Color(0xFFA78BDB));
    expect(
      violet.extension<DaylockColors>()!.statusSurface,
      const Color(0xFF211A2E),
    );
  });

  test(
    'Mono stays neutral, including fixed Material roles and error styling',
    () {
      for (final brightness in Brightness.values) {
        final scheme = DaylockTheme.forPalette(
          ColourTheme.mono,
          brightness,
        ).colorScheme;
        for (final color in [
          scheme.surface,
          scheme.surfaceContainerLow,
          scheme.primary,
          scheme.onSurface,
          scheme.primaryFixed,
          scheme.secondaryFixed,
          scheme.tertiaryFixed,
          scheme.inversePrimary,
          scheme.error,
          scheme.errorContainer,
        ]) {
          expect(color.r, color.g);
          expect(color.g, color.b);
        }
      }
    },
  );
}

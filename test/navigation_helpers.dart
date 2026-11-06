import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daylock/design/daylock_task_row.dart';

/// Keep Calendar regression scenarios intact through its new secondary route.
Future<void> navigateApp(WidgetTester tester, String destination) async {
  while (find.byType(NavigationBar).hitTestable().evaluate().isEmpty) {
    await tester.pageBack();
    await tester.pumpAndSettle();
  }
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(destination == 'Calendar' ? 'Journey' : destination),
    ),
  );
  await tester.pumpAndSettle();
  if (destination == 'Calendar') {
    final entry = find.byKey(const ValueKey('daily-history'));
    final journey = find.descendant(
      of: find.byKey(const ValueKey('journey-content')),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    // Start from the top: Journey keeps its scroll position between visits.
    tester.state<ScrollableState>(journey).position.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(entry, 300, scrollable: journey);
    await tester.ensureVisible(entry);
    await tester.pumpAndSettle();
    await tester.tap(entry);
    await tester.pumpAndSettle();
  }
}

/// The round checkbox that keeps a commitment on Today. Tapping the row itself
/// opens its actions, so completion always goes through this control.
Finder keepBox(String name) => find.descendant(
  of: find.widgetWithText(DaylockTaskRow, name),
  matching: find.byType(Checkbox),
);

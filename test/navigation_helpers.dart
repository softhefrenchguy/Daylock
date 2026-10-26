import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
    await tester.scrollUntilVisible(
      entry,
      300,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('journey-content')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.ensureVisible(entry);
    await tester.pumpAndSettle();
    await tester.tap(entry);
    await tester.pumpAndSettle();
  }
}

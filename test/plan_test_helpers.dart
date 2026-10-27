import 'package:daylock/screens/commitment_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> openCommitmentEditor(WidgetTester tester) async {
  if (find.byType(CommitmentEditor).evaluate().isNotEmpty) return;
  final open = find.byKey(const ValueKey('open-commitment-editor'));
  if (open.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      open,
      350,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('plan-content')),
        matching: find.byType(Scrollable),
      ),
      maxScrolls: 50,
    );
  }
  await tester.ensureVisible(open);
  await tester.pumpAndSettle();
  await tester.tap(open);
  await tester.pumpAndSettle();
}

Future<void> enterPlanText(
  WidgetTester tester,
  Finder field,
  String value,
) async {
  await openCommitmentEditor(tester);
  await tester.enterText(field, value);
}

Future<void> confirmPlanCommit(WidgetTester tester) async {
  await tester.pumpAndSettle();
  final confirm = find.byKey(const ValueKey('confirm-commit'));
  expect(confirm, findsOneWidget);
  await tester.ensureVisible(confirm);
  await tester.tap(confirm);
  await tester.pumpAndSettle();
}

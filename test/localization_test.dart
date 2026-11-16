import 'package:daylock/l10n/l10n.dart';
import 'package:daylock/main.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/routine.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:daylock/services/notifications/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'notification_preferences_test.dart' show notificationFixture;

class _Notifications extends NotificationService {
  @override
  Future<void> invalidate() async {}
  @override
  Future<void> synchronize(DaylockState state, DateTime now) async {}
  @override
  Future<void> requestPermission() async {}
}

/// Tab labels and one Today heading per language, as the app shows them.
const _expected = {
  'en': ('Today', 'Plan', 'Journey', 'Commitments'),
  'fr': ('Aujourd’hui', 'Planifier', 'Parcours', 'Engagements'),
  'es': ('Hoy', 'Planificar', 'Camino', 'Compromisos'),
  'de': ('Heute', 'Planen', 'Weg', 'Vorsätze'),
  'ar': ('اليوم', 'التخطيط', 'المسيرة', 'الالتزامات'),
};

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  for (final entry in _expected.entries) {
    final lang = entry.key;
    final (today, plan, journey, commitments) = entry.value;
    testWidgets('the app follows the phone language: $lang', (tester) async {
      tester.platformDispatcher.localesTestValue = [Locale(lang)];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await LocalStorage().save(notificationFixture());
      await tester.pumpWidget(
        MainApp(
          notificationService: _Notifications(),
          now: () => DateTime(2026, 10, 14, 12),
        ),
      );
      await tester.pumpAndSettle();

      // Text overflow throws in tests, so each tab rendering cleanly also
      // proves the longer translations fit.
      final directionOf = Directionality.of(
        tester.element(find.byType(NavigationBar)),
      );
      expect(directionOf, lang == 'ar' ? TextDirection.rtl : TextDirection.ltr);
      final nav = find.byType(NavigationBar);
      expect(
        find.descendant(of: nav, matching: find.text(today)),
        findsOneWidget,
      );
      expect(find.text(commitments), findsWidgets);

      await tester.tap(find.descendant(of: nav, matching: find.text(plan)));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: nav, matching: find.text(journey)));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: nav, matching: find.text(today)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('open-settings')));
      await tester.pumpAndSettle();
      expect(
        find.text(lookupAppLocalizations(Locale(lang)).settingsTitle),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  test('an unsupported phone language falls back to English', () {
    final resolved = basicLocaleListResolution(const [
      Locale('ja'),
    ], daylockLocales);
    expect(lookupAppLocalizations(resolved).today, 'Today');
  });

  test('plurals and placeholders format in every language', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final l = lookupAppLocalizations(locale);
      for (final n in [0, 1, 2, 3, 11, 100]) {
        expect(l.routineCount(n), isNotEmpty);
        expect(l.repeatEveryDays(n), isNotEmpty);
        expect(l.completedCommitments(n), isNotEmpty);
        expect(l.selectedAppsCount(n), isNotEmpty);
      }
      expect(l.removeFromDraft('Run'), contains('Run'));
      expect(l.keptOfEligible(2, 5), allOf(contains('2'), contains('5')));
      // Dates and weekday names come from the language too.
      expect(l.weekdayLong(1), isNotEmpty);
      expect(
        l.repeatLabel(RoutineSchedule.onWeekdays({1, 3})),
        contains(l.weekdayShort(1)),
      );
    }
    final fr = lookupAppLocalizations(const Locale('fr'));
    expect(fr.weekdayLong(1), 'lundi');
    expect(fr.repeatEveryDays(3), 'Tous les 3 jours');
    expect(fr.focusDuration(65 * 60000), '1 h 5 min');
  });
}

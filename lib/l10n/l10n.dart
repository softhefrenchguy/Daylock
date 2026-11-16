import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';
export 'labels.dart';

/// English, used when a widget is built outside the app's localizations
/// (isolated widget tests, overlays above the navigator).
final AppLocalizations englishStrings = lookupAppLocalizations(
  const Locale('en'),
);

/// Supported languages with English first: Flutter falls back to the first
/// entry when the phone's language isn't supported.
final List<Locale> daylockLocales = [
  const Locale('en'),
  for (final locale in AppLocalizations.supportedLocales)
    if (locale.languageCode != 'en') locale,
];

var _datesReady = false;

/// Loads date names for every language (synchronous; done once). Needed
/// wherever dates are formatted outside the app's own localizations, such as
/// in isolated widget tests.
void ensureDateFormatting() {
  if (_datesReady) return;
  initializeDateFormatting();
  // Arabic uses Western digits (0-9) everywhere, matching the app's counts.
  DateFormat.useNativeDigitsByDefaultFor('ar', false);
  _datesReady = true;
}

extension DaylockL10n on BuildContext {
  /// The app's text in the phone's language (English when not translated).
  AppLocalizations get l10n {
    ensureDateFormatting();
    return Localizations.of<AppLocalizations>(this, AppLocalizations) ??
        englishStrings;
  }
}

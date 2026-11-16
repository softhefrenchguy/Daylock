# Languages

Daylock is available in English, French, Spanish, German and Arabic. It follows the phone's language, or the language picked for Daylock in Android settings (Android 13+). Any other language falls back to English.

## Where text lives

- **App screens:** `lib/l10n/app_<lang>.arb`. English (`app_en.arb`) is the source. `flutter gen-l10n` (or any build) generates `AppLocalizations`.
- **Lock screen, notifications and the Accessibility description:** `android/app/src/main/res/values[-<lang>]/strings.xml` and `detection_strings.xml`.

## Using text in code

- In widgets, use `context.l10n.someKey`. Outside the app's localizations (isolated widget tests) this falls back to English.
- In `main.dart`'s state, which sits above the app's localizations, use `_l` (it reads through the navigator).
- Inside dialog and sheet builders, use the builder's own context (`dialogContext.l10n`). The outer context may be gone, for example after midnight rollover.
- Translated names for model values (colour themes, outcomes, repeat rules, event times, durations) are in `lib/l10n/labels.dart`. The models keep stable English labels for storage and tests.
- Dates use `intl` with the app's language: `daylockDateLabel`, `daylockWeekday`, `repeatDateLabel` and `achievementDateLabel`. English keeps its existing "Monday 16 November" style.
- Notification wording in `NotificationPolicy` goes through `ReminderTexts`: English by default (unit tests), Android resources at runtime.

## Adding or changing text

1. Add the key to `app_en.arb`, with placeholders and plurals in ICU format.
2. Add the same key to each of `app_fr.arb`, `app_es.arb`, `app_de.arb` and `app_ar.arb`. A missing key shows English.
3. Arabic plurals use `=0`, `=1`, `=2`, `few`, `many` and `other`. Where agreement is awkward, use a "label: {count}" form.

## Right-to-left

Arabic mirrors the layout. Use `EdgeInsetsDirectional` and `AlignmentDirectional` (start/end) rather than left/right. The tour's speech-bubble arrow is the exception, because it follows physical screen positions.

`test/localization_test.dart` opens the app in every language, checks the direction and the tab labels, and fails on text overflow.

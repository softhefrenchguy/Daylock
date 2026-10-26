# Journey Phase 2

Journey makes existing effort visible through Areas and personal Highlights. The main destinations are **Today, Plan, Journey**. Calendar is now **Journey → Daily history**, with a back button returning to Journey.

## Files and architecture

| Files | Changes |
| --- | --- |
| `lib/models/highlight.dart` | Immutable Highlight and HighlightBook, stable IDs, validation, deterministic timeline ordering, serialization, upsert and removal. |
| `lib/services/journey_service.dart` | Pure read-only aggregation of current and historical commitments; per-Area summaries, time ranges and activity buckets. |
| `lib/models/daylock_state.dart`, `lib/services/local_storage.dart` | Highlights in the existing v2 snapshot and additive migration; preservation across rollover. |
| `lib/screens/journey_screen.dart` | Area-first overview, recent Highlights, Past Chapters, Daily history. |
| `lib/screens/area_journey_screen.dart` | Area detail, ranges, activity chart, associated Highlights and read-only commitment links. |
| `lib/screens/highlight_editor.dart` | Lightweight title/date/description editor with an optional Area link. |
| `lib/design/daylock_journey.dart`, `daylock_areas.dart` | Theme-aware Area cards, Highlight tiles and accessible activity visualization; larger Area names for Journey. |
| `lib/main.dart` | Main navigation, secondary routes, Highlight actions, existing save ownership and live view updates. Derived Journey data is cached until a data change or date change. |
| `lib/screens/calendar_screen.dart` | Optional initial selected date for opening a particular recorded day, separate from the actual current date. Existing Calendar functionality remains. |
| `test/journey_data_test.dart`, `test/journey_widget_test.dart` | Aggregation, migration, Highlights, navigation, history, restoration, save recovery and responsive-layout coverage. |
| `test/navigation_helpers.dart` and existing Calendar/Focus/Plan flow tests | Reach Calendar through Journey instead of its former main tab; retain existing assertions and scenarios. |

No new packages, permissions, application IDs, signing changes, or native Android implementation changes are required.

## Navigation and UI

Journey opens with the active Areas, including Life under its current name. Area names and icons lead each card, with a concise all-time count of completed commitments and recorded Focus time when available. Empty Areas have a neutral introduction. The overview adds no percentages, targets, XP or competing progress bars.

Recent Highlights shows the latest three dated entries, with access to the full timeline. Highlights can describe achievements, experiences or any memorable day. Past Chapters shows archived Areas separately and preserves access to their detail pages. Restoring an Area in the existing Settings manager returns it to the active list; its underlying records do not change.

Area detail defaults to **Last 30 days**, with **All time** one tap away. The activity chart switches between completed commitments and recorded Focus; only one metric appears at a time. Tooltips, semantic labels and expandable textual activity details expose exact ranges and values. Recorded commitments retain their outcome labels and link to that date in Calendar. Area-specific Highlights follow the selected date range.

Settings, Routines, Freedom Control and notification entry points stay in their existing locations. Notification taps can still return directly to Today or Plan from any secondary Journey route.

## Aggregation and integrity

Journey reads existing daily snapshots plus today's live plan. Tomorrow and future historical dates are excluded. It never writes derived counts, inferred sessions, or backfilled Area IDs into history.

- A completed commitment means `TaskOutcome.completed`, for Goal or Focus. Excused and incomplete commitments do not increase that count.
- Focus totals sum `accumulatedFocusMilliseconds` **only for Focus tasks**, including actual recorded time on incomplete or excused tasks. Goals never imply hours.
- A running timer's unrecorded elapsed interval is not extrapolated. Its saved time appears when the existing Focus flow pauses or finishes the session. The Area page explains this. Journey never pauses a live timer to calculate a summary.
- Each date contributes one plan. If an immutable historical snapshot already exists for today's date after a backwards clock change, that snapshot takes precedence over the live plan. The same date is never counted twice.
- Within a plan, task position distinguishes records. Identical names do not collapse separate commitments. Calendar copies are not added as another source, and no session duration is summed twice.
- Legacy, missing and unknown commitment Area IDs resolve through Phase 1's permanent default Area. Archived IDs continue to resolve to their original Area. Renaming changes the displayed name, not the relationship.
- Last 30 days means today plus 29 prior **calendar dates**, inclusive. Calendar-date arithmetic avoids daylight-saving elapsed-hour errors. All time includes all available records through today.
- Charts use at most eight chronological buckets covering the selected span. Each bucket sums its actual records; empty buckets indicate no recorded activity, not an inferred missed day. Textual details identify each bucket's exact dates.

The source plans and historical snapshots remain unchanged by opening or filtering Journey. Plan locking and Freedom eligibility use their existing logic.

## Highlights and persistence

Each Highlight contains a 128-bit random stable ID, a required trimmed title, a calendar date, an optional description and an optional Area ID. Dates serialize as `YYYY-MM-DD` without timezone shifting. Titles support up to 120 Unicode code points and descriptions up to 2,000. Date selection can record older experiences; future dates are also accepted if deliberately selected.

The Highlight editor starts without an Area on the overall Journey page. Starting from an Area page preselects that Area, and the link can still be removed. Editing preserves the Highlight's ID. Deletion requires confirmation and affects only that Highlight. Photos are not stored.

Unassigned Highlights remain in the overall timeline and are not silently assigned to Life. Unknown Area references show **Area unavailable**, remain editable and stay in the overall timeline. Archived references remain associated with their Area and appear in its Past Chapter. New Area choices list active Areas; an existing archived link can be retained, and a Highlight created from a Past Chapter can reference that chapter.

Highlights are stored in a new `highlights` list inside the existing `daylock.state.v2` JSON. Older v2 saves receive an empty list once; all existing fields and historical records remain intact. Legacy v1 saves continue through the existing migration path. Repeated loads do not create duplicate records. Invalid Highlight collections fail through the existing load-error path without overwriting the stored save.

All edits use the existing snapshot save queue, error message and Retry behaviour. A failed Highlight save leaves the previous disk state intact; Retry saves the current state once. There is no new database, sync system or independent source of planner truth.

## Validation

Executed on 2026-10-26 with Flutter 3.47.6 / Dart 3.13.5:

| Check | Result |
| --- | --- |
| `flutter analyze` | Passed, no issues. |
| `flutter test --reporter expanded` | Passed: 570 tests, including 23 new Journey tests. |
| `android/gradlew.bat :app:testDebugUnitTest --rerun --console=plain` | Passed: 105 tests, zero failures/errors; the test task was explicitly rerun. |
| `flutter build apk --debug --build-name=0.1.0-alpha.5 --build-number=5` | Passed; `build/app/outputs/flutter-apk/app-debug.apk`. |
| `flutter build web --release --base-href /Daylock/ --build-name=0.1.0-alpha.5 --build-number=5` | Passed; `build/web`, including a successful Wasm dry run. |
| APK signature and metadata | Verified against the previous Daylock signing certificate; application ID remains `com.example.daylock`, version code 5. |
| `git diff --check` | Passed. |

Logs are in `build/journey-flutter-tests.log`, `build/journey-native-tests.log`, `build/journey-android-build.log` and `build/journey-web-build.log`. The initial regression run found tests still navigating to the removed Calendar tab; their navigation helpers now use Journey → Daily history while retaining the original assertions. A keyboard-layout test also needed to wait for text-field scrolling before attempting the next tap. The final suite has no unresolved failures.

Gradle reports native-access and future Gradle 10 deprecation warnings. The web build reports an unavailable Cupertino font family; Journey uses the successfully bundled MaterialIcons font. These warnings did not fail the builds. The app has not been installed on a physical device during this task, and iOS/macOS builds were not run on this Windows PC.

Test coverage includes:

- Current/history de-duplication, same-name commitments, future exclusion and immutable history.
- Completed versus incomplete/excused outcomes, Goals versus Focus, exact milliseconds and sub-minute display.
- Inclusive 30-day boundaries, all-time aggregation and conservation of bucket totals.
- Default Area fallback, renamed defaults, archived associations and restoration.
- Highlight creation, editing, date changes, deletion/cancellation, optional/unknown links, restart and rollover persistence.
- Additive migration and malformed saves remaining untouched.
- Save failure and successful retry without modifying planner state.
- Main navigation, Calendar access, selected historical dates and locked-plan restrictions.
- 320-pixel layouts at 100%, 200% and 300% text in light/dark themes, plus the Highlight editor with a keyboard inset.
- Existing Focus, Freedom, notification, Calendar-provider and native Android regression suites.

Phone-sized overview and detail previews were rendered from the actual widgets using fixture data for visual inspection. They are not screenshots of a physical device or evidence of a real Android upgrade.

## Physical-device checks still needed

1. Update the existing installation without uninstalling or clearing data. Confirm plans, Areas, routines, calendar connections, history and locks survive.
2. Open Journey with your real history. Check renamed Life, custom Areas, counts and Focus totals against selected Calendar days.
3. Start a Focus session, navigate to Journey, then pause/finish it in Today. Confirm the saved time appears once and navigation does not stop the timer.
4. Create a personal Highlight without an Area and another with an Area. Edit the date and description, restart, and test deletion/cancellation.
5. Archive an Area used in history and Highlights. Open its Past Chapter, then restore it through Settings and verify its return to active Areas.
6. Open Daily history, navigate months, select dates, edit local events, sync each configured calendar provider and check cached offline events.
7. Test Android back navigation, notification taps into Today/Plan, keyboard-open sheets, large system fonts and TalkBack labels for the activity chart.
8. Cross midnight with Journey or Daily history open. Confirm the new day and archived previous day update without duplicate records.
9. Recheck Freedom eligibility and Instagram blocking on the phone; automated regression tests do not replace physical-device verification of Android behaviour.

There is no Year in Review, AI summary, photo storage, gamification or new daily tracking requirement. Cross-device sync remains outside the existing local-storage architecture.

The requested GitHub phone-test package uses `flutter build apk --release --build-name=0.1.0-alpha.5 --build-number=5` and the existing signing configuration. It is distributed as a draft release pending physical-device verification. Uploading the source does not deploy the live web site.

# Journey homepage redesign

Journey now opens with a compact effort summary, a two-column Area grid and one featured Highlight. The four-Area fixture fits the header, summary, tiles, Highlight and history links in a 390 x 844 logical-pixel phone viewport with system insets and the existing bottom navigation.

## Files changed

| File | Change |
| --- | --- |
| `lib/screens/journey_screen.dart` | Compact summary and homepage composition; small history and management entry points. |
| `lib/design/journey_area_grid.dart` | Responsive Area tiles shared by Journey and Past Chapters. |
| `lib/design/journey_featured_highlight.dart` | Swipeable featured Highlight, explicit navigation, selection and accessibility. |
| `lib/screens/past_chapters_screen.dart` | Archived Areas moved into a dedicated secondary screen. |
| `lib/main.dart` | Connects Past Chapters, Area management and direct Highlight editing to existing flows. |
| `lib/design/daylock_journey.dart` | Removes the unused full-width Area card; existing Highlight lists and charts remain. |
| `test/journey_redesign_test.dart` | 24 widget tests covering the new presentation and interactions. |
| `test/journey_widget_test.dart` | Updates existing Journey expectations and archived-Area navigation. |
| `test/navigation_helpers.dart` | Targets vertical Journey scrolling separately from the horizontal carousel. |
| `docs/journey-ui-redesign.md` | This implementation and validation report. |

## Visual and interaction changes

The effort summary uses existing Journey records for completed commitments and actual recorded Focus time, plus the existing Highlight count. Archived effort remains part of the total. Goals never contribute inferred Focus hours.

Area tiles preserve configured names, icons and colours, including a renamed default Area. Each shows one indicator: recorded Focus time, otherwise completed commitments. Areas with recorded but unfinished commitments show `0 completed`; an Area with no commitment records can show its latest Highlight, or the quiet `Open space` state. Tapping opens the existing Area detail screen. Tile surfaces and borders blend the configured Area colour into the current theme; text uses the existing colour scheme.

Highlights show a prominent title, date, optional Area and a short description when space permits. Add, All and Edit are visible controls. The card opens the existing detail view; Edit operates on the selected Highlight using the existing editor and save flow. There are no photos or new persistence fields.

Daily history and Past Chapters are compact links below Highlights. Area management is available from the header and from Past Chapters. Archived Areas retain their existing detail, history and restoration flows. Today, Plan and Journey bottom navigation is unchanged.

## Responsive layout

- Content is centred with a maximum width of 720 logical pixels. At ordinary phone text sizes, the Area grid has two columns with a 10-pixel gap and near-square tiles.
- Row heights grow with content. Above 150% text scale on content narrower than 560 pixels, tiles use one column and names/indicators can wrap fully.
- The summary and secondary links wrap. The Highlight heading and controls can occupy separate lines. Carousel height follows scaled text metrics; large text gets more title and metadata lines, without a description preview.
- Smaller screens, many Areas and large system fonts scroll vertically. Fitting everything in one viewport is a four-Area, ordinary-font target, not a guarantee for every configuration.
- Normal-size long tile text and Highlight previews may truncate visually; full labels are exposed to accessibility and complete content remains available in the existing detail screens.

## Highlight navigation

Highlights retain the existing newest-first order. Swipe horizontally or use Previous/Next buttons; a `1 / N` indicator announces position through a semantic live region. Navigation stops at the ends and there is no automatic rotation.

Selection follows the Highlight's stable ID through saves, date reordering and routine rebuilds. A newly added Highlight becomes selected even when its date places it later in the list. Removing the selected item chooses an adjacent valid position; removing every item shows the compact empty state. The carousel handles returning from an empty list. Reduced-motion settings remove the arrow navigation animation. Add and All remain available in the empty state.

## Preserved behaviour

This change is confined to UI and navigation. Existing Area and Highlight models, serialization, storage, assignments, archiving/restoration, Journey aggregation, history, locked commitments, Focus, Freedom, Instagram blocking, notifications and routines are unchanged. There are no application-ID, signing, permission or native-code changes.

## Tests and build results

Executed on 2026-10-26 with Flutter 3.47.6 / Dart 3.13.5:

| Check | Result |
| --- | --- |
| `flutter analyze` | Passed, no issues. |
| `flutter test --reporter expanded` | Passed: 594 tests, including 24 new redesign widget tests. |
| `android/gradlew.bat :app:testDebugUnitTest --rerun --console=plain` | Passed: 105 tests, zero failures/errors/skips; test execution was explicitly rerun. |
| `flutter build apk --debug --build-name=0.1.0-alpha.6 --build-number=6` | Passed; output `build/app/outputs/flutter-apk/app-debug.apk`. |
| `flutter build web --release --base-href /Daylock/ --build-name=0.1.0-alpha.6 --build-number=6` | Passed, including Wasm dry run; output `build/web`. |
| APK verification | Signature verified, certificate SHA-256 `4c8b183e42c2d5e61003cee98d3473ed2b7e0cf54cf7b58355c40fc89e3c5d4c` matches the previous build. Application ID `com.example.daylock`, version code 6. |
| `git diff --check` | Passed. |

New widget coverage includes two-column geometry and viewport fit; actual effort totals including archived records; empty, unfinished and Highlight-only Areas; tile navigation; swiping and arrow navigation; selection across reordering/addition/deletion; creation and direct editing; history and management access; all six palettes in both appearances; 320 x 640 layouts at 100%, 150%, 200% and 300% text scale; many Areas and long names; semantic labels and reduced motion. The existing persistence, Focus, Freedom, notifications and native Android regression suites also passed.

Logs are `build/journey-redesign-flutter-tests.log`, `build/journey-redesign-native-tests.log`, `build/journey-redesign-android-build.log` and `build/journey-redesign-web-build.log`. Gradle's existing native-access/deprecation warnings and the web build's existing unavailable Cupertino font-family warning remain non-fatal. The new UI uses the successfully bundled MaterialIcons font. No iOS/macOS build or physical-device test was run on this Windows PC.

The GitHub handoff includes the source changes and an Android test APK in a draft release. Public release publication remains pending physical-device verification. Building the web output does not deploy the live website.

## Physical-device checklist

Automated layout and semantics tests do not establish real-device appearance, TalkBack behaviour or upgrade reliability. No physical-device verification was performed for this redesign.

1. Update the existing installation without uninstalling or clearing data. Confirm saved commitments, Areas, Highlights, history and settings remain present.
2. Open Journey with real data. Check the four-Area layout, a renamed default Area, an empty Area and an Area with Highlights but no commitment records. Compare totals with existing Area detail/history views.
3. Swipe Highlights, use both arrow buttons, open details and directly edit the selected item. Change its date, add an older Highlight and delete selected/last items; check selection, then restart to verify saved content.
4. Follow All Highlights, Daily history, Past Chapters and Manage Areas. Open an archived Area and restore it. Verify Android Back returns to the expected screen.
5. Check all six palettes in light and dark mode, long names, many Areas, small-screen/landscape layouts and the largest Android font/display settings. Check editor sheets with the keyboard open.
6. With TalkBack, navigate tiles, Highlight actions and Previous/Next controls; verify full labels, position announcements, focus order and access to all content. Repeat with reduced motion enabled and, for web, keyboard navigation and browser zoom.
7. Leave a Focus session running while opening Journey, and cross a day boundary with Journey open. Confirm totals update through the existing save/day-change flows. Recheck notification navigation, Freedom and Instagram blocking on the phone.

The local widget preview at `build/journey-redesign-preview.png` uses fixture data and desktop fonts; it is not a physical-device screenshot. Publication remains pending physical testing.

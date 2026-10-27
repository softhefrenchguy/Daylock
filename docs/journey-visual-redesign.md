# Journey visual redesign

The supplied **Journey Dashboard in Purple Dark Mode** mockup is the visual reference. Journey now uses the same hierarchy: header and subtitle, an icon-led summary card, tinted Area grid, illustrated Highlight, compact history cards, and the existing bottom navigation. Layout adapts to real content and screen size rather than reproducing the mockup's sample data.

[Dark preview](images/journey-visual-dark.png) · [Light preview](images/journey-visual-light.png) · [History cards after scrolling](images/journey-visual-history.png)

These are renders of the actual Flutter widgets with fixture data and desktop fonts at a 390 x 844 logical-pixel viewport. They are not screenshots from a physical Android device.

## Files changed

| File | Responsibility |
| --- | --- |
| `lib/screens/journey_screen.dart` | Header/subtitle, theme-derived background and dashboard composition. |
| `lib/design/journey_surface.dart` | Shared gradient surface, thin tinted border, restrained glow and Material press feedback. |
| `lib/design/journey_dashboard_cards.dart` | Three-metric summary and Daily history/Past Chapters cards. |
| `lib/design/journey_area_grid.dart` | Compact icon/name rows, effort or latest Highlight, and activity strip placement. |
| `lib/design/journey_activity_strip.dart` | Small labelled charts drawn from the existing Journey service's real buckets. |
| `lib/design/journey_featured_highlight.dart` | Illustrated featured card with preserved swipe, pagination, Add, Edit and All actions. |
| `lib/design/highlight_illustration.dart` | Reusable local layered artwork and static icon assets. |
| `lib/models/highlight_illustration.dart` | Stable icon IDs, labels and deterministic offline suggestion rules. |
| `lib/models/highlight.dart` | Optional backward-compatible illustration identifier. |
| `lib/screens/highlight_editor.dart` | Automatic/explicit illustration picker using the existing save flow. |
| `test/journey_visual_test.dart` | New data, persistence, chart, artwork and picker tests. |
| `test/journey_redesign_test.dart` | Updated summary presentation assertions; retained layout/navigation/theme checks. |
| `test/journey_widget_test.dart` | Navigation helper selects vertical scrolling now that the page includes a carousel. |
| `docs/journey-visual-redesign.md` and preview images | This report and fixture-based visual examples. |

## Visual changes

The progress summary shows completed commitments, recorded Focus time and saved Highlights, with distinct icons and prominent values. It uses the existing `JourneySummary`; no Goal contributes inferred Focus time. The background, borders and glows derive from the active theme, while Area cards retain the user's configured colours and icons. Summary icon accents are derived from the palette hue, retaining neutral accents in Mono.

Areas show their existing all-time effort indicator or latest Highlight when no commitment records exist. Empty Areas remain quiet and have no fake bars. Active and archived Areas use the same tile component; opening a tile still uses the existing detail screen.

Mini charts use `JourneyData.activity(areaId, last30Days: true)`. They display chronological buckets of actual recorded Focus milliseconds if that window contains Focus, otherwise completed commitment counts. A caption identifies the 30-day window and metric. Each chart scales to its own maximum; it is not a shared scale for comparing Areas. Zero buckets have no visible bar, and there is no chart when all values are zero. Positive bars have a one-pixel visibility floor. The accessible Area label includes the dates and values. No historical record or aggregation algorithm was changed.

Daily history and Past Chapters are small gradient cards with descriptive subtitles. Their routes and behaviour are unchanged. Area management is available through the header and View all.

## Illustration architecture and selection

`HighlightIllustration` is a reusable Flutter widget built from an orbit, radial glow, two rotated keepsake layers, a Material icon, accent lines and sparkles. Colours derive from the associated Area or the current theme. It uses no raster assets, generated images, remote services, photo storage or new package dependency. Artwork is decorative, ignored by hit testing and excluded from the accessibility tree; title and metadata remain separate and readable.

Selection priority is:

1. A supported explicit `illustrationIcon` stored on the Highlight.
2. A title suggestion using case-insensitive whole English words.
3. The associated Area icon, including an archived Area that still exists.
4. The generic celebration illustration.

The small ordered mapping checks driving/licence/license/car; certification/certificate/exam/qualification/graduation; cooking/cook/cooked/recipe/meal/baking; travel/trip/flight/holiday/vacation; and fitness/gym/strength/workout/marathon. The first matching category wins; substrings such as `carpet` do not match `car`. This is deliberately not language classification. Unmatched or non-English titles fall back to the Area or celebration.

The editor offers Automatic plus 13 explicit choices. Explicit choices survive title/date/description edits, storage reloads and day rollover. Selecting Automatic removes the explicit field and allows the predictable title/Area suggestion to update. Existing Highlights have a null selection and need no migration or recreation. Unknown future string IDs are retained on save but render through the fallback; malformed non-string optional artwork metadata is ignored without rejecting the otherwise valid Highlight. Other saved fields remain untouched and the state schema stays at version 2.

Carousel selection still follows Highlight ID across edits, reordered dates and list changes. Adding selects the new item; deletion selects a remaining valid item. Swipe, Previous/Next, position announcements and direct editing remain available. Artwork has a one-time 260 ms scale entrance; reduced motion removes it and the existing arrow transition animation. There are no looping animations.

## Responsive decisions

- At ordinary phone sizes the layout keeps two Area columns with compact spacing and content-driven row heights. Above 150% text scale on narrow layouts it switches to one column.
- The summary becomes vertical at larger text sizes. Labels have their own full-width space within each metric so long labels do not squeeze beside icons.
- Section headings/actions wrap. History cards stack on narrow screens or at larger text sizes. Existing SafeArea and bottom navigation remain intact.
- Highlight artwork stays beside text at ordinary sizes; at larger text sizes it moves below the text. Page height follows scaled text metrics. Descriptions are a short optional preview; the complete title/description remains available in the existing detail view.
- Long previews can use ellipses; they never overlap artwork. Many Areas, large fonts and smaller devices scroll naturally. The four-Area 390 x 844 widget fixture checks that the featured card is visible before scrolling; secondary navigation can require a short scroll.

## Validation and delivery

Executed on 2026-10-27 with Flutter 3.47.6 / Dart 3.13.5:

| Check | Actual result |
| --- | --- |
| `flutter analyze` | Passed, no issues. |
| `flutter test --reporter expanded` | Passed: 610 tests, including 16 new visual-redesign tests. |
| `android/gradlew.bat :app:testDebugUnitTest --rerun --console=plain` | Passed: 105 tests, zero failures/errors/skips. |
| `flutter build apk --debug --build-name=0.1.0-alpha.7 --build-number=7` | Passed. |
| `flutter build apk --release --build-name=0.1.0-alpha.7 --build-number=7` | Passed; `build/app/outputs/flutter-apk/app-release.apk`. |
| `flutter build web --release --base-href /Daylock/ --build-name=0.1.0-alpha.7 --build-number=7` | Passed, including Wasm dry run; `build/web`. |
| APK signature/metadata | Verified existing certificate SHA-256 `4c8b183e42c2d5e61003cee98d3473ed2b7e0cf54cf7b58355c40fc89e3c5d4c`, unchanged application ID `com.example.daylock`, version code 7. |
| Widget-render previews and `git diff --check` | Passed. |

The new tests cover deterministic icon priority and whole-word matching; unassigned/unknown/linked Areas; optional-field compatibility; explicit icon round trips and title changes; Automatic reset; unchanged history and commitments; real chart values and zero buckets; exclusion of old activity from recent charts; long text and the expanded picker at 320 pixels and 100%/300% text. Existing tests also exercise all six palettes in both appearances, navigation, swiping/editing, scaled layouts, reduced motion, persistence, native blocking, Freedom, notifications and routines.

During implementation, tests caught a large-text section-heading overflow and a viewport-fit regression; both were corrected. Navigation helpers were updated to distinguish the vertical page from the horizontal carousel. The final full suite has no unresolved failures. Existing Gradle native-access/deprecation warnings and the web build's unavailable Cupertino font-family warning remain non-fatal; this UI uses bundled MaterialIcons.

Logs are in `build/journey-visual-flutter-tests.log`, `build/journey-visual-native-tests.log`, `build/journey-visual-debug-build.log`, `build/journey-visual-release-build.log` and `build/journey-visual-web-build.log`. Release APK SHA-256: `44f6a6bb17e8e0be3216ce2abbd3eba765ebf5b43a51823dfc0015db36b2ed0b`.

Source and the test APK are delivered through GitHub, with the APK in a draft release pending phone testing. The web build does not deploy the live website. No permissions, signing configuration, application ID, Today/Plan workflows, Freedom rules, Instagram blocker, notifications, routines, history calculations or archiving logic were changed.

## Remaining device checks

No physical-device verification has been performed for this change. Before publishing a public release:

1. Update the existing app without uninstalling or clearing data. Confirm commitments, Areas, previous Highlights, history and settings remain present.
2. Compare the dashboard with the supplied mockup using real data, all six palettes and both appearances. Check long Focus totals, long Area names, large system fonts, landscape and small screens.
3. Compare recent chart values with Area history. Confirm empty and Highlight-only Areas show no bars and old effort outside the recent window stays in totals without creating recent activity.
4. Create Highlights from each suggested category, without an Area and with an Area. Select an explicit icon, change the title, restart, then return it to Automatic. Check archived/missing Area references.
5. Swipe and use arrow controls; edit/add/delete the selected item. Test long text and the picker with the keyboard open, TalkBack and reduced motion.
6. Check Daily history, Past Chapters, Area restoration and Android Back navigation. Recheck existing Focus, Freedom, Instagram blocking and notification navigation on the device.

Automated checks do not establish real-device GPU performance, font rendering, TalkBack focus behaviour or upgrade reliability. Web builds are verified separately from browser interaction and live deployment. Test APKs remain in draft releases until physical verification is complete.

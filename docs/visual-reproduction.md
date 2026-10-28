# Three-screen visual reproduction

The final three-screen image supplied on October 27 is the visual reference. Its completed Today, empty Plan and Journey states supersede the earlier two-screen image. The implementation was inspected against **rendered Android screenshots**, not just compilation results.

## Implementation

- `lib/design/daylock_task_row.dart`: compact completed rows, Area icon, recorded time, contextual menu, Area-derived tint and checkbox; incomplete rows retain independent Start/Resume/Pause controls. Completion still uses the existing callback and task model.
- `lib/design/daily_progress_card.dart`: larger, correctly filled progress ring and stronger summary surface using the existing eligible count and live recorded-time total.
- `lib/design/daylock_illustrations.dart`: bundled Flutter shapes, gradients, orbit, sparkle accents, calendar/pencil and lock artwork. Decorative artwork is excluded from accessibility semantics. No asset download or dependency is needed.
- `lib/design/daylock_freedom_status.dart`: permanent featured panel, responsive artwork and requirements using the existing eligibility result. Disabled, locked, waiting and earned states remain distinct.
- `lib/screens/plan_screen.dart`: illustrated empty state, aligned compact schedule and routine cards, Area-coloured populated rows, gradient Add action and unchanged sticky commit validation. The empty panel grows naturally with text scaling.
- `lib/design/daylock_widgets.dart`, `daylock_palette.dart`, `journey_surface.dart`, `daylock_routine_suggestions.dart`: reusable action gradient, deeper Violet background and brighter lavender, stronger shared borders/tints and routine icon. Other selectable palettes remain supported.
- `lib/screens/today_screen.dart`: tighter heading spacing and vertical centring when the content is shorter than the viewport; longer content scrolls. `lib/screens/journey_screen.dart` and `lib/design/journey_area_grid.dart`: stronger Area borders and 8 fewer pixels of section spacing to keep history links clear of navigation. Journey structure, carousel and illustration remain intact.

No model, persistence, stopwatch service, eligibility service, notification, Android manifest, application ID or signing changes. Existing Area assignments and archived Area records are resolved, never rewritten. Changing an Area colour changes its cards; task names never determine colours.

## Android visual verification

Captured using an Android 15 / API 35 emulator, 1080 × 2337 pixels at 443 dpi (approximately 390 × 844 logical pixels), default text size, system status and gesture-navigation insets. The emulator initially exited with its Vulkan renderer; subsequent captures used the software renderer with Vulkan/Impeller disabled **for this emulator run only**. Production rendering settings are unchanged.

The screenshot entry point, `tool/visual_fixture.dart`, imports the real screen widgets with explicit in-memory sample data. It never reads or writes user storage and is not imported by the production entry point. These are actual Android renders of the screens, not evidence of live timer, notification or blocker integration. The distributed APK is built separately from `lib/main.dart`.

| State | Actual Android capture | Inspection |
| --- | --- | --- |
| Today, all complete | [Completed Today](images/visual-reproduction/today-completed-android.png) | Full ring, three compact coloured rows, permanent illustrated Freedom card above navigation |
| Today, active stopwatch | [Active Today](images/visual-reproduction/today-running-android.png) | Recorded time and Pause remain visible; the longer overview scrolls to the bottom of Freedom |
| Plan, empty | [Empty Plan](images/visual-reproduction/plan-empty-android.png) | Calendar/pencil artwork, count, Add button, full panel above disabled sticky commit action |
| Plan, populated | [Populated Plan](images/visual-reproduction/plan-populated-android.png) | Actual Area colours and editable Area/menu actions; more rows scroll above the enabled commit button |
| Journey | [Journey dashboard](images/visual-reproduction/journey-android.png) | Four coloured tiles, existing illustrated Highlight, carousel and both history links above navigation |

The first Android pass exposed an oversized empty Plan panel and the bottom edge of Journey's history links meeting the navigation bar. The panel artwork/padding and Journey section gaps were reduced, captures repeated, and the corrected screenshots inspected. The completed Today overview was centred within spare viewport space; the Violet surfaces were made less grey and the Freedom gradient more saturated. A production empty-state smoke check also exposed long Freedom copy crossing the decorative lock: the header artwork now occupies its own layout column, with requirements below it, preventing that overlap.

Remaining differences: this is not a pixel-identical bitmap recreation. Artwork contours, sparkle positions, ring shading, platform font metrics and status-bar icons differ. Area colours reflect saved values rather than forcing the reference's green Pega colour. Journey distributes recorded time to the actual assigned Areas, so its fixture tile totals differ from the image. The existing descriptive Instagram configuration footer is retained. Schedule remains an informational section without a misleading navigation chevron; routine suggestions retain their actual expansion control. Incomplete timers retain explicit accessible labels and no obsolete time targets or automatic completion were introduced. The physical phone's exact viewport and font settings have not been verified.

## Reproduction and regression checks

`test/visual_reproduction_test.dart` renders all five states, verifies a true 100% ring, compact completed rows, Area recolouring without task mutation, and completed Today/empty Plan/Journey geometry with Android system insets. Optional widget-only previews are generated with:

```powershell
flutter test test/visual_reproduction_test.dart --dart-define=CAPTURE_VISUALS=true
```

For actual screenshots, use a dedicated emulator and `flutter run -d emulator-5554 -t tool/visual_fixture.dart --enable-software-rendering --no-enable-impeller`. The fixture starts at completed Today; tapping Today again selects active Today. Plan selects empty Plan and tapping Plan again selects populated Plan. Journey selects the dashboard. Capture using `adb shell screencap -p /sdcard/daylock-visual.png` and `adb pull`. The normal application entry point remains `lib/main.dart`.

Flutter analysis passed without issues. The full Flutter suite passed **671 tests**, including layout, accessibility text sizes, palette switching, timer flows, Freedom rules, persistence and Journey regressions. The Android debug build and a fresh run of **104 native Kotlin/JVM tests** passed. The production release APK is built from `lib/main.dart`; its application ID and signing certificate were verified unchanged.

Additional Android scroll checks confirmed the full [running Freedom card](images/visual-reproduction/today-running-scrolled-android.png) and [last populated Plan row](images/visual-reproduction/plan-populated-scrolled-android.png) remain reachable above fixed navigation and commit controls.

## Physical-device checklist before publishing

- Install the test APK over the current app; confirm commitments, Area assignments/colours, archived Areas, routines, history and Highlights remain intact.
- Compare completed Today, active/paused Today, empty/populated/committed Plan and Journey on the actual phone. Check small screens, long names, larger text, light mode and other palettes.
- Start, pause and resume timers; start a second timer; complete a running task; background and restart the app. Confirm recorded time and manual completion remain independent.
- Verify Freedom disabled, locked, waiting and earned states, the three requirements, and existing Instagram blocking. Check notification behaviour on the phone.
- Add/edit/remove a draft commitment, change its Area, accept a routine suggestion and review scheduled events. Check the editor with the keyboard open and committed-plan safeguards.
- Change an Area colour, check Today/Plan/Journey; open Highlights, carousel, Daily history and Past Chapters.

The APK stays in a draft GitHub release until physical-device verification is complete.

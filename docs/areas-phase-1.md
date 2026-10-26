# Journey Phase 1: Areas

Areas group commitments without changing completion, Focus, Freedom, notifications, or Instagram blocking. Manage them in **Today → Settings → Manage Areas**. Choose an Area in the existing commitment editor, or tap the Area beneath a commitment in an unlocked Plan.

## Architecture and changed files

| Files | Responsibility |
| --- | --- |
| `lib/models/area.dart` | Immutable Area and AreaBook; default identity, validation, ID resolution, archive/restore. |
| `lib/models/task.dart`, `plan_history.dart`, `routine.dart` | Nullable `areaId` on live commitments, immutable historical snapshots, and reusable routine steps. |
| `lib/models/daylock_state.dart`, `lib/services/local_storage.dart` | Areas in the existing atomic v2 saved state; additive migration and rollover preservation. |
| `lib/services/routine_service.dart` | Resolve an accepted step's Area against active Areas when creating its independent commitment. |
| `lib/main.dart` | Own and save Areas through the established save queue; enforce current-plan identity and locked-plan guards before assignment changes. |
| `lib/screens/areas_screen.dart`, `settings_screen.dart` | Secondary management screen; create, rename, customize, archive and restore. |
| `lib/design/daylock_areas.dart` | Shared icon/colour choices, accessible text labels, compact expandable selector and read-only badge. |
| `lib/screens/commitment_editor.dart`, `plan_screen.dart` | Optional selection during creation; Area-only editing in unlocked Plan. Rollover closes selection sheets and rejects retained callbacks. |
| `lib/screens/routine_editor.dart`, `routines_screen.dart`, `lib/design/daylock_routine_suggestions.dart` | Edit remembered assignments per step and show the Area a new suggestion will use. |
| `lib/screens/calendar_screen.dart`, `lib/design/daylock_calendar_details.dart` | Small read-only Area label on existing commitment details, including archived Areas. Existing navigation/layout stays intact. |
| `test/areas_test.dart`, `test/areas_widget_test.dart` | Model, migration, persistence, routine, Freedom, interaction, rollover and accessibility regression coverage. |

The app-icon assets are a separate change included in the Areas test build. No native Android implementation, signing configuration, app ID, permissions, or notification scheduling logic was changed for Areas.

## Identity and persistence

Each Area stores `id`, `name`, `icon`, opaque ARGB `colour`, UTC `createdAt`, `isArchived`, and `isDefault`. Custom IDs use 128 random bits. The permanent default has reserved ID `daylock.area.life` and starts with the name **Life**. The default flag must agree with that ID. Names never serve as relationships.

AreaBook requires exactly one default and unique IDs. Renaming, changing appearance, and archiving preserve IDs and creation times. There is no hard-delete operation. Attempts to archive the default, construct a collection without it, or duplicate it fail validation.

The existing `daylock.state.v2` SharedPreferences JSON gains an `areas` list. New Tasks and RoutineSteps default to the reserved ID. Relationships are stored as `areaId` alongside existing fields. MainApp saves Areas, plans, routine decisions and history through its existing ordered snapshot-save path.

An Area edit changes only `Task.areaId` on the existing Task object. It does not recreate the commitment, restart a timer, alter an outcome, or remove accumulated Focus. Both the UI and MainApp guard against editing a committed or superseded plan.

## Existing data and fallback

Opening a v2 save without `areas` adds Life once and persists it. Subsequent loads retain the original default, including its name, appearance and timestamp. The v1 migration also creates Life while retaining the existing v1 backup behaviour.

Absent Area IDs stay absent in old commitments, historical snapshots and routine definitions. They resolve to the current default at read time; there is no history backfill. Blank/non-string references safely become absent. Unknown string IDs remain stored but resolve to the default, preserving the possibility of resolving that ID later. Unknown icon identifiers display the Life icon safely.

Malformed Area collections fail through the established storage-load error path instead of resetting or overwriting user data. A regression test verifies the original stored JSON remains intact. Existing outcome migrations still apply as before.

Historical references resolve against the current Area collection: a rename updates the displayed Area name without rewriting the commitment. Archived Areas remain resolvable and appear with an “archived” label. The default can be renamed freely, so legacy records follow its new name.

## Routines and archive behaviour

Each reusable RoutineStep owns its assignment. Editing a step in Settings → Routines changes future suggestions. Acceptance copies that assignment into a detached Task using the existing routine revision, date and decision guards. Editing the accepted Task in Plan changes only that instance. Skip, dismiss, ordering, and cycle progress retain their existing behaviour.

Only active Areas appear in selection lists for new assignments. Archiving does not move existing draft, locked, or historical commitments. An existing routine step can retain an archived reference while being edited; the selector shows its current archived label, but offers only active replacements. New acceptances from that step use the default while the Area is archived. Restoring the Area restores future inheritance automatically. Suggestions display the Area that acceptance will actually use.

## Validation

Executed on 2026-10-26 with Flutter 3.47.6 / Dart 3.13.5:

| Check | Result |
| --- | --- |
| `flutter analyze` | Passed, no issues. |
| `flutter test --reporter expanded` | Passed: 547 tests, including 21 new Areas tests. |
| `android/gradlew.bat :app:testDebugUnitTest --console=plain` | Passed: 105 tests, zero failures/errors. |
| `flutter build apk --debug` | Passed; `build/app/outputs/flutter-apk/app-debug.apk`. |
| `flutter build web --release --base-href /Daylock/` | Passed; `build/web`, with successful Wasm dry run. |
| `git diff --check` | Passed. |

Logs are in `build/areas-flutter-tests.log`, `build/areas-native-tests.log`, `build/areas-android-build.log`, and `build/areas-web-build.log`. An initial accessibility test exposed excessive wrapping in the selector at 300% text size; the selector now stacks its label at large sizes and the regression test passes. No unresolved test failures remain. Gradle reported native-access and future Gradle 10 deprecation warnings. The web build reported an unavailable Cupertino font family; the new Area icons use the successfully bundled MaterialIcons font. These messages did not fail either build.

Automated coverage includes default creation/restart/identity, CRUD through Settings, archive/restore, legacy-data preservation, invalid references, Goal and Focus selection, detached routine inheritance, execution-state preservation, historical labels, stale callback rejection after commit and rollover, unchanged Freedom eligibility, and 320-pixel layouts at text scales 1, 2 and 3. Existing Flutter suites exercise notifications, Focus, routines, calendar, persistence and Freedom; existing Android unit tests cover native notification and Instagram behaviour.

## Device checks and limitations

- Upgrade an existing installation without clearing data. Confirm commitments, recorded Focus, routines, saved calendar connections and history remain available.
- In Settings, rename Life and customize its icon/colour. Restart the app and confirm there is still exactly one default.
- Create an Area, select it for a Goal and a Focus commitment, then change the Area before committing. Confirm committing disables assignment edits.
- Assign an Area to a routine step, accept it, and change the accepted instance. Verify the following suggestion retains the routine's assignment.
- Archive an Area used by a routine and historical commitment. Check that history retains its label, new suggestions use the default, and restoration resumes inheritance.
- Check the sheets with the Android keyboard open, large system font sizes and TalkBack. Colour is supplemented by icon and name; selection has a check mark.
- Cross midnight with an Area picker open; the old picker should close and the new day's plans should remain correct.

Physical-device, TalkBack and real upgrade checks remain manual; widget tests do not prove those device behaviours. Areas use the existing local storage and do not introduce cross-device sync. Phase 1 offers eight icons, six colour choices, and names up to 60 Unicode code points. No Journey tab, statistics, XP or automatic classification is included. No decision requires confirmation to use this implementation.

For the requested GitHub test download, the Android package is built with `flutter build apk --release --build-name=0.1.0-alpha.4 --build-number=4`, using the existing signing configuration. It is distributed as a draft release pending physical-device verification. Source upload does not deploy the live web site.

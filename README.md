# Daylock

Daylock is a Flutter productivity app built primarily for Android. Plan tomorrow's
commitments, lock that plan, and execute today's goals and Focus sessions. Fresh
installations start with empty plans. The Bold Discipline design uses strong
typography, restrained colour and six coordinated light/dark palettes.

## Features

- **Today:** Goal completion, timestamp-based Focus timers with minimum durations,
  and Excused outcomes with written reasons. Excuses are excluded from completion
  percentages; empty or all-excused days remain neutral.
- **Plan:** editable tomorrow drafts, Goal/Focus validation, scheduled events,
  routine suggestions and a confirmed Commit Tomorrow action that locks the plan.
- **Daily plans and history:** local-date rollover, immutable historical snapshots,
  recorded Focus time and a monthly commitment heatmap.
- **Calendar:** local event creation/editing/deletion plus read-only Google Calendar
  and Microsoft personal/work/school calendars, multiple accounts, visibility
  controls, recurring-event instances, meeting links and offline caches.
- **Routines:** ordered repeating Goal/Focus suggestions with Accept, Skip and
  Dismiss. Suggestions never create or commit tasks automatically.
- **Appearance:** Violet, Ocean, Forest, Ember, Rose and Mono; Dark, Light or System.
  New users default to Dark/Violet.
- **Freedom:** optional local Freedom Time plus eligible commitments completed and
  tomorrow committed. Zero eligible commitments do not automatically earn Freedom.
- **Optional Instagram restriction:** a separate, default-off control using a
  native AccessibilityService, Home navigation and a branded Daylock lock screen.

Plans, history, routines, events and preferences persist locally. OAuth tokens use
secure storage. There is no Daylock backend, account system or cloud database.

## Development setup

### Web version

Open [Daylock in your browser](https://softhefrenchguy.github.io/Daylock/).
Plans are saved in that browser's storage; they do not sync with the Android app
or another browser. Clearing site data removes those local plans. Scheduled
notifications, Instagram blocking, and Google/Microsoft calendar sign-in are not
available in this web build. Local planning, Focus timers, and local events work
without an account. Background tabs may pause UI updates; this is not a promise
of closed-browser reminders or offline availability.

The Flutter source stays on `main`. GitHub Pages serves the compiled web files
from the root of `gh-pages`. To prepare an updated site with the correct project
path, run `flutter build web --release --base-href /Daylock/`, then publish only
the contents of `build/web` plus an empty `.nojekyll` file to `gh-pages`. Rebuild
and republish after source changes; pushing `main` alone does not update the site.
Do not copy local app data, OAuth credentials, or signing keys into the web output.

### Local development

The current project has been validated with **Flutter 3.47.6 / Dart 3.13.5**.
The Dart SDK requirement is declared in pubspec.yaml and dependencies are pinned
in pubspec.lock. Install Flutter, Android Studio, its Android SDK and a compatible
JDK; Android Studio's bundled JBR works with this project's Gradle wrapper.
Android is the primary development target; other platform scaffolds are retained.

Clone your private repository using your configured GitHub authentication, then:

    cd daylock
    flutter --version
    flutter doctor
    flutter pub get
    flutter devices
    flutter run -d ANDROID_DEVICE_ID

Use a physical phone with USB debugging enabled or an Android emulator. If Flutter
is not on PATH, invoke the SDK's bin/flutter.bat on Windows or bin/flutter elsewhere.
Do not uninstall or clear storage when updating an installation with real data.

For a Windows PowerShell terminal that needs Java:

    $env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
    $env:Path = "$env:JAVA_HOME\bin;$env:Path"

These settings affect only the terminal session. Local SDK paths in
android/local.properties are generated locally and excluded from Git. Gradle
wrapper scripts/JAR and project configuration are version controlled.

The existing Android application ID is **com.example.daylock**. Keep it and the
existing signing configuration when updating an installed app. Debug builds use
the normal local Android debug key, which is never committed.

## Local notifications

Settings now includes Plan Tomorrow (20:00), Commitment Reminder (14:00),
Freedom and Focus completion preferences. Android evaluates current saved state
in a native receiver, so completed/excused tasks and committed plans suppress
obsolete reminders even without Flutter running. Permission is requested only
from the Settings button. Web/PWA shows unavailable scheduling controls.

See [local notification architecture and physical-device tests](docs/local-notifications.md).
Background delivery still requires physical-device verification; inexact alarms
can be delayed by Android battery restrictions. Test prereleases are available
from [GitHub Releases](https://github.com/softhefrenchguy/Daylock/releases).

## Calendar OAuth configuration

Local planning and local events work without OAuth registration. External account
connections require provider registrations you control:

- [Google Cloud setup](docs/google_calendar_setup.md): Android package/debug SHA-1
  registration and a Web OAuth client ID.
- [Microsoft Entra setup](docs/microsoft_calendar_setup.md): a native public client
  supporting personal and work/school accounts, authorization code with PKCE,
  and delegated read-only calendar permissions.

The public client IDs are Dart defines. Enter your existing IDs locally in
PowerShell and include both on each configured run/build:

    $daylockGoogleClientId = Read-Host 'Google Web OAuth client ID'
    $daylockMicrosoftClientId = Read-Host 'Microsoft Application client ID'
    flutter run -d ANDROID_DEVICE_ID "--dart-define=GOOGLE_SERVER_CLIENT_ID=$daylockGoogleClientId" "--dart-define=MICROSOFT_CLIENT_ID=$daylockMicrosoftClientId"

Client IDs are public identifiers, not client secrets. Neither integration needs
an embedded client secret. Never commit OAuth secrets/tokens, signing credentials,
device exports or real calendar/planner data. Test accounts/tokens in the test
fixtures are synthetic. See .gitignore for local credential/data exclusions.

## Android Accessibility and Instagram control

In Daylock Settings, Freedom Control and Block Instagram are independent.
Accessibility access must be enabled manually after reading Daylock's disclosure:

1. Open Daylock Settings and choose Open Accessibility Settings.
2. In Android Accessibility ? Downloaded/Installed apps, enable
   **Daylock Instagram detection**; manufacturer labels may differ.
3. Return to Daylock and confirm the service is enabled and connected.
4. Enable Block Instagram through its consent dialog and configure Freedom Control.
   Revoke access in Android Settings or disable blocking at any time.

Trusted sideloaded builds may require Allow restricted settings in Android App
info. Respect device/admin restrictions. There are no overlays, administrator
privileges, screen-content inspection or browsing-history collection. Only the
official Instagram package is targeted; other apps are not restricted.

Native code evaluates durable dated Freedom inputs against the current local clock.
Valid current-day inputs have no five-minute expiry. Midnight uses a saved tomorrow
summary without carrying yesterday's completion forward; Flutter still owns real
rollover and historical writes. Unknown state offers a bounded recovery screen
with Open Daylock and Disable Blocking, then permits reopening rather than traps.

Android/OEM service delivery and background-launch restrictions remain limitations.
This is voluntary control, not tamper-proof enforcement. Original Stage 2B was
verified on a physical phone; the durable-state expiry fix still needs the
5/30/120-minute, reboot and midnight checks described in the
[architecture and physical-device guide](docs/android-instagram-durable-state.md).
Publishing through Google Play requires review of the applicable Accessibility
API declaration, disclosure, consent and privacy requirements.

## Architecture

MainApp remains the state owner; no Provider, Riverpod or Bloc is used.

| Location | Responsibility |
| --- | --- |
| lib/models | Tasks/outcomes, dated plans, immutable history, events, routines and calendar account/cache models |
| lib/services | Local persistence/migrations, pure Freedom calculations, Focus/time and calendar provider/authentication services |
| lib/screens | Today, Plan, Calendar, Settings and routine/account controls |
| lib/design | Central palettes, appearance preferences, typography and reusable Bold Discipline components |
| android/app/src/main/kotlin/com/example/daylock | Accessibility detection, durable revisioned Freedom state, native policy and lock activity |
| test | Dart/widget tests using synthetic plans, events and authentication fixtures |
| android/app/src/test | Kotlin policy, persistence/revision and recovery tests |
| docs | Provider setup, native control verification and detailed development notes |

Ordinary app state is stored through DaylockState/LocalStorage. Credentials use
SecureCalendarCredentialStore; appearance uses separate preferences. Native
eligibility stores only dated counts/controls and a Focus deadline with atomic
revisions. External events never become commitments or contribute to completion.

## Validation

From the project root:

    flutter analyze
    flutter test

From android, with Java configured:

    ./gradlew :app:testDebugUnitTest

On Windows use ./gradlew.bat. Then from the project root:

    flutter build apk --debug

Run native/build checks sequentially with other Flutter commands on Windows to
avoid competing writes to generated assets. Use the existing OAuth defines when
building a phone installation that needs calendar connections.

Latest application validation: analysis clean, **510 Flutter tests** and
**62 Kotlin tests** passed, and the Android debug APK built. Automated tests do
not establish physical-device enforcement reliability.

See [development notes](docs/development-notes.md) for the existing model,
migration, timer and design decisions. Build outputs, local SDK configuration,
IDE launch settings, secrets, keystores and exported user data are excluded from Git.

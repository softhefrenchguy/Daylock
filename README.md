# Daylock

Daylock is a local-first Android app for planning tomorrow, keeping commitments,
and making space for the things that matter. Your plans, progress and preferences
stay on your device.

## Download for Android

Download **Daylock-0.1.0.apk** from the [latest GitHub release](https://github.com/softhefrenchguy/Daylock/releases/latest).
The APK supports Android 7.0 and newer. Open it on your phone and follow Android's
installation prompts. Android may ask you to allow installs from your browser or
file manager. Updating an existing Daylock installation signed with the same key
keeps its local data; do not uninstall the existing app before updating.

This is a GitHub-distributed APK, not a Google Play release. It uses the same
local debug signing identity as earlier Daylock test builds to preserve updates.
Keep the original signing key safe: losing it prevents future updates to this
installation. A Play Store distribution needs separate release preparation.

## Features

- **Today:** manage and complete commitments; record optional stopwatch time.
- **Plan:** prepare and commit tomorrow's plan, with routines and scheduled events.
- **Journey:** organise Areas, view progress and daily history, and save Highlights.
- **Freedom:** set a Freedom Time and use your commitments and tomorrow's plan to
  earn access to the apps you choose to restrict.
- **App restrictions:** optionally select installed Android apps and use the
  Accessibility service to restrict them while Freedom is not earned.
- **Appearance and reminders:** choose light, dark or system appearance, six colour
  palettes, and local notification preferences.

Daylock has no account or cloud sync. Local events work without a calendar account.
This GitHub APK does not include Google or Microsoft calendar sign-in client IDs,
so external calendar sign-in requires a separately configured build.

## Development setup

### Web version

Open [Daylock in your browser](https://softhefrenchguy.github.io/Daylock/).
Plans are saved in that browser's storage; they do not sync with the Android app
or another browser. Clearing site data removes those local plans. Scheduled
notifications, app restrictions, and Google/Microsoft calendar sign-in are not
available in this web build. Local planning, stopwatches, and local events work
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

Clone the repository, then:

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
and Freedom notification preferences. Android evaluates current saved state
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

## Android app restrictions

App restrictions and Freedom Control are separate, optional switches. To set them up:

1. Open **Settings > Freedom Control** and configure Freedom Time.
2. Open **Restricted Apps**, turn on app restrictions, and select the apps you want.
3. Open **Accessibility > Open Accessibility Settings** and follow the disclosure
   to enable **Daylock app restrictions** in Android's Accessibility settings.
4. Return to Daylock and check that the service is connected.

Android may require **Allow restricted settings** in Daylock's App info for a
sideloaded app. Device menus vary. You can disable restrictions in Daylock or
revoke Accessibility access in Android settings at any time. Daylock excludes
its own app, launchers, Android Settings and other recovery interfaces.

Android can delay or disconnect Accessibility and may prevent a background lock
screen from appearing. Restrictions are voluntary and are not tamper-proof. For
migration details, privacy, limitations and a device checklist, see the
[multi-app restrictions guide](docs/multi-app-restrictions.md).

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
eligibility stores dated counts and controls with atomic revisions. External events never become commitments or contribute to completion.

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

Latest feature validation: analysis clean, **681 Flutter tests** and
**117 Kotlin tests** passed, and Android debug and release APKs built. Automated tests do
not establish physical-device enforcement reliability.

See [development notes](docs/development-notes.md) for the existing model,
migration, timer and design decisions. Build outputs, local SDK configuration,
IDE launch settings, secrets, keystores and exported user data are excluded from Git.

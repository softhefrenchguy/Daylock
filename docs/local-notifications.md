# Local notifications

Daylock now stores four independent notification preferences in its existing
`daylock.state.v2` record. Plan Tomorrow defaults to 20:00, Commitment Reminder
to 14:00, and Freedom/Focus completion alerts default on. Freedom alerts still
require Freedom Control. Old saves receive these defaults without replacing any
other fields. Corrupt preferences fail the normal safe load path instead of
resetting planner data. Appearance, calendar credentials and signing are unchanged.

## Android delivery

`NotificationService` separates application state and widgets from the platform.
`flutter_local_notifications` 22.3.2 manages Android channel creation and the
explicit permission/settings flow. The conditional background delivery uses
AndroidX NotificationCompat directly from a native receiver; it does not start
a Flutter engine or rely on Dart executing at delivery time.

Before a planner save, MainApp freezes the state and invalidates the native
notification mirror. That cancels the pending alarm and clears Daylock's existing
reminders, whose contents could now be obsolete. Only after all outstanding saves
succeed does MainApp publish a new mirror. Notification bridge errors do not
reset planner data. A crash between invalidation and publication fails closed:
reopen Daylock to restore reminders from the successfully saved planner.

The private notification record contains only preferences, Freedom settings, the
two dated task summaries (name, outcome, minimum duration, existing deadline),
and local deduplication keys. It contains no calendar data, account credentials,
excuse reasons, tracking, analytics, or network calls. The mirror and delivery
ledger are excluded from backup/device transfer; app preferences remain in the
normal planner backup.

`NotificationPolicy` evaluates current local date and persisted outcomes every
time the receiver runs. It excludes completed/excused tasks and never treats
history as today's work. It uses the existing native `DetectionPolicy` Freedom
evaluator, the counterpart of Dart's `FreedomService`, with current eligible and
completed counts. It never changes Accessibility state or claims Instagram is
unlocked. Empty/all-excused days remain ineligible.

One replaceable `AlarmManager.setAndAllowWhileIdle` inexact alarm points at the
next daily time, Focus deadline, or local midnight. There is no foreground service,
periodic background polling, new Focus timer, or exact-alarm privilege. Default
daily times and midnight produce only a few wakeups per day; active Focus sessions
add their existing completion deadlines. If only Focus is enabled and no timer
is running, nothing is scheduled.

Boot, package replacement, time/timezone changes, notification block changes and
app resume rebuild the next alarm. Calendar-date arithmetic handles midnight and
DST; a nonexistent time shifts forward across the spring gap, and the first
occurrence of an overlapping time is used. A delayed daily reminder can catch up
within the same local day, after checking current state. Historical Focus alerts
are discarded. State more than one day old never invents new commitments.

Daily evaluated slots and delivered Focus/Freedom-earned keys are persisted before
posting. Reboot, repeated callbacks, settings changes and backward clock changes
cannot duplicate a retained key. The ledger retains 64 local dates. Focus keys use
the date and immutable Today task index; tap navigation also checks the task name.
If Today ever supports reordering/deletion, migrate these keys to stable task IDs.
Only one completion alert is allowed for a given Focus commitment on its date,
including after a reset. Pausing, excusing or resetting removes the pending
deadline. If Flutter settles a genuinely due timer before the inexact alarm, the
mirror retains that already-earned deadline for notification delivery only; it
does not alter elapsed time or task completion rules.

## Permission and channels

The app never automatically opens a notification permission dialog. In Settings,
tap **Allow notifications**. Android 13+ uses `POST_NOTIFICATIONS`. The fact that
the user was asked is stored before the dialog opens. Subsequent attempts open
system settings, so a decline is not repeatedly prompted. System permission and
per-category blocked channels are displayed independently of saved app toggles.

Manifest additions:

- `POST_NOTIFICATIONS` and `RECEIVE_BOOT_COMPLETED`.
- Non-exported `NotificationAlarmReceiver` and `NotificationRestoreReceiver`.
- Boot/package/time/timezone/app-block/channel-block system broadcast filters.
- Four default-importance channels: `daylock_plan`, `daylock_commitments`,
  `daylock_freedom`, `daylock_focus`.
- A monochrome Daylock lock notification icon, with private lock-screen content.

The notifications plugin adds `VIBRATE`. No exact-alarm, full-screen-intent,
notification-policy/DND bypass, Accessibility, or background-service permission
is required for notifications. The existing Accessibility service is unchanged.
Android ID remains `com.example.daylock`; signing configuration is unchanged.

## Web and other platforms

Conditional imports keep Android implementation code out of web builds. Web
checks the browser Notification API and secure-context capability but explicitly
disables scheduled notification controls. No browser permission is requested:
there is no push backend or service worker capable of reliable closed-app delivery.
Safari, an installed iPhone PWA, and a closed/throttled browser tab cannot promise
these reminders. Other desktop/native-iOS builds also show unavailable controls
in this stage. All planner functionality remains available.

## Automated checks

Validated on 14 October 2026: `flutter analyze` reports no issues; all 525
Flutter tests and 86 native Android tests pass (including 24 notification policy
tests). The Android debug APK and Flutter Web release build succeed. The APK signing certificate
matches the existing installation's original development key. These checks do
not include physical-device delivery.

Build output includes a non-fatal Cupertino font warning on web, and Java native
access/Gradle deprecation warnings on Android. No build or test failed. The local
APK is `build/app/outputs/flutter-apk/app-debug.apk`; the web output is `build/web`.

Tests cover additive preference migration and all 16 toggle combinations;
time selection/rescheduling; denied/revoked permission and blocked channels;
conditional suppression and remaining counts; Freedom transitions/neutral days;
Focus pause/resume/reset/excuse/completion; cold and warm tap navigation; snapshot
publication order and failure recovery; duplicate prevention; midnight, skipped
days, timezone changes and both DST boundaries; and persisted reboot restoration.

Run from the repository root (sequentially on Windows):

```powershell
flutter analyze
flutter test
cd android
.\gradlew.bat :app:testDebugUnitTest
cd ..
flutter build apk --debug
flutter build web --release
```

Build with your existing `GOOGLE_SERVER_CLIENT_ID` and `MICROSOFT_CLIENT_ID` Dart
defines when testing actual calendar connections. Builds without those public
IDs can test local notifications but are not a replacement for your configured
calendar build. Use test prereleases for device verification before distributing
a stable update.

## Physical Android test checklist

Background delivery has **not** been validated on a physical Android device.
Automated policy tests do not establish OEM/Doze delivery reliability.

1. Update an existing installation with the same signing key. Check existing
   plans, history, Focus elapsed time, excuses, routines, calendar accounts,
   appearance and Instagram controls. Do not uninstall or clear storage.
2. On Android 13+, deny notification permission, restart/background/resume the
   app and change toggles. Verify no repeated prompt or notification. Use the
   Settings button to enable permission; then disable one channel in Android
   settings and verify its blocked status after returning to Daylock.
3. Set Plan Tomorrow a few minutes ahead. Leave tomorrow uncommitted, background
   the app and wait (allow for inexact delays). Tap the alert: Plan opens. On a
   fresh local test date, commit tomorrow before the time and verify suppression.
4. Configure Commitment Reminder ahead with two unfinished Goals, one completed
   Goal and one excused Goal. Verify “2 commitments”, then repeat with every task
   completed/excused and with an empty day: no reminder. Tap opens Today.
5. Enable Freedom Control and set Freedom Time ahead. Test each missing condition,
   then complete eligible commitments and commit tomorrow after that time: exactly
   one “Freedom earned” alert. Reset/re-complete a Goal and restart the app; there
   must not be another earned alert that day. Repeat with zero/all-excused tasks
   and with Freedom Control off. Instagram behavior must remain independent.
6. Start a one-minute Focus task and background Daylock. Verify completion alert
   and the saved minimum-duration rule. Repeat after pausing, resuming, resetting,
   excusing, disabling Focus notifications, and completing while foregrounded.
   Tap the alert after process termination: Today opens the matching task sheet.
   Tap an old-date alert: it must not open a different day's task.
7. Repeat with the screen locked and battery saver/Doze, and with the UI process
   killed without force-stopping the package. Reboot during Focus and before a
   daily reminder. Unlock after boot and verify restored scheduling and no repeats.
8. Test midnight with a committed tomorrow plan, a skipped day, a timezone change,
   clock changes and DST boundaries on a test device. Check that only today's
   unfinished eligible work is counted; no historical Focus alert should appear.
9. Force-stop Daylock from Android settings as a separate limitation test: Android
   cancels/prevents alarms until the app is opened again. Reopen and verify recovery.
10. Open the web build and iPhone PWA. Confirm the limitation text and disabled
    scheduling controls, no unsolicited browser prompt, and working planner UI.

## Reliability limits

Inexact alarms can be late, especially under Doze, battery saving or OEM background
restrictions. Focus eligibility still changes at the original deadline, regardless
of delivery delay. User force-stop and some OEM task killers prevent background
delivery until relaunch. Device-off periods cannot produce on-time notifications.
Permission changes restore on the next supported system event or app resume.
DND and channel settings are respected; an accepted notification need not make a
sound. A process death between persisting a deduplication key and posting can lose
that one alert (an intentional at-most-once tradeoff). A failed/interrupted planner
save suppresses notifications until resynchronization. Extreme manual clock travel
outside the retained 64 dates is outside deduplication retention.

Platform references: [Android alarm scheduling](https://developer.android.com/develop/background-work/services/alarms),
[Android notification permission](https://developer.android.com/develop/ui/views/notifications/notification-permission),
and [flutter_local_notifications 22.3.2](https://pub.dev/packages/flutter_local_notifications/versions/22.3.2).

## Files

- `lib/models/notification_preferences.dart`, `daylock_state.dart`,
  `services/local_storage.dart`: preferences and additive migration.
- `lib/services/notifications/*`: shared interface, frozen snapshots,
  Android permission/bridge implementation, capability-aware web/stub implementations.
- `lib/main.dart`, `screens/settings_screen.dart`,
  `screens/notification_settings_section.dart`, `screens/today_screen.dart`:
  save/lifecycle integration, settings, and validated tap navigation.
- `android/app/src/main/kotlin/com/example/daylock/NotificationPolicy.kt`,
  `NotificationRuntime.kt`, `MainActivity.kt`: durable native policy, receivers,
  scheduling, delivery and bridge.
- Android manifest, Gradle configuration, backup rules and `ic_stat_daylock.xml`:
  permissions, desugaring and resources.
- `test/notification_*_test.dart` and native `NotificationPolicyTest.kt`: coverage.
- `pubspec.yaml`, `pubspec.lock`, affected generated plugin registrations and this
  guide/README: dependency wiring and documentation.

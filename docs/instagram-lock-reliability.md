# Instagram lock-screen reliability

## Findings and scope

The physical-device report confirms that the existing blocker leaves Instagram,
but not that its branded activity consistently appears. The previous service
requested `GLOBAL_ACTION_HOME` and immediately called `startActivity`. Home is an
asynchronous system navigation request: it can compete with the activity start
and pause/cover the `noHistory` lock activity. Android/OEM background activity
launch restrictions can also deny or delay `startActivity` without throwing.

The competing navigation sequence is confirmed in the old code. Which mechanism
caused a particular phone's missing screen is **not yet established**; the new
diagnostics and physical-device checklist below distinguish the outcomes.

`InstagramBlockingPolicy`, `DetectionPolicy`, `NativeFreedomRepository`, the
persisted native Freedom record, and the Flutter planner save barrier are unchanged.
The app ID, signing, manifest permissions and Accessibility configuration are
unchanged. No planner migration, data reset, overlay, polling service, full-screen
intent, task-hijacking flag or background-launch privilege override is introduced.

## Navigation and lifecycle

1. Accept a full-screen Instagram foreground event through the existing gate.
   Log the target session and current Freedom result; never inspect screen text,
   accessibility nodes, other app names or Instagram content.
2. Apply the existing eligibility and bounded recovery rules. Require the same
   foreground session, current state revision, enabled service, and an unlocked,
   interactive device. Make at most one enforcement attempt per foreground session.
3. Try the explicit, unexported Daylock lock activity in its existing separate
   task. Log the attempt and separately log that `startActivity` returned.
4. After **300 ms**, request Home only if the lock activity has not resumed and
   Instagram is still the same foreground session, with unchanged revision and
   current restriction. This avoids sending Home over a resumed Daylock screen
   or navigating away from an unrelated app. A thrown launch exception uses the
   same guarded Home fallback immediately.
5. At **1.5 seconds**, settle the attempt once. Visibility requires matching
   `onResume`, a drawn content frame, window focus, and an interactive/unlocked
   device. A successful launch request alone never counts as a displayed screen.
   This is lifecycle evidence, not proof that a person saw the screen.
6. Missing confirmation requests a notification, not another activity launch.
   A late visible acknowledgement cancels the notice. Old activity callbacks and
   delayed timers cannot confirm or change a newer attempt. Disconnecting removes
   service callbacks and invalidates its presentation authority.

Activity launches have a **three-second process-level cooldown** even across
rapid leave/reopen cycles and service rebinds. A fresh Instagram entry during
that cooldown still uses guarded Home navigation. Returning from the lock screen
or notification never automatically reopens Instagram. The existing palette,
dark/light/System mode, scrollable controls, Back/Home exit, disable-blocking
button and Accessibility-settings button remain available.

The grace period is a deliberate tradeoff: on a failed launch, Instagram may
remain visible briefly before Home is requested. There is no universal zero-frame
or zero-delay enforcement guarantee. Main-thread or system scheduling can extend
the delay; successful Home navigation also remains an Android-controlled action.

## Notification fallback

- Channel: `daylock_instagram_lock` / **Instagram lock notices**, default importance.
- Notification and tap request ID: **7450**, separate from 7400–7404 used by the
  Plan, Commitment, Freedom, and Focus scheduler. Neither path cancels all notices.
- Title: **Instagram is locked**.
- Body: **Complete your Daylock commitments to earn Freedom.**
- An immutable, direct activity PendingIntent opens Daylock on user tap. There
  is no notification trampoline or programmatic PendingIntent send.
- Recheck current Freedom and service state before posting. Never post the locked
  notice for unknown/recovery, earned, disabled, disconnected, or revoked states.
- Respect Android notification permission, the app notification switch, channel
  blocking and DND. Never request permission from the service. A notification
  accepted by Android is not proof of visible or audible delivery.
- One notice maximum per **five minutes**, using a reservation persisted before
  posting. Rapid launches, service restart and process recreation share that limit.
  Same-boot throttling uses monotonic time; reboot uses wall time. A backward clock
  correction across reboot allows one fresh notice, then normal throttling resumes.
- Reuse one notification ID, auto-cancel on tap and expire after five minutes.
  Confirmation of the lock screen cancels it. State/permission/service reconciliation
  also cancels when no longer blocked; without a new state event, expiry bounds an
  old notice. No extra periodic job runs just to remove this fallback.
- A failed reservation suppresses posting. A crash/exception after reservation
  can miss one notice instead of sending repeated notices. A corrupt reservation
  suppresses notices and is logged, without resetting any other data.

Only an additive `lockFallbackNotice` timestamp record is saved alongside the
existing native preferences, already excluded from backup/transfer. The existing
latest restriction field distinguishes requested, shown, unconfirmed, notification
posted and notification-permission/channel-unavailable states in Settings.

## Diagnostics

Connect a test phone with USB debugging. Capture the relevant local logs:

```powershell
adb logcat -v threadtime -T 1 "DaylockInstagramLock:I" "ActivityTaskManager:W" "ActivityManager:W" "StrictMode:D" "*:S"
```

`DaylockInstagramLock` uses an attempt ID, SDK level, fixed event names and bounded
status fields. No task names, screen contents or browsing history are logged or
transmitted by Daylock. Diagnostic output uses Android's rotating Logcat buffers;
the app does not create a persistent event-history file.

Look for `instagram_foreground`, `freedom_evaluated`, `lock_launch_attempt`,
`lock_launch_returned`, `activity_created`, `activity_resumed`, `activity_focus`,
`activity_drawn`, `lock_visible_confirmed`, `home_requested`, `home_result`,
`home_skipped`, `launch_throttled`, `lock_launch_unconfirmed`, `lock_launch_exception`,
and `fallback_result`. Exceptions log their class, not arbitrary exception text.

A missing `activity_resumed` after a returned launch request is **unconfirmed**,
not automatically classified as a BAL denial. On Android 15, correlate with the
system's `ActivityTaskManager` logs for actual denial evidence. Daylock does not
request privileged log access. Android 16+ debug builds additionally enable
`StrictMode.detectBlockedBackgroundActivityLaunch()` with log-only penalties,
preserving the existing VM policy. No such API is called on older Android versions.

## Automated versus physical verification

Validation on 24 October 2026: `flutter analyze` reports no issues; all **526
Flutter tests** and **105 Kotlin tests** pass (19 new Kotlin cases plus one new
Flutter widget test). The Android debug APK builds successfully at
`build/app/outputs/flutter-apk/app-debug.apk`; its signing certificate matches the
existing development key. No physical Android device was connected during validation.

Pure Kotlin tests exercise lifecycle ordering, silent-launch timeout, resumed
versus focused/drawn confirmation, pause and screen-lock conditions, late/stale
callbacks, rapid entries, service restart and cold-process authority. Notification
dispatch tests use the production dispatcher with injected ledger/renderer to
verify denied permission, grant-after-denial, durable throttling, reservation
before rendering, reboot/clock changes, corrupt/failed storage and platform errors.
Existing Freedom and notification-policy tests remain unchanged. A Flutter widget
test checks that the new statuses do not claim a visible lock screen or a Home
request that was not confirmed by that status.

These tests do **not** simulate an OEM's Accessibility binding, actual activity
task scheduling, Android 15 BAL decisions, notification delivery or visual palette.
Physical-device verification remains required. No new GitHub release is published.

Run sequentially from the repository:

```powershell
flutter analyze
flutter test
cd android
.\gradlew.bat :app:testDebugUnitTest
cd ..
flutter build apk --debug
```

## Physical-device checklist

Use an existing installation and the same signing key; do not uninstall or clear
storage. Record phone model, Android version, battery settings and app build. This
test APK still needs the existing OAuth Dart defines for calendar sign-in testing.

1. **Baseline/data:** verify plans, history, excuses, Focus elapsed time, routines,
   appearance, calendar data and Freedom settings. Enable the existing optional
   blocker and Accessibility, with a valid not-earned state. Compare before/after
   logs on the same phone if possible; count visible-screen confirmations separately
   from launch requests and successful Home requests.
2. **Launcher and Recents:** open Instagram from each, ten times with more than
   three seconds between attempts. Prefer one lock activity with no immediate Home
   transition when resumed. If unavailable, expect guarded Home and a notice when
   permitted. Tapping the notice opens Daylock, never Instagram.
3. **Background and cold process:** background Daylock before opening Instagram.
   Repeat after Android terminates its process, then rebinds Accessibility. Verify
   the process actually changed; `am kill` may spare a bound service. Do not equate
   force-stop with ordinary process death. No Flutter engine should be required to
   display the native lock screen or notification.
4. **Rapid launches:** reopen Instagram repeatedly within three seconds, including
   Recents. Expect no concurrent activity-launch loop; Home can still protect each
   new Instagram session. Over five minutes, allow at most one fallback posting.
   Switch to another app before the grace period ends: Daylock must not send that
   other app Home or issue a fresh activity retry.
5. **Locked/unlocked screen:** trigger near a screen lock and then unlock. There
   must be no claim of confirmed visibility without an unlocked, resumed, focused
   and drawn screen. Test notification shade, rotation and Back/Home as well.
6. **Service restart:** disable/re-enable Accessibility during the grace/confirmation
   interval, and after a fallback notice. Old callbacks must not navigate. Reopening
   Instagram after reconnect must use current durable state; notification cooldown
   must persist. Disabling/uninstalling Daylock must remain possible.
7. **Android 15:** test a physical API-35 device with Daylock backgrounded and via
   Recents. Capture system BAL logs. A returned launch request with no resume/draw
   must produce an unconfirmed result, not a false success. If the OS denies the
   screen, confirm Home and the permission-respecting fallback. Repeat on Android
   16+ debug build to inspect StrictMode diagnostics where available.
8. **Notifications:** deny `POST_NOTIFICATIONS`, disable all app notifications, and
   separately block **Instagram lock notices**. Blocking must still operate without
   permission dialogs or errors. Re-enable and test again. Check DND and lock-screen
   privacy. Verify Plan/Commitment/Freedom/Focus channels and notifications are intact.
9. **Eligibility and cancellation:** earn Freedom, disable Freedom Control, disable
   blocking, excuse tasks, and test the existing unknown-state recovery separately.
   These rules must match the previous build. Do not issue a locked notice for an
   earned/disabled/unknown state. Confirm a late lock-screen draw removes its fallback.
10. **Appearance and limits:** check all six palettes in Light, Dark and System mode,
    large text, and screen insets. Test a reboot and battery-saving restrictions.
    Force-stop separately: Android may stop delivery until Daylock is reopened.
    Record missed/delayed screens honestly; do not claim device reliability from
    automated tests alone.

References: [Android activity security/BAL and diagnostics](https://developer.android.com/guide/components/activities/secure-bal),
[AccessibilityService system navigation](https://developer.android.com/reference/android/accessibilityservice/AccessibilityService#performGlobalAction(int)).

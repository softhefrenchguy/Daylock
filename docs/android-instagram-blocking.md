> Historical original Stage 2B guide. Navigation was verified on the user's
> phone, then its five-minute expiry was confirmed as a bug. Current implementation
> uses [durable native eligibility](android-instagram-durable-state.md); that guide
> supersedes the expiry, reboot, clock, Focus and recovery rules below. The updated
> fix still requires physical-device verification.

# Instagram blocking — Stage 2B

For the current activity-first presentation, diagnostics and notification fallback,
see [Instagram lock-screen reliability](instagram-lock-reliability.md). That guide
supersedes the Home-first navigation and display acknowledgement described below.

Stage 2A detection was verified on the user's Android phone. This stage adds
**optional, voluntary restriction of the official Instagram Android app only**.
Stage 2B navigation and the native lock screen still need physical verification.

## Controls and restriction rules

Open Today's gear → Settings → **Instagram Control → Block Instagram**. The
separate blocking preference defaults **off**, including for existing users.
Enabling it requires an explicit disclosure/confirmation. **Freedom Control** in
the Freedom section is independent; turning either control off allows Instagram.
Accessibility access must also be enabled manually in Android Settings.

| Blocking / permission / native Freedom | Action when Instagram opens |
| --- | --- |
| Blocking off or Accessibility revoked | Allow; no navigation |
| Fresh snapshot with Freedom Control off | Allow |
| Fresh snapshot with Freedom earned | Allow |
| Fresh snapshot with Freedom not earned | Request Android Home, then open Daylock's lock activity |
| Missing, invalid, expired or stale snapshot | Allow, record recovery status, show a rate-limited refresh reminder |

Freedom still requires the current local Freedom Time, at least one eligible
Today commitment with every eligible commitment completed, and tomorrow committed.
Excuses are excluded and never count as completed. Empty/all-excused days remain
ineligible. Calendar events and routines do not enter this calculation.

**Five-minute limit:** the Stage 2A snapshot contract is retained. After five
minutes without a new snapshot, blocking pauses, even if all stored commitment
conditions remain unchanged. Reopen Daylock to refresh it. This avoids indefinite
enforcement from stale data, but makes this version unsuitable for guaranteed
all-day enforcement, parental control or tamper-proof restrictions.

## Native architecture

- `InstagramDetectionService` remains the system-bound AccessibilityService.
  It subscribes only to window-state changes. Package filtering now happens in
  code: other window package names are compared transiently to cancel a pending
  Instagram action when the user switches apps. Only a target/not-target boolean
  and session revision remain in memory. No other app names or window contents
  are saved. Pane appearance/title/disappearance events are ignored. Navigation
  requires a full-screen Instagram window, an interactive/unlocked device, current
  permission, fresh state and the same foreground session at the final check.
- `InstagramBlockingPolicy` is a pure Kotlin decision function, sharing the
  existing `DetectionPolicy` clock/freshness contract. Repeated events are gated
  for three seconds; leaving Instagram resets the gate so immediate reentry works.
  A state revision cancels/rechecks queued decisions after settings/state changes.
  There is one bounded retry for a concurrent state write, no polling loop.
- The service uses `performGlobalAction(GLOBAL_ACTION_HOME)` and an explicit
  intent for an unexported `InstagramLockActivity`. No overlay, gestures, fake
  Instagram UI, device administrator access or extra runtime permissions are used.
  No navigation is initiated for other packages.
- The lock activity is an ordinary, clearly branded Daylock screen in a separate
  task. It shows Freedom conditions and **Open Daylock**, **Return to Home**, and
  **Accessibility Settings**. Back returns Home. It is excluded from Recents and
  is not retained after leaving. It never automatically reopens Instagram.
- The native screen receives the same central dark/light palette as Flutter;
  System mode follows Android. Native scrollable layouts use system-bar/cutout
  insets and scalable text. Visible status updates at the next minute, snapshot
  expiry, or Focus deadline, with immediate updates on state/permission changes.
  It does not keep a worker/timer polling while hidden.
- A one-shot first-draw acknowledgement distinguishes a displayed lock screen
  from an attempted launch. If no acknowledgement arrives within 1.5 seconds,
  Settings reports that Home was requested but the screen was not confirmed.
  No retry or second Home action can push the user out of a different app.

Android does not offer a universal foreground guarantee through window events.
Split-screen, non-full-screen windows, Instagram Lite/clones/web use and another
Android profile are outside this implementation's scope. The service receives
future window activations, including Instagram reopened from Recents; toggling
blocking does not try to discover or redirect an already visible application.

## Native Freedom state and persistence

The existing planner save barrier is unchanged: startup/save first invalidates
native state; a fresh snapshot is published only after all planner saves succeed.
Completion, excuses, resets, Focus Start/Pause, tomorrow commitment and Freedom
settings therefore update the snapshot after persistence. Loading/saving errors
leave it unknown. Foreground snapshots refresh at most every 30 seconds when
inputs are unchanged; lifecycle transitions force refreshes.

Snapshots contain dated counts and conditions, not a permanently cached earned
boolean. Native code recomputes the time condition against its current clock.
Wall/monotonic age, boot count, local date, timezone ID and UTC offset must match;
reboot, midnight, clock changes, timezone/DST changes and permission revocation
invalidate eligibility. Source payloads over ten seconds old are rejected. Fresh
snapshots expire at five minutes, including those previously marked earned.

For the single active Focus session, Flutter additionally supplies the UTC
timestamp when its remaining minimum will be earned. Fresh native snapshots can
project that one commitment's completion at the deadline without running Flutter.
They cannot complete it early or count it twice. Flutter remains the only owner
of actual task outcomes, elapsed time, saves and historical snapshots. Old
snapshots missing this deadline while Focus runs safely require recovery.

`daylock.instagram_detection.v1`, the existing app-private native preferences,
receives additive `blockingEnabled`, `lastRestriction` and `lockAppearance` fields
plus the optional Focus deadline inside its snapshot. The setting survives process
and service restarts; reboot still invalidates eligibility. Missing settings
default off, and old snapshot formats remain readable. This file remains excluded
from backup/device transfer. A failed disable applies in memory immediately, but
Settings warns if it could not persist; revoking Accessibility is always available.

There is **no planner migration or reset**. Planner/history/routine/event storage,
OAuth secure storage and appearance preferences are untouched. App ID and signing
are unchanged. Only the latest Instagram detection/restriction record is retained;
there is no browsing history, screen text, accessibility-node access or transmission
of detection data.

## Android 15 limitations

Android allows some system-bound services, including Accessibility services, to
launch activities, but background-launch rules and OEM behavior can still deny
or delay a launch. Daylock first requests Home as the fallback. If Home itself
fails, it reports that restriction could not be applied. If launching the lock
screen throws or is silently denied, it reports an unconfirmed screen and leaves
navigation alone. No overlays or privileged workarounds are added. See
[Android background activity launch restrictions](https://developer.android.com/guide/components/activities/secure-bal).

Android must keep/rebind the service for background detection. Revocation stops
navigation immediately; enabled but disconnected is shown as waiting. Force-stop
kills the whole application/service. OEM battery policies, service delivery and
device reboot require testing; a saved toggle is not proof of active enforcement.
The user can always disable the service, turn blocking off or uninstall Daylock.

## Physical-device checklist

Use a full rebuild/relaunch for native changes; hot reload is insufficient.
Do not uninstall, clear storage or use the development reset flag. Launch with
your existing **public** OAuth client-ID variables to preserve configured calendar
functionality (no client secrets):

```powershell
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
flutter devices
flutter run -d 'ANDROID_DEVICE_ID' "--dart-define=GOOGLE_SERVER_CLIENT_ID=$daylockGoogleClientId" "--dart-define=MICROSOFT_CLIENT_ID=$daylockMicrosoftClientId"
```

The automated validation APK has no user OAuth defines. Use the command above,
with your existing variables, for testing with your working calendars. Java/PATH
changes affect only this terminal.

1. Confirm saved plans, history, calendars, routines and appearance are intact.
   Blocking starts off. Revisit Settings → Instagram Control; service status must
   be **enabled and connected**. If needed, use Open Accessibility Settings,
   consent, then enable **Daylock Instagram detection** manually. Android 15 may
   require Allow restricted settings in Daylock's App info for a trusted sideload;
   respect device/admin restrictions. See
   [Android restricted settings](https://support.google.com/android/answer/12623953?hl=en).
2. With blocking off, Instagram must open normally. Enable it through the consent
   dialog; with Freedom Control off it must still open normally. Cancellation of
   consent must leave blocking off.
3. Enable Freedom Control with at least one unfinished eligible Today commitment
   (or another unsatisfied condition). Immediately after returning from Daylock,
   open Instagram: expect Home, then the branded lock screen and correct checklist.
   Test Instagram already running via Recents as well as its launcher icon.
4. Test Open Daylock, Return to Home, Android Back and Accessibility Settings.
   Reopening Instagram immediately must restrict again without automatic bouncing.
   Other apps and system Settings must stay usable. Switch away quickly during an
   opening; a queued action must not redirect the new app. Do not place test calls
   to emergency services.
5. Reach the selected Freedom Time, complete all eligible commitments, and commit
   tomorrow. Reopen Instagram with fresh state: it must be allowed. Check each
   missing condition independently. Excusing a task excludes it; all-excused and
   empty Today must not earn Freedom. Existing Focus minimum rules remain intact.
6. Try a short Focus timer whose minimum is reached within the five-minute native
   freshness window. Before the minimum, Instagram remains restricted; after it,
   native eligibility should reflect that completion without Flutter foregrounded,
   provided every other Freedom condition is met. Return to Daylock and verify
   accumulated time and completion persisted normally.
7. Leave Daylock backgrounded for over five minutes, then open Instagram: it must
   be allowed with a refresh reminder. Reopen Daylock to recover; repeat an opening
   immediately to verify current restrictions. This fail-open expiry is intentional.
8. Verify toggle persistence after a normal app/service restart and device reboot.
   After reboot native eligibility is unknown until Daylock refreshes. Disable or
   revoke Accessibility: Instagram must remain usable with truthful Settings status.
   Reenable manually and refresh Daylock. Swiping the Flutter activity from Recents
   differs from force-stop, which kills the service too.
9. Automated tests cover midnight, timezone/DST and clock changes. If testing a
   midnight physically, let normal local rollover happen and verify history/time
   are retained. Avoid jumping your real device date forward to test: real rollover
   legitimately archives your plans. Native state must recover safely until Flutter
   refreshes with the actual new date/timezone.
10. Test selected palettes, Light/Dark/System, large text, screen insets and both
    navigation modes on your Android 15 phone. If only Home appears, inspect the
    last-attempt message in Settings; do not interpret it as a confirmed lock screen.

## Google Play policy

Daylock is a productivity app, not a disability accessibility tool;
`isAccessibilityTool` remains false. Before Play distribution, complete the
Accessibility API declaration/review, describe the exact function in the store
listing, provide prominent in-app disclosure and affirmative consent, and align
privacy/Data safety disclosures with on-device data handling. The implementation
includes consent and revocation controls; it is **not a guarantee of approval**.
Do not prevent disabling/uninstalling, bypass platform privacy controls or use
deceptive/system-impersonating UI. Review
[Google Play Accessibility API requirements](https://support.google.com/googleplay/android-developer/answer/10964491?hl=en)
and [disclosure and consent](https://support.google.com/googleplay/android-developer/answer/11150561?hl=en).

## Automated validation

Flutter tests cover native status compatibility, separate toggle/readback,
channel failures, consent/cancellation/disabling, fallback reporting, all palettes,
System appearance and narrow/large-text Settings. Existing planner, Focus, excuses,
history, routines and integration suites remain part of the full run. Pure Kotlin
tests cover restriction decisions, empty/excused days, deadline-based Focus,
expiry, time boundaries, midnight, timezone changes, reboot, permission revocation,
coalescing, foreground cancellation and quick reentry. They do not simulate actual
Android Home navigation or prove an OEM background-launch exemption.

```powershell
flutter analyze
flutter test
# From android, with session JAVA_HOME/PATH:
.\gradlew.bat :app:testDebugUnitTest
# From the project root:
flutter build apk --debug
```

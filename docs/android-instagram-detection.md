> Historical Stage 2A guide. Detection was subsequently verified on the user's
> phone. Current builds include optional Stage 2B restriction; see
> [Instagram blocking](android-instagram-blocking.md) for the current package-event
> handling, Focus deadline, consent, recovery rules and physical test checklist.
> Statements below describe the detection-only build, not current enforcement.

# Android Instagram detection — Stage 2A

This build detects Instagram window openings and reports Freedom eligibility.
**It does not block Instagram, show overlays, perform gestures, press Home/Back,
redirect users or start another app when Instagram is detected.** Physical-device
verification is required before implementing enforcement in a separate stage.

## Architecture and privacy

- `InstagramDetectionService` is a system-bound Kotlin AccessibilityService in the
  existing app process. It works without a Flutter activity/engine while Android
  keeps or rebinds the service. It is not a Flutter timer or foreground service.
- XML subscribes only to `TYPE_WINDOW_STATE_CHANGED` from `com.instagram.android`.
  Window-content retrieval and gesture capabilities are disabled. Event text,
  accessibility nodes, notifications and other applications are not inspected.
- The service detects Instagram window activation events, not an exclusive
  foreground/visibility guarantee in split-screen, picture-in-picture or OEM
  configurations. In-app activity/dialog transitions can also produce these events.
  Returning to Instagram within three seconds may share one coalesced detection.
  This is a latest-detection indicator, not a launch counter or usage tracker.
- A monotonic three-second gate bounds repeated event processing; Android also
  coalesces the event stream with a 100 ms notification timeout. A serial worker
  handles disk I/O, leaving accessibility callbacks and the Android UI unblocked.
- `daylock/instagram_detection` is the MethodChannel for status, invalidation,
  snapshot publication and the user-initiated Accessibility Settings shortcut.
  `daylock/instagram_detection/events` is the EventChannel for status/detections.
  Events are cached natively even if Flutter is detached; reattaching reads them.
- Enabled status comes from Android's enabled service list for this exact
  component. Connected status additionally requires a live service callback. An
  enabled-but-disconnected service is labelled as waiting, not falsely active.
- Separate app-private preferences, `daylock.instagram_detection.v1`, contain one
  overwritten detection record (timestamp and Freedom result at that instant) and
  one replaceable eligibility snapshot. There is no browsing/app-use history,
  task name, excuse reason, event title, account identifier or credential in this
  cache. These detection records are not sent over the network. The new cache is
  excluded from Android backup and device transfer.
- Existing Daylock v2 plans, history, routines, appearance and secure calendar
  credentials are not migrated or reset. The only new dependency is JUnit for
  Android unit tests; no Flutter dependency or extra runtime permission is added.
  `BIND_ACCESSIBILITY_SERVICE` protects the service declaration; Daylock does not
  request usage access, overlays, notification access or package-query permissions.

## Freedom snapshot contract

`MainApp` uses the existing pure `FreedomService` to prepare only dated eligibility
inputs: enabled setting, Freedom hour/minute, eligible/completed counts, correct
Today date, next-date commitment status and whether Focus is running. Excuses are
already excluded by the established progress calculation. Native code never marks
commitments completed, advances routines or writes planner data.

On app startup the old native snapshot is invalidated before loading planner data.
Each planner save invalidates it again. A replacement is published only after all
pending saves finish successfully. Failed loads/saves leave native eligibility
unknown; the existing Retry flow can restore it after a successful save. This cache
never changes the in-app Freedom rules, including neutral zero-eligible days.

Unchanged inputs refresh at most every **30 seconds** while Daylock is foregrounded;
changes publish after save, the Freedom Time boundary refreshes status immediately,
and background/resume force a refresh. Native code
stamps a successful snapshot with wall time, monotonic uptime, boot count, civil
date, time-zone ID and UTC offset. Delayed channel payloads older than **10 seconds**
(or from a future clock) are rejected instead of being restamped as fresh.

A native snapshot is valid for **less than five minutes**, and only if:

1. The boot count is known and unchanged; monotonic uptime has not reset.
2. Wall and monotonic ages are nonnegative and differ by at most two seconds.
3. Time-zone ID/offset and local date match the capture, and Today has the correct
   date. A DST offset change also invalidates the snapshot.
4. The native cache was successfully written and its schema/values are valid.

Time-set, time-zone and date broadcasts explicitly invalidate it while the process
is alive. Permission revocation also invalidates it. Per-read checks still apply
when Android delayed a broadcast or restarted the process. Reboot invalidates
without needing a boot permission/receiver. At five minutes it becomes **Unknown**,
even if previously earned or disabled. Reopening Daylock refreshes it.

For a fresh snapshot without running Focus, native code checks the current local
minute against Freedom Time, together with the cached commitment conditions. Thus
the time threshold can be reached while Flutter is backgrounded. Zero eligible
commitments remain not earned. An active Focus session reports **Unknown** until
Flutter reconciles and saves its timestamp-based completion; native detection does
not invent timer progress or completion. Disk/channel failures report unknown.

The **Freedom at that detection** label is a timestamped past result. It must not be
confused with **Current native Freedom snapshot**, which is reevaluated for freshness
when read. Five minutes is a conservative detection-stage cache contract, not an
authorisation design or guarantee for future enforcement; that stage must revisit
freshness, failure behaviour and physical-device results before blocking anything.

## Android 15 device verification

Use a full build/relaunch for Kotlin/manifest changes; hot reload cannot register
the native service. Keep the same public OAuth defines used for your working
calendar integrations. Do not uninstall or clear app data.

```powershell
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
flutter devices
flutter run -d 'ANDROID_DEVICE_ID' "--dart-define=GOOGLE_SERVER_CLIENT_ID=$daylockGoogleClientId" "--dart-define=MICROSOFT_CLIENT_ID=$daylockMicrosoftClientId"
```

Use your existing client-ID variables; no secret is needed. The debug APK built
during automated validation has no user OAuth defines. For device testing with
working calendars, rebuild/run with your existing defines rather than installing
that unconfigured validation APK. JAVA_HOME/PATH above affect only that terminal.

1. Open Today's gear → Settings → **Instagram detection · Test stage**. Initially
   it should show disabled and no detection unless a previous test was recorded.
2. Choose **Open Accessibility Settings**, read the disclosure and choose
   **Agree and open Settings**. This action does not enable the service itself.
3. In Android Accessibility → Downloaded/Installed apps (manufacturer labels vary),
   select **Daylock Instagram detection**, enable it manually and confirm Android's
   permission warning. You can disable it there at any time.
4. If a sideloaded Android 15 build is restricted, inspect Settings → Apps → Daylock
   → App info → more options → **Allow restricted settings**, if provided by your
   phone. Confirm only for this development build you trust. Some device/admin
   policies do not expose this option; do not bypass Android restrictions.
5. Return to Daylock and tap **Refresh status**. Verify **enabled and connected**.
   If it says waiting, let Android bind the service and refresh again.
6. Press Home, launch the official Instagram app, then return to Daylock Settings.
   Confirm that the latest detection time appears and **Freedom at that detection**
   matches the scenario below. Instagram should open normally every time.
7. Press Home and reopen Instagram after more than three seconds; verify another
   timestamp. Rapid repeated window events may be coalesced. Other apps must not
   update the Instagram detection record.

| Scenario | Expected recorded native result |
| --- | --- |
| Fresh snapshot; Freedom Control off | Control off |
| Before Freedom Time, unfinished eligible commitments, or tomorrow uncommitted | Not earned |
| After Freedom Time; all eligible Today commitments complete; tomorrow committed | Earned |
| Empty or all-excused Today | Not earned; no automatic unlock |
| Focus timer running while Flutter is backgrounded | Unknown until Flutter reconciles |
| Daylock left backgrounded over five minutes, then Instagram opened before returning | Unknown at detection; returning refreshes the current snapshot |
| Time/time-zone change or midnight while backgrounded | Unknown until refreshed |
| Android service disabled | Disabled; no new detection record |

Also swipe Daylock's activity from Recents, launch Instagram, and reopen Daylock to
verify the latest record survived without the Flutter UI. OEM battery/process
rules can stop or delay services; enabled alone is not a guarantee of delivery.
**Force-stop kills the whole app, including the service**; it is not a valid test of
ordinary Flutter background independence. After reboot, unlock the device, verify
Android's service setting and binding, and expect unknown eligibility until Daylock
refreshes. Detection applies only to the official package in the same Android
profile, not Instagram Lite, clones, web pages or another profile.

Physical verification is pending until these steps are run on the user's phone.
No enforcement, redirection or overlay implementation is included.

## Android and Google Play review before enforcement

Android requires the user to enable this service explicitly. Sideloaded apps can
be subject to Restricted Settings, and device policy/OEM limits can affect service
delivery. Respect these controls and revocation. See [Android restricted settings](https://support.google.com/android/answer/12623953?hl=en)
and [Android accessibility service documentation](https://developer.android.com/guide/topics/ui/accessibility/views/service).

Daylock is a productivity app, not an accessibility tool for people with
disabilities, so `isAccessibilityTool` is false. Google Play requires applicable
Accessibility API declaration/review, a specific prominent in-app disclosure and
affirmative consent for non-accessibility-tool use. Describe the exact background
detection, on-device data and purpose in the listing/privacy documentation and
complete the appropriate Data safety disclosures. This implementation does not
guarantee Play approval. See [Accessibility API policy](https://support.google.com/googleplay/android-developer/answer/10964491?hl=en)
and [prominent disclosure and consent](https://support.google.com/googleplay/android-developer/answer/11150561?hl=en).

Before any enforcement, reassess policy applicability and technical limits,
including rules against deceptive UI, circumventing privacy controls or preventing
users disabling/uninstalling services. Do not market this stage as blocking apps.
Native enforcement must remain a separate change after physical detection results
are verified.

## Automated validation

Flutter tests cover minimal Freedom payloads, excuses/empty days/running Focus,
ordered invalidation/publication, throttling, stream updates, revocation, native
errors, save/load failures, rollover, consent and narrow/large-text themed UI.
Kotlin JUnit tests cover the gate, repetition/restarts, eligibility, exact time and
expiry boundaries, reboot, clock/time-zone/DST/date invalidation and delayed inputs.

```powershell
flutter analyze
flutter test
# From android, using the terminal JAVA_HOME/PATH above:
.\gradlew.bat :app:testDebugUnitTest
# From the project root:
flutter build apk --debug
```

Automated tests and APK compilation do not verify Instagram's real Android 15
event delivery; use the physical checklist above before proceeding to enforcement.

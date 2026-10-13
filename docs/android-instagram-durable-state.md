# Durable native Instagram eligibility

The original Stage 2B detection, navigation and lock screen were verified on the
user's phone. The five-minute fail-open bug was also physically confirmed.
This update removes that dependency. **The updated build still needs physical
verification; automated results alone do not establish that the device bug is fixed.**

## State lifecycle

NativeFreedomState contains the minimum Freedom inputs: Control enabled,
Today date, Freedom hour/minute, eligible/completed counts, tomorrow committed,
and the UTC deadline for the single running Focus session, if any. Excuses are
already excluded by Flutter's established CommitmentProgress calculation.
NativePlanSummary adds tomorrow's date and counts for midnight reconciliation.
There are no task names, reasons, events, account details or credentials.

NativeFreedomRepository stores a versioned JSON record with those inputs, the
independent Instagram blocking setting and a monotonically increasing revision.
DetectionStore commits it as one nativeState preference in the existing private
daylock.instagram_detection.v1 file. The old blocking flag is mirrored in the
same editor commit for safe control recovery if the JSON becomes corrupt.
Android's built-in JSON implementation is used in production; JSON-java is a
JVM-test-only dependency so the same codec can be tested without Android stubs.

Startup and planner edits queue a native invalidation, marking eligibility unknown
while loading/saving. The existing planner-save flow is preserved. After all saves
succeed, MainApp publishes immutable dated counts through the serialized channel.
Goal completion/reset, excuses, Focus Start/Pause/completion, tomorrow commitment,
Freedom settings, resume and rollover all use this path.

Invalidation, publication and blocking changes each commit a new revision with the
entire record. Publication supplies expectedRevision from the latest acknowledged
native status. A stale publication is rejected without replacing newer data.
Older stream statuses cannot replace newer acknowledged state. Failed channel
publications clear deduplication so identical data can retry immediately.
Unchanged inputs, including nested tomorrow counts, are deduplicated. No thirty-
second heartbeat or five-minute lifetime is required.

The Accessibility service reads the latest in-process record on its serial worker
and rechecks the current clock and revision immediately before navigation. Durable
records are restored after service/process restart and reboot. No earned boolean,
capture-time authorization, boot-bound validity or TTL is persisted.

## Current-clock and date rules

Both controls and Accessibility must be enabled to restrict Instagram. With
Control disabled or Freedom earned, Instagram is allowed. Freedom uses the current
local device date/minute, at least one eligible Today commitment, all eligible
commitments completed, and tomorrow committed. Empty/all-excused days do not
automatically earn Freedom.

Current-day counts do not expire after 5, 30 or 120 minutes. Clock and timezone
changes reevaluate the local Freedom Time instead of discarding valid counts.
The existing broadcast receiver notifies observers on time/date/zone changes;
every Instagram window event independently checks the clock, even if Android
delays a broadcast. There is no alarm, WorkManager job, headless Flutter engine
or background polling loop.

At midnight, yesterday's counts cannot unlock Instagram:

- If the saved Today date matches the device date, evaluate those inputs.
- If the device date matches saved tomorrow, reconcile read-only from its actual
  saved counts. The following-day commitment flag is false. This matches Daylock's
  existing promotion of committed or uncommitted tomorrow plans.
- Report rollover_reconciled with the actual current plan date. Do not mutate
  Flutter's persisted plans or history. Opening Daylock performs its normal
  archive/rollover/save and publishes the new Today and Tomorrow.
- For multiple missed days or dates not represented by the two summaries, report
  unknown/date_changed. Never invent commitments, completion or history.

Month, year and leap-day boundaries use calendar components rather than elapsed
24-hour periods. Same-date timezone changes simply alter the current local minute;
changes to another date use the same reconciliation/recovery rules.

## Focus

The persisted UTC completion deadline includes the running session's start,
minimum duration and previously accumulated milliseconds. Native evaluation can
recognise that one commitment at its minimum without Flutter, including sessions
longer than five minutes and after reboot. It never double-counts or mutates a task.
The original date bounds the deadline; yesterday's session cannot complete work
for the next plan. Pauses, excuses and resets publish new counts/deadlines.
Flutter still owns actual accumulated time, outcomes and history, reconciling and
saving them on resume. Existing minimum-duration rules are unchanged.

## Recovery and user control

Missing, corrupted, failed-write or date-mismatched state is distinct from a valid
unearned day. InstagramRecoveryGate offers one branded recovery screen per
unresolved revision/date/reason in the service instance. It provides Open Daylock,
Disable Instagram blocking, Return to Home and Accessibility Settings.
Subsequent openings allow Instagram with a rate-limited reminder until state
changes. Recovery is deliberately escapable; it does not repeatedly redirect users.
A service/process restart can offer the unresolved prompt again.

The native Disable button works without Flutter. Disabling takes effect for the
current service even if writing fails; the failure message explains revoking
Accessibility as an independent escape. Failed writes cannot be guaranteed to
survive restart. Never interpret a failed preference write as safely persisted.
Permission revocation prevents all service navigation. Users can uninstall freely.

Home/navigation and Android 15 background-launch handling remain from Stage 2B.
If Home fails, no lock activity is launched. If the activity is denied or no first
draw is acknowledged, Settings reports the unconfirmed launch; there is no retry
loop or action against another app. Full-screen official Instagram window events
are the supported scope; split-screen, clones, Lite, web and other profiles are not.
Android service delivery/OEM restrictions and force-stop remain platform limits.
See [Android background launches](https://developer.android.com/guide/components/activities/secure-bal).

## Compatibility

Old expiring native snapshot records are not silently trusted indefinitely. Their
blocking preference is preserved; one normal Daylock launch publishes the new
durable record. Old native JSON need not be deleted. Malformed native data remains
unknown until a successful explicit synchronisation/invalidation/control change.

There is no planner migration or reset. Plans, historical snapshots, accumulated
Focus time, routines, events, provider caches, OAuth tokens and appearance settings
retain their existing storage formats. The app ID and signing are unchanged.
Native preferences remain excluded from backup/device transfer. Only the latest
detection/restriction is retained; there is no browsing history or transmission.
Accessibility disclosure, consent and revocation controls remain. Play distribution
still requires review against [Accessibility API policy](https://support.google.com/googleplay/android-developer/answer/10964491?hl=en).

## Physical-device acceptance checklist

Use a full rebuild/relaunch with the same existing public OAuth defines. Do not
uninstall, clear storage, use development-reset flags or corrupt real planner data.
From the Daylock directory, with your existing client-ID variables:

    $env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
    $env:Path = "$env:JAVA_HOME\bin;$env:Path"
    flutter run "--dart-define=GOOGLE_SERVER_CLIENT_ID=$daylockGoogleClientId" "--dart-define=MICROSOFT_CLIENT_ID=$daylockMicrosoftClientId"

The automated APK is compiled without user OAuth defines; use this configured
launch to preserve working calendar configuration. Session Java settings do not
modify system settings.

1. Confirm data/theme/calendar accounts are intact. Confirm Accessibility is
   enabled and connected, and both Freedom Control and Block Instagram are enabled.
2. Leave an eligible Today task unfinished and background Daylock. Open Instagram
   immediately, then after 5, 30 and 120 minutes without reopening Flutter.
   Use Return to Home from the native lock screen between checks. Each must restrict.
3. Repeat with Freedom earned: each opening must be allowed. Independently test
   time not reached, unfinished commitments and tomorrow uncommitted.
4. With other conditions satisfied, cross Freedom Time while Flutter stays closed:
   restrict before the boundary, allow afterward.
5. Start a Focus session longer than five minutes. Check before/after its minimum
   and resume Daylock to verify actual time and outcome still persist correctly.
6. Test normal process/service restart and same-day reboot before reopening Daylock.
   A valid dated state must still decide correctly. Force-stop kills the service
   and is different from swiping the Flutter activity from Recents.
7. Let normal local midnight occur while Flutter is backgrounded. Yesterday's
   earned state must not unlock. Expect tomorrow's saved counts and the new
   following-day commitment unmet. Open Daylock and verify real rollover/history.
8. Turn either control off: Instagram must open. Revoke Accessibility: no navigation.
   Verify recovery's Open Daylock and native Disable controls, repeated openings,
   Back/Home, other apps, large text and selected palette.
9. Automated tests cover corruption, missed dates, leap boundaries and timezone
   changes. Avoid jumping your real device date to simulate rollover: that
   legitimately archives actual plans. Use an isolated emulator/test install for
   destructive fault injection; never reset this user's existing installation.
10. If only Home appears, inspect the unconfirmed-launch message. Record which
    checks passed/failed on the physical phone before calling this fix verified.

## Automated checks

Flutter tests cover payload privacy/immutability, excuses, Focus deadlines,
revision ordering/retry, background lifecycle after 5/30/120 minutes, real resume
rollover/history, existing controls and theme/accessibility rendering.
Kotlin tests cover durable decisions, time/zone/date rules, boot/service restart,
JSON corruption and compatibility, atomic revisions, rejection of older state,
failed writes, midnight projections and bounded recovery. They do not prove actual
Android/OEM navigation or background service delivery.

    flutter analyze
    flutter test
    # android directory, with session JAVA_HOME:
    .\gradlew.bat :app:testDebugUnitTest
    # project root:
    flutter build apk --debug

Run build/native checks sequentially with other Flutter commands on Windows to
avoid competing writes to Flutter's generated asset directory.

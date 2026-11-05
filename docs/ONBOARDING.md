# First-launch setup

The Android `main()` entry point enables six setup screens. Planner embeds and
visual fixtures can continue to instantiate `MainApp` directly. Other platforms
can replay the tutorial in Settings; blocking and installed-app selection are
explicitly unavailable there.

Progress is stored as `daylock.onboarding.v2` using the existing
`SharedPreferencesAsync` instance in `LocalStorage`. Values 0–5 resume a screen;
6 means completed. Before the first planner save, new Android installations save
step 0. Existing planner data and the old v1 completion/migration marker no longer
skip the revised tutorial: every Android installation sees it automatically on
its first launch of this version. Subsequent launches resume progress until step
6 has been saved. Completed v2 setup does not repeat. This intentional one-time
upgrade prompt follows the user's request to show setup automatically.
Replay resets only this progress key. Leaving setup keeps its last saved step.
Storage failures show a retry message and never mark completion.

## Existing integrations

- Accessibility: reuses `InstagramDetectionSection.explainAndOpen`, including its
  disclosure and affirmative consent. Native code tries the component-specific
  settings action, with the general Accessibility screen as a fallback.
- Notifications: reuses the notification service's native permission request,
  status and settings methods. Optional: denial never blocks setup.
- Xiaomi / Redmi / Poco: the permission step shows a background-blocking card
  based on Android's manufacturer/brand. It opens App info for the runtime
  application ID and directs users to Power > No restrictions. A required
  checkbox records the user's confirmation separately as
  `daylock.onboarding.v2.power-reviewed`. This is explicitly not automatic
  verification of the proprietary setting. The confirmation survives interruption
  and app updates. Other manufacturers do not see this step. No exemption
  permission is requested and no battery setting is changed automatically.
- App selection: reuses `RestrictedAppsSection` and native durable selections.
  The tutorial explicitly explains that enabling restrictions also enables
  Freedom Control at the user's saved time.
- Goals: reuses `CommitmentEditor`, `Task`, the actual tomorrow plan and the
  existing planner save path. Today's committed plan stays locked. The callback
  rechecks plan identity and commitment after the editor returns. Existing goals
  satisfy this step without inserting duplicates.
- Test: a user tap requests `testRestrictedApp` on the existing channel. Native
  code validates the selected installed app, enabled/bound service, and existing
  Freedom BLOCK decision, clears historical presentation evidence, and opens the
  app normally. Accessibility performs the same restriction as any other app
  opening. There is no artificial lock screen or simulated Freedom result.

Only a fresh detection of that tested package plus `lock_shown` and `shown`
visibility evidence unlocks Finish Setup on Android. A launch request, Home
action or fallback notification alone is not reported as a verified lock screen.
Permissions and selection are rechecked before completion. Interrupted tests
resume the test step and must run again. Permission changes refresh on resume.

## Platform limits

Android alone controls granting Accessibility and notification access, service
binding, restricted settings, and background activity launches. The user must
enable Accessibility manually. Manufacturer settings screens may fall back to
the general list; choose the service belonging to the installed variant
(`Daylock Dev app restrictions` for debug).

If Freedom is already earned, the real blocker allows the app. Setup explains
this instead of overriding eligibility. Save & leave remains available; rerun
from Settings when Freedom is not earned. A missing lock screen produces
troubleshooting guidance and retry, never a false success. No additional Android
permissions, battery exemptions, packages or release-signing changes are added.

## Manual device checklist

1. Use a fresh test installation/profile (do not clear an existing user's data).
   Confirm welcome appears automatically. Existing installations, including ones
   with an old v1 marker, should also open the revised tutorial once. Confirm
   all existing plans and selected restricted apps survive.
2. Get Started, leave midway, close/reopen the app: it resumes the saved step.
   Test system Back, Save & leave, small screens and large accessibility text.
3. Review the Accessibility disclosure. Cancel should not open settings; Agree
   should. Return with access disabled, enabled but disconnected, then connected.
   Continue should require a real connection. Test notification grant and denial.
   On Xiaomi / Redmi / Poco, check the No restrictions guidance, app-specific
   App info shortcut and durable user confirmation. Merely opening App info must
   not count as confirmation. On Samsung/Pixel, the Xiaomi card must not appear.
4. Pick two launchable apps. Search by name, inspect icons, leave and restart.
   Choices should persist. Verify app restrictions and Freedom Control are on.
5. Create a commitment: verify it appears in tomorrow's actual Plan. Replaying
   must not duplicate it. A committed tomorrow plan must reject another insert
   and retain its existing commitments.
6. With Freedom not earned, test the selected app. Check the real branded lock
   screen, return to the tutorial, and confirm verification. Try a failed launch
   or disconnected service: Finish Setup must remain disabled; retry should work.
7. Finish, Go to Daylock, reopen: Today should appear without onboarding. Check
   the existing Today, Plan, Journey, notification and Freedom features.
8. Repeat permission-return and blocking tests on Pixel Android 13–15, Samsung
   One UI and Xiaomi HyperOS. Physical compatibility remains pending until these
   steps are performed; JVM/widget tests cannot prove OEM settings behavior.

# Earned breaks

The lock screen offers one deliberate way past it each day, so blocking stays honest without becoming a trap.

1. On the lock screen, tap **Take a 15-minute break**. It only appears while the app is actually blocked.
2. Wait 60 seconds. Leaving the screen starts the wait over, because the lock screen closes when it's hidden.
3. Type why you need the app (3 to 200 characters), then tap **Start 15-minute break**.
4. The app opens for 15 minutes. One break per local day. After that, the lock screen says today's break is used.

## Rules (`BreakPolicy`)

- **Time left** uses the monotonic clock within one boot, so changing the phone's clock can't stretch a break. After a reboot it falls back to the wall clock, capped at 15 minutes.
- **The log** keeps the latest 60 breaks in native preferences (`breaks.v1`), which are excluded from backup like the rest of the detection state. Flutter receives the latest 30 in the detection status and shows the last 30 days in Journey → Breaks, with each reason.
- **During a break**, the Accessibility service lets the app through and records `skipped_break_active`. When the break ends it re-checks the foreground app as a new visit, so someone still in the app is locked again.
- **Turning off app restrictions** in the lock screen's Other actions is unchanged and still always available.

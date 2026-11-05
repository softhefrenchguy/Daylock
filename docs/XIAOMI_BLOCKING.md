# Xiaomi / HyperOS background blocking

## Confirmed on the connected Poco, 5 November 2026

The AccessibilityService was enabled and bound, Instagram was selected,
restrictions were on, and native Freedom was not earned. Launching Instagram
while Daylock was visible could show the lock screen. Reopening it after Daylock
had been in the background failed.

Debug logging compared AccessibilityEvent.eventTime with SystemClock.uptimeMillis.
An Instagram window event arrived **42,193 ms late**, only when Daylock returned
to the foreground. Other queued launcher events then cancelled its foreground
token, producing `skipped_foreground_changed_before_eligibility`. Xiaomi SmartPower
logs showed Daylock entering idle after approximately three seconds. The service
remained bound: this was not a missing Accessibility grant or a package mismatch.

The phone's Daylock Dev App info > Power screen showed **Battery saver
(recommended)** selected. Changing only this app to **No restrictions** restored
timely event delivery: a normal Instagram launch after eight seconds in the
background arrived after 102 ms and the existing native lock screen was confirmed
resumed, drawn, focused and visible. This is evidence for this Poco configuration;
it is not a guarantee for every Xiaomi firmware.

## User setup

On affected Xiaomi / Redmi / Poco devices, open Android Settings > Apps >
Daylock > Power (or Battery saver), then select **No restrictions**. Settings
names vary. Apply it to the actual installed app: Daylock Dev and the official
Daylock have separate settings. Existing plans and selections are preserved.

No new Android permission, foreground service, automatic exemption request,
overlay, screen-content access, or keep-alive loop was added. The app cannot
promise immediate blocking while the OS withholds its Accessibility callbacks.

## Code safeguards and diagnostics

- Debug event logging includes event age, before pane filtering, to distinguish
  late callbacks from detection/filtering failures.
- Window events more than five seconds old, negative timestamps, and future
  timestamps cannot authorize navigation. Selected-app delays are reported as
  `skipped_event_delayed`, with Xiaomi battery-setting guidance in Diagnostics.
- Delayed events do not clear or replace a newer foreground session.
- The onboarding test explains that one successful opening does not prove
  reliable background delivery. Users should also reopen the selected app from
  Home after leaving Daylock in the background.
- The existing selection, Freedom decision, launch throttle and visible-screen
  confirmation remain in use.

## Repeatable manual verification

1. Enable this installed app's Accessibility service and select Instagram.
2. Confirm restrictions and Freedom Control are on and Freedom is not earned.
3. With No restrictions selected, leave Daylock for Home for at least 10 seconds.
4. Open Instagram normally, without the tutorial test button. Confirm Daylock's
   branded lock screen actually appears.
5. Repeat from Home and Recent Apps, after a longer background interval and after
   screen lock/unlock. Check that Settings, unselected apps and Home stay usable.
6. Repeat after a service rebind/reboot and on the official release variant.
   Battery choices are package-specific and must not be assumed to transfer from
   Dev to Play. Other Xiaomi firmware and other manufacturers need their own
   verification.

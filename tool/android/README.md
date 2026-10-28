# Native lock screen visual fixture

`LockScreenPreviewActivity.kt` is an optional, debug-only visual entry point for a dedicated emulator. It is outside Android source sets and is not included in normal debug/release builds.

1. On a disposable emulator, install Daylock, configure Freedom and Instagram blocking through the app, and enable its Accessibility service. The fixture does not change these settings or seed data.
2. Temporarily copy the file to `android/app/src/debug/kotlin/com/example/daylock/`. Add an Activity entry in the debug manifest's application element: `<activity android:name=".LockScreenPreviewActivity" android:exported="true" />`.
3. Build/install a debug APK with `lib/main.dart`. Start `adb shell am start -n com.example.daylock/.LockScreenPreviewActivity`.
4. Capture with `adb shell screencap -p /sdcard/daylock-lock.png`, then `adb pull /sdcard/daylock-lock.png`. Exercise the real screen's actions. Wait at least three seconds between launches for the existing cooldown.
5. Remove the copied Activity and restore the debug manifest before normal builds. Never copy this fixture into `src/main`.

This starts the real Activity from a foreground Activity with a valid presentation attempt. It exercises native rendering, current persisted eligibility, palette and actions. It does not test Instagram package detection, background activity launch restrictions or fallback timing. UI Automator may temporarily suppress accessibility services during inspection; reconnect before capturing a blocked state.

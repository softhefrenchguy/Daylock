# Google Calendar setup

The Android reader is implemented, but real sign-in cannot be tested until you
create OAuth clients in a Google Cloud project you control. No real client IDs
or secrets are included. Microsoft uses a separate
[Entra setup guide](microsoft_calendar_setup.md); include both providers' Dart
defines when launching with both enabled.

## Create the Google Cloud configuration

1. Create/select a project in [Google Cloud Console](https://console.cloud.google.com/).
   Enable **Google Calendar API** under **APIs & Services → Library**.
2. Configure **Google Auth Platform**: Branding (Daylock, support/contact email),
   Audience (**External** for personal/multiple Google accounts), and Data Access.
   During development, keep the audience in **Testing** and add every Google
   account you intend to connect as a test user. Workspace administrators may
   restrict access independently.
3. Add these two read-only Data Access scopes:

   ```text
   https://www.googleapis.com/auth/calendar.calendarlist.readonly
   https://www.googleapis.com/auth/calendar.events.readonly
   ```

   Native sign-in also obtains basic identity information. Calendar write scopes
   are not requested. See [Google's scope reference](https://developers.google.com/workspace/calendar/api/auth).
4. Under **Clients**, create an **Android** OAuth client with:
   - Package name: `com.example.daylock` (the app's existing application ID).
   - SHA-1 of the certificate signing your APK. With Java configured, run
     the following from the Android directory and copy the debug variant's SHA-1:

     ./gradlew signingReport

     On Windows use ./gradlew.bat signingReport. Each developer machine, release
     certificate and Play App Signing certificate needs its own matching
     registration. Do not generate or commit a signing key for OAuth setup, and
     do not change the package name; that would create a different installation.
5. In the **same project**, create a **Web application** OAuth client. Copy its
   **client ID** ending in `.apps.googleusercontent.com`. The Android SDK calls
   this `serverClientId`; this implementation does not run a backend. No custom
   redirect URI, JavaScript origin, Firebase setup or `google-services.json` is
   needed for this native flow. Do not copy the Web client's secret into Daylock.
   This follows [the official Android plugin setup](https://pub.dev/packages/google_sign_in_android).

**Stop here until you have created those OAuth clients.** Only the public Web
client ID is needed to configure the app; the Android registration is matched
by package and signing certificate. Never provide a client secret or access token.

## Run once your clients exist

Replace the placeholder with your actual **Web** client ID, then do a full run
on an Android device/emulator with Google Play Services:

```sh
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

On this Windows machine, Flutter is installed at
`<FLUTTER_SDK>\bin\flutter.bat`. From the Daylock project
root, use PowerShell to enter the **complete public Web client ID** for this
session without saving its value in the repository:

```powershell
flutter devices
$daylockGoogleClientId = Read-Host 'Paste your complete Web OAuth client ID'
flutter run -d 'ANDROID_DEVICE_ID' "--dart-define=GOOGLE_SERVER_CLIENT_ID=$daylockGoogleClientId"
```

Replace `ANDROID_DEVICE_ID` with the Android device ID printed by `devices`.
If none appears, connect a phone with USB debugging enabled or start an Android
emulator with Google Play Services, then run `devices` again. Use the Web client's
ID, including its `.apps.googleusercontent.com` suffix, rather than the Android
client ID. This variable exists only in the current PowerShell session; launch
with the define each time. No client secret is used.

Include the same define when building an APK. A full restart/build is required
after changing the define. Without a valid-looking ID, Google connection stays
disabled and all local Daylock functionality continues to work.

Open **Calendar → Calendar accounts → Connect Google Calendar**. Select an
account and grant both read-only permissions, then choose **Sync now**. Repeat
Connect for additional accounts. Calendar checkboxes control which calendars
appear in Calendar and tomorrow's Plan; hiding a calendar retains its cache.

Sync is manual and covers the previous 30 days plus today and the next 90 days.
Previously cached events outside that range remain available but may be stale;
selecting a date does not issue a network request. Recurring instances are
expanded within the sync window. An account's complete successful sync is saved
as one cache snapshot; failed pages never replace it with partial data.

If Google permissions expire or are removed, the cache stays available. Choose
**Reconnect**, select the same account, grant permission and **Sync now** again.
Choosing a different account during reconnect cannot replace the original account.
Testing-mode grants can expire; see [Google's OAuth app-state documentation](https://developers.google.com/identity/protocols/oauth2/production-readiness/overview).
Public distribution using sensitive scopes can require Google's verification.

Disconnect removes that account's Daylock credentials and cached events. It does
not delete Google events or revoke other connected accounts' grants. To revoke
Google's consent grant, use your Google Account's third-party access settings.

## Authentication and time handling

`google_sign_in` installs Google's native Credential Manager/authorization SDK.
Daylock uses its public platform interface to request authorization for a saved
account's stable ID and email, including after restart. This Android-only reader
never relies on the last signed-in user when syncing a different account.
Interactive authorization occurs only on Connect/Reconnect; sync refresh is silent.
Google Play Services handles renewal, without a client-side refresh token or
server auth code. The acquired access token is stored only in the existing
Keystore-backed `CalendarCredentialStore`. It is reacquired per account at sync
start; a 401 invalidates the native cached token and retries once with a renewed
token. Tokens never enter the planner JSON or error text.

The API is queried with `singleEvents=true`, `showDeleted=true`, UTC timed
responses and calendar-date window boundaries. Every calendar/event page must
succeed. Occurrence IDs, scoped by account and calendar, prevent duplicates.
Cancellation tombstones and complete-window reconciliation remove deleted/moved
instances. See [Google's event-list API](https://developers.google.com/workspace/calendar/api/v3/reference/events/list).

Timed events preserve exact UTC instants and display in the device's current
local zone. All-day date ranges preserve their original calendar dates and
exclusive ends. Explicit IANA wall times are resolved with `timezone`; ambiguous,
nonexistent or unzoned times fail safely rather than inventing a time. Calendar
time-zone metadata is optional, so old persisted calendars remain readable.

## Verify on your device

Automated tests cover native SDK contracts with a fake platform and Calendar HTTP
fixtures. They cannot validate your Cloud registrations, real consent screens,
Google Play Services or on-device secure storage. After configuration, check:

- Two Google accounts, including syncing the first after connecting/restarting
  with the second, and each account's separate calendar visibility.
- A recurring event, an edited occurrence, a cancelled occurrence, an all-day
  event, and an event spanning midnight or a DST change.
- Kill/reopen offline: cached events still appear and Today/Plan commitments are
  unchanged. Reconnect after removing Daylock's permission in your Google account.
- Disconnect one account: other accounts and local events remain available.

If sign-in repeatedly appears to cancel after selecting an account, check the
package, SHA-1 and Web client ID first. The native SDK can report configuration
errors as cancellation; [the plugin's troubleshooting guide](https://pub.dev/packages/google_sign_in_android#troubleshooting)
explains this limitation.

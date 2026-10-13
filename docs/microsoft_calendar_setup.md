# Microsoft Calendar setup

Daylock now has a read-only Microsoft Graph reader for personal Microsoft accounts
and Microsoft work/school accounts. Real sign-in requires an app registration you
control. No real Microsoft client ID or client secret is included in the project.
Your existing Google Cloud configuration remains separate.

## Register Daylock in Microsoft Entra

1. Open [Microsoft Entra admin center](https://entra.microsoft.com/) and select
   **App registrations > New registration**. Register **Daylock** with supported
   account types **Accounts in any organizational directory (Any Microsoft Entra
   ID tenant - Multitenant) and personal Microsoft accounts**. This corresponds
   to `AzureADandPersonalMicrosoftAccount`. A single-tenant or organizations-only
   registration cannot serve both account categories.
2. Copy the **Application (client) ID** from Overview. This public GUID is the
   only Microsoft configuration value passed to Flutter. Do not use the Object
   ID or Directory (tenant) ID as the client ID.
3. Under **Authentication**, add a **Mobile and desktop applications** platform
   (the portal may label this **Add Redirect URI**). Enter this exact custom URI:

   ```text
   com.example.daylock.microsoft://oauth/redirect
   ```

   Save it as a native/public-client redirect, preserving the scheme, host, path
   and casing. Leave implicit access-token and ID-token grant checkboxes disabled.
   Do not register this callback as a Web or SPA redirect. Under Authentication's
   advanced settings, set **Allow public client flows** to **Yes** and save.
   Daylock uses authorization code with S256 PKCE; it never uses a password or
   device-code grant. See Microsoft's
   [redirect platform instructions](https://learn.microsoft.com/en-us/entra/identity-platform/how-to-add-redirect-uri)
   and [public-client configuration](https://learn.microsoft.com/en-us/entra/identity-platform/scenario-mobile-app-configuration).
4. Under **API permissions > Add a permission > Microsoft Graph > Delegated
   permissions**, configure `Calendars.Read`. Daylock also requests `openid`,
   `profile`, `email`, and `offline_access` for sign-in identity and silent refresh;
   these may be listed under OpenId permissions. Remove the registration's default
   `User.Read` permission if present: Daylock obtains identity from the sign-in
   ID token and does not call Graph's user-profile endpoint. Do not add application
   permissions, calendar write permissions, or `OnlineMeetings.Read`. Teams links
   are read from calendar events. The read API supports delegated personal and
   organizational permissions; see [calendarView](https://learn.microsoft.com/en-us/graph/api/calendar-list-calendarview?view=graph-rest-1.0).
5. Supply consent normally during sign-in. Some organizations require an
   administrator to approve the application or grant tenant-wide delegated
   consent. Their policies still apply even though the registration is multitenant.
   Configure branding/publisher information honestly; public distribution and
   tenants that restrict unverified publishers may require further verification.
   Do not create a client secret for this Android public client.

The actual Android package/application ID is **`com.example.daylock`**, unchanged.
This implementation uses `flutter_appauth` and Android AppAuth's system-browser
callback. Microsoft's **Android** platform tile and its
`msauth://package/signature-hash` redirect are for MSAL/broker configuration;
they are not the configuration for this reader. **No signing certificate hash
is required for the chosen custom native redirect.** Existing signing keys and
Google's package/SHA-1 registration remain unchanged.

## Launch on your phone

Rebuild and fully restart after adding the native dependency or changing Dart
defines. Hot reload cannot configure either OAuth client. From the project root:

```powershell
flutter devices
$daylockMicrosoftClientId = Read-Host 'Paste the Entra Application (client) ID'
$daylockGoogleClientId = Read-Host 'Paste your existing Google Web client ID'
flutter run -d 'ANDROID_DEVICE_ID' "--dart-define=MICROSOFT_CLIENT_ID=$daylockMicrosoftClientId" "--dart-define=GOOGLE_SERVER_CLIENT_ID=$daylockGoogleClientId"
```

Replace `ANDROID_DEVICE_ID` with the device ID printed by `devices`. Include both
public client IDs on each run/build to keep both providers enabled. Neither value
needs to be committed to the repository; neither is a client secret. Missing or
malformed Microsoft configuration leaves both Microsoft connect buttons disabled
while preserving local functionality and saved caches.

Open **Calendar > Calendar accounts**. Use **Connect Microsoft Personal** for
Outlook.com/Hotmail/Live or **Connect Microsoft Work/School** for organizational
accounts. Select an account in the browser and consent, then choose **Sync now**
for that account. Repeat Connect to add more accounts. Personal sign-in uses
`consumers`; work/school initially uses `organizations` and subsequently refreshes
and reconnects against that account's saved tenant. Calendar checkboxes control
visibility in both Calendar and tomorrow's Plan without deleting the cache.

## How the integration works

`NativeMicrosoftCalendarAuth` uses
[flutter_appauth](https://pub.dev/packages/flutter_appauth) for system-browser
authorization, state/nonce, PKCE and HTTPS code exchange. It treats Graph access
tokens as opaque and reads account identity from the successful exchange's ID
token, supplementing native audience/expiry/nonce checks with issuer and tenant
checks. Stable account keys include provider, object ID and tenant; refresh never
depends on the browser's last selected account. Each account's access token,
refresh token and expiry use the existing Keystore-backed credential store.
Rotated refresh tokens are saved before using the new access token. Credentials
never enter `DaylockState`, planner JSON, source code or user-facing errors.

`MicrosoftCalendarProvider` serves both account categories. It reads `/me/calendars`
and each calendar's `calendarView`, collecting all pages before publishing a
complete snapshot. Graph expands recurring occurrences and exceptions. Immutable
event IDs are scoped by account/calendar; complete-window reconciliation handles
cancelled/deleted/moved events without duplicates. Pagination cannot send tokens
to another origin or account route. The shared `CalendarService` continues to
own visibility, reconciliation and local disconnect. No Event, DailyPlan or
storage-schema migration changes were needed; existing saves retain their format.

Timed events request UTC responses and store exact instants for device-zone
display. For all-day events, the reader requests details in the event's original
Windows/IANA zone when necessary, letting Graph perform the conversion and keeping
original calendar dates and exclusive end dates. The Graph query has a two-day
padding at each end to cover opposing device/event time zones; the returned
snapshot is filtered to the actual Daylock date window. Unsupported legacy custom
zones or incomplete/malformed responses fail the sync and preserve the old cache.
Teams join URLs and plain-text note previews use the existing read-only details.

Sync remains manual, covering the previous 30 days, today and the next 90 days.
Tokens refresh silently near expiry, and a Graph 401 forces one renewal/retry for
that account. Revocation requires **Reconnect** using the same account and tenant;
selecting another account cannot overwrite it. Offline/network failures, denied
permissions, throttling and incomplete pages preserve cached events. Daylock does
not retry indefinitely or show raw provider diagnostics. Work/school accounts
need an accessible Exchange mailbox; a Teams login alone does not guarantee one.

Browser sign-in supports the tenant's permitted MFA flows. This reader does not
implement MSAL broker/device-compliance integration. An organization requiring
Authenticator broker or device-bound conditional access can deny sign-in; ask
its administrator about application approval and permitted clients. Daylock
cannot bypass those policies. Disconnect removes only that account's local cache
and credentials; it neither signs other accounts out of the browser nor deletes
provider events or revokes the tenant's consent grant.

## Verify on your device

Automated tests use a fake native OAuth bridge and Graph responses. They cannot
verify a real Entra registration, browser callback, organizational policy or
on-device secure storage. After configuring your registration, check:

- Two personal accounts and a work/school account alongside the existing Google
  connection; sync each again after restarting the app.
- Multiple calendars, independent visibility, a recurring/edited/cancelled meeting,
  all-day and multi-day events, midnight/DST boundaries and a Teams meeting URL.
- Kill/reopen offline: schedules remain visible, while Goal/Focus completion and
  committed-plan locking remain unchanged. External events have no edit/delete.
- Revoke permission, then sync and reconnect the same account; failed consent or
  organizational restrictions should leave the previous events available.
- Disconnect one Microsoft account: other accounts, local events and commitments
  remain intact.

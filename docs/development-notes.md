# Development notes

Detailed implementation notes preserved from the original README. Start with the
repository README for setup; dated Stage 2A/2B guides describe historical builds.

# daylock

A local commitment planner. Fresh installs start with empty Today and Tomorrow plans.

## Design preview

Daylock uses **Bold Discipline**: strong Android Roboto typography, subtle tinted
backgrounds and restrained accents. New users start with **Dark + Violet**, keeping
the `#171321` background and `#A78BDB` highlight. Tap the gear in Today's header to
open **Settings**, then choose **Dark**, **Light** or **System** and one of **Violet,
Ocean, Forest, Ember, Rose or Mono**. Each palette has coordinated dark/light
backgrounds, surfaces, borders, accents, controls and status colours. System mode
follows device appearance changes while open; explicit Dark/Light ignore them.
The small preview updates immediately along with the whole app. Use Android's
Back action to return to Today; the three-tab navigation is unchanged.

Today has a dated heading, animated commitment progress, divided Goal rows and
Focus rows with elapsed seconds, duration progress and a large Start/Pause control.
Empty, completed and loading/error states are explicit. Freedom shows a live
eligibility checklist using the time chosen in Settings. Optional Instagram
blocking is configured separately in Settings and is off by default. Calendar uses
the same theme system for its
monthly commitment heatmap and event viewer.

Plan uses a compact heading and one tomorrow date. A timeline-style schedule comes
first so appointments inform planning; labels identify providers without account
emails. Commitments use compact divided rows with Goal/Focus icons, Focus minimum
minutes and optional text targets, without repeated type subtitles. Both lists
render lazily as you scroll. **+ Add commitment** opens a scrollable bottom sheet
with the existing Goal/Focus fields and validation. Keyboard insets keep its fields
and submit action above the Android keyboard; closing it discards unfinished input.
Adding closes the sheet and displays the new commitment without a snackbar covering
the bottom controls.

A persistent weekday-specific Commit bar sits above navigation and reserves its
own layout space. Commit asks for confirmation before locking. Committed plans
replace the action with a compact locked confirmation; there is no unlock control.
Rollover dismisses open editors/dialogs and rejects their stale callbacks. Task
editing/deletion was not supported before this redesign and has not been added.
Existing validation and state ownership are unchanged. Plan supports 320px screens
and up to 300% text, stacking the type selector where necessary. The footer itself
can scroll when keyboard/text settings leave very little height. It inherits the
shared loading/error flow and introduces no storage fields or packages.

`lib/design/daylock_palette.dart` is the central colour configuration for all twelve
variants. Standard semantic roles use Flutter's `ColorScheme`; extra Focus/Freedom
roles use the `DaylockColors` theme extension, including interpolation during theme
changes. `daylock_theme.dart` builds/caches themes and holds typography, spacing and
control styles. `daylock_widgets.dart` supplies labels, actions, progress and loading/error
presentation. `daylock_task_row.dart` presents Today commitments using the existing
callbacks; `daylock_plan_rows.dart` presents non-interactive planning requirements
and scheduled events. No font package or new dependency is required. Completion and
progress animations respect the system's reduced-motion setting. The layout is
scrollable and tested at 320px width with up to 200% text scaling. Settings adapts
its appearance controls and palette grid to larger text rather than shrinking it.

`AppearancePreferences` is an immutable mode/colour selection. `MainApp` owns a
small built-in `ValueNotifier` so both the app theme and the open Settings route
update together. `AppearanceStorage` saves only `daylock.appearance.v1` using the
existing preferences package, with ordered writes so rapid choices persist in
the correct order. It never rewrites planner snapshots or touches credentials.
Absent/unsupported/malformed appearance preferences safely use Dark/Violet;
malformed values are left intact until a new choice is saved. Storage failures
leave plans usable and show a Retry action when saving fails. The existing
development planner-data reset retains appearance preferences.

Run on your Android phone with your existing OAuth defines:

```powershell
flutter run -d 'ANDROID_DEVICE_ID' "--dart-define=GOOGLE_SERVER_CLIENT_ID=$daylockGoogleClientId" "--dart-define=MICROSOFT_CLIENT_ID=$daylockMicrosoftClientId"
```

Use your existing public client-ID session variables (see the provider setup
guides below). Existing saved commitments provide the normal preview data;
automated rendering fixtures never seed or reset the installed app.

## Android Instagram control (Stage 2B)

The original Stage 2B navigation was verified on the user's phone, where a
five-minute expiry bug was confirmed. Native eligibility now uses durable dated
inputs and atomic revisions, without an age timeout or Flutter heartbeat.
Block Instagram remains separate from Freedom Control and off by default.
Native code checks the current local time, date, eligible/completed counts and
next-day commitment on each opening, including after service restart/reboot.

Midnight reconciles read-only from the saved tomorrow summary; yesterday cannot
unlock the new day. Flutter still owns real rollover and historical writes.
Missing/corrupt/unrepresented dates offer a bounded recovery screen with Open
Daylock and Disable Blocking, then allow reopening rather than trap the user.
Android background-launch restrictions can still leave only Home, with truthful
status reporting. There are no planner/OAuth/storage resets or new permissions.

See [durable state lifecycle, migration and physical checklist](docs/android-instagram-durable-state.md).
The updated build requires 5/30/120-minute and midnight verification on the phone;
automated results alone do not establish the physical bug is fixed.
The original [Stage 2B](docs/android-instagram-blocking.md) and
[Stage 2A](docs/android-instagram-detection.md) guides are historical references.

## Freedom foundation and routines

Open **Settings → Freedom** to enable Freedom Control and choose a local Freedom
Time. Control is **off by default**, with **18:00** suggested. Today shows each
condition: time reached, all eligible Today commitments completed, and a committed
plan for the next calendar date. Excused commitments are excluded, never counted as
completed. An empty or all-excused day cannot earn Freedom and explains that there
are no eligible commitments. Completing tasks early alone does not earn Freedom.
No eligibility result is cached permanently; the pure `FreedomService` calculates
it from the current clock, settings and dated plans on each refresh.

`MainApp` checks the local clock every second while foregrounded, including when no
Focus timer runs, and immediately on resume or task/plan changes. Clock edits and
time-zone changes therefore refresh the status; moving to a new local date also
uses the existing rollover/history rules. Clock refreshes do not write storage
unless a timer completes or rollover changes a plan. Backward date changes preserve
existing data under the existing rollover policy: a mismatched Today date is
explicitly ineligible until it matches the local date. Instagram restriction is
separately opt-in; see the native control section above. No other apps are blocked.

Open **Settings → Routines → Create routine** to name an ordered sequence of Goal
or Focus steps. The step editor reuses Plan's name/duration validation; Focus steps
retain their minimum minutes and optional text target. Steps can be edited,
reordered or removed. A saved routine must have a name and at least one valid step.
Plan has a compact, initially collapsed **Routine suggestions** section near its
header. Each routine offers **one step per tomorrow planning date**:

- **Accept** adds an ordinary incomplete commitment to tomorrow's editable draft
  and advances the cycle by one step, wrapping after the last step.
- **Skip** advances one step without creating a commitment.
- **Dismiss** hides the suggestion for that date and keeps the same cycle step.
- An unanswered suggestion or missed date never advances the cycle. Nothing is
  automatically added or committed. A committed plan hides and rejects all actions.

Each routine persists its ordered definitions, next-step cursor and decisions keyed
by planning date. Repeated or stale actions are rejected; accepted commitments and
the corresponding decision are saved together. Restarting or rollover cannot add
the same suggestion twice. Editing retains the next step by its identity if it still
exists (otherwise the first step becomes next), along with prior date decisions.
Deleting a routine leaves accepted commitments and history intact. Accepted tasks
are independent copies: editing a routine does not change existing commitments.
Routines have no connection to calendar events or accounts.

`FreedomSettings` and immutable `RoutineBook` are additive fields in the existing
v2 `DaylockState` snapshot; the storage key/version remain unchanged. Missing fields
in older saves migrate to disabled Freedom/18:00 and an empty routine collection.
All existing plan, Focus, excuse, history, event and account-cache fields are
preserved. Invalid existing values fail through the usual safe load-error path
instead of resetting data. OAuth secure storage and appearance preferences remain
separate. No new package is required.

On Android, enable Control, choose a convenient time and inspect Today's checklist.
Complete at least one eligible Today commitment, finish any remaining eligible
commitments and commit tomorrow. The status becomes **Freedom earned** only after
the chosen time. Create a two-step routine, accept its suggestion in Plan, and check
that Today remains unchanged. Restart to verify the saved choice; after rollover,
the next planning date offers the next cycle step. Skip and Dismiss exercise the
rules above without creating tasks.

## Excused commitments

Commitments have three outcomes: **Completed**, **Incomplete** and **Excused**.
Goal taps still toggle completion. Long-press any Today commitment to view its
details and open **Mark completed**, **Excuse task** or **Reset to incomplete**.
Excusing requires a nonblank reason, up to 240 characters; cancelling makes no
change. Excused rows use a shield and a muted status rather than a completed
checkbox or strike-through. Tap an excused row to read its reason, change the
reason or reverse the excuse. Screen readers also expose a **Task actions** action.

Focus still requires its minimum duration: manual **Mark completed** is disabled
before that time is earned and the model enforces the same rule. Excusing an active
session settles timestamp-based elapsed time, stops its timer and saves the exact
milliseconds. Resetting to incomplete retains that time and clears the reason;
resuming continues from the earned duration. If the minimum was already earned,
starting again completes immediately without requiring repeated work.

Excused tasks are excluded from the denominator and never count as completed.
Three completed plus one excused is **3 / 3, 100%**; two completed, one incomplete
and one excused is **2 / 3, 67%**. Today shows the excused count separately. An
all-excused day shows **No eligible commitments**, without a completion percentage
or a completed-day status, and its Calendar tile is neutral.

`CommitmentProgress` supplies one calculation for live plans, history and Calendar.
`DailyPlan.progress` exposes total, eligible, completed and excused counts plus
nullable percentages. Historical `commitmentCount` still means the total original
count; `eligibleCount` and `excusedCount` are explicit additions. Recorded Focus
time includes legitimate time on excused tasks. Calendar keeps its existing layout,
showing excused outcomes and their reasons in the read-only historical rows.

Persistence adds `outcome` and `excuseReason` to live and historical task JSON in
the existing v2 snapshot. The compatibility `isCompleted` field is retained.
Older records safely derive outcomes from their existing completion/Focus data;
their dates, tasks, time, events and account cache remain intact. v1 migration
continues to retain its backup. Mixed old/new saves preserve existing excuses.
Invalid outcomes or missing reasons follow the load-error flow without resetting
the saved data. Migration write failures retain the original save and can retry.
OAuth storage and appearance preferences are unchanged. Rollover archives the final
outcome and reason as an immutable snapshot and dismisses obsolete task dialogs.

## Daily plan history

Past plans are retained locally without a retention limit. Before rollover replaces
Today, it captures an immutable `HistoricalDailyPlan`: the original calendar date,
committed flag, Goal/Focus requirements, completion flags and exact accumulated
Focus milliseconds. `MainApp` owns `PlanHistory` alongside its live plans; Calendar
reads this history without modifying it.

A running Focus session is settled at the end of its own local calendar day before
archiving, capped at its existing minimum duration. The following midnight is
constructed from calendar components, while elapsed time uses UTC timestamps, so
month/year changes and DST do not credit another day's time. Archived timers never
run again, and live tasks are not mutated while making their snapshots.

After several missed days, the stored Today plan is archived. A stored, committed
tomorrow plan whose date has passed is also retained with only its recorded progress;
an expired uncommitted draft is not treated as an executed plan. Unknown intervening
dates receive no records. The existing promotion of tomorrow after a one-day rollover
is unchanged. Repeated archive attempts keep the first snapshot for a date.

Read-only queries are available through `DaylockState.history`:

```dart
final plan = state.history.forDate(date); // Null when the date was never recorded.
final summary = state.history.summaryForDate(date);
final summaries = state.history.summaries(from: firstDate, through: lastDate);
```

Records and their task lists are immutable. Summaries expose commitment/completed
counts, accumulated Focus milliseconds and completion percentage. Recorded days with
zero commitments are neutral (`isNeutral`, null percentage), distinct from unknown
dates; scheduled events never enter these counts. Range queries return only known
dates, in chronological order, with inclusive boundaries.

Persistence adds `history` to the existing `daylock.state.v2` JSON snapshot and keeps
the same storage key/version. Previous v2 saves receive an empty collection without
backfilling earlier dates. Actual plans already present in a save can be archived at
their next rollover; no commitments or completion data are fabricated. v1 migration
also starts with empty history and retains its original backup. Invalid or duplicate
stored history follows the existing load-error/Retry flow, leaving the original save
intact. Rollover saves history and replacement plans together through the existing
ordered writes. Local/external events, credentials and appearance preferences are
preserved; normal migration never resets data.

## Reset development data

Stop the running app, then launch a debug build once with:

```sh
flutter run --dart-define=DAYLOCK_RESET_LOCAL_DATA=true
```

This deletes all saved Daylock plans and history, completion/focus progress, committed state,
local/cached calendar events, account metadata, and Daylock OAuth credentials on
the selected device, including the old v1 migration backup. It leaves unrelated
preferences and secure-storage keys intact. The reset completes before the app
loads its state.

After resetting, stop the app and launch normally:

```sh
flutter run
```

Do not keep the reset flag in an IDE launch configuration: every full launch
with that flag clears Daylock data again. Profile and release builds ignore the
flag. Normal launches preserve existing saves, including previously persisted
sample commitments; the app never guesses which tasks are samples from their names.

## Calendar and events

Calendar has a Monday-first, seven-column monthly heatmap. Use the arrows or swipe
left/right across the grid to move forward/back one month. Tap the month/year heading
to open a themed picker with twelve month choices, a directly editable year and year
steppers. Navigation supports the existing calendar-date range, years 1–9999, without
restricting it to a window around today. All three methods preserve the selected day
number, clamping to the last valid day of a shorter month. **Today** returns to the
current month, selects today and updates its details.

Five completion tones represent 0%, more than
0–25%, more than 25–50%, more than 50 but less than 100%, and 100%. Unknown dates,
recorded empty days and future dates are neutral. An accent outline marks today;
an ink outline marks the selected date. When today is selected, a second contrasting
inner ring preserves both states. The compact **Less / More** legend has an outlined
neutral swatch and tooltips/semantic labels distinguishing missing/empty days, 0%,
partial and full completion. Small dots indicate dates containing visible
local or cached external events, including each overlapping date of multi-day events.
Events never affect the heatmap.

Select a date to read its commitments and schedule below the grid. Past recorded
days show completion count/percentage, Goal/Focus results, targets and total Focus
time. Today projects live progress and elapsed Focus time without changing tasks or
providing completion/timer controls. Future dates show scheduled events. History is
read-only, and missing dates explicitly show that no history was recorded.

`CalendarDayActivity` is a temporary immutable view of existing plans/history, not a
new storage format. `DaylockHeatmapPalette` derives its tones from the central
`ColorScheme`, checking date-text contrast across all six palettes in both modes.
Calendar components live in `lib/design/daylock_calendar.dart` and
`daylock_calendar_details.dart`; event timeline presentation is shared with Plan.
Reduced-motion settings disable month fades and outline/progress transitions. Date
targets use their whole cell, at least 48px high at normal text sizes, with narrower
widths on small phones to retain all seven columns. At normal text sizes
the full grid fits 320px screens; at large accessibility sizes it can pan horizontally
to preserve seven columns and readable numbers. Swiping beyond either edge of a wide
grid changes month; ordinary panning preserves it. Vertical scrolling, taps and small
horizontal motions never trigger month navigation. Selected-day details scroll vertically,
and event/account dialogs allow their titles and contents to scroll at large text sizes.

Main event rows use concise source labels; external-event details retain full account
and calendar information, notes and selectable meeting links. Existing account connection,
sync, visibility and disconnect controls remain available through the top-right
**Calendar accounts** icon, with a tooltip and semantic label. Schedule has a small
**+ Add event** action beside its heading; it stacks when accessibility text needs
more room. Repeated explanatory text and the large event-creation button are removed.
`CalendarMonthPicker` owns only temporary picker inputs; `CalendarScreen` owns the
selected date and a single shared month-navigation method. `MainApp` remains the
owner of all live plans, history, events and accounts.
No backend, package, persistence, migration or authentication changes are introduced.

Select a date and choose **Add event**.
Titles are required; start/end times and notes are optional. Enter times in 24-hour
`HH:mm` format. If both times are entered, the end must follow the start on the same
day. Tap an event or its edit button to change it; deletion asks for confirmation.

Tomorrow's events appear in a separate schedule before commitments in Plan. Local events remain editable
through Calendar when commitments are locked; external events are always read-only.
Events never count toward commitment completion.

Events are stored separately from `DailyPlan` in the existing local JSON snapshot.
Their dates use `YYYY-MM-DD`, and their optional times use `HH:mm`, so they represent
local calendar dates and wall-clock times rather than timer timestamps. The v2
format gains an `events` field: older v2 saves receive an empty list on load and
are saved with that field, preserving plans and progress. v1 migration also starts
with no events. Invalid saved data follows the existing load-error path and is
left intact. Rollover preserves the event collection without turning events into
commitments. The local calendar uses no calendar dependency.

## External calendars

Google Calendar now has a native Android OAuth reader supporting multiple
accounts. Configure your Google Cloud OAuth clients using
[the setup guide](docs/google_calendar_setup.md), then build with the public Web
client ID in `GOOGLE_SERVER_CLIENT_ID`. Without configuration, Google connection
stays disabled. Microsoft Personal and Work/School now use native browser OAuth
with PKCE and Microsoft Graph. Follow [the Microsoft setup guide](docs/microsoft_calendar_setup.md)
and provide the public Entra Application ID through `MICROSOFT_CLIENT_ID`.
Include both defines to enable both providers. No simulated accounts ship in the app.

`MainApp` owns local events and an immutable `CalendarCache` separately from the
daily commitment plans. `CalendarAccount` uses provider, stable provider subject,
and optional tenant to distinguish multiple accounts, including work tenants.
`ConnectedCalendar` records calendar identity, visibility, and last successful
sync. Visible events from all accounts share the same Calendar and Plan display,
with provider, account, and calendar labels. Tapping an external event shows
read-only details and a selectable meeting URL. There are no external edit/delete
actions. Local mutation callbacks also reject external events.

`CalendarProvider` defines connection, complete calendar discovery, and read-only
event snapshots. There are no event write methods. `CalendarService` connects
multiple accounts, reconciles snapshots, and disconnects locally. Disconnecting
removes that account's credentials and cache; it does not change provider events
or revoke the provider's consent grant. Visibility hides events without deleting
the offline cache. Sync is manual, covering the last 30 days and the following
90 days; other cached ranges remain available but may be stale until refreshed.
Failed/incomplete fetches preserve the existing cache.

Stable event keys include provider, account, calendar, and provider event/occurrence
ID. Repeated snapshots upsert those keys. A complete snapshot replaces only its
calendar's requested date window, removing missing/cancelled/deleted events and
events moved out of the window; optional tombstones remove explicitly deleted
IDs. Removed calendars lose their cache. Adapters collect **every page** of
both calendar discovery and event responses before returning successful results.
Partial/delta pages must never be labelled complete snapshots.

Timed external events store UTC start/end instants, converted to the current
device zone for date filtering and display. They can span midnight and DST
boundaries. All-day events use date-only ranges with exclusive ends; they are
never shifted through UTC. Meeting URLs accept only HTTP(S). The Google reader
requests UTC responses, parses RFC3339 offsets and resolves explicit IANA zones
with `timezone`. Ambiguous/nonexistent or unzoned wall times fail safely. The
Microsoft reader requests UTC timed responses and lets Graph resolve original
Windows/IANA zones for all-day dates, using padded queries filtered to the actual
date window. Unsupported legacy custom zones fail safely and preserve the cache.

`CalendarCredentialStore` separates OAuth credentials from cache metadata.
`SecureCalendarCredentialStore` uses `flutter_secure_storage` with an Android
Keystore-backed encrypted namespace. Tokens are never passed to `DaylockState`
or `shared_preferences`, and provider errors are not rendered verbatim. Android
backup/transfer rules exclude the credential namespace and wrapped keys, while
leaving ordinary planner storage rules intact. Native consent and encrypted
storage require device verification with your OAuth clients; automated tests
use fake native authorization and HTTP responses. Google Play Services manages
token renewal; Daylock securely stores access tokens and never requests a server
refresh token. Microsoft refreshes each account using its own securely saved
refresh token and tenant, saving rotated tokens before use. Expired/revoked
permissions expose an account-specific Reconnect action.

Persistence remains additive v2: missing `calendarCache` becomes empty and missing
event `source` becomes `local`. Migration writes the canonical snapshot while
preserving daily dates, commitments, Focus progress, locking, and existing event
IDs. v1 migration remains supported. Malformed cache data is left intact and
reported through the existing load-error flow.

### Provider architecture

`NativeGoogleCalendarAuth` wraps account selection and account-specific read-only
authorization. `GoogleCalendarProvider` fetches calendar/event pages and expands
recurring instances through Google. `CalendarService` continues to own shared
reconciliation, visibility and local disconnect; `MainApp` still owns planner and
cache state. `NativeMicrosoftCalendarAuth` wraps AppAuth authorization/renewal;
one `MicrosoftCalendarProvider` serves both Microsoft account categories and
expands recurring instances through Graph's `calendarView`. `defaultCalendarService`
registers each configured Android provider independently. `CalendarFailure`
provides fixed error messages without leaking provider
diagnostics. `ConnectedCalendar.timeZone` is an optional additive persistence
field; existing saves and commitment behaviour remain unchanged.

Provider references: [Google scopes](https://developers.google.com/workspace/calendar/api/auth),
[Google event listing](https://developers.google.com/workspace/calendar/api/v3/reference/events/list),
[Microsoft calendarView](https://learn.microsoft.com/en-us/graph/api/calendar-list-calendarview?view=graph-rest-1.0),
[secure storage](https://pub.dev/packages/flutter_secure_storage),
[Android backup rules](https://developer.android.com/identity/data/autobackup).

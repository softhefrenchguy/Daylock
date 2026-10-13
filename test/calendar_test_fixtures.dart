import 'package:daylock/models/calendar_account.dart';
import 'package:daylock/models/calendar_cache.dart';
import 'package:daylock/models/event.dart';
import 'package:daylock/services/calendar_credentials.dart';
import 'package:daylock/services/calendar_provider.dart';

class MemoryCredentials implements CalendarCredentialStore {
  final values = <String, CalendarCredentials>{};
  bool failWrite = false;
  bool failDelete = false;
  @override
  Future<CalendarCredentials?> read(String accountId) async =>
      values[accountId];
  @override
  Future<void> write(String accountId, CalendarCredentials credentials) async {
    if (failWrite) throw StateError('Test write failure');
    values[accountId] = credentials;
  }

  @override
  Future<void> delete(String accountId) async {
    if (failDelete) throw StateError('Test delete failure');
    values.remove(accountId);
  }

  @override
  Future<void> clearDaylockCredentials() async => values.clear();
}

CalendarAccount testAccount(
  CalendarProviderType type, {
  String name = 'Alex',
  String subject = 'subject',
  String? tenant,
}) => CalendarAccount(
  provider: type,
  providerAccountId: subject,
  tenantId: tenant,
  displayName: name,
  email: '$subject@example.test',
);

ConnectedCalendar testCalendar(
  CalendarAccount account, {
  String id = 'primary',
  bool visible = true,
}) => ConnectedCalendar(
  accountId: account.id,
  id: id,
  name: '$id calendar',
  isVisible: visible,
);

Event testExternal(
  CalendarAccount account, {
  String id = 'remote',
  String calendar = 'primary',
  String title = 'Remote meeting',
  DateTime? date,
}) => Event.externalTimed(
  source: account.provider.eventSource,
  accountId: account.id,
  calendarId: calendar,
  externalEventId: id,
  title: title,
  startsAtUtc: (date ?? DateTime(2026, 10, 9, 10)).toUtc(),
  endsAtUtc: (date ?? DateTime(2026, 10, 9, 10))
      .add(const Duration(hours: 1))
      .toUtc(),
  notes: 'Meeting notes',
  meetingUrl: Uri.parse('https://example.test/meeting'),
);

CalendarCache testCache(CalendarAccount account, {Iterable<Event>? events}) =>
    CalendarCache(
      accounts: [account],
      calendars: [testCalendar(account)],
      events: events ?? [testExternal(account)],
    );

// Test-only adapter: no simulated accounts or events are shipped in the app.
class TestCalendarProvider implements CalendarProvider {
  @override
  final CalendarProviderType type;
  CalendarAccount? nextAccount;
  final calendarsByAccount = <String, List<ConnectedCalendar>>{};
  final snapshots = <String, CalendarEventSnapshot>{};
  bool failFetch = false;
  bool failDiscovery = false;

  TestCalendarProvider(this.type) : nextAccount = testAccount(type);

  @override
  Future<CalendarConnection?> connect() async => nextAccount == null
      ? null
      : CalendarConnection(
          account: nextAccount!,
          credentials: CalendarCredentials(
            accessToken: 'test-access-token',
            refreshToken: 'test-refresh-token',
          ),
        );

  @override
  Future<List<ConnectedCalendar>> listCalendars(
    CalendarAccount account,
    CalendarCredentialStore credentials,
  ) async {
    if (failDiscovery) throw StateError('Test offline');
    return calendarsByAccount[account.id] ?? [testCalendar(account)];
  }

  @override
  Future<CalendarEventSnapshot> fetchEvents(
    CalendarAccount account,
    ConnectedCalendar calendar,
    CalendarSyncWindow window,
    CalendarCredentialStore credentials,
  ) async {
    if (failFetch) throw StateError('Test offline');
    return snapshots[calendar.key] ??
        CalendarEventSnapshot(
          events: [testExternal(account, calendar: calendar.id)],
          isComplete: true,
        );
  }
}

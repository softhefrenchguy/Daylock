import '../models/calendar_account.dart';
import '../models/event.dart';
import 'calendar_credentials.dart';

class CalendarConnection {
  final CalendarAccount account;
  final CalendarCredentials credentials;
  CalendarConnection({required this.account, required this.credentials});
}

// Calendar boundaries, rather than 24-hour durations, include DST correctly.
class CalendarSyncWindow {
  final DateTime start;
  final DateTime endExclusive;
  CalendarSyncWindow({required DateTime start, required DateTime endExclusive})
    : start = DateTime(start.year, start.month, start.day),
      endExclusive = DateTime(
        endExclusive.year,
        endExclusive.month,
        endExclusive.day,
      ) {
    if (!this.endExclusive.isAfter(this.start)) {
      throw const FormatException('Invalid sync window');
    }
  }
}

class CalendarEventSnapshot {
  final List<Event> events;
  final Set<String> deletedExternalIds;
  final bool isComplete;

  CalendarEventSnapshot({
    required Iterable<Event> events,
    Iterable<String> deletedExternalIds = const [],
    required this.isComplete,
  }) : events = List.unmodifiable(events),
       deletedExternalIds = Set.unmodifiable(deletedExternalIds);
}

// Provider adapters implement only read operations. No event write API exists.
// OAuth is delegated/native, with read-only calendar scopes and no client secret.
// Adapters must finish ALL pages before marking a snapshot complete. Return UTC
// instants for timed events and date ranges (exclusive end) for all-day events.
// Resolve provider zones before constructing Event; never parse a naive wall
// time as the device zone. Expand occurrences on the provider side, with stable
// occurrence IDs; cancelled instances are omitted or returned as tombstone IDs.
// Token refresh/rotation uses the injected secure store, never the cache.
// Calendar discovery must also finish all pages, or throw rather than return a
// partial list: absence from that list means a calendar is no longer accessible.
abstract interface class CalendarProvider {
  CalendarProviderType get type;
  Future<CalendarConnection?> connect(); // null means the user cancelled.
  Future<List<ConnectedCalendar>> listCalendars(
    CalendarAccount account,
    CalendarCredentialStore credentials,
  );
  Future<CalendarEventSnapshot> fetchEvents(
    CalendarAccount account,
    ConnectedCalendar calendar,
    CalendarSyncWindow window,
    CalendarCredentialStore credentials,
  );
}

// Optional capability: existing adapters keep their original contract.
abstract interface class CalendarReauthorizingProvider {
  Future<CalendarConnection?> reconnect(CalendarAccount account);
}

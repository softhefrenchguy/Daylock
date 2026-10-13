import '../models/calendar_account.dart';
import '../models/calendar_cache.dart';
import '../models/event.dart';
import 'calendar_credentials.dart';
import 'calendar_provider.dart';

// Shared reconciliation for any provider. Callers publish/save only successful
// snapshots. A failed or incomplete fetch leaves the previous offline cache intact.
class CalendarService {
  final CalendarCredentialStore credentials;
  final Map<CalendarProviderType, CalendarProvider> _providers;
  final DateTime Function() _now;

  CalendarService({
    CalendarCredentialStore? credentials,
    Iterable<CalendarProvider> providers = const [],
    DateTime Function()? now,
  }) : credentials = credentials ?? SecureCalendarCredentialStore(),
       _providers = {for (final provider in providers) provider.type: provider},
       _now = now ?? DateTime.now;

  bool canConnect(CalendarProviderType type) => _providers.containsKey(type);

  bool canReconnect(CalendarProviderType type) =>
      _providers[type] is CalendarReauthorizingProvider;

  Future<CalendarCache> reconnect(CalendarCache cache, String accountId) async {
    final account = cache.accounts.firstWhere((a) => a.id == accountId);
    final provider = _provider(account.provider);
    if (provider is! CalendarReauthorizingProvider) {
      throw StateError('Account reconnection is unavailable');
    }
    final connection = await (provider as CalendarReauthorizingProvider)
        .reconnect(account);
    if (connection == null) return cache;
    if (connection.account.id != account.id) {
      throw const FormatException('Reconnect account mismatch');
    }
    await credentials.write(account.id, connection.credentials);
    return CalendarCache(
      accounts: [
        for (final a in cache.accounts)
          if (a.id == account.id) connection.account else a,
      ],
      calendars: cache.calendars,
      events: cache.events,
    );
  }

  CalendarProvider _provider(CalendarProviderType type) =>
      _providers[type] ??
      (throw StateError('Sign-in is not available for this provider yet'));

  List<ConnectedCalendar> _validateCalendars(
    CalendarAccount account,
    List<ConnectedCalendar> calendars,
  ) {
    if (calendars.any((c) => c.accountId != account.id) ||
        calendars.map((c) => c.id).toSet().length != calendars.length) {
      throw const FormatException('Invalid provider calendar list');
    }
    return calendars;
  }

  Future<CalendarCache> connect(
    CalendarCache cache,
    CalendarProviderType type,
  ) async {
    final provider = _provider(type);
    final connection = await provider.connect();
    if (connection == null) return cache;
    final account = connection.account;
    if (account.provider != type) {
      throw const FormatException('Provider account mismatch');
    }
    // OAuth completed, but do not publish metadata before secure storage succeeds.
    await credentials.write(account.id, connection.credentials);
    // Calendar discovery is a separate sync operation. Preserve a reconnect's cache.
    return CalendarCache(
      accounts: [...cache.accounts.where((a) => a.id != account.id), account],
      calendars: cache.calendars,
      events: cache.events,
    );
  }

  Future<CalendarCache> disconnect(
    CalendarCache cache,
    String accountId,
  ) async {
    await credentials.delete(accountId);
    return cache.withoutAccount(accountId);
  }

  Future<CalendarCache> synchronize(
    CalendarCache cache,
    String accountId,
    CalendarSyncWindow window,
  ) async {
    final account = cache.accounts.firstWhere((a) => a.id == accountId);
    final provider = _provider(account.provider);
    if (await credentials.read(accountId) == null) {
      throw StateError('Reconnect this account before syncing');
    }
    final discovered = _validateCalendars(
      account,
      await provider.listCalendars(account, credentials),
    );
    final calendars = <ConnectedCalendar>[];
    final events = <String, Event>{
      for (final e in cache.events.where((e) => e.accountId != accountId))
        e.id: e,
    };
    for (final calendar in discovered) {
      final previous = cache.calendars
          .where((c) => c.key == calendar.key)
          .firstOrNull;
      final snapshot = await provider.fetchEvents(
        account,
        calendar,
        window,
        credentials,
      );
      if (!snapshot.isComplete) {
        throw StateError('Incomplete calendar snapshot');
      }
      for (final event in snapshot.events) {
        if (event.accountId != accountId ||
            event.calendarId != calendar.id ||
            event.source != account.provider.eventSource ||
            !event.overlapsDates(window.start, window.endExclusive)) {
          throw const FormatException('Invalid provider event snapshot');
        }
      }
      // Authoritative replacement only inside this calendar's requested window.
      // Missing events remove cancellations, deletions, and events moved away.
      for (final event in cache.events.where(
        (e) => e.accountId == accountId && e.calendarId == calendar.id,
      )) {
        if (!event.overlapsDates(window.start, window.endExclusive) &&
            !snapshot.deletedExternalIds.contains(event.externalEventId)) {
          events[event.id] = event;
        }
      }
      for (final event in snapshot.events) {
        if (!snapshot.deletedExternalIds.contains(event.externalEventId)) {
          events[event.id] = event;
        }
      }
      calendars.add(
        calendar.copyWith(
          isVisible: previous?.isVisible ?? true,
          lastSyncedAt: _now(),
        ),
      );
    }
    // Calendars absent from the complete discovery result lose their cached events.
    return CalendarCache(
      accounts: cache.accounts,
      calendars: [
        ...cache.calendars.where((c) => c.accountId != accountId),
        ...calendars,
      ],
      events: events.values,
    );
  }
}

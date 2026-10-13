import 'calendar_account.dart';
import 'event.dart';

// Immutable, non-secret snapshot. Local events stay in DaylockState.events.
class CalendarCache {
  final List<CalendarAccount> accounts;
  final List<ConnectedCalendar> calendars;
  final List<Event> events;

  static const empty = CalendarCache._empty();
  const CalendarCache._empty()
    : accounts = const [],
      calendars = const [],
      events = const [];

  CalendarCache({
    Iterable<CalendarAccount> accounts = const [],
    Iterable<ConnectedCalendar> calendars = const [],
    Iterable<Event> events = const [],
  }) : accounts = List.unmodifiable(accounts),
       calendars = List.unmodifiable(calendars),
       events = List.unmodifiable(events) {
    final byAccount = {
      for (final account in this.accounts) account.id: account,
    };
    final byCalendar = {
      for (final calendar in this.calendars) calendar.key: calendar,
    };
    if (byAccount.length != this.accounts.length ||
        byCalendar.length != this.calendars.length ||
        this.events.map((e) => e.id).toSet().length != this.events.length) {
      throw const FormatException('Duplicate calendar cache identities');
    }
    for (final calendar in this.calendars) {
      if (!byAccount.containsKey(calendar.accountId)) {
        throw const FormatException('Calendar has no account');
      }
    }
    for (final event in this.events) {
      final account = byAccount[event.accountId];
      if (!event.isExternal ||
          account == null ||
          event.source != account.provider.eventSource ||
          !this.calendars.any(
            (c) => c.accountId == event.accountId && c.id == event.calendarId,
          )) {
        throw const FormatException('Invalid cached event ownership');
      }
    }
  }

  Iterable<Event> get visibleEvents => events.where(
    (event) => calendars.any(
      (c) =>
          c.accountId == event.accountId &&
          c.id == event.calendarId &&
          c.isVisible,
    ),
  );

  String sourceLabel(Event event) {
    if (!event.isExternal) return 'Local';
    final account = accounts.firstWhere((a) => a.id == event.accountId);
    final calendar = calendars.firstWhere(
      (c) => c.accountId == event.accountId && c.id == event.calendarId,
    );
    final identity =
        account.email == null || account.email == account.displayName
        ? account.displayName
        : '${account.displayName} (${account.email})';
    return '${account.provider.label} · $identity · ${calendar.name}';
  }

  CalendarCache setVisibility(
    String accountId,
    String calendarId,
    bool visible,
  ) => CalendarCache(
    accounts: accounts,
    events: events,
    calendars: calendars.map(
      (c) => c.accountId == accountId && c.id == calendarId
          ? c.copyWith(isVisible: visible)
          : c,
    ),
  );

  CalendarCache withoutAccount(String accountId) => CalendarCache(
    accounts: accounts.where((a) => a.id != accountId),
    calendars: calendars.where((c) => c.accountId != accountId),
    events: events.where((e) => e.accountId != accountId),
  );

  Map<String, dynamic> toJson() => {
    'accounts': accounts.map((a) => a.toJson()).toList(),
    'calendars': calendars.map((c) => c.toJson()).toList(),
    'events': events.map((e) => e.toJson()).toList(),
  };

  factory CalendarCache.fromJson(Map<String, dynamic> json) => CalendarCache(
    accounts: (json['accounts'] as List).map(
      (a) => CalendarAccount.fromJson(a as Map<String, dynamic>),
    ),
    calendars: (json['calendars'] as List).map(
      (c) => ConnectedCalendar.fromJson(c as Map<String, dynamic>),
    ),
    events: (json['events'] as List).map(
      (e) => Event.fromJson(e as Map<String, dynamic>),
    ),
  );
}

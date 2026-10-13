import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/calendar_account.dart';
import '../models/event.dart';
import 'calendar_credentials.dart';
import 'calendar_failure.dart';
import 'calendar_provider.dart';
import 'google_calendar_auth.dart';

class GoogleCalendarProvider
    implements CalendarProvider, CalendarReauthorizingProvider {
  final GoogleCalendarAuth auth;
  final http.Client _client;
  final Duration requestTimeout;
  static bool _zonesInitialized = false;

  GoogleCalendarProvider({
    required this.auth,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 30),
  }) : _client = client ?? http.Client();

  @override
  CalendarProviderType get type => CalendarProviderType.google;
  @override
  Future<CalendarConnection?> connect() => auth.connect();
  @override
  Future<CalendarConnection?> reconnect(CalendarAccount account) =>
      auth.connect(expectedAccount: account);

  Future<void> _renew(
    CalendarAccount account,
    CalendarCredentialStore store,
  ) async {
    await store.write(account.id, await auth.authorize(account));
  }

  Future<Map<String, dynamic>> _get(
    CalendarAccount account,
    CalendarCredentialStore store,
    List<String> path,
    Map<String, String> query,
  ) async {
    // Fixed host and structured path components: tokens never follow a URL
    // supplied by an event, account, page response or calendar ID.
    final uri = Uri(
      scheme: 'https',
      host: 'www.googleapis.com',
      pathSegments: ['calendar', 'v3', ...path],
      queryParameters: query,
    );
    for (var attempt = 0; attempt < 2; attempt++) {
      final credentials = await store.read(account.id);
      if (credentials == null) {
        throw const CalendarFailure(CalendarFailureKind.authorization);
      }
      http.Response response;
      try {
        final request = http.Request('GET', uri)
          ..followRedirects = false
          ..headers['Authorization'] = 'Bearer ${credentials.accessToken}'
          ..headers['Accept'] = 'application/json';
        response = await (() async => http.Response.fromStream(
          await _client.send(request),
        ))().timeout(requestTimeout);
      } catch (_) {
        throw const CalendarFailure(CalendarFailureKind.unavailable);
      }
      if (response.statusCode == 401) {
        if (attempt == 1) {
          throw const CalendarFailure(CalendarFailureKind.authorization);
        }
        await auth.invalidate(credentials.accessToken);
        await _renew(account, store);
        continue;
      }
      if (response.statusCode == 403) {
        // Quota/API configuration failures need a later retry, not repeated
        // consent dialogs. Only permission failures require reconnecting.
        final reasons = _errorReasons(response.body);
        if (reasons.any(
          {'insufficientPermissions', 'authError', 'forbidden'}.contains,
        )) {
          throw const CalendarFailure(CalendarFailureKind.authorization);
        }
        if (reasons.any({'accessNotConfigured', 'serviceDisabled'}.contains)) {
          throw const CalendarFailure(CalendarFailureKind.configuration);
        }
        throw const CalendarFailure(CalendarFailureKind.unavailable);
      }
      if (response.statusCode != 200) {
        throw const CalendarFailure(CalendarFailureKind.unavailable);
      }
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        throw const CalendarFailure(CalendarFailureKind.response);
      }
    }
    throw const CalendarFailure(CalendarFailureKind.authorization);
  }

  Set<String> _errorReasons(String body) {
    try {
      final error = (jsonDecode(body) as Map<String, dynamic>)['error'] as Map;
      return (error['errors'] as List? ?? [])
          .map((e) => (e as Map)['reason'] as String)
          .toSet();
    } catch (_) {
      return {};
    }
  }

  // A missing items field represents an empty collection in Google responses.
  // Repeated page tokens fail rather than hanging or publishing partial data.
  Future<List<Map<String, dynamic>>> _pages(
    CalendarAccount account,
    CalendarCredentialStore store,
    List<String> path,
    Map<String, String> query,
    String expectedKind,
  ) async {
    final pages = <Map<String, dynamic>>[];
    final seen = <String>{};
    String? token;
    do {
      final page = await _get(account, store, path, {
        ...query,
        'pageToken': ?token,
      });
      if (page['kind'] != expectedKind ||
          (page['items'] != null && page['items'] is! List)) {
        throw const CalendarFailure(CalendarFailureKind.response);
      }
      pages.add(page);
      final next = page['nextPageToken'];
      if (next != null &&
          (next is! String || next.isEmpty || !seen.add(next))) {
        throw const CalendarFailure(CalendarFailureKind.response);
      }
      token = next as String?;
    } while (token != null);
    return pages;
  }

  @override
  Future<List<ConnectedCalendar>> listCalendars(
    CalendarAccount account,
    CalendarCredentialStore credentials,
  ) async {
    // Reacquire for this saved account on every sync, even after app restarts.
    await _renew(account, credentials);
    final pages = await _pages(
      account,
      credentials,
      ['users', 'me', 'calendarList'],
      {'maxResults': '250', 'showHidden': 'true', 'minAccessRole': 'reader'},
      'calendar#calendarList',
    );
    try {
      return [
        for (final page in pages)
          for (final item in page['items'] as List? ?? [])
            if ((item as Map)['deleted'] != true)
              ConnectedCalendar(
                accountId: account.id,
                id: item['id'] as String,
                name:
                    (item['summaryOverride'] ?? item['summary'] ?? item['id'])
                        as String,
                timeZone: item['timeZone'] as String?,
              ),
      ];
    } catch (_) {
      throw const CalendarFailure(CalendarFailureKind.response);
    }
  }

  @override
  Future<CalendarEventSnapshot> fetchEvents(
    CalendarAccount account,
    ConnectedCalendar calendar,
    CalendarSyncWindow window,
    CalendarCredentialStore credentials,
  ) async {
    if (calendar.accountId != account.id || account.provider != type) {
      throw const CalendarFailure(CalendarFailureKind.response);
    }
    final pages = await _pages(
      account,
      credentials,
      ['calendars', calendar.id, 'events'],
      {
        'maxResults': '2500',
        'singleEvents': 'true',
        'showDeleted': 'true',
        'orderBy': 'startTime',
        'timeZone': 'UTC',
        'timeMin': window.start.toUtc().toIso8601String(),
        'timeMax': window.endExclusive.toUtc().toIso8601String(),
      },
      'calendar#events',
    );
    final events = <Event>[];
    final deleted = <String>{};
    try {
      for (final page in pages) {
        for (final item in page['items'] as List? ?? []) {
          final value = item as Map<String, dynamic>;
          final id = value['id'] as String;
          if (id.isEmpty) throw const FormatException('Missing event ID');
          if (value['status'] == 'cancelled') {
            // Cancelled recurring instances may contain only their instance ID.
            deleted.add(id);
            continue;
          }
          final title = (value['summary'] as String?)?.trim();
          final notes = value['description'] as String?;
          final meeting = _meetingUrl(value);
          final start = value['start'] as Map<String, dynamic>;
          final end = value['end'] as Map<String, dynamic>;
          final Event event;
          if (start['date'] != null && end['date'] != null) {
            event = Event.externalAllDay(
              source: type.eventSource,
              accountId: account.id,
              calendarId: calendar.id,
              externalEventId: id,
              title: title?.isNotEmpty == true ? title! : 'Untitled event',
              date: _date(start['date'] as String),
              endDateExclusive: _date(end['date'] as String),
              notes: notes,
              meetingUrl: meeting,
            );
          } else {
            final zone = page['timeZone'] as String? ?? calendar.timeZone;
            event = Event.externalTimed(
              source: type.eventSource,
              accountId: account.id,
              calendarId: calendar.id,
              externalEventId: id,
              title: title?.isNotEmpty == true ? title! : 'Untitled event',
              startsAtUtc: _instant(start, zone),
              endsAtUtc: _instant(end, zone),
              notes: notes,
              meetingUrl: meeting,
            );
          }
          events.add(event);
        }
      }
    } catch (_) {
      throw const CalendarFailure(CalendarFailureKind.response);
    }
    // Full window snapshots (not sync-token deltas) remove missing, moved and
    // deleted instances through the existing shared reconciler.
    return CalendarEventSnapshot(
      events: events,
      deletedExternalIds: deleted,
      isComplete: true,
    );
  }

  Uri? _meetingUrl(Map<String, dynamic> event) {
    final candidates = <Object?>[
      event['hangoutLink'],
      for (final entry
          in (event['conferenceData'] as Map?)?['entryPoints'] as List? ?? [])
        if ((entry as Map)['entryPointType'] == 'video') entry['uri'],
    ];
    for (final candidate in candidates.whereType<String>()) {
      final uri = Uri.tryParse(candidate);
      if (uri != null &&
          {'http', 'https'}.contains(uri.scheme) &&
          uri.host.isNotEmpty) {
        return uri;
      }
    }
    return null;
  }

  DateTime _date(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      throw const FormatException('Invalid date');
    }
    final date = DateTime.parse(value);
    if (date.toIso8601String().substring(0, 10) != value) {
      throw const FormatException('Invalid calendar date');
    }
    return date;
  }

  DateTime _instant(Map<String, dynamic> value, String? fallbackZone) {
    final text = value['dateTime'] as String;
    final pattern = RegExp(
      r'^(\d{4}-\d{2}-\d{2})T(\d{2}):(\d{2}):(\d{2})(\.\d{1,9})?(Z|[+-]\d{2}:\d{2})?$',
    );
    final match = pattern.firstMatch(text);
    if (match == null) throw const FormatException('Invalid timestamp');
    _date(match[1]!);
    if (int.parse(match[2]!) > 23 ||
        int.parse(match[3]!) > 59 ||
        int.parse(match[4]!) > 59) {
      throw const FormatException('Invalid time');
    }
    if (match[6] != null) {
      if (match[6] != 'Z') {
        final offset = match[6]!
            .substring(1)
            .split(':')
            .map(int.parse)
            .toList();
        if (offset[0] > 23 || offset[1] > 59) {
          throw const FormatException('Invalid offset');
        }
      }
      return DateTime.parse(text).toUtc();
    }
    // Google normally supplies offsets when UTC is requested. If it supplies
    // an IANA wall time, resolve it explicitly; never use the device's zone.
    final name = value['timeZone'] as String? ?? fallbackZone;
    if (name == null) throw const FormatException('Missing time zone');
    if (!_zonesInitialized) {
      tz_data.initializeTimeZones();
      _zonesInitialized = true;
    }
    final location = tz.getLocation(name);
    final wall = DateTime.parse('${text}Z');
    final candidates = <DateTime>{};
    for (final offset in location.zones.map((z) => z.offset).toSet()) {
      final instant = wall.subtract(offset);
      final local = tz.TZDateTime.from(instant, location);
      if (local.year == wall.year &&
          local.month == wall.month &&
          local.day == wall.day &&
          local.hour == wall.hour &&
          local.minute == wall.minute &&
          local.second == wall.second) {
        candidates.add(instant);
      }
    }
    // Reject nonexistent spring-forward times or ambiguous fall-back times.
    if (candidates.length != 1) {
      throw const FormatException('Ambiguous or nonexistent time');
    }
    return candidates.single;
  }
}

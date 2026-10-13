import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/calendar_account.dart';
import '../models/event.dart';
import 'calendar_credentials.dart';
import 'calendar_failure.dart';
import 'calendar_provider.dart';
import 'microsoft_calendar_auth.dart';

// One Graph reader for both Microsoft account categories. CalendarService still
// owns reconciliation, per-calendar visibility, persistence and local disconnect.
class MicrosoftCalendarProvider
    implements CalendarProvider, CalendarReauthorizingProvider {
  @override
  final CalendarProviderType type;
  final MicrosoftCalendarAuth auth;
  final http.Client _client;
  final Duration requestTimeout;
  static const _eventFields =
      'id,subject,start,end,isAllDay,isCancelled,originalStartTimeZone,originalEndTimeZone,onlineMeeting,onlineMeetingUrl,bodyPreview,type';

  MicrosoftCalendarProvider({
    required this.type,
    required this.auth,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 30),
  }) : _client = client ?? http.Client() {
    if (type == CalendarProviderType.google) {
      throw ArgumentError('Not a Microsoft provider');
    }
  }

  CalendarFailure _failure(CalendarFailureKind kind) =>
      CalendarFailure(kind, isMicrosoft: true);
  void _validateAccount(CalendarAccount account) {
    if (account.provider != type) throw _failure(CalendarFailureKind.response);
  }

  @override
  Future<CalendarConnection?> connect() => auth.connect(type);
  @override
  Future<CalendarConnection?> reconnect(CalendarAccount account) {
    _validateAccount(account);
    return auth.connect(type, expectedAccount: account);
  }

  Uri _uri(List<String> path, Map<String, String> query) => Uri(
    scheme: 'https',
    host: 'graph.microsoft.com',
    pathSegments: ['v1.0', 'me', ...path],
    queryParameters: query,
  );

  Future<Map<String, dynamic>> _get(
    CalendarAccount account,
    CalendarCredentialStore store,
    Uri uri, {
    String timeZone = 'UTC',
  }) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      final credentials = await auth.credentialsFor(account, store);
      http.Response response;
      try {
        final request = http.Request('GET', uri)
          ..followRedirects = false
          ..headers['Authorization'] = 'Bearer ${credentials.accessToken}'
          ..headers['Accept'] = 'application/json'
          ..headers['Prefer'] =
              'IdType="ImmutableId", outlook.timezone="$timeZone", outlook.body-content-type="text"';
        response = await (() async => http.Response.fromStream(
          await _client.send(request),
        ))().timeout(requestTimeout);
      } catch (_) {
        throw _failure(CalendarFailureKind.unavailable);
      }
      if (response.statusCode == 401) {
        if (attempt == 1) throw _failure(CalendarFailureKind.authorization);
        // Refresh once using this account's own refresh token; no consent UI.
        await auth.credentialsFor(account, store, forceRefresh: true);
        continue;
      }
      if (response.statusCode == 403) {
        throw _failure(CalendarFailureKind.authorization);
      }
      if (response.statusCode != 200) {
        throw _failure(CalendarFailureKind.unavailable);
      }
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        throw _failure(CalendarFailureKind.response);
      }
    }
    throw _failure(CalendarFailureKind.authorization);
  }

  Future<List<Map<String, dynamic>>> _pages(
    CalendarAccount account,
    CalendarCredentialStore store,
    Uri initial,
  ) async {
    final values = <Map<String, dynamic>>[];
    final seen = <String>{};
    Uri? uri = initial;
    while (uri != null) {
      // Graph nextLinks carry skip tokens. Never send credentials to another
      // origin, user/calendar route, or a redirected URL supplied in a response.
      if (uri.scheme != 'https' ||
          uri.host != 'graph.microsoft.com' ||
          uri.port != 443 ||
          uri.userInfo.isNotEmpty ||
          uri.hasFragment ||
          uri.path != initial.path ||
          !seen.add(uri.toString())) {
        throw _failure(CalendarFailureKind.response);
      }
      final page = await _get(account, store, uri);
      try {
        values.addAll((page['value'] as List).cast<Map<String, dynamic>>());
        final next = page['@odata.nextLink'] as String?;
        if (next?.isEmpty == true) throw const FormatException();
        uri = next == null ? null : initial.resolve(next);
      } catch (_) {
        throw _failure(CalendarFailureKind.response);
      }
    }
    return values;
  }

  @override
  Future<List<ConnectedCalendar>> listCalendars(
    CalendarAccount account,
    CalendarCredentialStore credentials,
  ) async {
    _validateAccount(account);
    final values = await _pages(
      account,
      credentials,
      _uri(['calendars'], {r'$top': '100', r'$select': 'id,name'}),
    );
    try {
      return [
        for (final value in values)
          ConnectedCalendar(
            accountId: account.id,
            id: value['id'] as String,
            name: value['name'] as String,
          ),
      ];
    } catch (_) {
      throw _failure(CalendarFailureKind.response);
    }
  }

  @override
  Future<CalendarEventSnapshot> fetchEvents(
    CalendarAccount account,
    ConnectedCalendar calendar,
    CalendarSyncWindow window,
    CalendarCredentialStore credentials,
  ) async {
    _validateAccount(account);
    if (calendar.accountId != account.id) {
      throw _failure(CalendarFailureKind.response);
    }
    final values = await _pages(
      account,
      credentials,
      _uri(
        ['calendars', calendar.id, 'calendarView'],
        {
          // Graph filters by instants, while all-day events belong to their
          // original calendar dates. Pad for opposing device/event time zones,
          // then restrict the completed snapshot to Daylock's date window.
          'startDateTime': window.start
              .toUtc()
              .subtract(const Duration(days: 2))
              .toIso8601String(),
          'endDateTime': window.endExclusive
              .toUtc()
              .add(const Duration(days: 2))
              .toIso8601String(),
          r'$top': '1000',
          r'$select': _eventFields,
        },
      ),
    );
    final events = <Event>[];
    final deleted = <String>{};
    try {
      for (var value in values) {
        // calendarView expands occurrences/exceptions; series-master IDs and
        // iCalUId must not merge separate recurring instances.
        final id = value['id'] as String;
        if (id.isEmpty) throw const FormatException();
        if (value['isCancelled'] == true || value.containsKey('@removed')) {
          deleted.add(id);
          continue;
        }
        if (value['type'] == 'seriesMaster') {
          throw const FormatException('Unexpanded recurrence');
        }
        if (value['isAllDay'] == true) {
          value = await _originalAllDay(account, calendar, credentials, value);
          if (value['isCancelled'] == true) {
            deleted.add(id);
            continue;
          }
        }
        final start = value['start'] as Map<String, dynamic>;
        final end = value['end'] as Map<String, dynamic>;
        final subject = (value['subject'] as String?)?.trim();
        final title = subject?.isNotEmpty == true ? subject! : 'Untitled event';
        final notes = value['bodyPreview'] as String?;
        final meeting = _meetingUrl(value);
        if (value['isAllDay'] == true) {
          events.add(
            Event.externalAllDay(
              source: type.eventSource,
              accountId: account.id,
              calendarId: calendar.id,
              externalEventId: id,
              title: title,
              notes: notes,
              meetingUrl: meeting,
              date: _wallDay(start),
              endDateExclusive: _wallDay(end),
            ),
          );
        } else if (value['isAllDay'] == false) {
          events.add(
            Event.externalTimed(
              source: type.eventSource,
              accountId: account.id,
              calendarId: calendar.id,
              externalEventId: id,
              title: title,
              notes: notes,
              meetingUrl: meeting,
              startsAtUtc: _instant(start),
              endsAtUtc: _instant(end),
            ),
          );
        } else {
          throw const FormatException('Missing all-day flag');
        }
      }
    } on CalendarFailure {
      rethrow;
    } catch (_) {
      throw _failure(CalendarFailureKind.response);
    }
    // Complete window replacement removes cancelled/deleted/moved instances
    // absent from the view, plus any explicit cancellation tombstones.
    return CalendarEventSnapshot(
      events: events
          .where(
            (event) => event.overlapsDates(window.start, window.endExclusive),
          )
          .toList(),
      deletedExternalIds: deleted,
      isComplete: true,
    );
  }

  Future<Map<String, dynamic>> _originalAllDay(
    CalendarAccount account,
    ConnectedCalendar calendar,
    CalendarCredentialStore store,
    Map<String, dynamic> value,
  ) async {
    final zone = value['originalStartTimeZone'] as String;
    // Use Graph itself to resolve Windows/IANA zones. UTC rendering may turn an
    // original midnight into the preceding/following date. Fetch only all-day
    // details in their original zone instead of guessing a Windows-zone mapping.
    if (!RegExp(r'^[A-Za-z0-9 _+./:-]{1,100}$').hasMatch(zone) ||
        zone.startsWith('tzone:')) {
      throw _failure(CalendarFailureKind.response);
    }
    if ((value['start'] as Map)['timeZone'] != zone ||
        (value['end'] as Map)['timeZone'] != zone) {
      final original = await _get(
        account,
        store,
        _uri(
          ['calendars', calendar.id, 'events', value['id'] as String],
          {r'$select': _eventFields},
        ),
        timeZone: zone,
      );
      if (original['id'] != value['id']) {
        throw _failure(CalendarFailureKind.response);
      }
      if (original['isCancelled'] == true) return original;
      if (original['isAllDay'] != true ||
          (original['start'] as Map)['timeZone'] != zone ||
          (original['end'] as Map)['timeZone'] != zone) {
        throw _failure(CalendarFailureKind.response);
      }
      return original;
    }
    return value;
  }

  DateTime _wallTime(String text) {
    final pattern = RegExp(
      r'^(\d{4}-\d{2}-\d{2})T(\d{2}):(\d{2}):(\d{2})(\.\d{1,9})?(Z|[+-]\d{2}:\d{2})?$',
    );
    final match = pattern.firstMatch(text);
    if (match == null) throw const FormatException('Invalid Graph time');
    final day = DateTime.parse(match[1]!);
    if (day.toIso8601String().substring(0, 10) != match[1] ||
        int.parse(match[2]!) > 23 ||
        int.parse(match[3]!) > 59 ||
        int.parse(match[4]!) > 59) {
      throw const FormatException('Invalid Graph calendar date/time');
    }
    final offset = match[6];
    if (offset != null &&
        offset != 'Z' &&
        (int.parse(offset.substring(1, 3)) > 23 ||
            int.parse(offset.substring(4, 6)) > 59)) {
      throw const FormatException('Invalid Graph UTC offset');
    }
    // Preserve these components before any UTC conversion for all-day dates.
    return DateTime.parse('${text.substring(0, 19)}${match[5] ?? ''}Z');
  }

  DateTime _instant(Map<String, dynamic> value) {
    final text = value['dateTime'] as String;
    _wallTime(text);
    if (RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(text)) {
      return DateTime.parse(text).toUtc();
    }
    if (value['timeZone'] != 'UTC') {
      throw const FormatException('Expected explicit Graph UTC');
    }
    return DateTime.parse('${text}Z');
  }

  DateTime _wallDay(Map<String, dynamic> value) {
    final wall = _wallTime(value['dateTime'] as String);
    if (wall.hour != 0 ||
        wall.minute != 0 ||
        wall.second != 0 ||
        wall.millisecond != 0 ||
        wall.microsecond != 0) {
      throw const FormatException(
        'All-day boundaries must be original midnight',
      );
    }
    return DateTime(wall.year, wall.month, wall.day);
  }

  Uri? _meetingUrl(Map<String, dynamic> value) {
    final candidates = [
      (value['onlineMeeting'] as Map?)?['joinUrl'],
      value['onlineMeetingUrl'],
    ];
    for (final text in candidates.whereType<String>()) {
      final uri = Uri.tryParse(text);
      if (uri != null &&
          {'https', 'http'}.contains(uri.scheme) &&
          uri.host.isNotEmpty) {
        return uri;
      }
    }
    return null;
  }
}

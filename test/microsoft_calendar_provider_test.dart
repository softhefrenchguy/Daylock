import 'dart:convert';

import 'package:daylock/models/calendar_account.dart';
import 'package:daylock/models/calendar_cache.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/services/calendar_failure.dart';
import 'package:daylock/services/calendar_provider.dart';
import 'package:daylock/services/calendar_service.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:daylock/services/microsoft_calendar_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'calendar_test_fixtures.dart';
import 'microsoft_calendar_test_fixtures.dart';

void main() {
  final account = microsoftAccount();
  final calendar = testCalendar(account, id: 'calendar');
  final window = CalendarSyncWindow(
    start: DateTime(2026, 10, 8),
    endExclusive: DateTime(2026, 10, 12),
  );
  late TestMicrosoftAuth auth;
  late MemoryCredentials store;
  setUp(() async {
    auth = TestMicrosoftAuth();
    store = MemoryCredentials();
    await store.write(
      account.id,
      (await auth.connect(account.provider))!.credentials,
    );
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('All calendar and calendarView pages use GET, immutable IDs, bounded UTC dates and no write permissions', () async {
    final requests = <http.Request>[];
    final provider = MicrosoftCalendarProvider(
      type: account.provider,
      auth: auth,
      client: MockClient((request) async {
        requests.add(request);
        expect(request.method, 'GET');
        expect(request.url.origin, 'https://graph.microsoft.com');
        expect(request.followRedirects, isFalse);
        expect(request.headers['Prefer'], contains('IdType="ImmutableId"'));
        expect(request.headers['Prefer'], contains('outlook.timezone="UTC"'));
        final next = request.url.queryParameters[r'$skiptoken'];
        final nextUri = next == null
            ? request.url.replace(
                queryParameters: {
                  ...request.url.queryParameters,
                  r'$skiptoken': 'page-two',
                },
              )
            : null;
        if (request.url.path.endsWith('/calendars')) {
          return graphPage([
            graphCalendar(id: next == null ? 'calendar' : 'encoded/A+='),
          ], next: nextUri);
        }
        expect(request.url.pathSegments.last, 'calendarView');
        expect(
          DateTime.parse(request.url.queryParameters['startDateTime']!),
          window.start.toUtc().subtract(const Duration(days: 2)),
        );
        expect(
          DateTime.parse(request.url.queryParameters['endDateTime']!),
          window.endExclusive.toUtc().add(const Duration(days: 2)),
        );
        return graphPage([
          {
            ...graphTimed(id: next == null ? 'occurrence-1' : 'exception-2'),
            'seriesMasterId': 'same-series',
            'iCalUId': 'same-fixture-id',
          },
          if (next != null) {'id': 'cancelled-3', 'isCancelled': true},
        ], next: nextUri);
      }),
    );
    final calendars = await provider.listCalendars(account, store);
    expect(calendars, hasLength(2));
    final snapshot = await provider.fetchEvents(
      account,
      calendars.last,
      window,
      store,
    );
    expect(snapshot.isComplete, isTrue);
    expect(snapshot.events.map((e) => e.id).toSet(), hasLength(2));
    expect(snapshot.deletedExternalIds, {'cancelled-3'});
    expect(
      snapshot.events.first.meetingUrl.toString(),
      'https://teams.microsoft.com/l/meetup-join/test',
    );
    expect(snapshot.events.first.notes, 'Meeting notes');
    expect(requests.last.url.pathSegments, [
      'v1.0',
      'me',
      'calendars',
      'encoded/A+=',
      'calendarView',
    ]);
    expect(requests, hasLength(4));
  });

  test('Personal and multiple work accounts coexist with Google; sync deduplicates and preserves visibility/persistence', () async {
    var phase = 0;
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/calendars')) {
        return graphPage([graphCalendar()]);
      }
      return graphPage(
        phase == 0
            ? [graphTimed(), graphTimed(id: 'deleted'), graphTimed(id: 'moved')]
            : [
                graphTimed(title: 'Updated Teams meeting'),
                {'id': 'deleted', 'isCancelled': true},
              ],
      );
    });
    final providers = [
      for (final type in [
        CalendarProviderType.microsoftPersonal,
        CalendarProviderType.microsoftWorkSchool,
      ])
        MicrosoftCalendarProvider(type: type, auth: auth, client: client),
    ];
    final service = CalendarService(
      credentials: store,
      providers: providers,
      now: () => microsoftTestNow,
    );
    final google = testAccount(CalendarProviderType.google);
    var cache = testCache(google);
    final accounts = [
      account,
      microsoftAccount(subject: 'second-personal'),
      microsoftAccount(
        type: CalendarProviderType.microsoftWorkSchool,
        subject: 'work-one',
      ),
      microsoftAccount(
        type: CalendarProviderType.microsoftWorkSchool,
        subject: 'work-two',
      ),
    ];
    for (final connected in accounts) {
      auth.selected = connected;
      cache = await service.connect(cache, connected.provider);
      cache = await service.synchronize(cache, connected.id, window);
    }
    expect(cache.accounts, hasLength(5));
    expect(cache.events, hasLength(13));
    cache = cache.setVisibility(account.id, 'calendar', false);
    phase = 1;
    cache = await service.synchronize(cache, account.id, window);
    cache = await service.synchronize(cache, account.id, window);
    expect(
      cache.events.where((e) => e.accountId == account.id).single.title,
      'Updated Teams meeting',
    );
    expect(cache.visibleEvents.any((e) => e.accountId == account.id), isFalse);
    expect(
      cache.events.where((e) => e.accountId == google.id).single.title,
      'Remote meeting',
    );
    expect(
      cache.events.where((e) => e.accountId == accounts[1].id),
      hasLength(3),
    );
    final state = DaylockState(
      todayPlan: DailyPlan(date: window.start, tasks: []),
      tomorrowPlan: DailyPlan(
        date: DateTime(2026, 10, 9),
        tasks: [],
        isCommitted: true,
      ),
      calendarCache: cache,
    );
    await LocalStorage().save(state);
    final restored = (await LocalStorage().load())!;
    expect(restored.toJson(), state.toJson());
    expect(jsonEncode(restored.toJson()), isNot(contains('refresh-')));
    final disconnected = await service.disconnect(cache, accounts[1].id);
    expect(disconnected.accounts, hasLength(4));
    expect(
      disconnected.events.any((e) => e.accountId == accounts[1].id),
      isFalse,
    );
    expect(disconnected.events.any((e) => e.accountId == google.id), isTrue);
  });

  test('401 renews only the affected account and retries once', () async {
    var calls = 0;
    final provider = MicrosoftCalendarProvider(
      type: account.provider,
      auth: auth,
      client: MockClient((request) async {
        calls++;
        if (calls == 1) return http.Response('', 401);
        expect(
          request.headers['Authorization'],
          'Bearer renewed-personal-user',
        );
        return graphPage([]);
      }),
    );
    expect(await provider.listCalendars(account, store), isEmpty);
    expect(auth.forcedRefreshes, [account.id]);
    expect(calls, 2);
  });

  test('Repeated 401 and denied organisational access preserve cache without prompting or repeated renewal', () async {
    for (final status in [401, 403]) {
      var calls = 0;
      auth.forcedRefreshes.clear();
      final provider = MicrosoftCalendarProvider(
        type: account.provider,
        auth: auth,
        client: MockClient((_) async {
          calls++;
          return http.Response('private diagnostic', status);
        }),
      );
      final service = CalendarService(
        credentials: store,
        providers: [provider],
      );
      final cache = CalendarCache(
        accounts: [account],
        calendars: [calendar],
        events: [testExternal(account, calendar: 'calendar')],
      );
      final previous = cache.toJson();
      await expectLater(
        service.synchronize(cache, account.id, window),
        throwsA(
          isA<CalendarFailure>()
              .having((e) => e.kind, 'kind', CalendarFailureKind.authorization)
              .having(
                (e) => e.message,
                'Microsoft message',
                contains('Microsoft'),
              ),
        ),
      );
      expect(calls, status == 401 ? 2 : 1);
      expect(auth.forcedRefreshes, status == 401 ? [account.id] : isEmpty);
      expect(cache.toJson(), previous);
    }
  });

  test('Offline, 429, server errors, redirects and malformed/partial pages retain previous cache', () async {
    for (final failure in [
      'offline',
      '429',
      '503',
      '302',
      'bad-json',
      'missing-value',
    ]) {
      final provider = MicrosoftCalendarProvider(
        type: account.provider,
        auth: auth,
        client: MockClient((request) async {
          if (request.url.path.endsWith('/calendars')) {
            return graphPage([graphCalendar()]);
          }
          if (request.url.queryParameters[r'$skiptoken'] == null) {
            return graphPage(
              [graphTimed(title: 'Partial update')],
              next: request.url.replace(
                queryParameters: {r'$skiptoken': 'next'},
              ),
            );
          }
          return switch (failure) {
            'offline' => throw http.ClientException('private-token diagnostic'),
            'bad-json' => http.Response('{', 200),
            'missing-value' => http.Response('{}', 200),
            _ => http.Response('private-token diagnostic', int.parse(failure)),
          };
        }),
      );
      final service = CalendarService(
        credentials: store,
        providers: [provider],
      );
      final cache = CalendarCache(
        accounts: [account],
        calendars: [calendar],
        events: [testExternal(account, calendar: 'calendar')],
      );
      final previous = cache.toJson();
      await expectLater(
        service.synchronize(cache, account.id, window),
        throwsA(isA<CalendarFailure>()),
      );
      expect(cache.toJson(), previous);
    }
  });

  test('Untrusted, cross-account, wrong-path and looping nextLinks never receive a token', () async {
    for (final next in [
      'https://attacker.test/steal',
      'http://graph.microsoft.com/v1.0/me/calendars',
      'https://graph.microsoft.com/v1.0/users/someone-else/calendars',
      'https://graph.microsoft.com/v1.0/me/events',
      'https://private@graph.microsoft.com/v1.0/me/calendars',
      'https://graph.microsoft.com:444/v1.0/me/calendars',
      'https://graph.microsoft.com/v1.0/me/calendars?loop=1',
    ]) {
      var calls = 0;
      final provider = MicrosoftCalendarProvider(
        type: account.provider,
        auth: auth,
        client: MockClient((request) async {
          calls++;
          expect(request.url.origin, 'https://graph.microsoft.com');
          return graphPage([graphCalendar()], next: Uri.parse(next));
        }),
      );
      await expectLater(
        provider.listCalendars(account, store),
        throwsA(isA<CalendarFailure>()),
      );
      expect(calls, next.contains('loop') ? 2 : 1);
    }
  });

  test('UTC and offset instants survive DST, overnight meetings and unsafe URL rejection', () async {
    final provider = MicrosoftCalendarProvider(
      type: account.provider,
      auth: auth,
      client: MockClient(
        (_) async => graphPage([
          graphTimed(
            id: 'dst',
            start: '2026-10-25T00:30:00.0000000',
            end: '2026-10-25T01:30:00.0000000',
          ),
          {
            ...graphTimed(
              id: 'overnight',
              start: '2026-10-09T23:30:00+09:00',
              end: '2026-10-10T01:30:00+09:00',
            ),
            'onlineMeeting': {'joinUrl': 'javascript:alert(1)'},
            'onlineMeetingUrl': 'https://example.test/legacy-meeting',
          },
        ]),
      ),
    );
    final events = (await provider.fetchEvents(
      account,
      calendar,
      CalendarSyncWindow(
        start: DateTime(2026, 10, 1),
        endExclusive: DateTime(2028, 3, 2),
      ),
      store,
    )).events;
    expect(events.first.startsAtUtc, DateTime.utc(2026, 10, 25, 0, 30));
    expect(
      events.first.endsAtUtc!.difference(events.first.startsAtUtc!).inHours,
      1,
    );
    expect(events.last.startsAtUtc, DateTime.utc(2026, 10, 9, 14, 30));
    expect(events.last.endsAtUtc, DateTime.utc(2026, 10, 9, 16, 30));
    expect(
      events.last.meetingUrl.toString(),
      'https://example.test/legacy-meeting',
    );
  });

  test('All-day events preserve original Windows-zone dates after UTC conversion across midnight/DST', () async {
    final headers = <String>[];
    final provider = MicrosoftCalendarProvider(
      type: account.provider,
      auth: auth,
      client: MockClient((request) async {
        headers.add(request.headers['Prefer']!);
        if (request.url.path.endsWith('/events/all-day')) {
          return http.Response(
            jsonEncode(
              graphAllDay(
                zone: 'GMT Standard Time',
                originalZone: 'GMT Standard Time',
                start: '2026-10-24T00:00:00.0000000',
                end: '2026-10-26T00:00:00.0000000',
              ),
            ),
            200,
          );
        }
        return graphPage([
          graphAllDay(
            originalZone: 'GMT Standard Time',
            start: '2026-10-23T23:00:00.0000000',
            end: '2026-10-26T00:00:00.0000000',
          ),
          graphAllDay(
            id: 'leap-day',
            start: '2028-02-29T00:00:00.0000000',
            end: '2028-03-01T00:00:00.0000000',
          ),
        ]);
      }),
    );
    final events = (await provider.fetchEvents(
      account,
      calendar,
      CalendarSyncWindow(
        start: DateTime(2026, 10, 1),
        endExclusive: DateTime(2028, 3, 2),
      ),
      store,
    )).events;
    expect(headers, hasLength(2));
    expect(headers.last, contains('outlook.timezone="GMT Standard Time"'));
    expect(events.first.date, DateTime(2026, 10, 24));
    expect(events.first.allDayEndDateExclusive, DateTime(2026, 10, 26));
    expect(events.first.occursOn(DateTime(2026, 10, 23)), isFalse);
    expect(events.first.occursOn(DateTime(2026, 10, 25)), isTrue);
    expect(events.first.occursOn(DateTime(2026, 10, 26)), isFalse);
    expect(events.last.date, DateTime(2028, 2, 29));
  });

  test(
    'Padded Graph queries preserve date-window boundaries for all-day events',
    () async {
      final provider = MicrosoftCalendarProvider(
        type: account.provider,
        auth: auth,
        client: MockClient(
          (_) async => graphPage([
            graphAllDay(
              id: 'previous',
              start: '2026-10-07T00:00:00',
              end: '2026-10-08T00:00:00',
            ),
            graphAllDay(
              id: 'first',
              start: '2026-10-08T00:00:00',
              end: '2026-10-09T00:00:00',
            ),
            graphAllDay(
              id: 'last',
              start: '2026-10-11T00:00:00',
              end: '2026-10-12T00:00:00',
            ),
            graphAllDay(
              id: 'next',
              start: '2026-10-12T00:00:00',
              end: '2026-10-13T00:00:00',
            ),
            graphTimed(
              id: 'outside',
              start: '2026-10-13T09:00:00Z',
              end: '2026-10-13T10:00:00Z',
            ),
          ]),
        ),
      );
      final snapshot = await provider.fetchEvents(
        account,
        calendar,
        window,
        store,
      );
      expect(snapshot.events.map((e) => e.externalEventId), ['first', 'last']);
      expect(snapshot.isComplete, isTrue);
    },
  );

  test('Unsupported custom zones, missing timezone tags, invalid dates and unexpanded series fail safely', () async {
    for (final value in [
      graphAllDay(originalZone: 'tzone://Microsoft/Custom'),
      {
        ...graphTimed(),
        'start': {
          'dateTime': '2026-10-09T10:00:00.0000000',
          'timeZone': 'Eastern Standard Time',
        },
      },
      graphTimed(start: '2026-02-30T10:00:00.0000000'),
      graphTimed(start: '2026-10-09T10:00:00+00:99'),
      {...graphTimed(), 'type': 'seriesMaster'},
      graphAllDay(start: '2026-10-09T01:00:00.0000000'),
    ]) {
      final provider = MicrosoftCalendarProvider(
        type: account.provider,
        auth: auth,
        client: MockClient((_) async => graphPage([value])),
      );
      await expectLater(
        provider.fetchEvents(account, calendar, window, store),
        throwsA(isA<CalendarFailure>()),
      );
    }
  });

  test('All-day detail failure does not discard offline events', () async {
    final provider = MicrosoftCalendarProvider(
      type: account.provider,
      auth: auth,
      client: MockClient((request) async {
        if (request.url.path.endsWith('/calendars')) {
          return graphPage([graphCalendar()]);
        }
        if (request.url.path.contains('/events/')) {
          return http.Response('Unavailable', 503);
        }
        return graphPage([graphAllDay(originalZone: 'Pacific Standard Time')]);
      }),
    );
    final service = CalendarService(credentials: store, providers: [provider]);
    final cache = CalendarCache(
      accounts: [account],
      calendars: [calendar],
      events: [testExternal(account, calendar: 'calendar')],
    );
    final previous = cache.toJson();
    await expectLater(
      service.synchronize(cache, account.id, window),
      throwsA(isA<CalendarFailure>()),
    );
    expect(cache.toJson(), previous);
  });
}

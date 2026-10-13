import 'dart:convert';

import 'package:daylock/models/calendar_account.dart';
import 'package:daylock/models/calendar_cache.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/services/calendar_failure.dart';
import 'package:daylock/services/calendar_provider.dart';
import 'package:daylock/services/calendar_service.dart';
import 'package:daylock/services/google_calendar_provider.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'calendar_test_fixtures.dart';
import 'google_calendar_test_fixtures.dart';

void main() {
  final account = testAccount(CalendarProviderType.google);
  final calendar = testCalendar(account);
  final window = CalendarSyncWindow(
    start: DateTime(2026, 10, 8),
    endExclusive: DateTime(2026, 10, 12),
  );
  late TestGoogleAuth auth;
  late MemoryCredentials store;
  setUp(() {
    auth = TestGoogleAuth();
    store = MemoryCredentials();
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test(
    'Collects every calendar and event page using only read-only GETs',
    () async {
      final requests = <http.Request>[];
      final provider = GoogleCalendarProvider(
        auth: auth,
        client: MockClient((request) async {
          requests.add(request);
          expect(request.method, 'GET');
          expect(request.url.origin, 'https://www.googleapis.com');
          expect(request.followRedirects, isFalse);
          expect(
            request.headers['Authorization'],
            startsWith('Bearer renewed-'),
          );
          final next = request.url.queryParameters['pageToken'];
          if (request.url.path.endsWith('calendarList')) {
            expect(request.url.queryParameters['showHidden'], 'true');
            expect(request.url.queryParameters['minAccessRole'], 'reader');
            return googlePage(
              'calendar#calendarList',
              items: [
                googleCalendar(
                  id: next == null ? 'primary' : 'other/@example.test',
                ),
              ],
              next: next == null ? 'next-calendars' : null,
            );
          }
          final query = request.url.queryParameters;
          expect(query['singleEvents'], 'true');
          expect(query['showDeleted'], 'true');
          expect(query['timeZone'], 'UTC');
          expect(DateTime.parse(query['timeMin']!), window.start.toUtc());
          expect(
            DateTime.parse(query['timeMax']!),
            window.endExclusive.toUtc(),
          );
          expect(query.containsKey('syncToken'), isFalse);
          return googlePage(
            'calendar#events',
            items: [
              {
                ...googleTimed(
                  id: next == null ? 'series_20261009' : 'series_20261010',
                ),
                'recurringEventId': 'series',
                'iCalUID': 'same-series-ical',
              },
              if (next != null)
                {'id': 'series_cancelled', 'status': 'cancelled'},
            ],
            next: next == null ? 'next-events' : null,
          );
        }),
      );
    final calendars = await provider.listCalendars(account, store);
    expect(calendars, hasLength(2));
    expect(ConnectedCalendar.fromJson(calendar.toJson()).timeZone, isNull);
      expect(calendars.last.timeZone, 'Europe/London');
      expect(
        ConnectedCalendar.fromJson(calendars.last.toJson()).timeZone,
        'Europe/London',
      );
      final snapshot = await provider.fetchEvents(
        account,
        calendars.last,
        window,
        store,
      );
      expect(snapshot.isComplete, isTrue);
      expect(snapshot.events.map((e) => e.externalEventId), [
        'series_20261009',
        'series_20261010',
      ]);
      expect(snapshot.events.map((e) => e.id).toSet(), hasLength(2));
      expect(snapshot.deletedExternalIds, {'series_cancelled'});
      expect(requests.last.url.pathSegments, [
        'calendar',
        'v3',
        'calendars',
        'other/@example.test',
        'events',
      ]);
      expect(requests, hasLength(4));
    },
  );

  test('Repeated sync, cancellations and moved instances reconcile; separate accounts never collide', () async {
    var phase = 0;
    final provider = GoogleCalendarProvider(
      auth: auth,
      client: MockClient((request) async {
        if (request.url.path.endsWith('calendarList')) {
          return googlePage('calendar#calendarList', items: [googleCalendar()]);
        }
        return googlePage(
          'calendar#events',
          items: phase == 0
              ? [
                  googleTimed(id: 'same-id'),
                  googleTimed(id: 'removed'),
                  googleTimed(id: 'moved'),
                ]
              : [
                  {
                    ...googleTimed(id: 'same-id', title: 'Edited occurrence'),
                    'start': {'dateTime': '2026-10-09T12:00:00Z'},
                    'end': {'dateTime': '2026-10-09T13:00:00Z'},
                  },
                  {'id': 'removed', 'status': 'cancelled'},
                ],
        );
      }),
    );
    final service = CalendarService(credentials: store, providers: [provider]);
    var cache = await service.connect(CalendarCache.empty, provider.type);
    cache = await service.synchronize(cache, account.id, window);
    final second = testAccount(CalendarProviderType.google, subject: 'second');
    auth.selected = second;
    cache = await service.connect(cache, provider.type);
    cache = await service.synchronize(cache, second.id, window);
    expect(cache.events, hasLength(6));
    cache = cache.setVisibility(account.id, 'primary', false);
    phase = 1;
    cache = await service.synchronize(cache, account.id, window);
    cache = await service.synchronize(cache, account.id, window);
    expect(
      cache.events.where((e) => e.accountId == account.id).single.title,
      'Edited occurrence',
    );
    expect(cache.events.where((e) => e.accountId == second.id), hasLength(3));
    expect(cache.visibleEvents.every((e) => e.accountId == second.id), isTrue);
    expect(auth.authorized, [account.id, second.id, account.id, account.id]);
    expect(store.values.keys.toSet(), {account.id, second.id});

    final state = DaylockState(
      todayPlan: DailyPlan(date: window.start, tasks: []),
      tomorrowPlan: DailyPlan(
        date: DateTime(2026, 10, 9),
        tasks: [],
        isCommitted: true,
      ),
      calendarCache: cache,
    );
    final storage = LocalStorage();
    await storage.save(state);
    final saved = (await storage.load())!;
    expect(saved.toJson(), state.toJson());
    expect(jsonEncode(saved.toJson()), isNot(contains('renewed-')));
    expect(saved.todayPlan.tasks, isEmpty);
    expect(saved.tomorrowPlan.isCommitted, isTrue);
  });

  test(
    '401 invalidates and renews the same account token then retries once',
    () async {
      var requests = 0;
      final provider = GoogleCalendarProvider(
        auth: auth,
        client: MockClient((request) async {
          requests++;
          if (requests == 1) return http.Response('', 401);
          expect(request.headers['Authorization'], 'Bearer renewed-subject-2');
          return googlePage('calendar#calendarList');
        }),
      );
      expect(await provider.listCalendars(account, store), isEmpty);
      expect(auth.invalidated, ['renewed-subject-1']);
      expect(auth.authorized, [account.id, account.id]);
      expect(store.values[account.id]!.accessToken, 'renewed-subject-2');
      expect(requests, 2);
    },
  );

  test(
    'Revoked permissions and repeated 401s preserve cache without looping',
    () async {
      var requests = 0;
      final provider = GoogleCalendarProvider(
        auth: auth,
        client: MockClient((request) async {
          requests++;
          return http.Response('', 401);
        }),
      );
      final service = CalendarService(
        credentials: store,
        providers: [provider],
      );
      await service.connect(CalendarCache.empty, provider.type);
      final cache = testCache(account);
      final old = cache.toJson();
      await expectLater(
        service.synchronize(cache, account.id, window),
        throwsA(
          isA<CalendarFailure>().having(
            (e) => e.kind,
            'kind',
            CalendarFailureKind.authorization,
          ),
        ),
      );
      expect(requests, 2);
      expect(cache.toJson(), old);
      auth.failure = const CalendarFailure(CalendarFailureKind.authorization);
      await expectLater(
        service.synchronize(cache, account.id, window),
        throwsA(isA<CalendarFailure>()),
      );
      expect(requests, 2);
      expect(cache.toJson(), old);
    },
  );

  for (final entry in <String, CalendarFailureKind>{
    'insufficientPermissions': CalendarFailureKind.authorization,
    'accessNotConfigured': CalendarFailureKind.configuration,
    'rateLimitExceeded': CalendarFailureKind.unavailable,
  }.entries) {
    test('403 ${entry.key} has a safe actionable error', () async {
      final provider = GoogleCalendarProvider(
        auth: auth,
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'error': {
                'message': 'private-token-or-details',
                'errors': [
                  {'reason': entry.key},
                ],
              },
            }),
            403,
          ),
        ),
      );
      await expectLater(
        provider.listCalendars(account, store),
        throwsA(
          isA<CalendarFailure>()
              .having((e) => e.kind, 'kind', entry.value)
              .having(
                (e) => e.message,
                'message',
                isNot(contains('private-token-or-details')),
              ),
        ),
      );
      expect(auth.invalidated, isEmpty);
    });
  }

  test('Network failures, missing pages, malformed responses and looping pagination cannot replace cache', () async {
    for (final failure in [
      'offline',
      '429',
      '500',
      'bad-json',
      'wrong-kind',
      'loop',
    ]) {
      final provider = GoogleCalendarProvider(
        auth: auth,
        client: MockClient((request) async {
          if (request.url.path.endsWith('calendarList')) {
            return googlePage(
              'calendar#calendarList',
              items: [googleCalendar()],
            );
          }
          if (request.url.queryParameters['pageToken'] == null) {
            return googlePage(
              'calendar#events',
              items: [googleTimed(title: 'Partial update')],
              next: 'page-two',
            );
          }
          return switch (failure) {
            'offline' => throw http.ClientException('private diagnostic'),
            '429' => http.Response('', 429),
            '500' => http.Response('', 500),
            'bad-json' => http.Response('{', 200),
            'wrong-kind' => http.Response('{}', 200),
            _ => googlePage('calendar#events', next: 'page-two'),
          };
        }),
      );
      final service = CalendarService(
        credentials: store,
        providers: [provider],
      );
      await service.connect(CalendarCache.empty, provider.type);
      final cache = testCache(account);
      final previous = cache.toJson();
      await expectLater(
        service.synchronize(cache, account.id, window),
        throwsA(isA<CalendarFailure>()),
      );
      expect(cache.toJson(), previous);
    }
  });

  test('Timed offsets, DST, all-day exclusive ranges, notes and meeting URLs are preserved', () async {
    await store.write(account.id, (await auth.authorize(account)));
    final provider = GoogleCalendarProvider(
      auth: auth,
      client: MockClient(
        (_) async => googlePage(
          'calendar#events',
          items: [
            {
              ...googleTimed(
                start: '2026-10-25T01:30:00+01:00',
                end: '2026-10-25T01:30:00+00:00',
              ),
              'description': 'Meet about Chapter 7',
              'hangoutLink': 'https://meet.google.com/abc-defg-hij',
            },
            {
              ...googleTimed(
                id: 'other-zone',
                start: '2026-10-09T00:30:00+09:00',
                end: '2026-10-09T01:30:00+09:00',
              ),
              'conferenceData': {
                'entryPoints': [
                  {
                    'entryPointType': 'video',
                    'uri': 'https://example.test/call',
                  },
                ],
              },
            },
            {
              'id': 'all-day',
              'start': {'date': '2028-02-29'},
              'end': {'date': '2028-03-02'},
            },
          ],
        ),
      ),
    );
    final snapshot = await provider.fetchEvents(
      account,
      calendar,
      window,
      store,
    );
    final timed = snapshot.events.first;
    expect(timed.startsAtUtc, DateTime.utc(2026, 10, 25, 0, 30));
    expect(timed.endsAtUtc, DateTime.utc(2026, 10, 25, 1, 30));
    expect(timed.notes, 'Meet about Chapter 7');
    expect(timed.meetingUrl.toString(), 'https://meet.google.com/abc-defg-hij');
    expect(snapshot.events[1].startsAtUtc, DateTime.utc(2026, 10, 8, 15, 30));
    final allDay = snapshot.events.last;
    expect(allDay.title, 'Untitled event');
    expect(allDay.occursOn(DateTime(2028, 2, 29)), isTrue);
    expect(allDay.occursOn(DateTime(2028, 3, 1)), isTrue);
    expect(allDay.occursOn(DateTime(2028, 3, 2)), isFalse);
  });

  test(
    'Explicit IANA wall times resolve independently of the device zone',
    () async {
      await store.write(account.id, await auth.authorize(account));
      final provider = GoogleCalendarProvider(
        auth: auth,
        client: MockClient(
          (_) async => googlePage(
            'calendar#events',
            items: [
              googleTimed(
                start: '2026-07-09T10:00:00',
                end: '2026-07-09T11:00:00',
                zone: 'Europe/London',
              ),
              googleTimed(
                id: 'ny',
                start: '2026-07-09T10:00:00',
                end: '2026-07-09T11:00:00',
                zone: 'America/New_York',
              ),
            ],
          ),
        ),
      );
      final events = (await provider.fetchEvents(
        account,
        calendar,
        window,
        store,
      )).events;
      expect(events[0].startsAtUtc, DateTime.utc(2026, 7, 9, 9));
      expect(events[1].startsAtUtc, DateTime.utc(2026, 7, 9, 14));
    },
  );

  test('Unknown zones, ambiguous/nonexistent wall times and invalid dates fail safely', () async {
    await store.write(account.id, await auth.authorize(account));
    for (final event in [
      googleTimed(
        start: '2026-03-29T01:30:00',
        end: '2026-03-29T03:00:00',
        zone: 'Europe/London',
      ),
      googleTimed(
        start: '2026-10-25T01:30:00',
        end: '2026-10-25T03:00:00',
        zone: 'Europe/London',
      ),
      googleTimed(
        start: '2026-10-09T01:30:00',
        end: '2026-10-09T03:00:00',
        zone: 'Not/AZone',
      ),
      googleTimed(start: '2026-02-30T10:00:00Z'),
      googleTimed(start: '2026-10-09T25:30:00Z'),
      {
        'id': 'invalid-day',
        'start': {'date': '2026-02-30'},
        'end': {'date': '2026-03-02'},
      },
    ]) {
      final provider = GoogleCalendarProvider(
        auth: auth,
        client: MockClient(
          (_) async => googlePage('calendar#events', items: [event]),
        ),
      );
      await expectLater(
        provider.fetchEvents(account, calendar, window, store),
        throwsA(isA<CalendarFailure>()),
      );
    }
  });

  test('Reconnect restores only matching account credentials, keeps cache and handles cancellation', () async {
    final provider = GoogleCalendarProvider(
      auth: auth,
      client: MockClient((_) async => googlePage('calendar#events')),
    );
    final service = CalendarService(credentials: store, providers: [provider]);
    final cache = testCache(account);
    expect(service.canReconnect(CalendarProviderType.google), isTrue);
    expect(service.canConnect(CalendarProviderType.microsoftPersonal), isFalse);
    final reconnected = await service.reconnect(cache, account.id);
    expect(auth.expected!.id, account.id);
    expect(reconnected.toJson(), cache.toJson());
    expect(store.values[account.id]!.accessToken, 'connected-subject');
    auth.selected = testAccount(CalendarProviderType.google, subject: 'wrong');
    await expectLater(
      service.reconnect(cache, account.id),
      throwsFormatException,
    );
    expect(store.values[account.id]!.accessToken, 'connected-subject');
    auth.selected = null;
    expect(
      identical(await service.reconnect(cache, account.id), cache),
      isTrue,
    );
    final disconnected = await service.disconnect(cache, account.id);
    expect(disconnected.events, isEmpty);
    expect(store.values, isEmpty);
  });
}

import 'dart:convert';

import 'package:daylock/models/calendar_account.dart';
import 'package:daylock/models/calendar_cache.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/event.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/services/calendar_credentials.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'calendar_test_fixtures.dart';

DaylockState _state({CalendarCache? cache}) => DaylockState(
  todayPlan: DailyPlan(
    date: DateTime(2026, 10, 8),
    tasks: [Task(name: 'Gym', type: TaskType.goal, isCompleted: true)],
    isCommitted: true,
  ),
  tomorrowPlan: DailyPlan(
    date: DateTime(2026, 10, 9),
    tasks: [
      Task(
        name: 'Read',
        type: TaskType.focus,
        accumulatedFocusMilliseconds: 120000,
      ),
    ],
    isCommitted: true,
  ),
  events: [
    Event(id: 'local', title: 'Driving lesson', date: DateTime(2026, 10, 10)),
  ],
  calendarCache: cache ?? CalendarCache.empty,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('Account IDs distinguish providers, users, and work tenants and survive serialization', () {
    final accounts = [
      for (final type in CalendarProviderType.values) testAccount(type),
      testAccount(CalendarProviderType.google, subject: 'second'),
      testAccount(CalendarProviderType.microsoftWorkSchool, tenant: 'tenant-a'),
      testAccount(CalendarProviderType.microsoftWorkSchool, tenant: 'tenant-b'),
    ];
    expect(accounts.map((a) => a.id).toSet(), hasLength(6));
    for (final account in accounts) {
      expect(CalendarAccount.fromJson(account.toJson()).id, account.id);
    }
  });

  test(
    'External events round trip with meeting URL and stable scoped identities',
    () {
      final account = testAccount(CalendarProviderType.google);
      final event = testExternal(account);
      expect(Event.fromJson(event.toJson()).toJson(), event.toJson());
      expect(event.isExternal, isTrue);
      expect(event.meetingUrl.toString(), 'https://example.test/meeting');
      expect(testExternal(account, title: 'Renamed').id, event.id);
      expect(testExternal(account, calendar: 'other').id, isNot(event.id));
      expect(
        testExternal(testAccount(CalendarProviderType.google, subject: 'other'))
            .id,
        isNot(event.id),
      );
    },
  );

  test('UTC instants normalize offsets and reject zone-less times', () {
    final account = testAccount(CalendarProviderType.microsoftPersonal);
    final event = Event.externalTimed(
      source: account.provider.eventSource,
      accountId: account.id,
      calendarId: 'primary',
      externalEventId: 'offset',
      title: 'Offset meeting',
      startsAtUtc: DateTime.parse('2026-10-09T14:00:00+02:00'),
      endsAtUtc: DateTime.parse('2026-10-09T15:00:00+02:00'),
    );
    expect(event.startsAtUtc, DateTime.utc(2026, 10, 9, 12));
    final local = event.startsAtUtc!.toLocal();
    expect(event.occursOn(local), isTrue);
    expect(
      event.timeLabelForDate(local),
      '${EventTime(local.hour, local.minute)}–${EventTime(local.hour + 1, local.minute)}',
    );
    expect(
      () => Event.fromJson({
        ...event.toJson(),
        'startsAtUtc': '2026-10-09T12:00:00',
      }),
      throwsFormatException,
    );
  });

  test('Overnight and midnight endings use exclusive boundaries', () {
    final account = testAccount(CalendarProviderType.google);
    Event timed(DateTime end) => Event.externalTimed(
      source: account.provider.eventSource,
      accountId: account.id,
      calendarId: 'primary',
      externalEventId: 'overnight',
      title: 'Overnight',
      startsAtUtc: DateTime(2026, 10, 8, 23, 30).toUtc(),
      endsAtUtc: end.toUtc(),
    );
    final overnight = timed(DateTime(2026, 10, 9, 1));
    expect(overnight.occursOn(DateTime(2026, 10, 8)), isTrue);
    expect(overnight.occursOn(DateTime(2026, 10, 9)), isTrue);
    expect(overnight.occursOn(DateTime(2026, 10, 10)), isFalse);
    expect(overnight.timeLabelForDate(DateTime(2026, 10, 8)), '23:30–Next day');
    expect(overnight.timeLabelForDate(DateTime(2026, 10, 9)), 'Earlier–01:00');
    expect(
      timed(DateTime(2026, 10, 9)).occursOn(DateTime(2026, 10, 9)),
      isFalse,
    );
  });

  test(
    'All-day spans preserve dates across leap day without shifting zones',
    () {
      final account = testAccount(CalendarProviderType.microsoftWorkSchool);
      final event = Event.externalAllDay(
        source: account.provider.eventSource,
        accountId: account.id,
        calendarId: 'primary',
        externalEventId: 'all',
        title: 'Away',
        date: DateTime.utc(2028, 2, 28),
        endDateExclusive: DateTime.utc(2028, 3, 1),
      );
      expect(event.date, DateTime(2028, 2, 28));
      expect(event.occursOn(DateTime(2028, 2, 29)), isTrue);
      expect(event.occursOn(DateTime(2028, 3, 1)), isFalse);
      expect(Event.fromJson(event.toJson()).toJson(), event.toJson());
    },
  );

  test('Timed events on DST transition dates compare calendar boundaries', () {
    final account = testAccount(CalendarProviderType.google);
    final start = DateTime(2026, 10, 25);
    final next = DateTime(2026, 10, 26);
    final event = Event.externalTimed(
      source: account.provider.eventSource,
      accountId: account.id,
      calendarId: 'primary',
      externalEventId: 'dst',
      title: 'DST day',
      startsAtUtc: start.toUtc(),
      endsAtUtc: next.toUtc(),
    );
    expect(event.occursOn(start), isTrue);
    expect(event.occursOn(next), isFalse);
    expect(event.timeLabelForDate(start), 'Continues all day');
  });

  test('Invalid cache ownership, duplicate identities, and unsafe URLs are rejected', () {
    final account = testAccount(CalendarProviderType.google);
    final event = testExternal(account);
    expect(
      () => CalendarCache(
        accounts: [account],
        calendars: [testCalendar(account)],
        events: [event, event],
      ),
      throwsFormatException,
    );
    expect(() => CalendarCache(events: [event]), throwsFormatException);
    expect(
      () => CalendarCache(
        accounts: [account],
        calendars: [testCalendar(account)],
        events: [Event(id: 'x', title: 'Local', date: DateTime(2026, 10, 9))],
      ),
      throwsFormatException,
    );
    expect(
      () => Event.fromJson({
        ...event.toJson(),
        'meetingUrl': 'javascript:alert(1)',
      }),
      throwsFormatException,
    );
    expect(
      () => Event.fromJson({...event.toJson(), 'calendarId': 'forged'}),
      throwsFormatException,
    );
  });

  test('Persistence and rollover retain separate local/external events and visibility', () async {
    final account = testAccount(CalendarProviderType.google);
    final cache = testCache(account)
        .setVisibility(account.id, 'primary', false);
    final state = _state(cache: cache);
    await LocalStorage().save(state);
    final restored = (await LocalStorage().load())!;
    expect(restored.toJson(), state.toJson());
    expect(restored.events.single.isExternal, isFalse);
    expect(restored.calendarCache.events.single.isExternal, isTrue);
    expect(restored.calendarCache.visibleEvents, isEmpty);
    final rolled = restored.rollOver(DateTime(2026, 10, 9));
    expect(rolled.calendarCache.toJson(), cache.toJson());
    expect(rolled.events.single.id, 'local');
    expect(rolled.todayPlan.tasks.single.name, 'Read');
    expect(rolled.todayPlan.tasks.single.accumulatedFocusMilliseconds, 120000);
    expect(rolled.tomorrowPlan.tasks, isEmpty);
  });

  test('Pre-integration saves migrate local source and empty accounts without changing plans', () async {
    final old = _state().toJson()..remove('calendarCache');
    (old['events'] as List).single.remove('source');
    final prefs = SharedPreferencesAsync();
    await prefs.setString(LocalStorage.stateKey, jsonEncode(old));
    final restored = (await LocalStorage().load())!;
    expect(restored.calendarCache.accounts, isEmpty);
    expect(restored.events.single.source, EventSource.local);
    expect(restored.todayPlan.toJson(), old['todayPlan']);
    expect(restored.tomorrowPlan.toJson(), old['tomorrowPlan']);
    expect(
      jsonDecode((await prefs.getString(LocalStorage.stateKey))!),
      restored.toJson(),
    );
  });

  test('Corrupt external cache stays intact rather than being silently migrated empty', () async {
    final old = jsonEncode({..._state().toJson(), 'calendarCache': null});
    final prefs = SharedPreferencesAsync();
    await prefs.setString(LocalStorage.stateKey, old);
    await expectLater(LocalStorage().load(), throwsA(isA<TypeError>()));
    expect(await prefs.getString(LocalStorage.stateKey), old);
  });

  test('Credentials use secure storage; ordinary state snapshots contain no tokens', () async {
    final account = testAccount(CalendarProviderType.google);
    final credentials = CalendarCredentials(
      accessToken: 'private-access-value',
      refreshToken: 'private-refresh-value',
      expiresAt: DateTime.utc(2026, 10, 9),
    );
    await SecureCalendarCredentialStore().write(account.id, credentials);
    await LocalStorage().save(_state(cache: testCache(account)));
    final json = (await SharedPreferencesAsync().getString(
      LocalStorage.stateKey,
    ))!;
    expect(json, isNot(contains('private-access-value')));
    expect(json, isNot(contains('private-refresh-value')));
    expect(json, isNot(contains('accessToken')));
    final restored = (await SecureCalendarCredentialStore().read(account.id))!;
    expect(restored.toSecureJson(), credentials.toSecureJson());
    await SecureCalendarCredentialStore().delete(account.id);
    expect(await SecureCalendarCredentialStore().read(account.id), isNull);
  });

  test('Secure reset removes only Daylock calendar credentials', () async {
    final store = SecureCalendarCredentialStore();
    final platform = const FlutterSecureStorage();
    await store.write('a', CalendarCredentials(accessToken: 'a-token'));
    await store.write('b', CalendarCredentials(accessToken: 'b-token'));
    await platform.write(key: 'unrelated.secret', value: 'keep');
    await store.clearDaylockCredentials();
    expect(await store.read('a'), isNull);
    expect(await store.read('b'), isNull);
    expect(await platform.read(key: 'unrelated.secret'), 'keep');
  });
}

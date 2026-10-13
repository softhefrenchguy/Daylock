import 'package:daylock/models/calendar_account.dart';
import 'package:daylock/models/calendar_cache.dart';
import 'package:daylock/services/calendar_provider.dart';
import 'package:daylock/services/calendar_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'calendar_test_fixtures.dart';

void main() {
  final window = CalendarSyncWindow(
    start: DateTime(2026, 10, 8),
    endExclusive: DateTime(2026, 10, 12),
  );

  test('Connects multiple accounts across all three provider types without merging identities', () async {
    final credentials = MemoryCredentials();
    final providers = CalendarProviderType.values
        .map(TestCalendarProvider.new)
        .toList();
    final service = CalendarService(
      credentials: credentials,
      providers: providers,
    );
    var cache = CalendarCache.empty;
    for (final provider in providers) {
      cache = await service.connect(cache, provider.type);
      cache = await service.synchronize(
        cache,
        provider.nextAccount!.id,
        window,
      );
    }
    final google = providers.first;
    google.nextAccount = testAccount(
      CalendarProviderType.google,
      subject: 'second-google',
    );
    cache = await service.connect(cache, google.type);
    cache = await service.synchronize(cache, google.nextAccount!.id, window);
    expect(cache.accounts, hasLength(4));
    expect(cache.events, hasLength(4));
    expect(cache.events.map((e) => e.id).toSet(), hasLength(4));
    expect(credentials.values, hasLength(4));
    final again = await service.connect(cache, google.type);
    expect(again.accounts, hasLength(4));
    expect(again.events, hasLength(4));
  });

  test('Repeated sync replaces changes without duplicates and preserves hidden calendars', () async {
    final provider = TestCalendarProvider(CalendarProviderType.google);
    final credentials = MemoryCredentials();
    final service = CalendarService(
      credentials: credentials,
      providers: [provider],
      now: () => DateTime.utc(2026, 10, 8, 9),
    );
    var cache = await service.connect(CalendarCache.empty, provider.type);
    final account = cache.accounts.single;
    cache = await service.synchronize(cache, account.id, window);
    cache = cache.setVisibility(account.id, 'primary', false);
    final changed = testExternal(account, title: 'Updated meeting');
    provider.snapshots[testCalendar(account).key] = CalendarEventSnapshot(
      events: [changed, changed],
      isComplete: true,
    );
    cache = await service.synchronize(cache, account.id, window);
    cache = await service.synchronize(cache, account.id, window);
    expect(cache.events.single.title, 'Updated meeting');
    expect(cache.visibleEvents, isEmpty);
    expect(cache.calendars.single.lastSyncedAt, DateTime.utc(2026, 10, 8, 9));
    expect(
      cache.setVisibility(account.id, 'primary', true).visibleEvents,
      hasLength(1),
    );
  });

  test('Snapshot removes missing/cancelled events only in its scope and honours tombstones', () async {
    final provider = TestCalendarProvider(CalendarProviderType.google);
    final credentials = MemoryCredentials();
    final service = CalendarService(
      credentials: credentials,
      providers: [provider],
    );
    var cache = await service.connect(CalendarCache.empty, provider.type);
    final account = cache.accounts.single;
    final other = testAccount(CalendarProviderType.microsoftPersonal);
    final removed = testExternal(account, id: 'deleted');
    final outside = testExternal(
      account,
      id: 'outside',
      date: DateTime(2027, 1, 2, 9),
    );
    final outsideCancelled = testExternal(
      account,
      id: 'cancelled-outside',
      date: DateTime(2027, 1, 2, 9),
    );
    final kept = testExternal(other);
    cache = CalendarCache(
      accounts: [account, other],
      calendars: [testCalendar(account), testCalendar(other)],
      events: [removed, outside, outsideCancelled, kept],
    );
    provider.snapshots[testCalendar(account).key] = CalendarEventSnapshot(
      events: [],
      deletedExternalIds: ['cancelled-outside'],
      isComplete: true,
    );
    final updated = await service.synchronize(cache, account.id, window);
    expect(updated.events.map((e) => e.id).toSet(), {outside.id, kept.id});
    expect(cache.events, hasLength(4));
  });

  test(
    'Removed calendar caches are purged without changing another account',
    () async {
      final provider = TestCalendarProvider(CalendarProviderType.google);
      final credentials = MemoryCredentials();
      final service = CalendarService(
        credentials: credentials,
        providers: [provider],
      );
      var cache = await service.connect(CalendarCache.empty, provider.type);
      final account = cache.accounts.single;
      final other = testAccount(CalendarProviderType.microsoftWorkSchool);
      cache = CalendarCache(
        accounts: [account, other],
        calendars: [testCalendar(account), testCalendar(other)],
        events: [testExternal(account), testExternal(other)],
      );
      provider.calendarsByAccount[account.id] = [];
      final updated = await service.synchronize(cache, account.id, window);
      expect(updated.accounts, hasLength(2));
      expect(updated.calendars.single.accountId, other.id);
      expect(updated.events.single.accountId, other.id);
    },
  );

  test('Failed or incomplete sync never clears offline events or modifies the old snapshot', () async {
    final provider = TestCalendarProvider(CalendarProviderType.google);
    final credentials = MemoryCredentials();
    final service = CalendarService(
      credentials: credentials,
      providers: [provider],
    );
    var cache = await service.connect(CalendarCache.empty, provider.type);
    final account = cache.accounts.single;
    cache = await service.synchronize(cache, account.id, window);
    final previous = cache.toJson();
    provider.failFetch = true;
    await expectLater(
      service.synchronize(cache, account.id, window),
      throwsStateError,
    );
    provider.failFetch = false;
    provider.snapshots[testCalendar(account).key] = CalendarEventSnapshot(
      events: [],
      isComplete: false,
    );
    await expectLater(
      service.synchronize(cache, account.id, window),
      throwsStateError,
    );
    expect(cache.toJson(), previous);
  });

  test('Invalid snapshots and discovery lists cannot cross account or calendar boundaries', () async {
    final provider = TestCalendarProvider(CalendarProviderType.google);
    final service = CalendarService(
      credentials: MemoryCredentials(),
      providers: [provider],
    );
    var cache = await service.connect(CalendarCache.empty, provider.type);
    final account = cache.accounts.single;
    cache = await service.synchronize(cache, account.id, window);
    provider.snapshots[testCalendar(account).key] = CalendarEventSnapshot(
      events: [
        testExternal(
          testAccount(CalendarProviderType.google, subject: 'someone-else'),
        ),
      ],
      isComplete: true,
    );
    await expectLater(
      service.synchronize(cache, account.id, window),
      throwsFormatException,
    );
    provider.calendarsByAccount[account.id] = [
      testCalendar(account),
      testCalendar(account),
    ];
    await expectLater(
      service.synchronize(cache, account.id, window),
      throwsFormatException,
    );
    expect(cache.events, hasLength(1));
  });

  test('Cancelled sign-in is a no-op and unavailable providers do not simulate connection', () async {
    final provider = TestCalendarProvider(CalendarProviderType.google)
      ..nextAccount = null;
    final credentials = MemoryCredentials();
    final service = CalendarService(
      credentials: credentials,
      providers: [provider],
    );
    expect(
      identical(
        await service.connect(CalendarCache.empty, provider.type),
        CalendarCache.empty,
      ),
      isTrue,
    );
    expect(credentials.values, isEmpty);
    expect(service.canConnect(CalendarProviderType.microsoftPersonal), isFalse);
    await expectLater(
      service.connect(
        CalendarCache.empty,
        CalendarProviderType.microsoftPersonal,
      ),
      throwsStateError,
    );
  });

  test('Secure storage failures do not publish new connections or disconnect cached accounts', () async {
    final provider = TestCalendarProvider(CalendarProviderType.google);
    final credentials = MemoryCredentials()..failWrite = true;
    final service = CalendarService(
      credentials: credentials,
      providers: [provider],
    );
    await expectLater(
      service.connect(CalendarCache.empty, provider.type),
      throwsStateError,
    );
    expect(CalendarCache.empty.accounts, isEmpty);
    credentials.failWrite = false;
    var cache = await service.connect(CalendarCache.empty, provider.type);
    final account = cache.accounts.single;
    cache = await service.synchronize(cache, account.id, window);
    credentials.failDelete = true;
    await expectLater(service.disconnect(cache, account.id), throwsStateError);
    expect(cache.events, hasLength(1));
    credentials.failDelete = false;
    final updated = await service.disconnect(cache, account.id);
    expect(updated.accounts, isEmpty);
    expect(updated.calendars, isEmpty);
    expect(updated.events, isEmpty);
    expect(credentials.values, isEmpty);
  });
}

import 'dart:async';

import 'package:daylock/models/calendar_account.dart';
import 'package:daylock/services/calendar_credentials.dart';
import 'package:daylock/services/calendar_failure.dart';
import 'package:daylock/services/microsoft_calendar_auth.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'calendar_test_fixtures.dart';
import 'microsoft_calendar_test_fixtures.dart';

void main() {
  late TestAppAuth appAuth;
  late NativeMicrosoftCalendarAuth auth;
  late MemoryCredentials store;
  setUp(() {
    appAuth = TestAppAuth();
    store = MemoryCredentials();
    auth = NativeMicrosoftCalendarAuth(
      config: const MicrosoftCalendarConfig(clientId: microsoftTestClient),
      appAuth: appAuth,
      now: () => microsoftTestNow,
    );
  });

  test('No invented client ID or interactive flow when unconfigured', () async {
    expect(
      const MicrosoftCalendarConfig.fromEnvironment().isConfigured,
      isFalse,
    );
    final empty = NativeMicrosoftCalendarAuth(
      config: const MicrosoftCalendarConfig(clientId: ''),
      appAuth: appAuth,
    );
    await expectLater(
      empty.connect(CalendarProviderType.microsoftPersonal),
      throwsA(isA<CalendarFailure>()),
    );
    expect(appAuth.authorizations, isEmpty);
  });

  test('Personal/work authorization uses code flow, account chooser, minimal scopes and no secret', () async {
    final personal = (await auth.connect(
      CalendarProviderType.microsoftPersonal,
    ))!;
    appAuth.selected = microsoftAccount(
      type: CalendarProviderType.microsoftWorkSchool,
      subject: 'work',
    );
    final work = (await auth.connect(
      CalendarProviderType.microsoftWorkSchool,
    ))!;
    expect(personal.account.provider, CalendarProviderType.microsoftPersonal);
    expect(personal.account.tenantId, MicrosoftCalendarConfig.consumerTenant);
    expect(work.account.tenantId, microsoftTestTenant);
    expect(personal.account.id, isNot(work.account.id));
    expect(
      appAuth.authorizations[0].serviceConfiguration!.authorizationEndpoint,
      'https://login.microsoftonline.com/consumers/oauth2/v2.0/authorize',
    );
    expect(
      appAuth.authorizations[1].serviceConfiguration!.tokenEndpoint,
      'https://login.microsoftonline.com/organizations/oauth2/v2.0/token',
    );
    for (final request in appAuth.authorizations) {
      expect(request.grantType, GrantType.authorizationCode);
      expect(request.clientSecret, isNull);
      expect(request.allowInsecureConnections, isFalse);
      expect(request.redirectUrl, MicrosoftCalendarConfig.redirectUri);
      expect(request.promptValues, ['select_account']);
      expect(request.scopes, NativeMicrosoftCalendarAuth.scopes);
      expect(request.scopes!.where((s) => s.startsWith('https://graph')), [
        'https://graph.microsoft.com/Calendars.Read',
      ]);
      // Combined exchange delegates nonce/state/PKCE generation to native AppAuth.
      expect(request.codeVerifier, isNull);
    }
  });

  test('Cancelling sign-in is a no-op', () async {
    appAuth.failure = FlutterAppAuthUserCancelledException(
      code: 'user-cancelled',
      platformErrorDetails: FlutterAppAuthPlatformErrorDetails(),
    );
    expect(await auth.connect(CalendarProviderType.microsoftPersonal), isNull);
    expect(store.values, isEmpty);
  });

  test('Reconnect checks subject AND tenant and targets the saved work tenant', () async {
    final work = microsoftAccount(
      type: CalendarProviderType.microsoftWorkSchool,
      subject: 'work',
    );
    appAuth.selected = work;
    expect(
      (await auth.connect(work.provider, expectedAccount: work))!.account.id,
      work.id,
    );
    final request = appAuth.authorizations.single;
    expect(request.loginHint, work.email);
    expect(
      request.serviceConfiguration!.authorizationEndpoint,
      'https://login.microsoftonline.com/$microsoftTestTenant/oauth2/v2.0/authorize',
    );
    appAuth.selected = microsoftAccount(
      type: work.provider,
      subject: 'someone-else',
    );
    await expectLater(
      auth.connect(work.provider, expectedAccount: work),
      throwsA(
        isA<CalendarFailure>().having(
          (e) => e.kind,
          'kind',
          CalendarFailureKind.accountMismatch,
        ),
      ),
    );
    appAuth.selected = microsoftAccount(
      type: work.provider,
      subject: 'work',
      tenant: '33333333-3333-3333-3333-333333333333',
    );
    await expectLater(
      auth.connect(work.provider, expectedAccount: work),
      throwsA(isA<CalendarFailure>()),
    );
  });

  test('ID-token issuer/audience/expiry and account-category checks reject invalid responses', () async {
    for (final overrides in [
      {'iss': 'https://untrusted.test/issuer'},
      {'aud': 'another-client'},
      {'exp': 0},
      {'tid': 'not-a-tenant'},
      {'oid': ''},
      {
        'tid': microsoftTestTenant,
        'iss': 'https://login.microsoftonline.com/$microsoftTestTenant/v2.0',
      },
    ]) {
      appAuth.authorizationResponse = AuthorizationTokenResponse(
        'test-access',
        'test-refresh',
        microsoftTestNow.add(const Duration(hours: 1)),
        microsoftIdToken(appAuth.selected, overrides: overrides),
        'Bearer',
        null,
        null,
        null,
      );
      await expectLater(
        auth.connect(CalendarProviderType.microsoftPersonal),
        throwsA(isA<CalendarFailure>()),
      );
    }
  });

  test('Expired/forced refresh rotates secure credentials separately for multiple tenants and personal accounts', () async {
    final accounts = [
      microsoftAccount(),
      microsoftAccount(
        type: CalendarProviderType.microsoftWorkSchool,
        subject: 'work',
      ),
      microsoftAccount(
        type: CalendarProviderType.microsoftWorkSchool,
        subject: 'work',
        tenant: '33333333-3333-3333-3333-333333333333',
      ),
    ];
    for (var i = 0; i < accounts.length; i++) {
      await store.write(
        accounts[i].id,
        CalendarCredentials(
          accessToken: 'old-$i',
          refreshToken: 'refresh-$i',
          expiresAt: microsoftTestNow.subtract(const Duration(minutes: 5)),
        ),
      );
    }
    for (final account in accounts) {
      final value = await auth.credentialsFor(account, store);
      expect(store.values[account.id], same(value));
      expect(value.refreshToken, startsWith('rotated-refresh-'));
    }
    expect(appAuth.refreshes.map((r) => r.refreshToken), [
      'refresh-0',
      'refresh-1',
      'refresh-2',
    ]);
    expect(
      appAuth.refreshes[1].serviceConfiguration!.tokenEndpoint,
      'https://login.microsoftonline.com/$microsoftTestTenant/oauth2/v2.0/token',
    );
    expect(
      appAuth.refreshes[2].serviceConfiguration!.tokenEndpoint,
      'https://login.microsoftonline.com/33333333-3333-3333-3333-333333333333/oauth2/v2.0/token',
    );
    final current = store.values[accounts.first.id]!;
    expect(await auth.credentialsFor(accounts.first, store), same(current));
    expect(appAuth.refreshes, hasLength(3));
    await auth.credentialsFor(accounts.first, store, forceRefresh: true);
    expect(appAuth.refreshes.last.refreshToken, 'rotated-refresh-0');
    expect(appAuth.refreshes.every((r) => r.clientSecret == null), isTrue);
  });

  test('Concurrent renewal shares one account refresh and preserves an omitted rotated refresh token', () async {
    final account = microsoftAccount();
    await store.write(
      account.id,
      CalendarCredentials(
        accessToken: 'old',
        refreshToken: 'keep-this-refresh',
      ),
    );
    final pending = Completer<TokenResponse>();
    appAuth.refreshHandler = (_) => pending.future;
    final requests = List.generate(
      3,
      (_) => auth.credentialsFor(account, store),
    );
    await Future<void>.delayed(Duration.zero);
    expect(appAuth.refreshes, hasLength(1));
    pending.complete(
      TokenResponse(
        'renewed',
        null,
        microsoftTestNow.add(const Duration(hours: 1)),
        null,
        'Bearer',
        null,
        null,
      ),
    );
    final results = await Future.wait(requests);
    expect(results.every((r) => r.accessToken == 'renewed'), isTrue);
    expect(store.values[account.id]!.refreshToken, 'keep-this-refresh');
  });

  for (final entry in {
    'invalid_grant': CalendarFailureKind.authorization,
    'interaction_required': CalendarFailureKind.authorization,
    'invalid_client': CalendarFailureKind.configuration,
    'consent_required': CalendarFailureKind.adminConsent,
    'temporarily_unavailable': CalendarFailureKind.unavailable,
  }.entries) {
    test(
      '${entry.key} preserves credentials and displays only a safe Microsoft message',
      () async {
        final account = microsoftAccount();
        final old = CalendarCredentials(
          accessToken: 'old-access',
          refreshToken: 'private-refresh',
        );
        await store.write(account.id, old);
        appAuth.failure = microsoftOAuthError(
          entry.key,
          description: 'private-refresh personal diagnostic',
        );
        await expectLater(
          auth.credentialsFor(account, store),
          throwsA(
            isA<CalendarFailure>()
                .having((e) => e.kind, 'kind', entry.value)
                .having(
                  (e) => e.message,
                  'safe message',
                  isNot(contains('private-refresh')),
                ),
          ),
        );
        expect(store.values[account.id], same(old));
        expect(appAuth.authorizations, isEmpty); // Never show UI during sync.
      },
    );
  }

  test('Admin-consent and conditional-access policy codes explain the IT approval requirement', () async {
    for (final code in ['65001', '90094', '53003']) {
      appAuth.failure = microsoftOAuthError(
        'access_denied',
        description: 'AADSTS$code: private diagnostic',
      );
      await expectLater(
        auth.connect(CalendarProviderType.microsoftWorkSchool),
        throwsA(
          isA<CalendarFailure>()
              .having((e) => e.kind, 'kind', CalendarFailureKind.adminConsent)
              .having(
                (e) => e.message,
                'IT message',
                contains('IT administrator'),
              ),
        ),
      );
    }
  });

  test('Missing refresh tokens, reduced permissions and secure-storage failures never publish invalid renewal', () async {
    final account = microsoftAccount();
    await store.write(account.id, CalendarCredentials(accessToken: 'old'));
    await expectLater(
      auth.credentialsFor(account, store),
      throwsA(isA<CalendarFailure>()),
    );
    expect(appAuth.refreshes, isEmpty);
    final previous = CalendarCredentials(
      accessToken: 'old',
      refreshToken: 'refresh',
    );
    await store.write(account.id, previous);
    appAuth.refreshHandler = (_) async => TokenResponse(
      'new',
      'rotated',
      microsoftTestNow.add(const Duration(hours: 1)),
      null,
      'Bearer',
      ['openid'],
      null,
    );
    await expectLater(
      auth.credentialsFor(account, store),
      throwsA(isA<CalendarFailure>()),
    );
    expect(store.values[account.id], same(previous));
    appAuth.refreshHandler = null;
    store.failWrite = true;
    await expectLater(auth.credentialsFor(account, store), throwsStateError);
    expect(store.values[account.id], same(previous));
  });
}

import 'package:daylock/models/calendar_account.dart';
import 'package:daylock/services/calendar_failure.dart';
import 'package:daylock/services/google_calendar_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

import 'calendar_test_fixtures.dart';

class _NativePlatform extends GoogleSignInPlatform {
  final initializations = <InitParameters>[];
  final requests = <AuthorizationRequestDetails>[];
  final cleared = <String>[];
  var signOutCount = 0;
  String subject = 'first';
  String? token = 'native-access';
  GoogleSignInException? failure;
  bool failInitialization = false;

  @override
  Future<void> init(InitParameters params) async {
    initializations.add(params);
    if (failInitialization) throw StateError('Native init failed');
  }

  @override
  Future<void> signOut(SignOutParams params) async => signOutCount++;

  @override
  Future<AuthenticationResults> authenticate(
    AuthenticateParameters params,
  ) async {
    if (failure != null) throw failure!;
    expect(params.scopeHint, NativeGoogleCalendarAuth.scopes);
    return AuthenticationResults(
      user: GoogleSignInUserData(id: subject, email: '$subject@example.test'),
      authenticationTokens: const AuthenticationTokenData(
        idToken: 'not-a-calendar-token',
      ),
    );
  }

  @override
  Future<ClientAuthorizationTokenData?> clientAuthorizationTokensForScopes(
    ClientAuthorizationTokensForScopesParameters params,
  ) async {
    requests.add(params.request);
    if (failure != null) throw failure!;
    return token == null
        ? null
        : ClientAuthorizationTokenData(accessToken: token!);
  }

  @override
  Future<void> clearAuthorizationToken(
    ClearAuthorizationTokenParams params,
  ) async => cleared.add(params.accessToken);

  // Any accidental call to broad revocation, server auth codes or another flow
  // fails this fake. No live SDK or OAuth credentials are used in these tests.
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  const config = GoogleCalendarConfig(
    serverClientId: 'test-public.apps.googleusercontent.com',
  );
  late _NativePlatform platform;
  late NativeGoogleCalendarAuth auth;
  setUp(() {
    platform = _NativePlatform();
    auth = NativeGoogleCalendarAuth(config: config, platform: platform);
  });

  test('Unconfigured builds cannot start OAuth', () async {
    final unconfigured = NativeGoogleCalendarAuth(
      config: const GoogleCalendarConfig(serverClientId: ''),
      platform: platform,
    );
    expect(const GoogleCalendarConfig.fromEnvironment().isConfigured, isFalse);
    expect(
      const GoogleCalendarConfig(serverClientId: 'secret-or-invalid')
          .isConfigured,
      isFalse,
    );
    await expectLater(unconfigured.connect(), throwsA(isA<CalendarFailure>()));
    expect(platform.initializations, isEmpty);
  });

  test('Connects two accounts with explicit read-only consent without revoking the first', () async {
    final first = (await auth.connect())!;
    platform.subject = 'second';
    final second = (await auth.connect())!;
    expect(first.account.id, isNot(second.account.id));
    expect(first.account.displayName, 'first@example.test');
    expect(first.credentials.accessToken, 'native-access');
    expect(first.credentials.refreshToken, isNull);
    expect(first.credentials.expiresAt, isNull);
    expect(
      platform.initializations.single.serverClientId,
      config.serverClientId,
    );
    expect(platform.signOutCount, 2);
    expect(platform.requests.map((r) => r.userId), ['first', 'second']);
    expect(platform.requests.every((r) => r.promptIfUnauthorized), isTrue);
    for (final request in platform.requests) {
      expect(request.scopes, NativeGoogleCalendarAuth.scopes);
      expect(request.scopes.every((s) => s.endsWith('.readonly')), isTrue);
    }
  });

  test('After restart, silent authorization targets each saved account, not the last login', () async {
    final first = testAccount(CalendarProviderType.google, subject: 'first');
    final second = testAccount(CalendarProviderType.google, subject: 'second');
    await auth.authorize(first);
    await auth.authorize(second);
    await auth.authorize(first);
    expect(platform.signOutCount, 0);
    expect(platform.requests.map((r) => r.email), [
      first.email,
      second.email,
      first.email,
    ]);
    expect(platform.requests.map((r) => r.userId), [
      'first',
      'second',
      'first',
    ]);
    expect(platform.requests.every((r) => !r.promptIfUnauthorized), isTrue);
  });

  test('Cancelled chooser makes no connection; revoked consent requires explicit reconnect', () async {
    platform.failure = const GoogleSignInException(
      code: GoogleSignInExceptionCode.canceled,
    );
    expect(await auth.connect(), isNull);
    platform.failure = null;
    platform.token = null;
    await expectLater(
      auth.authorize(testAccount(CalendarProviderType.google)),
      throwsA(
        isA<CalendarFailure>().having(
          (e) => e.kind,
          'kind',
          CalendarFailureKind.authorization,
        ),
      ),
    );
    expect(platform.requests.single.promptIfUnauthorized, isFalse);
  });

  test('Reconnect cannot overwrite another saved Google account', () async {
    final expected = testAccount(
      CalendarProviderType.google,
      subject: 'second',
    );
    await expectLater(
      auth.connect(expectedAccount: expected),
      throwsA(isA<CalendarFailure>()),
    );
    expect(platform.requests, isEmpty);
    platform.subject = 'second';
    expect(
      (await auth.connect(expectedAccount: expected))!.account.id,
      expected.id,
    );
  });

  test(
    'Configuration errors are safe and initialization can be retried',
    () async {
      platform.failInitialization = true;
      await expectLater(auth.connect(), throwsA(isA<CalendarFailure>()));
      platform.failInitialization = false;
      platform.failure = const GoogleSignInException(
        code: GoogleSignInExceptionCode.clientConfigurationError,
        description: 'private SDK diagnostic test-token',
      );
      await expectLater(
        auth.connect(),
        throwsA(
          isA<CalendarFailure>().having(
            (e) => e.message,
            'safe message',
            isNot(contains('test-token')),
          ),
        ),
      );
      expect(platform.initializations, hasLength(2));
      platform.failure = null;
      await auth.invalidate('expired-access');
      expect(platform.cleared, ['expired-access']);
    },
  );

  test(
    'Missing saved email cannot silently authorize a different account',
    () async {
      final account = CalendarAccount(
        provider: CalendarProviderType.google,
        providerAccountId: 'old-subject',
        displayName: 'Old cache',
      );
      await expectLater(
        auth.authorize(account),
        throwsA(isA<CalendarFailure>()),
      );
      expect(platform.requests, isEmpty);
    },
  );
}

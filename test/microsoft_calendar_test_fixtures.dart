import 'dart:convert';

import 'package:daylock/models/calendar_account.dart';
import 'package:daylock/services/calendar_credentials.dart';
import 'package:daylock/services/calendar_failure.dart';
import 'package:daylock/services/calendar_provider.dart';
import 'package:daylock/services/microsoft_calendar_auth.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:http/http.dart' as http;

const microsoftTestClient = '11111111-1111-1111-1111-111111111111';
const microsoftTestTenant = '22222222-2222-2222-2222-222222222222';
final microsoftTestNow = DateTime.utc(2026, 10, 8, 9);

CalendarAccount microsoftAccount({
  CalendarProviderType type = CalendarProviderType.microsoftPersonal,
  String subject = 'personal-user',
  String? tenant,
}) => CalendarAccount(
  provider: type,
  providerAccountId: subject,
  tenantId:
      tenant ??
      (type == CalendarProviderType.microsoftPersonal
          ? MicrosoftCalendarConfig.consumerTenant
          : microsoftTestTenant),
  displayName: 'Microsoft $subject',
  email: '$subject@example.test',
);

String microsoftIdToken(
  CalendarAccount account, {
  Map<String, dynamic> overrides = const {},
}) {
  String encode(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${encode({'alg': 'RS256'})}.${encode({'iss': 'https://login.microsoftonline.com/${account.tenantId}/v2.0', 'tid': account.tenantId, 'oid': account.providerAccountId, 'sub': 'pairwise-subject', 'aud': microsoftTestClient, 'name': account.displayName, 'preferred_username': account.email, 'exp': microsoftTestNow.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000, ...overrides})}.test-signature'; // Test-only: native AppAuth is replaced by this fixture.
}

class TestAppAuth extends FlutterAppAuth {
  CalendarAccount selected = microsoftAccount();
  final authorizations = <AuthorizationTokenRequest>[];
  final refreshes = <TokenRequest>[];
  Object? failure;
  AuthorizationTokenResponse? authorizationResponse;
  Future<TokenResponse> Function(TokenRequest)? refreshHandler;

  @override
  Future<AuthorizationTokenResponse> authorizeAndExchangeCode(
    AuthorizationTokenRequest request,
  ) async {
    authorizations.add(request);
    if (failure != null) throw failure!;
    return authorizationResponse ??
        AuthorizationTokenResponse(
          'access-${selected.providerAccountId}',
          'refresh-${selected.providerAccountId}',
          microsoftTestNow.add(const Duration(hours: 1)),
          microsoftIdToken(selected),
          'Bearer',
          NativeMicrosoftCalendarAuth.scopes,
          null,
          null,
        );
  }

  @override
  Future<TokenResponse> token(TokenRequest request) async {
    refreshes.add(request);
    if (failure != null) throw failure!;
    if (refreshHandler != null) return refreshHandler!(request);
    return TokenResponse(
      'renewed-${request.refreshToken}',
      'rotated-${request.refreshToken}',
      microsoftTestNow.add(const Duration(hours: 1)),
      null,
      'Bearer',
      null,
      null,
    );
  }
}

FlutterAppAuthPlatformException microsoftOAuthError(
  String error, {
  String? description,
}) => FlutterAppAuthPlatformException(
  code: 'test-oauth-error',
  platformErrorDetails: FlutterAppAuthPlatformErrorDetails(
    error: error,
    errorDescription: description,
  ),
);

class TestMicrosoftAuth implements MicrosoftCalendarAuth {
  CalendarAccount? selected;
  CalendarAccount? expected;
  CalendarFailure? failure;
  final forcedRefreshes = <String>[];
  @override
  Future<CalendarConnection?> connect(
    CalendarProviderType type, {
    CalendarAccount? expectedAccount,
  }) async {
    expected = expectedAccount;
    final account =
        selected ??
        microsoftAccount(
          type: type,
          subject: type == CalendarProviderType.microsoftPersonal
              ? 'personal-user'
              : 'work-user',
        );
    return CalendarConnection(
      account: account,
      credentials: CalendarCredentials(
        accessToken: 'access-${account.providerAccountId}',
        refreshToken: 'refresh-${account.providerAccountId}',
        expiresAt: microsoftTestNow.add(const Duration(hours: 1)),
      ),
    );
  }

  @override
  Future<CalendarCredentials> credentialsFor(
    CalendarAccount account,
    CalendarCredentialStore store, {
    bool forceRefresh = false,
  }) async {
    if (failure != null) throw failure!;
    if (forceRefresh) {
      forcedRefreshes.add(account.id);
      final value = CalendarCredentials(
        accessToken: 'renewed-${account.providerAccountId}',
      );
      await store.write(account.id, value);
      return value;
    }
    return (await store.read(account.id))!;
  }
}

http.Response graphPage(List<Object?> values, {Uri? next}) => http.Response(
  jsonEncode({'value': values, '@odata.nextLink': ?next?.toString()}),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, Object?> graphCalendar({String id = 'calendar'}) => {
  'id': id,
  'name': 'Outlook $id',
};
Map<String, Object?> graphTimed({
  String id = 'instance',
  String title = 'Teams meeting',
  String start = '2026-10-09T10:00:00.0000000',
  String end = '2026-10-09T11:00:00.0000000',
}) => {
  'id': id,
  'subject': title,
  'type': 'occurrence',
  'isAllDay': false,
  'isCancelled': false,
  'start': {'dateTime': start, 'timeZone': 'UTC'},
  'end': {'dateTime': end, 'timeZone': 'UTC'},
  'bodyPreview': 'Meeting notes',
  'onlineMeeting': {
    'joinUrl': 'https://teams.microsoft.com/l/meetup-join/test',
  },
};
Map<String, Object?> graphAllDay({
  String id = 'all-day',
  String title = 'All-day appointment',
  String zone = 'UTC',
  String originalZone = 'UTC',
  String start = '2026-10-09T00:00:00.0000000',
  String end = '2026-10-10T00:00:00.0000000',
}) => {
  'id': id,
  'subject': title,
  'type': 'singleInstance',
  'isAllDay': true,
  'isCancelled': false,
  'originalStartTimeZone': originalZone,
  'originalEndTimeZone': originalZone,
  'start': {'dateTime': start, 'timeZone': zone},
  'end': {'dateTime': end, 'timeZone': zone},
};

import 'dart:convert';

import 'package:flutter_appauth/flutter_appauth.dart';

import '../models/calendar_account.dart';
import 'calendar_credentials.dart';
import 'calendar_failure.dart';
import 'calendar_provider.dart';

class MicrosoftCalendarConfig {
  static const redirectUri = 'com.example.daylock.microsoft://oauth/redirect';
  static const consumerTenant = '9188040d-6c67-4c5b-b112-36a304b66dad';
  static final _guid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  final String clientId;
  const MicrosoftCalendarConfig({required this.clientId});
  const MicrosoftCalendarConfig.fromEnvironment()
    : clientId = const String.fromEnvironment('MICROSOFT_CLIENT_ID');
  bool get isConfigured => _guid.hasMatch(clientId);
  static bool isTenant(String? value) => value != null && _guid.hasMatch(value);
}

abstract interface class MicrosoftCalendarAuth {
  Future<CalendarConnection?> connect(
    CalendarProviderType type, {
    CalendarAccount? expectedAccount,
  });
  Future<CalendarCredentials> credentialsFor(
    CalendarAccount account,
    CalendarCredentialStore store, {
    bool forceRefresh = false,
  });
}

// AppAuth owns browser authorization, state/nonce, S256 PKCE and the TLS code
// exchange. No tokens are read from redirect parameters or browser storage.
// Unlike a single current-user session, each refresh uses the saved account's
// own secure refresh token and tenant. Graph access tokens are treated as opaque.
class NativeMicrosoftCalendarAuth implements MicrosoftCalendarAuth {
  static const scopes = [
    'openid',
    'profile',
    'email',
    'offline_access',
    'https://graph.microsoft.com/Calendars.Read',
  ];
  final MicrosoftCalendarConfig config;
  final FlutterAppAuth _appAuth;
  final DateTime Function() _now;
  final _refreshes = <String, Future<CalendarCredentials>>{};

  NativeMicrosoftCalendarAuth({
    required this.config,
    FlutterAppAuth? appAuth,
    DateTime Function()? now,
  }) : _appAuth = appAuth ?? const FlutterAppAuth(),
       _now = now ?? DateTime.now;

  CalendarFailure _failure(CalendarFailureKind kind) =>
      CalendarFailure(kind, isMicrosoft: true);

  void _configured() {
    if (!config.isConfigured) throw _failure(CalendarFailureKind.configuration);
  }

  String _authority(CalendarProviderType type, [CalendarAccount? account]) {
    if (type == CalendarProviderType.microsoftPersonal) return 'consumers';
    if (type != CalendarProviderType.microsoftWorkSchool) {
      throw _failure(CalendarFailureKind.configuration);
    }
    if (account == null) return 'organizations';
    if (!MicrosoftCalendarConfig.isTenant(account.tenantId) ||
        account.tenantId!.toLowerCase() ==
            MicrosoftCalendarConfig.consumerTenant) {
      throw _failure(CalendarFailureKind.authorization);
    }
    return account.tenantId!;
  }

  AuthorizationServiceConfiguration _endpoints(
    String authority,
  ) => AuthorizationServiceConfiguration(
    // Explicit trusted endpoints avoid treating the multi-tenant discovery
    // document's {tenantid} issuer template as a concrete OIDC issuer.
    authorizationEndpoint:
        'https://login.microsoftonline.com/$authority/oauth2/v2.0/authorize',
    tokenEndpoint:
        'https://login.microsoftonline.com/$authority/oauth2/v2.0/token',
  );

  CalendarFailure _oauthFailure(FlutterAppAuthPlatformException error) {
    final details = error.platformErrorDetails;
    final description = details.errorDescription ?? '';
    if (RegExp(r'AADSTS(?:65001|65004|90094|53003|50105)\b')
            .hasMatch(description) ||
        details.error == 'consent_required') {
      return _failure(CalendarFailureKind.adminConsent);
    }
    if ({
      'invalid_client',
      'unauthorized_client',
      'invalid_scope',
      'invalid_request',
    }.contains(details.error)) {
      return _failure(CalendarFailureKind.configuration);
    }
    if ({
      'invalid_grant',
      'interaction_required',
      'login_required',
      'access_denied',
    }.contains(details.error)) {
      return _failure(CalendarFailureKind.authorization);
    }
    return _failure(CalendarFailureKind.unavailable);
  }

  CalendarCredentials _credentials(
    TokenResponse response, {
    String? previousRefreshToken,
  }) {
    if (response.accessToken?.isNotEmpty != true ||
        response.tokenType?.toLowerCase() != 'bearer') {
      throw _failure(CalendarFailureKind.response);
    }
    final granted = response.scopes;
    if (granted != null &&
        !granted.any(
          (s) =>
              s == 'Calendars.Read' ||
              s == 'https://graph.microsoft.com/Calendars.Read',
        )) {
      throw _failure(CalendarFailureKind.authorization);
    }
    return CalendarCredentials(
      accessToken: response.accessToken!,
      refreshToken: response.refreshToken?.isNotEmpty == true
          ? response.refreshToken
          : previousRefreshToken,
      expiresAt: response.accessTokenExpirationDateTime,
    );
  }

  CalendarAccount _account(String? idToken, CalendarProviderType type) {
    // Read only the ID token returned by AppAuth's successful PKCE/TLS exchange.
    // Native AppAuth checks audience, expiry and nonce. Supplement issuer/tenant
    // checks because our endpoints deliberately use no templated discovery issuer.
    // This is not a JWT verifier for arbitrary externally supplied tokens.
    try {
      final parts = idToken!.split('.');
      if (parts.length != 3 || parts[2].isEmpty) throw const FormatException();
      final claims = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      final tenant = (claims['tid'] as String).toLowerCase();
      final subject = claims['oid'] as String;
      if (!MicrosoftCalendarConfig.isTenant(tenant) ||
          subject.trim().isEmpty ||
          claims['iss'] != 'https://login.microsoftonline.com/$tenant/v2.0' ||
          (claims['aud'] as String).toLowerCase() !=
              config.clientId.toLowerCase() ||
          (claims['exp'] as num) * 1000 <=
              _now().toUtc().millisecondsSinceEpoch ||
          (type == CalendarProviderType.microsoftPersonal) !=
              (tenant == MicrosoftCalendarConfig.consumerTenant)) {
        throw const FormatException();
      }
      final email =
          (claims['preferred_username'] ?? claims['email']) as String?;
      final name = (claims['name'] as String?)?.trim();
      return CalendarAccount(
        provider: type,
        providerAccountId: subject,
        tenantId: tenant,
        displayName: name?.isNotEmpty == true
            ? name!
            : email?.isNotEmpty == true
            ? email!
            : 'Microsoft account',
        email: email,
      );
    } catch (_) {
      throw _failure(CalendarFailureKind.response);
    }
  }

  @override
  Future<CalendarConnection?> connect(
    CalendarProviderType type, {
    CalendarAccount? expectedAccount,
  }) async {
    _configured();
    try {
      final response = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          config.clientId,
          MicrosoftCalendarConfig.redirectUri,
          serviceConfiguration: _endpoints(_authority(type, expectedAccount)),
          scopes: scopes,
          promptValues: ['select_account'],
          loginHint: expectedAccount?.email,
        ),
      );
      final account = _account(response.idToken, type);
      if (expectedAccount != null && account.id != expectedAccount.id) {
        throw _failure(CalendarFailureKind.accountMismatch);
      }
      return CalendarConnection(
        account: account,
        credentials: _credentials(response),
      );
    } on FlutterAppAuthUserCancelledException {
      return null;
    } on FlutterAppAuthPlatformException catch (error) {
      throw _oauthFailure(error);
    }
  }

  @override
  Future<CalendarCredentials> credentialsFor(
    CalendarAccount account,
    CalendarCredentialStore store, {
    bool forceRefresh = false,
  }) async {
    _configured();
    _authority(account.provider, account);
    final current = await store.read(account.id);
    if (current == null) throw _failure(CalendarFailureKind.authorization);
    if (!forceRefresh &&
        current.expiresAt?.isAfter(
              _now().toUtc().add(const Duration(minutes: 1)),
            ) ==
            true) {
      return current;
    }
    final pending = _refreshes[account.id];
    if (pending != null) return pending;
    final refresh = _refresh(account, store, current);
    _refreshes[account.id] = refresh;
    try {
      return await refresh;
    } finally {
      _refreshes.remove(account.id);
    }
  }

  Future<CalendarCredentials> _refresh(
    CalendarAccount account,
    CalendarCredentialStore store,
    CalendarCredentials current,
  ) async {
    if (current.refreshToken?.isNotEmpty != true) {
      throw _failure(CalendarFailureKind.authorization);
    }
    try {
      final response = await _appAuth.token(
        TokenRequest(
          config.clientId,
          MicrosoftCalendarConfig.redirectUri,
          serviceConfiguration: _endpoints(
            _authority(account.provider, account),
          ),
          scopes: scopes,
          refreshToken: current.refreshToken,
        ),
      );
      if (response.idToken != null &&
          _account(response.idToken, account.provider).id != account.id) {
        throw _failure(CalendarFailureKind.accountMismatch);
      }
      final renewed = _credentials(
        response,
        previousRefreshToken: current.refreshToken,
      );
      await store.write(
        account.id,
        renewed,
      ); // Save rotated refresh tokens first.
      return renewed;
    } on FlutterAppAuthPlatformException catch (error) {
      throw _oauthFailure(error);
    }
  }
}

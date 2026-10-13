import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

import '../models/calendar_account.dart';
import 'calendar_credentials.dart';
import 'calendar_failure.dart';
import 'calendar_provider.dart';

class GoogleCalendarConfig {
  final String serverClientId;
  const GoogleCalendarConfig({required this.serverClientId});
  const GoogleCalendarConfig.fromEnvironment()
    : serverClientId = const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  bool get isConfigured =>
      RegExp(r'^[A-Za-z0-9_-]+\.apps\.googleusercontent\.com$')
          .hasMatch(serverClientId);
}

abstract interface class GoogleCalendarAuth {
  Future<CalendarConnection?> connect({CalendarAccount? expectedAccount});
  Future<CalendarCredentials> authorize(CalendarAccount account);
  Future<void> invalidate(String accessToken);
}

// google_sign_in supplies the registered Android implementation. Its public
// platform interface lets us authorize a *saved* account by ID AND email rather
// than the SDK's last signed-in user. This is Android-only: other platforms may
// support only a single user. Never request a server auth code or ship a secret.
class NativeGoogleCalendarAuth implements GoogleCalendarAuth {
  static const scopes = [
    'https://www.googleapis.com/auth/calendar.calendarlist.readonly',
    'https://www.googleapis.com/auth/calendar.events.readonly',
  ];
  final GoogleCalendarConfig config;
  final GoogleSignInPlatform _platform;
  Future<void>? _initialization;

  NativeGoogleCalendarAuth({
    required this.config,
    GoogleSignInPlatform? platform,
  }) : _platform = platform ?? GoogleSignInPlatform.instance;

  Future<void> _initialize() async {
    if (!config.isConfigured) {
      throw const CalendarFailure(CalendarFailureKind.configuration);
    }
    try {
      await (_initialization ??= _platform.init(
        InitParameters(serverClientId: config.serverClientId),
      ));
    } catch (_) {
      _initialization = null;
      throw const CalendarFailure(CalendarFailureKind.configuration);
    }
  }

  CalendarFailure _failure(GoogleSignInException exception) =>
      CalendarFailure(switch (exception.code) {
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError =>
          CalendarFailureKind.configuration,
        GoogleSignInExceptionCode.userMismatch =>
          CalendarFailureKind.authorization,
        _ => CalendarFailureKind.unavailable,
      });

  Future<CalendarCredentials> _token(
    CalendarAccount account, {
    required bool prompt,
  }) async {
    if (account.provider != CalendarProviderType.google ||
        account.email == null ||
        account.email!.isEmpty) {
      throw const CalendarFailure(CalendarFailureKind.authorization);
    }
    final token = await _platform.clientAuthorizationTokensForScopes(
      ClientAuthorizationTokensForScopesParameters(
        request: AuthorizationRequestDetails(
          scopes: scopes,
          userId: account.providerAccountId,
          email: account.email,
          promptIfUnauthorized: prompt,
        ),
      ),
    );
    if (token == null || token.accessToken.isEmpty) {
      throw const CalendarFailure(CalendarFailureKind.authorization);
    }
    // Google Play Services manages renewal. The SDK returns neither an expiry
    // nor a client refresh token, so do not invent an expiry or request offline
    // server credentials. Only the access token goes into our secure store.
    return CalendarCredentials(accessToken: token.accessToken);
  }

  @override
  Future<CalendarConnection?> connect({
    CalendarAccount? expectedAccount,
  }) async {
    await _initialize();
    try {
      // Clear account selection without revoking any connected account's grant.
      // disconnect() revokes grants and must not be used for multi-account UI.
      await _platform.signOut(const SignOutParams());
      final result = await _platform.authenticate(
        const AuthenticateParameters(scopeHint: scopes),
      );
      final user = result.user;
      final account = CalendarAccount(
        provider: CalendarProviderType.google,
        providerAccountId: user.id,
        displayName: user.displayName?.trim().isNotEmpty == true
            ? user.displayName!
            : user.email,
        email: user.email,
      );
      if (expectedAccount != null && expectedAccount.id != account.id) {
        throw const CalendarFailure(CalendarFailureKind.authorization);
      }
      return CalendarConnection(
        account: account,
        credentials: await _token(account, prompt: true),
      );
    } on GoogleSignInException catch (exception) {
      if (exception.code == GoogleSignInExceptionCode.canceled) return null;
      throw _failure(exception);
    }
  }

  @override
  Future<CalendarCredentials> authorize(CalendarAccount account) async {
    await _initialize();
    try {
      // Silent refresh must never open an account chooser or consent screen.
      return await _token(account, prompt: false);
    } on GoogleSignInException catch (exception) {
      throw _failure(exception);
    }
  }

  @override
  Future<void> invalidate(String accessToken) async {
    await _initialize();
    try {
      await _platform.clearAuthorizationToken(
        ClearAuthorizationTokenParams(accessToken: accessToken),
      );
    } on GoogleSignInException catch (exception) {
      throw _failure(exception);
    }
  }
}

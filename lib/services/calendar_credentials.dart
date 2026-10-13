import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Never include this object in DaylockState, logs, or account metadata.
class CalendarCredentials {
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;

  CalendarCredentials({
    required this.accessToken,
    this.refreshToken,
    DateTime? expiresAt,
  }) : expiresAt = expiresAt?.toUtc() {
    if (accessToken.isEmpty) {
      throw const FormatException('Missing access token');
    }
  }

  Map<String, dynamic> toSecureJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresAt': expiresAt?.toIso8601String(),
  };

  factory CalendarCredentials.fromSecureJson(Map<String, dynamic> json) =>
      CalendarCredentials(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String?,
        expiresAt: json['expiresAt'] == null
            ? null
            : DateTime.parse(json['expiresAt'] as String),
      );
}

abstract interface class CalendarCredentialStore {
  Future<CalendarCredentials?> read(String accountId);
  Future<void> write(String accountId, CalendarCredentials credentials);
  Future<void> delete(String accountId);
  Future<void> clearDaylockCredentials();
}

class SecureCalendarCredentialStore implements CalendarCredentialStore {
  static const keyPrefix = 'daylock.calendar.credentials.';
  final FlutterSecureStorage _storage;

  SecureCalendarCredentialStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(
              storageNamespace: 'daylock_calendar_credentials',
              resetOnError: false,
            ),
          );

  @override
  Future<CalendarCredentials?> read(String accountId) async {
    final value = await _storage.read(key: '$keyPrefix$accountId');
    return value == null
        ? null
        : CalendarCredentials.fromSecureJson(
            jsonDecode(value) as Map<String, dynamic>,
          );
  }

  @override
  Future<void> write(String accountId, CalendarCredentials credentials) =>
      _storage.write(
        key: '$keyPrefix$accountId',
        value: jsonEncode(credentials.toSecureJson()),
      );

  @override
  Future<void> delete(String accountId) =>
      _storage.delete(key: '$keyPrefix$accountId');

  @override
  Future<void> clearDaylockCredentials() async {
    for (final key in (await _storage.readAll()).keys.toList().where(
      (key) => key.startsWith(keyPrefix),
    )) {
      await _storage.delete(key: key);
    }
  }
}

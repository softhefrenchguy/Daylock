import 'dart:convert';

import 'event.dart';

enum CalendarProviderType {
  google,
  microsoftPersonal,
  microsoftWorkSchool;

  String get label => switch (this) {
    google => 'Google Calendar',
    microsoftPersonal => 'Microsoft Personal',
    microsoftWorkSchool => 'Microsoft Work/School',
  };

  EventSource get eventSource => EventSource.values.byName(name);
}

// Public account metadata only. OAuth tokens belong in CredentialStore.
class CalendarAccount {
  final String id;
  final CalendarProviderType provider;
  final String providerAccountId;
  final String? tenantId;
  final String displayName;
  final String? email;

  CalendarAccount({
    required this.provider,
    required this.providerAccountId,
    required this.displayName,
    this.tenantId,
    this.email,
  }) : id = base64Url.encode(
         utf8.encode(jsonEncode([provider.name, providerAccountId, tenantId])),
       ) {
    if (providerAccountId.trim().isEmpty || displayName.trim().isEmpty) {
      throw const FormatException('Invalid calendar account');
    }
  }

  Map<String, dynamic> toJson() => {
    'provider': provider.name,
    'providerAccountId': providerAccountId,
    'tenantId': tenantId,
    'displayName': displayName,
    'email': email,
  };

  factory CalendarAccount.fromJson(Map<String, dynamic> json) =>
      CalendarAccount(
        provider: CalendarProviderType.values.byName(
          json['provider'] as String,
        ),
        providerAccountId: json['providerAccountId'] as String,
        tenantId: json['tenantId'] as String?,
        displayName: json['displayName'] as String,
        email: json['email'] as String?,
      );
}

class ConnectedCalendar {
  final String accountId;
  final String id;
  final String name;
  final bool isVisible;
  final DateTime? lastSyncedAt;
  final String? timeZone;

  ConnectedCalendar({
    required this.accountId,
    required this.id,
    required this.name,
    this.isVisible = true,
    this.timeZone,
    DateTime? lastSyncedAt,
  }) : lastSyncedAt = lastSyncedAt?.toUtc() {
    if (accountId.isEmpty || id.isEmpty || name.trim().isEmpty) {
      throw const FormatException('Invalid connected calendar');
    }
  }

  String get key => jsonEncode([accountId, id]);

  ConnectedCalendar copyWith({bool? isVisible, DateTime? lastSyncedAt}) =>
      ConnectedCalendar(
        accountId: accountId,
        id: id,
        name: name,
        isVisible: isVisible ?? this.isVisible,
        timeZone: timeZone,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      );

  Map<String, dynamic> toJson() => {
    'accountId': accountId,
    'id': id,
    'name': name,
    'isVisible': isVisible,
    'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    if (timeZone != null) 'timeZone': timeZone,
  };

  factory ConnectedCalendar.fromJson(Map<String, dynamic> json) =>
      ConnectedCalendar(
        accountId: json['accountId'] as String,
        id: json['id'] as String,
        name: json['name'] as String,
        isVisible: json['isVisible'] as bool,
        timeZone: json['timeZone'] as String?,
        lastSyncedAt: json['lastSyncedAt'] == null
            ? null
            : DateTime.parse(json['lastSyncedAt'] as String),
      );
}

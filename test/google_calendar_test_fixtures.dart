import 'dart:convert';

import 'package:daylock/models/calendar_account.dart';
import 'package:daylock/services/calendar_credentials.dart';
import 'package:daylock/services/calendar_failure.dart';
import 'package:daylock/services/calendar_provider.dart';
import 'package:daylock/services/google_calendar_auth.dart';
import 'package:http/http.dart' as http;

import 'calendar_test_fixtures.dart';

class TestGoogleAuth implements GoogleCalendarAuth {
  CalendarAccount? selected = testAccount(CalendarProviderType.google);
  CalendarAccount? expected;
  final authorized = <String>[];
  final invalidated = <String>[];
  CalendarFailure? failure;
  @override
  Future<CalendarConnection?> connect({
    CalendarAccount? expectedAccount,
  }) async {
    expected = expectedAccount;
    return selected == null
        ? null
        : CalendarConnection(
            account: selected!,
            credentials: CalendarCredentials(
              accessToken: 'connected-${selected!.providerAccountId}',
            ),
          );
  }

  @override
  Future<CalendarCredentials> authorize(CalendarAccount account) async {
    authorized.add(account.id);
    if (failure != null) throw failure!;
    return CalendarCredentials(
      accessToken: 'renewed-${account.providerAccountId}-${authorized.length}',
    );
  }

  @override
  Future<void> invalidate(String accessToken) async =>
      invalidated.add(accessToken);
}

http.Response googlePage(
  String kind, {
  List<Object?>? items,
  String? next,
  String? zone,
}) => http.Response(
  jsonEncode({
    'kind': kind,
    'items': ?items,
    'nextPageToken': ?next,
    'timeZone': ?zone,
  }),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, Object?> googleTimed({
  String id = 'instance',
  String? title = 'Google meeting',
  String start = '2026-10-09T10:00:00Z',
  String end = '2026-10-09T11:00:00Z',
  String? zone,
}) => {
  'id': id,
  'summary': ?title,
  'start': {'dateTime': start, 'timeZone': ?zone},
  'end': {'dateTime': end, 'timeZone': ?zone},
};

Map<String, Object?> googleCalendar({String id = 'primary'}) => {
  'id': id,
  'summary': '$id calendar',
  'timeZone': 'Europe/London',
  'accessRole': 'owner',
};

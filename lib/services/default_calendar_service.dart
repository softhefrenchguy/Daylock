import 'package:flutter/foundation.dart';

import 'calendar_service.dart';
import 'google_calendar_auth.dart';
import 'google_calendar_provider.dart';
import '../models/calendar_account.dart';
import 'microsoft_calendar_auth.dart';
import 'microsoft_calendar_provider.dart';

CalendarService defaultCalendarService({DateTime Function()? now}) {
  const config = GoogleCalendarConfig.fromEnvironment();
  const microsoftConfig = MicrosoftCalendarConfig.fromEnvironment();
  final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  final microsoftAuth = NativeMicrosoftCalendarAuth(
    config: microsoftConfig,
    now: now,
  );
  return CalendarService(
    now: now,
    providers: [
      if (isAndroid && config.isConfigured)
        GoogleCalendarProvider(auth: NativeGoogleCalendarAuth(config: config)),
      if (isAndroid && microsoftConfig.isConfigured)
        for (final type in [
          CalendarProviderType.microsoftPersonal,
          CalendarProviderType.microsoftWorkSchool,
        ])
          MicrosoftCalendarProvider(type: type, auth: microsoftAuth),
    ],
  );
}

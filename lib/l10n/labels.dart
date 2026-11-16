import 'package:intl/intl.dart';

import '../design/appearance_preferences.dart';
import '../design/daylock_palette.dart';
import '../models/calendar_account.dart';
import '../services/calendar_failure.dart';
import '../models/event.dart';
import '../models/routine.dart';
import '../models/task.dart';
import 'app_localizations.dart';
import 'l10n.dart' show englishStrings, ensureDateFormatting;

/// Translated names for values the models keep as stable English labels.
extension DaylockLabels on AppLocalizations {
  String appearanceMode(AppearanceMode mode) => switch (mode) {
    AppearanceMode.dark => appearanceDark,
    AppearanceMode.light => appearanceLight,
    AppearanceMode.system => appearanceSystem,
  };

  String colourTheme(ColourTheme colour) => switch (colour) {
    ColourTheme.violet => colourViolet,
    ColourTheme.ocean => colourOcean,
    ColourTheme.forest => colourForest,
    ColourTheme.ember => colourEmber,
    ColourTheme.rose => colourRose,
    ColourTheme.mono => colourMono,
  };

  String illustration(String id) => switch (id) {
    'celebration' => illustrationCelebration,
    'driving' => illustrationDriving,
    'award' => illustrationAward,
    'cooking' => illustrationCooking,
    'travel' => illustrationTravel,
    'fitness' => illustrationFitness,
    'learning' => illustrationLearning,
    'health' => illustrationHealth,
    'work' => illustrationWork,
    'home' => illustrationHome,
    'people' => illustrationPeople,
    'creative' => illustrationCreativity,
    _ => illustrationSunrise,
  };

  String taskOutcome(TaskOutcome outcome) => switch (outcome) {
    TaskOutcome.incomplete => outcomeIncomplete,
    TaskOutcome.completed => outcomeCompleted,
    TaskOutcome.excused => outcomeExcused,
  };

  String calendarProvider(CalendarProviderType type) =>
      eventSource(type.eventSource);

  String eventSource(EventSource source) => switch (source) {
    EventSource.local => sourceLocal,
    EventSource.google => sourceGoogle,
    EventSource.microsoftPersonal => sourceMicrosoftPersonal,
    EventSource.microsoftWorkSchool => sourceMicrosoftWorkSchool,
  };

  String freedomState(String state) => switch (state) {
    'earned' => freedomStateEarned,
    'notEarned' => freedomStateNotEarned,
    'disabled' => freedomStateControlOff,
    _ => freedomStateUnknown,
  };

  /// Monday = 1 … Sunday = 7, abbreviated in this language.
  String weekdayShort(int weekday) {
    ensureDateFormatting();
    return DateFormat.E(localeName).format(DateTime(2024, 1, weekday));
  }

  /// Monday = 1 … Sunday = 7, in full.
  String weekdayLong(int weekday) {
    ensureDateFormatting();
    return DateFormat.EEEE(localeName).format(DateTime(2024, 1, weekday));
  }

  /// "Every 2 days", "Weekdays", "Mon, Wed, Fri"…
  String repeatLabel(RoutineSchedule schedule) {
    if (schedule.isDaily) return repeatDaily;
    if (schedule.kind == RepeatKind.interval) {
      return repeatEveryDays(schedule.everyDays);
    }
    final days = schedule.weekdays;
    if (days.length == 5 && days.containsAll(RoutineSchedule.weekdaysOnly)) {
      return repeatWeekdays;
    }
    if (days.length == 2 && days.containsAll({6, 7})) return repeatWeekends;
    final sorted = days.toList()..sort();
    return sorted.map(weekdayShort).join(listSeparator);
  }

  /// An event's time on [selectedDate], e.g. "09:00–10:00" or "All day".
  String eventTime(Event event, DateTime selectedDate) {
    final start = event.startsAtUtc?.toLocal();
    final end = event.endsAtUtc?.toLocal();
    if (start != null && end != null) {
      final day = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
      final next = DateTime(day.year, day.month, day.day + 1);
      if (!start.isAfter(day) && !end.isBefore(next)) {
        return eventContinuesAllDay;
      }
      final from = start.isBefore(day)
          ? eventEarlier
          : EventTime(start.hour, start.minute).toString();
      final until = !end.isBefore(next)
          ? eventNextDay
          : EventTime(end.hour, end.minute).toString();
      return '$from–$until';
    }
    if (event.startTime != null && event.endTime != null) {
      return '${event.startTime}–${event.endTime}';
    }
    if (event.startTime != null) return '${event.startTime}';
    if (event.endTime != null) return eventUntil('${event.endTime}');
    return eventAllDay;
  }

  /// Recorded stopwatch time: "0 min", "<1 min", "45 min", "2 hr 5 min".
  String focusDuration(int milliseconds) {
    if (milliseconds == 0) return durationMinutes(0);
    if (milliseconds < 60000) return durationUnderMinute;
    final minutes = milliseconds ~/ 60000;
    if (minutes < 60) return durationMinutes(minutes);
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? durationHours(hours) : durationHoursMinutes(hours, rest);
  }
}

extension DaylockAreaLabels on AppLocalizations {
  /// Name of an Area icon id ("life", "health"…).
  String areaIcon(String id) => switch (id) {
    'health' => areaIconHealth,
    'work' => areaIconWork,
    'learning' => areaIconLearning,
    'home' => areaIconHome,
    'people' => areaIconPeople,
    'creative' => areaIconCreative,
    'fitness' => areaIconFitness,
    _ => areaIconLife,
  };

  /// Name of an Area colour ("Lavender", "Blue"…).
  String areaColour(String name) => switch (name) {
    'Blue' => areaColourBlue,
    'Teal' => areaColourTeal,
    'Green' => areaColourGreen,
    'Amber' => areaColourAmber,
    'Rose' => areaColourRose,
    _ => areaColourLavender,
  };
}

extension DaylockServiceLabels on AppLocalizations {
  /// Status text produced by services in English, shown in this language.
  /// Unknown text is shown as it is.
  String known(String english) {
    final en = englishStrings;
    final pairs = <String, String>{
      en.notifExplainAndroid: notifExplainAndroid,
      en.notifExplainError: notifExplainError,
      en.notifExplainDefault: notifExplainDefault,
      en.notifExplainWebSupported: notifExplainWebSupported,
      en.notifExplainWebUnsupported: notifExplainWebUnsupported,
      en.detectionReadFailed: detectionReadFailed,
      en.selectionLoadFailed: selectionLoadFailed,
      en.selectionSaveFailed: selectionSaveFailed,
    };
    return pairs[english] ?? english;
  }

  String calendarFailure(CalendarFailure failure) {
    final ms = failure.isMicrosoft;
    return switch (failure.kind) {
      CalendarFailureKind.authorization =>
        ms ? calFailAuthMicrosoft : calFailAuthGoogle,
      CalendarFailureKind.configuration =>
        ms ? calFailConfigMicrosoft : calFailConfigGoogle,
      CalendarFailureKind.unavailable =>
        ms ? calFailUnavailableMicrosoft : calFailUnavailableGoogle,
      CalendarFailureKind.response =>
        ms ? calFailResponseMicrosoft : calFailResponseGoogle,
      CalendarFailureKind.adminConsent => calFailAdminConsent,
      CalendarFailureKind.accountMismatch => calFailAccountMismatch,
    };
  }
}

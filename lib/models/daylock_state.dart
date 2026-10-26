import 'daily_plan.dart';
import 'event.dart';
import 'task.dart';
import 'calendar_cache.dart';
import 'plan_history.dart';
import 'freedom_settings.dart';
import 'routine.dart';
import 'notification_preferences.dart';
import 'area.dart';
import 'highlight.dart';

// A snapshot for storage. MainApp still owns the live plans.
class DaylockState {
  final DailyPlan todayPlan;
  final DailyPlan tomorrowPlan;
  final List<Event> events;
  final CalendarCache calendarCache;
  final PlanHistory history;
  final FreedomSettings freedomSettings;
  final RoutineBook routines;
  final NotificationPreferences notificationPreferences;
  final AreaBook areas;
  final HighlightBook highlights;

  DaylockState({
    required this.todayPlan,
    required this.tomorrowPlan,
    this.events = const [],
    this.calendarCache = CalendarCache.empty,
    this.history = PlanHistory.empty,
    this.freedomSettings = const FreedomSettings(),
    this.routines = RoutineBook.empty,
    this.notificationPreferences = const NotificationPreferences(),
    AreaBook? areas,
    this.highlights = HighlightBook.empty,
  }) : areas = areas ?? AreaBook.initial(createdAt: todayPlan.date);

  DaylockState rollOver(DateTime now) {
    final currentDate = DateTime(now.year, now.month, now.day);
    // Ignore time-of-day and avoid discarding plans if the clock moves backwards.
    if (!currentDate.isAfter(todayPlan.date)) return this;

    final nextDate = DateTime(
      todayPlan.date.year,
      todayPlan.date.month,
      todayPlan.date.day + 1,
    );
    final canPromote =
        currentDate == nextDate && tomorrowPlan.date == currentDate;

    var archived = history.archive(todayPlan);
    if (tomorrowPlan.isCommitted &&
        tomorrowPlan.date.isAfter(todayPlan.date) &&
        tomorrowPlan.date.isBefore(currentDate)) {
      archived = archived.archive(tomorrowPlan, settleFocus: false);
    }

    return DaylockState(
      events: events,
      calendarCache: calendarCache,
      history: archived,
      freedomSettings: freedomSettings,
      routines: routines,
      notificationPreferences: notificationPreferences,
      areas: areas,
      highlights: highlights,
      todayPlan: canPromote
          ? tomorrowPlan
          : DailyPlan(date: currentDate, tasks: []),
      tomorrowPlan: DailyPlan(
        date: DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day + 1,
        ),
        tasks: [],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    if (events.any((event) => event.isExternal)) {
      throw const FormatException(
        'External events belong in the calendar cache',
      );
    }
    return {
      'version': 2,
      'todayPlan': todayPlan.toJson(),
      'tomorrowPlan': tomorrowPlan.toJson(),
      'events': events.map((event) => event.toJson()).toList(),
      'calendarCache': calendarCache.toJson(),
      'history': history.toJson(),
      'freedomSettings': freedomSettings.toJson(),
      'routines': routines.toJson(),
      'notificationPreferences': notificationPreferences.toJson(),
      'areas': areas.toJson(),
      'highlights': highlights.toJson(),
    };
  }

  factory DaylockState.fromJson(
    Map<String, dynamic> json, {
    DateTime? migrationTime,
  }) {
    if (json['version'] != 2) {
      throw const FormatException('Unsupported saved state version');
    }
    return DaylockState(
      highlights: json.containsKey('highlights')
          ? HighlightBook.fromJson(json['highlights'] as List)
          : HighlightBook.empty,
      areas: json.containsKey('areas')
          ? AreaBook.fromJson(json['areas'] as List)
          : AreaBook.initial(createdAt: migrationTime),
      notificationPreferences: json.containsKey('notificationPreferences')
          ? NotificationPreferences.fromJson(
              json['notificationPreferences'] as Map<String, dynamic>,
            )
          : const NotificationPreferences(),
      freedomSettings: json.containsKey('freedomSettings')
          ? FreedomSettings.fromJson(
              json['freedomSettings'] as Map<String, dynamic>,
            )
          : const FreedomSettings(),
      routines: json.containsKey('routines')
          ? RoutineBook.fromJson(json['routines'] as List)
          : RoutineBook.empty,
      history: json.containsKey('history')
          ? PlanHistory.fromJson(json['history'] as List)
          : PlanHistory.empty,
      calendarCache: json.containsKey('calendarCache')
          ? CalendarCache.fromJson(
              json['calendarCache'] as Map<String, dynamic>,
            )
          : CalendarCache.empty,
      // Version 2 saves written before Calendar had no events field.
      // Only a missing field migrates to empty; malformed data still fails safely.
      events: _localEvents(json),
      todayPlan: DailyPlan.fromJson(json['todayPlan'] as Map<String, dynamic>),
      tomorrowPlan: DailyPlan.fromJson(
        json['tomorrowPlan'] as Map<String, dynamic>,
      ),
    );
  }

  static List<Event> _localEvents(Map<String, dynamic> json) {
    if (!json.containsKey('events')) return [];
    final events = (json['events'] as List)
        .map((event) => Event.fromJson(event as Map<String, dynamic>))
        .toList();
    if (events.any((event) => event.isExternal)) {
      throw const FormatException('External event in local events');
    }
    return events;
  }

  factory DaylockState.fromLegacyJson(
    Map<String, dynamic> json, {
    required DateTime today,
  }) => DaylockState(
    areas: AreaBook.initial(createdAt: today),
    // The old format had no dates. Assign them once, during migration.
    todayPlan: DailyPlan(
      date: today,
      tasks: (json['tasks'] as List)
          .map((task) => Task.fromJson(task as Map<String, dynamic>))
          .toList(),
      isCommitted: true,
    ),
    tomorrowPlan: DailyPlan(
      date: DateTime(today.year, today.month, today.day + 1),
      tasks: (json['tomorrowTasks'] as List)
          .map((task) => Task.fromJson(task as Map<String, dynamic>))
          .toList(),
      isCommitted: json['isTomorrowCommitted'] as bool,
    ),
  );
}

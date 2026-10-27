import '../models/area.dart';
import '../models/daily_plan.dart';
import '../models/plan_history.dart';
import '../models/task.dart';

DateTime journeyDay(DateTime date) => DateTime(date.year, date.month, date.day);
int _dayNumber(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

class JourneyRecord {
  final DateTime date;
  final int taskIndex;
  final String areaId;
  final HistoricalTask task;
  const JourneyRecord({
    required this.date,
    required this.taskIndex,
    required this.areaId,
    required this.task,
  });
}

class JourneySummary {
  final List<JourneyRecord> records;
  JourneySummary(Iterable<JourneyRecord> records)
    : records = List.unmodifiable(records);
  int get completedCount =>
      records.where((r) => r.task.outcome == TaskOutcome.completed).length;
  int get focusMilliseconds =>
      records.fold(0, (sum, r) => sum + r.task.accumulatedFocusMilliseconds);
}

class JourneyBucket {
  final DateTime from, through;
  final JourneySummary summary;
  JourneyBucket(this.from, this.through, Iterable<JourneyRecord> records)
    : summary = JourneySummary(records);
}

/// A derived read model, never persisted and never writes to historical records.
class JourneyData {
  final DateTime today;
  final List<JourneyRecord> records;
  JourneyData({
    required AreaBook areas,
    required PlanHistory history,
    required DailyPlan todayPlan,
    required DateTime now,
  }) : today = journeyDay(now),
       records = List.unmodifiable(
         _records(areas, history, todayPlan, journeyDay(now), now),
       );

  static Iterable<JourneyRecord> _records(
    AreaBook areas,
    PlanHistory history,
    DailyPlan live,
    DateTime today,
    DateTime now,
  ) sync* {
    final days = {
      for (final plan in history.plans)
        if (!plan.date.isAfter(today)) plan.date: plan,
    };
    // Preserve an immutable historical snapshot after a backwards clock change.
    // The live plan is included only when this date has no historical snapshot.
    if (live.date == today && !days.containsKey(today)) {
      days[today] = HistoricalDailyPlan.capture(
        live,
        settleFocus: false,
        recordedAt: now,
      );
    }
    final dates = days.keys.toList()..sort((a, b) => b.compareTo(a));
    for (final date in dates) {
      final tasks = days[date]!.tasks;
      for (var i = 0; i < tasks.length; i++) {
        yield JourneyRecord(
          date: date,
          taskIndex: i,
          areaId: areas.resolve(tasks[i].areaId).id,
          task: tasks[i],
        );
      }
    }
  }

  DateTime get last30Start => DateTime(today.year, today.month, today.day - 29);
  JourneySummary forArea(String id, {bool last30Days = false}) =>
      JourneySummary(
        records.where(
          (r) =>
              r.areaId == id && (!last30Days || !r.date.isBefore(last30Start)),
        ),
      );

  /// At most eight chronological buckets; calendar-day arithmetic avoids DST drift.
  List<JourneyBucket> activity(String id, {required bool last30Days}) {
    final selected = forArea(id, last30Days: last30Days).records;
    final start = last30Days || selected.isEmpty
        ? last30Start
        : selected.last.date;
    final days = _dayNumber(today) - _dayNumber(start) + 1;
    final width = (days / 8).ceil().clamp(1, days);
    return [
      for (var offset = 0; offset < days; offset += width)
        _bucket(start, offset, width, days, selected),
    ];
  }

  JourneyBucket _bucket(
    DateTime start,
    int offset,
    int width,
    int days,
    List<JourneyRecord> selected,
  ) {
    final from = DateTime(start.year, start.month, start.day + offset);
    final through = DateTime(
      start.year,
      start.month,
      start.day + (offset + width - 1).clamp(0, days - 1),
    );
    return JourneyBucket(
      from,
      through,
      selected.where((r) => !r.date.isBefore(from) && !r.date.isAfter(through)),
    );
  }
}

String journeyFocusLabel(int milliseconds) {
  if (milliseconds == 0) return '0 min';
  if (milliseconds < 60000) return '<1 min';
  final minutes = milliseconds ~/ 60000;
  return minutes < 60
      ? '$minutes min'
      : '${minutes ~/ 60} hr${minutes % 60 == 0 ? '' : ' ${minutes % 60} min'}';
}

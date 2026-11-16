import '../models/area.dart';
import '../models/break_entry.dart';
import '../models/task.dart';
import 'journey_service.dart';

/// The last seven days, ending today: how the week went.
class WeeklyReview {
  final DateTime from, through;

  /// Days with commitments, and how many were fully kept.
  final int daysPlanned, daysKept;

  /// Commitments kept, out of those that counted (excused ones don't).
  final int kept, eligible;
  final int focusMilliseconds;

  /// The Area with the most kept commitments this week, if any.
  final Area? topArea;
  final int topAreaKept;

  /// Active Areas with nothing kept this week.
  final List<Area> quietAreas;
  final int breaks;
  final int streak;

  const WeeklyReview({
    required this.from,
    required this.through,
    required this.daysPlanned,
    required this.daysKept,
    required this.kept,
    required this.eligible,
    required this.focusMilliseconds,
    required this.topArea,
    required this.topAreaKept,
    required this.quietAreas,
    required this.breaks,
    required this.streak,
  });

  bool get isEmpty => daysPlanned == 0;
  double get keptShare => eligible == 0 ? 0 : kept / eligible;

  factory WeeklyReview.of(
    JourneyData data,
    AreaBook areas, {
    Iterable<BreakEntry> breaks = const [],
  }) {
    final through = data.today;
    final from = DateTime(through.year, through.month, through.day - 6);
    bool inWeek(DateTime date) {
      final day = journeyDay(date);
      return !day.isBefore(from) && !day.isAfter(through);
    }

    final records = data.records.where((r) => inWeek(r.date)).toList();
    final days = {for (final r in records) journeyDay(r.date)};
    final keptByArea = <String, int>{};
    var kept = 0, eligible = 0, focus = 0;
    for (final r in records) {
      focus += r.task.accumulatedFocusMilliseconds;
      if (r.task.outcome == TaskOutcome.excused) continue;
      eligible++;
      if (r.task.outcome == TaskOutcome.completed) {
        kept++;
        keptByArea[r.areaId] = (keptByArea[r.areaId] ?? 0) + 1;
      }
    }
    String? topId;
    for (final entry in keptByArea.entries) {
      if (topId == null || entry.value > keptByArea[topId]!) topId = entry.key;
    }
    return WeeklyReview(
      from: from,
      through: through,
      daysPlanned: days.length,
      daysKept: days
          .where((d) => data.statusOn(d) == JourneyDayStatus.kept)
          .length,
      kept: kept,
      eligible: eligible,
      focusMilliseconds: focus,
      topArea: topId == null ? null : areas.resolve(topId),
      topAreaKept: topId == null ? 0 : keptByArea[topId]!,
      quietAreas: [
        for (final area in areas.active)
          if (!keptByArea.containsKey(area.id)) area,
      ],
      breaks: breaks.where((b) => inWeek(b.at)).length,
      streak: data.currentStreak,
    );
  }
}

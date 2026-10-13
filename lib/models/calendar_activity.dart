import 'daily_plan.dart';
import 'plan_history.dart';
import 'commitment_progress.dart';

enum HeatmapIntensity { neutral, zero, low, medium, high, complete }

// Five completion bands plus neutral. Events deliberately have no input here.
HeatmapIntensity commitmentIntensity(int completed, int total) {
  if (total < 0 || completed < 0 || completed > total) {
    throw ArgumentError('Invalid commitment counts');
  }
  if (total == 0) return HeatmapIntensity.neutral;
  if (completed == 0) return HeatmapIntensity.zero;
  final fraction = completed / total;
  if (fraction <= 0.25) return HeatmapIntensity.low;
  if (fraction <= 0.5) return HeatmapIntensity.medium;
  if (fraction < 1) return HeatmapIntensity.high;
  return HeatmapIntensity.complete;
}

DateTime _day(DateTime date) => DateTime(date.year, date.month, date.day);

// A read-only projection, never another owner of live task or history state.
class CalendarDayActivity {
  final DateTime date;
  final bool isToday;
  final bool isFuture;
  final bool isRecorded;
  final List<HistoricalTask> commitments;

  CalendarDayActivity._({
    required this.date,
    required this.isToday,
    required this.isFuture,
    required this.isRecorded,
    required Iterable<HistoricalTask> commitments,
  }) : commitments = List.unmodifiable(commitments);

  factory CalendarDayActivity.forDate({
    required DateTime date,
    required DateTime currentTime,
    required PlanHistory history,
    DailyPlan? todayPlan,
  }) {
    final selected = _day(date);
    final today = _day(currentTime);
    final isToday = selected == today;
    final isFuture = selected.isAfter(today);
    final past = selected.isBefore(today) ? history.forDate(selected) : null;
    final live = isToday && todayPlan?.date == today ? todayPlan : null;
    return CalendarDayActivity._(
      date: selected,
      isToday: isToday,
      isFuture: isFuture,
      isRecorded: past != null || live != null,
      commitments: live != null
          ? live.tasks.map((task) => HistoricalTask.capture(task, currentTime))
          : past?.tasks ?? const [],
    );
  }

  CommitmentProgress get progress =>
      CommitmentProgress.fromOutcomes(commitments.map((task) => task.outcome));
  int get completedCount => progress.completedCount;
  int get eligibleCount => progress.eligibleCount;
  int get excusedCount => progress.excusedCount;
  double? get completionPercentage => progress.percentage;
  int get focusMilliseconds => commitments.fold(
    0,
    (total, task) => total + task.accumulatedFocusMilliseconds,
  );
  HeatmapIntensity get intensity =>
      commitmentIntensity(completedCount, eligibleCount);
}

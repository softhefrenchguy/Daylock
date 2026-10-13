import 'daily_plan.dart';
import 'task.dart';
import 'commitment_progress.dart';

DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

// Immutable execution snapshots: no timer or completion setters are exposed.
class HistoricalTask {
  final String name;
  final TaskType type;
  final TaskOutcome outcome;
  final String? excuseReason;
  bool get isCompleted => outcome == TaskOutcome.completed;
  bool get isExcused => outcome == TaskOutcome.excused;
  final int? minimumFocusMinutes;
  final String? focusTarget;
  final int accumulatedFocusMilliseconds;

  HistoricalTask._(Task task)
    : name = task.name,
      type = task.type,
      outcome = task.outcome,
      excuseReason = task.excuseReason,
      minimumFocusMinutes = task.minimumFocusMinutes,
      focusTarget = task.focusTarget,
      accumulatedFocusMilliseconds = task.accumulatedFocusMilliseconds;

  factory HistoricalTask.capture(
    Task task,
    DateTime dayEndsAt, {
    bool settleFocus = true,
  }) {
    final copy = Task.fromJson(task.toJson());
    if (settleFocus) {
      copy.pauseFocus(dayEndsAt);
    } else {
      // A missed committed draft was never Today. Do not infer timer activity.
      copy.focusStartedAt = null;
    }
    return HistoricalTask._(copy);
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type.name,
    'isCompleted': isCompleted,
    'outcome': outcome.name,
    'excuseReason': excuseReason,
    if (type == TaskType.focus) ...{
      'minimumFocusMinutes': minimumFocusMinutes,
      'focusTarget': focusTarget,
      'accumulatedFocusMilliseconds': accumulatedFocusMilliseconds,
      'focusStartedAt': null,
    },
  };

  factory HistoricalTask.fromJson(Map<String, dynamic> json) {
    final task = Task.fromJson(json);
    if (task.isFocusRunning || task.isCompleted != json['isCompleted']) {
      throw const FormatException(
        'Historical tasks must have settled timers and completion',
      );
    }
    return HistoricalTask._(task);
  }
}

class HistoricalDailyPlan {
  final DateTime date;
  final bool isCommitted;
  final List<HistoricalTask> tasks;

  HistoricalDailyPlan._({
    required this.date,
    required this.isCommitted,
    required Iterable<HistoricalTask> tasks,
  }) : tasks = List.unmodifiable(tasks);

  factory HistoricalDailyPlan.capture(
    DailyPlan plan, {
    bool settleFocus = true,
  }) {
    // Construct the following local midnight, not date + an elapsed 24 hours.
    final end = DateTime(plan.date.year, plan.date.month, plan.date.day + 1);
    return HistoricalDailyPlan._(
      date: plan.date,
      isCommitted: plan.isCommitted,
      tasks: plan.tasks.map(
        (task) => HistoricalTask.capture(task, end, settleFocus: settleFocus),
      ),
    );
  }

  DailyCompletionSummary get summary => DailyCompletionSummary._(this);

  Map<String, dynamic> toJson() => {
    'date':
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    'isCommitted': isCommitted,
    'tasks': tasks.map((task) => task.toJson()).toList(),
  };

  factory HistoricalDailyPlan.fromJson(Map<String, dynamic> json) {
    // Reuse the existing strict calendar-date validation without changing live plans.
    final date = DailyPlan.fromJson({...json, 'tasks': <dynamic>[]}).date;
    return HistoricalDailyPlan._(
      date: date,
      isCommitted: json['isCommitted'] as bool,
      tasks: (json['tasks'] as List).map(
        (task) => HistoricalTask.fromJson(task as Map<String, dynamic>),
      ),
    );
  }
}

class DailyCompletionSummary {
  final DateTime date;
  final bool isCommitted;
  final int commitmentCount;
  final int completedCount;
  final int accumulatedFocusMilliseconds;
  final CommitmentProgress progress;

  DailyCompletionSummary._(HistoricalDailyPlan plan)
    : date = plan.date,
      isCommitted = plan.isCommitted,
      commitmentCount = plan.tasks.length,
      completedCount = plan.tasks.where((task) => task.isCompleted).length,
      progress = CommitmentProgress.fromOutcomes(
        plan.tasks.map((task) => task.outcome),
      ),
      accumulatedFocusMilliseconds = plan.tasks
          .where((task) => task.type == TaskType.focus)
          .fold(0, (total, task) => total + task.accumulatedFocusMilliseconds);

  int get eligibleCount => progress.eligibleCount;
  int get excusedCount => progress.excusedCount;
  bool get isNeutral => progress.isNeutral;
  double? get completionFraction => progress.fraction;
  double? get completionPercentage => progress.percentage;
}

// One permanent, immutable record per date. Missing dates remain unknown.
class PlanHistory {
  final Map<DateTime, HistoricalDailyPlan> _plans;
  static const empty = PlanHistory._empty();
  const PlanHistory._empty() : _plans = const {};

  PlanHistory._(Map<DateTime, HistoricalDailyPlan> plans)
    : _plans = Map.unmodifiable(plans);

  HistoricalDailyPlan? forDate(DateTime date) => _plans[_day(date)];
  DailyCompletionSummary? summaryForDate(DateTime date) =>
      forDate(date)?.summary;

  List<HistoricalDailyPlan> get plans {
    final sorted = _plans.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return List.unmodifiable(sorted);
  }

  List<DailyCompletionSummary> summaries({DateTime? from, DateTime? through}) =>
      List.unmodifiable(
        plans
            .where(
              (plan) =>
                  (from == null || !plan.date.isBefore(_day(from))) &&
                  (through == null || !plan.date.isAfter(_day(through))),
            )
            .map((plan) => plan.summary),
      );

  PlanHistory archive(DailyPlan plan, {bool settleFocus = true}) {
    // Preserve the original snapshot, including after a backwards clock change.
    if (_plans.containsKey(plan.date)) return this;
    return PlanHistory._({
      ..._plans,
      plan.date: HistoricalDailyPlan.capture(plan, settleFocus: settleFocus),
    });
  }

  List<Map<String, dynamic>> toJson() =>
      plans.map((plan) => plan.toJson()).toList();

  factory PlanHistory.fromJson(List<dynamic> json) {
    final plans = <DateTime, HistoricalDailyPlan>{};
    for (final value in json) {
      final plan = HistoricalDailyPlan.fromJson(value as Map<String, dynamic>);
      if (plans.containsKey(plan.date)) {
        throw const FormatException('Duplicate historical plan date');
      }
      plans[plan.date] = plan;
    }
    return PlanHistory._(plans);
  }
}

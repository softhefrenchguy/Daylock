import 'dart:math';

import 'task.dart';
import 'area.dart';

String newRoutineId() {
  final random = Random.secure();
  return List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

String routineDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

DateTime _day(DateTime date) => DateTime(date.year, date.month, date.day);

/// Whole calendar days between two dates, immune to DST-length days.
int calendarDaysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

enum RepeatKind { interval, weekly }

/// When a routine lands in a plan. Fixed to the calendar: removing one
/// occurrence never moves the ones after it.
class RoutineSchedule {
  static const maxInterval = 30;
  static const weekdaysOnly = {1, 2, 3, 4, 5};
  final RepeatKind kind;

  /// Interval only: every [everyDays] days counted from [anchor].
  final int everyDays;
  final DateTime anchor;

  /// Weekly only: [DateTime.weekday] values (1 = Monday).
  final Set<int> weekdays;

  RoutineSchedule._(this.kind, this.everyDays, DateTime anchor, Set<int> days)
    : anchor = _day(anchor),
      weekdays = Set.unmodifiable(days) {
    if (kind == RepeatKind.interval &&
        (everyDays < 1 || everyDays > maxInterval || weekdays.isNotEmpty)) {
      throw const FormatException('Invalid repeat interval');
    }
    if (kind == RepeatKind.weekly &&
        (weekdays.isEmpty || weekdays.any((d) => d < 1 || d > 7))) {
      throw const FormatException('Invalid repeat weekdays');
    }
  }

  factory RoutineSchedule.everyDays(int days, {required DateTime from}) =>
      RoutineSchedule._(RepeatKind.interval, days, from, const {});
  factory RoutineSchedule.daily({DateTime? from}) =>
      RoutineSchedule.everyDays(1, from: from ?? DateTime(2000));
  factory RoutineSchedule.onWeekdays(Iterable<int> days) =>
      RoutineSchedule._(RepeatKind.weekly, 1, DateTime(2000), days.toSet());

  bool get isDaily =>
      (kind == RepeatKind.interval && everyDays == 1) ||
      (kind == RepeatKind.weekly && weekdays.length == 7);

  bool isDue(DateTime date) => switch (kind) {
    RepeatKind.interval => () {
      final days = calendarDaysBetween(anchor, date);
      return days >= 0 && days % everyDays == 0;
    }(),
    RepeatKind.weekly => weekdays.contains(date.weekday),
  };

  /// The first [count] due dates on or after [from].
  List<DateTime> upcoming(DateTime from, {int count = 3}) {
    final result = <DateTime>[];
    var date = _day(from);
    // Every schedule repeats within maxInterval days, so this always ends.
    for (var i = 0; result.length < count && i < 400; i++) {
      if (isDue(date)) result.add(date);
      date = DateTime(date.year, date.month, date.day + 1);
    }
    return result;
  }

  DateTime? nextDue(DateTime from) {
    final next = upcoming(from, count: 1);
    return next.isEmpty ? null : next.single;
  }

  /// Same rule, re-counted from [date] (only intervals have a start).
  RoutineSchedule anchoredAt(DateTime date) => kind == RepeatKind.interval
      ? RoutineSchedule.everyDays(everyDays, from: date)
      : this;

  /// Same rule regardless of where an interval was counted from.
  bool sameRule(RoutineSchedule other) =>
      kind == other.kind &&
      everyDays == other.everyDays &&
      weekdays.length == other.weekdays.length &&
      weekdays.containsAll(other.weekdays);

  static const _short = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String get label {
    if (isDaily) return 'Daily';
    if (kind == RepeatKind.interval) return 'Every $everyDays days';
    if (weekdays.length == 5 && weekdays.containsAll(weekdaysOnly)) {
      return 'Weekdays';
    }
    if (weekdays.length == 2 && weekdays.containsAll({6, 7})) {
      return 'Weekends';
    }
    final sorted = weekdays.toList()..sort();
    return sorted.map((d) => _short[d - 1]).join(', ');
  }

  Map<String, dynamic> toJson() => switch (kind) {
    RepeatKind.interval => {
      'kind': 'interval',
      'everyDays': everyDays,
      'anchor': routineDateKey(anchor),
    },
    RepeatKind.weekly => {
      'kind': 'weekly',
      'weekdays': (weekdays.toList()..sort()),
    },
  };

  factory RoutineSchedule.fromJson(Map<String, dynamic> json) =>
      switch (json['kind']) {
        'interval' => RoutineSchedule.everyDays(
          json['everyDays'] as int,
          from: _parseDate(json['anchor'] as String),
        ),
        'weekly' => RoutineSchedule.onWeekdays(
          (json['weekdays'] as List).cast<int>(),
        ),
        _ => throw const FormatException('Unknown repeat kind'),
      };

  static DateTime _parseDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null || routineDateKey(date) != value) {
      throw const FormatException('Invalid repeat start date');
    }
    return date;
  }
}

/// What happened to a routine on one plan date. `added` put its step in the
/// plan; `removed` means the user took it out again, so it is not re-added.
enum RoutineAction { added, removed }

RoutineAction _readAction(String value) => switch (value) {
  'added' || 'accept' => RoutineAction.added,
  // Legacy suggestions: Skip and Dismiss both kept the step out of the plan.
  'removed' || 'skip' || 'dismiss' => RoutineAction.removed,
  _ => throw const FormatException('Unknown routine decision'),
};

class RoutineStep {
  final String id, name;
  final String? areaId;
  final TaskType type;
  final int? minimumFocusMinutes;
  final String? focusTarget;
  RoutineStep({
    required this.id,
    required String name,
    required this.type,
    this.areaId = Area.defaultId,
    this.minimumFocusMinutes,
    String? focusTarget,
  }) : name = name.trim(),
       focusTarget = focusTarget == null || focusTarget.trim().isEmpty
           ? null
           : focusTarget.trim() {
    if (id.isEmpty ||
        this.name.isEmpty ||
        (type == TaskType.focus &&
            (minimumFocusMinutes == null || minimumFocusMinutes! <= 0)) ||
        (type == TaskType.goal &&
            (minimumFocusMinutes != null || focusTarget != null))) {
      throw const FormatException('Invalid routine step');
    }
  }
  factory RoutineStep.fromTask(Task task, {String? id}) => RoutineStep(
    id: id ?? newRoutineId(),
    name: task.name,
    type: task.type,
    areaId: task.areaId,
    minimumFocusMinutes: task.minimumFocusMinutes,
    focusTarget: task.focusTarget,
  );
  Task toTask({String? routineId}) => Task(
    name: name,
    type: type,
    areaId: areaId ?? Area.defaultId,
    minimumFocusMinutes: minimumFocusMinutes,
    focusTarget: focusTarget,
    routineId: routineId,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'minimumFocusMinutes': minimumFocusMinutes,
    'focusTarget': focusTarget,
    if (areaId != null) 'areaId': areaId,
  };
  factory RoutineStep.fromJson(Map<String, dynamic> json) => RoutineStep(
    id: json['id'] as String,
    name: json['name'] as String,
    type: TaskType.values.byName(json['type'] as String),
    areaId: readAreaId(json['areaId']),
    minimumFocusMinutes: json['minimumFocusMinutes'] as int?,
    focusTarget: json['focusTarget'] as String?,
  );
}

class RoutineDecision {
  final RoutineAction action;
  final String stepId;
  const RoutineDecision({required this.action, required this.stepId});
  Map<String, dynamic> toJson() => {'action': action.name, 'stepId': stepId};
  factory RoutineDecision.fromJson(Map<String, dynamic> json) =>
      RoutineDecision(
        action: _readAction(json['action'] as String),
        stepId: json['stepId'] as String,
      );
}

/// A repeating commitment. One step repeats the same task; several steps
/// rotate (Push → Pull → Legs), moving on only after a step stays in a plan.
class Routine {
  /// Decisions older than this are pruned; they only guard upcoming dates.
  static const decisionRetentionDays = 30;
  final String id, name;
  final List<RoutineStep> steps;
  final RoutineSchedule schedule;
  final int nextStepIndex, revision;
  final Map<String, RoutineDecision> decisions;
  Routine({
    required this.id,
    required String name,
    required Iterable<RoutineStep> steps,
    RoutineSchedule? schedule,
    this.nextStepIndex = 0,
    this.revision = 0,
    Map<String, RoutineDecision> decisions = const {},
  }) : name = name.trim(),
       steps = List.unmodifiable(steps),
       schedule = schedule ?? RoutineSchedule.daily(),
       decisions = Map.unmodifiable(decisions) {
    if (id.isEmpty ||
        this.name.isEmpty ||
        this.steps.isEmpty ||
        nextStepIndex < 0 ||
        nextStepIndex >= this.steps.length ||
        revision < 0 ||
        this.steps.map((step) => step.id).toSet().length != this.steps.length) {
      throw const FormatException('Invalid routine');
    }
    for (final entry in decisions.entries) {
      final date = DateTime.tryParse(entry.key);
      if (date == null ||
          routineDateKey(date) != entry.key ||
          entry.value.stepId.isEmpty) {
        throw const FormatException('Invalid routine decision date');
      }
    }
  }
  RoutineStep get nextStep => steps[nextStepIndex];
  bool get isRotation => steps.length > 1;

  Routine _copy({
    String? name,
    List<RoutineStep>? steps,
    RoutineSchedule? schedule,
    int? nextStepIndex,
    int? revision,
    Map<String, RoutineDecision>? decisions,
  }) => Routine(
    id: id,
    name: name ?? this.name,
    steps: steps ?? this.steps,
    schedule: schedule ?? this.schedule,
    nextStepIndex: nextStepIndex ?? this.nextStepIndex,
    revision: revision ?? this.revision,
    decisions: decisions ?? this.decisions,
  );

  Routine edit({
    required String name,
    required List<RoutineStep> steps,
    RoutineSchedule? schedule,
  }) {
    final index = steps.indexWhere((step) => step.id == nextStep.id);
    return _copy(
      name: name,
      steps: steps,
      schedule: schedule,
      nextStepIndex: index < 0 ? 0 : index,
      revision: revision + 1,
    );
  }

  Routine withSchedule(RoutineSchedule schedule) =>
      _copy(schedule: schedule, revision: revision + 1);

  Map<String, RoutineDecision> _pruned(DateTime date) {
    final oldest = DateTime(
      date.year,
      date.month,
      date.day - decisionRetentionDays,
    );
    return {
      for (final entry in decisions.entries)
        if (!DateTime.parse(entry.key).isBefore(oldest)) entry.key: entry.value,
    };
  }

  /// Records that [nextStep] was put in the plan for [date] and moves on.
  Routine add(DateTime date) {
    if (decisions.containsKey(routineDateKey(date))) return this;
    return _copy(
      nextStepIndex: (nextStepIndex + 1) % steps.length,
      decisions: {
        ..._pruned(date),
        routineDateKey(date): RoutineDecision(
          action: RoutineAction.added,
          stepId: nextStep.id,
        ),
      },
    );
  }

  /// Records an occurrence that already exists (the task the user was editing
  /// when they turned on Repeat), without adding a second copy.
  Routine recordExisting(DateTime date, String stepId) => _copy(
    decisions: {
      ..._pruned(date),
      routineDateKey(date): RoutineDecision(
        action: RoutineAction.added,
        stepId: stepId,
      ),
    },
  );

  /// The user took this date's step out of the plan. It is not re-added that
  /// day, and a rotation offers the same step again next time.
  Routine remove(DateTime date) {
    final key = routineDateKey(date);
    final decision = decisions[key];
    if (decision == null || decision.action != RoutineAction.added) {
      return this;
    }
    final index = steps.indexWhere((step) => step.id == decision.stepId);
    return _copy(
      nextStepIndex: index < 0 ? nextStepIndex : index,
      decisions: {
        ...decisions,
        key: RoutineDecision(
          action: RoutineAction.removed,
          stepId: decision.stepId,
        ),
      },
    );
  }

  /// Reverses [remove] for Undo: the step is back in the plan.
  Routine restore(DateTime date) {
    final key = routineDateKey(date);
    final decision = decisions[key];
    if (decision == null || decision.action != RoutineAction.removed) {
      return this;
    }
    final index = steps.indexWhere((step) => step.id == decision.stepId);
    return _copy(
      nextStepIndex: index < 0 ? nextStepIndex : (index + 1) % steps.length,
      decisions: {
        ...decisions,
        key: RoutineDecision(
          action: RoutineAction.added,
          stepId: decision.stepId,
        ),
      },
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'steps': steps.map((step) => step.toJson()).toList(),
    'schedule': schedule.toJson(),
    'nextStepIndex': nextStepIndex,
    'revision': revision,
    'decisions': decisions.map(
      (date, decision) => MapEntry(date, decision.toJson()),
    ),
  };
  factory Routine.fromJson(Map<String, dynamic> json) => Routine(
    id: json['id'] as String,
    name: json['name'] as String,
    steps: (json['steps'] as List).map(
      (step) => RoutineStep.fromJson(step as Map<String, dynamic>),
    ),
    // Routines saved before schedules existed were offered every day.
    schedule: json.containsKey('schedule')
        ? RoutineSchedule.fromJson(json['schedule'] as Map<String, dynamic>)
        : RoutineSchedule.daily(),
    nextStepIndex: json['nextStepIndex'] as int,
    revision: json['revision'] as int,
    decisions: (json['decisions'] as Map<String, dynamic>).map(
      (date, decision) => MapEntry(
        date,
        RoutineDecision.fromJson(decision as Map<String, dynamic>),
      ),
    ),
  );
}

class RoutineBook {
  final List<Routine> routines;
  static const empty = RoutineBook._empty();
  const RoutineBook._empty() : routines = const [];
  RoutineBook(Iterable<Routine> routines)
    : routines = List.unmodifiable(routines) {
    if (this.routines.map((routine) => routine.id).toSet().length !=
        this.routines.length) {
      throw const FormatException('Duplicate routine ID');
    }
  }
  Routine? byId(String? id) {
    for (final routine in routines) {
      if (routine.id == id) return routine;
    }
    return null;
  }

  RoutineBook upsert(Routine routine) => RoutineBook([
    for (final existing in routines)
      if (existing.id != routine.id) existing else routine,
    if (!routines.any((existing) => existing.id == routine.id)) routine,
  ]);
  RoutineBook remove(String id) =>
      RoutineBook(routines.where((routine) => routine.id != id));
  List<Map<String, dynamic>> toJson() =>
      routines.map((routine) => routine.toJson()).toList();
  factory RoutineBook.fromJson(List<dynamic> json) => RoutineBook(
    json.map((routine) => Routine.fromJson(routine as Map<String, dynamic>)),
  );
}

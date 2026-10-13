enum TaskType { goal, focus }

enum TaskOutcome {
  incomplete('Incomplete'),
  completed('Completed'),
  excused('Excused');

  final String label;
  const TaskOutcome(this.label);
}

class Task {
  static const legacyFocusMinutes = 25;
  static const maxExcuseReasonLength = 240;

  String name;
  final TaskType type;
  final int? minimumFocusMinutes;
  final String? focusTarget;
  int _accumulatedFocusMilliseconds;
  DateTime? focusStartedAt;
  late TaskOutcome _outcome;
  String? _excuseReason;

  Task({
    required this.name,
    required this.type,
    bool isCompleted = false,
    TaskOutcome? outcome,
    String? excuseReason,
    int? minimumFocusMinutes,
    String? focusTarget,
    int accumulatedFocusMilliseconds = 0,
    DateTime? focusStartedAt,
  }) : minimumFocusMinutes = type == TaskType.focus
           ? minimumFocusMinutes ?? legacyFocusMinutes
           : null,
       focusTarget =
           type == TaskType.focus && (focusTarget?.trim().isNotEmpty ?? false)
           ? focusTarget!.trim()
           : null,
       focusStartedAt = type == TaskType.focus ? focusStartedAt?.toUtc() : null,
       _accumulatedFocusMilliseconds = accumulatedFocusMilliseconds,
       _excuseReason = excuseReason?.trim() {
    if (type == TaskType.focus && this.minimumFocusMinutes! <= 0) {
      throw ArgumentError.value(
        minimumFocusMinutes,
        'minimumFocusMinutes',
        'Must be positive',
      );
    }
    if (accumulatedFocusMilliseconds < 0) {
      throw ArgumentError.value(
        accumulatedFocusMilliseconds,
        'accumulatedFocusMilliseconds',
      );
    }
    _outcome =
        outcome ??
        (type == TaskType.focus
            ? accumulatedFocusMilliseconds >= this.minimumFocusMinutes! * 60000
                  ? TaskOutcome.completed
                  : TaskOutcome.incomplete
            : isCompleted
            ? TaskOutcome.completed
            : TaskOutcome.incomplete);
    if (_outcome == TaskOutcome.excused) {
      _validateReason(_excuseReason);
      if (this.focusStartedAt != null) {
        throw const FormatException(
          'An excused task cannot have a running timer',
        );
      }
    } else if (_excuseReason != null) {
      throw const FormatException(
        'Only excused tasks can have an excuse reason',
      );
    }
    if (_outcome == TaskOutcome.completed &&
        type == TaskType.focus &&
        accumulatedFocusMilliseconds < this.minimumFocusMinutes! * 60000) {
      throw const FormatException(
        'Focus completion requires its minimum duration',
      );
    }
  }

  TaskOutcome get outcome => _outcome;
  String? get excuseReason => _excuseReason;
  bool get isCompleted => _outcome == TaskOutcome.completed;
  bool get isExcused => _outcome == TaskOutcome.excused;
  bool get isEligible => !isExcused;

  set isCompleted(bool value) {
    if (type == TaskType.focus) {
      throw StateError('Focus completion is determined by elapsed time');
    }
    _outcome = value ? TaskOutcome.completed : TaskOutcome.incomplete;
    _excuseReason = null;
  }

  int get accumulatedFocusMilliseconds => _accumulatedFocusMilliseconds;
  set accumulatedFocusMilliseconds(int value) {
    if (value < 0) {
      throw ArgumentError.value(value, 'accumulatedFocusMilliseconds');
    }
    _accumulatedFocusMilliseconds = value;
    if (type == TaskType.focus && !isExcused) {
      _outcome = value >= minimumFocusMinutes! * 60000
          ? TaskOutcome.completed
          : TaskOutcome.incomplete;
    }
  }

  static void _validateReason(String? reason) {
    if (reason == null ||
        reason.isEmpty ||
        reason.length > maxExcuseReasonLength) {
      throw const FormatException(
        'Excused tasks require a short written reason',
      );
    }
  }

  void changeOutcome(
    TaskOutcome outcome, {
    required DateTime now,
    String? reason,
  }) {
    final trimmed = reason?.trim();
    if (outcome == TaskOutcome.excused) _validateReason(trimmed);
    if (outcome == TaskOutcome.completed &&
        type == TaskType.focus &&
        focusMillisecondsAt(now) < minimumFocusMinutes! * 60000) {
      throw StateError('Focus completion requires its minimum duration');
    }
    // Settle first, then apply the outcome. No recorded time is discarded on reset.
    pauseFocus(now);
    _outcome = outcome;
    _excuseReason = outcome == TaskOutcome.excused ? trimmed : null;
  }

  bool get isFocusRunning =>
      type == TaskType.focus && !isExcused && focusStartedAt != null;

  int focusMillisecondsAt(DateTime now) {
    if (type != TaskType.focus) return 0;
    final elapsed = !isFocusRunning
        ? 0
        : now.toUtc().difference(focusStartedAt!).inMilliseconds;
    return (accumulatedFocusMilliseconds + (elapsed < 0 ? 0 : elapsed)).clamp(
      0,
      minimumFocusMinutes! * 60000,
    );
  }

  void startFocus(DateTime now) {
    if (type != TaskType.focus || isExcused || isCompleted || isFocusRunning) {
      return;
    }
    // A reset can retain a fully earned duration. Starting again completes it
    // immediately, without requiring repeated work or bypassing the minimum.
    if (accumulatedFocusMilliseconds >= minimumFocusMinutes! * 60000) {
      _outcome = TaskOutcome.completed;
    } else {
      focusStartedAt = now.toUtc();
    }
  }

  bool pauseFocus(DateTime now) {
    if (!isFocusRunning) return false;
    accumulatedFocusMilliseconds = focusMillisecondsAt(now);
    focusStartedAt = null;
    return true;
  }

  bool finishFocusIfDue(DateTime now) {
    if (!isFocusRunning ||
        focusMillisecondsAt(now) < minimumFocusMinutes! * 60000) {
      return false;
    }
    return pauseFocus(now);
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
      'focusStartedAt': focusStartedAt?.toIso8601String(),
    },
  };

  factory Task.fromJson(Map<String, dynamic> json) {
    final type = TaskType.values.byName(json['type'] as String);
    final completed = json['isCompleted'] as bool;
    TaskOutcome? savedOutcome;
    if (json.containsKey('outcome')) {
      final value = json['outcome'];
      savedOutcome = value is String
          ? TaskOutcome.values.asNameMap()[value]
          : null;
      if (savedOutcome == null) {
        throw const FormatException('Invalid saved task outcome');
      }
    }
    final minimum = json.containsKey('minimumFocusMinutes')
        ? json['minimumFocusMinutes'] as int
        : legacyFocusMinutes;
    final legacyCompletedFocus =
        type == TaskType.focus &&
        completed &&
        !json.containsKey('accumulatedFocusMilliseconds');
    final task = Task(
      name: json['name'] as String,
      type: type,
      isCompleted: completed,
      outcome: savedOutcome,
      excuseReason: json['excuseReason'] as String?,
      minimumFocusMinutes: minimum,
      focusTarget: json['focusTarget'] as String?,
      accumulatedFocusMilliseconds: legacyCompletedFocus
          ? minimum * 60000
          : (json['accumulatedFocusMilliseconds'] as int?) ?? 0,
      focusStartedAt: json['focusStartedAt'] == null
          ? null
          : DateTime.parse(json['focusStartedAt'] as String),
    );
    if (json.containsKey('outcome') && task.isCompleted != completed) {
      throw const FormatException('Saved task outcome and completion disagree');
    }
    return task;
  }
}

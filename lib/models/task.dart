import 'dart:math';

import 'area.dart';
import 'stopwatch_stamp.dart';

// Retained solely as legacy metadata. All Tasks now behave as commitments.
enum TaskType { goal, focus }

enum TaskOutcome {
  incomplete('Incomplete'),
  completed('Completed'),
  excused('Excused');

  final String label;
  const TaskOutcome(this.label);
}

String newCommitmentId() {
  final random = Random.secure();
  return List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

class Task {
  static const legacyFocusMinutes = 25;
  static const maxExcuseReasonLength = 240;
  final String id;
  String name;
  String? areaId;
  final TaskType type;
  final int? minimumFocusMinutes;
  final String? focusTarget;
  int _accumulatedFocusMilliseconds;
  DateTime? focusStartedAt;
  StopwatchStamp? _anchor;
  StopwatchStamp Function()? _clock;
  bool _legacyTimer = false;
  TaskOutcome _outcome;
  String? _excuseReason;

  Task({
    String? id,
    required this.name,
    this.type = TaskType.goal,
    this.areaId = Area.defaultId,
    bool isCompleted = false,
    TaskOutcome? outcome,
    String? excuseReason,
    int? minimumFocusMinutes,
    String? focusTarget,
    int accumulatedFocusMilliseconds = 0,
    DateTime? focusStartedAt,
    StopwatchStamp? stopwatchAnchor,
  }) : id = id ?? newCommitmentId(),
       minimumFocusMinutes = type == TaskType.focus
           ? minimumFocusMinutes ?? legacyFocusMinutes
           : minimumFocusMinutes,
       focusTarget = focusTarget?.trim().isEmpty == true
           ? null
           : focusTarget?.trim(),
       focusStartedAt = focusStartedAt?.toUtc(),
       _anchor = stopwatchAnchor,
       _accumulatedFocusMilliseconds = accumulatedFocusMilliseconds,
       _outcome =
           outcome ??
           (isCompleted ? TaskOutcome.completed : TaskOutcome.incomplete),
       _excuseReason = excuseReason?.trim() {
    if (this.id.isEmpty ||
        accumulatedFocusMilliseconds < 0 ||
        (this.minimumFocusMinutes != null && this.minimumFocusMinutes! <= 0)) {
      throw const FormatException('Invalid commitment');
    }
    if (_outcome == TaskOutcome.excused) {
      _validateReason(_excuseReason);
    } else if (_excuseReason != null) {
      throw const FormatException(
        'Only excused tasks can have an excuse reason',
      );
    }
  }

  TaskOutcome get outcome => _outcome;
  String? get excuseReason => _excuseReason;
  bool get isCompleted => outcome == TaskOutcome.completed;
  bool get isExcused => outcome == TaskOutcome.excused;
  bool get isEligible => !isExcused;
  set isCompleted(bool value) => changeOutcome(
    value ? TaskOutcome.completed : TaskOutcome.incomplete,
    now: _clock?.call().wall ?? DateTime.now(),
  );
  int get accumulatedFocusMilliseconds => _accumulatedFocusMilliseconds;
  set accumulatedFocusMilliseconds(int value) {
    if (value < 0) {
      throw ArgumentError.value(value, 'accumulatedFocusMilliseconds');
    }
    _accumulatedFocusMilliseconds = value;
  }

  void bindStopwatchClock(StopwatchStamp Function() clock) => _clock = clock;
  bool get isFocusRunning =>
      outcome == TaskOutcome.incomplete && focusStartedAt != null;

  int _elapsed(DateTime now) {
    if (!isFocusRunning) return 0;
    final current = _clock?.call();
    if (current != null && _anchor != null) {
      if (_anchor!.session != current.session) return 0;
      return max(0, current.elapsedMilliseconds - _anchor!.elapsedMilliseconds);
    }
    // Standalone callers use an explicit clock. Production binds a monotonic
    // source before exposing loaded commitments to the UI.
    return max(0, now.toUtc().difference(focusStartedAt!).inMilliseconds);
  }

  int focusMillisecondsAt(DateTime now) =>
      accumulatedFocusMilliseconds + _elapsed(now);

  void startFocus(DateTime now) {
    if (outcome != TaskOutcome.incomplete || isFocusRunning) return;
    _anchor = _clock?.call();
    focusStartedAt = (_anchor?.wall ?? now).toUtc();
    _legacyTimer = false;
  }

  bool pauseFocus(DateTime now) {
    if (focusStartedAt == null) return false;
    if (isFocusRunning) _accumulatedFocusMilliseconds += _elapsed(now);
    focusStartedAt = null;
    _anchor = null;
    _legacyTimer = false;
    return true;
  }

  bool discardStopwatchAnchor() {
    final changed = focusStartedAt != null;
    focusStartedAt = null;
    _anchor = null;
    _legacyTimer = false;
    return changed;
  }

  // Source compatibility only: stopwatches have no deadline or auto-completion.
  bool finishFocusIfDue(DateTime now) => false;

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
    pauseFocus(now);
    _outcome = outcome;
    _excuseReason = outcome == TaskOutcome.excused ? trimmed : null;
  }

  /// A date boundary is not an elapsed 24-hour interval (DST matters). If wall
  /// time changed substantially, keep only checkpointed time for an old day.
  int millisecondsAtBoundary(DateTime end) {
    if (!isFocusRunning) return accumulatedFocusMilliseconds;
    final stamp = _clock?.call();
    final elapsed = _elapsed(stamp?.wall ?? end);
    if (stamp != null &&
        _anchor != null &&
        (stamp.wall.difference(_anchor!.wall).inMilliseconds - elapsed).abs() >
            120000) {
      return accumulatedFocusMilliseconds;
    }
    return accumulatedFocusMilliseconds +
        min(
          elapsed,
          max(0, end.toUtc().difference(focusStartedAt!).inMilliseconds),
        );
  }

  /// Same-boot Android anchors survive process death. Rebooted or unknown
  /// anchors pause without guessing elapsed time. Legacy wall-only data uses
  /// an explicit bounded best-effort migration, not an exact-time claim.
  bool recoverStopwatch(StopwatchStamp stamp, DateTime dayEnd) {
    if (focusStartedAt == null) return false;
    if (!isFocusRunning) return pauseFocus(stamp.wall);
    if (_anchor != null &&
        _anchor!.session == stamp.session &&
        stamp.elapsedMilliseconds >= _anchor!.elapsedMilliseconds) {
      return false;
    }
    if (_legacyTimer) {
      final delta = stamp.wall.difference(focusStartedAt!).inMilliseconds;
      if (delta >= 0 && delta <= const Duration(hours: 24).inMilliseconds) {
        _accumulatedFocusMilliseconds += min(
          delta,
          max(0, dayEnd.toUtc().difference(focusStartedAt!).inMilliseconds),
        );
        focusStartedAt = null;
        _anchor = null;
        _legacyTimer = false;
        if (stamp.wall.isBefore(dayEnd.toUtc())) startFocus(stamp.wall);
        return true;
      }
    }
    focusStartedAt = null;
    _anchor = null;
    _legacyTimer = false;
    return true;
  }

  void checkpointStopwatch(DateTime now) {
    if (!isFocusRunning) return;
    _accumulatedFocusMilliseconds += _elapsed(now);
    _anchor = _clock?.call();
    focusStartedAt = (_anchor?.wall ?? now).toUtc();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'isCompleted': isCompleted,
    'outcome': outcome.name,
    'excuseReason': excuseReason,
    if (areaId != null) 'areaId': areaId,
    if (minimumFocusMinutes != null) 'minimumFocusMinutes': minimumFocusMinutes,
    if (focusTarget != null) 'focusTarget': focusTarget,
    'accumulatedFocusMilliseconds': accumulatedFocusMilliseconds,
    'focusStartedAt': focusStartedAt?.toIso8601String(),
    if (!_legacyTimer) 'stopwatchVersion': 1,
    if (_anchor != null) 'stopwatchAnchor': _anchor!.toJson(),
  };

  factory Task.fromJson(Map<String, dynamic> json, {String? fallbackId}) {
    final type = TaskType.values.byName(json['type'] as String? ?? 'goal');
    final completed = json['isCompleted'] as bool;
    final rawOutcome = json['outcome'];
    final outcome = rawOutcome == null
        ? (completed ? TaskOutcome.completed : TaskOutcome.incomplete)
        : TaskOutcome.values.asNameMap()[rawOutcome];
    if (outcome == null || (outcome == TaskOutcome.completed) != completed) {
      throw const FormatException('Saved task outcome and completion disagree');
    }
    final rawStart = json['focusStartedAt'];
    final task = Task(
      id: json['id'] as String? ?? fallbackId,
      name: json['name'] as String,
      type: type,
      areaId: readAreaId(json['areaId']),
      outcome: outcome,
      excuseReason: json['excuseReason'] as String?,
      minimumFocusMinutes: json['minimumFocusMinutes'] as int?,
      focusTarget: json['focusTarget'] as String?,
      accumulatedFocusMilliseconds:
          json['accumulatedFocusMilliseconds'] as int? ?? 0,
      focusStartedAt: rawStart is String ? DateTime.tryParse(rawStart) : null,
      stopwatchAnchor: StopwatchStamp.read(json['stopwatchAnchor']),
    );
    task._legacyTimer =
        !json.containsKey('stopwatchVersion') && task.focusStartedAt != null;
    return task;
  }
}

import '../models/daylock_state.dart';
import '../models/task.dart';
import 'stopwatch_clock.dart';

/// App-wide coordinator, independent of the visible page. One snapshot write
/// persists both sides of a switch; MainApp serializes commands and saves.
class CommitmentStopwatches {
  final StopwatchClock clock;
  CommitmentStopwatches(this.clock);

  bool reconcile(DaylockState state, {bool recovering = false}) {
    var changed = false;
    Task? running;
    final day = state.todayPlan.date;
    final end = DateTime(day.year, day.month, day.day + 1);
    for (final task in state.todayPlan.tasks) {
      task.bindStopwatchClock(() => clock.current);
      if (running != null && task.isFocusRunning) {
        changed = task.discardStopwatchAnchor() || changed;
        continue;
      }
      if (recovering) {
        changed = task.recoverStopwatch(clock.current, end) || changed;
      }
      if (task.isFocusRunning) {
        if (running != null) {
          // Conflicting persisted anchors cannot both establish elapsed effort.
          // Keep recorded totals but do not invent overlapping uncheckpointed time.
          changed = task.discardStopwatchAnchor() || changed;
        } else {
          running = task;
        }
      } else {
        changed = task.discardStopwatchAnchor() || changed;
      }
    }
    for (final task in state.tomorrowPlan.tasks) {
      task.bindStopwatchClock(() => clock.current);
      changed = task.discardStopwatchAnchor() || changed;
    }
    return changed;
  }

  void toggle(DaylockState state, Task task) {
    reconcile(state);
    if (!state.todayPlan.tasks.contains(task) ||
        task.outcome != TaskOutcome.incomplete) {
      return;
    }
    final now = clock.current.wall;
    if (task.isFocusRunning) {
      task.pauseFocus(now);
    } else {
      for (final previous in state.todayPlan.tasks) {
        previous.pauseFocus(now);
      }
      task.startFocus(now);
    }
  }

  bool checkpoint(DaylockState state) {
    final running = state.todayPlan.tasks.where((t) => t.isFocusRunning);
    for (final task in running) {
      task.checkpointStopwatch(clock.current.wall);
    }
    return running.isNotEmpty;
  }
}

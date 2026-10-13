import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/task.dart';

// Explicit saved user data for tests; these are never seeded by the app.
DaylockState existingCommitments(DateTime date) => DaylockState(
  todayPlan: DailyPlan(
    date: date,
    tasks: [
      Task(name: 'Existing goal', type: TaskType.goal),
      Task(
        name: 'Existing focus',
        type: TaskType.focus,
        minimumFocusMinutes: 25,
      ),
      Task(name: 'Another goal', type: TaskType.goal),
    ],
    isCommitted: true,
  ),
  tomorrowPlan: DailyPlan(
    date: DateTime(date.year, date.month, date.day + 1),
    tasks: [],
  ),
);

import '../models/area.dart';
import '../models/daily_plan.dart';
import '../models/routine.dart';
import '../models/task.dart';

class RoutineApplication {
  final RoutineBook book;
  final List<Task> added;
  const RoutineApplication({required this.book, this.added = const []});
  bool get changed => added.isNotEmpty;
}

class RoutineService {
  const RoutineService();

  /// Routines due on [plan]'s date that have not been handled for that date
  /// yet. A committed plan is never changed.
  List<Routine> due(RoutineBook book, DailyPlan plan) => [
    if (!plan.isCommitted)
      for (final routine in book.routines)
        if (routine.schedule.isDue(plan.date) &&
            !routine.decisions.containsKey(routineDateKey(plan.date)) &&
            !plan.tasks.any((task) => task.routineId == routine.id))
          routine,
  ];

  /// Builds each due routine's next step as a real commitment for [plan].
  /// The caller appends [RoutineApplication.added] and saves both together.
  RoutineApplication apply(
    RoutineBook book,
    DailyPlan plan, {
    AreaBook? areas,
  }) {
    final routines = due(book, plan);
    if (routines.isEmpty) return RoutineApplication(book: book);
    var updated = book;
    final added = <Task>[];
    for (final routine in routines) {
      final task = routine.nextStep.toTask(routineId: routine.id);
      if (areas != null) task.areaId = areas.forNewCommitment(task.areaId).id;
      added.add(task);
      updated = updated.upsert(routine.add(plan.date));
    }
    return RoutineApplication(book: updated, added: added);
  }
}

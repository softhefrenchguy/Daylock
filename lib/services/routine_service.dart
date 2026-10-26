import '../models/routine.dart';
import '../models/task.dart';
import '../models/area.dart';

class RoutineSuggestion {
  final String routineId, routineName;
  final DateTime date;
  final int revision;
  final RoutineStep step;
  const RoutineSuggestion({
    required this.routineId,
    required this.routineName,
    required this.date,
    required this.revision,
    required this.step,
  });
}

class RoutineResolution {
  final RoutineBook book;
  final Task? task;
  final bool changed;
  const RoutineResolution({
    required this.book,
    this.task,
    required this.changed,
  });
}

class RoutineService {
  const RoutineService();
  List<RoutineSuggestion> suggestions(RoutineBook book, DateTime date) =>
      List.unmodifiable([
        for (final routine in book.routines)
          if (!routine.decisions.containsKey(routineDateKey(date)))
            RoutineSuggestion(
              routineId: routine.id,
              routineName: routine.name,
              date: DateTime(date.year, date.month, date.day),
              revision: routine.revision,
              step: routine.nextStep,
            ),
      ]);
  RoutineResolution resolve(
    RoutineBook book,
    RoutineSuggestion suggestion,
    RoutineAction action,
    DateTime planDate, {
    AreaBook? areas,
  }) {
    if (routineDateKey(suggestion.date) != routineDateKey(planDate)) {
      return RoutineResolution(book: book, changed: false);
    }
    final matches = book.routines.where(
      (routine) => routine.id == suggestion.routineId,
    );
    if (matches.isEmpty) return RoutineResolution(book: book, changed: false);
    final routine = matches.single;
    if (routine.decisions.containsKey(routineDateKey(planDate)) ||
        routine.revision != suggestion.revision ||
        routine.nextStep.id != suggestion.step.id) {
      return RoutineResolution(book: book, changed: false);
    }
    final task = action == RoutineAction.accept
        ? routine.nextStep.toTask()
        : null;
    if (task != null && areas != null) {
      task.areaId = areas.forNewCommitment(task.areaId).id;
    }
    return RoutineResolution(
      book: book.upsert(routine.decide(planDate, action)),
      changed: true,
      task: task,
    );
  }
}

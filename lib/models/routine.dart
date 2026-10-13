import 'dart:math';

import 'task.dart';

String newRoutineId() {
  final random = Random.secure();
  return List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

String routineDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

enum RoutineAction { accept, skip, dismiss }

class RoutineStep {
  final String id, name;
  final TaskType type;
  final int? minimumFocusMinutes;
  final String? focusTarget;
  RoutineStep({
    required this.id,
    required String name,
    required this.type,
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
      throw const FormatException('Invalid routine suggestion');
    }
  }
  factory RoutineStep.fromTask(Task task, {String? id}) => RoutineStep(
    id: id ?? newRoutineId(),
    name: task.name,
    type: task.type,
    minimumFocusMinutes: task.minimumFocusMinutes,
    focusTarget: task.focusTarget,
  );
  Task toTask() => Task(
    name: name,
    type: type,
    minimumFocusMinutes: minimumFocusMinutes,
    focusTarget: focusTarget,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'minimumFocusMinutes': minimumFocusMinutes,
    'focusTarget': focusTarget,
  };
  factory RoutineStep.fromJson(Map<String, dynamic> json) => RoutineStep(
    id: json['id'] as String,
    name: json['name'] as String,
    type: TaskType.values.byName(json['type'] as String),
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
        action: RoutineAction.values.byName(json['action'] as String),
        stepId: json['stepId'] as String,
      );
}

class Routine {
  final String id, name;
  final List<RoutineStep> steps;
  final int nextStepIndex, revision;
  final Map<String, RoutineDecision> decisions;
  Routine({
    required this.id,
    required String name,
    required Iterable<RoutineStep> steps,
    this.nextStepIndex = 0,
    this.revision = 0,
    Map<String, RoutineDecision> decisions = const {},
  }) : name = name.trim(),
       steps = List.unmodifiable(steps),
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
  Routine edit({required String name, required List<RoutineStep> steps}) {
    final index = steps.indexWhere((step) => step.id == nextStep.id);
    return Routine(
      id: id,
      name: name,
      steps: steps,
      nextStepIndex: index < 0 ? 0 : index,
      revision: revision + 1,
      decisions: decisions,
    );
  }

  Routine decide(DateTime date, RoutineAction action) {
    if (decisions.containsKey(routineDateKey(date))) return this;
    return Routine(
      id: id,
      name: name,
      steps: steps,
      nextStepIndex: action == RoutineAction.dismiss
          ? nextStepIndex
          : (nextStepIndex + 1) % steps.length,
      revision: revision,
      decisions: {
        ...decisions,
        routineDateKey(date): RoutineDecision(
          action: action,
          stepId: nextStep.id,
        ),
      },
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'steps': steps.map((step) => step.toJson()).toList(),
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

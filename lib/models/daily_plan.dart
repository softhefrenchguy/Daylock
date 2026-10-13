import 'task.dart';
import 'commitment_progress.dart';

class DailyPlan {
  final DateTime date;
  final List<Task> tasks;
  bool isCommitted;

  DailyPlan({
    required DateTime date,
    required this.tasks,
    this.isCommitted = false,
  }) : date = DateTime(date.year, date.month, date.day);

  CommitmentProgress get progress =>
      CommitmentProgress.fromOutcomes(tasks.map((task) => task.outcome));

  Map<String, dynamic> toJson() => {
    'date':
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}',
    'tasks': tasks.map((task) => task.toJson()).toList(),
    'isCommitted': isCommitted,
  };

  factory DailyPlan.fromJson(Map<String, dynamic> json) {
    final value = json['date'] as String;
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      throw FormatException('Invalid plan date', value);
    }
    final parts = value.split('-').map(int.parse).toList();
    final date = DateTime(parts[0], parts[1], parts[2]);
    if (date.year != parts[0] ||
        date.month != parts[1] ||
        date.day != parts[2]) {
      throw FormatException('Invalid plan date', value);
    }

    return DailyPlan(
      date: date,
      tasks: (json['tasks'] as List)
          .map((task) => Task.fromJson(task as Map<String, dynamic>))
          .toList(),
      isCommitted: json['isCommitted'] as bool,
    );
  }
}

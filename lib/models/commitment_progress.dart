import 'task.dart';

// Shared by live plans, immutable history and Calendar projections. Events never
// enter this calculation, and excused commitments are neither completed nor owed.
class CommitmentProgress {
  final int totalCount;
  final int completedCount;
  final int excusedCount;

  const CommitmentProgress._(
    this.totalCount,
    this.completedCount,
    this.excusedCount,
  );

  factory CommitmentProgress.fromOutcomes(Iterable<TaskOutcome> outcomes) {
    var total = 0;
    var completed = 0;
    var excused = 0;
    for (final outcome in outcomes) {
      total++;
      if (outcome == TaskOutcome.completed) completed++;
      if (outcome == TaskOutcome.excused) excused++;
    }
    return CommitmentProgress._(total, completed, excused);
  }

  int get eligibleCount => totalCount - excusedCount;
  int get remainingCount => eligibleCount - completedCount;
  bool get isNeutral => eligibleCount == 0;
  bool get isComplete => !isNeutral && completedCount == eligibleCount;
  double? get fraction => isNeutral ? null : completedCount / eligibleCount;
  double? get percentage => fraction == null ? null : fraction! * 100;
}

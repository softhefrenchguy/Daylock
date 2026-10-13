import '../models/daily_plan.dart';
import '../models/freedom_settings.dart';

class FreedomEligibility {
  final FreedomSettings settings;
  final bool currentPlans,
      timeReached,
      hasEligibleCommitments,
      commitmentsCompleted,
      tomorrowCommitted;
  final int completedCount, eligibleCount;
  const FreedomEligibility({
    required this.settings,
    required this.currentPlans,
    required this.timeReached,
    required this.hasEligibleCommitments,
    required this.commitmentsCompleted,
    required this.tomorrowCommitted,
    required this.completedCount,
    required this.eligibleCount,
  });
  bool get conditionsSatisfied =>
      currentPlans &&
      timeReached &&
      hasEligibleCommitments &&
      commitmentsCompleted &&
      tomorrowCommitted;
  bool get earned => settings.enabled && conditionsSatisfied;
}

// Pure eligibility only. This service never blocks apps or changes plans.
class FreedomService {
  const FreedomService();
  FreedomEligibility evaluate({
    required DateTime now,
    required FreedomSettings settings,
    required DailyPlan todayPlan,
    DailyPlan? tomorrowPlan,
  }) {
    settings.toJson();
    final local = now.isUtc ? now.toLocal() : now;
    final date = DateTime(local.year, local.month, local.day);
    final nextDate = DateTime(local.year, local.month, local.day + 1);
    final progress = todayPlan.progress;
    return FreedomEligibility(
      settings: settings,
      currentPlans: todayPlan.date == date,
      timeReached:
          local.hour * 60 + local.minute >=
          settings.hour * 60 + settings.minute,
      hasEligibleCommitments: progress.eligibleCount > 0,
      commitmentsCompleted: progress.isComplete,
      tomorrowCommitted:
          tomorrowPlan?.date == nextDate && tomorrowPlan!.isCommitted,
      completedCount: progress.completedCount,
      eligibleCount: progress.eligibleCount,
    );
  }
}

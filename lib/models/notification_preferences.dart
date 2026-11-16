/// Preferences are independent of operating-system permission.
class NotificationPreferences {
  final bool planTomorrow, commitments, freedom, focus;

  /// Sunday-evening weekly review.
  final bool weekly;
  final int planMinute, commitmentMinute;
  const NotificationPreferences({
    this.planTomorrow = true,
    this.commitments = true,
    this.freedom = true,
    this.focus = true,
    this.weekly = true,
    this.planMinute = 1200,
    this.commitmentMinute = 840,
  });
  NotificationPreferences copyWith({
    bool? planTomorrow,
    bool? commitments,
    bool? freedom,
    bool? focus,
    bool? weekly,
    int? planMinute,
    int? commitmentMinute,
  }) => NotificationPreferences(
    planTomorrow: planTomorrow ?? this.planTomorrow,
    commitments: commitments ?? this.commitments,
    freedom: freedom ?? this.freedom,
    focus: focus ?? this.focus,
    weekly: weekly ?? this.weekly,
    planMinute: planMinute ?? this.planMinute,
    commitmentMinute: commitmentMinute ?? this.commitmentMinute,
  );
  Map<String, dynamic> toJson() {
    if (planMinute < 0 ||
        planMinute >= 1440 ||
        commitmentMinute < 0 ||
        commitmentMinute >= 1440) {
      throw const FormatException('Invalid notification time');
    }
    return {
      'planTomorrow': planTomorrow,
      'commitments': commitments,
      'freedom': freedom,
      'focus': focus,
      'weekly': weekly,
      'planMinute': planMinute,
      'commitmentMinute': commitmentMinute,
    };
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    final value = NotificationPreferences(
      planTomorrow: json['planTomorrow'] as bool,
      commitments: json['commitments'] as bool,
      freedom: json['freedom'] as bool,
      focus: json['focus'] as bool,
      // Settings saved before the weekly review existed turn it on.
      weekly: json['weekly'] as bool? ?? true,
      planMinute: json['planMinute'] as int,
      commitmentMinute: json['commitmentMinute'] as int,
    );
    value.toJson();
    return value;
  }
}

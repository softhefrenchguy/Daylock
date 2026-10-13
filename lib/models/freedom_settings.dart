class FreedomSettings {
  final bool enabled;
  final int hour;
  final int minute;

  const FreedomSettings({
    this.enabled = false,
    this.hour = 18,
    this.minute = 0,
  });
  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  FreedomSettings copyWith({bool? enabled, int? hour, int? minute}) =>
      FreedomSettings(
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );
  Map<String, dynamic> toJson() {
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw const FormatException('Invalid Freedom Time');
    }
    return {'enabled': enabled, 'hour': hour, 'minute': minute};
  }

  factory FreedomSettings.fromJson(Map<String, dynamic> json) {
    final settings = FreedomSettings(
      enabled: json['enabled'] as bool,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
    );
    settings.toJson();
    return settings;
  }
}

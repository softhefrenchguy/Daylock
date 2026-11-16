/// A break taken from the lock screen: which app, when, and why. Recorded by
/// the Android side; Daylock shows them in the Journey.
class BreakEntry {
  final DateTime at;
  final String app, reason;
  const BreakEntry({required this.at, required this.app, required this.reason});

  /// Reads one entry from the native status map; null if it is malformed.
  static BreakEntry? fromMap(Object? value) {
    if (value is! Map) return null;
    final at = value['at'], app = value['app'], reason = value['reason'];
    if (at is! int || reason is! String) return null;
    return BreakEntry(
      at: DateTime.fromMillisecondsSinceEpoch(at),
      app: app is String && app.isNotEmpty ? app : '?',
      reason: reason,
    );
  }

  /// Breaks from the last [days] days before [now], newest first.
  static List<BreakEntry> recent(
    Iterable<BreakEntry> all,
    DateTime now, {
    int days = 30,
  }) {
    final from = now.subtract(Duration(days: days));
    return all.where((b) => b.at.isAfter(from)).toList()
      ..sort((a, b) => b.at.compareTo(a.at));
  }
}

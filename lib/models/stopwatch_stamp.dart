/// A monotonic timestamp is comparable only within the same boot/session.
class StopwatchStamp {
  final DateTime wall;
  final int elapsedMilliseconds;
  final String session;
  const StopwatchStamp(this.wall, this.elapsedMilliseconds, this.session);
  Map<String, dynamic> toJson() => {
    'wall': wall.toUtc().toIso8601String(),
    'elapsed': elapsedMilliseconds,
    'session': session,
  };
  static StopwatchStamp? read(Object? value) {
    if (value is! Map) return null;
    final wall = value['wall'];
    final elapsed = value['elapsed'];
    final session = value['session'];
    if (wall is! String ||
        elapsed is! int ||
        elapsed < 0 ||
        session is! String ||
        session.isEmpty) {
      return null;
    }
    final parsed = DateTime.tryParse(wall);
    return parsed == null
        ? null
        : StopwatchStamp(parsed.toUtc(), elapsed, session);
  }
}

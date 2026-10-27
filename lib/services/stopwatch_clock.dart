import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/stopwatch_stamp.dart';

/// Android elapsedRealtime includes deep sleep and is stable across processes
/// within one boot. Between native samples, Dart's monotonic Stopwatch drives UI.
class StopwatchClock {
  final DateTime Function() wallNow;
  final bool android;
  final MethodChannel channel;
  final Stopwatch _ticks = Stopwatch()..start();
  final String _process =
      'process-${Random.secure().nextInt(1 << 32)}-${DateTime.now().microsecondsSinceEpoch}';
  StopwatchStamp? _base;
  bool _processOnly = false;
  int _sampleTick = 0;
  Future<void> _pending = Future.value();
  StopwatchClock({
    DateTime Function()? wallNow,
    bool? android,
    MethodChannel? channel,
  }) : wallNow = wallNow ?? DateTime.now,
       android =
           android ??
           (!kIsWeb && defaultTargetPlatform == TargetPlatform.android),
       channel = channel ?? const MethodChannel('daylock/stopwatch_clock');
  StopwatchStamp get current => StopwatchStamp(
    wallNow().toUtc(),
    (_base?.elapsedMilliseconds ?? 0) +
        _ticks.elapsedMilliseconds -
        _sampleTick,
    _base?.session ?? _process,
  );
  Future<void> synchronize() {
    final operation = _pending.then((_) async {
      if (!android || _processOnly) return;
      try {
        final raw = await channel.invokeMapMethod<String, dynamic>('read');
        final elapsed = raw?['elapsedMs'];
        final boot = raw?['bootCount'];
        if (elapsed is int && elapsed >= 0 && boot is int && boot >= 0) {
          _base = StopwatchStamp(
            wallNow().toUtc(),
            elapsed,
            'android-boot-$boot',
          );
          _sampleTick = _ticks.elapsedMilliseconds;
        } else if (_base == null) {
          _processOnly = true;
        }
      } on MissingPluginException {
        // Desktop/web use a process-local monotonic clock; recovery is conservative.
        if (_base == null) _processOnly = true;
      } on PlatformException {
        // Retain the last known monotonic source rather than jumping to wall time.
        if (_base == null) _processOnly = true;
      }
    });
    _pending = operation.catchError((Object _) {});
    return operation;
  }
}

/// Compatibility clock for existing deterministic app tests injecting `now`.
/// Production always uses StopwatchClock; new clock-change tests inject their
/// wall and monotonic readings independently.
class InjectedStopwatchClock extends StopwatchClock {
  InjectedStopwatchClock(DateTime Function() now)
    : super(wallNow: now, android: false);
  @override
  StopwatchStamp get current => StopwatchStamp(
    wallNow().toUtc(),
    wallNow().millisecondsSinceEpoch,
    'injected-test-clock',
  );
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../design/appearance_preferences.dart';
import '../design/daylock_theme.dart';

import '../models/daily_plan.dart';
import 'freedom_service.dart';

// Only the FreedomService result's inputs are shared. No task names/reasons, events,
// accounts or credentials cross this channel. Native code owns durable revisions.
class NativeFreedomInput {
  final Map<String, Object> values;
  NativeFreedomInput._(Map<String, Object> values)
    : values = Map.unmodifiable(values);
  factory NativeFreedomInput.fromEligibility(
    DailyPlan plan,
    FreedomEligibility eligibility, {
    required DailyPlan tomorrowPlan,
  }) {
    final running = plan.tasks.where((task) => task.isFocusRunning).firstOrNull;
    final focusCompletesAtMs = running?.focusStartedAt?.millisecondsSinceEpoch;
    return NativeFreedomInput._({
      'date':
          '${plan.date.year.toString().padLeft(4, '0')}-${plan.date.month.toString().padLeft(2, '0')}-${plan.date.day.toString().padLeft(2, '0')}',
      'enabled': eligibility.settings.enabled,
      'hour': eligibility.settings.hour,
      'minute': eligibility.settings.minute,
      // Changes at the boundary trigger an immediate publication/status refresh.
      // Native eligibility still evaluates its own current local minute.
      'timeReached': eligibility.timeReached,
      'eligibleCount': eligibility.eligibleCount,
      'completedCount': eligibility.completedCount,
      'tomorrowCommitted': eligibility.tomorrowCommitted,
      'runningFocus': plan.tasks.any((task) => task.isFocusRunning),
      'tomorrowPlan': Map<String, Object>.unmodifiable({
        'date':
            '${tomorrowPlan.date.year.toString().padLeft(4, '0')}-${tomorrowPlan.date.month.toString().padLeft(2, '0')}-${tomorrowPlan.date.day.toString().padLeft(2, '0')}',
        'eligibleCount': tomorrowPlan.progress.eligibleCount,
        'completedCount': tomorrowPlan.progress.completedCount,
      }),
      if (running != null && focusCompletesAtMs != null)
        'focusCompletesAtMs':
            focusCompletesAtMs +
            running.minimumFocusMinutes! * 60000 -
            running.accumulatedFocusMilliseconds,
    });
  }
}

class InstagramDetectionStatus {
  final bool supported, enabled, connected, detectionSaveFailed;
  final DateTime? lastDetectedAt;
  final String? freedomAtDetection;
  final String freedomState, freedomReason;
  final String? error;
  final bool blockingEnabled;
  final String? lastRestriction;
  final bool blockingSaveFailed;
  final int revision;
  const InstagramDetectionStatus({
    this.supported = false,
    this.enabled = false,
    this.connected = false,
    this.detectionSaveFailed = false,
    this.lastDetectedAt,
    this.freedomAtDetection,
    this.freedomState = 'unknown',
    this.freedomReason = 'missing',
    this.error,
    this.blockingEnabled = false,
    this.lastRestriction,
    this.blockingSaveFailed = false,
    this.revision = 0,
  });
  factory InstagramDetectionStatus.fromMap(Map<dynamic, dynamic> map) {
    final latest = map['lastDetection'] as Map?;
    final freedom = map['freedom'] as Map;
    final enabled = map['enabled'] as bool;
    return InstagramDetectionStatus(
      supported: map['supported'] as bool,
      enabled: enabled,
      connected: enabled && map['connected'] == true,
      detectionSaveFailed: map['detectionSaveFailed'] == true,
      lastDetectedAt: latest == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(latest['detectedAtMs'] as int),
      freedomAtDetection: latest?['freedomState'] as String?,
      freedomState: freedom['state'] as String,
      freedomReason: freedom['reason'] as String,
      blockingEnabled: map['blockingEnabled'] == true,
      lastRestriction: map['lastRestriction'] as String?,
      blockingSaveFailed: map['blockingSaveFailed'] == true,
      revision: map['revision'] as int? ?? 0,
    );
  }
  static String freedomLabel(String state) => switch (state) {
    'earned' => 'Earned',
    'notEarned' => 'Not earned',
    'disabled' => 'Control off',
    _ => 'Unknown',
  };
}

class InstagramDetectionBridge {
  final MethodChannel _methods;
  final EventChannel _events;
  final bool _android;
  final status = ValueNotifier(const InstagramDetectionStatus());
  Future<void>? _ready;
  Future<void> _pending = Future.value();
  StreamSubscription<dynamic>? _subscription;
  bool _closed = false;
  bool _available = false;
  Map<String, Object>? _lastPublished;
  int _nativeRevision = 0;

  InstagramDetectionBridge({
    MethodChannel? methods,
    EventChannel? events,
    bool? android,
  }) : _methods = methods ?? const MethodChannel('daylock/instagram_detection'),
       _events =
           events ?? const EventChannel('daylock/instagram_detection/events'),
       _android =
           android ??
           (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  Future<void> start() => _ready ??= _start();
  Future<void> _start() async {
    if (!_android || _closed) return;
    try {
      // On launch old cached eligibility cannot survive an unreadable planner save.
      _receive(await _methods.invokeMethod('invalidateSnapshot'));
      _available = true;
      if (_closed) return;
      _subscription = _events.receiveBroadcastStream().listen(
        _receive,
        onError: (Object error) => _failed(),
      );
    } on MissingPluginException {
      _available = false;
    } catch (_) {
      _available =
          true; // The channel exists; permit retry after a native failure.
      _failed();
    }
  }

  void _receive(dynamic value) {
    if (_closed) return;
    try {
      final next = InstagramDetectionStatus.fromMap(value as Map);
      if (next.revision < _nativeRevision) return;
      _nativeRevision = next.revision;
      status.value = next;
    } catch (_) {
      _failed();
    }
  }

  void _failed() {
    if (_closed) return;
    final old = status.value;
    _lastPublished = null;
    status.value = InstagramDetectionStatus(
      supported: _android,
      // Unknown permission/connectivity must not be presented as enabled.
      lastDetectedAt: old.lastDetectedAt,
      freedomAtDetection: old.freedomAtDetection,
      error: 'Could not read native detection status. Refresh or open Android Settings manually.',
      freedomReason: 'native_unavailable',
      blockingEnabled: old.blockingEnabled,
      lastRestriction: old.lastRestriction,
      revision: _nativeRevision,
    );
  }

  Future<void> _call(String method, [Object? arguments]) {
    final operation = _pending.then((_) async {
      await start();
      if (!_available || _closed) return;
      try {
        final payload = method == 'publishSnapshot'
            ? {...arguments as Map, 'expectedRevision': _nativeRevision}
            : arguments;
        _receive(await _methods.invokeMethod(method, payload));
      } catch (_) {
        _failed();
      }
    });
    _pending = operation;
    return operation;
  }

  Future<void> refresh() => _call('getStatus');
  Future<void> setBlockingEnabled(bool enabled) =>
      _call('setBlockingEnabled', {'enabled': enabled});
  Future<void> publishAppearance(AppearancePreferences preferences) {
    Map<String, int> variant(Brightness brightness) {
      final colors = DaylockTheme.forPalette(
        preferences.colour,
        brightness,
      ).colorScheme;
      return {
        'background': colors.surface.toARGB32(),
        'foreground': colors.onSurface.toARGB32(),
        'muted': colors.onSurfaceVariant.toARGB32(),
        'accent': colors.primary.toARGB32(),
        'onAccent': colors.onPrimary.toARGB32(),
        'outline': colors.outline.toARGB32(),
      };
    }

    return _call('publishAppearance', {
      'mode': preferences.mode.name,
      'dark': variant(Brightness.dark),
      'light': variant(Brightness.light),
    });
  }

  Future<void> invalidateSnapshot() {
    _lastPublished = null;
    return _call('invalidateSnapshot');
  }

  Future<void> publishSnapshot(NativeFreedomInput input, {bool force = false}) {
    final previous = _lastPublished;
    final unchanged =
        previous != null &&
        previous.length == input.values.length &&
        input.values.keys.every((key) {
          final a = previous[key], b = input.values[key];
          return a is Map && b is Map ? mapEquals(a, b) : a == b;
        });
    if (!force && unchanged) {
      return Future.value();
    }
    _lastPublished = input.values;
    return _call('publishSnapshot', input.values);
  }

  Future<void> openAccessibilitySettings() async {
    await start();
    if (!_available || _closed) return;
    try {
      await _methods.invokeMethod('openAccessibilitySettings');
    } catch (_) {
      _failed();
    }
  }

  Future<void> close() async {
    _closed = true;
    await _subscription?.cancel();
    status.dispose();
  }
}

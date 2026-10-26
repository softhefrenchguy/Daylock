import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/daylock_state.dart';

class LocalStorage {
  static const stateKey = 'daylock.state.v2';
  static const legacyStateKey = 'daylock.state.v1';

  final SharedPreferencesAsync _preferences;
  final DateTime Function() _now;
  Future<void> _pendingSave = Future<void>.value();

  LocalStorage({SharedPreferencesAsync? preferences, DateTime Function()? now})
    : _preferences = preferences ?? SharedPreferencesAsync(),
      _now = now ?? DateTime.now;

  Future<DaylockState?> load() async {
    await _pendingSave;
    final json = await _preferences.getString(stateKey);
    if (json != null) {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final state = DaylockState.fromJson(decoded, migrationTime: _now());
      // Additive v2 migration: missing collections become empty. Never backfill history.
      if (!decoded.containsKey('events') ||
          !decoded.containsKey('calendarCache') ||
          !decoded.containsKey('history') ||
          !decoded.containsKey('freedomSettings') ||
          !decoded.containsKey('routines') ||
          !decoded.containsKey('notificationPreferences') ||
          !decoded.containsKey('areas') ||
          !decoded.containsKey('highlights') ||
          _needsOutcomeMigration(decoded) ||
          (decoded['events'] as List).any(
            (event) => !(event as Map).containsKey('source'),
          )) {
        await save(state);
      }
      return state;
    }

    final legacyJson = await _preferences.getString(legacyStateKey);
    if (legacyJson == null) return null;

    final migrated = DaylockState.fromLegacyJson(
      jsonDecode(legacyJson) as Map<String, dynamic>,
      today: _now(),
    );
    // Write v2 before exposing the migrated plans; retain v1 as a backup.
    await save(migrated);
    return migrated;
  }

  bool _needsOutcomeMigration(Map<String, dynamic> json) {
    final plans = [
      json['todayPlan'],
      json['tomorrowPlan'],
      ...json['history'] as List,
    ];
    return plans.any(
      (plan) => ((plan as Map)['tasks'] as List).any(
        (task) =>
            !(task as Map).containsKey('outcome') ||
            !task.containsKey('excuseReason'),
      ),
    );
  }

  Future<void> save(DaylockState state) {
    // Encode immediately so later edits cannot change a queued snapshot.
    final json = jsonEncode(state.toJson());
    final save = _pendingSave.then(
      (_) => _preferences.setString(stateKey, json),
    );
    // Report errors to the caller, while allowing the next save to retry.
    _pendingSave = save.catchError((Object _) {});
    return save;
  }

  Future<void> reset() async {
    await _pendingSave;
    // Remove the backup first so it cannot resurrect old commitments.
    await _preferences.remove(legacyStateKey);
    await _preferences.remove(stateKey);
  }
}

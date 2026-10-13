import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../design/appearance_preferences.dart';

// Separate from planner snapshots and credentials: appearance changes never
// rewrite, migrate or clear any commitment/calendar/authentication data.
class AppearanceStorage {
  static const key = 'daylock.appearance.v1';
  final SharedPreferencesAsync _preferences;
  Future<void> _pending = Future<void>.value();
  AppearanceStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  Future<AppearancePreferences> load() async {
    await _pending;
    final saved = await _preferences.getString(key);
    if (saved == null) return const AppearancePreferences();
    try {
      return AppearancePreferences.fromJson(
        jsonDecode(saved) as Map<String, dynamic>,
      );
    } on FormatException {
      return const AppearancePreferences();
    } on TypeError {
      return const AppearancePreferences();
    }
  }

  Future<void> save(AppearancePreferences preferences) {
    final encoded = jsonEncode(preferences.toJson());
    final save = _pending.then((_) => _preferences.setString(key, encoded));
    _pending = save.catchError((Object _) {});
    return save;
  }
}

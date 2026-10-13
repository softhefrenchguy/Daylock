import 'dart:async';
import 'dart:convert';

import 'package:daylock/design/appearance_preferences.dart';
import 'package:daylock/design/daylock_palette.dart';
import 'package:daylock/services/appearance_storage.dart';
import 'package:daylock/services/local_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  test('New installs default to Dark/Violet without writing or modifying planner data', () async {
    final preferences = SharedPreferencesAsync();
    await preferences.setString(
      LocalStorage.stateKey,
      'existing planner snapshot',
    );
    await preferences.setString(
      LocalStorage.legacyStateKey,
      'existing migration backup',
    );
    expect(await AppearanceStorage().load(), const AppearancePreferences());
    expect(await preferences.getString(AppearanceStorage.key), isNull);
    expect(
      await preferences.getString(LocalStorage.stateKey),
      'existing planner snapshot',
    );
    expect(
      await preferences.getString(LocalStorage.legacyStateKey),
      'existing migration backup',
    );
  });

  test('All 18 combinations round-trip independently of planner and unrelated data', () async {
    final preferences = SharedPreferencesAsync();
    await preferences.setString(LocalStorage.stateKey, '{existing planner}');
    await preferences.setString('unrelated.setting', 'keep');
    for (final mode in AppearanceMode.values) {
      for (final colour in ColourTheme.values) {
        final appearance = AppearancePreferences(mode: mode, colour: colour);
        await AppearanceStorage().save(appearance);
        expect(await AppearanceStorage().load(), appearance);
        expect(
          jsonDecode((await preferences.getString(AppearanceStorage.key))!),
          appearance.toJson(),
        );
      }
    }
    expect(
      await preferences.getString(LocalStorage.stateKey),
      '{existing planner}',
    );
    expect(await preferences.getString('unrelated.setting'), 'keep');
  });

  test('Malformed and unknown settings fall back safely without replacing their saved value', () async {
    final preferences = SharedPreferencesAsync();
    for (final raw in [
      '{',
      'null',
      '[]',
      '{}',
      '{"mode":"unexpected","colour":"unexpected"}',
    ]) {
      await preferences.setString(AppearanceStorage.key, raw);
      expect(await AppearanceStorage().load(), const AppearancePreferences());
      expect(await preferences.getString(AppearanceStorage.key), raw);
    }
    expect(
      AppearancePreferences.fromJson({'mode': 'system', 'colour': 'unknown'})
          .mode,
      AppearanceMode.system,
    );
    expect(
      AppearancePreferences.fromJson({'mode': 'unknown', 'colour': 'ocean'})
          .colour,
      ColourTheme.ocean,
    );
  });

  test(
    'Rapid choices save in order and load waits for the last queued write',
    () async {
      final platform = _DelayedPreferences();
      SharedPreferencesAsyncPlatform.instance = platform;
      final storage = AppearanceStorage();
      const first = AppearancePreferences(
        mode: AppearanceMode.light,
        colour: ColourTheme.forest,
      );
      const last = AppearancePreferences(
        mode: AppearanceMode.system,
        colour: ColourTheme.ember,
      );
      final a = storage.save(first);
      final b = storage.save(last);
      final restored = storage.load();
      await Future<void>.delayed(Duration.zero);
      expect(platform.gates, hasLength(1));
      platform.gates.first.complete();
      await a;
      await Future<void>.delayed(Duration.zero);
      expect(platform.gates, hasLength(2));
      platform.gates.last.complete();
      await b;
      expect(await restored, last);
    },
  );

  test(
    'A failed write reports failure and does not block the next choice',
    () async {
      SharedPreferencesAsyncPlatform.instance = _FailOncePreferences();
      final storage = AppearanceStorage();
      await expectLater(
        storage.save(const AppearancePreferences(colour: ColourTheme.ocean)),
        throwsStateError,
      );
      const latest = AppearancePreferences(colour: ColourTheme.rose);
      await storage.save(latest);
      expect(await storage.load(), latest);
    },
  );
}

final class _DelayedPreferences extends InMemorySharedPreferencesAsync {
  _DelayedPreferences() : super.empty();
  final gates = <Completer<void>>[];
  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) async {
    final gate = Completer<void>();
    gates.add(gate);
    await gate.future;
    return super.setString(key, value, options);
  }
}

final class _FailOncePreferences extends InMemorySharedPreferencesAsync {
  _FailOncePreferences() : super.empty();
  bool fail = true;
  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) async {
    if (fail) {
      fail = false;
      throw StateError('Unavailable');
    }
    return super.setString(key, value, options);
  }
}

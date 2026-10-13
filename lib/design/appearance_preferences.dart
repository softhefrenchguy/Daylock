import 'package:flutter/material.dart';

import 'daylock_palette.dart';

enum AppearanceMode {
  dark('Dark', ThemeMode.dark),
  light('Light', ThemeMode.light),
  system('System', ThemeMode.system);

  final String label;
  final ThemeMode themeMode;
  const AppearanceMode(this.label, this.themeMode);
}

@immutable
class AppearancePreferences {
  final AppearanceMode mode;
  final ColourTheme colour;
  const AppearancePreferences({
    this.mode = AppearanceMode.dark,
    this.colour = ColourTheme.violet,
  });

  AppearancePreferences copyWith({AppearanceMode? mode, ColourTheme? colour}) =>
      AppearancePreferences(
        mode: mode ?? this.mode,
        colour: colour ?? this.colour,
      );

  Map<String, String> toJson() => {'mode': mode.name, 'colour': colour.name};
  factory AppearancePreferences.fromJson(Map<String, dynamic> json) =>
      AppearancePreferences(
        mode:
            AppearanceMode.values
                .where((mode) => mode.name == json['mode'])
                .firstOrNull ??
            AppearanceMode.dark,
        colour:
            ColourTheme.values
                .where((colour) => colour.name == json['colour'])
                .firstOrNull ??
            ColourTheme.violet,
      );

  @override
  bool operator ==(Object other) =>
      other is AppearancePreferences &&
      other.mode == mode &&
      other.colour == colour;
  @override
  int get hashCode => Object.hash(mode, colour);
}

import 'package:flutter/material.dart';

enum ColourTheme {
  violet('Violet'),
  ocean('Ocean'),
  forest('Forest'),
  ember('Ember'),
  rose('Rose'),
  mono('Mono');

  final String label;
  const ColourTheme(this.label);
}

// ColorScheme provides standard Material semantics; this extension contains the
// extra Focus and Freedom roles. Widgets never need to know the chosen palette.
@immutable
class DaylockColors extends ThemeExtension<DaylockColors> {
  final Color focusSurface;
  final Color focusActiveSurface;
  final Color statusSurface;
  final Color completedSurface;
  final Color statusOutline;
  final Color statusAccent;
  final Color onStatus;
  final Color onStatusMuted;
  const DaylockColors({
    required this.focusSurface,
    required this.focusActiveSurface,
    required this.statusSurface,
    required this.completedSurface,
    required this.statusOutline,
    required this.statusAccent,
    required this.onStatus,
    required this.onStatusMuted,
  });

  static DaylockColors of(BuildContext context) =>
      Theme.of(context).extension<DaylockColors>() ??
      DaylockPalettes.colors(ColourTheme.violet, Theme.of(context).brightness);

  @override
  DaylockColors copyWith({
    Color? focusSurface,
    Color? focusActiveSurface,
    Color? statusSurface,
    Color? completedSurface,
    Color? statusOutline,
    Color? statusAccent,
    Color? onStatus,
    Color? onStatusMuted,
  }) => DaylockColors(
    focusSurface: focusSurface ?? this.focusSurface,
    focusActiveSurface: focusActiveSurface ?? this.focusActiveSurface,
    statusSurface: statusSurface ?? this.statusSurface,
    completedSurface: completedSurface ?? this.completedSurface,
    statusOutline: statusOutline ?? this.statusOutline,
    statusAccent: statusAccent ?? this.statusAccent,
    onStatus: onStatus ?? this.onStatus,
    onStatusMuted: onStatusMuted ?? this.onStatusMuted,
  );
  @override
  DaylockColors lerp(covariant DaylockColors? other, double t) => other == null
      ? this
      : DaylockColors(
          focusSurface: Color.lerp(focusSurface, other.focusSurface, t)!,
          focusActiveSurface: Color.lerp(
            focusActiveSurface,
            other.focusActiveSurface,
            t,
          )!,
          statusSurface: Color.lerp(statusSurface, other.statusSurface, t)!,
          completedSurface: Color.lerp(
            completedSurface,
            other.completedSurface,
            t,
          )!,
          statusOutline: Color.lerp(statusOutline, other.statusOutline, t)!,
          statusAccent: Color.lerp(statusAccent, other.statusAccent, t)!,
          onStatus: Color.lerp(onStatus, other.onStatus, t)!,
          onStatusMuted: Color.lerp(onStatusMuted, other.onStatusMuted, t)!,
        );
}

class _Tone {
  final int background, surface, ink, muted, accent, onAccent, border, outline;
  const _Tone({
    required this.background,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.onAccent,
    required this.border,
    required this.outline,
  });
}

class _Palette {
  final _Tone dark, light;
  final int status, completed, statusOutline, statusMuted;
  const _Palette({
    required this.dark,
    required this.light,
    required this.status,
    required this.completed,
    required this.statusOutline,
    required this.statusMuted,
  });
}

abstract final class DaylockPalettes {
  static const _palettes = <ColourTheme, _Palette>{
    ColourTheme.violet: _Palette(
      dark: _Tone(
        background: 0xFF171321,
        surface: 0xFF211A2E,
        ink: 0xFFF8F6FC,
        muted: 0xFFBEB5CF,
        accent: 0xFFA78BDB,
        onAccent: 0xFF171321,
        border: 0xFF3C324D,
        outline: 0xFF8C819E,
      ),
      light: _Tone(
        background: 0xFFF8F6FC,
        surface: 0xFFF0EBF6,
        ink: 0xFF171321,
        muted: 0xFF62586F,
        accent: 0xFF7054A4,
        onAccent: 0xFFFFFFFF,
        border: 0xFFDED7E8,
        outline: 0xFF807389,
      ),
      status: 0xFF211A2E,
      completed: 0xFF302245,
      statusOutline: 0xFF4B3A63,
      statusMuted: 0xFFD6CDE3,
    ),
    ColourTheme.ocean: _Palette(
      dark: _Tone(
        background: 0xFF111923,
        surface: 0xFF1A2634,
        ink: 0xFFF3F8FE,
        muted: 0xFFAFBED0,
        accent: 0xFF82B6EC,
        onAccent: 0xFF111923,
        border: 0xFF304356,
        outline: 0xFF7D94AE,
      ),
      light: _Tone(
        background: 0xFFF4F8FD,
        surface: 0xFFE8F0F9,
        ink: 0xFF152336,
        muted: 0xFF52657C,
        accent: 0xFF27649C,
        onAccent: 0xFFFFFFFF,
        border: 0xFFD2DFEE,
        outline: 0xFF6D8198,
      ),
      status: 0xFF172638,
      completed: 0xFF213950,
      statusOutline: 0xFF375575,
      statusMuted: 0xFFC8DBEF,
    ),
    ColourTheme.forest: _Palette(
      dark: _Tone(
        background: 0xFF121C17,
        surface: 0xFF1C2B23,
        ink: 0xFFF3FAF5,
        muted: 0xFFB0C4B7,
        accent: 0xFF8CCBA6,
        onAccent: 0xFF121C17,
        border: 0xFF314B3B,
        outline: 0xFF809C8A,
      ),
      light: _Tone(
        background: 0xFFF5F9F5,
        surface: 0xFFE9F1E9,
        ink: 0xFF182A1F,
        muted: 0xFF53685B,
        accent: 0xFF2E704A,
        onAccent: 0xFFFFFFFF,
        border: 0xFFD3E1D5,
        outline: 0xFF708777,
      ),
      status: 0xFF1A2C22,
      completed: 0xFF253F30,
      statusOutline: 0xFF3C6149,
      statusMuted: 0xFFCDE4D4,
    ),
    ColourTheme.ember: _Palette(
      dark: _Tone(
        background: 0xFF211712,
        surface: 0xFF30221B,
        ink: 0xFFFFF7F0,
        muted: 0xFFD0B7A6,
        accent: 0xFFEBA776,
        onAccent: 0xFF211712,
        border: 0xFF51382B,
        outline: 0xFFA58A77,
      ),
      light: _Tone(
        background: 0xFFFCF7F2,
        surface: 0xFFF6ECE2,
        ink: 0xFF302118,
        muted: 0xFF755C49,
        accent: 0xFF985025,
        onAccent: 0xFFFFFFFF,
        border: 0xFFE9D9C9,
        outline: 0xFF967961,
      ),
      status: 0xFF302019,
      completed: 0xFF493022,
      statusOutline: 0xFF704831,
      statusMuted: 0xFFF0D8C5,
    ),
    ColourTheme.rose: _Palette(
      dark: _Tone(
        background: 0xFF21151D,
        surface: 0xFF301E2A,
        ink: 0xFFFFF4FA,
        muted: 0xFFCEB2C4,
        accent: 0xFFE7A0C2,
        onAccent: 0xFF21151D,
        border: 0xFF4D3042,
        outline: 0xFFA18397,
      ),
      light: _Tone(
        background: 0xFFFCF5F9,
        surface: 0xFFF6EAF1,
        ink: 0xFF321E2A,
        muted: 0xFF76576B,
        accent: 0xFFA13C70,
        onAccent: 0xFFFFFFFF,
        border: 0xFFE8D4E0,
        outline: 0xFF95778B,
      ),
      status: 0xFF301C29,
      completed: 0xFF472738,
      statusOutline: 0xFF693B55,
      statusMuted: 0xFFF0D1E3,
    ),
    ColourTheme.mono: _Palette(
      dark: _Tone(
        background: 0xFF171717,
        surface: 0xFF242424,
        ink: 0xFFF5F5F5,
        muted: 0xFFBBBBBB,
        accent: 0xFFCCCCCC,
        onAccent: 0xFF171717,
        border: 0xFF3C3C3C,
        outline: 0xFF929292,
      ),
      light: _Tone(
        background: 0xFFF8F8F8,
        surface: 0xFFEDEDED,
        ink: 0xFF202020,
        muted: 0xFF626262,
        accent: 0xFF505050,
        onAccent: 0xFFFFFFFF,
        border: 0xFFDCDCDC,
        outline: 0xFF808080,
      ),
      status: 0xFF242424,
      completed: 0xFF333333,
      statusOutline: 0xFF555555,
      statusMuted: 0xFFD5D5D5,
    ),
  };

  static ColorScheme scheme(ColourTheme colour, Brightness brightness) {
    final palette = _palettes[colour]!;
    final tone = brightness == Brightness.dark ? palette.dark : palette.light;
    final seed = Color(palette.light.accent);
    final surface = Color(tone.surface);
    final accent = Color(tone.accent);
    final ink = Color(tone.ink);
    final muted = Color(tone.muted);
    final background = Color(tone.background);
    final error = brightness == Brightness.dark
        ? const Color(0xFFFFB4AB)
        : const Color(0xFFBA1A1A);
    return ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    ).copyWith(
      primary: accent,
      onPrimary: Color(tone.onAccent),
      primaryContainer: surface,
      onPrimaryContainer: ink,
      secondary: accent,
      onSecondary: Color(tone.onAccent),
      secondaryContainer: surface,
      onSecondaryContainer: ink,
      tertiary: accent,
      onTertiary: Color(tone.onAccent),
      tertiaryContainer: surface,
      onTertiaryContainer: ink,
      surface: background,
      onSurface: ink,
      onSurfaceVariant: muted,
      surfaceDim: surface,
      surfaceBright: surface,
      surfaceContainerLowest: background,
      surfaceContainerLow: surface,
      surfaceContainer: surface,
      surfaceContainerHigh: Color.alphaBlend(
        ink.withValues(alpha: 0.03),
        surface,
      ),
      surfaceContainerHighest: Color.alphaBlend(
        ink.withValues(alpha: 0.06),
        surface,
      ),
      outline: Color(tone.outline),
      outlineVariant: Color(tone.border),
      surfaceTint: accent,
      primaryFixed: surface,
      onPrimaryFixed: ink,
      primaryFixedDim: Color(tone.border),
      onPrimaryFixedVariant: muted,
      secondaryFixed: surface,
      onSecondaryFixed: ink,
      secondaryFixedDim: Color(tone.border),
      onSecondaryFixedVariant: muted,
      tertiaryFixed: surface,
      onTertiaryFixed: ink,
      tertiaryFixedDim: Color(tone.border),
      onTertiaryFixedVariant: muted,
      inverseSurface: ink,
      onInverseSurface: background,
      inversePrimary: Color(
        (brightness == Brightness.dark ? palette.light : palette.dark).accent,
      ),
      error: colour == ColourTheme.mono ? accent : error,
      onError: colour == ColourTheme.mono
          ? Color(tone.onAccent)
          : brightness == Brightness.dark
          ? const Color(0xFF690005)
          : Colors.white,
      errorContainer: colour == ColourTheme.mono
          ? surface
          : brightness == Brightness.dark
          ? const Color(0xFF93000A)
          : const Color(0xFFFFDAD6),
      onErrorContainer: colour == ColourTheme.mono
          ? ink
          : brightness == Brightness.dark
          ? const Color(0xFFFFDAD6)
          : const Color(0xFF410002),
      shadow: Colors.black,
      scrim: Colors.black,
    );
  }

  static DaylockColors colors(ColourTheme colour, Brightness brightness) {
    final palette = _palettes[colour]!;
    final scheme = DaylockPalettes.scheme(colour, brightness);
    return DaylockColors(
      focusSurface: Color.alphaBlend(
        scheme.primary.withValues(alpha: 0.05),
        scheme.surface,
      ),
      focusActiveSurface: Color.alphaBlend(
        scheme.primary.withValues(alpha: 0.12),
        scheme.surface,
      ),
      statusSurface: Color(palette.status),
      completedSurface: Color(palette.completed),
      statusOutline: Color(palette.statusOutline),
      statusAccent: Color(palette.dark.accent),
      onStatus: Color(palette.dark.ink),
      onStatusMuted: Color(palette.statusMuted),
    );
  }
}

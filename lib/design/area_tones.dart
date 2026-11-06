import 'package:flutter/material.dart';

/// WCAG contrast ratio between two opaque colours.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Tones derived from a user-chosen Area colour.
///
/// Areas are user-defined (any name, any colour), so nothing here assumes a
/// particular hue. [ink] is adjusted until it reaches 4.5:1 against [surface],
/// which keeps labels, rings and checks readable for every possible choice.
@immutable
class AreaTones {
  /// Readable foreground: labels, checkbox rings, the filled "kept" check.
  final Color ink;

  /// Quiet background for badges and tiles.
  final Color tint;

  /// Foreground drawn on top of [ink] (the tick inside a kept check).
  final Color onInk;

  const AreaTones._(this.ink, this.tint, this.onInk);

  factory AreaTones.of(
    Color base, {
    required Brightness brightness,
    required Color surface,
  }) {
    final dark = brightness == Brightness.dark;
    var hsl = HSLColor.fromColor(base.withValues(alpha: 1));
    // Muted swatches look dull on a dark sky, so lift their saturation a little.
    if (dark && hsl.saturation > 0.08 && hsl.saturation < 0.55) {
      hsl = hsl.withSaturation(0.55);
    }
    var lightness = dark
        ? (hsl.lightness < 0.72 ? 0.72 : hsl.lightness)
        : (hsl.lightness > 0.42 ? 0.42 : hsl.lightness);
    var ink = hsl.withLightness(lightness).toColor();
    var guard = 0;
    while (contrastRatio(ink, surface) < 4.5 && guard++ < 40) {
      lightness = (lightness + (dark ? 0.02 : -0.02)).clamp(0.0, 1.0);
      ink = hsl.withLightness(lightness).toColor();
      if (lightness == 0 || lightness == 1) break;
    }
    final tint = Color.alphaBlend(
      base.withValues(alpha: dark ? 0.30 : 0.14),
      surface,
    );
    final onInk =
        contrastRatio(ink, const Color(0xFF140F2A)) >=
            contrastRatio(ink, Colors.white)
        ? const Color(0xFF140F2A)
        : Colors.white;
    return AreaTones._(ink, tint, onInk);
  }

  static AreaTones forContext(BuildContext context, Color base) {
    final theme = Theme.of(context);
    return AreaTones.of(
      base,
      brightness: theme.brightness,
      surface: theme.colorScheme.surfaceContainerLow,
    );
  }
}

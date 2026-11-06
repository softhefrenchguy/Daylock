import 'package:flutter/material.dart';

import 'daylock_palette.dart';

abstract final class DaylockSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double radius = 16;
  static const double icon = 20;

  /// Rounded display face that echoes the Daylock wordmark (bundled, offline).
  static const String displayFont = 'Nunito';

  /// Grouped lists and cards.
  static const double cardRadius = 18;
}

abstract final class DaylockTheme {
  static final _themes = <(ColourTheme, Brightness), ThemeData>{};
  static ThemeData get light =>
      forPalette(ColourTheme.violet, Brightness.light);
  static ThemeData get dark => forPalette(ColourTheme.violet, Brightness.dark);
  static ThemeData forPalette(ColourTheme colour, Brightness brightness) =>
      _themes.putIfAbsent((
        colour,
        brightness,
      ), () => _build(colour, brightness));

  // Compatibility aliases for the original Violet design. Components use
  // ColorScheme and DaylockColors instead of these fixed-palette aliases.
  static Color get violet => light.colorScheme.primary;
  static Color get highlight => dark.colorScheme.primary;
  static Color get darkBackground => dark.colorScheme.surface;
  static Color get lightBackground => light.colorScheme.surface;
  static Color get statusSurface =>
      dark.extension<DaylockColors>()!.statusSurface;
  static Color get completedSurface =>
      dark.extension<DaylockColors>()!.completedSurface;
  static Color get statusOutline =>
      dark.extension<DaylockColors>()!.statusOutline;
  static Color get onStatusMuted =>
      dark.extension<DaylockColors>()!.onStatusMuted;

  static ThemeData _build(ColourTheme colour, Brightness brightness) {
    final scheme = DaylockPalettes.scheme(colour, brightness);
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final text = base.textTheme
        .apply(
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
          fontFamily: 'Roboto',
        )
        .copyWith(
          displayLarge: TextStyle(
            fontFamily: DaylockSpace.displayFont,
            fontSize: 60,
            height: 1.0,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.8,
            color: scheme.onSurface,
          ),
          headlineLarge: TextStyle(
            fontFamily: DaylockSpace.displayFont,
            fontSize: 34,
            height: 1.1,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.7,
            color: scheme.onSurface,
          ),
          headlineMedium: TextStyle(
            fontFamily: DaylockSpace.displayFont,
            fontSize: 26,
            height: 1.15,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
            color: scheme.onSurface,
          ),
          titleLarge: TextStyle(
            fontFamily: DaylockSpace.displayFont,
            fontSize: 20,
            height: 1.3,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.1,
            color: scheme.onSurface,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            height: 1.5,
            color: scheme.onSurface,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: scheme.onSurface,
          ),
          labelLarge: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: scheme.onSurface,
          ),
          labelSmall: TextStyle(
            fontSize: 11,
            height: 1.4,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: scheme.onSurfaceVariant,
          ),
        );
    return base.copyWith(
      extensions: [DaylockPalettes.colors(colour, brightness)],
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: text.headlineLarge!.copyWith(fontSize: 28),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 54),
          padding: const EdgeInsets.symmetric(
            horizontal: DaylockSpace.lg,
            vertical: DaylockSpace.md,
          ),
          textStyle: text.labelLarge!.copyWith(fontSize: 16),
          elevation: 0,
          shape: const StadiumBorder(),
        ),
      ),
      // Standard bottom-edge messages: a floating one can sit over content and
      // catch taps meant for the commitment underneath it.
      snackBarTheme: SnackBarThemeData(
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xFFF1E9FF)
            : const Color(0xFF241A42),
        contentTextStyle: text.bodyMedium!.copyWith(
          fontSize: 15,
          color: brightness == Brightness.dark
              ? const Color(0xFF1D1036)
              : const Color(0xFFF5F1FF),
        ),
        actionTextColor: brightness == Brightness.dark
            ? const Color(0xFF5B2FB0)
            : const Color(0xFFD9BFFF),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: scheme.outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: text.headlineMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color.alphaBlend(
          scheme.onSurface.withValues(alpha: .04),
          scheme.surfaceContainerLow,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DaylockSpace.radius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: text.labelLarge,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: const CircleBorder(),
        side: BorderSide(color: scheme.outline, width: 2),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.outlineVariant,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        indicatorColor: scheme.primary.withValues(alpha: 0.13),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelSmall!.copyWith(
            letterSpacing: 0,
            fontSize: 12,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

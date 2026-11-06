import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The warm "kept" colour used for the sun and fully kept days.
///
/// It belongs to the theme, never to an Area, so it cannot clash with the
/// colours people choose for their Areas.
Color daylockGold(Brightness brightness) => brightness == Brightness.dark
    ? const Color(0xFFFFC27A)
    : const Color(0xFFE38A2B);

/// What the landscape shows.
enum SceneMood {
  /// The sun climbs with [DaylockScene.progress]: 0 is below the hills.
  dawn,

  /// Night before: stars and a moon, the sun waiting below the hills.
  night,

  /// Freedom earned: the sun is fully up and the sky turns gold.
  earned,

  /// Journey: a warm sunset looking back over the days.
  dusk,
}

/// A layered-hills landscape behind the top of a screen.
///
/// Colours derive from the active palette, so every colour theme keeps its own
/// character. The scene is decorative and hidden from screen readers.
class DaylockScene extends StatelessWidget {
  final SceneMood mood;
  final double progress;
  final double height;
  final Widget? child;

  /// Colour of the nearest hill, so the scene melts into what sits below it.
  /// Defaults to the page background.
  final Color? ground;

  const DaylockScene({
    super.key,
    required this.mood,
    this.progress = 0,
    required this.height,
    this.child,
    this.ground,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final palette = SceneColors.of(theme);
    final overlay = palette.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(statusBarColor: Colors.transparent),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ExcludeSemantics(
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: progress.clamp(0, 1).toDouble()),
                duration: reduce
                    ? Duration.zero
                    : const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => CustomPaint(
                  painter: _ScenePainter(
                    mood: mood,
                    progress: value,
                    colors: palette,
                    ground: ground ?? palette.background,
                  ),
                ),
              ),
            ),
            ?child,
          ],
        ),
      ),
    );
  }
}

/// Palette-derived scene colours, also used for text placed over the sky.
@immutable
class SceneColors {
  final Brightness brightness;
  final Color background, accent, onSky, onSkyMuted;
  const SceneColors._(
    this.brightness,
    this.background,
    this.accent,
    this.onSky,
    this.onSkyMuted,
  );

  factory SceneColors.of(ThemeData theme) {
    final dark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;
    return SceneColors._(
      theme.brightness,
      scheme.surface,
      scheme.primary,
      dark ? const Color(0xFFF7F3FF) : scheme.onSurface,
      dark ? const Color(0xFFDCD3F2) : scheme.onSurfaceVariant,
    );
  }

  bool get dark => brightness == Brightness.dark;

  HSLColor get _hue => HSLColor.fromColor(accent);

  Color _tone(double lightness, {double saturation = 0.55, double shift = 0}) {
    final hue = (_hue.hue + shift) % 360;
    final sat = _hue.saturation < 0.08 ? 0.0 : saturation;
    return HSLColor.fromAHSL(1, hue, sat, lightness).toColor();
  }

  List<Color> sky(SceneMood mood) {
    if (dark) {
      return switch (mood) {
        SceneMood.night => [
          Color.lerp(background, Colors.black, .25)!,
          _tone(.17, saturation: .5),
        ],
        SceneMood.dawn => [background, _tone(.22), _tone(.33, shift: 10)],
        SceneMood.earned => [
          _tone(.22),
          _tone(.36, saturation: .5, shift: 20),
          const Color(0xFFE2708A),
          const Color(0xFFFFB877),
        ],
        SceneMood.dusk => [
          _tone(.15),
          _tone(.28, shift: 6),
          _tone(.42, saturation: .45, shift: 24),
          const Color(0xFFD9708E),
        ],
      };
    }
    return switch (mood) {
      SceneMood.night => [
        _tone(.86, saturation: .45),
        _tone(.92, saturation: .5),
      ],
      SceneMood.dawn => [
        _tone(.95, saturation: .7),
        _tone(.92, saturation: .55, shift: 30),
        const Color(0xFFFFDCC8),
      ],
      SceneMood.earned || SceneMood.dusk => [
        _tone(.93, saturation: .6),
        const Color(0xFFFFD6E4),
        const Color(0xFFFFCFA0),
      ],
    };
  }

  Color get hillFar =>
      dark ? _tone(.40, saturation: .5) : _tone(.84, saturation: .55);
  Color get hillMid =>
      dark ? _tone(.27, saturation: .55) : _tone(.74, saturation: .5);
  Color get glow => dark ? const Color(0xFFFF8FD2) : const Color(0xFFFFC8A0);
}

class _ScenePainter extends CustomPainter {
  final SceneMood mood;
  final double progress;
  final SceneColors colors;
  final Color ground;
  _ScenePainter({
    required this.mood,
    required this.progress,
    required this.colors,
    required this.ground,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;
    final sky = colors.sky(mood);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: sky,
        ).createShader(rect),
    );

    final sunX = w * (mood == SceneMood.dusk ? 0.83 : 0.77);
    final horizon = h - 80;
    final sunRadius = mood == SceneMood.earned ? 48.0 : 34.0;
    final double sunY = switch (mood) {
      SceneMood.dawn => horizon + 46 - (horizon + 46 - h * 0.40) * progress,
      SceneMood.night => horizon + 60,
      SceneMood.earned => h * 0.38,
      SceneMood.dusk => h * 0.66,
    };
    final warm = mood == SceneMood.earned || mood == SceneMood.dusk;

    // Glow behind the sun; strongest when the day is kept.
    final glowStrength = switch (mood) {
      SceneMood.night => colors.dark ? .25 : .35,
      SceneMood.dawn => .35 + .35 * progress,
      _ => .85,
    };
    final glowCenter = Offset(sunX, math.min(sunY, horizon + 10));
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(
            glowCenter.dx / w * 2 - 1,
            glowCenter.dy / h * 2 - 1,
          ),
          radius: 0.9,
          colors: [
            (warm ? const Color(0xFFFFE0A0) : colors.glow).withValues(
              alpha: glowStrength,
            ),
            (warm ? const Color(0xFFFFC27A) : colors.accent).withValues(
              alpha: glowStrength * .3,
            ),
            Colors.transparent,
          ],
          stops: const [0, .45, 1],
        ).createShader(rect),
    );

    if (colors.dark && (mood == SceneMood.night || mood == SceneMood.dawn)) {
      final star = Paint()..color = Colors.white;
      const stars = [
        [.10, .16, 1.2, .55],
        [.49, .10, 1.0, .45],
        [.64, .27, 1.3, .40],
        [.31, .37, 1.0, .35],
        [.86, .15, 1.2, .40],
        [.20, .55, 1.0, .30],
        [.57, .45, .9, .35],
      ];
      final fade = mood == SceneMood.night ? 1.0 : 1 - progress;
      for (final s in stars) {
        star.color = Colors.white.withValues(alpha: s[3] * fade);
        canvas.drawCircle(Offset(w * s[0], h * s[1]), s[2], star);
      }
    }

    if (mood == SceneMood.night) {
      final moon = Offset(w * 0.82, h * 0.2);
      final layer = Rect.fromCircle(center: moon, radius: 30);
      canvas.saveLayer(layer, Paint());
      canvas.drawCircle(
        moon,
        21,
        Paint()
          ..color = colors.dark
              ? const Color(0xFFF2E6FF)
              : const Color(0xFFFFFFFF),
      );
      canvas.drawCircle(
        moon + const Offset(9, -7),
        18,
        Paint()..blendMode = BlendMode.clear,
      );
      canvas.restore();
    } else {
      if (warm) {
        final rays = Paint()
          ..color = const Color(0xFFFFF0CF).withValues(alpha: .8)
          ..strokeWidth = mood == SceneMood.earned ? 5 : 4
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 7; i++) {
          final angle = math.pi + i * math.pi / 6;
          final inner = sunRadius + 14;
          final outer = sunRadius + 28;
          canvas.drawLine(
            Offset(
              sunX + math.cos(angle) * inner,
              sunY + math.sin(angle) * inner,
            ),
            Offset(
              sunX + math.cos(angle) * outer,
              sunY + math.sin(angle) * outer,
            ),
            rays,
          );
        }
      }
      final sunRect = Rect.fromCircle(
        center: Offset(sunX, sunY),
        radius: sunRadius,
      );
      canvas.drawCircle(
        Offset(sunX, sunY),
        sunRadius,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-.15, -.25),
            colors: warm
                ? const [
                    Color(0xFFFFFFFF),
                    Color(0xFFFFF0CF),
                    Color(0xFFFFC27A),
                  ]
                : colors.dark
                ? const [
                    Color(0xFFFFFAF3),
                    Color(0xFFFFD2EA),
                    Color(0xFFEC8FFF),
                  ]
                : const [
                    Color(0xFFFFFFFF),
                    Color(0xFFFFE6C6),
                    Color(0xFFFFB37A),
                  ],
            stops: const [0, .55, 1],
          ).createShader(sunRect),
      );
    }

    Path hill(List<double> d) {
      final sx = w / 390;
      return Path()
        ..moveTo(0, h - d[0])
        ..cubicTo(d[1] * sx, h - d[2], d[3] * sx, h - d[4], d[5] * sx, h - d[6])
        ..cubicTo(d[7] * sx, h - d[8], d[9] * sx, h - d[10], w, h - d[11])
        ..lineTo(w, h + 2) // past the edge: no seam at fractional pixel ratios
        ..lineTo(0, h + 2)
        ..close();
    }

    canvas.drawPath(
      hill([66, 70, 94, 140, 92, 205, 72, 262, 55, 322, 86, 96]),
      Paint()
        ..color = warm && !colors.dark
            ? const Color(0xFFE3C3F0)
            : colors.hillFar,
    );
    canvas.drawPath(
      hill([42, 80, 66, 150, 54, 232, 40, 300, 28, 352, 56, 60]),
      Paint()..color = colors.hillMid,
    );
    canvas.drawPath(
      hill([18, 90, 34, 190, 12, 270, 20, 330, 26, 366, 32, 30]),
      Paint()..color = ground,
    );
  }

  @override
  bool shouldRepaint(_ScenePainter old) =>
      old.mood != mood ||
      old.progress != progress ||
      old.colors.accent != colors.accent ||
      old.colors.background != colors.background ||
      old.ground != ground ||
      old.colors.brightness != colors.brightness;
}

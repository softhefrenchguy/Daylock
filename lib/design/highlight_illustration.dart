import 'package:flutter/material.dart';

const highlightIllustrationIcons = <String, IconData>{
  'celebration': Icons.auto_awesome,
  'driving': Icons.directions_car_rounded,
  'award': Icons.workspace_premium_rounded,
  'cooking': Icons.soup_kitchen_rounded,
  'travel': Icons.flight_rounded,
  'fitness': Icons.fitness_center_rounded,
  'learning': Icons.menu_book_rounded,
  'health': Icons.favorite_rounded,
  'work': Icons.work_outline_rounded,
  'home': Icons.home_rounded,
  'people': Icons.people_alt_rounded,
  'creative': Icons.palette_rounded,
  'life': Icons.wb_sunny_rounded,
};

/// A small local illustration: glow, orbit, layered keepsake, emblem and stars.
/// Entirely decorative; the adjacent Highlight text provides the semantics.
class HighlightIllustration extends StatelessWidget {
  final String iconId;
  final Color accent;
  const HighlightIllustration({
    super.key,
    required this.iconId,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pale = Color.lerp(accent, colors.surface, .28)!;
    final foreground =
        ThemeData.estimateBrightnessForColor(pale) == Brightness.dark
        ? Colors.white
        : const Color(0xff211b32);
    final artwork = AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) => FittedBox(
          child: SizedBox(
            width: 136,
            height: 136,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accent.withValues(alpha: .32),
                        accent.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: -.35,
                  child: Container(
                    width: 105,
                    height: 105,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: accent.withValues(alpha: .20)),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(8, 7),
                  child: Transform.rotate(
                    angle: .12,
                    child: Container(
                      width: 88,
                      height: 65,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: accent.withValues(alpha: .22),
                      ),
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: -.17,
                  child: Container(
                    width: 90,
                    height: 66,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color.lerp(pale, Colors.white, .26)!, pale],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: .25),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          highlightIllustrationIcons[iconId] ??
                              Icons.auto_awesome,
                          key: ValueKey('illustration-emblem-$iconId'),
                          color: foreground,
                          size: 31,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (final width in [1.0, .8, .6]) ...[
                                FractionallySizedBox(
                                  widthFactor: width,
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      color: foreground.withValues(alpha: .32),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 7,
                  top: 29,
                  child: Icon(Icons.auto_awesome, size: 22, color: accent),
                ),
                Positioned(
                  right: 12,
                  bottom: 16,
                  child: Icon(
                    Icons.auto_awesome,
                    size: 17,
                    color: colors.primary,
                  ),
                ),
                Positioned(
                  right: 17,
                  top: 15,
                  child: Icon(Icons.star_rounded, size: 9, color: accent),
                ),
                Positioned(
                  left: 19,
                  bottom: 25,
                  child: Icon(Icons.circle, size: 4, color: accent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final reduced = MediaQuery.disableAnimationsOf(context);
    return ExcludeSemantics(
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          key: ValueKey('illustration-motion-$iconId-$reduced'),
          tween: Tween(begin: reduced ? 1 : .94, end: 1),
          duration: reduced ? Duration.zero : const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) =>
              Transform.scale(scale: value, child: child),
          child: artwork,
        ),
      ),
    );
  }
}

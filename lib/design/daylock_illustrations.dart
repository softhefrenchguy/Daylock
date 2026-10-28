import 'package:flutter/material.dart';

/// Local vector artwork: no network assets, timers, or semantic controls.
class DaylockIllustration extends StatelessWidget {
  final bool planner;
  final IconData lockIcon;
  final Color accent;
  const DaylockIllustration({
    super.key,
    required this.accent,
    this.planner = false,
    this.lockIcon = Icons.lock_outline_rounded,
  });

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AspectRatio(
      aspectRatio: 1,
      child: FittedBox(
        child: SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 154,
                height: 154,
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
                angle: -.5,
                child: Container(
                  width: 124,
                  height: 94,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    color: accent.withValues(alpha: .08),
                    border: Border.all(color: accent.withValues(alpha: .35)),
                  ),
                ),
              ),
              Transform.rotate(
                angle: planner ? -.18 : .18,
                child: Container(
                  width: planner ? 88 : 78,
                  height: planner ? 94 : 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(planner ? 12 : 20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(accent, Colors.white, .25)!,
                        accent,
                        Color.lerp(accent, const Color(0xff381363), .55)!,
                      ],
                    ),
                    border: Border.all(
                      color: accent.withValues(alpha: .8),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: .3),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: planner
                      ? Stack(
                          children: [
                            Positioned(
                              top: 22,
                              bottom: 4,
                              left: 4,
                              right: 4,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: const Color(0xff28123d),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                            for (final left in [18.0, 66.0])
                              Positioned(
                                top: -1,
                                left: left,
                                child: Container(
                                  width: 6,
                                  height: 17,
                                  decoration: BoxDecoration(
                                    color: Color.lerp(
                                      accent,
                                      Colors.white,
                                      .45,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            for (final top in [43.0, 59.0])
                              Positioned(
                                top: top,
                                left: 23,
                                child: Container(
                                  width: top == 43 ? 30 : 23,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: accent,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Icon(lockIcon, size: 43, color: Colors.white),
                ),
              ),
              if (planner)
                Positioned(
                  right: 15,
                  bottom: 23,
                  child: Transform.rotate(
                    angle: -.1,
                    child: Icon(Icons.edit_rounded, size: 49, color: accent),
                  ),
                ),
              for (final star in const [
                (15.0, 60.0, 16.0),
                (121.0, 26.0, 12.0),
                (135.0, 112.0, 10.0),
                (31.0, 130.0, 9.0),
              ])
                Positioned(
                  left: star.$1,
                  top: star.$2,
                  child: Icon(
                    Icons.auto_awesome,
                    size: star.$3,
                    color: Color.lerp(accent, Colors.white, .25),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

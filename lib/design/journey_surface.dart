import 'package:flutter/material.dart';

import 'daylock_theme.dart';

/// Shared flat card. Elevation is declared once: a fill in dark mode and a
/// soft shadow in light mode. [accent] adds only a faint tint when emphasized.
class JourneySurface extends StatelessWidget {
  final Widget child;
  final Color? accent;
  final VoidCallback? onTap;
  final double radius;
  final bool emphasized;
  const JourneySurface({
    super.key,
    required this.child,
    this.accent,
    this.onTap,
    this.radius = DaylockSpace.cardRadius,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = scheme.surfaceContainerLow;
    final fill = emphasized && accent != null
        ? Color.alphaBlend(accent!.withValues(alpha: dark ? .10 : .05), base)
        : base;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: .07),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: onTap == null ? child : InkWell(onTap: onTap, child: child),
      ),
    );
  }
}

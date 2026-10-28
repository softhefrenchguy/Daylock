import 'package:flutter/material.dart';

/// Shared tinted glass-like surface, with contrast supplied by the active theme.
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
    this.radius = 20,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = accent ?? scheme.primary;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(
              alpha: dark ? (emphasized ? .12 : .045) : .025,
            ),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: dark ? scheme.surface : scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(
            color: Color.alphaBlend(
              tint.withValues(alpha: emphasized ? .8 : .45),
              scheme.outlineVariant,
            ),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                tint.withValues(alpha: dark ? .22 : .09),
                tint.withValues(alpha: .035),
                tint.withValues(alpha: dark ? .10 : .055),
              ],
            ),
          ),
          child: onTap == null ? child : InkWell(onTap: onTap, child: child),
        ),
      ),
    );
  }
}

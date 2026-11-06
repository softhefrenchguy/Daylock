import 'package:flutter/material.dart';

import 'daylock_scene.dart';
import 'daylock_theme.dart';

/// A rounded, flat group. Rows inside are separated by hairlines.
class DaylockGroup extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final Color? color;
  const DaylockGroup({
    super.key,
    required this.children,
    this.padding = EdgeInsets.zero,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        items.add(
          Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
        );
      }
      items.add(children[i]);
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DaylockSpace.cardRadius),
        boxShadow: light
            ? [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: .07),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: color ?? scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(DaylockSpace.cardRadius),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: items,
          ),
        ),
      ),
    );
  }
}

/// A small coloured tile holding an icon, used to make rows recognisable.
class DaylockIconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const DaylockIconTile({
    super.key,
    required this.icon,
    required this.color,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surfaceContainerLow;
    final hsl = HSLColor.fromColor(color);
    final ink = dark
        ? hsl.withLightness(hsl.lightness < .74 ? .74 : hsl.lightness).toColor()
        : hsl
              .withLightness(hsl.lightness > .40 ? .40 : hsl.lightness)
              .toColor();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          color.withValues(alpha: dark ? .28 : .14),
          surface,
        ),
        borderRadius: BorderRadius.circular(size * .3),
      ),
      child: Icon(icon, size: size * .52, color: ink),
    );
  }
}

/// Fixed accent hues for app sections (not Areas, which are user-chosen).
abstract final class DaylockHues {
  static const violet = Color(0xFFB77BFF);
  static const teal = Color(0xFF4FD1BE);
  static const pink = Color(0xFFFF7FC8);
  static const amber = Color(0xFFFFB45E);
  static const blue = Color(0xFF8A9DFF);
  static const grey = Color(0xFF9B93B8);
}

class DaylockSectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  final EdgeInsetsGeometry padding;
  const DaylockSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.padding = const EdgeInsets.fromLTRB(0, 24, 0, 10),
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
        ),
        if (action != null) Flexible(child: action!),
      ],
    ),
  );
}

/// The landscape header that opens Today, Plan, Journey and onboarding.
class DaylockSkyHeader extends StatelessWidget {
  final SceneMood mood;
  final double progress;
  final double height;
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? bottom;
  final Widget? belowTitle;
  final double horizontalPadding;

  const DaylockSkyHeader({
    super.key,
    required this.mood,
    required this.title,
    this.progress = 0,
    this.height = 250,
    this.subtitle,
    this.actions = const [],
    this.bottom,
    this.belowTitle,
    this.horizontalPadding = DaylockSpace.lg,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sky = SceneColors.of(theme);
    // The sky grows with its content, so large text never spills out of it.
    return Stack(
      children: [
        Positioned.fill(
          child: DaylockScene(
            mood: mood,
            progress: progress,
            height: double.infinity,
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: height + MediaQuery.paddingOf(context).top,
            minWidth: double.infinity,
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                14,
                horizontalPadding - 8,
                0,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Semantics(
                                header: true,
                                child: Text(
                                  title,
                                  style: theme.textTheme.displayLarge!.copyWith(
                                    fontSize: 44,
                                    letterSpacing: -.9,
                                    color: sky.onSky,
                                  ),
                                ),
                              ),
                              if (subtitle != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    subtitle!,
                                    style: theme.textTheme.bodyLarge!.copyWith(
                                      color: sky.onSkyMuted,
                                    ),
                                  ),
                                ),
                              ?belowTitle,
                            ],
                          ),
                        ),
                        ...actions,
                      ],
                    ),
                    const Spacer(),
                    Padding(
                      padding: EdgeInsets.only(
                        top: 12,
                        right: horizontalPadding - 8,
                        bottom: bottom == null ? 40 : 22,
                      ),
                      child: bottom ?? const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A round icon button that sits on the sky.
class DaylockSkyButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Key? buttonKey;
  const DaylockSkyButton({
    super.key,
    this.buttonKey,
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final sky = SceneColors.of(Theme.of(context));
    return IconButton(
      key: buttonKey,
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: sky.dark
            ? Colors.black.withValues(alpha: .22)
            : Colors.white.withValues(alpha: .55),
        foregroundColor: sky.onSky,
        minimumSize: const Size(48, 48),
      ),
      icon: Icon(icon),
    );
  }
}

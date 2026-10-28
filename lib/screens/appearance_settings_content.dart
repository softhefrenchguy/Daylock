import 'package:flutter/material.dart';

import '../design/appearance_preferences.dart';
import '../design/daylock_palette.dart';
import '../design/daylock_theme.dart';
import '../design/daylock_widgets.dart';
import '../design/journey_surface.dart';

class AppearanceSettingsContent extends StatelessWidget {
  final AppearancePreferences preferences;
  final ValueChanged<AppearancePreferences> onChanged;
  final VoidCallback? onAreasRequested;
  final int areaCount;
  const AppearanceSettingsContent({
    super.key,
    required this.preferences,
    required this.onChanged,
    this.onAreasRequested,
    required this.areaCount,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const DaylockLabel('APPEARANCE'),
      const SizedBox(height: DaylockSpace.sm),
      LayoutBuilder(
        builder: (context, constraints) {
          final stacked =
              constraints.maxWidth < 280 ||
              MediaQuery.textScalerOf(context).scale(14) > 20;
          final choices = [
            for (final mode in AppearanceMode.values)
              _AppearanceChoice(
                mode: mode,
                selected: preferences.mode == mode,
                stacked: stacked,
                onTap: () => onChanged(preferences.copyWith(mode: mode)),
              ),
          ];
          return stacked
              ? Column(
                  children: [
                    for (final choice in choices)
                      Padding(
                        padding: const EdgeInsets.only(bottom: DaylockSpace.sm),
                        child: choice,
                      ),
                  ],
                )
              : Row(
                  children: [
                    for (var i = 0; i < choices.length; i++) ...[
                      if (i > 0) const SizedBox(width: DaylockSpace.sm),
                      Expanded(child: choices[i]),
                    ],
                  ],
                );
        },
      ),
      const SizedBox(height: DaylockSpace.sm),
      Text(
        preferences.mode == AppearanceMode.system
            ? 'Follows your device appearance.'
            : '${preferences.mode.label} appearance, in any device mode.',
        style: Theme.of(context).textTheme.bodyMedium!
            .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: DaylockSpace.xl),
      const DaylockLabel('COLOUR THEME'),
      const SizedBox(height: DaylockSpace.md),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns =
              MediaQuery.textScalerOf(context).scale(14) > 20 &&
                  constraints.maxWidth < 560
              ? 1
              : 2;
          final width =
              (constraints.maxWidth - DaylockSpace.sm * (columns - 1)) /
              columns;
          return Wrap(
            spacing: DaylockSpace.sm,
            runSpacing: DaylockSpace.sm,
            children: [
              for (final colour in ColourTheme.values)
                SizedBox(
                  width: width,
                  child: _PaletteChoice(
                    colour: colour,
                    selected: preferences.colour == colour,
                    onTap: () =>
                        onChanged(preferences.copyWith(colour: colour)),
                  ),
                ),
            ],
          );
        },
      ),
      const SizedBox(height: DaylockSpace.xl),
      const DaylockLabel('LIVE PREVIEW'),
      const SizedBox(height: DaylockSpace.md),
      const AppearancePreview(),
      const SizedBox(height: DaylockSpace.xl),

      JourneySurface(
        child: ListTile(
          key: const ValueKey('manage-areas'),
          leading: Icon(
            Icons.grid_view_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: const Text('Manage Areas'),
          subtitle: Text('$areaCount active Areas'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onAreasRequested,
        ),
      ),
    ],
  );
}

class _AppearanceChoice extends StatelessWidget {
  final AppearanceMode mode;
  final bool selected, stacked;
  final VoidCallback onTap;
  const _AppearanceChoice({
    required this.mode,
    required this.selected,
    required this.stacked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = Icon(
      switch (mode) {
        AppearanceMode.dark => Icons.dark_mode_outlined,
        AppearanceMode.light => Icons.light_mode_outlined,
        AppearanceMode.system => Icons.brightness_auto_outlined,
      },
      color: selected ? scheme.primary : scheme.onSurfaceVariant,
      size: 24,
    );
    final label = Text(
      mode.label,
      style: Theme.of(context).textTheme.labelLarge,
    );
    return _SelectableSurface(
      key: ValueKey('appearance-${mode.name}'),
      selected: selected,
      onTap: onTap,
      child: stacked
          ? Row(
              children: [
                icon,
                const SizedBox(width: DaylockSpace.md),
                Expanded(child: label),
                if (selected)
                  Icon(
                    Icons.check_rounded,
                    color: scheme.primary,
                    size: DaylockSpace.icon,
                  ),
              ],
            )
          : Column(
              children: [
                icon,
                const SizedBox(height: DaylockSpace.sm),
                label,
              ],
            ),
    );
  }
}

class _PaletteChoice extends StatelessWidget {
  final ColourTheme colour;
  final bool selected;
  final VoidCallback onTap;
  const _PaletteChoice({
    required this.colour,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = DaylockPalettes.scheme(
      colour,
      Theme.of(context).brightness,
    );
    return _SelectableSurface(
      key: ValueKey('colour-${colour.name}'),
      selected: selected,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  colour.label,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(width: DaylockSpace.xs),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: DaylockSpace.icon,
                color: selected ? scheme.primary : scheme.outline,
              ),
            ],
          ),
          const SizedBox(height: DaylockSpace.md),
          ExcludeSemantics(
            child: Row(
              children: [
                for (final color in [
                  palette.primary,
                  palette.surface,
                  palette.surfaceContainerHigh,
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: DaylockSpace.sm),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.outline),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectableSurface extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  const _SelectableSurface({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: JourneySurface(
        radius: DaylockSpace.radius,
        emphasized: selected,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.all(14),
          child: child,
        ),
      ),
    );
  }
}

// Presentation only. This preview has no Task instances, timers or save callbacks.
class AppearancePreview extends StatelessWidget {
  const AppearancePreview({super.key});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = DaylockColors.of(context);
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: 'Appearance preview. Example commitment styling.',
      child: ExcludeSemantics(
        child: Container(
          key: const ValueKey('appearance-preview'),
          width: double.infinity,
          padding: const EdgeInsets.all(DaylockSpace.md),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(DaylockSpace.radius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: DaylockSpace.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Today', style: text.titleLarge),
                  Text(
                    '1 / 2 complete',
                    style: text.bodyMedium!.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DaylockSpace.md),
              const DaylockProgress(value: 0.5, label: 'Example progress'),
              const SizedBox(height: DaylockSpace.md),
              Row(
                children: [
                  Icon(
                    Icons.check_box_rounded,
                    color: scheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: DaylockSpace.sm),
                  Expanded(
                    child: Text('Keep your word.', style: text.labelLarge),
                  ),
                ],
              ),
              const SizedBox(height: DaylockSpace.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(DaylockSpace.md),
                decoration: BoxDecoration(
                  color: semantic.focusActiveSurface,
                  border: Border.all(color: scheme.primary),
                  borderRadius: BorderRadius.circular(DaylockSpace.radius),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DaylockLabel('STOPWATCH', color: scheme.primary),
                          const SizedBox(height: DaylockSpace.xs),
                          Text('23:00 recorded', style: text.labelLarge),
                        ],
                      ),
                    ),
                    const SizedBox(width: DaylockSpace.sm),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(DaylockSpace.sm),
                      ),
                      child: Icon(
                        Icons.pause_rounded,
                        color: scheme.onPrimary,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DaylockSpace.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(DaylockSpace.md),
                decoration: BoxDecoration(
                  color: semantic.statusSurface,
                  borderRadius: BorderRadius.circular(DaylockSpace.radius),
                ),
                child: DaylockLabel('FREEDOM', color: semantic.statusAccent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

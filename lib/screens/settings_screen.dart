import 'package:flutter/material.dart';

import '../design/appearance_preferences.dart';
import '../design/daylock_palette.dart';
import '../design/daylock_theme.dart';
import '../design/daylock_widgets.dart';
import '../models/freedom_settings.dart';
import '../services/instagram_detection_bridge.dart';
import 'instagram_detection_section.dart';

class SettingsScreen extends StatelessWidget {
  final AppearancePreferences preferences;
  final ValueChanged<AppearancePreferences> onChanged;
  final FreedomSettings freedomSettings;
  final ValueChanged<FreedomSettings>? onFreedomChanged;
  final VoidCallback? onRoutinesRequested;
  final int routineCount;
  final InstagramDetectionBridge? detectionBridge;
  const SettingsScreen({
    super.key,
    required this.preferences,
    required this.onChanged,
    this.freedomSettings = const FreedomSettings(),
    this.onFreedomChanged,
    this.onRoutinesRequested,
    this.routineCount = 0,
    this.detectionBridge,
  });

  Future<void> _chooseFreedomTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: freedomSettings.hour,
        minute: freedomSettings.minute,
      ),
    );
    if (context.mounted && time != null) {
      onFreedomChanged?.call(
        freedomSettings.copyWith(hour: time.hour, minute: time.minute),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.all(DaylockSpace.lg),
              child: Column(
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
                            onTap: () =>
                                onChanged(preferences.copyWith(mode: mode)),
                          ),
                      ];
                      return stacked
                          ? Column(
                              children: [
                                for (final choice in choices)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: DaylockSpace.sm,
                                    ),
                                    child: choice,
                                  ),
                              ],
                            )
                          : Row(
                              children: [
                                for (var i = 0; i < choices.length; i++) ...[
                                  if (i > 0)
                                    const SizedBox(width: DaylockSpace.sm),
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
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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
                          (constraints.maxWidth -
                              DaylockSpace.sm * (columns - 1)) /
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
                                onTap: () => onChanged(
                                  preferences.copyWith(colour: colour),
                                ),
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
                  const DaylockLabel('FREEDOM'),
                  SwitchListTile(
                    key: const ValueKey('freedom-enabled'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Freedom Control'),
                    value: freedomSettings.enabled,
                    onChanged: onFreedomChanged == null
                        ? null
                        : (value) => onFreedomChanged!(
                            freedomSettings.copyWith(enabled: value),
                          ),
                  ),
                  ListTile(
                    key: const ValueKey('freedom-time'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Freedom Time'),
                    subtitle: Text(freedomSettings.timeLabel),
                    trailing: const Icon(Icons.schedule_outlined),
                    onTap: onFreedomChanged == null
                        ? null
                        : () => _chooseFreedomTime(context),
                  ),
                  const Text(
                    'Freedom requires the configured time, completed eligible Today commitments, and a committed tomorrow plan. Instagram blocking is a separate control below.',
                  ),
                  const SizedBox(height: DaylockSpace.xl),
                  const DaylockLabel('ROUTINES'),
                  ListTile(
                    key: const ValueKey('manage-routines'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Manage routines'),
                    subtitle: Text('$routineCount routines'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: onRoutinesRequested,
                  ),
                  if (detectionBridge != null) ...[
                    const SizedBox(height: DaylockSpace.xl),
                    InstagramDetectionSection(bridge: detectionBridge!),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
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
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(DaylockSpace.radius);
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected
            ? DaylockColors.of(context).focusSurface
            : scheme.surfaceContainerLow,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: AnimatedContainer(
            duration: daylockMotion(context),
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.all(DaylockSpace.md),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: child,
          ),
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
                          DaylockLabel('FOCUS', color: scheme.primary),
                          const SizedBox(height: DaylockSpace.xs),
                          Text('23 / 60 min', style: text.labelLarge),
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

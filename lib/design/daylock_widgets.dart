import '../l10n/l10n.dart';

import 'package:flutter/material.dart';

import 'daylock_theme.dart';

/// "12 min" or "12 min 5 s", in [l]'s language (English by default).
String recordedFocusLabel(int milliseconds, [AppLocalizations? l]) {
  l ??= englishStrings;
  final seconds = milliseconds ~/ 1000;
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  return remainder == 0
      ? l.durationMinutes(minutes)
      : l.durationMinutesSeconds(minutes, remainder);
}

Duration daylockMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : const Duration(milliseconds: 220);

/// A small section heading. Labels are written in capitals at call sites; they
/// render in sentence case so headings never shout ("COLOUR THEME" reads as
/// "Colour theme").
class DaylockLabel extends StatelessWidget {
  final String text;
  final Color? color;
  const DaylockLabel(this.text, {super.key, this.color});

  static String sentenceCase(String value) {
    if (value.isEmpty || value != value.toUpperCase()) return value;
    final lower = value.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Text(
        sentenceCase(text),
        style: theme.textTheme.titleMedium!.copyWith(
          fontFamily: DaylockSpace.displayFont,
          fontWeight: FontWeight.w800,
          fontSize: 17,
          color: color ?? theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class DaylockProgress extends StatelessWidget {
  final double value;
  final String label;
  const DaylockProgress({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    value: '${(value * 100).round()}%',
    child: ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        duration: daylockMotion(context),
        builder: (context, progress, _) => LinearProgressIndicator(
          value: progress,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    ),
  );
}

/// A palette-derived highlight for featured primary actions.
ButtonStyle daylockGradientActionStyle(BuildContext context) {
  final colors = Theme.of(context).colorScheme;
  return FilledButton.styleFrom(
    backgroundBuilder: (context, states, child) {
      if (states.contains(WidgetState.disabled)) return child!;
      return Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DaylockSpace.radius),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(colors.primary, Colors.white, .22)!,
              colors.primary,
            ],
          ),
        ),
        child: child,
      );
    },
  );
}

// A shared primary action with a comfortable touch target and a leading icon.
class DaylockAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  const DaylockAction({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: DaylockSpace.icon),
      label: Text(label),
    ),
  );
}

class DaylockLoadState extends StatelessWidget {
  final bool failed;
  final VoidCallback onRetry;
  const DaylockLoadState({
    super.key,
    required this.failed,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DaylockSpace.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                failed ? Icons.refresh_rounded : Icons.adjust_rounded,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: DaylockSpace.lg),
              Text('DAYLOCK', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: DaylockSpace.md),
              Text(
                failed ? context.l10n.loadFailed : context.l10n.loadingDay,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: DaylockSpace.lg),
              if (failed)
                DaylockAction(
                  label: context.l10n.retry,
                  icon: Icons.refresh_rounded,
                  onPressed: onRetry,
                )
              else
                Semantics(
                  label: context.l10n.loadingCommitments,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

import 'package:flutter/material.dart';

import 'daylock_theme.dart';

String recordedFocusLabel(int milliseconds) {
  final seconds = milliseconds ~/ 1000;
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  return remainder == 0 ? '$minutes min' : '$minutes min $remainder s';
}

Duration daylockMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : const Duration(milliseconds: 220);

class DaylockLabel extends StatelessWidget {
  final String text;
  final Color? color;
  const DaylockLabel(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.labelSmall!.copyWith(color: color),
  );
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
                failed
                    ? 'Could not load your saved commitments.'
                    : 'Getting your day ready.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: DaylockSpace.lg),
              if (failed)
                DaylockAction(
                  label: 'Retry',
                  icon: Icons.refresh_rounded,
                  onPressed: onRetry,
                )
              else
                Semantics(
                  label: 'Loading commitments',
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

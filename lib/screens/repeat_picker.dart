import '../l10n/l10n.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../design/daylock_theme.dart';
import '../models/routine.dart';

/// Compact date for repeat previews, e.g. "Wed 18 Nov" ("mer. 18 nov.").
String repeatDateLabel(DateTime date) {
  ensureDateFormatting();
  final locale = Intl.getCurrentLocale();
  return (locale.startsWith('en')
          ? DateFormat('EEE d MMM', locale)
          : DateFormat.MMMEd(locale))
      .format(date);
}

/// The picker's answer. A null [schedule] means "Never".
class RepeatChoice {
  final RoutineSchedule? schedule;
  const RepeatChoice(this.schedule);
}

/// Shows the Repeat sheet. Returns null when the user closes it unchanged.
/// [from] is the first date the repeat can land on (the plan being edited).
Future<RepeatChoice?> showRepeatPicker(
  BuildContext context, {
  required RoutineSchedule? initial,
  required DateTime from,
  bool allowNever = true,
}) => showModalBottomSheet<RepeatChoice>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  constraints: const BoxConstraints(maxWidth: 640),
  builder: (sheetContext) => Theme(
    data: Theme.of(Navigator.of(sheetContext).context),
    child: RepeatPicker(initial: initial, from: from, allowNever: allowNever),
  ),
);

enum _Preset { never, daily, weekdays, everyOther, custom }

class RepeatPicker extends StatefulWidget {
  final RoutineSchedule? initial;
  final DateTime from;
  final bool allowNever;
  const RepeatPicker({
    super.key,
    required this.initial,
    required this.from,
    this.allowNever = true,
  });
  @override
  State<RepeatPicker> createState() => _RepeatPickerState();
}

class _RepeatPickerState extends State<RepeatPicker> {
  late _Preset _preset;
  RepeatKind _customKind = RepeatKind.weekly;
  Set<int> _days = {};
  int _every = 3;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _days = {widget.from.weekday};
    if (s == null) {
      _preset = widget.allowNever ? _Preset.never : _Preset.daily;
    } else if (s.isDaily) {
      _preset = _Preset.daily;
    } else if (s.kind == RepeatKind.weekly &&
        s.weekdays.length == 5 &&
        s.weekdays.containsAll(RoutineSchedule.weekdaysOnly)) {
      _preset = _Preset.weekdays;
    } else if (s.kind == RepeatKind.interval && s.everyDays == 2) {
      _preset = _Preset.everyOther;
    } else {
      _preset = _Preset.custom;
      _customKind = s.kind;
      if (s.kind == RepeatKind.weekly) _days = {...s.weekdays};
      if (s.kind == RepeatKind.interval) _every = s.everyDays;
    }
  }

  RoutineSchedule? get _schedule {
    final from = widget.from;
    return switch (_preset) {
      _Preset.never => null,
      _Preset.daily => RoutineSchedule.daily(from: from),
      _Preset.weekdays => RoutineSchedule.onWeekdays(
        RoutineSchedule.weekdaysOnly,
      ),
      _Preset.everyOther => RoutineSchedule.everyDays(2, from: from),
      _Preset.custom =>
        _customKind == RepeatKind.weekly
            ? (_days.isEmpty ? null : RoutineSchedule.onWeekdays(_days))
            : RoutineSchedule.everyDays(_every, from: from),
    };
  }

  bool get _valid =>
      _preset != _Preset.custom ||
      _customKind == RepeatKind.interval ||
      _days.isNotEmpty;

  /// Keep an unchanged interval's original start so re-saving never shifts it.
  RoutineSchedule? get _result {
    final chosen = _schedule;
    final initial = widget.initial;
    if (chosen != null && initial != null && chosen.sameRule(initial)) {
      return initial;
    }
    return chosen;
  }

  String _presetLabel(_Preset preset) => switch (preset) {
    _Preset.never => context.l10n.repeatNever,
    _Preset.daily => context.l10n.repeatDaily,
    _Preset.weekdays => context.l10n.repeatWeekdays,
    _Preset.everyOther => context.l10n.repeatEveryDays(2),
    _Preset.custom => context.l10n.repeatCustom,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final schedule = _result;
    final next = schedule?.upcoming(widget.from) ?? const <DateTime>[];
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          DaylockSpace.lg,
          0,
          DaylockSpace.lg,
          DaylockSpace.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.repeat,
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.repeatClose,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: DaylockSpace.sm),
            Wrap(
              spacing: DaylockSpace.sm,
              runSpacing: DaylockSpace.sm,
              children: [
                for (final preset in _Preset.values)
                  if (preset != _Preset.never || widget.allowNever)
                    ChoiceChip(
                      key: ValueKey('repeat-preset-${preset.name}'),
                      label: Text(_presetLabel(preset)),
                      selected: _preset == preset,
                      onSelected: (_) => setState(() => _preset = preset),
                    ),
              ],
            ),
            if (_preset == _Preset.custom) ...[
              const SizedBox(height: DaylockSpace.md),
              SegmentedButton<RepeatKind>(
                key: const ValueKey('repeat-custom-kind'),
                segments: [
                  ButtonSegment(
                    value: RepeatKind.weekly,
                    label: Text(context.l10n.repeatDaysOfWeek),
                  ),
                  ButtonSegment(
                    value: RepeatKind.interval,
                    label: Text(context.l10n.repeatEveryNDays),
                  ),
                ],
                selected: {_customKind},
                onSelectionChanged: (value) =>
                    setState(() => _customKind = value.single),
              ),
              const SizedBox(height: DaylockSpace.md),
              if (_customKind == RepeatKind.weekly)
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (var day = 1; day <= 7; day++)
                      Semantics(
                        label: context.l10n.weekdayLong(day),
                        excludeSemantics: true,
                        selected: _days.contains(day),
                        button: true,
                        child: _DayToggle(
                          key: ValueKey('repeat-day-$day'),
                          letter: DateFormat.EEEEE(context.l10n.localeName)
                              .format(DateTime(2024, 1, day)),
                          selected: _days.contains(day),
                          onTap: () => setState(() {
                            if (!_days.remove(day)) _days.add(day);
                          }),
                        ),
                      ),
                  ],
                )
              else
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: DaylockSpace.sm,
                  runSpacing: DaylockSpace.sm,
                  children: [
                    Text(
                      context.l10n.repeatEvery,
                      style: theme.textTheme.titleMedium,
                    ),
                    IconButton.outlined(
                      key: const ValueKey('repeat-every-less'),
                      tooltip: context.l10n.repeatFewerDays,
                      onPressed: _every > 2
                          ? () => setState(() => _every--)
                          : null,
                      icon: const Icon(Icons.remove_rounded),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 32),
                      child: Text(
                        '$_every',
                        key: const ValueKey('repeat-every-value'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    IconButton.outlined(
                      key: const ValueKey('repeat-every-more'),
                      tooltip: context.l10n.repeatMoreDays,
                      onPressed: _every < RoutineSchedule.maxInterval
                          ? () => setState(() => _every++)
                          : null,
                      icon: const Icon(Icons.add_rounded),
                    ),
                    Text('days', style: theme.textTheme.titleMedium),
                  ],
                ),
            ],
            const SizedBox(height: DaylockSpace.md),
            Semantics(
              liveRegion: true,
              child: Text(
                key: const ValueKey('repeat-preview'),
                !_valid
                    ? context.l10n.repeatPickOneDay
                    : schedule == null
                    ? context.l10n.repeatOnlyThisDay
                    : context.l10n.repeatNext(
                        next.map(repeatDateLabel).join(' · '),
                      ),
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: _valid ? colors.onSurfaceVariant : colors.error,
                ),
              ),
            ),
            const SizedBox(height: DaylockSpace.lg),
            FilledButton(
              key: const ValueKey('repeat-done'),
              onPressed: _valid
                  ? () => Navigator.of(context).pop(RepeatChoice(_result))
                  : null,
              child: Text(context.l10n.done),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayToggle extends StatelessWidget {
  final String letter;
  final bool selected;
  final VoidCallback onTap;
  const _DayToggle({
    super.key,
    required this.letter,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: selected ? colors.primary : colors.surfaceContainerHigh,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Center(
            child: Text(
              letter,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: selected ? colors.onPrimary : colors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

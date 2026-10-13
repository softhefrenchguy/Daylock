import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/calendar_activity.dart';
import '../models/event.dart';
import 'daylock_widgets.dart';

// Semantic heatmap tones derived from the central coordinated ColorScheme.
class DaylockHeatmapPalette {
  final ColorScheme scheme;
  const DaylockHeatmapPalette(this.scheme);

  Color background(HeatmapIntensity intensity) => switch (intensity) {
    HeatmapIntensity.neutral => scheme.surfaceContainerLow,
    HeatmapIntensity.zero => scheme.outlineVariant,
    HeatmapIntensity.low => Color.lerp(
      scheme.surfaceContainerLow,
      scheme.primary,
      .26,
    )!,
    HeatmapIntensity.medium => Color.lerp(
      scheme.surfaceContainerLow,
      scheme.primary,
      .50,
    )!,
    HeatmapIntensity.high => Color.lerp(
      scheme.surfaceContainerLow,
      scheme.primary,
      .73,
    )!,
    HeatmapIntensity.complete => scheme.primary,
  };

  Color foreground(HeatmapIntensity intensity) {
    final luminance = background(intensity).computeLuminance();
    double contrast(Color color) {
      final ink = color.computeLuminance();
      return (math.max(ink, luminance) + .05) /
          (math.min(ink, luminance) + .05);
    }

    final preferred = contrast(scheme.onSurface) >= contrast(scheme.onPrimary)
        ? scheme.onSurface
        : scheme.onPrimary;
    if (contrast(preferred) >= 4.5) return preferred;
    // Mid-intensity tones occasionally need neutral ink for accessible contrast.
    return contrast(Colors.black) >= contrast(Colors.white)
        ? Colors.black
        : Colors.white;
  }
}

String calendarDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class DaylockMonthGrid extends StatefulWidget {
  final DateTime selectedDate;
  final CalendarDayActivity Function(DateTime) activityForDate;
  final List<Event> events;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<int>? onMonthChanged;

  const DaylockMonthGrid({
    super.key,
    required this.selectedDate,
    required this.activityForDate,
    required this.events,
    required this.onDateSelected,
    this.onMonthChanged,
  });

  @override
  State<DaylockMonthGrid> createState() => _DaylockMonthGridState();
}

class _DaylockMonthGridState extends State<DaylockMonthGrid> {
  double _drag = 0;
  double _edgeDrag = 0;

  void _finishSwipe(double distance) {
    if (distance.abs() < 56) return;
    widget.onMonthChanged?.call(distance < 0 ? 1 : -1);
  }

  bool _onGridScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.horizontal) return false;
    if (notification is ScrollStartNotification) _edgeDrag = 0;
    if (notification is OverscrollNotification &&
        notification.dragDetails != null) {
      _edgeDrag -= notification.overscroll;
    }
    if (notification is ScrollEndNotification && _edgeDrag.abs() >= 56) {
      final distance = _edgeDrag;
      _edgeDrag = 0;
      // Wide accessibility grids pan normally; a deliberate swipe beyond an edge
      // changes month. Defer until layout notifications have finished.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _finishSwipe(distance);
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final month = DateTime(widget.selectedDate.year, widget.selectedDate.month);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final leading = month.weekday - 1;
    final weeks = ((leading + days) / 7).ceil();
    final theme = Theme.of(context);
    final palette = DaylockHeatmapPalette(theme.colorScheme);
    return LayoutBuilder(
      builder: (context, constraints) {
        final minimumCell = math.max(
          40.0,
          MediaQuery.textScalerOf(context).scale(13) * 2 + 14,
        );
        final width = math.max(constraints.maxWidth, minimumCell * 7);
        final height = math.max(
          48.0,
          MediaQuery.textScalerOf(context).scale(13) * 1.5 + 20,
        );
        final wide = width > constraints.maxWidth + 1;
        return GestureDetector(
          key: const ValueKey('calendar-month-swipe'),
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: widget.onMonthChanged == null
              ? null
              : (_) => _drag = 0,
          onHorizontalDragUpdate: widget.onMonthChanged == null
              ? null
              : (details) => _drag += details.primaryDelta ?? 0,
          onHorizontalDragEnd: widget.onMonthChanged == null
              ? null
              : (_) => _finishSwipe(_drag),
          onHorizontalDragCancel: () => _drag = 0,
          child: NotificationListener<ScrollNotification>(
            onNotification: _onGridScroll,
            child: SingleChildScrollView(
              key: const ValueKey('calendar-grid-scroll'),
              scrollDirection: Axis.horizontal,
              physics: wide
                  ? const ClampingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              child: SizedBox(
                width: width,
                child: Column(
                  children: [
                    Row(
                      children: [
                        for (final label in const [
                          'MO',
                          'TU',
                          'WE',
                          'TH',
                          'FR',
                          'SA',
                          'SU',
                        ])
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                label,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelSmall!.copyWith(
                                  letterSpacing: 0,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    for (var week = 0; week < weeks; week++)
                      Row(
                        children: [
                          for (var column = 0; column < 7; column++)
                            Expanded(
                              child: SizedBox(
                                height: height,
                                child: Builder(
                                  builder: (context) {
                                    final number =
                                        week * 7 + column - leading + 1;
                                    if (number < 1 || number > days) {
                                      return const SizedBox.shrink();
                                    }
                                    final date = DateTime(
                                      month.year,
                                      month.month,
                                      number,
                                    );
                                    return _CalendarDateTile(
                                      date: date,
                                      selected: date == widget.selectedDate,
                                      activity: widget.activityForDate(date),
                                      palette: palette,
                                      eventCount: widget.events
                                          .where(
                                            (event) => event.occursOn(date),
                                          )
                                          .length,
                                      onSelected: () =>
                                          widget.onDateSelected(date),
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CalendarDateTile extends StatelessWidget {
  final DateTime date;
  final CalendarDayActivity activity;
  final DaylockHeatmapPalette palette;
  final bool selected;
  final int eventCount;
  final VoidCallback onSelected;
  const _CalendarDateTile({
    required this.date,
    required this.activity,
    required this.palette,
    required this.selected,
    required this.eventCount,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final key = calendarDateKey(date);
    final progress = activity.completionPercentage;
    final description = progress == null
        ? activity.isRecorded
              ? activity.excusedCount > 0
                    ? 'No eligible commitments, ${activity.excusedCount} excused, neutral'
                    : 'No commitments, neutral'
              : 'No recorded commitments, neutral'
        : '${activity.completedCount} of ${activity.eligibleCount} eligible commitments complete, ${progress.round()} percent, ${activity.excusedCount} excused';
    return Semantics(
      key: ValueKey('calendar-day-$key'),
      button: true,
      selected: selected,
      label:
          '${MaterialLocalizations.of(context).formatFullDate(date)}${activity.isToday ? ', Today' : ''}',
      value: '$description, $eventCount scheduled events',
      onTap: onSelected,
      excludeSemantics: true,
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.all(1),
          child: AnimatedContainer(
            key: ValueKey('calendar-outline-$key'),
            duration: daylockMotion(context),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: selected
                    ? theme.colorScheme.onSurface
                    : activity.isToday
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Material(
              key: ValueKey('heatmap-fill-$key'),
              color: palette.background(activity.intensity),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
                side: activity.isToday
                    ? BorderSide(
                        color: selected
                            ? palette.foreground(activity.intensity)
                            : theme.colorScheme.primary,
                        width: 2,
                      )
                    : BorderSide.none,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${date.day}',
                    maxLines: 1,
                    softWrap: false,
                    style: theme.textTheme.labelLarge!.copyWith(
                      fontSize: 13,
                      height: 1.2,
                      letterSpacing: 0,
                      color: palette.foreground(activity.intensity),
                      fontWeight: selected || activity.isToday
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  SizedBox(
                    height: 4,
                    width: 4,
                    child: eventCount == 0
                        ? null
                        : DecoratedBox(
                            key: ValueKey('calendar-events-$key'),
                            decoration: BoxDecoration(
                              color: palette.foreground(activity.intensity),
                              shape: BoxShape.circle,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _intensityLabel(HeatmapIntensity intensity) => switch (intensity) {
  HeatmapIntensity.neutral =>
    'Neutral: no eligible commitments, missing history or future date',
  HeatmapIntensity.zero => 'Recorded commitments: 0 percent complete',
  HeatmapIntensity.low => 'More than 0 to 25 percent complete',
  HeatmapIntensity.medium => 'More than 25 to 50 percent complete',
  HeatmapIntensity.high => 'More than 50 to less than 100 percent complete',
  HeatmapIntensity.complete => '100 percent complete',
};

class DaylockHeatmapLegend extends StatelessWidget {
  const DaylockHeatmapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = DaylockHeatmapPalette(theme.colorScheme);
    Widget swatch(HeatmapIntensity intensity) => Tooltip(
      message: _intensityLabel(intensity),
      child: Semantics(
        label: _intensityLabel(intensity),
        excludeSemantics: true,
        child: SizedBox(
          width: 20,
          height: 24,
          child: Center(
            child: Container(
              key: ValueKey('heatmap-legend-${intensity.name}'),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: palette.background(intensity),
                borderRadius: BorderRadius.circular(2),
                border: intensity == HeatmapIntensity.neutral
                    ? Border.all(color: theme.colorScheme.outline)
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
    final labelStyle = theme.textTheme.bodySmall!.copyWith(
      fontSize: 11,
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        swatch(HeatmapIntensity.neutral),
        Text('Less', style: labelStyle),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final intensity in HeatmapIntensity.values.skip(1))
              swatch(intensity),
          ],
        ),
        Text('More', style: labelStyle),
      ],
    );
  }
}

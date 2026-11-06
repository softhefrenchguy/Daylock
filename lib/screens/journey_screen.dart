import 'package:flutter/material.dart';

import '../design/area_tones.dart';
import '../design/daylock_areas.dart';
import '../design/daylock_scene.dart';
import '../design/daylock_surfaces.dart';
import '../design/daylock_theme.dart';
import '../design/highlight_illustration.dart';
import '../models/area.dart';
import '../models/highlight.dart';
import '../models/highlight_illustration.dart';
import '../services/journey_service.dart';

const _monthsShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String achievementDateLabel(DateTime date) =>
    '${date.day} ${_monthsShort[date.month - 1]}';

class JourneyScreen extends StatelessWidget {
  final AreaBook areas;
  final HighlightBook highlights;
  final JourneyData data;
  final ValueChanged<String> onAreaOpened;
  final ValueChanged<Highlight> onHighlightOpened;
  final ValueChanged<Highlight>? onHighlightEdited;
  final VoidCallback onAddHighlight, onAllHighlights, onDailyHistory;
  final VoidCallback? onPastChapters, onManageAreas;
  const JourneyScreen({
    super.key,
    required this.areas,
    required this.highlights,
    required this.data,
    required this.onAreaOpened,
    required this.onHighlightOpened,
    required this.onAddHighlight,
    required this.onAllHighlights,
    required this.onDailyHistory,
    this.onHighlightEdited,
    this.onPastChapters,
    this.onManageAreas,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final summary = JourneySummary(data.records);
    final streak = data.currentStreak;
    final longest = data.longestStreak;
    final sky = SceneColors.of(theme);
    final gold = daylockGold(theme.brightness);
    final dark = theme.brightness == Brightness.dark;
    final achievements = highlights.newestFirst;
    final weekly = {
      for (final a in areas.active) a.id: data.keptThisWeek(a.id),
    };
    final most = weekly.values.fold(0, (a, b) => a > b ? a : b);
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth < 360
            ? DaylockSpace.md
            : DaylockSpace.lg;
        Widget boxed(Widget child) => Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: child,
            ),
          ),
        );
        return ListView(
          key: const ValueKey('journey-content'),
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            DaylockSkyHeader(
              mood: SceneMood.dusk,
              height: 244,
              horizontalPadding: padding,
              title: 'Journey',
              actions: [
                if (onManageAreas != null)
                  DaylockSkyButton(
                    buttonKey: const ValueKey('journey-manage-areas'),
                    icon: Icons.tune_rounded,
                    tooltip: 'Manage Areas',
                    onPressed: onManageAreas,
                  ),
              ],
              belowTitle: Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Semantics(
                  key: const ValueKey('journey-streak'),
                  container: true,
                  label: streak == 1 ? '1 day streak' : '$streak day streak',
                  child: ExcludeSemantics(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$streak',
                          style: theme.textTheme.displayLarge!.copyWith(
                            fontSize: 72,
                            height: .95,
                            color: dark ? const Color(0xFFFFF3DF) : sky.onSky,
                            shadows: dark
                                ? [
                                    Shadow(
                                      color: gold.withValues(alpha: .5),
                                      blurRadius: 24,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'day streak',
                                  style: theme.textTheme.titleLarge!.copyWith(
                                    fontSize: 22,
                                    color: sky.onSky,
                                  ),
                                ),
                                Text(
                                  streak == 0
                                      ? 'Keep all of today to start one'
                                      : streak >= longest
                                      ? 'Your longest yet'
                                      : 'Longest: $longest days',
                                  style: theme.textTheme.bodyMedium!.copyWith(
                                    color: sky.onSkyMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            boxed(
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  key: const ValueKey('journey-effort-summary'),
                  children: [
                    _Total(
                      value: '${summary.completedCount}',
                      label: 'kept',
                      valueKey: const ValueKey('journey-total-completed'),
                      color: gold,
                    ),
                    _Total(
                      value: _shortFocus(summary.focusMilliseconds),
                      label: 'focused',
                      valueKey: const ValueKey('journey-total-focus'),
                      color: dark
                          ? const Color(0xFF7FE3D3)
                          : const Color(0xFF14776A),
                    ),
                    _Total(
                      value: '${highlights.highlights.length}',
                      label: highlights.highlights.length == 1
                          ? 'achievement'
                          : 'achievements',
                      valueKey: const ValueKey('journey-total-highlights'),
                      color: dark
                          ? const Color(0xFFFF9AD8)
                          : const Color(0xFFB2307A),
                    ),
                  ],
                ),
              ),
            ),
            boxed(
              DaylockSectionHeader(
                title: 'Achievements',
                action: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (achievements.length > 1)
                      Flexible(
                        child: TextButton(
                          key: const ValueKey('all-highlights'),
                          onPressed: onAllHighlights,
                          child: Text(
                            'See all ${achievements.length}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    IconButton.filledTonal(
                      key: const ValueKey('add-highlight'),
                      tooltip: 'Add achievement',
                      onPressed: onAddHighlight,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height:
                  186 *
                  MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.9),
              child: ListView(
                key: const ValueKey('journey-achievements'),
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: padding),
                children: [
                  for (final highlight in achievements.take(12))
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _AchievementCard(
                        highlight: highlight,
                        area: areas.areas
                            .where((a) => a.id == highlight.areaId)
                            .firstOrNull,
                        areaMissing:
                            highlight.areaId != null &&
                            !areas.areas.any((a) => a.id == highlight.areaId),
                        onOpened: () => onHighlightOpened(highlight),
                        onEdited: onHighlightEdited == null
                            ? null
                            : () => onHighlightEdited!(highlight),
                      ),
                    ),
                  _AddAchievementCard(
                    empty: achievements.isEmpty,
                    onAdd: onAddHighlight,
                  ),
                ],
              ),
            ),
            boxed(
              DaylockSectionHeader(
                title: 'Last 5 weeks',
                action: TextButton(
                  key: const ValueKey('daily-history'),
                  onPressed: onDailyHistory,
                  child: const Text('Daily history'),
                ),
              ),
            ),
            boxed(_WeeksGrid(data: data)),
            boxed(
              DaylockSectionHeader(
                title: 'Your Areas',
                action: onManageAreas == null
                    ? null
                    : TextButton(
                        onPressed: onManageAreas,
                        child: const Text('Manage'),
                      ),
              ),
            ),
            boxed(
              DaylockGroup(
                key: const ValueKey('journey-area-grid'),
                children: [
                  for (final area in areas.active)
                    _AreaRow(
                      area: area,
                      kept: weekly[area.id] ?? 0,
                      most: most,
                      onTap: () => onAreaOpened(area.id),
                    ),
                ],
              ),
            ),
            if (onPastChapters != null)
              boxed(
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: DaylockGroup(
                    children: [
                      ListTile(
                        key: const ValueKey('past-chapters'),
                        onTap: onPastChapters,
                        leading: DaylockIconTile(
                          icon: Icons.inventory_2_outlined,
                          color: scheme.primary,
                        ),
                        title: const Text('Past Chapters'),
                        subtitle: const Text('Areas you’ve archived'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

String _shortFocus(int milliseconds) {
  final minutes = milliseconds ~/ 60000;
  if (minutes < 60) return '${minutes}m';
  return '${minutes ~/ 60}h';
}

class _Total extends StatelessWidget {
  final String value, label;
  final Color color;
  final Key? valueKey;
  const _Total({
    required this.value,
    required this.label,
    required this.color,
    this.valueKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Semantics(
        container: true,
        label: '$value $label',
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                key: valueKey,
                style: theme.textTheme.displayLarge!.copyWith(
                  fontSize: 34,
                  color: color,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Highlight highlight;
  final Area? area;
  final bool areaMissing;
  final VoidCallback onOpened;
  final VoidCallback? onEdited;
  const _AchievementCard({
    required this.highlight,
    required this.area,
    this.areaMissing = false,
    required this.onOpened,
    this.onEdited,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final base = area == null ? const Color(0xFFFF7FC8) : Color(area!.colour);
    final tones = AreaTones.forContext(context, base);
    final card = Color.alphaBlend(
      base.withValues(alpha: dark ? .30 : .16),
      theme.colorScheme.surfaceContainerLow,
    );
    final iconId = resolveHighlightIllustration(
      title: highlight.title,
      explicitIcon: highlight.illustrationIcon,
      areaIcon: area?.icon,
    );
    return Semantics(
      button: true,
      label:
          'Achievement: ${highlight.title}, ${achievementDateLabel(highlight.date)}',
      child: Material(
        key: ValueKey('highlight-${highlight.id}'),
        color: card,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpened,
          onLongPress: onEdited,
          child: SizedBox(
            width: 158,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AchievementBadge(
                      key: ValueKey('highlight-illustration-${highlight.id}'),
                      iconId: iconId,
                      tones: tones,
                      glow: dark,
                    ),
                    const Spacer(),
                    Text(
                      highlight.title,
                      maxLines: MediaQuery.textScalerOf(context).scale(1) > 1.4
                          ? 2
                          : 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge!.copyWith(
                        fontSize: 17,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        achievementDateLabel(highlight.date),
                        if (area != null) area!.name,
                        if (areaMissing) 'Area unavailable',
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: tones.ink,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddAchievementCard extends StatelessWidget {
  final bool empty;
  final VoidCallback onAdd;
  const _AddAchievementCard({required this.empty, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: scheme.outlineVariant, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onAdd,
        child: SizedBox(
          width: empty ? 260 : 158,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.primary, width: 2),
                  ),
                  child: Icon(Icons.add_rounded, color: scheme.primary),
                ),
                const Spacer(),
                Text(
                  empty ? 'Keep a moment that matters.' : 'Add an achievement',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge!.copyWith(fontSize: 17),
                ),
                if (empty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'A driving licence, a first 10k, a finished chapter.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeeksGrid extends StatelessWidget {
  final JourneyData data;
  const _WeeksGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final gold = daylockGold(theme.brightness);
    final today = data.today;
    final monday = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday - 1) - 28,
    );
    final days = [
      for (var i = 0; i < 35; i++)
        DateTime(monday.year, monday.month, monday.day + i),
    ];
    final keptDays = days
        .where(
          (d) => !d.isAfter(today) && data.statusOn(d) == JourneyDayStatus.kept,
        )
        .length;
    final some = Color.alphaBlend(
      scheme.primary.withValues(alpha: dark ? .55 : .45),
      scheme.surfaceContainerLow,
    );
    final missed = Color.alphaBlend(
      scheme.onSurface.withValues(alpha: dark ? .16 : .12),
      scheme.surfaceContainerLow,
    );
    final empty = Color.alphaBlend(
      scheme.onSurface.withValues(alpha: dark ? .05 : .04),
      scheme.surfaceContainerLow,
    );
    Widget legend(Color color, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.bodySmall!.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
    Widget cell(DateTime day) {
      final future = day.isAfter(today);
      final status = data.statusOn(day);
      final kept = status == JourneyDayStatus.kept;
      final color = future
          ? Colors.transparent
          : switch (status) {
              JourneyDayStatus.kept => gold,
              JourneyDayStatus.some => some,
              JourneyDayStatus.missed => missed,
              _ => Colors.transparent,
            };
      final quiet =
          status == JourneyDayStatus.none || status == JourneyDayStatus.excused;
      return Container(
        decoration: BoxDecoration(
          color: !future && quiet ? empty : color,
          borderRadius: BorderRadius.circular(8),
          border: day == today && !kept
              ? Border.all(color: gold, width: 2)
              : null,
          boxShadow: kept && dark
              ? [BoxShadow(color: gold.withValues(alpha: .4), blurRadius: 10)]
              : null,
        ),
      );
    }

    const initials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return DaylockGroup(
      key: const ValueKey('journey-weeks'),
      padding: const EdgeInsets.all(14),
      children: [
        Semantics(
          container: true,
          label: keptDays == 1
              ? 'Last 5 weeks: 1 day fully kept'
              : 'Last 5 weeks: $keptDays days fully kept',
          child: ExcludeSemantics(
            child: Column(
              children: [
                Row(
                  children: [
                    for (final letter in initials)
                      Expanded(
                        child: Center(
                          child: Text(
                            letter,
                            style: theme.textTheme.bodySmall!.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Column(
                  children: [
                    for (var week = 0; week < 5; week++)
                      Padding(
                        padding: EdgeInsets.only(top: week == 0 ? 0 : 6),
                        child: Row(
                          children: [
                            for (var i = 0; i < 7; i++) ...[
                              if (i > 0) const SizedBox(width: 6),
                              Expanded(
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: cell(days[week * 7 + i]),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              legend(gold, 'All kept'),
              legend(some, 'Some kept'),
              legend(missed, 'Missed'),
            ],
          ),
        ),
      ],
    );
  }
}

class _AreaRow extends StatelessWidget {
  final Area area;
  final int kept, most;
  final VoidCallback onTap;
  const _AreaRow({
    required this.area,
    required this.kept,
    required this.most,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tones = AreaTones.forContext(context, Color(area.colour));
    final fraction = most == 0 ? 0.0 : kept / most;
    return InkWell(
      key: ValueKey('journey-area-${area.id}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tones.tint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                areaIcons[area.icon] ?? Icons.wb_sunny_outlined,
                color: tones.ink,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          area.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge!.copyWith(
                            fontSize: 17,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '$kept this week',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium!.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 8,
                      backgroundColor: scheme.outlineVariant,
                      valueColor: AlwaysStoppedAnimation(tones.ink),
                      semanticsLabel: kept == 1
                          ? '${area.name}: 1 kept this week'
                          : '${area.name}: $kept kept this week',
                      semanticsValue: '${(fraction * 100).round()}%',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// The round, Area-coloured emblem on an achievement card.
class AchievementBadge extends StatelessWidget {
  /// Resolved illustration id (see `resolveHighlightIllustration`).
  final String iconId;
  final AreaTones tones;
  final bool glow;
  const AchievementBadge({
    super.key,
    required this.iconId,
    required this.tones,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: 52,
    height: 52,
    decoration: BoxDecoration(
      color: tones.ink,
      shape: BoxShape.circle,
      boxShadow: glow
          ? [BoxShadow(color: tones.ink.withValues(alpha: .45), blurRadius: 20)]
          : null,
    ),
    child: Icon(
      highlightIllustrationIcons[iconId] ?? Icons.auto_awesome,
      color: tones.onInk,
      size: 26,
    ),
  );
}

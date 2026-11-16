import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../design/daylock_surfaces.dart';
import '../design/daylock_theme.dart';
import '../design/daylock_widgets.dart';
import '../l10n/l10n.dart';
import '../services/weekly_review.dart';

/// How the last seven days went, and a nudge to plan the next one.
class WeeklyReviewScreen extends StatelessWidget {
  final WeeklyReview review;
  final VoidCallback onPlanTomorrow;
  const WeeklyReviewScreen({
    super.key,
    required this.review,
    required this.onPlanTomorrow,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    ensureDateFormatting();
    final range = DateFormat.MMMd(l.localeName);
    final r = review;
    final (headline, body) = r.isEmpty
        ? (l.weekQuietTitle, l.weekQuietBody)
        : r.keptShare >= .8
        ? (l.weekStrongTitle, l.weekStrongBody)
        : r.keptShare >= .5
        ? (l.weekSolidTitle, l.weekSolidBody)
        : (l.weekBuildTitle, l.weekBuildBody);
    Widget stat(IconData icon, String value, String label) => ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(value, style: theme.textTheme.titleMedium),
      subtitle: Text(label),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l.weekTitle)),
      body: ListView(
        key: const ValueKey('weekly-review'),
        padding: const EdgeInsets.all(DaylockSpace.lg),
        children: [
          Text(
            l.weekRange(range.format(r.from), range.format(r.through)),
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: DaylockSpace.sm),
          Text(headline, style: theme.textTheme.headlineMedium),
          const SizedBox(height: DaylockSpace.sm),
          Text(body, style: theme.textTheme.bodyLarge!.copyWith(color: muted)),
          const SizedBox(height: DaylockSpace.lg),
          if (!r.isEmpty)
            DaylockGroup(
              children: [
                stat(
                  Icons.wb_sunny_outlined,
                  l.weekDaysKept(r.daysKept, r.daysPlanned),
                  l.weekDaysKeptLabel,
                ),
                stat(
                  Icons.check_circle_outline,
                  l.keptOfEligible(r.kept, r.eligible),
                  l.weekCommitmentsLabel,
                ),
                if (r.focusMilliseconds > 0)
                  stat(
                    Icons.timer_outlined,
                    l.focusDuration(r.focusMilliseconds),
                    l.recordedTimeLabel,
                  ),
                stat(
                  Icons.local_fire_department_outlined,
                  l.dayStreakLabel(r.streak),
                  l.weekStreakLabel,
                ),
              ],
            ),
          if (r.topArea != null || r.quietAreas.isNotEmpty) ...[
            const SizedBox(height: DaylockSpace.lg),
            DaylockLabel(l.weekAreasLabel),
            const SizedBox(height: DaylockSpace.sm),
            DaylockGroup(
              children: [
                if (r.topArea != null)
                  ListTile(
                    leading: const Icon(Icons.trending_up_rounded),
                    title: Text(l.weekTopArea(r.topArea!.name)),
                    subtitle: Text(l.weekTopAreaKept(r.topAreaKept)),
                  ),
                if (r.quietAreas.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.nights_stay_outlined),
                    title: Text(
                      l.weekQuietAreas(
                        r.quietAreas.map((a) => a.name).join(l.listSeparator),
                      ),
                    ),
                    subtitle: Text(l.weekQuietAreasHint),
                  ),
              ],
            ),
          ],
          if (r.breaks > 0) ...[
            const SizedBox(height: DaylockSpace.md),
            Text(l.weekBreaks(r.breaks), style: TextStyle(color: muted)),
          ],
          const SizedBox(height: DaylockSpace.xl),
          DaylockAction(
            key: const ValueKey('weekly-plan'),
            label: l.planTomorrow,
            icon: Icons.arrow_forward_rounded,
            onPressed: onPlanTomorrow,
          ),
        ],
      ),
    );
  }
}

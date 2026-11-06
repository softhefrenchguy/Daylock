import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../design/area_tones.dart';
import '../design/daylock_freedom_status.dart';
import '../design/daylock_scene.dart';
import '../design/daylock_surfaces.dart';
import '../design/daylock_task_row.dart';
import '../design/daylock_theme.dart';
import '../design/daylock_widgets.dart';
import '../models/area.dart';
import '../models/commitment_progress.dart';
import '../models/daily_plan.dart';
import '../models/freedom_settings.dart';
import '../models/task.dart';
import '../services/freedom_service.dart';
import 'task_actions_sheet.dart';

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String daylockDateLabel(DateTime date) =>
    '${_weekdays[date.weekday - 1]} ${date.day} ${_months[date.month - 1]}';

String daylockWeekday(DateTime date) => _weekdays[date.weekday - 1];

class TodayScreen extends StatefulWidget {
  final DailyPlan plan;
  final DailyPlan? tomorrowPlan;
  final AreaBook? areas;
  final VoidCallback onTaskChanged;
  final ValueChanged<Task> onFocusToggled;
  final VoidCallback? onPlanRequested;
  final VoidCallback? onSettingsRequested;
  final VoidCallback? onFreedomRequested;
  final DateTime currentTime;
  final FreedomEligibility? freedomEligibility;
  final void Function(Task task, TaskOutcome outcome, String? reason)?
  onOutcomeChanged;

  /// Shown under the header, e.g. a warning that app blocking has stopped.
  final Widget? notice;

  const TodayScreen({
    super.key,
    this.notice,
    required this.plan,
    this.tomorrowPlan,
    this.areas,
    required this.onTaskChanged,
    required this.onFocusToggled,
    required this.currentTime,
    this.onPlanRequested,
    this.onSettingsRequested,
    this.onFreedomRequested,
    this.onOutcomeChanged,
    this.freedomEligibility,
  });

  @override
  State<TodayScreen> createState() => TodayScreenState();
}

class TodayScreenState extends State<TodayScreen> {
  final Set<ModalRoute<dynamic>> _ownedModals = {};
  bool _openingModal = false;
  bool _showAll = false;
  bool _freedomOpen = false;

  FreedomEligibility get _currentFreedom =>
      widget.freedomEligibility ??
      const FreedomService().evaluate(
        now: widget.currentTime,
        settings: const FreedomSettings(),
        todayPlan: widget.plan,
      );

  DailyPlan get plan => widget.plan;
  DateTime get currentTime => widget.currentTime;
  VoidCallback get onTaskChanged => widget.onTaskChanged;
  ValueChanged<Task> get onFocusToggled => widget.onFocusToggled;
  VoidCallback? get onPlanRequested => widget.onPlanRequested;
  VoidCallback? get onSettingsRequested => widget.onSettingsRequested;

  void openNotificationTask(int index, String name) {
    if (index < 0 || index >= plan.tasks.length) return;
    final task = plan.tasks[index];
    if (task.name == name) _showActions(task);
  }

  bool _canChange(DailyPlan source, Task task) =>
      mounted && identical(source, widget.plan) && source.tasks.contains(task);

  void _dismissModal() {
    final routes = _ownedModals.toList();
    _ownedModals.clear();
    if (routes.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final route in routes) {
        final navigator = route.navigator;
        if (navigator != null && navigator.mounted && route.isActive) {
          navigator.removeRoute(route);
        }
      }
    });
  }

  @override
  void dispose() {
    _undoTimer?.cancel();
    _dismissModal();
    super.dispose();
  }

  Task? _undoTask;
  DailyPlan? _undoPlan;
  Timer? _undoTimer;

  void _undoKept() {
    final task = _undoTask, source = _undoPlan;
    _undoTimer?.cancel();
    setState(() => _undoTask = _undoPlan = null);
    if (task != null &&
        source != null &&
        _canChange(source, task) &&
        task.isCompleted) {
      _applyOutcome(task, TaskOutcome.incomplete, null);
    }
  }

  @override
  void didUpdateWidget(covariant TodayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.plan, widget.plan)) {
      _showAll = false;
      _dismissModal();
    }
  }

  Future<void> _showActions(Task task) async {
    final source = plan;
    if (_openingModal || !_canChange(source, task)) return;
    _openingModal = true;
    try {
      final outcome = await showModalBottomSheet<TaskOutcome>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        constraints: const BoxConstraints(maxWidth: 640),
        builder: (sheetContext) {
          final route = ModalRoute.of(sheetContext);
          if (route != null) _ownedModals.add(route);
          return Theme(
            data: Theme.of(Navigator.of(sheetContext).context),
            child: TaskActionsSheet(
              task: task,
              area: widget.areas?.resolve(task.areaId),
              currentTime: currentTime,
              canChange: () => _canChange(source, task),
            ),
          );
        },
      );
      _ownedModals.removeWhere((route) => !route.isActive);
      if (!mounted || outcome == null || !_canChange(source, task)) return;
      String? reason;
      if (outcome == TaskOutcome.excused) {
        reason = await showDialog<String>(
          context: context,
          builder: (dialogContext) {
            final route = ModalRoute.of(dialogContext);
            if (route != null) _ownedModals.add(route);
            return ExcuseReasonDialog(
              canChange: () => _canChange(source, task),
              initialReason: task.excuseReason,
            );
          },
        );
        _ownedModals.removeWhere((route) => !route.isActive);
        if (reason == null || !_canChange(source, task)) return;
      }
      _applyOutcome(task, outcome, reason);
    } finally {
      _openingModal = false;
    }
  }

  void _applyOutcome(Task task, TaskOutcome outcome, String? reason) {
    final change = widget.onOutcomeChanged;
    if (change != null) {
      change(task, outcome, reason);
    } else {
      task.changeOutcome(outcome, now: currentTime, reason: reason);
      onTaskChanged();
    }
  }

  void _toggleKept(Task task) {
    final source = plan;
    if (!_canChange(source, task)) return;
    final keeping = !task.isCompleted;
    _applyOutcome(
      task,
      keeping ? TaskOutcome.completed : TaskOutcome.incomplete,
      null,
    );
    // A local Undo bar: it never hides the app's own messages (such as a
    // failed save) and it disappears when you leave Today.
    _undoTimer?.cancel();
    setState(() {
      _undoTask = keeping ? task : null;
      _undoPlan = keeping ? source : null;
    });
    if (!keeping) return;
    _undoTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _undoTask = _undoPlan = null);
    });
    SemanticsService.sendAnnouncement(
      View.of(context),
      'Kept ${task.name}',
      Directionality.of(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = plan.progress;
    final empty = plan.tasks.isEmpty;
    final eligibility = _currentFreedom;
    final tomorrow = widget.tomorrowPlan;
    final tomorrowLocked =
        tomorrow != null && tomorrow.isCommitted && tomorrow.tasks.isNotEmpty;
    final earned = eligibility.settings.enabled && eligibility.earned;

    final visible = <Task>[];
    if (_showAll || plan.tasks.length <= 3) {
      visible.addAll(plan.tasks);
    } else {
      final running = plan.tasks
          .where((task) => task.isFocusRunning)
          .firstOrNull;
      visible.addAll(plan.tasks.take(3));
      if (running != null && !visible.contains(running)) {
        visible[2] = running;
        visible.sort(
          (a, b) => plan.tasks.indexOf(a).compareTo(plan.tasks.indexOf(b)),
        );
      }
    }

    final mood = earned
        ? SceneMood.earned
        : empty && tomorrowLocked
        ? SceneMood.night
        : SceneMood.dawn;
    final fraction = summary.fraction ?? 0;
    final recorded = plan.tasks.fold<int>(
      0,
      (total, task) => total + task.focusMillisecondsAt(currentTime),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth < 360
            ? DaylockSpace.md
            : DaylockSpace.lg;
        Widget section(Widget child) => Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: child,
            ),
          ),
        );
        final content = SingleChildScrollView(
          key: const ValueKey('today-content'),
          padding: EdgeInsets.only(bottom: _undoTask == null ? 32 : 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DaylockSkyHeader(
                mood: mood,
                progress: empty ? 0 : fraction,
                height: earned ? 400 : 262,
                horizontalPadding: padding,
                title: 'Today',
                subtitle: daylockDateLabel(plan.date),
                actions: [
                  if (onSettingsRequested != null)
                    DaylockSkyButton(
                      buttonKey: const ValueKey('open-settings'),
                      icon: Icons.settings_outlined,
                      tooltip: 'Settings',
                      onPressed: onSettingsRequested,
                    ),
                ],
                bottom: earned
                    ? _EarnedHeadline(
                        eligibility: eligibility,
                        onTap: () =>
                            setState(() => _freedomOpen = !_freedomOpen),
                      )
                    : empty
                    ? null
                    : _ProgressHeadline(
                        summary: summary,
                        recordedMilliseconds: recorded,
                      ),
              ),
              if (widget.notice != null) section(widget.notice!),
              if (earned)
                section(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tomorrowLocked
                              ? 'You kept your word and ${daylockWeekday(tomorrow.date)} is already committed. Enjoy it.'
                              : 'You kept your word. Enjoy it.',
                          style: theme.textTheme.bodyLarge!.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (_freedomOpen)
                          Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: _FreedomDetails(eligibility: eligibility),
                          ),
                      ],
                    ),
                  ),
                ),
              if (empty)
                section(
                  _EmptyToday(
                    tomorrow: tomorrowLocked ? tomorrow : null,
                    areas: widget.areas,
                    onPlanRequested: onPlanRequested,
                  ),
                ),
              if (!earned)
                section(
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _FreedomStrip(
                      eligibility: eligibility,
                      empty: empty,
                      open: _freedomOpen,
                      onToggle: () =>
                          setState(() => _freedomOpen = !_freedomOpen),
                      onTurnOn:
                          widget.onFreedomRequested ?? onSettingsRequested,
                    ),
                  ),
                ),
              if (!empty)
                section(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DaylockSectionHeader(
                        title: 'Commitments',
                        padding: EdgeInsets.fromLTRB(0, earned ? 4 : 24, 0, 10),
                      ),
                      DaylockGroup(
                        children: [
                          for (final task in visible)
                            Semantics(
                              customSemanticsActions: {
                                const CustomSemanticsAction(
                                  label: 'Task actions',
                                ): () =>
                                    _showActions(task),
                              },
                              child: DaylockTaskRow(
                                key: ObjectKey(task),
                                task: task,
                                currentTime: currentTime,
                                area: widget.areas?.resolve(task.areaId),
                                onGoalChanged: () => _toggleKept(task),
                                onFocusToggled: () => onFocusToggled(task),
                                onDetailsRequested: () => _showActions(task),
                              ),
                            ),
                        ],
                      ),
                      if (plan.tasks.length > 3)
                        Center(
                          child: TextButton.icon(
                            key: const ValueKey('today-expand'),
                            onPressed: () =>
                                setState(() => _showAll = !_showAll),
                            icon: Icon(
                              _showAll ? Icons.expand_less : Icons.expand_more,
                            ),
                            label: Text(
                              _showAll
                                  ? 'Show fewer commitments'
                                  : 'Show all ${plan.tasks.length} commitments',
                            ),
                          ),
                        ),
                      if (summary.excusedCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${summary.excusedCount} excused',
                            key: const ValueKey('today-excused-count'),
                            style: theme.textTheme.bodySmall!.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
        final undo = _undoTask;
        return Stack(
          children: [
            content,
            if (undo != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: SafeArea(
                  top: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: _UndoBar(
                        key: const ValueKey('kept-snackbar'),
                        name: undo.name,
                        onUndo: _undoKept,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _UndoBar extends StatelessWidget {
  final String name;
  final VoidCallback onUndo;
  const _UndoBar({super.key, required this.name, required this.onUndo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final background = dark ? const Color(0xFFF1E9FF) : const Color(0xFF241A42);
    final foreground = dark ? const Color(0xFF1D1036) : const Color(0xFFF5F1FF);
    final action = dark ? const Color(0xFF5B2FB0) : const Color(0xFFD9BFFF);
    return Semantics(
      liveRegion: true,
      container: true,
      child: Material(
        color: background,
        elevation: 6,
        shadowColor: Colors.black54,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: daylockGold(Brightness.dark),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 15,
                  color: Color(0xFF3A1D05),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Kept: $name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    fontSize: 15,
                    color: foreground,
                  ),
                ),
              ),
              TextButton(
                onPressed: onUndo,
                style: TextButton.styleFrom(foregroundColor: action),
                child: const Text('Undo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _timedLabel(int milliseconds) {
  final seconds = milliseconds ~/ 1000;
  final hours = seconds ~/ 3600;
  final minutes = seconds ~/ 60 % 60;
  return hours > 0
      ? '${hours}h ${minutes}m'
      : minutes > 0
      ? '${minutes}m ${seconds % 60}s'
      : '${seconds}s';
}

class _ProgressHeadline extends StatelessWidget {
  final CommitmentProgress summary;
  final int recordedMilliseconds;
  const _ProgressHeadline({
    required this.summary,
    required this.recordedMilliseconds,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sky = SceneColors.of(theme);
    final neutral = summary.isNeutral;
    final headline = neutral
        ? 'No eligible commitments'
        : '${summary.completedCount} of ${summary.eligibleCount} kept';
    final remaining = summary.remainingCount;
    final status = neutral
        ? 'Excused commitments don’t count'
        : summary.isComplete
        ? 'Day complete'
        : remaining == 1
        ? '1 more and the sun is up'
        : '$remaining more and the sun is up';
    final timed = recordedMilliseconds > 0
        ? ' · ${_timedLabel(recordedMilliseconds)} timed'
        : '';
    final fraction = summary.fraction;
    return Semantics(
      key: const ValueKey('daily-summary'),
      container: true,
      label: neutral ? 'No eligible commitments' : 'Commitments complete',
      value: '${((fraction ?? 0) * 100).round()}%',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headline,
            style: theme.textTheme.headlineMedium!.copyWith(color: sky.onSky),
          ),
          const SizedBox(height: 2),
          Text(
            '$status$timed',
            key: const ValueKey('today-recorded-time'),
            style: theme.textTheme.bodyMedium!.copyWith(
              color: sky.onSkyMuted,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

/// The conditions plus where app restrictions live.
class _FreedomDetails extends StatelessWidget {
  final FreedomEligibility eligibility;
  const _FreedomDetails({required this.eligibility});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('freedom-details'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FreedomConditions(eligibility: eligibility),
        const SizedBox(height: 6),
        Text(
          'App restrictions are configured in Settings.',
          style: theme.textTheme.bodySmall!.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _EarnedHeadline extends StatelessWidget {
  final FreedomEligibility eligibility;
  final VoidCallback onTap;
  const _EarnedHeadline({required this.eligibility, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sky = SceneColors.of(theme);
    return Tooltip(
      key: const ValueKey('freedom-indicator'),
      message: 'Freedom earned',
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        hint: 'Show Freedom details',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(
            key: const ValueKey('freedom-earned-headline'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: sky.dark
                      ? Colors.black.withValues(alpha: .25)
                      : Colors.white.withValues(alpha: .6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_open_rounded, size: 16, color: sky.onSky),
                    const SizedBox(width: 6),
                    Text(
                      'Apps unlocked at ${eligibility.settings.timeLabel}',
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: sky.onSky,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Freedom earned.',
                style: theme.textTheme.displayLarge!.copyWith(
                  fontSize: 44,
                  color: sky.onSky,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FreedomStrip extends StatelessWidget {
  final FreedomEligibility eligibility;
  final bool empty, open;
  final VoidCallback onToggle;
  final VoidCallback? onTurnOn;
  const _FreedomStrip({
    required this.eligibility,
    required this.empty,
    required this.open,
    required this.onToggle,
    this.onTurnOn,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enabled = eligibility.settings.enabled;
    final time = eligibility.settings.timeLabel;
    final tooltip = !enabled
        ? 'Freedom Control is off'
        : eligibility.earned
        ? 'Freedom earned'
        : 'Freedom not yet earned';
    final String title, detail;
    if (!enabled) {
      title = 'Freedom Control is off';
      detail = 'Earn your apps back by keeping your word.';
    } else if (!eligibility.hasEligibleCommitments) {
      title = 'Apps stay locked today';
      detail = 'An empty day doesn’t earn Freedom. Commit a plan for tomorrow.';
    } else if (!eligibility.commitmentsCompleted) {
      final left = eligibility.eligibleCount - eligibility.completedCount;
      title = 'Apps unlock at $time';
      detail = left == 1
          ? 'Keep 1 more to earn it'
          : 'Keep $left more to earn it';
    } else if (!eligibility.tomorrowCommitted) {
      title = 'Apps unlock at $time';
      detail = 'Commit tomorrow’s plan to earn it';
    } else {
      title = 'Waiting for Freedom Time';
      detail = 'Everything’s kept. Apps unlock at $time';
    }
    return Tooltip(
      key: const ValueKey('freedom-indicator'),
      message: tooltip,
      excludeFromSemantics: true,
      child: DaylockGroup(
        key: const ValueKey('freedom-status'),
        color: enabled
            ? Color.alphaBlend(
                scheme.primary.withValues(
                  alpha: theme.brightness == Brightness.dark ? .14 : .10,
                ),
                scheme.surfaceContainerLow,
              )
            : null,
        children: [
          InkWell(
            onTap: enabled ? onToggle : onTurnOn,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact =
                      constraints.maxWidth < 270 ||
                      MediaQuery.textScalerOf(context).scale(1) > 1.3;
                  final turnOn = FilledButton.tonal(
                    key: const ValueKey('freedom-turn-on'),
                    onPressed: onTurnOn,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(48, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      backgroundColor: scheme.primary.withValues(alpha: .22),
                      foregroundColor: scheme.onSurface,
                    ),
                    child: const Text('Turn on'),
                  );
                  final text = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        key: const ValueKey('freedom-title'),
                        style: theme.textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (enabled || empty)
                        Text(
                          detail,
                          style: theme.textTheme.bodyMedium!.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      if (!enabled && compact)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: turnOn,
                        ),
                    ],
                  );
                  return Row(
                    children: [
                      DaylockIconTile(
                        icon: enabled
                            ? Icons.lock_rounded
                            : Icons.lock_outline_rounded,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: text),
                      if (!enabled && !compact)
                        turnOn
                      else if (enabled)
                        Icon(
                          open
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          semanticLabel: open
                              ? 'Hide Freedom details'
                              : 'Show Freedom details',
                          color: scheme.onSurfaceVariant,
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          if (enabled && open)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: _FreedomDetails(eligibility: eligibility),
            ),
        ],
      ),
    );
  }
}

class _EmptyToday extends StatelessWidget {
  final DailyPlan? tomorrow;
  final AreaBook? areas;
  final VoidCallback? onPlanRequested;
  const _EmptyToday({this.tomorrow, this.areas, this.onPlanRequested});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locked = tomorrow;
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            locked == null
                ? 'A clear day.'
                : 'All set for ${daylockWeekday(locked.date)}.',
            style: theme.textTheme.headlineLarge,
          ),
          const SizedBox(height: DaylockSpace.sm),
          Text(
            locked == null
                ? 'No commitments for today. Plan tomorrow, and tomorrow’s sun is yours to raise.'
                : 'Nothing planned today, and tomorrow is locked in. Rest is the plan.',
            style: theme.textTheme.bodyLarge!.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (locked != null) ...[
            const SizedBox(height: 18),
            DaylockGroup(
              key: const ValueKey('tomorrow-locked'),
              children: [
                ListTile(
                  leading: DaylockIconTile(
                    icon: Icons.lock_rounded,
                    color: scheme.primary,
                    size: 36,
                  ),
                  title: Text(
                    '${daylockWeekday(locked.date)}’s ${locked.tasks.length}',
                    style: theme.textTheme.titleLarge,
                  ),
                  trailing: onPlanRequested == null
                      ? null
                      : TextButton(
                          onPressed: onPlanRequested,
                          child: const Text('View'),
                        ),
                ),
                for (final task in locked.tasks.take(5))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: areas == null
                                ? scheme.primary
                                : AreaTones.forContext(
                                    context,
                                    Color(areas!.resolve(task.areaId).colour),
                                  ).ink,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            task.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ] else if (onPlanRequested != null) ...[
            const SizedBox(height: DaylockSpace.lg),
            DaylockAction(
              label: 'Plan tomorrow',
              icon: Icons.arrow_forward_rounded,
              onPressed: onPlanRequested,
            ),
          ],
        ],
      ),
    );
  }
}

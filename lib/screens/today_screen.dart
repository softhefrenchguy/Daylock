import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../design/daylock_task_row.dart';
import '../design/daylock_theme.dart';
import '../design/daylock_widgets.dart';
import '../models/daily_plan.dart';
import '../models/task.dart';
import '../models/area.dart';
import '../design/daily_progress_card.dart';
import 'task_actions_sheet.dart';
import '../services/freedom_service.dart';
import '../models/freedom_settings.dart';
import '../design/daylock_freedom_status.dart';

class TodayScreen extends StatefulWidget {
  final DailyPlan plan;
  final AreaBook? areas;
  final VoidCallback onTaskChanged;
  final ValueChanged<Task> onFocusToggled;
  final VoidCallback? onPlanRequested;
  final VoidCallback? onSettingsRequested;
  final DateTime currentTime;
  final FreedomEligibility? freedomEligibility;
  final void Function(Task task, TaskOutcome outcome, String? reason)?
  onOutcomeChanged;

  const TodayScreen({
    super.key,
    required this.plan,
    this.areas,
    required this.onTaskChanged,
    required this.onFocusToggled,
    required this.currentTime,
    this.onPlanRequested,
    this.onSettingsRequested,
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
  final GlobalKey _freedomCard = GlobalKey();
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
    _dismissModal();
    super.dispose();
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
      final change = widget.onOutcomeChanged;
      if (change != null) {
        change(task, outcome, reason);
      } else {
        task.changeOutcome(outcome, now: currentTime, reason: reason);
        onTaskChanged();
      }
    } finally {
      _openingModal = false;
    }
  }

  void _showFreedom() {
    final target = _freedomCard.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: daylockMotion(context),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final now = plan.date;
    const weekdays = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ];
    const months = [
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER',
    ];
    final summary = plan.progress;
    final empty = plan.tasks.isEmpty;
    final eligibility = _currentFreedom;
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
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = constraints.maxWidth < 360
              ? DaylockSpace.md
              : DaylockSpace.lg;
          return SingleChildScrollView(
            key: const ValueKey('today-content'),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 640,
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(padding, 12, padding, 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${weekdays[now.weekday - 1]} ${now.day} ${months[now.month - 1]}',
                        style: theme.textTheme.labelLarge!.copyWith(
                          color: colors.primary,
                          fontSize: 13,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              header: true,
                              child: Text(
                                'Today',
                                style: theme.textTheme.headlineLarge!.copyWith(
                                  fontSize: 36,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            key: const ValueKey('freedom-indicator'),
                            tooltip: !eligibility.settings.enabled
                                ? 'Freedom Control is off'
                                : eligibility.earned
                                ? 'Freedom earned'
                                : 'Freedom not yet earned',
                            onPressed: _showFreedom,
                            icon: Icon(
                              !eligibility.settings.enabled
                                  ? Icons.lock_outline_rounded
                                  : eligibility.earned
                                  ? Icons.lock_open_rounded
                                  : Icons.lock_rounded,
                              color: eligibility.settings.enabled
                                  ? colors.primary
                                  : colors.onSurfaceVariant,
                            ),
                          ),
                          if (onSettingsRequested != null)
                            IconButton(
                              key: const ValueKey('open-settings'),
                              tooltip: 'Settings',
                              onPressed: onSettingsRequested,
                              icon: const Icon(Icons.settings_outlined),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DailyProgressCard(
                        progress: summary,
                        recordedMilliseconds: plan.tasks.fold<int>(
                          0,
                          (total, task) =>
                              total + task.focusMillisecondsAt(currentTime),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your commitments',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      if (empty)
                        _EmptyToday(onPlanRequested: onPlanRequested)
                      else ...[
                        for (final task in visible)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Semantics(
                              customSemanticsActions: {
                                const CustomSemanticsAction(
                                  label: 'Task actions',
                                ): () =>
                                    _showActions(task),
                              },
                              child: GestureDetector(
                                onLongPress: () => _showActions(task),
                                child: DaylockTaskRow(
                                  key: ObjectKey(task),
                                  task: task,
                                  currentTime: currentTime,
                                  area: widget.areas?.resolve(task.areaId),
                                  onGoalChanged: () {
                                    final outcome = task.isCompleted
                                        ? TaskOutcome.incomplete
                                        : TaskOutcome.completed;
                                    if (widget.onOutcomeChanged != null) {
                                      widget.onOutcomeChanged!(
                                        task,
                                        outcome,
                                        null,
                                      );
                                    } else {
                                      task.changeOutcome(
                                        outcome,
                                        now: currentTime,
                                      );
                                      onTaskChanged();
                                    }
                                  },
                                  onFocusToggled: () => onFocusToggled(task),
                                  onDetailsRequested: () => _showActions(task),
                                ),
                              ),
                            ),
                          ),
                        if (plan.tasks.length > 3)
                          Center(
                            child: TextButton.icon(
                              key: const ValueKey('today-expand'),
                              onPressed: () =>
                                  setState(() => _showAll = !_showAll),
                              icon: Icon(
                                _showAll
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                              ),
                              label: Text(
                                _showAll
                                    ? 'Show fewer commitments'
                                    : 'Show all ${plan.tasks.length} commitments',
                              ),
                            ),
                          ),
                      ],
                      const SizedBox(height: 8),
                      KeyedSubtree(
                        key: _freedomCard,
                        child: DaylockFreedomStatus(eligibility: eligibility),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyToday extends StatelessWidget {
  final VoidCallback? onPlanRequested;
  const _EmptyToday({this.onPlanRequested});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DaylockSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.wb_sunny_outlined,
            color: theme.colorScheme.primary,
            size: 32,
          ),
          const SizedBox(height: DaylockSpace.md),
          Text('A clear day.', style: theme.textTheme.headlineLarge),
          const SizedBox(height: DaylockSpace.sm),
          Text(
            'No commitments for today.\nMake a deliberate plan for tomorrow.',
            style: theme.textTheme.bodyLarge!.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (onPlanRequested != null) ...[
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

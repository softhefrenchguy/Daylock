import 'package:flutter/material.dart';

import '../design/daylock_palette.dart';
import '../design/daylock_plan_rows.dart';
import '../design/daylock_theme.dart';
import '../design/daylock_widgets.dart';
import '../models/calendar_cache.dart';
import '../models/daily_plan.dart';
import '../models/event.dart';
import '../models/task.dart';
import '../models/area.dart';
import '../design/daylock_areas.dart';
import 'commitment_editor.dart';
import '../models/routine.dart';
import '../services/routine_service.dart';
import '../design/daylock_routine_suggestions.dart';

class PlanScreen extends StatefulWidget {
  final DailyPlan plan;
  final AreaBook? areas;
  final void Function(Task, String)? onTaskAreaChanged;
  final List<Event> events;
  final CalendarCache? calendarCache;
  final ValueChanged<Task> onTaskCreated;
  final VoidCallback onCommitTomorrow;
  final List<RoutineSuggestion> routineSuggestions;
  final void Function(RoutineSuggestion, RoutineAction)? onRoutineAction;
  const PlanScreen({
    super.key,
    required this.plan,
    this.areas,
    this.onTaskAreaChanged,
    this.events = const [],
    this.calendarCache,
    required this.onTaskCreated,
    required this.onCommitTomorrow,
    this.routineSuggestions = const [],
    this.onRoutineAction,
  });

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  ModalRoute<dynamic>? _activeModal;
  bool _openingModal = false;

  bool _editable(DailyPlan plan) =>
      mounted && identical(widget.plan, plan) && !plan.isCommitted;

  void _dismissModal() {
    final route = _activeModal;
    _activeModal = null;
    if (route == null) return;
    // Rollover/disposal can happen during a build. Close only our exact route.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = route.navigator;
      if (navigator != null && navigator.mounted && route.isActive) {
        navigator.removeRoute(route);
      }
    });
  }

  @override
  void dispose() {
    _dismissModal();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PlanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.plan, widget.plan) || widget.plan.isCommitted) {
      _dismissModal();
    }
  }

  Future<void> _addCommitment() async {
    final plan = widget.plan;
    if (!_editable(plan) || _openingModal) return;
    _openingModal = true;
    final task = await showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (sheetContext) {
        _activeModal = ModalRoute.of(sheetContext);
        // Follow the app theme even if system appearance changes with the sheet open.
        return Theme(
          data: Theme.of(Navigator.of(sheetContext).context),
          child: CommitmentEditor(
            canCreate: () => _editable(plan),
            areas: widget.areas,
          ),
        );
      },
    );
    _activeModal = null;
    _openingModal = false;
    if (task == null || !_editable(plan)) return;
    widget.onTaskCreated(task);
  }

  Future<void> _changeArea(Task task) async {
    final plan = widget.plan;
    if (!_editable(plan) || _openingModal || !plan.tasks.contains(task)) return;
    _openingModal = true;
    final id = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (sheetContext) {
        _activeModal = ModalRoute.of(sheetContext);
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DaylockSpace.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Area for ${task.name}',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                AreaChoices(
                  book: widget.areas ?? AreaBook.initial(),
                  selectedId: task.areaId,
                  onSelected: (id) {
                    if (_editable(plan) && plan.tasks.contains(task)) {
                      Navigator.pop(sheetContext, id);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
    _activeModal = null;
    _openingModal = false;
    if (id != null && _editable(plan) && plan.tasks.contains(task)) {
      widget.onTaskAreaChanged?.call(task, id);
    }
  }

  Future<void> _confirmCommit() async {
    final plan = widget.plan;
    if (!_editable(plan) || plan.tasks.isEmpty || _openingModal) return;
    _openingModal = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        _activeModal = ModalRoute.of(dialogContext);
        return AlertDialog(
          scrollable: true,
          title: const Text('Commit tomorrow?'),
          content: const Text(
            'This locks tomorrow’s commitments. You won’t be able to add or change them.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (dialogContext.mounted &&
                    ModalRoute.of(dialogContext)?.isCurrent == true) {
                  Navigator.of(dialogContext).pop(false);
                }
              },
              child: const Text('Keep planning'),
            ),
            FilledButton(
              key: const ValueKey('confirm-commit'),
              onPressed: () {
                if (dialogContext.mounted &&
                    ModalRoute.of(dialogContext)?.isCurrent == true &&
                    _editable(plan)) {
                  Navigator.of(dialogContext).pop(true);
                }
              },
              child: const Text('Commit'),
            ),
          ],
        );
      },
    );
    _activeModal = null;
    _openingModal = false;
    if (confirmed == true && _editable(plan) && plan.tasks.isNotEmpty) {
      widget.onCommitTomorrow();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final plan = widget.plan;
    final scheduled = Event.forDate(widget.events, plan.date);
    const weekdays = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ];
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = constraints.maxWidth < 360
              ? DaylockSpace.md
              : DaylockSpace.lg;
          return Column(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: CustomScrollView(
                      key: const ValueKey('plan-content'),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            padding,
                            DaylockSpace.md,
                            padding,
                            DaylockSpace.md,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Semantics(
                                  header: true,
                                  child: Text(
                                    'Plan',
                                    style: theme.textTheme.headlineLarge!
                                        .copyWith(fontSize: 40),
                                  ),
                                ),
                                const SizedBox(height: DaylockSpace.xs),
                                Text(
                                  'Tomorrow · ${MaterialLocalizations.of(context).formatFullDate(plan.date)}',
                                  style: theme.textTheme.bodyMedium!.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: DaylockSpace.lg),
                                if (!plan.isCommitted &&
                                    widget.routineSuggestions.isNotEmpty &&
                                    widget.onRoutineAction != null) ...[
                                  DaylockRoutineSuggestions(
                                    areas: widget.areas,
                                    suggestions: widget.routineSuggestions,
                                    onAction: (suggestion, action) {
                                      if (_editable(plan)) {
                                        widget.onRoutineAction!(
                                          suggestion,
                                          action,
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(height: DaylockSpace.md),
                                ],
                                const DaylockLabel('SCHEDULE'),
                                if (scheduled.isEmpty) ...[
                                  const SizedBox(height: DaylockSpace.sm),
                                  Text(
                                    'No scheduled events for tomorrow.',
                                    style: theme.textTheme.bodyMedium!.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: padding),
                          sliver: SliverList.builder(
                            itemCount: scheduled.length,
                            itemBuilder: (context, index) =>
                                DaylockPlanEventRow(
                                  event: scheduled[index],
                                  date: plan.date,
                                ),
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            padding,
                            DaylockSpace.lg,
                            padding,
                            DaylockSpace.sm,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    const Expanded(
                                      child: DaylockLabel('COMMITMENTS'),
                                    ),
                                    Text(
                                      '${plan.tasks.length}',
                                      style: theme.textTheme.labelLarge,
                                    ),
                                  ],
                                ),
                                if (!plan.isCommitted) ...[
                                  const SizedBox(height: DaylockSpace.sm),
                                  OutlinedButton(
                                    key: const ValueKey(
                                      'open-commitment-editor',
                                    ),
                                    onPressed: _addCommitment,
                                    child: const Text('+ Add commitment'),
                                  ),
                                ],
                                if (plan.tasks.isEmpty) ...[
                                  const SizedBox(height: DaylockSpace.md),
                                  Text(
                                    'No commitments planned yet.',
                                    style: theme.textTheme.bodyMedium!.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            padding,
                            0,
                            padding,
                            DaylockSpace.md,
                          ),
                          sliver: SliverList.builder(
                            itemCount: plan.tasks.length,
                            itemBuilder: (context, index) => Column(
                              key: ValueKey('plan-task-$index'),
                              children: [
                                DaylockPlanTaskRow(task: plan.tasks[index]),
                                if (widget.areas != null)
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child:
                                        !plan.isCommitted &&
                                            widget.onTaskAreaChanged != null
                                        ? TextButton(
                                            key: ValueKey(
                                              'edit-task-area-$index',
                                            ),
                                            onPressed: () =>
                                                _changeArea(plan.tasks[index]),
                                            child: AreaBadge(
                                              area: widget.areas!.resolve(
                                                plan.tasks[index].areaId,
                                              ),
                                            ),
                                          )
                                        : AreaBadge(
                                            area: widget.areas!.resolve(
                                              plan.tasks[index].areaId,
                                            ),
                                          ),
                                  ),
                                const Divider(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // This takes layout space rather than overlaying the last row. Its own
              // scroll view keeps actions reachable at extreme text/keyboard sizes.
              ConstrainedBox(
                key: const ValueKey('plan-commit-bar'),
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight * .5,
                ),
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border(
                        top: BorderSide(color: colors.outlineVariant),
                      ),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: padding,
                            vertical: 12,
                          ),
                          child: plan.isCommitted
                              ? const _CommittedPlan()
                              : DaylockAction(
                                  key: const ValueKey('commit-tomorrow'),
                                  label:
                                      'COMMIT ${weekdays[plan.date.weekday - 1]}',
                                  icon: Icons.lock_outline_rounded,
                                  onPressed: plan.tasks.isEmpty
                                      ? null
                                      : _confirmCommit,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CommittedPlan extends StatelessWidget {
  const _CommittedPlan();
  @override
  Widget build(BuildContext context) {
    final colors = DaylockColors.of(context);
    return Container(
      key: const ValueKey('committed-plan'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.statusSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: colors.statusAccent,
            size: DaylockSpace.icon,
          ),
          const SizedBox(width: DaylockSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tomorrow's plan is committed.",
                  style: Theme.of(context).textTheme.labelLarge!
                      .copyWith(color: colors.onStatus),
                ),
                Text(
                  'Your commitments are locked.',
                  style: Theme.of(context).textTheme.bodySmall!
                      .copyWith(color: colors.onStatusMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

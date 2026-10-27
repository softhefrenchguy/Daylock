import 'package:flutter/material.dart';

import '../design/daylock_palette.dart';
import '../design/journey_surface.dart';
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
  final void Function(Task, Task)? onTaskEdited;
  final ValueChanged<Task>? onTaskRemoved;
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
    this.onTaskEdited,
    this.onTaskRemoved,
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

  Future<void> _editCommitment(Task task) async {
    final plan = widget.plan;
    if (!_editable(plan) || _openingModal || !plan.tasks.contains(task)) return;
    _openingModal = true;
    final edited = await showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (sheetContext) {
        _activeModal = ModalRoute.of(sheetContext);
        return Theme(
          data: Theme.of(Navigator.of(sheetContext).context),
          child: CommitmentEditor(
            initialTask: task,
            areas: widget.areas,
            heading: 'Edit commitment',
            submitLabel: 'Save changes',
            canCreate: () => _editable(plan) && plan.tasks.contains(task),
          ),
        );
      },
    );
    _activeModal = null;
    _openingModal = false;
    if (edited != null && _editable(plan) && plan.tasks.contains(task)) {
      widget.onTaskEdited?.call(task, edited);
    }
  }

  Future<void> _removeCommitment(Task task) async {
    final plan = widget.plan;
    if (!_editable(plan) || _openingModal || !plan.tasks.contains(task)) return;
    _openingModal = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        _activeModal = ModalRoute.of(dialogContext);
        return AlertDialog(
          title: const Text('Remove commitment?'),
          content: Text('Remove ${task.name} from tomorrow?s draft?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const ValueKey('confirm-remove-commitment'),
              onPressed: () {
                if (_editable(plan) && plan.tasks.contains(task)) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
    _activeModal = null;
    _openingModal = false;
    if (confirmed == true && _editable(plan) && plan.tasks.contains(task)) {
      widget.onTaskRemoved?.call(task);
    }
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
                              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                const SizedBox(height: DaylockSpace.xs),
                                Text(
                                  plan.isCommitted ? 'Committed' : 'Draft',
                                  style: theme.textTheme.labelMedium!.copyWith(
                                    color: colors.primary,
                                  ),
                                ),
                                const SizedBox(height: DaylockSpace.md),
                                if (!plan.isCommitted &&
                                    widget.routineSuggestions.isNotEmpty &&
                                    widget.onRoutineAction != null) ...[
                                  JourneySurface(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      child: DaylockRoutineSuggestions(
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
                                    ),
                                  ),
                                  const SizedBox(height: DaylockSpace.md),
                                ],
                                JourneySurface(
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.event_outlined,
                                              color: colors.primary,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 10),
                                            const Expanded(
                                              child: DaylockLabel('SCHEDULE'),
                                            ),
                                          ],
                                        ),
                                        if (scheduled.isEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            'No scheduled events for tomorrow.',
                                            style: theme.textTheme.bodyMedium!
                                                .copyWith(
                                                  color:
                                                      colors.onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: padding),
                          sliver: SliverList.builder(
                            itemCount: scheduled.length,
                            itemBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: JourneySurface(
                                radius: 14,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: DaylockPlanEventRow(
                                    event: scheduled[index],
                                    date: plan.date,
                                  ),
                                ),
                              ),
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
                                Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 12,
                                  children: [
                                    Wrap(
                                      spacing: 8,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        const DaylockLabel('COMMITMENTS'),
                                        Text(
                                          '${plan.tasks.length}',
                                          style: theme.textTheme.labelLarge,
                                        ),
                                      ],
                                    ),
                                    if (!plan.isCommitted && plan.tasks.isEmpty)
                                      FilledButton(
                                        key: const ValueKey(
                                          'open-commitment-editor',
                                        ),
                                        onPressed: _addCommitment,
                                        child: const Text('+ Add commitment'),
                                      )
                                    else if (!plan.isCommitted)
                                      TextButton(
                                        key: const ValueKey(
                                          'open-commitment-editor',
                                        ),
                                        onPressed: _addCommitment,
                                        child: const Text('+ Add commitment'),
                                      ),
                                  ],
                                ),
                                if (plan.tasks.isEmpty) ...[
                                  const SizedBox(height: 8),
                                  JourneySurface(
                                    radius: 16,
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        children: [
                                          ExcludeSemantics(
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: RadialGradient(
                                                  colors: [
                                                    colors.primary.withValues(
                                                      alpha: .3,
                                                    ),
                                                    colors.primary.withValues(
                                                      alpha: .05,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.edit_calendar_rounded,
                                                color: colors.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'No commitments planned yet.',
                                                  style: theme
                                                      .textTheme
                                                      .titleSmall,
                                                ),
                                                Text(
                                                  plan.isCommitted
                                                      ? 'Tomorrow is locked.'
                                                      : 'Add one small step for tomorrow.',
                                                  style: theme
                                                      .textTheme
                                                      .bodySmall!
                                                      .copyWith(
                                                        color: colors
                                                            .onSurfaceVariant,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
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
                            itemBuilder: (context, index) {
                              final task = plan.tasks[index];
                              final selectedArea = widget.areas?.resolve(
                                task.areaId,
                              );
                              final areaName = selectedArea == null
                                  ? null
                                  : '${selectedArea.name}${selectedArea.isArchived ? ' (archived)' : ''}';
                              return Padding(
                                key: ValueKey('plan-task-$index'),
                                padding: const EdgeInsets.only(bottom: 8),
                                child: JourneySurface(
                                  radius: 16,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      0,
                                      8,
                                      8,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: DaylockPlanTaskRow(
                                                task: task,
                                                area: selectedArea,
                                                areaAction: widget.areas == null
                                                    ? null
                                                    : !plan.isCommitted &&
                                                          widget.onTaskAreaChanged !=
                                                              null
                                                    ? TextButton(
                                                        key: ValueKey(
                                                          'edit-task-area-$index',
                                                        ),
                                                        onPressed: () =>
                                                            _changeArea(task),
                                                        style:
                                                            TextButton.styleFrom(
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              minimumSize:
                                                                  const Size(
                                                                    48,
                                                                    36,
                                                                  ),
                                                              alignment: Alignment
                                                                  .centerLeft,
                                                              visualDensity:
                                                                  VisualDensity
                                                                      .compact,
                                                            ),
                                                        child: Text(
                                                          areaName!,
                                                          style: theme
                                                              .textTheme
                                                              .bodySmall!
                                                              .copyWith(
                                                                color: colors
                                                                    .onSurfaceVariant,
                                                              ),
                                                        ),
                                                      )
                                                    : Text(
                                                        areaName!,
                                                        style: theme
                                                            .textTheme
                                                            .bodySmall!
                                                            .copyWith(
                                                              color: colors
                                                                  .onSurfaceVariant,
                                                            ),
                                                      ),
                                              ),
                                            ),
                                            if (!plan.isCommitted &&
                                                (widget.onTaskEdited != null ||
                                                    widget.onTaskRemoved !=
                                                        null))
                                              PopupMenuButton<String>(
                                                key: ValueKey(
                                                  'plan-task-actions-$index',
                                                ),
                                                tooltip:
                                                    'Actions for ${task.name}',
                                                onSelected: (action) {
                                                  if (action == 'edit') {
                                                    _editCommitment(task);
                                                  }
                                                  if (action == 'remove') {
                                                    _removeCommitment(task);
                                                  }
                                                },
                                                itemBuilder: (_) => [
                                                  if (widget.onTaskEdited !=
                                                      null)
                                                    const PopupMenuItem(
                                                      value: 'edit',
                                                      child: Text(
                                                        'Edit commitment',
                                                      ),
                                                    ),
                                                  if (widget.onTaskRemoved !=
                                                      null)
                                                    const PopupMenuItem(
                                                      value: 'remove',
                                                      child: Text(
                                                        'Remove commitment',
                                                      ),
                                                    ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
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

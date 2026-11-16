import '../l10n/l10n.dart';

import 'package:flutter/material.dart';

import '../design/area_tones.dart';
import '../design/daylock_scene.dart';
import '../design/daylock_surfaces.dart';
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
import 'today_screen.dart' show daylockDateLabel, daylockWeekday;
import '../models/routine.dart';

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
  final RoutineBook routines;

  /// Repeat was changed in the editor for [Task]; a null schedule is Never.
  /// Called after [onTaskCreated] / [onTaskEdited] for the same task.
  final void Function(Task, RoutineSchedule?)? onRepeatChanged;
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
    this.routines = RoutineBook.empty,
    this.onRepeatChanged,
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
    var repeatChanged = false;
    RoutineSchedule? repeat;
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
            repeatFrom: widget.onRepeatChanged == null ? null : plan.date,
            onRepeatChanged: (schedule) {
              repeatChanged = true;
              repeat = schedule;
            },
          ),
        );
      },
    );
    _activeModal = null;
    _openingModal = false;
    if (task == null || !_editable(plan)) return;
    widget.onTaskCreated(task);
    if (repeatChanged && plan.tasks.contains(task)) {
      widget.onRepeatChanged?.call(task, repeat);
    }
  }

  Future<void> _editCommitment(Task task) async {
    final plan = widget.plan;
    if (!_editable(plan) || _openingModal || !plan.tasks.contains(task)) return;
    _openingModal = true;
    final routine = widget.routines.byId(task.routineId);
    var repeatChanged = false;
    RoutineSchedule? repeat;
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
            heading: sheetContext.l10n.editCommitment,
            submitLabel: sheetContext.l10n.saveChanges,
            canCreate: () => _editable(plan) && plan.tasks.contains(task),
            repeatFrom: widget.onRepeatChanged == null ? null : plan.date,
            initialRepeat: routine?.schedule,
            rotationName: routine != null && routine.isRotation
                ? routine.name
                : null,
            onRepeatChanged: (schedule) {
              repeatChanged = true;
              repeat = schedule;
            },
          ),
        );
      },
    );
    _activeModal = null;
    _openingModal = false;
    if (edited != null && _editable(plan) && plan.tasks.contains(task)) {
      widget.onTaskEdited?.call(task, edited);
      if (repeatChanged && plan.tasks.contains(edited)) {
        widget.onRepeatChanged?.call(edited, repeat);
      }
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
          title: Text(dialogContext.l10n.removeCommitmentTitle),
          content: Text(dialogContext.l10n.removeFromDraft(task.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(dialogContext.l10n.cancel),
            ),
            FilledButton(
              key: const ValueKey('confirm-remove-commitment'),
              onPressed: () {
                if (_editable(plan) && plan.tasks.contains(task)) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: Text(dialogContext.l10n.remove),
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
                  sheetContext.l10n.areaFor(task.name),
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
          title: Text(
            dialogContext.l10n.lockInWeekdayQuestion(daylockWeekday(plan.date)),
          ),
          content: Text(
            plan.tasks.length == 1
                ? dialogContext.l10n.lockInConfirmOne(daylockWeekday(plan.date))
                : dialogContext.l10n.lockInConfirmMany(
                    plan.tasks.length,
                    daylockWeekday(plan.date),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (dialogContext.mounted &&
                    ModalRoute.of(dialogContext)?.isCurrent == true) {
                  Navigator.of(dialogContext).pop(false);
                }
              },
              child: Text(dialogContext.l10n.keepPlanning),
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
              child: Text(dialogContext.l10n.lockItIn),
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
    final weekday = daylockWeekday(plan.date);
    final sky = SceneColors.of(theme);
    final editable = !plan.isCommitted;
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth < 360
            ? DaylockSpace.md
            : DaylockSpace.lg;
        Widget boxed(Widget child) => SliverToBoxAdapter(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: padding),
                child: child,
              ),
            ),
          ),
        );
        return Column(
          children: [
            Expanded(
              child: CustomScrollView(
                key: const ValueKey('plan-content'),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverToBoxAdapter(
                    child: DaylockSkyHeader(
                      key: const ValueKey('plan-sky'),
                      mood: SceneMood.night,
                      height: 196,
                      horizontalPadding: padding,
                      title: context.l10n.plan,
                      subtitle: context.l10n.tomorrowDate(
                        daylockDateLabel(plan.date),
                      ),
                      belowTitle: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: sky.dark
                                ? Colors.black.withValues(alpha: .28)
                                : Colors.white.withValues(alpha: .65),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            plan.isCommitted
                                ? context.l10n.committed
                                : context.l10n.draft,
                            style: theme.textTheme.labelLarge!.copyWith(
                              color: sky.onSky,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  boxed(
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_outlined,
                            size: 20,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Semantics(
                              label: context.l10n.schedule,
                              child: Text(
                                scheduled.isEmpty
                                    ? context.l10n.noScheduledEventsTomorrow
                                    : scheduled.length == 1
                                    ? context.l10n.scheduledEvents(1)
                                    : context.l10n.scheduledEvents(
                                        scheduled.length,
                                      ),
                                style: theme.textTheme.bodyMedium!.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (scheduled.isNotEmpty)
                    const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  if (scheduled.isNotEmpty)
                    SliverList.builder(
                      itemCount: scheduled.length,
                      itemBuilder: (context, index) => _segment(
                        padding: padding,
                        first: index == 0,
                        last: index == scheduled.length - 1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: DaylockPlanEventRow(
                            event: scheduled[index],
                            date: plan.date,
                          ),
                        ),
                      ),
                    ),
                  boxed(
                    DaylockSectionHeader(
                      title: plan.tasks.isEmpty
                          ? context.l10n.commitments
                          : context.l10n.commitmentsCount(plan.tasks.length),
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        0,
                        22,
                        0,
                        10,
                      ),
                      // Always in the same place, however long the plan is.
                      action: editable
                          ? TextButton.icon(
                              key: const ValueKey('open-commitment-editor'),
                              onPressed: _addCommitment,
                              icon: const Icon(Icons.add_rounded, size: 20),
                              label: Text(
                                context.l10n.add,
                                semanticsLabel: context.l10n.addACommitment,
                              ),
                            )
                          : null,
                    ),
                  ),
                  // Built lazily: long plans only build the rows on screen.
                  SliverList.builder(
                    itemCount: plan.tasks.isEmpty ? 1 : plan.tasks.length,
                    itemBuilder: (context, index) {
                      final count = plan.tasks.isEmpty ? 1 : plan.tasks.length;
                      final Widget child;
                      if (index < plan.tasks.length) {
                        child = _planRow(context, plan, index);
                      } else if (plan.tasks.isEmpty) {
                        child = Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            20,
                            20,
                            20,
                            16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.noCommitmentsPlanned,
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                plan.isCommitted
                                    ? context.l10n.tomorrowIsLocked
                                    : context.l10n.addOneSmallStep,
                                style: theme.textTheme.bodyMedium!.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        child = const SizedBox.shrink();
                      }
                      return _segment(
                        padding: padding,
                        first: index == 0,
                        last: index == count - 1,
                        child: child,
                      );
                    },
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
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
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                        padding,
                        10,
                        padding,
                        14,
                      ),
                      child: plan.isCommitted
                          ? const _CommittedPlan()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                DaylockAction(
                                  key: const ValueKey('commit-tomorrow'),
                                  label: context.l10n.lockInWeekday(weekday),
                                  icon: Icons.lock_outline_rounded,
                                  onPressed: plan.tasks.isEmpty
                                      ? null
                                      : _confirmCommit,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  plan.tasks.isEmpty
                                      ? context.l10n.addOneToLockIn(weekday)
                                      : plan.tasks.length == 1
                                      ? context.l10n.locksThisCommitment
                                      : context.l10n.locksTheseCommitments(
                                          plan.tasks.length,
                                        ),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall!.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
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

  /// One row of a rounded group, drawn per row so long lists stay lazy.
  Widget _segment({
    required double padding,
    required bool first,
    required bool last,
    required Widget child,
  }) {
    final scheme = Theme.of(context).colorScheme;
    const radius = Radius.circular(DaylockSpace.cardRadius);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Material(
            color: scheme.surfaceContainerLow,
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.vertical(
              top: first ? radius : Radius.zero,
              bottom: last ? radius : Radius.zero,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!first)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: scheme.outlineVariant,
                  ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _planRow(BuildContext context, DailyPlan plan, int index) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final task = plan.tasks[index];
    final selectedArea = widget.areas?.resolve(task.areaId);
    final tones = AreaTones.forContext(
      context,
      selectedArea == null ? colors.primary : Color(selectedArea.colour),
    );
    final areaName = selectedArea == null
        ? null
        : selectedArea.isArchived
        ? context.l10n.archivedArea(selectedArea.name)
        : selectedArea.name;
    final areaStyle = theme.textTheme.bodySmall!.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: tones.ink,
    );
    return Padding(
      key: ValueKey('plan-task-$index'),
      padding: const EdgeInsetsDirectional.fromSTEB(14, 4, 4, 4),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tones.tint,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${index + 1}',
                style: theme.textTheme.labelLarge!.copyWith(
                  fontFamily: DaylockSpace.displayFont,
                  fontWeight: FontWeight.w800,
                  color: tones.ink,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DaylockPlanTaskRow(
              task: task,
              area: selectedArea,
              showIcon: false,
              repeatLabel: switch (widget.routines.byId(task.routineId)) {
                final routine? => context.l10n.repeatLabel(routine.schedule),
                null => null,
              },
              areaAction: areaName == null
                  ? null
                  : !plan.isCommitted && widget.onTaskAreaChanged != null
                  ? TextButton(
                      key: ValueKey('edit-task-area-$index'),
                      onPressed: () => _changeArea(task),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(48, 32),
                        alignment: AlignmentDirectional.centerStart,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(areaName, style: areaStyle),
                    )
                  : Text(areaName, style: areaStyle),
            ),
          ),
          if (!plan.isCommitted &&
              (widget.onTaskEdited != null || widget.onTaskRemoved != null))
            PopupMenuButton<String>(
              key: ValueKey('plan-task-actions-$index'),
              tooltip: context.l10n.actionsFor(task.name),
              icon: Icon(
                Icons.more_vert_rounded,
                color: colors.onSurfaceVariant,
              ),
              onSelected: (action) {
                if (action == 'edit') _editCommitment(task);
                if (action == 'remove') _removeCommitment(task);
              },
              itemBuilder: (_) => [
                if (widget.onTaskEdited != null)
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(context.l10n.editCommitment),
                  ),
                if (widget.onTaskRemoved != null)
                  PopupMenuItem(
                    value: 'remove',
                    child: Text(context.l10n.removeCommitment),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CommittedPlan extends StatelessWidget {
  const _CommittedPlan();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DaylockGroup(
      key: const ValueKey('committed-plan'),
      color: Color.alphaBlend(
        scheme.primary.withValues(alpha: .12),
        scheme.surfaceContainerLow,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              DaylockIconTile(icon: Icons.lock_rounded, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.tomorrowPlanCommitted,
                      style: theme.textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      context.l10n.yourCommitmentsLocked,
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../design/daylock_calendar.dart';
import '../design/daylock_calendar_details.dart';
import '../design/daylock_theme.dart';
import '../design/daylock_widgets.dart';
import '../models/calendar_activity.dart';
import '../models/daily_plan.dart';
import '../models/plan_history.dart';
import '../models/area.dart';
import '../models/event.dart';
import 'event_editor.dart';
import '../models/calendar_cache.dart';
import '../services/calendar_service.dart';
import '../services/calendar_provider.dart';
import 'calendar_accounts_dialog.dart';
import 'calendar_month_picker.dart';

class CalendarScreen extends StatefulWidget {
  final DateTime initialDate;
  final DateTime? initialSelectedDate;
  final List<Event> events;
  final DailyPlan? todayPlan;
  final PlanHistory history;
  final AreaBook? areas;
  final ValueChanged<Event> onEventSaved;
  final ValueChanged<Event> onEventDeleted;
  final CalendarCache? calendarCache;
  final CalendarService? calendarService;
  final Future<CalendarCache> Function(CalendarCache)? onCalendarCacheChanged;

  const CalendarScreen({
    super.key,
    required this.initialDate,
    this.initialSelectedDate,
    required this.events,
    this.todayPlan,
    this.history = PlanHistory.empty,
    this.areas,
    required this.onEventSaved,
    required this.onEventDeleted,
    this.calendarCache,
    this.calendarService,
    this.onCalendarCacheChanged,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final date = widget.initialSelectedDate ?? widget.initialDate;
    _selectedDate = DateTime(date.year, date.month, date.day);
  }

  Future<void> _editEvent([Event? event]) async {
    if (event?.isExternal == true) return;
    final saved = await showDialog<Event>(
      context: context,
      builder: (_) => EventEditor(date: _selectedDate, event: event),
    );
    if (!mounted || saved == null) return;
    widget.onEventSaved(saved);
    setState(() => _selectedDate = saved.date);
  }

  CalendarDayActivity _activity(DateTime date) => CalendarDayActivity.forDate(
    date: date,
    currentTime: widget.initialDate,
    history: widget.history,
    todayPlan: widget.todayPlan,
  );

  void _changeMonth(int delta) {
    final month = DateTime(_selectedDate.year, _selectedDate.month + delta);
    _showMonth(month);
  }

  void _showMonth(DateTime month) {
    if (month.year < 1 || month.year > 9999) return;
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    setState(
      () => _selectedDate = DateTime(
        month.year,
        month.month,
        _selectedDate.day > lastDay ? lastDay : _selectedDate.day,
      ),
    );
  }

  Future<void> _chooseMonth() async {
    final month = await showDialog<DateTime>(
      context: context,
      builder: (_) => CalendarMonthPicker(initialMonth: _selectedDate),
    );
    if (mounted && month != null) _showMonth(month);
  }

  Future<void> _deleteEvent(Event event) async {
    if (event.isExternal) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Delete event?'),
        content: Text('Delete “${event.title}” from your schedule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (mounted && confirmed == true) widget.onEventDeleted(event);
  }

  Future<void> _manageAccounts() async {
    final service = widget.calendarService;
    final changed = widget.onCalendarCacheChanged;
    if (service == null || changed == null) return;
    var cache = widget.calendarCache ?? CalendarCache.empty;
    Future<CalendarCache> publish(CalendarCache updated) async {
      cache = await changed(updated);
      return cache;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CalendarAccountsDialog(
        cache: cache,
        canConnect: service.canConnect,
        canReconnect: service.canReconnect,
        onReconnect: (id) async => publish(await service.reconnect(cache, id)),
        onConnect: (type) async => publish(await service.connect(cache, type)),
        onDisconnect: (id) async =>
            publish(await service.disconnect(cache, id)),
        onSynchronize: (id) async {
          final now = widget.initialDate;
          return publish(
            await service.synchronize(
              cache,
              id,
              CalendarSyncWindow(
                start: DateTime(now.year, now.month, now.day - 30),
                endExclusive: DateTime(now.year, now.month, now.day + 91),
              ),
            ),
          );
        },
        onVisibilityChanged: (calendar, visible) => publish(
          cache.setVisibility(calendar.accountId, calendar.id, visible),
        ),
      ),
    );
  }

  void _viewExternalEvent(Event event) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(event.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.timeLabelForDate(_selectedDate)),
              Text(
                widget.calendarCache?.sourceLabel(event) ?? event.source.label,
              ),
              const Text('Read-only · cached event'),
              if (event.notes != null) Text(event.notes!),
              if (event.meetingUrl != null)
                SelectableText(event.meetingUrl.toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = Event.forDate(widget.events, _selectedDate);
    final locale = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final month = locale.formatMonthYear(_selectedDate);
    final visibleMonth = DateTime(_selectedDate.year, _selectedDate.month);
    final current = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    final activity = _activity(_selectedDate);
    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Previous month',
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: _selectedDate.year == 1 && _selectedDate.month == 1
              ? null
              : () => _changeMonth(-1),
        ),
        Flexible(
          child: TextButton(
            onPressed: () => setState(() => _selectedDate = current),
            child: const Text('Today'),
          ),
        ),
        IconButton(
          tooltip: 'Next month',
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: _selectedDate.year == 9999 && _selectedDate.month == 12
              ? null
              : () => _changeMonth(1),
        ),
      ],
    );
    return SafeArea(
      child: SingleChildScrollView(
        key: const ValueKey('calendar-scroll'),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Calendar',
                    style: theme.textTheme.headlineLarge!.copyWith(
                      fontSize: 40,
                      letterSpacing: -1.2,
                    ),
                  ),
                ),
                if (widget.calendarService != null)
                  Semantics(
                    key: const ValueKey('calendar-accounts'),
                    label: 'Calendar accounts',
                    button: true,
                    onTap: _manageAccounts,
                    excludeSemantics: true,
                    child: IconButton(
                      tooltip: 'Calendar accounts',
                      onPressed: _manageAccounts,
                      icon: const Icon(
                        Icons.manage_accounts_outlined,
                        size: 24,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final title = TextButton(
                  key: const ValueKey('open-calendar-month-picker'),
                  onPressed: _chooseMonth,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    foregroundColor: theme.colorScheme.onSurface,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          month,
                          key: const ValueKey('calendar-month'),
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.expand_more_rounded,
                        size: DaylockSpace.icon,
                      ),
                    ],
                  ),
                );
                if (constraints.maxWidth < 310 ||
                    MediaQuery.textScalerOf(context).scale(21) > 28) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      Align(alignment: Alignment.centerRight, child: controls),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: title),
                    controls,
                  ],
                );
              },
            ),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              key: const ValueKey('calendar-month-transition'),
              duration: daylockMotion(context),
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [
                  for (final child in previous)
                    IgnorePointer(child: ExcludeSemantics(child: child)),
                  ?current,
                ],
              ),
              child: DaylockMonthGrid(
                key: ValueKey(visibleMonth),
                selectedDate: _selectedDate,
                activityForDate: _activity,
                events: widget.events,
                onMonthChanged: (delta) {
                  if (DateTime(_selectedDate.year, _selectedDate.month) ==
                      visibleMonth) {
                    _changeMonth(delta);
                  }
                },
                onDateSelected: (date) => setState(() => _selectedDate = date),
              ),
            ),
            const SizedBox(height: 8),
            const DaylockHeatmapLegend(),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              locale.formatFullDate(_selectedDate),
              key: const ValueKey('calendar-selected-date'),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            DaylockCalendarCommitments(activity: activity, areas: widget.areas),
            if (!activity.isFuture) const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final action = TextButton.icon(
                  key: const ValueKey('calendar-add-event'),
                  onPressed: () => _editEvent(),
                  icon: const Icon(Icons.add, size: DaylockSpace.icon),
                  label: const Text('Add event'),
                );
                if (MediaQuery.textScalerOf(context).scale(15) > 24) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [const DaylockLabel('SCHEDULE'), action],
                  );
                }
                return Row(
                  children: [
                    const Expanded(child: DaylockLabel('SCHEDULE')),
                    Flexible(child: action),
                  ],
                );
              },
            ),
            const SizedBox(height: 4),
            if (events.isEmpty)
              Text('No events scheduled.', style: theme.textTheme.bodyMedium)
            else
              for (final event in events)
                DaylockCalendarEventRow(
                  key: ValueKey('event-${event.id}'),
                  event: event,
                  date: _selectedDate,
                  onView: () => event.isExternal
                      ? _viewExternalEvent(event)
                      : _editEvent(event),
                  onDelete: () => _deleteEvent(event),
                ),
          ],
        ),
      ),
    );
  }
}

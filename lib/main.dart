import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'design/daylock_theme.dart';
import 'design/daylock_widgets.dart';
import 'design/appearance_preferences.dart';
import 'services/appearance_storage.dart';
import 'screens/settings_screen.dart';

import 'models/daylock_state.dart';
import 'models/daily_plan.dart';
import 'models/plan_history.dart';
import 'models/event.dart';
import 'models/calendar_cache.dart';
import 'services/calendar_service.dart';
import 'services/calendar_credentials.dart';
import 'services/default_calendar_service.dart';
import 'models/task.dart';
import 'screens/today_screen.dart';
import 'screens/plan_screen.dart';
import 'screens/calendar_screen.dart';
import 'services/local_storage.dart';
import 'models/freedom_settings.dart';
import 'models/routine.dart';
import 'models/area.dart';
import 'screens/areas_screen.dart';
import 'services/freedom_service.dart';
import 'services/routine_service.dart';
import 'screens/routines_screen.dart';
import 'services/instagram_detection_bridge.dart';
import 'models/notification_preferences.dart';
import 'services/notifications/notification_service.dart';
import 'services/notifications/default_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const resetLocalData = bool.fromEnvironment('DAYLOCK_RESET_LOCAL_DATA');
  if (kDebugMode && resetLocalData) {
    await SecureCalendarCredentialStore().clearDaylockCredentials();
    await LocalStorage().reset();
  }
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  final LocalStorage? storage;
  final DateTime Function()? now;
  final CalendarService? calendarService;
  final AppearanceStorage? appearanceStorage;
  final InstagramDetectionBridge? detectionBridge;
  final NotificationService? notificationService;

  const MainApp({
    super.key,
    this.storage,
    this.now,
    this.calendarService,
    this.appearanceStorage,
    this.detectionBridge,
    this.notificationService,
  });

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  late final LocalStorage _storage;
  late final DateTime Function() _now;
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _appearance = ValueNotifier(const AppearancePreferences());
  final _planningChanges = ValueNotifier(0);
  final _todayScreenKey = GlobalKey<TodayScreenState>();
  late final NotificationService _notifications;
  NotificationTarget? _pendingNotificationTap;
  NotificationPreferences notificationPreferences =
      const NotificationPreferences();
  FreedomSettings freedomSettings = const FreedomSettings();
  RoutineBook routines = RoutineBook.empty;
  late AreaBook areas;
  late final AppearanceStorage _appearanceStorage;
  late final Future<void> _appearanceReady;
  bool _isLoading = true;
  bool _loadFailed = false;
  bool _foreground = true;
  Timer? _clockRefreshTimer;
  int selectedPage = 0;

  late DailyPlan todayPlan;
  late DailyPlan tomorrowPlan;
  List<Event> events = [];
  CalendarCache calendarCache = CalendarCache.empty;
  PlanHistory history = PlanHistory.empty;
  late final CalendarService _calendarService;
  late final InstagramDetectionBridge _detectionBridge;
  int _nativePendingSaves = 0, _nativeSaveRevision = 0;
  bool _nativePersistedReady = false, _nativeSaveFailed = false;

  @override
  void initState() {
    super.initState();
    _now = widget.now ?? DateTime.now;
    _notifications = widget.notificationService ?? defaultNotificationService();
    _notifications.onTap = _notificationTapped;
    unawaited(_notifications.start());
    _detectionBridge = widget.detectionBridge ?? InstagramDetectionBridge();
    unawaited(_detectionBridge.start());
    _calendarService =
        widget.calendarService ?? defaultCalendarService(now: _now);
    final now = _now();
    areas = AreaBook.initial(createdAt: now);
    todayPlan = DailyPlan(date: now, tasks: [], isCommitted: true);
    tomorrowPlan = DailyPlan(
      date: DateTime(now.year, now.month, now.day + 1),
      tasks: [],
    );
    _storage = widget.storage ?? LocalStorage(now: _now);
    _appearanceStorage = widget.appearanceStorage ?? AppearanceStorage();
    _appearanceReady = _loadAppearance();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadState());
  }

  DaylockState _snapshot() => DaylockState(
    todayPlan: todayPlan,
    tomorrowPlan: tomorrowPlan,
    events: events,
    calendarCache: calendarCache,
    history: history,
    freedomSettings: freedomSettings,
    routines: routines,
    areas: areas,
    notificationPreferences: notificationPreferences,
  );

  @override
  void dispose() {
    _notifications.dispose();
    unawaited(_detectionBridge.close());
    _clockRefreshTimer?.cancel();
    _appearance.dispose();
    _planningChanges.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAccessibilityFeatures() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasForeground = _foreground;
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _refreshClock();
      _publishNativeFreedom(force: true);
      unawaited(_detectionBridge.refresh());
      unawaited(_notifications.refresh());
    } else {
      if (wasForeground) _publishNativeFreedom(force: true);
      _clockRefreshTimer?.cancel();
      _clockRefreshTimer = null;
    }
  }

  bool _reconcileFocus(DaylockState state, DateTime now) {
    var changed = false;
    var hasRunningFocus = false;
    for (final task in state.todayPlan.tasks) {
      changed = task.finishFocusIfDue(now) || changed;
      if (task.isFocusRunning) {
        if (hasRunningFocus) {
          changed = task.pauseFocus(now) || changed;
        } else {
          hasRunningFocus = true;
        }
      }
    }
    // Tomorrow is planning only; its commitments cannot run a timer yet.
    for (final task in state.tomorrowPlan.tasks) {
      changed = task.pauseFocus(now) || changed;
    }
    return changed;
  }

  void _configureClockRefresh() {
    // Observe wall-clock/time-zone changes and midnight even without Focus running.
    // Refreshing eligibility never writes storage; only changed plans/timers do.
    final active = !_isLoading && !_loadFailed && _foreground;
    if (!active) {
      _clockRefreshTimer?.cancel();
      _clockRefreshTimer = null;
    } else {
      _clockRefreshTimer ??= Timer.periodic(
        const Duration(seconds: 1),
        (_) => _refreshClock(),
      );
    }
  }

  void _refreshClock() {
    if (_isLoading || _loadFailed) return;
    _checkRollover();
    final changed = _reconcileFocus(_snapshot(), _now());
    setState(() {});
    if (changed) unawaited(_saveState());
    _publishNativeFreedom();
    _configureClockRefresh();
  }

  void _publishNativeFreedom({bool force = false}) {
    if (!mounted ||
        _isLoading ||
        _loadFailed ||
        !_nativePersistedReady ||
        _nativePendingSaves != 0 ||
        _nativeSaveFailed) {
      return;
    }
    final eligibility = const FreedomService().evaluate(
      now: _now(),
      settings: freedomSettings,
      todayPlan: todayPlan,
      tomorrowPlan: tomorrowPlan,
    );
    unawaited(
      _detectionBridge.publishSnapshot(
        NativeFreedomInput.fromEligibility(
          todayPlan,
          eligibility,
          tomorrowPlan: tomorrowPlan,
        ),
        force: force,
      ),
    );
  }

  void _toggleFocus(Task task, DailyPlan sourcePlan) {
    _refreshClock();
    if (!identical(sourcePlan, todayPlan) ||
        !todayPlan.tasks.contains(task) ||
        task.type != TaskType.focus ||
        task.isCompleted ||
        task.isExcused) {
      return;
    }
    final now = _now();
    setState(() {
      if (task.isFocusRunning) {
        task.pauseFocus(now);
      } else {
        for (final other in todayPlan.tasks) {
          other.pauseFocus(now);
        }
        task.startFocus(now);
      }
    });
    unawaited(_saveState());
    _configureClockRefresh();
  }

  void _checkRollover() {
    if (_isLoading || _loadFailed) return;

    final previous = _snapshot();
    final current = previous.rollOver(_now());
    if (identical(previous, current)) return;

    setState(() {
      todayPlan = current.todayPlan;
      tomorrowPlan = current.tomorrowPlan;
      history = current.history;
    });
    unawaited(_saveState());
  }

  void _changeTaskOutcome(
    Task task,
    DailyPlan sourcePlan,
    TaskOutcome outcome,
    String? reason,
  ) {
    _refreshClock();
    if (!identical(sourcePlan, todayPlan) || !todayPlan.tasks.contains(task)) {
      return;
    }
    setState(() => task.changeOutcome(outcome, now: _now(), reason: reason));
    unawaited(_saveState());
    _configureClockRefresh();
  }

  Future<void> _loadState() async {
    try {
      await _appearanceReady;
      final saved = await _storage.load();
      final previous = saved ?? _snapshot();
      final current = previous.rollOver(_now());
      final focusChanged = _reconcileFocus(current, _now());
      if (saved == null || !identical(previous, current) || focusChanged) {
        await _storage.save(current);
      }
      if (!mounted) return;

      setState(() {
        todayPlan = current.todayPlan;
        tomorrowPlan = current.tomorrowPlan;
        events = List.of(current.events);
        calendarCache = current.calendarCache;
        history = current.history;
        freedomSettings = current.freedomSettings;
        routines = current.routines;
        areas = current.areas;
        notificationPreferences = current.notificationPreferences;
        _isLoading = false;
        _loadFailed = false;
        _nativePersistedReady = true;
        _nativeSaveFailed = false;
      });
      // Also catch a date change while the initial read/write was pending.
      _refreshClock();
      _publishNotifications();
      if (_pendingNotificationTap != null) {
        final target = _pendingNotificationTap!;
        _pendingNotificationTap = null;
        _notificationTapped(target);
      }
    } catch (_) {
      if (!mounted) return;
      _nativePersistedReady = false;
      unawaited(_detectionBridge.invalidateSnapshot());
      unawaited(_notifications.invalidate());
      // Keep existing saved data intact rather than replacing it with defaults.
      setState(() {
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _loadAppearance() async {
    try {
      final saved = await _appearanceStorage.load();
      if (mounted) _appearance.value = saved;
      if (mounted) unawaited(_detectionBridge.publishAppearance(saved));
    } catch (_) {
      // An appearance read failure never prevents access to planner data.
    }
  }

  void _changeAppearance(AppearancePreferences preferences) {
    if (_appearance.value == preferences) return;
    _appearance.value = preferences;
    unawaited(_detectionBridge.publishAppearance(preferences));
    unawaited(_saveAppearance(preferences));
  }

  Future<void> _saveAppearance(AppearancePreferences preferences) async {
    try {
      await _appearanceStorage.save(preferences);
    } catch (_) {
      if (!mounted) return;
      _messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: const Text('Could not save appearance settings.'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => unawaited(_saveAppearance(_appearance.value)),
          ),
        ),
      );
    }
  }

  void _openSettings() => _navigatorKey.currentState!.push(
    MaterialPageRoute<void>(
      builder: (_) => ValueListenableBuilder<AppearancePreferences>(
        valueListenable: _appearance,
        builder: (context, preferences, _) => ValueListenableBuilder<int>(
          valueListenable: _planningChanges,
          builder: (context, revision, _) => SettingsScreen(
            preferences: preferences,
            onChanged: _changeAppearance,
            freedomSettings: freedomSettings,
            onFreedomChanged: _changeFreedomSettings,
            routineCount: routines.routines.length,
            onRoutinesRequested: _openRoutines,
            onAreasRequested: _openAreas,
            areaCount: areas.active.length,
            detectionBridge: _detectionBridge,
            notificationService: _notifications,
            notificationPreferences: notificationPreferences,
            onNotificationsChanged: _changeNotifications,
          ),
        ),
      ),
    ),
  );

  void _changeFreedomSettings(FreedomSettings settings) {
    settings.toJson();
    setState(() => freedomSettings = settings);
    _planningChanges.value++;
    unawaited(_saveState());
  }

  void _changeNotifications(NotificationPreferences preferences) {
    preferences.toJson();
    setState(() => notificationPreferences = preferences);
    _planningChanges.value++;
    unawaited(_saveState());
  }

  void _publishNotifications() {
    if (!mounted ||
        _isLoading ||
        _loadFailed ||
        !_nativePersistedReady ||
        _nativePendingSaves != 0 ||
        _nativeSaveFailed) {
      return;
    }
    unawaited(_notifications.synchronize(_snapshot(), _now()));
  }

  void _notificationTapped(NotificationTarget target) {
    if (!mounted) return;
    if (_isLoading || _loadFailed) {
      _pendingNotificationTap = target;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshClock();
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
      setState(() => selectedPage = target.screen == 'plan' ? 1 : 0);
      if (target.screen != 'plan' &&
          target.date == notificationDate(todayPlan.date) &&
          target.taskIndex != null &&
          target.taskName != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || target.date != notificationDate(todayPlan.date)) {
            return;
          }
          _todayScreenKey.currentState?.openNotificationTask(
            target.taskIndex!,
            target.taskName!,
          );
        });
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _openAreas() => _navigatorKey.currentState!.push(
    MaterialPageRoute<void>(
      builder: (_) => ValueListenableBuilder<int>(
        valueListenable: _planningChanges,
        builder: (context, revision, _) => AreasScreen(
          book: areas,
          onSaved: (area) {
            setState(() => areas = areas.upsert(area));
            _planningChanges.value++;
            unawaited(_saveState());
          },
          onArchived: (id, archived) {
            if (areas.resolve(id).isDefault) return;
            setState(() => areas = areas.archive(id, archived));
            _planningChanges.value++;
            unawaited(_saveState());
          },
        ),
      ),
    ),
  );

  void _changeTaskArea(Task task, String id, DailyPlan sourcePlan) {
    _refreshClock();
    if (!identical(sourcePlan, tomorrowPlan) ||
        tomorrowPlan.isCommitted ||
        !tomorrowPlan.tasks.contains(task) ||
        !areas.active.any((a) => a.id == id)) {
      return;
    }
    // Update only the relationship; retain the same Task and all execution state.
    setState(() => task.areaId = id);
    unawaited(_saveState());
  }

  void _openRoutines() => _navigatorKey.currentState!.push(
    MaterialPageRoute<void>(
      builder: (_) => ValueListenableBuilder<int>(
        valueListenable: _planningChanges,
        builder: (context, revision, _) => RoutinesScreen(
          book: routines,
          areas: areas,
          onSaved: _saveRoutine,
          onDeleted: (id) {
            setState(() => routines = routines.remove(id));
            _planningChanges.value++;
            unawaited(_saveState());
          },
        ),
      ),
    ),
  );

  void _saveRoutine(Routine saved) {
    final matches = routines.routines.where(
      (routine) => routine.id == saved.id,
    );
    if (matches.isEmpty && saved.revision != 0) return;
    if (matches.isNotEmpty && saved.revision != matches.single.revision + 1) {
      return;
    }
    final updated = matches.isEmpty
        ? saved
        : matches.single.edit(name: saved.name, steps: saved.steps);
    setState(() => routines = routines.upsert(updated));
    _planningChanges.value++;
    unawaited(_saveState());
  }

  void _resolveRoutine(
    RoutineSuggestion suggestion,
    RoutineAction action,
    DailyPlan sourcePlan,
  ) {
    _refreshClock();
    if (!identical(sourcePlan, tomorrowPlan) || tomorrowPlan.isCommitted) {
      return;
    }
    final resolution = const RoutineService().resolve(
      routines,
      suggestion,
      action,
      tomorrowPlan.date,
      areas: areas,
    );
    if (!resolution.changed) return;
    setState(() {
      routines = resolution.book;
      if (resolution.task != null) tomorrowPlan.tasks.add(resolution.task!);
    });
    _planningChanges.value++;
    // Decisions, cycle progress and accepted tasks are saved together.
    unawaited(_saveState());
  }

  Future<void> _saveState() async {
    // Freeze mutable tasks before any await, preserving the order of rapid edits.
    final snapshot = DaylockState.fromJson(_snapshot().toJson());
    final revision = ++_nativeSaveRevision;
    _nativePendingSaves++;
    // Invalidate before publishing changes; never bless an unsaved planner state.
    unawaited(_detectionBridge.invalidateSnapshot());
    // Fail closed before persisting changes. Notification failures are isolated
    // by the service and must never prevent saving the user's planner data.
    final notificationInvalidation = _notifications.invalidate();
    try {
      await notificationInvalidation;
      await _storage.save(snapshot);
      if (revision == _nativeSaveRevision) _nativeSaveFailed = false;
    } catch (_) {
      if (revision == _nativeSaveRevision) _nativeSaveFailed = true;
      if (!mounted) return;
      _messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: const Text('Could not save your changes.'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => unawaited(_saveState()),
          ),
        ),
      );
    } finally {
      _nativePendingSaves--;
      if (mounted && _nativePendingSaves == 0) {
        _publishNativeFreedom(force: true);
        _publishNotifications();
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<AppearancePreferences>(
        valueListenable: _appearance,
        builder: (context, preferences, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: _navigatorKey,
          scaffoldMessengerKey: _messengerKey,
          theme: DaylockTheme.forPalette(preferences.colour, Brightness.light),
          darkTheme: DaylockTheme.forPalette(
            preferences.colour,
            Brightness.dark,
          ),
          themeMode: preferences.mode.themeMode,
          themeAnimationDuration:
              (MediaQuery.maybeOf(context)?.disableAnimations ??
                  WidgetsBinding
                      .instance
                      .platformDispatcher
                      .accessibilityFeatures
                      .disableAnimations)
              ? Duration.zero
              : const Duration(milliseconds: 220),
          home: _buildHome(),
        ),
      );

  Widget _buildHome() {
    if (_isLoading || _loadFailed) {
      return Scaffold(
        body: DaylockLoadState(
          failed: _loadFailed,
          onRetry: () {
            setState(() {
              _isLoading = true;
            });
            unawaited(_loadState());
          },
        ),
      );
    }

    final planForTomorrow = tomorrowPlan;
    final planForToday = todayPlan;
    final displayedEvents = [...events, ...calendarCache.visibleEvents];
    final pages = [
      TodayScreen(
        key: _todayScreenKey,
        plan: planForToday,
        freedomEligibility: const FreedomService().evaluate(
          now: _now(),
          settings: freedomSettings,
          todayPlan: planForToday,
          tomorrowPlan: planForTomorrow,
        ),
        onOutcomeChanged: (task, outcome, reason) =>
            _changeTaskOutcome(task, planForToday, outcome, reason),
        onSettingsRequested: _openSettings,
        onPlanRequested: () => setState(() {
          selectedPage = 1;
        }),
        currentTime: _now(),
        onFocusToggled: (task) => _toggleFocus(task, planForToday),
        onTaskChanged: () {
          setState(() {});
          unawaited(_saveState());
        },
      ),
      PlanScreen(
        key: ValueKey(planForTomorrow.date),
        plan: planForTomorrow,
        areas: areas,
        onTaskAreaChanged: (task, id) =>
            _changeTaskArea(task, id, planForTomorrow),
        routineSuggestions: const RoutineService().suggestions(
          routines,
          planForTomorrow.date,
        ),
        onRoutineAction: (suggestion, action) =>
            _resolveRoutine(suggestion, action, planForTomorrow),
        events: Event.forDate(displayedEvents, planForTomorrow.date),
        calendarCache: calendarCache,
        onTaskCreated: (task) {
          _refreshClock();
          if (!identical(planForTomorrow, tomorrowPlan) ||
              tomorrowPlan.isCommitted) {
            return;
          }

          setState(() {
            task.areaId = areas.forNewCommitment(task.areaId).id;
            tomorrowPlan.tasks.add(task);
          });
          unawaited(_saveState());
        },
        onCommitTomorrow: () {
          if (!identical(planForTomorrow, tomorrowPlan) ||
              tomorrowPlan.isCommitted ||
              tomorrowPlan.tasks.isEmpty) {
            return;
          }

          setState(() {
            tomorrowPlan.isCommitted = true;
          });
          unawaited(_saveState());
        },
      ),
      CalendarScreen(
        areas: areas,
        initialDate: _now(),
        todayPlan: planForToday,
        history: history,
        events: displayedEvents,
        calendarCache: calendarCache,
        calendarService: _calendarService,
        onCalendarCacheChanged: (updated) async {
          if (!mounted) return calendarCache;
          setState(() => calendarCache = updated);
          await _saveState();
          return calendarCache;
        },
        onEventSaved: (event) {
          if (event.isExternal ||
              calendarCache.events.any((e) => e.id == event.id)) {
            return;
          }
          setState(() {
            final index = events.indexWhere(
              (existing) => existing.id == event.id,
            );
            if (index == -1) {
              events.add(event);
            } else {
              events[index] = event;
            }
          });
          unawaited(_saveState());
        },
        onEventDeleted: (event) {
          if (event.isExternal) return;
          setState(
            () => events.removeWhere((existing) => existing.id == event.id),
          );
          unawaited(_saveState());
        },
      ),
    ];

    return Scaffold(
      body: pages[selectedPage],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedPage,
        onDestinationSelected: (index) {
          setState(() {
            selectedPage = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: 'Plan',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
        ],
      ),
    );
  }
}

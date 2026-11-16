import 'services/weekly_review.dart';
import 'screens/weekly_review_screen.dart';
import 'services/backup_service.dart';
import 'screens/backup_screen.dart';
import 'l10n/l10n.dart';

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'design/daylock_theme.dart';
import 'design/daylock_widgets.dart';
import 'design/appearance_preferences.dart';
import 'services/appearance_storage.dart';
import 'screens/settings_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/commitment_editor.dart';

import 'models/daylock_state.dart';
import 'models/onboarding_steps.dart';
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
import 'models/highlight.dart';
import 'services/journey_service.dart';
import 'screens/journey_screen.dart';
import 'screens/past_chapters_screen.dart';
import 'services/stopwatch_clock.dart';
import 'services/commitment_stopwatches.dart';
import 'screens/area_journey_screen.dart';
import 'screens/highlight_editor.dart';
import 'design/daylock_journey.dart';
import 'services/freedom_service.dart';
import 'services/routine_service.dart';
import 'screens/routines_screen.dart';
import 'screens/app_tour.dart';
import 'screens/blocking_health_notice.dart';
import 'services/instagram_detection_bridge.dart';
import 'models/notification_preferences.dart';
import 'services/notifications/notification_service.dart';
import 'services/notifications/default_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ensureDateFormatting();
  const resetLocalData = bool.fromEnvironment('DAYLOCK_RESET_LOCAL_DATA');
  if (kDebugMode && resetLocalData) {
    await SecureCalendarCredentialStore().clearDaylockCredentials();
    await LocalStorage().reset();
  }
  runApp(
    MainApp(
      onboardingEnabled:
          !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
    ),
  );
}

class MainApp extends StatefulWidget {
  final LocalStorage? storage;
  final DateTime Function()? now;
  final CalendarService? calendarService;
  final AppearanceStorage? appearanceStorage;
  final InstagramDetectionBridge? detectionBridge;
  final NotificationService? notificationService;
  final StopwatchClock? stopwatchClock;
  final BackupFiles? backupFiles;
  // The Android entry point enables first-run setup. Embedders and visual
  // fixtures can open the planner directly without starting device setup.
  final bool onboardingEnabled;

  const MainApp({
    super.key,
    this.storage,
    this.now,
    this.calendarService,
    this.appearanceStorage,
    this.detectionBridge,
    this.notificationService,
    this.stopwatchClock,
    this.backupFiles,
    this.onboardingEnabled = false,
  });

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  late final LocalStorage _storage;
  late final DateTime Function() _now;
  late final StopwatchClock _stopwatchClock;
  late final CommitmentStopwatches _stopwatches;
  Future<void> _stopwatchOperations = Future.value();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _appearance = ValueNotifier(const AppearancePreferences());
  final _planningChanges = ValueNotifier(0);
  final _journeyChanges = ValueNotifier(0);
  final _todayScreenKey = GlobalKey<TodayScreenState>();
  late final NotificationService _notifications;
  NotificationTarget? _pendingNotificationTap;
  NotificationPreferences notificationPreferences =
      const NotificationPreferences();
  FreedomSettings freedomSettings = const FreedomSettings();
  RoutineBook routines = RoutineBook.empty;
  late AreaBook areas;
  HighlightBook highlights = HighlightBook.empty;
  JourneyData? _cachedJourney;
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
  late final BackupFiles _backupFiles = widget.backupFiles ?? BackupFiles();
  int _nativePendingSaves = 0, _nativeSaveRevision = 0;
  bool _nativePersistedReady = false, _nativeSaveFailed = false;
  int _onboardingStep = 0;
  bool _onboardingPowerReviewed = false;
  bool _tutorialOpen = false;

  /// Index into [daylockTour] while the guided tour is showing.
  int? _tourStep;
  bool get _onboardingEnabled => widget.onboardingEnabled;

  @override
  void initState() {
    super.initState();
    _now = widget.now ?? DateTime.now;
    _stopwatchClock =
        widget.stopwatchClock ??
        (widget.now == null ? StopwatchClock() : InjectedStopwatchClock(_now));
    _stopwatches = CommitmentStopwatches(_stopwatchClock);
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
    highlights: highlights,
    notificationPreferences: notificationPreferences,
  );

  @override
  void dispose() {
    _notifications.dispose();
    unawaited(_detectionBridge.close());
    _clockRefreshTimer?.cancel();
    _appearance.dispose();
    _planningChanges.dispose();
    _journeyChanges.dispose();
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
      unawaited(_synchronizeStopwatches());
      _publishNativeFreedom(force: true);
      unawaited(_detectionBridge.refresh());
      unawaited(_notifications.refresh());
    } else {
      if (wasForeground) unawaited(_synchronizeStopwatches(checkpoint: true));
      if (wasForeground) _publishNativeFreedom(force: true);
      _clockRefreshTimer?.cancel();
      _clockRefreshTimer = null;
    }
  }

  bool _reconcileFocus(DaylockState state, DateTime now) {
    return _stopwatches.reconcile(state);
  }

  Future<void> _synchronizeStopwatches({bool checkpoint = false}) async {
    await _stopwatchClock.synchronize();
    if (!mounted || _isLoading || _loadFailed) return;
    _refreshClock();
    if (checkpoint && _stopwatches.checkpoint(_snapshot())) await _saveState();
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
    if (todayPlan.tasks.any((t) => t.isFocusRunning)) _cachedJourney = null;
    setState(() {});
    _journeyChanges.value++;
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

  void _toggleFocus(Task task, DailyPlan sourcePlan) =>
      _queueStopwatch(() async {
        _refreshClock();
        if (!identical(sourcePlan, todayPlan) ||
            !todayPlan.tasks.contains(task) ||
            task.isCompleted ||
            task.isExcused) {
          return;
        }
        setState(() => _stopwatches.toggle(_snapshot(), task));
        await _saveState();
        _configureClockRefresh();
      });

  void _queueStopwatch(Future<void> Function() operation) {
    _stopwatchOperations = _stopwatchOperations.then((_) async {
      await _stopwatchClock.synchronize();
      if (!mounted || _isLoading || _loadFailed) return;
      if (_nativeSaveFailed) {
        _messengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(_l.savePendingBeforeStopwatch),
            action: SnackBarAction(
              label: _l.retry,
              onPressed: () => unawaited(_saveState()),
            ),
          ),
        );
        return;
      }
      await operation();
    });
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
    if (!_applyRoutines()) unawaited(_saveState());
  }

  /// Puts every routine due tomorrow into tomorrow's draft. Returns whether
  /// anything was added (and saved). Committed plans are never touched, and a
  /// routine the user removed for a date is not added back.
  bool _applyRoutines() {
    if (_isLoading || _loadFailed) return false;
    final applied = const RoutineService().apply(
      routines,
      tomorrowPlan,
      areas: areas,
    );
    if (!applied.changed) return false;
    setState(() {
      routines = applied.book;
      tomorrowPlan.tasks.addAll(applied.added);
    });
    _planningChanges.value++;
    unawaited(_saveState());
    return true;
  }

  void _changeTaskOutcome(
    Task task,
    DailyPlan sourcePlan,
    TaskOutcome outcome,
    String? reason,
  ) => _queueStopwatch(() async {
    _refreshClock();
    if (!identical(sourcePlan, todayPlan) || !todayPlan.tasks.contains(task)) {
      return;
    }
    setState(() => task.changeOutcome(outcome, now: _now(), reason: reason));
    await _saveState();
    _configureClockRefresh();
  });

  Future<void> _loadState() async {
    try {
      await _appearanceReady;
      final saved = await _storage.load();
      bool showTutorial = false;
      if (_onboardingEnabled) {
        final progress = await _storage.loadOnboardingStep();
        // Run the revised setup once for every Android installation, including
        // existing users who previously skipped/migrated the old tutorial.
        // Planner data never counts as evidence that setup was completed.
        _onboardingStep = progress ?? 0;
        _onboardingPowerReviewed = await _storage.loadOnboardingPowerReviewed();
        await _storage.saveOnboardingStep(_onboardingStep);
        showTutorial = _onboardingStep < OnboardingSteps.complete;
      }
      final previous = saved ?? _snapshot();
      await _stopwatchClock.synchronize();
      final recovered = _stopwatches.reconcile(previous, recovering: true);
      final current = previous.rollOver(_now());
      final focusChanged = _reconcileFocus(current, _now());
      if (saved == null ||
          !identical(previous, current) ||
          focusChanged ||
          recovered) {
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
        highlights = current.highlights;
        notificationPreferences = current.notificationPreferences;
        _isLoading = false;
        _loadFailed = false;
        _nativePersistedReady = true;
        _nativeSaveFailed = false;
      });
      // Also catch a date change while the initial read/write was pending.
      _refreshClock();
      _applyRoutines();
      _publishNotifications();
      if (showTutorial) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _openTutorial();
        });
      }
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
          content: Text(_l.couldNotSaveAppearance),
          action: SnackBarAction(
            label: _l.retry,
            onPressed: () => unawaited(_saveAppearance(_appearance.value)),
          ),
        ),
      );
    }
  }

  void _openSettings([SettingsDestination? destination]) =>
      _navigatorKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => ValueListenableBuilder<AppearancePreferences>(
            valueListenable: _appearance,
            builder: (context, preferences, _) => ValueListenableBuilder<int>(
              valueListenable: _planningChanges,
              builder: (context, revision, _) => SettingsScreen(
                readFreedom: () => const FreedomService().evaluate(
                  now: _now(),
                  settings: freedomSettings,
                  todayPlan: todayPlan,
                  tomorrowPlan: tomorrowPlan,
                ),
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
                onSetupRequested: () => _openTutorial(restart: true),
                onTourRequested: _startTour,
                onBackupRequested: _openBackup,
                initialDestination: destination,
              ),
            ),
          ),
        ),
      );

  void _openWeeklyReview() => _navigatorKey.currentState!.push(
    MaterialPageRoute<void>(
      builder: (routeContext) => WeeklyReviewScreen(
        review: WeeklyReview.of(
          _journeyData(),
          areas,
          breaks: _detectionBridge.status.value.breaks,
        ),
        onPlanTomorrow: () {
          Navigator.of(routeContext).pop();
          setState(() => selectedPage = 1);
        },
      ),
    ),
  );

  void _openBackup() => _navigatorKey.currentState!.push(
    MaterialPageRoute<void>(
      builder: (_) => BackupScreen(
        files: _backupFiles,
        current: _snapshot,
        now: _now,
        restore: _restoreBackup,
      ),
    ),
  );

  /// Replaces all planner data with a backup, then reloads it the normal
  /// way (rollover, stopwatches, routines, notifications).
  Future<bool> _restoreBackup(DaylockState state) async {
    try {
      await _storage.save(state);
    } catch (_) {
      return false;
    }
    _cachedJourney = null;
    await _loadState();
    return !_loadFailed;
  }

  Future<void> _openTutorial({bool restart = false}) async {
    if (_tutorialOpen || _isLoading || _loadFailed) return;
    _tutorialOpen = true;
    try {
      if (restart) {
        await _storage.saveOnboardingStep(0);
        _onboardingStep = 0;
      }
      if (!mounted) return;
      await _navigatorKey.currentState!.push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/setup'),
          builder: (context) => OnboardingScreen(
            bridge: _detectionBridge,
            notifications: _notifications,
            initialStep: _onboardingStep,
            onTourRequested: _startTour,
            initialPowerReviewed: _onboardingPowerReviewed,
            savePowerReviewed: (reviewed) async {
              await _storage.saveOnboardingPowerReviewed(reviewed);
              _onboardingPowerReviewed = reviewed;
            },
            saveStep: (step) async {
              await _storage.saveOnboardingStep(step);
              _onboardingStep = step;
            },
            hasGoal: () =>
                !_nativeSaveFailed &&
                (todayPlan.tasks.isNotEmpty || tomorrowPlan.tasks.isNotEmpty),
            createGoal: _createOnboardingGoal,
            enableFreedom: () async {
              setState(
                () => freedomSettings = freedomSettings.copyWith(enabled: true),
              );
              _planningChanges.value++;
              await _saveState();
              if (_nativeSaveFailed) {
                throw StateError('Freedom settings could not be saved');
              }
              await _detectionBridge.refresh();
            },
            onExit: () {
              _navigatorKey.currentState!.pop();
              setState(() => selectedPage = 0);
              if (_onboardingStep == OnboardingSteps.complete &&
                  _pendingNotificationTap != null) {
                final target = _pendingNotificationTap!;
                _pendingNotificationTap = null;
                _notificationTapped(target);
              }
            },
          ),
        ),
      );
    } catch (_) {
      _messengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(_l.couldNotSaveSetup)),
      );
    } finally {
      _tutorialOpen = false;
    }
  }

  /// Walks through the real Today, Plan and Journey screens with spotlights.
  void _startTour() {
    if (_isLoading || _loadFailed) return;
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    _goToTourStop(0);
  }

  void _goToTourStop(int index) {
    if (index < 0) return;
    if (index >= daylockTour.length) return _endTour();
    // The overlay switches tabs itself, once the bubble has faded out.
    setState(() => _tourStep = index);
  }

  void _endTour() {
    if (_tourStep == null) return;
    setState(() {
      _tourStep = null;
      selectedPage = 0;
    });
  }

  Future<bool> _createOnboardingGoal(BuildContext context) async {
    _refreshClock();
    final plan = tomorrowPlan;
    if (plan.isCommitted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_l.tomorrowAlreadyCommitted)));
      return false;
    }
    final task = await showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => CommitmentEditor(
        areas: areas,
        heading: _l.firstCommitmentHeading,
        canCreate: () => identical(plan, tomorrowPlan) && !plan.isCommitted,
      ),
    );
    if (!mounted || task == null) return false;
    _refreshClock();
    if (!identical(plan, tomorrowPlan) ||
        plan.isCommitted ||
        plan.tasks.any((existing) => existing.id == task.id)) {
      return false;
    }
    setState(() {
      task.areaId = areas.forNewCommitment(task.areaId).id;
      plan.tasks.add(task);
    });
    await _saveState();
    return !_nativeSaveFailed;
  }

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
    if (_isLoading ||
        _loadFailed ||
        (_onboardingEnabled && _onboardingStep < OnboardingSteps.complete)) {
      _pendingNotificationTap = target;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshClock();
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
      setState(() => selectedPage = target.screen == 'plan' ? 1 : 0);
      if (target.screen == 'review') return _openWeeklyReview();
      if (target.pausesStopwatch) return _pauseFromNotification(target);
      if (target.keepsTask) return _keepFromWidget(target);
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

  /// The running-stopwatch notification's Pause button. Only pauses the
  /// exact task it named, on the same day, if it is still running.
  /// A commitment tapped on the home screen widget: keep it, with Undo.
  /// Stale or mismatched taps (another day, a renamed or moved commitment)
  /// change nothing.
  void _keepFromWidget(NotificationTarget target) {
    final index = target.taskIndex;
    final tasks = todayPlan.tasks;
    if (target.date != notificationDate(todayPlan.date) ||
        index == null ||
        index < 0 ||
        index >= tasks.length) {
      return;
    }
    final task = tasks[index];
    if (task.name != target.taskName ||
        task.outcome != TaskOutcome.incomplete) {
      return;
    }
    task.changeOutcome(TaskOutcome.completed, now: _now());
    setState(() {});
    unawaited(_saveState());
    _messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(_l.keptName(task.name)),
        action: SnackBarAction(
          label: _l.undo,
          onPressed: () {
            if (!identical(tasks, todayPlan.tasks) || !task.isCompleted) return;
            task.changeOutcome(TaskOutcome.incomplete, now: _now());
            setState(() {});
            unawaited(_saveState());
          },
        ),
      ),
    );
  }

  void _pauseFromNotification(NotificationTarget target) {
    final index = target.taskIndex;
    final tasks = todayPlan.tasks;
    if (target.date != notificationDate(todayPlan.date) ||
        index == null ||
        index < 0 ||
        index >= tasks.length) {
      return;
    }
    final task = tasks[index];
    if (task.name != target.taskName || !task.isFocusRunning) return;
    _toggleFocus(task, todayPlan);
    _messengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(_l.pausedTask(task.name))),
    );
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
          planningDate: tomorrowPlan.date,
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
        : matches.single.edit(
            name: saved.name,
            steps: saved.steps,
            schedule: saved.schedule,
          );
    setState(() => routines = routines.upsert(updated));
    _planningChanges.value++;
    if (!_applyRoutines()) unawaited(_saveState());
  }

  /// Repeat was set or cleared from the commitment editor. A single-step
  /// routine lives behind the task; rotations are only managed in Routines.
  void _changeRepeat(Task task, RoutineSchedule? schedule, DailyPlan source) {
    _refreshClock();
    if (!identical(source, tomorrowPlan) ||
        tomorrowPlan.isCommitted ||
        !tomorrowPlan.tasks.contains(task)) {
      return;
    }
    final date = tomorrowPlan.date;
    final existing = routines.byId(task.routineId);
    if (existing != null && existing.isRotation) return;
    setState(() {
      if (schedule == null) {
        if (existing != null) routines = routines.remove(existing.id);
        task.routineId = null;
      } else if (existing != null) {
        var updated = existing.withSchedule(schedule);
        if (schedule.isDue(date) &&
            !updated.decisions.containsKey(routineDateKey(date))) {
          updated = updated.recordExisting(date, updated.steps.single.id);
        }
        routines = routines.upsert(updated);
      } else {
        final step = RoutineStep.fromTask(task);
        var routine = Routine(
          id: newRoutineId(),
          name: task.name,
          steps: [step],
          schedule: schedule,
        );
        // The task being edited is this date's occurrence, so it is never
        // added twice. If the repeat isn't due that day, it stays a one-off.
        if (schedule.isDue(date)) {
          routine = routine.recordExisting(date, step.id);
        }
        routines = routines.upsert(routine);
        task.routineId = routine.id;
      }
    });
    _planningChanges.value++;
    unawaited(_saveState());
  }

  void _removeTask(Task task, DailyPlan source) {
    _refreshClock();
    if (!identical(source, tomorrowPlan) ||
        tomorrowPlan.isCommitted ||
        !tomorrowPlan.tasks.contains(task)) {
      return;
    }
    final index = tomorrowPlan.tasks.indexOf(task);
    final routine = routines.byId(task.routineId);
    final date = tomorrowPlan.date;
    setState(() {
      tomorrowPlan.tasks.remove(task);
      if (routine != null) routines = routines.upsert(routine.remove(date));
    });
    _planningChanges.value++;
    unawaited(_saveState());
    if (routine == null) return;
    final messenger = _messengerKey.currentState;
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        key: const ValueKey('routine-removed-snackbar'),
        duration: const Duration(seconds: 6),
        content: Row(
          children: [
            Expanded(child: Text(_l.removedForWeekday(daylockWeekday(date)))),
            TextButton(
              key: const ValueKey('routine-removed-undo'),
              onPressed: () {
                messenger.hideCurrentSnackBar();
                _undoRemoval(task, index, routine.id, source);
              },
              child: Text(_l.undo),
            ),
            TextButton(
              key: const ValueKey('routine-removed-stop'),
              onPressed: () {
                messenger.hideCurrentSnackBar();
                _stopRepeating(routine.id);
              },
              child: Text(_l.stopRepeating),
            ),
          ],
        ),
      ),
    );
  }

  void _undoRemoval(Task task, int index, String routineId, DailyPlan source) {
    _refreshClock();
    if (!identical(source, tomorrowPlan) ||
        tomorrowPlan.isCommitted ||
        tomorrowPlan.tasks.contains(task)) {
      return;
    }
    final routine = routines.byId(routineId);
    setState(() {
      tomorrowPlan.tasks.insert(
        index.clamp(0, tomorrowPlan.tasks.length),
        task,
      );
      if (routine != null) {
        routines = routines.upsert(routine.restore(tomorrowPlan.date));
      }
    });
    _planningChanges.value++;
    unawaited(_saveState());
  }

  void _stopRepeating(String routineId) {
    if (routines.byId(routineId) == null) return;
    setState(() => routines = routines.remove(routineId));
    _planningChanges.value++;
    unawaited(_saveState());
    _messengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(_l.stoppedRepeating)),
    );
  }

  JourneyData _journeyData() {
    final now = _now();
    if (_cachedJourney == null || _cachedJourney!.today != journeyDay(now)) {
      _cachedJourney = JourneyData(
        areas: areas,
        history: history,
        todayPlan: todayPlan,
        now: now,
      );
    }
    return _cachedJourney!;
  }

  void _openCalendar([DateTime? date]) => _navigatorKey.currentState!.push(
    MaterialPageRoute<void>(
      builder: (_) => ValueListenableBuilder<int>(
        valueListenable: _journeyChanges,
        builder: (context, revision, _) => Scaffold(
          appBar: AppBar(title: Text(_l.dailyHistory)),
          body: _buildCalendar(date),
        ),
      ),
    ),
  );

  void _openPastChapters() => _navigatorKey.currentState!.push(
    MaterialPageRoute<void>(
      builder: (_) => ValueListenableBuilder<int>(
        valueListenable: _journeyChanges,
        builder: (context, revision, _) => PastChaptersScreen(
          areas: areas,
          highlights: highlights,
          data: _journeyData(),
          onAreaOpened: _openAreaJourney,
          onManageAreas: _openAreas,
        ),
      ),
    ),
  );

  void _openAreaJourney(String id) => _navigatorKey.currentState!.push(
    MaterialPageRoute<void>(
      builder: (_) => ValueListenableBuilder<int>(
        valueListenable: _journeyChanges,
        builder: (context, revision, _) => AreaJourneyScreen(
          area: areas.resolve(id),
          areas: areas,
          data: _journeyData(),
          highlights: highlights,
          onHighlightOpened: _openHighlight,
          onDayOpened: _openCalendar,
          onAddHighlight: () => _editHighlight(initialAreaId: id),
        ),
      ),
    ),
  );

  Future<void> _editHighlight({
    Highlight? original,
    String? initialAreaId,
  }) async {
    final saved = await showModalBottomSheet<Highlight>(
      context: _navigatorKey.currentContext!,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) => HighlightEditor(
        highlight: original,
        areas: areas,
        now: _now(),
        initialAreaId: initialAreaId,
      ),
    );
    if (!mounted || saved == null) return;
    if (original != null &&
        !highlights.highlights.any((h) => h.id == original.id)) {
      return;
    }
    setState(() => highlights = highlights.upsert(saved));
    unawaited(_saveState());
  }

  void _openHighlights() => _navigatorKey.currentState!.push(
    MaterialPageRoute<void>(
      builder: (_) => ValueListenableBuilder<int>(
        valueListenable: _journeyChanges,
        builder: (context, revision, _) => Scaffold(
          appBar: AppBar(title: Text(_l.achievements)),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: OutlinedButton.icon(
                        onPressed: () => _editHighlight(),
                        icon: const Icon(Icons.add),
                        label: Text(_l.addAchievement),
                      ),
                    ),
                    if (highlights.highlights.isEmpty)
                      Text(_l.achievementsIntro),
                    for (final highlight in highlights.newestFirst)
                      JourneyHighlightTile(
                        highlight: highlight,
                        areas: areas,
                        onTap: () => _openHighlight(highlight),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  void _openHighlight(Highlight selected) => _navigatorKey.currentState!.push(
    MaterialPageRoute<void>(
      builder: (_) => ValueListenableBuilder<int>(
        valueListenable: _journeyChanges,
        builder: (context, revision, _) {
          final matches = highlights.highlights.where(
            (h) => h.id == selected.id,
          );
          if (matches.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: Text(_l.achievement)),
              body: Center(child: Text(_l.achievementRemoved)),
            );
          }
          final highlight = matches.single;
          return Scaffold(
            appBar: AppBar(title: Text(_l.achievement)),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        highlight.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        MaterialLocalizations.of(context)
                            .formatFullDate(highlight.date),
                      ),
                      if (highlight.areaId != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          areas.areas.any((a) => a.id == highlight.areaId)
                              ? areas.resolve(highlight.areaId).name
                              : _l.areaUnavailable,
                        ),
                      ],
                      if (highlight.description != null) ...[
                        const SizedBox(height: 24),
                        Text(highlight.description!),
                      ],
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        children: [
                          OutlinedButton(
                            key: const ValueKey('edit-highlight'),
                            onPressed: () =>
                                _editHighlight(original: highlight),
                            child: Text(_l.edit),
                          ),
                          TextButton(
                            key: const ValueKey('delete-highlight'),
                            onPressed: () =>
                                _deleteHighlight(context, highlight),
                            child: Text(_l.delete),
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
      ),
    ),
  );

  Future<void> _deleteHighlight(
    BuildContext context,
    Highlight highlight,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: Text(_l.deleteAchievementTitle),
        content: Text(_l.deleteAchievementBody(highlight.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_l.keepAchievement),
          ),
          FilledButton(
            key: const ValueKey('confirm-delete-highlight'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_l.delete),
          ),
        ],
      ),
    );
    if (!mounted || !context.mounted || confirmed != true) return;
    Navigator.pop(context);
    setState(() => highlights = highlights.remove(highlight.id));
    unawaited(_saveState());
  }

  Future<void> _saveState() async {
    _cachedJourney = null;
    _journeyChanges.value++;
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
          content: Text(_l.couldNotSaveChanges),
          action: SnackBarAction(
            label: _l.retry,
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
          // Follows the phone's language (or Daylock's own language in
          // Android settings), falling back to English.
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: daylockLocales,
          onGenerateTitle: (context) => context.l10n.appTitle,
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
          // The tour sits above every route; the app stays mounted below it.
          builder: (context, child) => _withAppLocale(
            context,
            Stack(
              children: [
                child!,
                if (_tourStep != null)
                  Positioned.fill(
                    child: AppTourOverlay(
                      key: const ValueKey('app-tour'),
                      index: _tourStep!,
                      searchRoot: () => _navigatorKey.currentContext,
                      onShowPage: (page) {
                        if (page != selectedPage) {
                          setState(() => selectedPage = page);
                        }
                      },
                      onNext: () => _goToTourStop(_tourStep! + 1),
                      onBack: () => _goToTourStop(_tourStep! - 1),
                      onClose: _endTour,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );

  /// The app's text in the phone's language. This State sits above the
  /// app's localizations, so text is read through the navigator.
  AppLocalizations get _l =>
      _navigatorKey.currentContext?.l10n ?? englishStrings;

  /// Dates and weekday names follow the app's language.
  Widget _withAppLocale(BuildContext context, Widget child) {
    Intl.defaultLocale = Localizations.localeOf(context).toString();
    return child;
  }

  Widget _buildCalendar(DateTime? selectedDate) => CalendarScreen(
    areas: areas,
    initialDate: _now(),
    initialSelectedDate: selectedDate,
    todayPlan: todayPlan,
    history: history,
    events: [...events, ...calendarCache.visibleEvents],
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
        final index = events.indexWhere((existing) => existing.id == event.id);
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
      setState(() => events.removeWhere((existing) => existing.id == event.id));
      unawaited(_saveState());
    },
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
        notice: BlockingHealthNotice(
          status: _detectionBridge.status,
          onOpenAccessibility: () =>
              unawaited(_detectionBridge.openAccessibilitySettings()),
          onOpenAppInfo: () => unawaited(_detectionBridge.openAppSettings()),
        ),
        plan: planForToday,
        tomorrowPlan: planForTomorrow,
        onFreedomRequested: () => _openSettings(SettingsDestination.freedom),
        areas: areas,
        freedomEligibility: const FreedomService().evaluate(
          now: _now(),
          settings: freedomSettings,
          todayPlan: planForToday,
          tomorrowPlan: planForTomorrow,
        ),
        onOutcomeChanged: (task, outcome, reason) =>
            _changeTaskOutcome(task, planForToday, outcome, reason),
        onSettingsRequested: () => _openSettings(),
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
        onTaskEdited: (old, edited) {
          _refreshClock();
          if (!identical(planForTomorrow, tomorrowPlan) ||
              tomorrowPlan.isCommitted) {
            return;
          }
          final index = tomorrowPlan.tasks.indexOf(old);
          if (index < 0 || edited.id != old.id) return;
          setState(() {
            edited.areaId = areas.resolve(old.areaId).id == edited.areaId
                ? old.areaId
                : areas.forNewCommitment(edited.areaId).id;
            tomorrowPlan.tasks[index] = edited;
          });
          unawaited(_saveState());
        },
        onTaskRemoved: (task) => _removeTask(task, planForTomorrow),
        routines: routines,
        onRepeatChanged: (task, schedule) =>
            _changeRepeat(task, schedule, planForTomorrow),
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
      _buildJourneyScreen(),
    ];

    return PopScope(
      // System Back during the tour closes the tour, not the app.
      canPop: _tourStep == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _endTour();
      },
      child: Scaffold(
        // During the tour, tabs fade in rather than cut.
        body: _TourPageFade(
          key: ValueKey(selectedPage),
          enabled: _tourStep != null,
          child: pages[selectedPage],
        ),
        bottomNavigationBar: Builder(
          builder: (context) => NavigationBar(
            selectedIndex: selectedPage,
            onDestinationSelected: (index) {
              setState(() {
                selectedPage = index;
              });
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.wb_sunny_outlined),
                selectedIcon: const Icon(Icons.wb_sunny_rounded),
                label: context.l10n.today,
              ),
              NavigationDestination(
                icon: const Icon(Icons.bedtime_outlined),
                selectedIcon: const Icon(Icons.bedtime_rounded),
                label: context.l10n.plan,
              ),
              NavigationDestination(
                icon: const Icon(Icons.landscape_outlined),
                selectedIcon: const Icon(Icons.landscape_rounded),
                label: context.l10n.journey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJourneyScreen() => ValueListenableBuilder(
    valueListenable: _detectionBridge.status,
    builder: (context, detection, _) => JourneyScreen(
      breaks: detection.breaks,
      onWeeklyReview: _openWeeklyReview,
      areas: areas,
      highlights: highlights,
      data: _journeyData(),
      onAreaOpened: _openAreaJourney,
      onHighlightOpened: _openHighlight,
      onAddHighlight: () => _editHighlight(),
      onHighlightEdited: (highlight) => _editHighlight(original: highlight),
      onPastChapters: _openPastChapters,
      onManageAreas: _openAreas,
      onAllHighlights: _openHighlights,
      onDailyHistory: () => _openCalendar(),
    ),
  );
}

/// Fades a tab in when the guided tour switches to it. Outside the tour the
/// tab appears at once, as before.
class _TourPageFade extends StatelessWidget {
  final bool enabled;
  final Widget child;
  const _TourPageFade({super.key, required this.enabled, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!enabled || MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      // Starts partly visible so the swap never dips to black under the dim.
      tween: Tween(begin: .35, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - t)),
          child: child,
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../design/journey_surface.dart';
import '../design/daylock_scene.dart';
import '../design/daylock_surfaces.dart';
import '../models/onboarding_steps.dart';
import '../models/routine.dart';
import '../models/task.dart';
import '../services/instagram_detection_bridge.dart';
import '../services/notifications/notification_service.dart';
import 'instagram_detection_section.dart';
import 'restricted_apps_section.dart';

/// Presentation only: the app owns plans, persistence, and native enforcement.
class OnboardingScreen extends StatefulWidget {
  final InstagramDetectionBridge bridge;
  final NotificationService notifications;
  final int initialStep;
  final bool initialPowerReviewed;
  final Future<void> Function(bool)? savePowerReviewed;
  final Future<void> Function(int) saveStep;
  final Future<bool> Function(BuildContext) createGoal;
  final bool Function() hasGoal;
  final Future<void> Function() enableFreedom;
  final VoidCallback onExit;
  final VoidCallback? onAreasRequested,
      onRoutinesRequested,
      onJourneyRequested,
      onCalendarRequested,
      onSettingsRequested;
  const OnboardingScreen({
    super.key,
    required this.bridge,
    required this.notifications,
    required this.saveStep,
    required this.createGoal,
    required this.hasGoal,
    required this.enableFreedom,
    required this.onExit,
    this.initialStep = 0,
    this.initialPowerReviewed = false,
    this.savePowerReviewed,
    this.onAreasRequested,
    this.onRoutinesRequested,
    this.onJourneyRequested,
    this.onCalendarRequested,
    this.onSettingsRequested,
  });
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  late int _step;
  late bool _powerReviewed;
  bool _busy = false, _testing = false, _verified = false;
  DateTime? _testStarted;
  String? _testedPackage;
  Timer? _timeout;
  final _scroll = ScrollController();
  String? _message;
  String _exampleArea = 'Life';
  Routine _exampleRoutine = _newExampleRoutine();
  int _exampleDay = 1;
  String? _routineFeedback;
  static Routine _newExampleRoutine() => Routine(
    id: 'tutorial-example',
    name: 'Workout cycle',
    steps: [
      RoutineStep(id: 'a', name: 'Upper body', type: TaskType.goal),
      RoutineStep(id: 'b', name: 'Lower body', type: TaskType.goal),
    ],
  );
  void _tryRoutine(RoutineAction action) {
    final step = _exampleRoutine.nextStep.name;
    setState(() {
      // Exercise the actual routine model in memory; never save preview data.
      _exampleRoutine = _exampleRoutine.decide(
        DateTime(2000, 1, _exampleDay++),
        action,
      );
      _routineFeedback = switch (action) {
        RoutineAction.accept =>
          'Accept would add “$step” to tomorrow’s plan and advance the cycle.',
        RoutineAction.skip =>
          'Skip advances the cycle without adding a commitment.',
        RoutineAction.dismiss =>
          'Dismiss keeps “$step” as the next step for another day.',
      };
    });
  }

  static const _titles = [
    'Take Back Control',
    'Set Up App Blocking',
    'Choose Your Distractions',
    'Set Your First Commitment',
    'Your Daily Rhythm',
    'Give Your Commitments a Home',
    'Build Your Routines',
    'See Your Journey Grow',
    "You're Almost Ready!",
    "You're All Set!",
  ];
  @override
  void initState() {
    super.initState();
    _step = widget.initialStep.clamp(0, OnboardingSteps.ready);
    _powerReviewed = widget.initialPowerReviewed;
    WidgetsBinding.instance.addObserver(this);
    widget.bridge.status.addListener(_statusChanged);
    widget.notifications.status.addListener(_statusChanged);
    unawaited(widget.bridge.refresh());
    unawaited(widget.notifications.refresh());
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _scroll.dispose();
    widget.bridge.status.removeListener(_statusChanged);
    widget.notifications.status.removeListener(_statusChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _statusChanged() {
    if (!mounted) return;
    final s = widget.bridge.status.value;
    final fresh =
        _testStarted != null &&
        s.lastDetectedAt != null &&
        !s.lastDetectedAt!.isBefore(_testStarted!);
    if (_testing &&
        fresh &&
        s.lastDetectedPackage == _testedPackage &&
        s.selectedPackages.contains(_testedPackage) &&
        s.lastRestriction == 'lock_shown' &&
        s.lastLockLaunch == 'shown' &&
        s.enabled &&
        s.connected) {
      _timeout?.cancel();
      _verified = true;
      _testing = false;
      _message = 'Verified: Android displayed the Daylock lock screen.';
    }
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.bridge.refresh());
      unawaited(widget.notifications.refresh());
    }
  }

  Future<void> _move(int step) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await widget.saveStep(step);
      if (!mounted) return;
      if (step == OnboardingSteps.complete) {
        widget.onExit();
        return;
      }
      if (_scroll.hasClients) _scroll.jumpTo(0);
      setState(() => _step = step);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'Could not save setup progress. Please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _test() async {
    final s = widget.bridge.status.value;
    if (s.selectedPackages.isEmpty) return;
    setState(() {
      _testing = true;
      _verified = false;
      _testStarted = DateTime.fromMillisecondsSinceEpoch(
        DateTime.now().millisecondsSinceEpoch,
      );
      _testedPackage = s.selectedPackages.first;
      _message = 'Opening your selected app. Return to Daylock after checking the lock screen.';
    });
    await widget.bridge.testRestrictedApp(_testedPackage!);
    if (!mounted) return;
    _timeout?.cancel();
    _timeout = Timer(const Duration(seconds: 12), () {
      if (mounted && !_verified) {
        setState(() {
          _testing = false;
          _message =
              'Lock screen not confirmed. Check Accessibility is connected, then retry. '
              'Android may return Home or restrict the lock-screen launch. Open Permissions & Diagnostics in Settings for the recorded result.';
        });
      }
    });
    _statusChanged();
  }

  bool get _permissionReady {
    final s = widget.bridge.status.value;
    return !s.supported || (s.enabled && s.connected && s.error == null);
  }

  bool get _powerReady =>
      !widget.bridge.status.value.xiaomiDevice || _powerReviewed;

  Future<void> _reviewPower(bool reviewed) async {
    setState(() => _busy = true);
    try {
      await widget.savePowerReviewed?.call(reviewed);
      if (mounted) setState(() => _powerReviewed = reviewed);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'Could not save your confirmation. Please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool get _canContinue {
    final s = widget.bridge.status.value;
    return switch (_step) {
      1 => _permissionReady && _powerReady,
      2 =>
        !s.supported ||
            (s.selectedPackages.isNotEmpty &&
                s.selectionError == null &&
                s.error == null),
      3 => widget.hasGoal(),
      OnboardingSteps.test =>
        !s.supported ||
            (_verified &&
                _permissionReady &&
                _powerReady &&
                s.blockingEnabled &&
                s.selectedPackages.contains(_testedPackage) &&
                widget.hasGoal()),
      OnboardingSteps.ready =>
        !s.supported ||
            (_permissionReady &&
                _powerReady &&
                s.blockingEnabled &&
                s.selectedPackages.isNotEmpty &&
                widget.hasGoal()),
      _ => true,
    };
  }

  static const _cardHues = [
    DaylockHues.violet,
    DaylockHues.pink,
    DaylockHues.teal,
    DaylockHues.amber,
    DaylockHues.blue,
  ];
  int _cardIndex = 0;

  Widget _card(
    IconData icon,
    String title,
    String body, {
    Widget? action,
    bool checked = false,
  }) {
    final theme = Theme.of(context);
    final hue = checked
        ? daylockGold(theme.brightness)
        : _cardHues[_cardIndex++ % _cardHues.length];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: JourneySurface(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  DaylockIconTile(
                    icon: checked ? Icons.check_rounded : icon,
                    color: hue,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleLarge!.copyWith(fontSize: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                body,
                style: theme.textTheme.bodyMedium!.copyWith(
                  height: 1.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (action != null) ...[const SizedBox(height: 14), action],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _content() {
    final s = widget.bridge.status.value;
    final n = widget.notifications.status.value;
    switch (_step) {
      case 0:
        return [
          Text(
            'Plan your day. Earn your freedom. Keep your commitments before your distracting apps unlock.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 22),
          for (final entry in [
            (Icons.bedtime_outlined, 'Plan tomorrow'),
            (Icons.lock_outline, 'Block distractions'),
            (Icons.check_circle_outline, 'Keep your word'),
            (Icons.lock_open, 'Unlock apps'),
          ])
            _card(entry.$1, entry.$2, switch (entry.$2) {
              'Plan tomorrow' =>
                'Choose a few meaningful commitments the evening before.',
              'Block distractions' => 'You choose which apps to restrict.',
              'Keep your word' =>
                'Keep today’s commitments, then lock in tomorrow’s plan.',
              _ => 'Reach your Freedom Time and enjoy your earned break.',
            }),
        ];
      case 1:
        return [
          if (s.xiaomiDevice)
            _card(
              Icons.battery_saver_outlined,
              'Xiaomi / Poco: keep blocking active',
              'HyperOS can pause Daylock in the background even while Accessibility shows enabled. '
                  'A test inside Daylock may work while opening Instagram from Home does not.\n\n'
                  'In this app’s App info:\n'
                  '• Autostart: on\n'
                  '• Battery saver (or Power): No restrictions\n'
                  '• Other permissions → Display pop-up windows while running in the background: allow\n\n'
                  'Swiping Daylock away in Recents or using “Clean” can still stop blocking. '
                  'If that happens, Today shows a warning: turn Daylock off and on in Accessibility.\n\n'
                  'Use the settings for this installed Daylock app; Daylock Dev and the Play version have separate settings. '
                  'Daylock cannot read these Xiaomi choices. Confirm them yourself below, then test normal app openings too.',
              action: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    key: const ValueKey('setup-app-power'),
                    onPressed: widget.bridge.openAppSettings,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open Daylock App info'),
                  ),
                  CheckboxListTile(
                    key: const ValueKey('setup-power-reviewed'),
                    contentPadding: EdgeInsets.zero,
                    value: _powerReviewed,
                    onChanged: _busy
                        ? null
                        : (value) => _reviewPower(value == true),
                    title: const Text(
                      'I changed these settings for this Daylock app',
                    ),
                    subtitle: const Text(
                      'Your confirmation; not automatically verified.',
                    ),
                  ),
                ],
              ),
            ),
          _card(
            Icons.accessibility_new,
            'Accessibility access',
            !s.supported
                ? 'Blocking is available on Android. You can still use the planner here.'
                : s.enabled && s.connected
                ? 'Enabled and connected. Daylock is ready to detect selected apps.'
                : s.enabled
                ? 'Enabled. Waiting for Android to connect the service. Tap Refresh after returning.'
                : 'Daylock detects when a selected app opens and can show its lock screen or return Home. '
                      'Screen contents are never read. Access is optional and can be revoked in Android Settings.',
            checked: s.enabled && s.connected,
            action: !s.supported || (s.enabled && s.connected)
                ? null
                : FilledButton(
                    onPressed: () => InstagramDetectionSection.explainAndOpen(
                      context,
                      widget.bridge,
                    ),
                    child: const Text('Enable Accessibility'),
                  ),
          ),
          _card(
            Icons.notifications_none,
            'Notifications · optional',
            n.permission == NotificationPermission.allowed
                ? 'Allowed. Local reminders and fallback restriction notices can appear.'
                : 'Allow local reminders and a notice when Android cannot display the lock screen. You can continue without notifications.',
            checked: n.permission == NotificationPermission.allowed,
            action:
                n.permission == NotificationPermission.allowed ||
                    n.permission == NotificationPermission.unsupported
                ? null
                : OutlinedButton(
                    onPressed: () async {
                      if (n.askedBefore) {
                        await widget.notifications.openSettings();
                      } else {
                        await widget.notifications.requestPermission();
                      }
                      await widget.notifications.refresh();
                    },
                    child: const Text('Allow notifications'),
                  ),
          ),
          TextButton(
            onPressed: () => widget.bridge.refresh(),
            child: const Text('Refresh permission status'),
          ),
          const Text(
            'On Xiaomi / HyperOS, Samsung and Pixel, settings names vary. '
            'Choose this installed Daylock app’s service. If “Restricted settings” appears, '
            'review App info → Allow restricted settings only for a build you trust. '
            'If the service is enabled but disconnected, toggle it off and on once.',
          ),
        ];
      case 2:
        return [
          const Text(
            'Choose apps you want to open more intentionally. Your selections stay on this device.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Turning on app restrictions here also enables Freedom Control at your saved Freedom Time.',
          ),
          if (s.supported)
            RestrictedAppsSection(
              bridge: widget.bridge,
              onMasterChanged: (enabled) async {
                try {
                  if (enabled) await widget.enableFreedom();
                  await widget.bridge.setBlockingEnabled(enabled);
                } catch (_) {
                  if (mounted) {
                    setState(
                      () => _message =
                          'Could not save blocking settings. Please retry.',
                    );
                  }
                }
              },
            )
          else
            const Text('Installed-app selection is available on Android.'),
        ];
      case 3:
        return [
          _card(
            Icons.flag_outlined,
            'One small step for tomorrow',
            'Today’s plan is already locked. Your first new commitment goes into tomorrow’s real plan. '
                'Apps unlock when all eligible commitments are complete, Freedom Time is reached, and tomorrow’s plan is committed. '
                'An empty day does not earn Freedom.',
            checked: widget.hasGoal(),
            action: FilledButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      try {
                        await widget.createGoal(context);
                      } catch (_) {
                        if (mounted) {
                          setState(
                            () => _message =
                                'Could not save your commitment. Please retry.',
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
              icon: const Icon(Icons.add),
              label: const Text('Create a commitment'),
            ),
          ),
          if (widget.hasGoal())
            const Text(
              'Your plan already contains a commitment. You can continue without creating another.',
            ),
        ];
      case OnboardingSteps.overview:
        return [
          _card(
            Icons.today_outlined,
            'Today: keep your word',
            'See today’s commitments and progress. Start, pause and resume a stopwatch to record your effort. '
                'Time recorded does not complete a commitment: mark it complete yourself. '
                'Use the task menu to record an excuse when needed; excused tasks are excluded from Freedom eligibility.',
          ),
          _card(
            Icons.edit_note,
            'Plan: prepare tomorrow',
            'Add and edit tomorrow’s commitments, assign an Area, and review routine suggestions. '
                'Commit the plan when you are ready. Once committed, its commitments are locked against editing. '
                'They become your Today plan when the date changes.',
          ),
          _card(
            Icons.event_outlined,
            'Calendar & Daily History',
            'View dates, scheduled events and saved past days. Events help organise your schedule; '
                'they are separate from commitments and do not earn Freedom.',
            action: widget.onCalendarRequested == null
                ? null
                : OutlinedButton(
                    onPressed: widget.onCalendarRequested,
                    child: const Text('Explore Calendar'),
                  ),
          ),
          _card(
            Icons.lock_open,
            'Freedom has three conditions',
            'Complete all eligible commitments, reach your chosen Freedom Time, and commit tomorrow’s plan. '
                'Empty or all-excused days do not earn Freedom. '
                'Freedom Control and the app-restrictions switch must both be on for selected apps to be restricted.',
          ),
        ];
      case OnboardingSteps.areas:
        return [
          const Text(
            'Areas connect your commitments and progress to what matters: Life, study, fitness, work, or anything you choose.',
          ),
          const SizedBox(height: 16),
          _card(
            Icons.category_outlined,
            'Try an Area · example only',
            'Tap an Area below to see how a commitment gets a home. This preview does not create or change your data.',
            action: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final area in ['Life', 'Study', 'Gym'])
                      ChoiceChip(
                        label: Text(area),
                        selected: _exampleArea == area,
                        onSelected: (_) => setState(() => _exampleArea = area),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Read ten pages → $_exampleArea',
                  key: const ValueKey('tutorial-area-preview'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          _card(
            Icons.palette_outlined,
            'Make each Area yours',
            'Create Areas with a name, icon and colour. Choose an Area when adding a commitment. '
                'Life is the default when no other Area is selected. '
                'Archive an Area when that chapter is over; its history stays available in Past Chapters.',
            action: widget.onAreasRequested == null
                ? null
                : FilledButton(
                    onPressed: widget.onAreasRequested,
                    child: const Text('Open Areas'),
                  ),
          ),
        ];
      case OnboardingSteps.routines:
        return [
          _card(
            Icons.repeat_rounded,
            'A cycle you can keep returning to',
            'Create a routine with ordered steps, such as Upper body → Lower body. '
                'Plan offers one suggestion per routine for each planning date. '
                'Accept adds that step as a real commitment; Skip advances without adding it; Dismiss saves that step for another day.',
          ),
          _card(
            Icons.touch_app_outlined,
            'Try the cycle · example only',
            'Each tap previews a decision on another planning day. Nothing is added to your real plan.',
            action: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Next suggestion: ${_exampleRoutine.nextStep.name}',
                  key: const ValueKey('tutorial-routine-preview'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final action in RoutineAction.values)
                      OutlinedButton(
                        key: ValueKey('tutorial-routine-${action.name}'),
                        onPressed: () => _tryRoutine(action),
                        child: Text(switch (action) {
                          RoutineAction.accept => 'Try Accept',
                          RoutineAction.skip => 'Try Skip',
                          RoutineAction.dismiss => 'Try Dismiss',
                        }),
                      ),
                  ],
                ),
                if (_routineFeedback != null) ...[
                  const SizedBox(height: 12),
                  Semantics(liveRegion: true, child: Text(_routineFeedback!)),
                ],
              ],
            ),
          ),
          const Text(
            'Routine suggestions still need your review in an editable Plan. They never complete a commitment automatically.',
          ),
          if (widget.onRoutinesRequested != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: FilledButton(
                onPressed: widget.onRoutinesRequested,
                child: const Text('Open Routines'),
              ),
            ),
        ];
      case OnboardingSteps.journey:
        return [
          _card(
            Icons.auto_stories_outlined,
            'Progress in the areas that matter',
            'Journey brings together completed commitments, recorded time and saved Highlights. '
                'Open an Area to explore its progress and activity over time.',
          ),
          _card(
            Icons.auto_awesome_outlined,
            'Achievements: keep the moments',
            'Save a milestone with a title, date, note and illustration. Link it to an Area if you want. '
                'Achievements celebrate what you’re proud of; they do not complete tasks or unlock apps.',
          ),
          _card(
            Icons.history,
            'Daily History & Past Chapters',
            'Daily History opens your calendar and saved past days. Past Chapters keeps archived Areas within reach. '
                'Archiving an Area does not erase the progress you made.',
          ),
          if (widget.onJourneyRequested != null)
            FilledButton(
              onPressed: widget.onJourneyRequested,
              child: const Text('Explore Journey'),
            ),
          const SizedBox(height: 16),
          _card(
            Icons.settings_outlined,
            'Set it up your way',
            'Settings contains your Freedom Time, local notification reminders, restricted apps and permission diagnostics. '
                'Appearance lets you choose light, dark or system mode and a colour palette. '
                'You can replay this tutorial there any time.',
            action: widget.onSettingsRequested == null
                ? null
                : OutlinedButton(
                    onPressed: widget.onSettingsRequested,
                    child: const Text('Explore Settings'),
                  ),
          ),
        ];
      case OnboardingSteps.test:
        return [
          _card(
            Icons.verified_outlined,
            'Try your real app restriction',
            !s.supported
                ? 'Blocking tests require the Android app.'
                : 'Open a selected app and look for Daylock’s lock screen. Return here to see the result. '
                      'Also open it normally from Home after leaving Daylock in the background: this test confirms only one opening. '
                      'This uses your real Freedom conditions and never completes a goal for you.',
            checked: _verified,
            action: !s.supported
                ? null
                : FilledButton.icon(
                    onPressed:
                        !_testing &&
                            _permissionReady &&
                            s.blockingEnabled &&
                            s.freedomState == 'notEarned' &&
                            s.selectedPackages.isNotEmpty
                        ? _test
                        : null,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(_testing ? 'Checking…' : 'Test a selected app'),
                  ),
          ),
          if (s.supported &&
              (!s.blockingEnabled || s.freedomState == 'disabled'))
            OutlinedButton(
              onPressed: () async {
                try {
                  await widget.enableFreedom();
                  await widget.bridge.setBlockingEnabled(true);
                } catch (_) {
                  if (mounted) {
                    setState(
                      () => _message =
                          'Could not save blocking settings. Please retry.',
                    );
                  }
                }
              },
              child: const Text('Enable Freedom Control and app restrictions'),
            ),
          if (s.supported && s.freedomState != 'notEarned')
            Text(
              'Current Freedom: ${InstagramDetectionStatus.freedomLabel(s.freedomState)}. '
              'The real test needs Freedom Control on and Freedom not yet earned. '
              'You can leave setup and return from Settings when those conditions apply.',
            ),
          if (!_permissionReady)
            const Text(
              'Accessibility is not connected. Go back to permission setup.',
            ),
          if (!_powerReady)
            const Text(
              'Go back to Set Up App Blocking and confirm the Xiaomi battery setting before finishing setup.',
            ),
          if (s.error != null) Text(s.error!),
          TextButton(
            onPressed: () => widget.bridge.refresh(),
            child: const Text('Refresh and retry'),
          ),
        ];
      default:
        return [
          _card(
            Icons.auto_awesome,
            'Make room for what matters',
            'Your preferences and commitment are saved. Start with Today, plan tomorrow, and watch your Journey grow.',
            checked: true,
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _step == 0,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && !_busy) unawaited(_move(_step - 1));
    },
    child: Scaffold(
      body: Builder(
        builder: (context) {
          _cardIndex = 0;
          final theme = Theme.of(context);
          final sky = SceneColors.of(theme);
          final last = _step >= OnboardingSteps.ready;
          // Back and Save & leave stay pinned while the step scrolls.
          final controls = SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  if (_step > 0)
                    DaylockSkyButton(
                      tooltip: 'Previous step',
                      icon: Icons.arrow_back_rounded,
                      onPressed: _busy ? null : () => _move(_step - 1),
                    ),
                  const Spacer(),
                  DaylockSkyButton(
                    tooltip: 'Save & leave',
                    icon: Icons.close_rounded,
                    onPressed: _busy ? null : widget.onExit,
                  ),
                ],
              ),
            ),
          );
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _scroll,
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              DaylockScene(
                                mood: last ? SceneMood.earned : SceneMood.dawn,
                                progress:
                                    (_step + 1) / OnboardingSteps.complete,
                                height: last ? 300 : 236,
                                child: SafeArea(
                                  bottom: false,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      8,
                                      12,
                                      0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 48),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            12,
                                            4,
                                            12,
                                            0,
                                          ),
                                          child: Text(
                                            'Step ${_step + 1} of ${OnboardingSteps.complete}',
                                            style: theme.textTheme.labelLarge!
                                                .copyWith(
                                                  color: sky.onSkyMuted,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              AnimatedSwitcher(
                                duration:
                                    MediaQuery.disableAnimationsOf(context)
                                    ? Duration.zero
                                    : const Duration(milliseconds: 200),
                                child: Padding(
                                  key: ValueKey(_step),
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    4,
                                    24,
                                    0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Semantics(
                                        header: true,
                                        child: Text(
                                          _titles[_step],
                                          style: theme.textTheme.headlineLarge,
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      ..._content(),
                                      if (_message != null)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          child: Semantics(
                                            liveRegion: true,
                                            child: Text(_message!),
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
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _busy || !_canContinue
                                  ? null
                                  : () => _move(_step + 1),
                              child: Text(switch (_step) {
                                0 => 'Get Started',
                                OnboardingSteps.test => 'Finish Setup',
                                OnboardingSteps.ready => 'Go to Daylock',
                                _ => 'Continue',
                              }),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(top: 0, left: 0, right: 0, child: controls),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

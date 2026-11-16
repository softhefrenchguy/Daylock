import '../l10n/l10n.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../design/journey_surface.dart';
import '../design/daylock_scene.dart';
import '../design/daylock_surfaces.dart';
import '../models/onboarding_steps.dart';
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

  /// Starts the guided tour of the real app once setup closes. When null,
  /// the last step simply finishes setup.
  final VoidCallback? onTourRequested;
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
    this.onTourRequested,
  });
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  late int _step;

  /// True when the last move went forward; steps slide in from that side.
  bool _forward = true;
  late bool _powerReviewed;
  bool _busy = false, _testing = false, _verified = false;
  DateTime? _testStarted;
  String? _testedPackage;
  Timer? _timeout;
  final _scroll = ScrollController();
  String? _message;
  String _title(int step) {
    final l = context.l10n;
    return switch (step) {
      0 => l.setupTitleWelcome,
      1 => l.setupTitleBlocking,
      2 => l.setupTitleApps,
      3 => l.setupTitleCommitment,
      OnboardingSteps.test => l.setupTitleTest,
      OnboardingSteps.ready => l.setupTitleReady,
      // Retired feature-tour pages; the tour now runs in the real app.
      _ => '',
    };
  }

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep.clamp(0, OnboardingSteps.ready);
    // Progress saved on a retired tour page resumes at the next real page.
    if (_step >= OnboardingSteps.overview && _step < OnboardingSteps.test) {
      _step = _blockingSetUp ? OnboardingSteps.test : OnboardingSteps.ready;
    }
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
      _message = context.l10n.setupVerified;
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

  /// Saves and shows [step]. Returns false when progress couldn't be saved.
  Future<bool> _move(int step) async {
    if (_busy) return false;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await widget.saveStep(step);
      if (!mounted) return false;
      if (step == OnboardingSteps.complete) {
        widget.onExit();
        return true;
      }
      if (_scroll.hasClients && _scroll.offset > 0) {
        final reduce = MediaQuery.disableAnimationsOf(context);
        unawaited(
          _scroll.animateTo(
            0,
            duration: reduce
                ? Duration.zero
                : const Duration(milliseconds: 360),
            curve: Curves.easeInOutCubic,
          ),
        );
      }
      setState(() {
        _forward = step > _step;
        _step = step;
      });
      return true;
    } catch (_) {
      if (mounted) {
        setState(() => _message = context.l10n.setupSaveProgressFailed);
      }
      return false;
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
      _message = context.l10n.setupOpeningApp;
    });
    await widget.bridge.testRestrictedApp(_testedPackage!);
    if (!mounted) return;
    _timeout?.cancel();
    _timeout = Timer(const Duration(seconds: 12), () {
      if (mounted && !_verified) {
        setState(() {
          _testing = false;
          _message = context.l10n.setupLockNotConfirmed;
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

  /// App blocking is optional. Without Accessibility, setup skips choosing
  /// apps and the blocking test; Daylock still works as a planner.
  bool get _blockingSetUp {
    final s = widget.bridge.status.value;
    return s.supported && _permissionReady;
  }

  /// The pages this person actually sees, in order.
  List<int> get _sequence => [
    0,
    1,
    if (_blockingSetUp) 2,
    3,
    if (_blockingSetUp) OnboardingSteps.test,
    OnboardingSteps.ready,
  ];

  int get _position {
    final index = _sequence.indexOf(_step);
    return index < 0 ? _sequence.where((s) => s < _step).length : index;
  }

  int get _nextStep {
    if (_step >= OnboardingSteps.ready) return OnboardingSteps.complete;
    return _sequence.firstWhere(
      (s) => s > _step,
      orElse: () => OnboardingSteps.ready,
    );
  }

  int get _previousStep =>
      _sequence.lastWhere((s) => s < _step, orElse: () => 0);

  Future<void> _finish({required bool tour}) async {
    final done = await _move(OnboardingSteps.complete);
    if (done && tour) widget.onTourRequested?.call();
  }

  Future<void> _reviewPower(bool reviewed) async {
    setState(() => _busy = true);
    try {
      await widget.savePowerReviewed?.call(reviewed);
      if (mounted) setState(() => _powerReviewed = reviewed);
    } catch (_) {
      if (mounted) {
        setState(() => _message = context.l10n.setupSaveConfirmationFailed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool get _canContinue {
    final s = widget.bridge.status.value;
    return switch (_step) {
      // Accessibility is optional; the Xiaomi check only matters once on.
      1 => !_blockingSetUp || _powerReady,
      2 =>
        !s.supported ||
            (s.selectedPackages.isNotEmpty &&
                s.selectionError == null &&
                s.error == null),
      3 => widget.hasGoal(),
      // The test can be skipped; "Finish Setup" appears only once verified.
      OnboardingSteps.test => widget.hasGoal(),
      OnboardingSteps.ready => widget.hasGoal(),
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
            context.l10n.setupWelcomeBody,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 22),
          for (final entry in [
            (
              Icons.bedtime_outlined,
              context.l10n.planTomorrow,
              context.l10n.setupWelcomePlan,
            ),
            (
              Icons.lock_outline,
              context.l10n.setupBlockDistractions,
              context.l10n.setupWelcomeBlock,
            ),
            (
              Icons.check_circle_outline,
              context.l10n.setupKeepYourWord,
              context.l10n.setupWelcomeKeep,
            ),
            (
              Icons.lock_open,
              context.l10n.setupUnlockApps,
              context.l10n.setupWelcomeUnlock,
            ),
          ])
            _card(entry.$1, entry.$2, entry.$3),
        ];
      case 1:
        return [
          if (s.xiaomiDevice)
            _card(
              Icons.battery_saver_outlined,
              context.l10n.setupXiaomiTitle,
              context.l10n.setupXiaomiBody,
              action: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    key: const ValueKey('setup-app-power'),
                    onPressed: widget.bridge.openAppSettings,
                    icon: const Icon(Icons.open_in_new),
                    label: Text(context.l10n.setupOpenAppInfo),
                  ),
                  CheckboxListTile(
                    key: const ValueKey('setup-power-reviewed'),
                    contentPadding: EdgeInsets.zero,
                    value: _powerReviewed,
                    onChanged: _busy
                        ? null
                        : (value) => _reviewPower(value == true),
                    title: Text(context.l10n.setupXiaomiConfirm),
                    subtitle: Text(context.l10n.setupXiaomiConfirmNote),
                  ),
                ],
              ),
            ),
          if (s.supported)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                context.l10n.setupBlockingOptional,
                key: const ValueKey('setup-blocking-optional'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          _card(
            Icons.accessibility_new,
            context.l10n.setupAccessibilityTitle,
            !s.supported
                ? context.l10n.setupBlockingAndroidOnly
                : s.enabled && s.connected
                ? context.l10n.setupAccessibilityConnected
                : s.enabled
                ? context.l10n.setupAccessibilityWaiting
                : context.l10n.setupAccessibilityExplain,
            checked: s.enabled && s.connected,
            action: !s.supported || (s.enabled && s.connected)
                ? null
                : FilledButton(
                    onPressed: () => InstagramDetectionSection.explainAndOpen(
                      context,
                      widget.bridge,
                    ),
                    child: Text(context.l10n.setupEnableAccessibility),
                  ),
          ),
          _card(
            Icons.notifications_none,
            context.l10n.setupNotificationsTitle,
            n.permission == NotificationPermission.allowed
                ? context.l10n.setupNotificationsAllowed
                : context.l10n.setupNotificationsExplain,
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
                    child: Text(context.l10n.setupAllowNotifications),
                  ),
          ),
          TextButton(
            onPressed: () => widget.bridge.refresh(),
            child: Text(context.l10n.setupRefreshPermissions),
          ),
          Text(context.l10n.setupAccessibilityOemHelp),
        ];
      case 2:
        return [
          Text(context.l10n.setupChooseAppsBody),
          const SizedBox(height: 12),
          Text(context.l10n.setupRestrictionsEnableFreedom),
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
                      () => _message = context.l10n.setupSaveBlockingFailed,
                    );
                  }
                }
              },
            )
          else
            Text(context.l10n.setupAppSelectionAndroidOnly),
        ];
      case 3:
        return [
          _card(
            Icons.flag_outlined,
            context.l10n.setupOneSmallStep,
            context.l10n.setupFirstCommitmentBody,
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
                                context.l10n.setupSaveCommitmentFailed,
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
              icon: const Icon(Icons.add),
              label: Text(context.l10n.setupCreateCommitment),
            ),
          ),
          if (widget.hasGoal()) Text(context.l10n.setupAlreadyHasCommitment),
        ];
      case OnboardingSteps.test:
        return [
          _card(
            Icons.verified_outlined,
            context.l10n.setupTestTitle,
            !s.supported
                ? context.l10n.setupTestAndroidOnly
                : context.l10n.setupTestBody,
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
                    label: Text(
                      _testing
                          ? context.l10n.setupChecking
                          : context.l10n.setupTestSelectedApp,
                    ),
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
                      () => _message = context.l10n.setupSaveBlockingFailed,
                    );
                  }
                }
              },
              child: Text(context.l10n.setupEnableFreedomAndRestrictions),
            ),
          if (s.supported && s.freedomState != 'notEarned')
            Text(
              context.l10n.setupTestNeedsFreedom(
                context.l10n.freedomState(s.freedomState),
              ),
            ),
          if (!_permissionReady)
            Text(context.l10n.setupAccessibilityNotConnected),
          if (!_powerReady) Text(context.l10n.setupConfirmXiaomi),
          if (s.error != null) Text(s.error!),
          TextButton(
            onPressed: () => widget.bridge.refresh(),
            child: Text(context.l10n.setupRefreshRetry),
          ),
        ];
      default:
        return [
          _card(
            Icons.auto_awesome,
            context.l10n.setupReadyTitle,
            context.l10n.setupReadyBody,
            checked: true,
          ),
          if (widget.onTourRequested != null)
            _card(
              Icons.explore_outlined,
              context.l10n.setupTourTitle,
              context.l10n.setupTourBody,
            ),
          if (s.supported && !_blockingSetUp)
            _card(
              Icons.lock_open_outlined,
              context.l10n.setupBlockingOff,
              context.l10n.setupBlockingOffBody,
            ),
          if (widget.onTourRequested != null)
            Center(
              child: TextButton(
                key: const ValueKey('setup-skip-tour'),
                onPressed: _busy || !_canContinue
                    ? null
                    : () => _finish(tour: false),
                child: Text(context.l10n.setupSkipTour),
              ),
            ),
        ];
    }
  }

  Duration _motion(int milliseconds) => MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : Duration(milliseconds: milliseconds);

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _step == 0,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && !_busy) unawaited(_move(_previousStep));
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
              padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 0),
              child: Row(
                children: [
                  if (_step > 0)
                    DaylockSkyButton(
                      tooltip: context.l10n.previousStep,
                      icon: Icons.arrow_back_rounded,
                      onPressed: _busy ? null : () => _move(_previousStep),
                    ),
                  const Spacer(),
                  DaylockSkyButton(
                    tooltip: context.l10n.saveAndLeave,
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
                              AnimatedSize(
                                duration: _motion(500),
                                curve: Curves.easeInOutCubic,
                                alignment: Alignment.topCenter,
                                child: AnimatedSwitcher(
                                  duration: _motion(600),
                                  switchInCurve: Curves.easeOut,
                                  switchOutCurve: Curves.easeIn,
                                  layoutBuilder: (current, previous) => Stack(
                                    alignment: Alignment.topCenter,
                                    children: [...previous, ?current],
                                  ),
                                  child: DaylockScene(
                                    key: ValueKey(last),
                                    mood: last
                                        ? SceneMood.earned
                                        : SceneMood.dawn,
                                    progress:
                                        (_position + 1) / _sequence.length,
                                    height: last ? 300 : 236,
                                    child: SafeArea(
                                      bottom: false,
                                      child: Padding(
                                        padding:
                                            const EdgeInsetsDirectional.fromSTEB(
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
                                              padding:
                                                  const EdgeInsetsDirectional.fromSTEB(
                                                    12,
                                                    4,
                                                    12,
                                                    0,
                                                  ),
                                              child: Text(
                                                context.l10n.stepNOfM(
                                                  _position + 1,
                                                  _sequence.length,
                                                ),
                                                style: theme
                                                    .textTheme
                                                    .labelLarge!
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
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: _motion(380),
                                reverseDuration: _motion(220),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                // Keep both steps pinned to the top while
                                // they cross, so the page doesn't jump.
                                layoutBuilder: (current, previous) => Stack(
                                  alignment: Alignment.topCenter,
                                  children: [...previous, ?current],
                                ),
                                transitionBuilder: (child, animation) {
                                  final incoming = child.key == ValueKey(_step);
                                  // Forward: new step from the right, old to
                                  // the left. Back mirrors it.
                                  final side =
                                      (_forward == incoming ? 1.0 : -1.0) * .08;
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween(
                                        begin: Offset(side, 0),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Padding(
                                  key: ValueKey(_step),
                                  padding: const EdgeInsetsDirectional.fromSTEB(
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
                                          _title(_step),
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
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            24,
                            8,
                            24,
                            16,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _busy || !_canContinue
                                  ? null
                                  : _step == OnboardingSteps.ready
                                  ? () => _finish(
                                      tour: widget.onTourRequested != null,
                                    )
                                  : () => _move(_nextStep),
                              child: Text(switch (_step) {
                                0 => context.l10n.getStarted,
                                1
                                    when !_blockingSetUp &&
                                        widget.bridge.status.value.supported =>
                                  context.l10n.continueWithoutBlocking,
                                OnboardingSteps.test when !_verified =>
                                  context.l10n.skipTestForNow,
                                OnboardingSteps.test =>
                                  context.l10n.finishSetup,
                                OnboardingSteps.ready
                                    when widget.onTourRequested != null =>
                                  context.l10n.takeTheTour,
                                OnboardingSteps.ready =>
                                  context.l10n.goToDaylock,
                                _ => context.l10n.continueLabel,
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

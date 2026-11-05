import 'dart:async';

import 'package:flutter/material.dart';

import '../design/journey_surface.dart';
import '../services/instagram_detection_bridge.dart';
import '../services/notifications/notification_service.dart';
import 'instagram_detection_section.dart';
import 'restricted_apps_section.dart';

/// Presentation only: the app owns plans, persistence, and native enforcement.
class OnboardingScreen extends StatefulWidget {
  final InstagramDetectionBridge bridge;
  final NotificationService notifications;
  final int initialStep;
  final Future<void> Function(int) saveStep;
  final Future<bool> Function(BuildContext) createGoal;
  final bool Function() hasGoal;
  final Future<void> Function() enableFreedom;
  final VoidCallback onExit;
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
  });
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  late int _step;
  bool _busy = false, _testing = false, _verified = false;
  DateTime? _testStarted;
  String? _testedPackage;
  Timer? _timeout;
  final _scroll = ScrollController();
  String? _message;
  static const _titles = [
    'Take Back Control',
    'Set Up App Blocking',
    'Choose Your Distractions',
    'Set Your First Goal',
    "You're Almost Ready!",
    "You're All Set!",
  ];
  @override
  void initState() {
    super.initState();
    _step = widget.initialStep.clamp(0, 5);
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
      if (step == 6) {
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

  bool get _canContinue {
    final s = widget.bridge.status.value;
    return switch (_step) {
      1 => _permissionReady,
      2 =>
        !s.supported ||
            (s.selectedPackages.isNotEmpty &&
                s.selectionError == null &&
                s.error == null),
      3 => widget.hasGoal(),
      4 =>
        !s.supported ||
            (_verified &&
                _permissionReady &&
                s.blockingEnabled &&
                s.selectedPackages.contains(_testedPackage) &&
                widget.hasGoal()),
      5 =>
        !s.supported ||
            (_permissionReady &&
                s.blockingEnabled &&
                s.selectedPackages.isNotEmpty &&
                widget.hasGoal()),
      _ => true,
    };
  }

  Widget _card(
    IconData icon,
    String title,
    String body, {
    Widget? action,
    bool checked = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: JourneySurface(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  checked ? Icons.check_circle : icon,
                  color: checked
                      ? Colors.green
                      : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(body, style: const TextStyle(height: 1.5)),
            if (action != null) ...[const SizedBox(height: 16), action],
          ],
        ),
      ),
    ),
  );
  List<Widget> _content() {
    final s = widget.bridge.status.value;
    final n = widget.notifications.status.value;
    switch (_step) {
      case 0:
        return [
          const Text(
            'Stop mindless scrolling. Complete your goals before unlocking your distracting apps.',
          ),
          const SizedBox(height: 28),
          for (final entry in [
            (Icons.edit_note, 'Create goals'),
            (Icons.lock_outline, 'Block distractions'),
            (Icons.check_circle_outline, 'Complete goals'),
            (Icons.lock_open, 'Unlock apps'),
          ])
            _card(entry.$1, entry.$2, switch (entry.$2) {
              'Create goals' => 'Choose one meaningful step for tomorrow.',
              'Block distractions' => 'You choose which apps to restrict.',
              'Complete goals' =>
                'Keep your commitments, then commit tomorrow’s plan.',
              _ => 'Reach your Freedom Time and enjoy your earned break.',
            }),
        ];
      case 1:
        return [
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
      case 4:
        return [
          _card(
            Icons.verified_outlined,
            'Try your real app restriction',
            !s.supported
                ? 'Blocking tests require the Android app.'
                : 'Open a selected app and look for Daylock’s lock screen. Return here to see the result. '
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
      appBar: AppBar(
        leading: _step == 0
            ? null
            : IconButton(
                tooltip: 'Previous step',
                icon: const Icon(Icons.arrow_back),
                onPressed: _busy ? null : () => _move(_step - 1),
              ),
        actions: [
          IconButton(
            onPressed: _busy ? null : widget.onExit,
            tooltip: 'Save & leave',
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'SETUP · ${_step + 1} OF 6',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(value: (_step + 1) / 6),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: AnimatedSwitcher(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 200),
                      child: Column(
                        key: ValueKey(_step),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _titles[_step],
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 24),
                          ..._content(),
                          if (_message != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Semantics(
                                liveRegion: true,
                                child: Text(_message!),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy || !_canContinue
                          ? null
                          : () => _move(_step + 1),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(switch (_step) {
                          0 => 'Get Started',
                          4 => 'Finish Setup',
                          5 => 'Go to Daylock',
                          _ => 'Continue',
                        }),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

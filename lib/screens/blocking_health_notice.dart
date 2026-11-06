import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../design/daylock_theme.dart';
import '../services/instagram_detection_bridge.dart';

/// Warns on Today when app blocking is set up but Android is not running
/// Daylock's Accessibility service. Xiaomi / HyperOS stops the service when
/// the app is swiped away or "cleaned", and Android does not restart it until
/// the user turns it off and on, so without this the lock silently stops.
class BlockingHealthNotice extends StatefulWidget {
  final ValueListenable<InstagramDetectionStatus> status;
  final VoidCallback onOpenAccessibility;
  final VoidCallback onOpenAppInfo;

  /// Android connects the service shortly after the app starts; wait before
  /// warning so a normal launch never flashes the notice.
  final Duration grace;

  const BlockingHealthNotice({
    super.key,
    required this.status,
    required this.onOpenAccessibility,
    required this.onOpenAppInfo,
    this.grace = const Duration(seconds: 3),
  });

  static bool needsAttention(InstagramDetectionStatus s) =>
      s.supported &&
      s.blockingEnabled &&
      s.selectedPackages.isNotEmpty &&
      !(s.enabled && s.connected);

  @override
  State<BlockingHealthNotice> createState() => _BlockingHealthNoticeState();
}

class _BlockingHealthNoticeState extends State<BlockingHealthNotice> {
  Timer? _timer;
  bool _show = false;

  @override
  void initState() {
    super.initState();
    widget.status.addListener(_update);
    _update();
  }

  @override
  void didUpdateWidget(BlockingHealthNotice old) {
    super.didUpdateWidget(old);
    if (old.status != widget.status) {
      old.status.removeListener(_update);
      widget.status.addListener(_update);
      _update();
    }
  }

  void _update() {
    final problem = BlockingHealthNotice.needsAttention(widget.status.value);
    if (!problem) {
      _timer?.cancel();
      _timer = null;
      if (_show) setState(() => _show = false);
      return;
    }
    if (_show || _timer != null) return;
    _timer = Timer(widget.grace, () {
      _timer = null;
      if (mounted && BlockingHealthNotice.needsAttention(widget.status.value)) {
        setState(() => _show = true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.status.removeListener(_update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return const SizedBox.shrink();
    final s = widget.status.value;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final stopped = s.enabled; // Switched on, but Android is not running it.
    final body = stopped
        ? 'Android stopped Daylock in the background, so your selected apps '
              'open freely. In Accessibility, turn Daylock off and on again.'
        : 'Accessibility access for Daylock is off, so your selected apps '
              'open freely. Turn it on to bring the lock back.';
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Material(
        key: const ValueKey('blocking-health-notice'),
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(DaylockSpace.cardRadius),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lock_open_rounded, color: scheme.onErrorContainer),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      stopped
                          ? 'App blocking has stopped'
                          : 'App blocking is off',
                      style: theme.textTheme.titleMedium!.copyWith(
                        color: scheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                body,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: scheme.onErrorContainer,
                ),
              ),
              if (stopped && s.xiaomiDevice)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'To stop it happening again on Xiaomi / Poco: in Daylockâ€™s '
                    'App info allow Autostart, set Battery saver to No '
                    'restrictions, allow pop-ups while running in the '
                    'background, and avoid swiping Daylock away in Recents.',
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: scheme.onErrorContainer,
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                children: [
                  TextButton(
                    key: const ValueKey('blocking-health-accessibility'),
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.onErrorContainer,
                    ),
                    onPressed: widget.onOpenAccessibility,
                    child: const Text('Open Accessibility'),
                  ),
                  if (s.xiaomiDevice)
                    TextButton(
                      key: const ValueKey('blocking-health-app-info'),
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.onErrorContainer,
                      ),
                      onPressed: widget.onOpenAppInfo,
                      child: const Text('Open App info'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

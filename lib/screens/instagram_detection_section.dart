import 'package:flutter/material.dart';

import '../design/daylock_theme.dart';
import '../design/daylock_widgets.dart';
import '../design/journey_surface.dart';
import '../services/instagram_detection_bridge.dart';
import 'restricted_apps_section.dart';

enum DetectionSectionMode { full, restricted, diagnostics }

class InstagramDetectionSection extends StatelessWidget {
  final InstagramDetectionBridge bridge;
  final DetectionSectionMode mode;
  const InstagramDetectionSection({
    super.key,
    required this.bridge,
    this.mode = DetectionSectionMode.full,
  });

  Future<void> _explainAndOpen(BuildContext context) async {
    final agree = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('App restriction permission'),
        content: const Text(
          'Daylock uses Android Accessibility to detect when a selected app opens, including while Daylock is in the background. '
          'It saves only the latest selected-app detection, Freedom status and restriction result on this device; nothing is sent to a server. '
          'Installed-app lists and selections stay on this device. It does not read screen content or collect browsing history. '
          'With the separate app restrictions switch enabled, it can return Home and show a branded Daylock lock screen when Freedom is not earned. '
          'Window package changes are compared only to cancel actions if you switch apps; other app names are not retained. '
          'It does not draw overlays or restrict unselected apps.\n\n'
          'You choose whether to enable “Daylock app restrictions” in Android Accessibility Settings. '
          'You can disable it there at any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('agree-detection'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Agree and open Settings'),
          ),
        ],
      ),
    );
    if (context.mounted && agree == true) {
      await bridge.openAccessibilitySettings();
    }
  }

  Future<void> _changeBlocking(BuildContext context, bool enabled) async {
    if (!enabled) {
      await bridge.setBlockingEnabled(false);
      return;
    }
    final agree = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Enable app restrictions?'),
        content: const Text(
          'When Freedom Control is on and Freedom is not earned, Daylock uses Accessibility to leave a selected app and show its own lock screen. '
          'Installed-app lists and selections stay on this device. It does not read screen content or collect browsing history. Only the latest selected-app detection and restriction result stay on this device. '
          'Other window package names are compared only to cancel a pending action if you switch apps; they are not retained. '
          'You can turn blocking off here or revoke Accessibility access at any time.\n\n'
          'Freedom inputs stay valid for their calendar date without reopening Daylock. If current state is missing or invalid, Daylock offers a recovery screen with Open Daylock and Disable Blocking; subsequent openings are allowed while recovery is needed. '
          'This is a voluntary restriction, not a tamper-proof or parental-control system.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm-instagram-blocking'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enable blocking'),
          ),
        ],
      ),
    );
    if (context.mounted && agree == true) await bridge.setBlockingEnabled(true);
  }

  @override
  Widget build(BuildContext context) => mode == DetectionSectionMode.restricted
      ? RestrictedAppsSection(
          bridge: bridge,
          onMasterChanged: (value) => _changeBlocking(context, value),
        )
      : ValueListenableBuilder<InstagramDetectionStatus>(
          valueListenable: bridge.status,
          builder: (context, status, _) => Column(
            key: const ValueKey('instagram-detection-section'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (mode == DetectionSectionMode.full) ...[
                const DaylockLabel('APP RESTRICTIONS'),
                const SizedBox(height: DaylockSpace.sm),
                const Text(
                  'Accessibility detects selected apps opening in the background. Optional blocking shows a Daylock lock screen or returns Home until Freedom is earned. If the screen cannot appear, a notification explains the block when Android permits it.',
                ),
                SwitchListTile(
                  key: const ValueKey('instagram-blocking-enabled'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('App restrictions'),
                  subtitle: const Text(
                    'Separate from Freedom Control. Off by default.',
                  ),
                  value: status.blockingEnabled,
                  onChanged: status.supported && status.error == null
                      ? (value) => _changeBlocking(context, value)
                      : null,
                ),
                Text(
                  status.error != null
                      ? 'App restriction status unavailable'
                      : !status.blockingEnabled
                      ? 'App restrictions: off'
                      : !status.enabled || !status.connected
                      ? 'App restrictions: waiting for Accessibility access'
                      : status.freedomState == 'disabled'
                      ? 'Selected apps allowed — Freedom Control is off'
                      : status.freedomState == 'earned'
                      ? 'Selected apps allowed — Freedom earned'
                      : status.freedomState == 'unknown'
                      ? 'Blocking paused — open Daylock to refresh Freedom state'
                      : 'App restrictions ready — launch and navigation depend on Android',
                  key: const ValueKey('instagram-blocking-status'),
                ),
                if (status.lastRestriction != null)
                  Text(switch (status.lastRestriction) {
                    'recovery_shown' => 'Last attempt: recovery screen shown. Open Daylock to refresh plans or disable blocking.',
                    'lock_shown' =>
                      'Last restriction attempt: Daylock lock screen shown.',
                    'state_unknown' => 'Last attempt: Selected apps allowed while Freedom state was unavailable.',
                    'lock_launch_requested' => 'Last attempt: lock screen requested; display not yet confirmed.',
                    'lock_fallback_posted' => 'Last attempt: lock screen not confirmed; app restriction notification posted. Android controls its delivery.',
                    'lock_fallback_unavailable' => 'Last attempt: lock screen not confirmed. Allow notifications and the App restriction notices channel in Android settings for fallback notices.',
                    'home_only' => 'Last attempt: Home requested; lock screen was not confirmed.',
                    'lock_launch_failed' || 'lock_launch_unconfirmed' => 'Last attempt: lock screen was not confirmed. Android may restrict background launches.',
                    'home_failed' => 'Last attempt: Android rejected Home navigation. Restriction could not be applied.',
                    _ => 'Last restriction attempt could not be verified.',
                  }),
                const SizedBox(height: DaylockSpace.md),
                Text(
                  status.error != null
                      ? 'Service status unavailable'
                      : !status.supported
                      ? 'Native detection is available on Android only.'
                      : !status.enabled
                      ? 'Accessibility service: disabled'
                      : status.connected
                      ? 'Accessibility service: enabled and connected'
                      : 'Accessibility service: enabled — waiting for Android to connect',
                  key: const ValueKey('detection-service-status'),
                ),
                if (status.blockingSaveFailed)
                  const Text(
                    'The blocking choice could not be saved. Disabling takes effect now, but may not survive a restart. Revoke Accessibility access if necessary.',
                  ),
                const SizedBox(height: DaylockSpace.sm),
                Text(
                  status.lastDetectedAt == null
                      ? 'No selected app has been detected yet.'
                      : 'Last restricted-app detection: ${MaterialLocalizations.of(context).formatMediumDate(status.lastDetectedAt!)} '
                            '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(status.lastDetectedAt!), alwaysUse24HourFormat: true)}',
                  key: const ValueKey('instagram-last-detection'),
                ),
                if (status.freedomAtDetection != null)
                  Text(
                    'Freedom at that detection: ${InstagramDetectionStatus.freedomLabel(status.freedomAtDetection!)}',
                  ),
                const SizedBox(height: DaylockSpace.sm),
                Text(
                  'Current native Freedom state: ${InstagramDetectionStatus.freedomLabel(status.freedomState)}',
                  key: const ValueKey('native-freedom-status'),
                ),
                if (status.freedomState == 'unknown' && status.supported)
                  Text(
                    status.freedomReason == 'focus_needs_refresh'
                        ? 'An active Focus session needs Daylock to reconcile its timer. Native detection does not mark it complete.'
                        : 'Current dated state is unavailable. Open Daylock to reconcile plans or turn blocking off. Valid current-day inputs do not expire after five minutes.',
                  ),
                if (status.freedomReason == 'rollover_reconciled')
                  const Text(
                    'New day: using the saved plan for this date. Open Daylock to archive history and prepare the following day.',
                  ),
                if (status.freedomReason == 'no_eligible_commitments')
                  const Text(
                    'No eligible commitments. Empty or all-excused days do not earn Freedom.',
                  ),
                if (status.detectionSaveFailed)
                  const Text(
                    'The latest detection could not be persisted and may not survive a restart.',
                  ),
                if (status.error != null)
                  Text(
                    status.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (status.error != null && status.supported)
                  TextButton(
                    onPressed: () => bridge.setBlockingEnabled(false),
                    child: const Text('Turn blocking off'),
                  ),
                const SizedBox(height: DaylockSpace.md),
                const Text(
                  'Android Settings → Accessibility → Downloaded/Installed apps → Daylock app restrictions. Turn the service on manually. Names vary by phone.',
                ),
                const SizedBox(height: DaylockSpace.sm),
                const Text(
                  'If Android 15 shows “Restricted settings”, inspect Daylock’s App info for “Allow restricted settings” and confirm only for this development build you trust.',
                ),
                const SizedBox(height: DaylockSpace.sm),
              ] else ...[
                JourneySurface(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          status.error != null
                              ? 'Service status unavailable'
                              : !status.supported
                              ? 'Available on Android only'
                              : 'Accessibility service: ${status.enabled ? 'enabled' : 'disabled'}',
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Service ${status.connected ? 'connected' : 'disconnected'}',
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'App restrictions: ${status.blockingEnabled ? 'on' : 'off'}',
                        ),
                        const SizedBox(height: 10),
                        Text('${status.selectedPackages.length} selected apps'),
                        if (status.selectionError != null)
                          Text(status.selectionError!),
                        const SizedBox(height: 10),
                        Text(
                          'Native Freedom: ${InstagramDetectionStatus.freedomLabel(status.freedomState)}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                JourneySurface(
                  child: ExpansionTile(
                    key: const ValueKey('detection-details'),
                    title: const Text('Technical details & setup'),
                    childrenPadding: const EdgeInsets.all(16),
                    children: [
                      if (status.lastRestriction == null)
                        const Text('No restriction attempt yet.')
                      else
                        Text(switch (status.lastRestriction) {
                          'recovery_shown' => 'Last attempt: recovery screen shown. Open Daylock to refresh plans or disable blocking.',
                          'lock_shown' => 'Last restriction attempt: Daylock lock screen shown.',
                          'state_unknown' => 'Last attempt: Selected apps allowed while Freedom state was unavailable.',
                          'lock_launch_requested' => 'Last attempt: lock screen requested; display not yet confirmed.',
                          'lock_fallback_posted' => 'Last attempt: lock screen not confirmed; app restriction notification posted. Android controls its delivery.',
                          'lock_fallback_unavailable' => 'Last attempt: lock screen not confirmed. Allow notifications and the App restriction notices channel in Android settings for fallback notices.',
                          'home_only' => 'Last attempt: Home requested; lock screen was not confirmed.',
                          'lock_launch_failed' || 'lock_launch_unconfirmed' => 'Last attempt: lock screen was not confirmed. Android may restrict background launches.',
                          'home_failed' => 'Last attempt: Android rejected Home navigation. Restriction could not be applied.',
                          _ =>
                            'Last restriction attempt could not be verified.',
                        }),
                      const SizedBox(height: DaylockSpace.md),
                      Text(
                        status.error != null
                            ? 'Service status unavailable'
                            : !status.supported
                            ? 'Native detection is available on Android only.'
                            : !status.enabled
                            ? 'Accessibility service: disabled'
                            : status.connected
                            ? 'Accessibility service: enabled and connected'
                            : 'Accessibility service: enabled — waiting for Android to connect',
                        key: const ValueKey('detection-service-status'),
                      ),
                      if (status.blockingSaveFailed)
                        const Text(
                          'The blocking choice could not be saved. Disabling takes effect now, but may not survive a restart. Revoke Accessibility access if necessary.',
                        ),
                      const SizedBox(height: DaylockSpace.sm),
                      Text(
                        status.lastDetectedAt == null
                            ? 'No selected app has been detected yet.'
                            : 'Last restricted-app detection: ${MaterialLocalizations.of(context).formatMediumDate(status.lastDetectedAt!)} '
                                  '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(status.lastDetectedAt!), alwaysUse24HourFormat: true)}',
                        key: const ValueKey('instagram-last-detection'),
                      ),
                      if (status.lastDetectedPackage != null)
                        Text(
                          'Last restricted package: ${status.lastDetectedPackage}',
                        ),
                      if (status.freedomAtDetection != null)
                        Text(
                          'Freedom at that detection: ${InstagramDetectionStatus.freedomLabel(status.freedomAtDetection!)}',
                        ),
                      const SizedBox(height: DaylockSpace.sm),
                      Text(
                        'Current native Freedom state: ${InstagramDetectionStatus.freedomLabel(status.freedomState)}',
                        key: const ValueKey('native-freedom-status'),
                      ),
                      if (status.freedomState == 'unknown' && status.supported)
                        Text(
                          status.freedomReason == 'focus_needs_refresh'
                              ? 'An active Focus session needs Daylock to reconcile its timer. Native detection does not mark it complete.'
                              : 'Current dated state is unavailable. Open Daylock to reconcile plans or turn blocking off. Valid current-day inputs do not expire after five minutes.',
                        ),
                      if (status.freedomReason == 'rollover_reconciled')
                        const Text(
                          'New day: using the saved plan for this date. Open Daylock to archive history and prepare the following day.',
                        ),
                      if (status.freedomReason == 'no_eligible_commitments')
                        const Text(
                          'No eligible commitments. Empty or all-excused days do not earn Freedom.',
                        ),
                      if (status.detectionSaveFailed)
                        const Text(
                          'The latest detection could not be persisted and may not survive a restart.',
                        ),
                      if (status.error != null)
                        Text(
                          status.error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      if (status.error != null && status.supported)
                        TextButton(
                          onPressed: () => bridge.setBlockingEnabled(false),
                          child: const Text('Turn blocking off'),
                        ),
                      const SizedBox(height: DaylockSpace.md),
                      const Text(
                        'Android Settings → Accessibility → Downloaded/Installed apps → Daylock app restrictions. Turn the service on manually. Names vary by phone.',
                      ),
                      const SizedBox(height: DaylockSpace.sm),
                      const Text(
                        'If Android 15 shows “Restricted settings”, inspect Daylock’s App info for “Allow restricted settings” and confirm only for this development build you trust.',
                      ),
                      const SizedBox(height: DaylockSpace.sm),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (mode != DetectionSectionMode.restricted)
                Wrap(
                  spacing: DaylockSpace.sm,
                  runSpacing: DaylockSpace.sm,
                  children: [
                    OutlinedButton(
                      key: const ValueKey('open-accessibility-settings'),
                      onPressed: status.supported
                          ? () => _explainAndOpen(context)
                          : null,
                      child: const Text('Open Accessibility Settings'),
                    ),
                    TextButton(
                      key: const ValueKey('refresh-detection'),
                      onPressed: status.supported ? bridge.refresh : null,
                      child: const Text('Refresh status'),
                    ),
                  ],
                ),
            ],
          ),
        );
}

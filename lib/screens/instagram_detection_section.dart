import '../l10n/l10n.dart';

import 'package:flutter/material.dart';

import '../design/daylock_theme.dart';
import '../design/daylock_widgets.dart';
import '../design/journey_surface.dart';
import '../services/instagram_detection_bridge.dart';
import 'restricted_apps_section.dart';

enum DetectionSectionMode { full, restricted, diagnostics }

String _restrictionDiagnostic(AppLocalizations l, String? value) =>
    switch (value) {
      null => l.diagRestrictionNone,
      'skipped_event_delayed' => l.diagRestrictionSkippedEventDelayed,
      'test_requested' => l.diagRestrictionTestRequested,
      'detected_selected_app' => l.diagRestrictionDetectedSelectedApp,
      'eligibility_notEarned' => l.diagRestrictionEligibilityNotEarned,
      'eligibility_earned' => l.diagRestrictionEligibilityEarned,
      'eligibility_disabled' => l.diagRestrictionEligibilityDisabled,
      'eligibility_unknown' => l.diagRestrictionEligibilityUnknown,
      'restriction_triggered' => l.diagRestrictionRestrictionTriggered,
      'restriction_recovery' => l.diagRestrictionRestrictionRecovery,
      'recovery_shown' => l.diagRestrictionRecoveryShown,
      'lock_shown' => l.diagRestrictionLockShown,
      'state_unknown' => l.diagRestrictionStateUnknown,
      'lock_launch_requested' => l.diagRestrictionLockLaunchRequested,
      'lock_fallback_posted' => l.diagRestrictionLockFallbackPosted,
      'lock_fallback_unavailable' => l.diagRestrictionLockFallbackUnavailable,
      'home_only' => l.diagRestrictionHomeOnly,
      'lock_launch_failed' ||
      'lock_launch_unconfirmed' => l.diagRestrictionLockLaunchUnconfirmed,
      'home_failed' => l.diagRestrictionHomeFailed,
      'skipped_foreground_changed_before_eligibility' ||
      'skipped_foreground_changed_before_navigation' =>
        l.diagRestrictionSkippedForegroundChangedBeforeNavigation,
      'skipped_accessibility_disabled' =>
        l.diagRestrictionSkippedAccessibilityDisabled,
      'skipped_selection_unavailable' =>
        l.diagRestrictionSkippedSelectionUnavailable,
      'skipped_device_not_interactive' =>
        l.diagRestrictionSkippedDeviceNotInteractive,
      'skipped_service_inactive' => l.diagRestrictionSkippedServiceInactive,
      'skipped_lock_already_visible' =>
        l.diagRestrictionSkippedLockAlreadyVisible,
      'retrying_state_changed' => l.diagRestrictionRetryingStateChanged,
      'skipped_state_changed' => l.diagRestrictionSkippedStateChanged,
      'skipped_freedom_earned' => l.diagRestrictionSkippedFreedomEarned,
      'skipped_freedom_disabled' => l.diagRestrictionSkippedFreedomDisabled,
      'skipped_launch_throttled' => l.diagRestrictionSkippedLaunchThrottled,
      _ => l.diagRestrictionOther,
    };

String _homeDiagnostic(AppLocalizations l, String? value) => switch (value) {
  'attempted' => l.diagHomeAttempted,
  'accepted' => l.diagHomeAccepted,
  'rejected' => l.diagHomeRejected,
  _ => '',
};

String _lockDiagnostic(AppLocalizations l, String? value) => switch (value) {
  'attempted' => l.diagLockAttempted,
  'requested_unconfirmed' => l.diagLockRequestedUnconfirmed,
  'shown' => l.diagLockShown,
  'failed_exception' => l.diagLockFailedException,
  'unconfirmed' => l.diagLockUnconfirmed,
  _ => '',
};

class InstagramDetectionSection extends StatelessWidget {
  final InstagramDetectionBridge bridge;
  final DetectionSectionMode mode;
  const InstagramDetectionSection({
    super.key,
    required this.bridge,
    this.mode = DetectionSectionMode.full,
  });

  static Future<void> explainAndOpen(
    BuildContext context,
    InstagramDetectionBridge bridge,
  ) async {
    final agree = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(context.l10n.diagPermissionTitle),
        content: Text(context.l10n.diagPermissionBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey('agree-detection'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.diagAgreeOpenSettings),
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
        title: Text(context.l10n.diagEnableBlockingTitle),
        content: Text(context.l10n.diagEnableBlockingBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey('confirm-instagram-blocking'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.diagEnableBlocking),
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
                DaylockLabel(context.l10n.diagAppRestrictionsLabel),
                const SizedBox(height: DaylockSpace.sm),
                Text(context.l10n.diagAppRestrictionsIntro),
                SwitchListTile(
                  key: const ValueKey('instagram-blocking-enabled'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.diagAppRestrictions),
                  subtitle: Text(context.l10n.diagSeparateFromFreedom),
                  value: status.blockingEnabled,
                  onChanged: status.supported && status.error == null
                      ? (value) => _changeBlocking(context, value)
                      : null,
                ),
                Text(
                  status.error != null
                      ? context.l10n.diagStatusUnavailable
                      : !status.blockingEnabled
                      ? context.l10n.diagRestrictionsOff
                      : !status.enabled || !status.connected
                      ? context.l10n.diagWaitingForAccessibility
                      : status.freedomState == 'disabled'
                      ? context.l10n.diagAllowedFreedomOff
                      : status.freedomState == 'earned'
                      ? context.l10n.diagAllowedFreedomEarned
                      : status.freedomState == 'unknown'
                      ? context.l10n.diagBlockingPaused
                      : context.l10n.diagRestrictionsReady,
                  key: const ValueKey('instagram-blocking-status'),
                ),
                if (status.lastRestriction != null)
                  Text(
                    _restrictionDiagnostic(
                      context.l10n,
                      status.lastRestriction,
                    ),
                  ),
                const SizedBox(height: DaylockSpace.md),
                Text(
                  status.error != null
                      ? context.l10n.diagServiceStatusUnavailable
                      : !status.supported
                      ? context.l10n.diagAndroidOnly
                      : !status.enabled
                      ? context.l10n.diagServiceDisabled
                      : status.connected
                      ? context.l10n.diagServiceConnected
                      : context.l10n.diagServiceWaiting,
                  key: const ValueKey('detection-service-status'),
                ),
                if (status.blockingSaveFailed)
                  Text(context.l10n.diagBlockingSaveFailed),
                const SizedBox(height: DaylockSpace.sm),
                Text(
                  status.lastDetectedAt == null
                      ? context.l10n.diagNoDetectionYet
                      : context.l10n.diagLastDetection(
                          '${MaterialLocalizations.of(context).formatMediumDate(status.lastDetectedAt!)} '
                          '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(status.lastDetectedAt!), alwaysUse24HourFormat: true)}',
                        ),
                  key: const ValueKey('instagram-last-detection'),
                ),
                if (status.freedomAtDetection != null)
                  Text(
                    context.l10n.diagFreedomAtDetection(
                      context.l10n.freedomState(status.freedomAtDetection!),
                    ),
                  ),
                const SizedBox(height: DaylockSpace.sm),
                Text(
                  context.l10n.diagCurrentFreedom(
                    context.l10n.freedomState(status.freedomState),
                  ),
                  key: const ValueKey('native-freedom-status'),
                ),
                if (status.freedomState == 'unknown' && status.supported)
                  Text(
                    status.freedomReason == 'focus_needs_refresh'
                        ? context.l10n.diagFocusNeedsRefresh
                        : context.l10n.diagStateUnavailable,
                  ),
                if (status.freedomReason == 'rollover_reconciled')
                  Text(context.l10n.diagRolloverReconciled),
                if (status.freedomReason == 'no_eligible_commitments')
                  Text(context.l10n.diagNoEligible),
                if (status.detectionSaveFailed)
                  Text(context.l10n.diagDetectionSaveFailed),
                if (status.error != null)
                  Text(
                    context.l10n.known(status.error!),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (status.error != null && status.supported)
                  TextButton(
                    onPressed: () => bridge.setBlockingEnabled(false),
                    child: Text(context.l10n.diagTurnBlockingOff),
                  ),
                const SizedBox(height: DaylockSpace.md),
                Text(context.l10n.diagSettingsPath),
                const SizedBox(height: DaylockSpace.sm),
                Text(context.l10n.diagRestrictedSettings),
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
                              ? context.l10n.diagServiceStatusUnavailable
                              : !status.supported
                              ? context.l10n.diagAvailableAndroidOnly
                              : status.enabled
                              ? context.l10n.diagServiceEnabledShort
                              : context.l10n.diagServiceDisabled,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          status.connected
                              ? context.l10n.serviceConnected
                              : context.l10n.diagServiceDisconnected,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          status.blockingEnabled
                              ? context.l10n.diagRestrictionsOn
                              : context.l10n.diagRestrictionsOff,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          context.l10n.selectedAppsCount(
                            status.selectedPackages.length,
                          ),
                        ),
                        if (status.selectionError != null)
                          Text(context.l10n.known(status.selectionError!)),
                        const SizedBox(height: 10),
                        Text(
                          context.l10n.diagNativeFreedom(
                            context.l10n.freedomState(status.freedomState),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                JourneySurface(
                  child: ExpansionTile(
                    key: const ValueKey('detection-details'),
                    title: Text(context.l10n.diagTechnicalDetails),
                    childrenPadding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        _restrictionDiagnostic(
                          context.l10n,
                          status.lastRestriction,
                        ),
                      ),
                      if (status.lastHomeAction != null &&
                          _homeDiagnostic(
                            context.l10n,
                            status.lastHomeAction,
                          ).isNotEmpty)
                        Text(
                          _homeDiagnostic(context.l10n, status.lastHomeAction),
                        ),
                      if (status.lastLockLaunch != null &&
                          _lockDiagnostic(
                            context.l10n,
                            status.lastLockLaunch,
                          ).isNotEmpty)
                        Text(
                          _lockDiagnostic(context.l10n, status.lastLockLaunch),
                        ),
                      const SizedBox(height: DaylockSpace.md),
                      Text(
                        status.error != null
                            ? context.l10n.diagServiceStatusUnavailable
                            : !status.supported
                            ? context.l10n.diagAndroidOnly
                            : !status.enabled
                            ? context.l10n.diagServiceDisabled
                            : status.connected
                            ? context.l10n.diagServiceConnected
                            : context.l10n.diagServiceWaiting,
                        key: const ValueKey('detection-service-status'),
                      ),
                      if (status.blockingSaveFailed)
                        Text(context.l10n.diagBlockingSaveFailed),
                      const SizedBox(height: DaylockSpace.sm),
                      Text(
                        status.lastDetectedAt == null
                            ? context.l10n.diagNoDetectionYet
                            : context.l10n.diagLastDetection(
                                '${MaterialLocalizations.of(context).formatMediumDate(status.lastDetectedAt!)} '
                                '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(status.lastDetectedAt!), alwaysUse24HourFormat: true)}',
                              ),
                        key: const ValueKey('instagram-last-detection'),
                      ),
                      if (status.lastDetectedPackage != null)
                        Text(
                          context.l10n.diagLastPackage(
                            status.lastDetectedPackage!,
                          ),
                        ),
                      if (status.freedomAtDetection != null)
                        Text(
                          context.l10n.diagFreedomAtDetection(
                            context.l10n.freedomState(
                              status.freedomAtDetection!,
                            ),
                          ),
                        ),
                      const SizedBox(height: DaylockSpace.sm),
                      Text(
                        context.l10n.diagCurrentFreedom(
                          context.l10n.freedomState(status.freedomState),
                        ),
                        key: const ValueKey('native-freedom-status'),
                      ),
                      if (status.freedomState == 'unknown' && status.supported)
                        Text(
                          status.freedomReason == 'focus_needs_refresh'
                              ? context.l10n.diagFocusNeedsRefresh
                              : context.l10n.diagStateUnavailable,
                        ),
                      if (status.freedomReason == 'rollover_reconciled')
                        Text(context.l10n.diagRolloverReconciled),
                      if (status.freedomReason == 'no_eligible_commitments')
                        Text(context.l10n.diagNoEligible),
                      if (status.detectionSaveFailed)
                        Text(context.l10n.diagDetectionSaveFailed),
                      if (status.error != null)
                        Text(
                          context.l10n.known(status.error!),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      if (status.error != null && status.supported)
                        TextButton(
                          onPressed: () => bridge.setBlockingEnabled(false),
                          child: Text(context.l10n.diagTurnBlockingOff),
                        ),
                      const SizedBox(height: DaylockSpace.md),
                      Text(context.l10n.diagSettingsPath),
                      const SizedBox(height: DaylockSpace.sm),
                      Text(context.l10n.diagRestrictedSettings),
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
                          ? () => explainAndOpen(context, bridge)
                          : null,
                      child: Text(context.l10n.openAccessibilitySettings),
                    ),
                    TextButton(
                      key: const ValueKey('refresh-detection'),
                      onPressed: status.supported ? bridge.refresh : null,
                      child: Text(context.l10n.refreshStatus),
                    ),
                  ],
                ),
            ],
          ),
        );
}

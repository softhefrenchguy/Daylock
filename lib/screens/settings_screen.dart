import '../l10n/l10n.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../services/freedom_service.dart';
import '../design/daylock_freedom_status.dart';
import '../design/daylock_surfaces.dart';
import '../design/journey_surface.dart';
import 'appearance_settings_content.dart';
export 'appearance_settings_content.dart' show AppearancePreview;

import '../design/appearance_preferences.dart';
import '../design/daylock_widgets.dart';
import '../models/freedom_settings.dart';
import '../services/instagram_detection_bridge.dart';
import 'instagram_detection_section.dart';
import '../models/notification_preferences.dart';
import '../services/notifications/notification_service.dart';
import 'notification_settings_section.dart';

class SettingsScreen extends StatefulWidget {
  final FreedomEligibility Function()? readFreedom;
  final AppearancePreferences preferences;
  final ValueChanged<AppearancePreferences> onChanged;
  final FreedomSettings freedomSettings;
  final ValueChanged<FreedomSettings>? onFreedomChanged;
  final VoidCallback? onRoutinesRequested;
  final int routineCount;
  final VoidCallback? onAreasRequested;
  final int areaCount;
  final InstagramDetectionBridge? detectionBridge;
  final NotificationPreferences notificationPreferences;
  final ValueChanged<NotificationPreferences>? onNotificationsChanged;
  final NotificationService? notificationService;
  final VoidCallback? onSetupRequested;
  final VoidCallback? onTourRequested;
  final SettingsDestination? initialDestination;
  const SettingsScreen({
    super.key,
    this.readFreedom,
    required this.preferences,
    required this.onChanged,
    this.freedomSettings = const FreedomSettings(),
    this.onFreedomChanged,
    this.onRoutinesRequested,
    this.routineCount = 0,
    this.onAreasRequested,
    this.areaCount = 1,
    this.detectionBridge,
    this.notificationPreferences = const NotificationPreferences(),
    this.onNotificationsChanged,
    this.notificationService,
    this.onSetupRequested,
    this.onTourRequested,
    this.initialDestination,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

enum SettingsDestination {
  freedom,
  planning,
  appearance,
  notifications,
  about,
  restricted,
  diagnostics,
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _revision = ValueNotifier(0);
  Timer? _clock;
  @override
  void initState() {
    super.initState();
    final destination = widget.initialDestination;
    if (destination != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _open(destination);
      });
    }
    // Presentation only: re-read existing eligibility while Settings is open.
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && widget.readFreedom != null) _revision.value++;
    });
  }

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _revision.value++;
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _revision.dispose();
    super.dispose();
  }

  void _open(SettingsDestination destination) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: RouteSettings(name: '/settings/${destination.name}'),
      builder: (context) => ValueListenableBuilder<int>(
        valueListenable: _revision,
        builder: (context, _, _) => _page(destination),
      ),
    ),
  );

  Future<void> _chooseFreedomTime(BuildContext context) async {
    final current = widget.freedomSettings;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (mounted && time != null) {
      widget.onFreedomChanged?.call(
        widget.freedomSettings.copyWith(hour: time.hour, minute: time.minute),
      );
    }
  }

  Widget _page(SettingsDestination destination) {
    final s = widget;
    final bridge = s.detectionBridge;
    return SettingsPage(
      title: switch (destination) {
        SettingsDestination.freedom => context.l10n.settingsFreedomControl,
        SettingsDestination.planning => context.l10n.settingsPlanningRoutines,
        SettingsDestination.appearance => context.l10n.settingsAppearance,
        SettingsDestination.notifications => context.l10n.settingsNotifications,
        SettingsDestination.about => context.l10n.settingsAbout,
        SettingsDestination.restricted => context.l10n.settingsRestrictedApps,
        SettingsDestination.diagnostics =>
          context.l10n.settingsPermissionsDiagnostics,
      },
      children: switch (destination) {
        SettingsDestination.appearance => [
          AppearanceSettingsContent(
            preferences: s.preferences,
            onChanged: s.onChanged,
            areaCount: s.areaCount,
            onAreasRequested: s.onAreasRequested,
          ),
        ],
        SettingsDestination.planning => [
          SettingsNavigationCard(
            id: 'manage-routines',
            icon: Icons.checklist_rounded,
            title: context.l10n.settingsManageRoutines,
            subtitle: context.l10n.routineCount(s.routineCount),
            onTap: s.onRoutinesRequested,
          ),
          Text(
            context.l10n.settingsRoutinesIntro,
            style: TextStyle(height: 1.5),
          ),
        ],
        SettingsDestination.notifications => [
          if (s.notificationService != null && s.onNotificationsChanged != null)
            NotificationSettingsSection(
              preferences: s.notificationPreferences,
              onChanged: s.onNotificationsChanged!,
              service: s.notificationService!,
            )
          else
            Text(context.l10n.settingsNotificationsUnavailable),
        ],
        SettingsDestination.about => [
          JourneySurface(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DaylockLabel('DAYLOCK'),
                  const SizedBox(height: 10),
                  Text(
                    context.l10n.keepYourWord,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(context.l10n.settingsAboutCommitments),
                  const SizedBox(height: 12),
                  Text(context.l10n.settingsRestrictedIntro),
                ],
              ),
            ),
          ),
        ],
        SettingsDestination.restricted => [
          if (bridge != null)
            InstagramDetectionSection(
              bridge: bridge,
              mode: DetectionSectionMode.restricted,
            )
          else
            Text(context.l10n.settingsRestrictionsAndroidOnly),
        ],
        SettingsDestination.diagnostics => [
          if (bridge != null)
            InstagramDetectionSection(
              bridge: bridge,
              mode: DetectionSectionMode.diagnostics,
            )
          else
            Text(context.l10n.settingsDiagnosticsAndroidOnly),
        ],
        SettingsDestination.freedom => [
          _FreedomSettingsHero(
            eligibility: s.readFreedom?.call(),
            settings: s.freedomSettings,
          ),
          DaylockGroup(
            children: [
              SwitchListTile(
                key: const ValueKey('freedom-enabled'),
                title: Text(context.l10n.settingsFreedomControl),
                value: s.freedomSettings.enabled,
                onChanged: s.onFreedomChanged == null
                    ? null
                    : (value) => s.onFreedomChanged!(
                        s.freedomSettings.copyWith(enabled: value),
                      ),
              ),
              ListTile(
                key: const ValueKey('freedom-time'),
                title: Text(context.l10n.freedomTime),
                subtitle: Text(s.freedomSettings.timeLabel),
                trailing: const Icon(Icons.schedule_outlined),
                onTap: s.onFreedomChanged == null
                    ? null
                    : () => _chooseFreedomTime(context),
              ),
            ],
          ),
          if (bridge != null)
            ValueListenableBuilder<InstagramDetectionStatus>(
              valueListenable: bridge.status,
              builder: (context, status, _) => DaylockGroup(
                children: [
                  SettingsNavigationCard(
                    grouped: true,
                    tint: DaylockHues.pink,
                    id: 'settings-restricted',
                    icon: Icons.lock_outline_rounded,
                    title: context.l10n.settingsRestrictedApps,
                    subtitle:
                        status.error != null || status.selectionError != null
                        ? context.l10n.settingsRestrictionNeedsAttention
                        : status.blockingEnabled
                        ? context.l10n.settingsSelectedSwitchOn(
                            status.selectedPackages.length,
                          )
                        : context.l10n.settingsSelectedSwitchOff(
                            status.selectedPackages.length,
                          ),
                    onTap: () => _open(SettingsDestination.restricted),
                  ),
                  SettingsNavigationCard(
                    grouped: true,
                    tint: DaylockHues.blue,
                    id: 'settings-diagnostics',
                    icon: Icons.accessibility_new_rounded,
                    title: context.l10n.accessibility,
                    subtitle: status.error != null
                        ? context.l10n.statusUnavailable
                        : !status.supported
                        ? context.l10n.availableOnAndroid
                        : status.connected
                        ? context.l10n.serviceConnected
                        : status.enabled
                        ? context.l10n.waitingForConnection
                        : context.l10n.serviceDisabled,
                    onTap: () => _open(SettingsDestination.diagnostics),
                  ),
                ],
              ),
            )
          else
            SettingsNavigationCard(
              id: 'settings-restricted',
              icon: Icons.lock_outline_rounded,
              title: context.l10n.settingsRestrictedApps,
              subtitle: context.l10n.settingsChooseInstalledApps,
              onTap: () => _open(SettingsDestination.restricted),
            ),
        ],
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final freedom = widget.freedomSettings;
    final row = <SettingsDestination, (IconData, Color, String, String, String?)>{
      SettingsDestination.freedom: (
        Icons.lock_outline_rounded,
        DaylockHues.violet,
        context.l10n.settingsFreedomControl,
        context.l10n.settingsFreedomSubtitle,
        '${freedom.enabled ? context.l10n.on : context.l10n.off} \u00b7 ${freedom.timeLabel}',
      ),
      SettingsDestination.planning: (
        Icons.checklist_rounded,
        DaylockHues.teal,
        context.l10n.settingsPlanningRoutines,
        context.l10n.settingsPlanningSubtitle,
        widget.routineCount == 1
            ? context.l10n.routineCount(1)
            : context.l10n.routineCount(widget.routineCount),
      ),
      SettingsDestination.appearance: (
        Icons.palette_outlined,
        DaylockHues.pink,
        context.l10n.settingsAppearance,
        context.l10n.settingsAppearanceSubtitle,
        '${context.l10n.appearanceMode(widget.preferences.mode)} \u00b7 ${context.l10n.colourTheme(widget.preferences.colour)}',
      ),
      SettingsDestination.notifications: (
        Icons.notifications_outlined,
        DaylockHues.amber,
        context.l10n.settingsNotifications,
        context.l10n.settingsNotificationsSubtitle,
        null,
      ),
    };
    return SettingsPage(
      title: context.l10n.settingsTitle,
      children: [
        DaylockGroup(
          children: [
            for (final entry in row.entries)
              SettingsNavigationCard(
                grouped: true,
                id: 'settings-${entry.key.name}',
                icon: entry.value.$1,
                tint: entry.value.$2,
                title: entry.value.$3,
                subtitle: entry.value.$4,
                value: entry.value.$5,
                onTap: () => _open(entry.key),
              ),
          ],
        ),
        const SizedBox(height: 8),
        DaylockGroup(
          children: [
            SettingsNavigationCard(
              grouped: true,
              id: 'settings-setup',
              icon: Icons.explore_outlined,
              tint: DaylockHues.blue,
              title: context.l10n.settingsRunSetup,
              subtitle: context.l10n.settingsRunSetupSubtitle,
              onTap: widget.onSetupRequested,
            ),
            if (widget.onTourRequested != null)
              SettingsNavigationCard(
                grouped: true,
                id: 'settings-tour',
                icon: Icons.tour_outlined,
                tint: DaylockHues.amber,
                title: context.l10n.settingsTakeTour,
                subtitle: context.l10n.settingsTakeTourSubtitle,
                onTap: widget.onTourRequested,
              ),
            SettingsNavigationCard(
              grouped: true,
              id: 'settings-about',
              icon: Icons.info_outline_rounded,
              tint: DaylockHues.grey,
              title: context.l10n.settingsAbout,
              subtitle: context.l10n.settingsAboutSubtitle,
              onTap: () => _open(SettingsDestination.about),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 28),
          child: Text(
            context.l10n.tagline,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
      ],
    );
  }
}

class SettingsPage extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const SettingsPage({super.key, required this.title, required this.children});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 20, 16),
            child: Row(
              children: [
                const BackButton(),
                const SizedBox(width: 4),
                if (MediaQuery.textScalerOf(context).scale(32) <= 72)
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      20,
                      0,
                      20,
                      24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (MediaQuery.textScalerOf(context).scale(32) >
                            72) ...[
                          Text(
                            title,
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 16),
                        ],
                        for (final child in children) ...[
                          child,
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class SettingsNavigationCard extends StatelessWidget {
  final String id, title, subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? tint;
  final String? value;

  /// Inside a [DaylockGroup]: no surface of its own.
  final bool grouped;
  const SettingsNavigationCard({
    super.key,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
    this.tint,
    this.value,
    this.grouped = false,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final row = InkWell(
      key: grouped ? ValueKey(id) : null,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 10, 12),
        child: Row(
          children: [
            DaylockIconTile(icon: icon, color: tint ?? scheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge!.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // The current value says more than a description, so it
                  // takes the second line when there is one.
                  Semantics(
                    label: value == null ? null : subtitle,
                    child: Text(
                      value ?? subtitle,
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
    if (grouped) return row;
    return JourneySurface(key: ValueKey(id), child: row);
  }
}

class _FreedomSettingsHero extends StatelessWidget {
  final FreedomEligibility? eligibility;
  final FreedomSettings settings;
  const _FreedomSettingsHero({
    required this.eligibility,
    required this.settings,
  });
  @override
  Widget build(BuildContext context) {
    final e = eligibility;
    if (e != null) return DaylockFreedomStatus(eligibility: e);
    return JourneySurface(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          settings.enabled
              ? context.l10n.freedomStatusUnavailable
              : context.l10n.freedomControlOff,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}

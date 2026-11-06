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
        SettingsDestination.freedom => 'Freedom Control',
        SettingsDestination.planning => 'Planning & Routines',
        SettingsDestination.appearance => 'Appearance',
        SettingsDestination.notifications => 'Notifications',
        SettingsDestination.about => 'About',
        SettingsDestination.restricted => 'Restricted Apps',
        SettingsDestination.diagnostics => 'Permissions & Diagnostics',
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
            title: 'Manage routines',
            subtitle: '${s.routineCount} routines',
            onTap: s.onRoutinesRequested,
          ),
          const Text(
            'Plan your next steps with recurring commitments.',
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
            const Text('Notification controls are unavailable on this device.'),
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
                    'Keep your word.',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Commitments, optional stopwatches and progress in the areas that matter.',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Choose which supported Android apps to restrict until Freedom is earned.',
                  ),
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
            const Text('App restrictions are available on Android.'),
        ],
        SettingsDestination.diagnostics => [
          if (bridge != null)
            InstagramDetectionSection(
              bridge: bridge,
              mode: DetectionSectionMode.diagnostics,
            )
          else
            const Text('Accessibility diagnostics are available on Android.'),
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
                title: const Text('Freedom Control'),
                value: s.freedomSettings.enabled,
                onChanged: s.onFreedomChanged == null
                    ? null
                    : (value) => s.onFreedomChanged!(
                        s.freedomSettings.copyWith(enabled: value),
                      ),
              ),
              ListTile(
                key: const ValueKey('freedom-time'),
                title: const Text('Freedom Time'),
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
                    title: 'Restricted Apps',
                    subtitle:
                        status.error != null || status.selectionError != null
                        ? 'App restriction status needs attention'
                        : status.blockingEnabled
                        ? '${status.selectedPackages.length} selected, switch on'
                        : '${status.selectedPackages.length} selected, switch off',
                    onTap: () => _open(SettingsDestination.restricted),
                  ),
                  SettingsNavigationCard(
                    grouped: true,
                    tint: DaylockHues.blue,
                    id: 'settings-diagnostics',
                    icon: Icons.accessibility_new_rounded,
                    title: 'Accessibility',
                    subtitle: status.error != null
                        ? 'Status unavailable'
                        : !status.supported
                        ? 'Available on Android'
                        : status.connected
                        ? 'Service connected'
                        : status.enabled
                        ? 'Waiting for connection'
                        : 'Service disabled',
                    onTap: () => _open(SettingsDestination.diagnostics),
                  ),
                ],
              ),
            )
          else
            SettingsNavigationCard(
              id: 'settings-restricted',
              icon: Icons.lock_outline_rounded,
              title: 'Restricted Apps',
              subtitle: 'Choose installed Android apps',
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
        'Freedom Control',
        'Restricted apps, Freedom Time and permissions',
        '${freedom.enabled ? 'On' : 'Off'} \u00b7 ${freedom.timeLabel}',
      ),
      SettingsDestination.planning: (
        Icons.checklist_rounded,
        DaylockHues.teal,
        'Planning & Routines',
        'Recurring commitments and planning',
        widget.routineCount == 1
            ? '1 routine'
            : '${widget.routineCount} routines',
      ),
      SettingsDestination.appearance: (
        Icons.palette_outlined,
        DaylockHues.pink,
        'Appearance',
        'Theme, colours and Areas',
        '${widget.preferences.mode.label} \u00b7 ${widget.preferences.colour.label}',
      ),
      SettingsDestination.notifications: (
        Icons.notifications_outlined,
        DaylockHues.amber,
        'Notifications',
        'Reminders and alerts',
        null,
      ),
    };
    return SettingsPage(
      title: 'Settings',
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
              title: 'Run Setup Tutorial',
              subtitle: 'Permissions, distractions and your first commitment',
              onTap: widget.onSetupRequested,
            ),
            SettingsNavigationCard(
              grouped: true,
              id: 'settings-about',
              icon: Icons.info_outline_rounded,
              tint: DaylockHues.grey,
              title: 'About',
              subtitle: 'App information',
              onTap: () => _open(SettingsDestination.about),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 28),
          child: Text(
            'Plan your day. Earn your freedom.',
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
            padding: const EdgeInsets.fromLTRB(12, 12, 20, 16),
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
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
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
              ? 'Freedom status unavailable'
              : 'Freedom Control is off',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../services/freedom_service.dart';
import '../design/daylock_illustrations.dart';
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
                    'Instagram is the currently supported restricted app.',
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
            const Text('Instagram controls are available on Android.'),
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
          JourneySurface(
            child: Column(
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
                const Divider(indent: 16, endIndent: 16),
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
          ),
          if (bridge != null)
            ValueListenableBuilder<InstagramDetectionStatus>(
              valueListenable: bridge.status,
              builder: (context, status, _) => Column(
                children: [
                  SettingsNavigationCard(
                    id: 'settings-restricted',
                    icon: Icons.lock_outline_rounded,
                    title: 'Restricted Apps',
                    subtitle: status.error != null
                        ? 'Instagram status unavailable'
                        : status.blockingEnabled
                        ? 'Instagram blocking on'
                        : 'Instagram blocking off',
                    onTap: () => _open(SettingsDestination.restricted),
                  ),
                  const SizedBox(height: 12),
                  SettingsNavigationCard(
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
              subtitle: 'Instagram only',
              onTap: () => _open(SettingsDestination.restricted),
            ),
        ],
      },
    );
  }

  @override
  Widget build(BuildContext context) => SettingsPage(
    title: 'Settings',
    children: [
      for (final item in const [
        (
          SettingsDestination.freedom,
          Icons.lock_outline_rounded,
          'Freedom Control',
          'Restricted apps, Freedom Time and permissions',
        ),
        (
          SettingsDestination.planning,
          Icons.checklist_rounded,
          'Planning & Routines',
          'Recurring commitments and planning',
        ),
        (
          SettingsDestination.appearance,
          Icons.palette_outlined,
          'Appearance',
          'Theme, colours and Areas',
        ),
        (
          SettingsDestination.notifications,
          Icons.notifications_outlined,
          'Notifications',
          'Reminders and alerts',
        ),
        (
          SettingsDestination.about,
          Icons.info_outline_rounded,
          'About',
          'App information',
        ),
      ])
        SettingsNavigationCard(
          id: 'settings-${item.$1.name}',
          icon: item.$2,
          title: item.$3,
          subtitle: item.$4,
          onTap: () => _open(item.$1),
        ),
    ],
  );
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
  const SettingsNavigationCard({
    super.key,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => JourneySurface(
    key: ValueKey(id),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium!
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, size: 20),
        ],
      ),
    ),
  );
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
    final waiting =
        e != null &&
        e.settings.enabled &&
        e.currentPlans &&
        !e.timeReached &&
        e.commitmentsCompleted &&
        e.tomorrowCommitted;
    final title = !settings.enabled
        ? 'Freedom Control is off'
        : e == null
        ? 'Freedom status unavailable'
        : e.earned
        ? 'Freedom earned'
        : waiting
        ? 'Waiting for Freedom Time'
        : 'Freedom not yet earned';
    final colors = Theme.of(context).colorScheme;
    return JourneySurface(
      emphasized: true,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DaylockLabel('FREEDOM', color: colors.primary),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Freedom Time \u00b7 ${settings.timeLabel}',
                        style: Theme.of(context).textTheme.bodyMedium!
                            .copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 76,
                  child: DaylockIllustration(
                    accent: colors.primary,
                    lockIcon: e?.earned == true
                        ? Icons.lock_open_rounded
                        : waiting
                        ? Icons.schedule_rounded
                        : Icons.lock_outline_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

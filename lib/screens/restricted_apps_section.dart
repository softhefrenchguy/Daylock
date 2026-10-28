import 'package:flutter/material.dart';

import '../design/daylock_widgets.dart';
import '../design/journey_surface.dart';
import '../services/instagram_detection_bridge.dart';

class RestrictedAppsSection extends StatefulWidget {
  final InstagramDetectionBridge bridge;
  final Future<void> Function(bool) onMasterChanged;
  const RestrictedAppsSection({
    super.key,
    required this.bridge,
    required this.onMasterChanged,
  });
  @override
  State<RestrictedAppsSection> createState() => _RestrictedAppsSectionState();
}

class _RestrictedAppsSectionState extends State<RestrictedAppsSection>
    with WidgetsBindingObserver {
  List<InstalledRestrictedApp> _apps = [];
  final _pending = <String, (int, bool)>{};
  var _sequence = 0;
  var _loadVersion = 0;
  var _loading = true;
  String? _error;
  String _query = '';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final version = ++_loadVersion;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final apps = await widget.bridge.loadInstalledApps();
      if (mounted && version == _loadVersion) {
        setState(() {
          _apps = apps;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted && version == _loadVersion) {
        setState(() {
          _loading = false;
          _error = 'Could not load installed apps. Your saved selections have not been replaced.';
        });
      }
    }
  }

  Future<void> _select(InstalledRestrictedApp app, bool value) async {
    final operation = ++_sequence;
    setState(() => _pending[app.packageName] = (operation, value));
    try {
      await widget.bridge.setRestrictedApp(app.packageName, value);
    } finally {
      if (mounted && _pending[app.packageName]?.$1 == operation) {
        setState(() => _pending.remove(app.packageName));
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<InstagramDetectionStatus>(
    valueListenable: widget.bridge.status,
    builder: (context, status, _) {
      final selected = {...status.selectedPackages};
      for (final entry in _pending.entries) {
        if (entry.value.$2) {
          selected.add(entry.key);
        } else {
          selected.remove(entry.key);
        }
      }
      final apps = filterRestrictedApps(_apps, _query);
      final supported = status.supported;
      final error = status.selectionError ?? status.error;
      final enforcement = !supported
          ? 'App restrictions are available on Android.'
          : error != null
          ? 'Restrictions paused: status needs attention.'
          : !status.blockingEnabled
          ? 'App restrictions are off. Your selections are saved.'
          : selected.isEmpty
          ? 'No apps selected. Nothing is restricted.'
          : !status.enabled || !status.connected
          ? 'Waiting for Accessibility access. Selected apps are not restricted.'
          : status.freedomState == 'disabled'
          ? 'Freedom Control is off. Selected apps are accessible.'
          : status.freedomState == 'earned'
          ? 'Freedom earned. Selected apps are accessible.'
          : status.freedomState == 'unknown'
          ? 'Freedom status needs a refresh. Recovery is available; repeated openings are allowed.'
          : 'Selected apps are restricted until Freedom is earned.';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: DaylockLabel(
                  '${selected.length} SELECTED',
                  key: const ValueKey('selected-app-count'),
                ),
              ),
              IconButton(
                key: const ValueKey('refresh-apps'),
                tooltip: 'Refresh apps',
                onPressed: _loading || !supported ? null : _load,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          JourneySurface(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SwitchListTile(
                    key: const ValueKey('instagram-blocking-enabled'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('App restrictions'),
                    subtitle: const Text(
                      'Master control for all selected apps.',
                    ),
                    value: status.blockingEnabled,
                    onChanged: supported ? widget.onMasterChanged : null,
                  ),
                  Text(
                    enforcement,
                    key: const ValueKey('app-enforcement-status'),
                  ),
                  if (status.blockingSaveFailed)
                    const Text(
                      'The master setting could not be saved. Turning it off applies now, but may not survive a restart.',
                    ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      error,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Choose apps below. Freedom Control and app restrictions are separate. System recovery apps are excluded.',
          ),
          const SizedBox(height: 12),
          if (status.removedAppCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${status.removedAppCount} unavailable or reinstalled app(s) removed from selection. Select them again if needed.',
              ),
            ),
          if (selected.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'No apps selected yet. Choose the apps you want to restrict.',
              ),
            ),
          TextField(
            key: const ValueKey('restricted-app-search'),
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: 'Search apps',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (!supported)
            const Text('Installed-app selection requires Android.')
          else if (_error != null) ...[
            Text(_error!),
            TextButton(
              onPressed: _load,
              child: const Text('Retry app discovery'),
            ),
          ] else if (apps.isEmpty)
            Text(
              _query.trim().isEmpty
                  ? 'No supported launchable apps were found in this Android profile.'
                  : 'No matching apps.',
            )
          else
            for (final app in apps)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: JourneySurface(
                  child: SwitchListTile(
                    key: ValueKey('restricted-app-${app.packageName}'),
                    secondary: SizedBox(
                      width: 36,
                      height: 36,
                      child: app.icon == null
                          ? const Icon(
                              Icons.apps_rounded,
                              semanticLabel: 'App icon unavailable',
                            )
                          : Image.memory(
                              app.icon!,
                              excludeFromSemantics: true,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.apps_rounded),
                            ),
                    ),
                    title: Text(app.name),
                    subtitle: _pending.containsKey(app.packageName)
                        ? const Text('Saving selection…')
                        : null,
                    value: selected.contains(app.packageName),
                    onChanged: (value) => _select(app, value),
                  ),
                ),
              ),
          const SizedBox(height: 8),
          const Text(
            'Selections stay on this device. New or reinstalled apps must be selected explicitly.',
          ),
        ],
      );
    },
  );
}

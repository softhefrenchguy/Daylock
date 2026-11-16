import '../l10n/l10n.dart';

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
          _error = context.l10n.appsLoadFailed;
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
  Widget build(BuildContext context) =>
      ValueListenableBuilder<InstagramDetectionStatus>(
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
          final rawError = status.selectionError ?? status.error;
          final error = rawError == null ? null : context.l10n.known(rawError);
          final enforcement = !supported
              ? context.l10n.settingsRestrictionsAndroidOnly
              : error != null
              ? context.l10n.appsPausedAttention
              : !status.blockingEnabled
              ? context.l10n.appsRestrictionsOff
              : selected.isEmpty
              ? context.l10n.appsNoneSelected
              : !status.enabled || !status.connected
              ? context.l10n.appsWaitingAccessibility
              : status.freedomState == 'disabled'
              ? context.l10n.appsFreedomOff
              : status.freedomState == 'earned'
              ? context.l10n.appsFreedomEarned
              : status.freedomState == 'unknown'
              ? context.l10n.appsNeedsRefresh
              : context.l10n.appsRestricted;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DaylockLabel(
                      context.l10n.selectedCountLabel(selected.length),
                      key: const ValueKey('selected-app-count'),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('refresh-apps'),
                    tooltip: context.l10n.refreshApps,
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
                        title: Text(context.l10n.diagAppRestrictions),
                        subtitle: Text(context.l10n.appsMasterControl),
                        value: status.blockingEnabled,
                        onChanged: supported ? widget.onMasterChanged : null,
                      ),
                      Text(
                        enforcement,
                        key: const ValueKey('app-enforcement-status'),
                      ),
                      if (status.blockingSaveFailed)
                        Text(context.l10n.appsMasterSaveFailed),
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
              Text(context.l10n.appsChooseBelow),
              const SizedBox(height: 12),
              if (status.removedAppCount > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(context.l10n.appsRemoved(status.removedAppCount)),
                ),
              if (selected.isEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(context.l10n.appsNoneSelectedYet),
                ),
              TextField(
                key: const ValueKey('restricted-app-search'),
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: context.l10n.searchApps,
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (!supported)
                Text(context.l10n.appsSelectionRequiresAndroid)
              else if (_error != null) ...[
                Text(_error!),
                TextButton(
                  onPressed: _load,
                  child: Text(context.l10n.retryAppDiscovery),
                ),
              ] else if (apps.isEmpty)
                Text(
                  _query.trim().isEmpty
                      ? context.l10n.appsNoneFound
                      : context.l10n.appsNoMatches,
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
                              ? Icon(
                                  Icons.apps_rounded,
                                  semanticLabel:
                                      context.l10n.appIconUnavailable,
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
                            ? Text(context.l10n.savingSelection)
                            : null,
                        value: selected.contains(app.packageName),
                        onChanged: (value) => _select(app, value),
                      ),
                    ),
                  ),
              const SizedBox(height: 8),
              Text(context.l10n.appsSelectionsStay),
            ],
          );
        },
      );
}

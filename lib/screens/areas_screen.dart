import '../l10n/l10n.dart';

import 'package:flutter/material.dart';

import '../design/daylock_areas.dart';
import '../design/daylock_theme.dart';
import '../models/area.dart';

class AreasScreen extends StatelessWidget {
  final AreaBook book;
  final ValueChanged<Area> onSaved;
  final void Function(String, bool) onArchived;
  const AreasScreen({
    super.key,
    required this.book,
    required this.onSaved,
    required this.onArchived,
  });

  Future<void> _edit(BuildContext context, [Area? area]) async {
    final saved = await showModalBottomSheet<Area>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) => AreaEditor(area: area),
    );
    if (context.mounted && saved != null) onSaved(saved);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.areas)),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(DaylockSpace.lg),
            children: [
              Text(context.l10n.areasIntro),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                key: const ValueKey('create-area'),
                onPressed: () => _edit(context),
                icon: const Icon(Icons.add),
                label: Text(context.l10n.createArea),
              ),
              const SizedBox(height: 16),
              for (final archived in [false, true]) ...[
                if (archived && book.areas.any((a) => a.isArchived))
                  Text(
                    context.l10n.archived,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                for (final area in book.areas.where(
                  (a) => a.isArchived == archived,
                )) ...[
                  ListTile(
                    key: ValueKey('area-${area.id}'),
                    contentPadding: EdgeInsets.zero,
                    title: AreaBadge(area: area),
                    subtitle: area.isDefault
                        ? Text(context.l10n.defaultAlwaysAvailable)
                        : null,
                    onTap: () => _edit(context, area),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => _edit(context, area),
                        child: Text(context.l10n.edit),
                      ),
                      if (!area.isDefault)
                        TextButton(
                          key: ValueKey('archive-area-${area.id}'),
                          onPressed: () =>
                              onArchived(area.id, !area.isArchived),
                          child: Text(
                            area.isArchived
                                ? context.l10n.restore
                                : context.l10n.archive,
                          ),
                        ),
                    ],
                  ),
                  const Divider(),
                ],
              ],
              Text(context.l10n.archivingExplainer),
            ],
          ),
        ),
      ),
    ),
  );
}

class AreaEditor extends StatefulWidget {
  final Area? area;
  const AreaEditor({super.key, this.area});
  @override
  State<AreaEditor> createState() => _AreaEditorState();
}

class _AreaEditorState extends State<AreaEditor> {
  late final TextEditingController _name;
  late String _icon;
  late int _colour;
  bool _submitted = false;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.area?.name);
    _icon = widget.area?.icon ?? 'life';
    _colour = widget.area?.colour ?? Area.defaultColour;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (_submitted ||
        _name.text.trim().isEmpty ||
        _name.text.trim().runes.length > Area.maxNameLength) {
      return;
    }
    _submitted = true;
    Navigator.pop(
      context,
      widget.area?.copyWith(name: _name.text, icon: _icon, colour: _colour) ??
          Area.create(
            name: _name.text,
            icon: _icon,
            colour: _colour,
            now: DateTime.now(),
          ),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DaylockSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.area == null
                        ? context.l10n.createArea
                        : context.l10n.editArea,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.closeEditor,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            TextField(
              key: const ValueKey('area-name'),
              controller: _name,
              maxLength: Area.maxNameLength,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: context.l10n.areaName),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            Text(context.l10n.icon),
            Wrap(
              spacing: 8,
              children: [
                for (final entry in areaIcons.entries)
                  ChoiceChip(
                    key: ValueKey('area-icon-${entry.key}'),
                    avatar: Icon(entry.value, size: 20),
                    label: Text(context.l10n.areaIcon(entry.key)),
                    selected: _icon == entry.key,
                    onSelected: (_) => setState(() => _icon = entry.key),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(context.l10n.colour),
            Wrap(
              spacing: 8,
              children: [
                for (final entry in areaColours.entries)
                  ChoiceChip(
                    key: ValueKey('area-colour-${entry.key}'),
                    avatar: Icon(
                      Icons.circle,
                      color: Color(entry.value),
                      size: 20,
                    ),
                    label: Text(context.l10n.areaColour(entry.key)),
                    selected: _colour == entry.value,
                    onSelected: (_) => setState(() => _colour = entry.value),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('save-area'),
              onPressed:
                  _name.text.trim().isEmpty ||
                      _name.text.trim().runes.length > Area.maxNameLength
                  ? null
                  : _save,
              child: Text(context.l10n.saveArea),
            ),
          ],
        ),
      ),
    ),
  );
}

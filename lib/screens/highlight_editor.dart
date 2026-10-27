import 'package:flutter/material.dart';

import '../design/daylock_areas.dart';
import '../design/daylock_theme.dart';
import '../design/highlight_illustration.dart';
import '../models/area.dart';
import '../models/highlight.dart';
import '../models/highlight_illustration.dart';

class HighlightEditor extends StatefulWidget {
  final Highlight? highlight;
  final AreaBook areas;
  final DateTime now;
  final String? initialAreaId;
  const HighlightEditor({
    super.key,
    this.highlight,
    required this.areas,
    required this.now,
    this.initialAreaId,
  });
  @override
  State<HighlightEditor> createState() => _HighlightEditorState();
}

class _HighlightEditorState extends State<HighlightEditor> {
  late final TextEditingController _title, _description;
  late DateTime _date;
  String? _areaId;
  String? _illustrationIcon;
  bool _choosingIllustration = false;
  bool _submitted = false;
  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.highlight?.title);
    _description = TextEditingController(text: widget.highlight?.description);
    _date = widget.highlight?.date ?? DateUtils.dateOnly(widget.now);
    _areaId = widget.highlight == null
        ? widget.initialAreaId
        : widget.highlight!.areaId;
    _illustrationIcon = widget.highlight?.illustrationIcon;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  bool get _valid =>
      _title.text.trim().isNotEmpty &&
      _title.text.trim().runes.length <= Highlight.maxTitleLength &&
      _description.text.trim().runes.length <= Highlight.maxDescriptionLength;
  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1),
      lastDate: DateTime(9999, 12, 31),
    );
    if (mounted && value != null) setState(() => _date = value);
  }

  void _save() {
    if (!_valid || _submitted) return;
    _submitted = true;
    final old = widget.highlight;
    Navigator.pop(
      context,
      old == null
          ? Highlight.create(
              title: _title.text,
              date: _date,
              description: _description.text,
              areaId: _areaId,
              illustrationIcon: _illustrationIcon,
            )
          : Highlight(
              id: old.id,
              title: _title.text,
              date: _date,
              description: _description.text,
              areaId: _areaId,
              illustrationIcon: _illustrationIcon,
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
                    widget.highlight == null
                        ? 'Add Highlight'
                        : 'Edit Highlight',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Close editor',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('highlight-title'),
              controller: _title,
              maxLength: Highlight.maxTitleLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Something worth remembering',
              ),
              onChanged: (_) => setState(() {}),
            ),
            ListTile(
              key: const ValueKey('highlight-date'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(
                MaterialLocalizations.of(context).formatMediumDate(_date),
              ),
              trailing: const Icon(Icons.edit_outlined),
              onTap: _pickDate,
            ),
            TextField(
              key: const ValueKey('highlight-description'),
              controller: _description,
              minLines: 2,
              maxLines: 5,
              maxLength: Highlight.maxDescriptionLength,
              decoration: const InputDecoration(
                labelText: 'A few words (optional)',
              ),
              onChanged: (_) => setState(() {}),
            ),
            SwitchListTile(
              key: const ValueKey('highlight-link-area'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Link to an Area'),
              subtitle: const Text('Optional'),
              value: _areaId != null,
              onChanged: (value) => setState(
                () => _areaId = value ? widget.areas.defaultArea.id : null,
              ),
            ),
            if (_areaId != null) ...[
              if (!widget.areas.areas.any((a) => a.id == _areaId))
                const Text(
                  'The previous Area is unavailable. Choose an Area or remove the link.',
                ),
              AreaSelector(
                book: widget.areas,
                selectedId: _areaId,
                onChanged: (id) => setState(() => _areaId = id),
              ),
            ],
            const SizedBox(height: 16),
            _illustrationPicker(context),
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('save-highlight'),
              onPressed: _valid ? _save : null,
              child: const Text('Save Highlight'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _illustrationPicker(BuildContext context) {
    final area = widget.areas.areas.where((a) => a.id == _areaId).firstOrNull;
    final resolved = resolveHighlightIllustration(
      title: _title.text,
      explicitIcon: _illustrationIcon,
      areaIcon: area?.icon,
    );
    final automatic = !highlightIllustrationLabels.containsKey(
      _illustrationIcon,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          key: const ValueKey('select-highlight-illustration'),
          onPressed: () =>
              setState(() => _choosingIllustration = !_choosingIllustration),
          icon: Icon(highlightIllustrationIcons[resolved]),
          label: Text(
            'Illustration: ${automatic ? 'Automatic · ' : ''}${highlightIllustrationLabels[resolved]}',
          ),
        ),
        if (_choosingIllustration) ...[
          const SizedBox(height: 8),
          Text(
            'Choose a look, or let the title and Area suggest one.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ChoiceChip(
                key: const ValueKey('highlight-icon-automatic'),
                label: const Text('Automatic'),
                selected: automatic,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                onSelected: (_) => setState(() => _illustrationIcon = null),
              ),
              for (final entry in highlightIllustrationLabels.entries)
                ChoiceChip(
                  key: ValueKey('highlight-icon-${entry.key}'),
                  avatar: Icon(highlightIllustrationIcons[entry.key], size: 18),
                  label: Text(entry.value),
                  selected: _illustrationIcon == entry.key,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  onSelected: (_) =>
                      setState(() => _illustrationIcon = entry.key),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

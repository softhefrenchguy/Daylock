import 'package:flutter/material.dart';

import '../models/area.dart';
import '../models/highlight.dart';
import '../models/highlight_illustration.dart';
import 'highlight_illustration.dart';
import 'journey_surface.dart';

/// Stable selection follows the Highlight ID across saves, reordering and ticks.
class JourneyFeaturedHighlight extends StatefulWidget {
  final List<Highlight> highlights;
  final AreaBook areas;
  final VoidCallback onAdd, onAll;
  final ValueChanged<Highlight> onOpened;
  final ValueChanged<Highlight>? onEdited;
  const JourneyFeaturedHighlight({
    super.key,
    required this.highlights,
    required this.areas,
    required this.onAdd,
    required this.onAll,
    required this.onOpened,
    this.onEdited,
  });
  @override
  State<JourneyFeaturedHighlight> createState() =>
      _JourneyFeaturedHighlightState();
}

class _JourneyFeaturedHighlightState extends State<JourneyFeaturedHighlight> {
  final _pages = PageController(keepPage: false);
  int _index = 0;
  String? _selectedId;
  @override
  void initState() {
    super.initState();
    _selectedId = widget.highlights.firstOrNull?.id;
  }

  @override
  void didUpdateWidget(covariant JourneyFeaturedHighlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previousIds = oldWidget.highlights.map((h) => h.id).toSet();
    final added = widget.highlights
        .where((h) => !previousIds.contains(h.id))
        .firstOrNull;
    if (added != null) _selectedId = added.id;
    final index = widget.highlights.indexWhere((h) => h.id == _selectedId);
    final next = widget.highlights.isEmpty
        ? 0
        : index >= 0
        ? index
        : _index.clamp(0, widget.highlights.length - 1);
    _selectedId = widget.highlights.isEmpty ? null : widget.highlights[next].id;
    if (next != _index) {
      _index = next;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pages.hasClients) _pages.jumpToPage(_index);
      });
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _move(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= widget.highlights.length || !_pages.hasClients) {
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(next);
    } else {
      _pages.animateToPage(
        next,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    }
  }

  double _lineHeight(TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: 'Ag', style: style),
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: Directionality.of(context),
    )..layout();
    final height = painter.height;
    painter.dispose();
    return height;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final items = widget.highlights;
    final large = MediaQuery.textScalerOf(context).scale(14) > 19;
    final titleStyle = theme.textTheme.titleLarge!.copyWith(
      fontSize: 20,
      height: 1.2,
    );
    final detailStyle = theme.textTheme.bodySmall!.copyWith(
      height: 1.35,
      color: colors.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(
              'Highlights',
              style: theme.textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (items.isNotEmpty && widget.onEdited != null)
                  IconButton(
                    key: const ValueKey('edit-featured-highlight'),
                    tooltip: 'Edit Highlight',
                    onPressed: () => widget.onEdited!(items[_index]),
                    icon: const Icon(Icons.edit_outlined, size: 20),
                  ),
                IconButton(
                  key: const ValueKey('add-highlight'),
                  tooltip: 'Add Highlight',
                  onPressed: widget.onAdd,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
                Tooltip(
                  message: 'All Highlights',
                  child: TextButton(
                    key: const ValueKey('all-highlights'),
                    onPressed: widget.onAll,
                    child: const Text('All'),
                  ),
                ),
              ],
            ),
          ],
        ),
        if (items.isEmpty)
          Container(
            key: const ValueKey('empty-highlights'),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_outlined, color: colors.primary),
                const SizedBox(width: 12),
                const Expanded(child: Text('Keep a moment that matters.')),
              ],
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final description = !large && constraints.maxWidth >= 320;
              final titleLines = large ? 4 : 2;
              final metaLines = large ? 3 : 1;
              final height =
                  28 +
                  titleLines * _lineHeight(titleStyle) +
                  10 +
                  metaLines * _lineHeight(detailStyle) +
                  (description ? 6 + _lineHeight(detailStyle) : 0) +
                  (large ? 72 : 0);
              return SizedBox(
                height: height,
                child: PageView.builder(
                  key: const ValueKey('featured-highlights'),
                  controller: _pages,
                  itemCount: items.length,
                  allowImplicitScrolling: true,
                  onPageChanged: (index) => setState(() {
                    _index = index;
                    _selectedId = items[index].id;
                  }),
                  itemBuilder: (context, index) {
                    final highlight = items[index];
                    final matches = widget.areas.areas.where(
                      (a) => a.id == highlight.areaId,
                    );
                    final areaName = highlight.areaId == null
                        ? null
                        : matches.isEmpty
                        ? 'Area unavailable'
                        : matches.single.name;
                    final date = MaterialLocalizations.of(context)
                        .formatMediumDate(highlight.date);
                    final metadata =
                        '$date${areaName == null ? '' : ' · $areaName'}';
                    final area = matches.firstOrNull;
                    final accent = area == null
                        ? colors.primary
                        : Color(area.colour);
                    final illustration = SizedBox(
                      width: large
                          ? 68
                          : constraints.maxWidth >= 320
                          ? 100
                          : 72,
                      height: large ? 68 : 100,
                      child: HighlightIllustration(
                        key: ValueKey('highlight-illustration-${highlight.id}'),
                        iconId: resolveHighlightIllustration(
                          title: highlight.title,
                          explicitIcon: highlight.illustrationIcon,
                          areaIcon: area?.icon,
                        ),
                        accent: accent,
                      ),
                    );
                    final text = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              highlight.title,
                              style: titleStyle,
                              maxLines: titleLines,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          metadata,
                          style: detailStyle,
                          maxLines: metaLines,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (description && highlight.description != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            highlight.description!,
                            style: detailStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    );
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Semantics(
                        button: true,
                        label: '${highlight.title}. $metadata. Open Highlight',
                        onTap: () => widget.onOpened(highlight),
                        child: ExcludeSemantics(
                          child: JourneySurface(
                            accent: accent,
                            key: ValueKey('highlight-${highlight.id}'),
                            onTap: () => widget.onOpened(highlight),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: large
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: text),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: illustration,
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Expanded(child: text),
                                        const SizedBox(width: 8),
                                        illustration,
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        if (items.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                key: const ValueKey('previous-highlight'),
                tooltip: 'Previous Highlight',
                onPressed: _index == 0 ? null : () => _move(-1),
                icon: const Icon(Icons.chevron_left, size: 20),
              ),
              Semantics(
                container: true,
                liveRegion: true,
                label: 'Highlight ${_index + 1} of ${items.length}',
                excludeSemantics: true,
                child: Text(
                  '${_index + 1} / ${items.length}',
                  key: const ValueKey('highlight-position'),
                  style: theme.textTheme.bodySmall,
                ),
              ),
              IconButton(
                key: const ValueKey('next-highlight'),
                tooltip: 'Next Highlight',
                onPressed: _index == items.length - 1 ? null : () => _move(1),
                icon: const Icon(Icons.chevron_right, size: 20),
              ),
            ],
          ),
      ],
    );
  }
}

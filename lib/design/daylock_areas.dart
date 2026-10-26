import 'package:flutter/material.dart';

import '../models/area.dart';

const areaIcons = <String, IconData>{
  'life': Icons.wb_sunny_outlined,
  'health': Icons.favorite_outline,
  'work': Icons.work_outline,
  'learning': Icons.menu_book_outlined,
  'home': Icons.home_outlined,
  'people': Icons.people_outline,
  'creative': Icons.palette_outlined,
  'fitness': Icons.fitness_center,
};
const areaColours = <String, int>{
  'Lavender': Area.defaultColour,
  'Blue': 0xff528cce,
  'Teal': 0xff348e88,
  'Green': 0xff639455,
  'Amber': 0xffad802b,
  'Rose': 0xffc16e8b,
};

class AreaBadge extends StatelessWidget {
  final Area area;
  final TextStyle? textStyle;
  final double iconSize;
  const AreaBadge({
    super.key,
    required this.area,
    this.textStyle,
    this.iconSize = 20,
  });
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        areaIcons[area.icon] ?? areaIcons['life'],
        color: Color(area.colour),
        size: iconSize,
      ),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          '${area.name}${area.isArchived ? ' (archived)' : ''}',
          style: textStyle ?? Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    ],
  );
}

/// Expands inside the editor, so rollover closes the entire editing surface.
class AreaSelector extends StatefulWidget {
  final AreaBook book;
  final String? selectedId;
  final ValueChanged<String> onChanged;
  const AreaSelector({
    super.key,
    required this.book,
    required this.selectedId,
    required this.onChanged,
  });
  @override
  State<AreaSelector> createState() => _AreaSelectorState();
}

class _AreaSelectorState extends State<AreaSelector> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      OutlinedButton(
        key: const ValueKey('select-area'),
        onPressed: () => setState(() => _expanded = !_expanded),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = MediaQuery.textScalerOf(context).scale(14) > 22;
            final selection = Row(
              children: [
                if (!stacked) ...[
                  const Text('Area'),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: AreaBadge(
                    area: widget.book.resolve(widget.selectedId),
                  ),
                ),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              ],
            );
            return stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [const Text('Area'), selection],
                  )
                : selection;
          },
        ),
      ),
      if (_expanded)
        AreaChoices(
          book: widget.book,
          selectedId: widget.selectedId,
          onSelected: (id) {
            widget.onChanged(id);
            setState(() => _expanded = false);
          },
        ),
    ],
  );
}

class AreaChoices extends StatelessWidget {
  final AreaBook book;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  const AreaChoices({
    super.key,
    required this.book,
    required this.selectedId,
    required this.onSelected,
  });
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final area in book.active)
        ListTile(
          key: ValueKey('choose-area-${area.id}'),
          title: AreaBadge(area: area),
          selected: area.id == book.resolve(selectedId).id,
          trailing: area.id == book.resolve(selectedId).id
              ? const Icon(Icons.check)
              : null,
          onTap: () => onSelected(area.id),
        ),
    ],
  );
}

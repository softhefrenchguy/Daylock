import 'package:flutter/material.dart';

import '../models/area.dart';
import 'area_tones.dart';

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

/// Area picker: every active Area as a chip in its own (user-chosen) colour.
class AreaSelector extends StatelessWidget {
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Area',
        key: const ValueKey('select-area'),
        style: Theme.of(context).textTheme.labelLarge!
            .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 8),
      AreaChoices(book: book, selectedId: selectedId, onSelected: onChanged),
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = book.resolve(selectedId).id;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final area in book.active)
          Builder(
            builder: (context) {
              final tones = AreaTones.forContext(context, Color(area.colour));
              final on = area.id == selected;
              return Semantics(
                selected: on,
                button: true,
                child: Material(
                  key: ValueKey('choose-area-${area.id}'),
                  color: on ? tones.ink : tones.tint,
                  shape: const StadiumBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onSelected(area.id),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              on
                                  ? Icons.check_rounded
                                  : (areaIcons[area.icon] ??
                                        Icons.wb_sunny_outlined),
                              size: 18,
                              color: on ? tones.onInk : tones.ink,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                area.name,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelLarge!.copyWith(
                                  color: on ? tones.onInk : tones.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

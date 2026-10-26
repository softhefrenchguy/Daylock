import 'dart:math';

/// Relationships use IDs; names and appearance are freely editable.
class Area {
  static const defaultId = 'daylock.area.life';
  static const defaultColour = 0xff9473c6;
  static const maxNameLength = 60;
  final String id, name, icon;
  final int colour;
  final DateTime createdAt;
  final bool isArchived, isDefault;

  Area({
    required this.id,
    required String name,
    required this.icon,
    required this.colour,
    required DateTime createdAt,
    this.isArchived = false,
    this.isDefault = false,
  }) : name = name.trim(),
       createdAt = createdAt.toUtc() {
    if (id.trim().isEmpty ||
        this.name.isEmpty ||
        this.name.runes.length > maxNameLength ||
        icon.isEmpty ||
        colour < 0xff000000 ||
        colour > 0xffffffff ||
        isDefault != (id == defaultId) ||
        (isDefault && isArchived)) {
      throw const FormatException('Invalid Area');
    }
  }

  factory Area.create({
    required String name,
    required String icon,
    required int colour,
    required DateTime now,
  }) {
    final random = Random.secure();
    final id = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    return Area(id: id, name: name, icon: icon, colour: colour, createdAt: now);
  }

  Area copyWith({String? name, String? icon, int? colour, bool? isArchived}) =>
      Area(
        id: id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        colour: colour ?? this.colour,
        createdAt: createdAt,
        isDefault: isDefault,
        isArchived: isArchived ?? this.isArchived,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'colour': colour,
    'createdAt': createdAt.toIso8601String(),
    'isArchived': isArchived,
    'isDefault': isDefault,
  };
  factory Area.fromJson(Map<String, dynamic> json) => Area(
    id: json['id'] as String,
    name: json['name'] as String,
    icon: json['icon'] as String,
    colour: json['colour'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
    isArchived: json['isArchived'] as bool,
    isDefault: json['isDefault'] as bool,
  );
}

/// Invalid/missing relationships fall back at resolution, not by rewriting history.
String? readAreaId(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : null;

class AreaBook {
  final List<Area> areas;
  AreaBook(Iterable<Area> areas) : areas = List.unmodifiable(areas) {
    if (this.areas.where((a) => a.isDefault).length != 1 ||
        this.areas.map((a) => a.id).toSet().length != this.areas.length) {
      throw const FormatException(
        'Areas require one permanent default and unique IDs',
      );
    }
  }
  factory AreaBook.initial({DateTime? createdAt}) => AreaBook([
    Area(
      id: Area.defaultId,
      name: 'Life',
      icon: 'life',
      colour: Area.defaultColour,
      createdAt: createdAt ?? DateTime.now(),
      isDefault: true,
    ),
  ]);
  Area get defaultArea => areas.singleWhere((a) => a.isDefault);
  List<Area> get active => List.unmodifiable(areas.where((a) => !a.isArchived));
  Area resolve(String? id) =>
      areas.firstWhere((a) => a.id == id, orElse: () => defaultArea);
  Area forNewCommitment(String? id) {
    final area = resolve(id);
    return area.isArchived ? defaultArea : area;
  }

  AreaBook upsert(Area area) {
    final previous = areas.where((a) => a.id == area.id);
    if (previous.isNotEmpty &&
        (previous.single.createdAt != area.createdAt ||
            previous.single.isDefault != area.isDefault)) {
      throw StateError('Area identity cannot change');
    }
    return AreaBook([
      for (final old in areas)
        if (old.id == area.id) area else old,
      if (previous.isEmpty) area,
    ]);
  }

  AreaBook archive(String id, bool archived) {
    final area = areas.singleWhere((a) => a.id == id);
    return upsert(area.copyWith(isArchived: archived));
  }

  // No hard-delete operation: historical references remain resolvable.
  List<Map<String, dynamic>> toJson() => areas.map((a) => a.toJson()).toList();
  factory AreaBook.fromJson(List<dynamic> json) => AreaBook(
    json.map((value) => Area.fromJson(value as Map<String, dynamic>)),
  );
}

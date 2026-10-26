import 'dart:math';

import 'area.dart';

/// Personal milestones are independent of planner execution and eligibility.
class Highlight {
  static const maxTitleLength = 120;
  static const maxDescriptionLength = 2000;
  final String id, title;
  final DateTime date;
  final String? description, areaId;

  Highlight({
    required this.id,
    required String title,
    required DateTime date,
    String? description,
    this.areaId,
  }) : title = title.trim(),
       date = DateTime(date.year, date.month, date.day),
       description = description?.trim().isEmpty == true
           ? null
           : description?.trim() {
    if (id.trim().isEmpty ||
        date.year < 1 ||
        date.year > 9999 ||
        this.title.isEmpty ||
        this.title.runes.length > maxTitleLength ||
        (this.description?.runes.length ?? 0) > maxDescriptionLength) {
      throw const FormatException('Invalid Highlight');
    }
  }

  factory Highlight.create({
    required String title,
    required DateTime date,
    String? description,
    String? areaId,
  }) {
    final random = Random.secure();
    final id = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    return Highlight(
      id: id,
      title: title,
      date: date,
      description: description,
      areaId: areaId,
    );
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date':
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    'description': description,
    if (areaId != null) 'areaId': areaId,
  };
  factory Highlight.fromJson(Map<String, dynamic> json) {
    final raw = json['date'] as String;
    final date = DateTime.parse(raw);
    final result = Highlight(
      id: json['id'] as String,
      title: json['title'] as String,
      date: date,
      description: json['description'] as String?,
      areaId: readAreaId(json['areaId']),
    );
    if (result.toJson()['date'] != raw) {
      throw const FormatException('Invalid Highlight date');
    }
    return result;
  }
}

class HighlightBook {
  final List<Highlight> highlights;
  static const empty = HighlightBook._empty();
  const HighlightBook._empty() : highlights = const [];
  HighlightBook(Iterable<Highlight> values)
    : highlights = List.unmodifiable(values) {
    if (highlights.map((h) => h.id).toSet().length != highlights.length) {
      throw const FormatException('Duplicate Highlight ID');
    }
  }
  List<Highlight> get newestFirst => List.unmodifiable(
    [...highlights]..sort((a, b) {
      final date = b.date.compareTo(a.date);
      return date != 0 ? date : a.id.compareTo(b.id);
    }),
  );
  HighlightBook upsert(Highlight value) => HighlightBook([
    for (final old in highlights)
      if (old.id == value.id) value else old,
    if (!highlights.any((h) => h.id == value.id)) value,
  ]);
  HighlightBook remove(String id) =>
      HighlightBook(highlights.where((h) => h.id != id));
  List<Map<String, dynamic>> toJson() =>
      highlights.map((h) => h.toJson()).toList();
  factory HighlightBook.fromJson(List<dynamic> json) => HighlightBook(
    json.map((h) => Highlight.fromJson(h as Map<String, dynamic>)),
  );
}

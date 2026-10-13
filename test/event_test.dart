import 'dart:convert';

import 'package:daylock/models/event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Event JSON round trip preserves all fields without completion state',
    () {
      final event = Event(
        id: 'lesson',
        title: ' Driving lesson ',
        date: DateTime.utc(2026, 10, 10, 23, 30),
        startTime: EventTime(14, 0),
        endTime: EventTime(16, 0),
        notes: ' Bring licence ',
      );
      final json =
          jsonDecode(jsonEncode(event.toJson())) as Map<String, dynamic>;
      expect(json, {
        'id': 'lesson',
        'title': 'Driving lesson',
        'date': '2026-10-10',
        'startTime': '14:00',
        'endTime': '16:00',
        'notes': 'Bring licence',
        'source': 'local',
      });
      final restored = Event.fromJson(json);
      expect(restored.toJson(), event.toJson());
      expect(restored.date, DateTime(2026, 10, 10));
      expect(restored.timeLabel, '14:00–16:00');
      expect(json.containsKey('isCompleted'), isFalse);
      expect(json.containsKey('type'), isFalse);
    },
  );

  test('Times and notes are independently optional', () {
    final allDay = Event(
      id: 'a',
      title: 'Birthday',
      date: DateTime(2028, 2, 29),
      notes: ' ',
    );
    final restored = Event.fromJson(allDay.toJson());
    expect(restored.startTime, isNull);
    expect(restored.endTime, isNull);
    expect(restored.notes, isNull);
    expect(restored.timeLabel, 'All day');
    expect(
      Event(
        id: 'b',
        title: 'Starts',
        date: allDay.date,
        startTime: EventTime(9, 5),
      ).timeLabel,
      '09:05',
    );
    expect(
      Event(
        id: 'c',
        title: 'Ends',
        date: allDay.date,
        endTime: EventTime(17, 30),
      ).timeLabel,
      'Until 17:30',
    );
  });

  test('Filtering uses calendar dates and sorts all-day then timed events', () {
    final date = DateTime(2026, 10, 10);
    final events = [
      Event(
        id: 'late',
        title: 'Later',
        date: date,
        startTime: EventTime(16, 0),
      ),
      Event(id: 'other', title: 'Other day', date: DateTime(2026, 10, 11)),
      Event(
        id: 'early',
        title: 'Earlier',
        date: date,
        startTime: EventTime(9, 0),
      ),
      Event(id: 'all', title: 'All day', date: date),
    ];
    expect(
      Event.forDate(events, DateTime.utc(2026, 10, 10, 23)).map((e) => e.id),
      ['all', 'early', 'late'],
    );
    expect(events.first.id, 'late'); // Sorting must not mutate shared state.
    expect(Event.forDate(events, DateTime(2026, 10, 12)), isEmpty);
  });

  test('New IDs differ even for events created together', () {
    final ids = List.generate(100, (_) => Event.newId());
    expect(ids.toSet(), hasLength(100));
    expect(ids.every((id) => RegExp(r'^[0-9a-f]{32}$').hasMatch(id)), isTrue);
  });

  test('Rejects missing titles, IDs, and reversed or equal time ranges', () {
    final date = DateTime(2026, 10, 10);
    expect(
      () => Event(id: '', title: 'Lesson', date: date),
      throwsFormatException,
    );
    expect(() => Event(id: 'x', title: ' ', date: date), throwsFormatException);
    for (final hour in [13, 14]) {
      expect(
        () => Event(
          id: 'x',
          title: 'Lesson',
          date: date,
          startTime: EventTime(14, 0),
          endTime: EventTime(hour, 0),
        ),
        throwsFormatException,
      );
    }
  });

  test('Rejects invalid or normalized dates and malformed times', () {
    final json = Event(
      id: 'x',
      title: 'Lesson',
      date: DateTime(2026, 10, 10),
    ).toJson();
    for (final date in [
      '2026-02-30',
      '2026-13-01',
      '2027-02-29',
      '2026-1-10',
      '2026-10-10T00:00:00Z',
    ]) {
      expect(
        () => Event.fromJson({...json, 'date': date}),
        throwsFormatException,
      );
    }
    for (final time in ['24:00', '12:60', '9:00', '12:00Z', 'abc']) {
      expect(
        () => Event.fromJson({...json, 'startTime': time}),
        throwsFormatException,
      );
    }
  });
}

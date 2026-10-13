import 'dart:math';
import 'dart:convert';

enum EventSource {
  local,
  google,
  microsoftPersonal,
  microsoftWorkSchool;

  String get label => switch (this) {
    local => 'Local',
    google => 'Google Calendar',
    microsoftPersonal => 'Microsoft Personal',
    microsoftWorkSchool => 'Microsoft Work/School',
  };
}

// A wall-clock time, independent of time zones and elapsed timer durations.
class EventTime implements Comparable<EventTime> {
  final int hour;
  final int minute;

  EventTime(this.hour, this.minute) {
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw const FormatException('Invalid event time');
    }
  }

  factory EventTime.parse(String value) {
    if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(value)) {
      throw const FormatException('Use HH:mm for event times');
    }
    return EventTime(
      int.parse(value.substring(0, 2)),
      int.parse(value.substring(3)),
    );
  }

  @override
  int compareTo(EventTime other) =>
      (hour * 60 + minute).compareTo(other.hour * 60 + other.minute);

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

// Scheduled information only: events have no commitment or completion state.
class Event {
  final String id;
  final String title;
  final DateTime _date;
  final EventTime? startTime;
  final EventTime? endTime;
  final String? notes;
  final EventSource source;
  final String? externalEventId;
  final String? accountId;
  final String? calendarId;
  final Uri? meetingUrl;
  final DateTime? startsAtUtc;
  final DateTime? endsAtUtc;
  final DateTime? allDayEndDateExclusive;

  bool get isExternal => source != EventSource.local;
  // Recompute when the device changes zone; UTC instants are the source of truth.
  DateTime get date =>
      startsAtUtc == null ? _date : _day(startsAtUtc!.toLocal());
  static DateTime _day(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  Event({
    required this.id,
    required String title,
    required DateTime date,
    this.startTime,
    this.endTime,
    String? notes,
    this.source = EventSource.local,
    this.externalEventId,
    this.accountId,
    this.calendarId,
    this.meetingUrl,
    this.startsAtUtc,
    this.endsAtUtc,
    DateTime? allDayEndDateExclusive,
  }) : title = title.trim(),
       _date = _day(date),
       allDayEndDateExclusive = allDayEndDateExclusive == null
           ? null
           : _day(allDayEndDateExclusive),
       notes = notes == null || notes.trim().isEmpty ? null : notes.trim() {
    if (id.trim().isEmpty || this.title.isEmpty) {
      throw const FormatException('Events need an ID and title');
    }
    if (meetingUrl != null &&
        (!['https', 'http'].contains(meetingUrl!.scheme) ||
            meetingUrl!.host.isEmpty)) {
      throw const FormatException('Invalid meeting URL');
    }
    if (isExternal) {
      if (externalEventId == null ||
          externalEventId!.isEmpty ||
          accountId == null ||
          accountId!.isEmpty ||
          calendarId == null ||
          calendarId!.isEmpty ||
          id != externalId(source, accountId!, calendarId!, externalEventId!)) {
        throw const FormatException('External events need a scoped identity');
      }
      final timed = startsAtUtc != null && endsAtUtc != null;
      final allDay =
          startsAtUtc == null &&
          endsAtUtc == null &&
          this.allDayEndDateExclusive != null;
      if (startTime != null ||
          endTime != null ||
          (!timed && !allDay) ||
          (timed &&
              (this.allDayEndDateExclusive != null ||
                  !startsAtUtc!.isUtc ||
                  !endsAtUtc!.isUtc ||
                  !endsAtUtc!.isAfter(startsAtUtc!))) ||
          (allDay && !this.allDayEndDateExclusive!.isAfter(_date))) {
        throw const FormatException('Invalid external event date range');
      }
    } else if (externalEventId != null ||
        accountId != null ||
        calendarId != null ||
        startsAtUtc != null ||
        endsAtUtc != null ||
        allDayEndDateExclusive != null) {
      throw const FormatException(
        'Local events cannot carry external metadata',
      );
    }
    if (startTime != null &&
        endTime != null &&
        endTime!.compareTo(startTime!) <= 0) {
      throw const FormatException('End time must be after start time');
    }
  }

  static String externalId(
    EventSource source,
    String accountId,
    String calendarId,
    String remoteId,
  ) =>
      'external:${base64Url.encode(utf8.encode(jsonEncode([source.name, accountId, calendarId, remoteId])))}';

  factory Event.externalTimed({
    required EventSource source,
    required String accountId,
    required String calendarId,
    required String externalEventId,
    required String title,
    required DateTime startsAtUtc,
    required DateTime endsAtUtc,
    String? notes,
    Uri? meetingUrl,
  }) => Event(
    id: externalId(source, accountId, calendarId, externalEventId),
    source: source,
    accountId: accountId,
    calendarId: calendarId,
    externalEventId: externalEventId,
    title: title,
    date: startsAtUtc.toLocal(),
    startsAtUtc: startsAtUtc,
    endsAtUtc: endsAtUtc,
    notes: notes,
    meetingUrl: meetingUrl,
  );

  factory Event.externalAllDay({
    required EventSource source,
    required String accountId,
    required String calendarId,
    required String externalEventId,
    required String title,
    required DateTime date,
    required DateTime endDateExclusive,
    String? notes,
    Uri? meetingUrl,
  }) => Event(
    id: externalId(source, accountId, calendarId, externalEventId),
    source: source,
    accountId: accountId,
    calendarId: calendarId,
    externalEventId: externalEventId,
    title: title,
    date: date,
    allDayEndDateExclusive: endDateExclusive,
    notes: notes,
    meetingUrl: meetingUrl,
  );

  bool occursOn(DateTime date) =>
      overlapsDates(_day(date), DateTime(date.year, date.month, date.day + 1));

  bool overlapsDates(DateTime start, DateTime endExclusive) {
    if (startsAtUtc != null) {
      return startsAtUtc!.isBefore(endExclusive.toUtc()) &&
          endsAtUtc!.isAfter(start.toUtc());
    }
    final end =
        allDayEndDateExclusive ??
        DateTime(_date.year, _date.month, _date.day + 1);
    return _date.isBefore(endExclusive) && end.isAfter(start);
  }

  String timeLabelForDate(DateTime selectedDate) {
    if (startsAtUtc == null) return timeLabel;
    final start = startsAtUtc!.toLocal();
    final end = endsAtUtc!.toLocal();
    final day = _day(selectedDate);
    final next = DateTime(day.year, day.month, day.day + 1);
    if (!start.isAfter(day) && !end.isBefore(next)) return 'Continues all day';
    final from = start.isBefore(day)
        ? 'Earlier'
        : EventTime(start.hour, start.minute).toString();
    final until = !end.isBefore(next)
        ? 'Next day'
        : EventTime(end.hour, end.minute).toString();
    return '$from–$until';
  }

  static String newId() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  String get timeLabel {
    if (startsAtUtc != null) return timeLabelForDate(date);
    if (startTime != null && endTime != null) return '$startTime–$endTime';
    if (startTime != null) return '$startTime';
    if (endTime != null) return 'Until $endTime';
    return 'All day';
  }

  static List<Event> forDate(Iterable<Event> events, DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final result = events.where((event) => event.occursOn(day)).toList();
    result.sort((a, b) {
      final aMinutes = a.startsAtUtc != null
          ? (a.startsAtUtc!.toLocal().isBefore(day)
                ? 0
                : a.startsAtUtc!.toLocal().hour * 60 +
                      a.startsAtUtc!.toLocal().minute)
          : a.startTime == null
          ? -1
          : a.startTime!.hour * 60 + a.startTime!.minute;
      final bMinutes = b.startsAtUtc != null
          ? (b.startsAtUtc!.toLocal().isBefore(day)
                ? 0
                : b.startsAtUtc!.toLocal().hour * 60 +
                      b.startsAtUtc!.toLocal().minute)
          : b.startTime == null
          ? -1
          : b.startTime!.hour * 60 + b.startTime!.minute;
      final timeOrder = aMinutes.compareTo(bMinutes);
      return timeOrder != 0 ? timeOrder : a.title.compareTo(b.title);
    });
    return result;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date':
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    'startTime': startTime?.toString(),
    'endTime': endTime?.toString(),
    'notes': notes,
    'source': source.name,
    if (meetingUrl != null) 'meetingUrl': meetingUrl.toString(),
    if (isExternal) ...{
      'externalEventId': externalEventId,
      'accountId': accountId,
      'calendarId': calendarId,
      'startsAtUtc': startsAtUtc?.toIso8601String(),
      'endsAtUtc': endsAtUtc?.toIso8601String(),
      'allDayEndDateExclusive': allDayEndDateExclusive
          ?.toIso8601String()
          .substring(0, 10),
    },
  };

  factory Event.fromJson(Map<String, dynamic> json) {
    final dateText = json['date'] as String;
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateText)) {
      throw const FormatException('Invalid event date');
    }
    final year = int.parse(dateText.substring(0, 4));
    final month = int.parse(dateText.substring(5, 7));
    final day = int.parse(dateText.substring(8));
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      throw const FormatException('Invalid event date');
    }
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      date: date,
      startTime: json['startTime'] == null
          ? null
          : EventTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : EventTime.parse(json['endTime'] as String),
      notes: json['notes'] as String?,
      source: json.containsKey('source')
          ? EventSource.values.byName(json['source'] as String)
          : EventSource.local,
      externalEventId: json['externalEventId'] as String?,
      accountId: json['accountId'] as String?,
      calendarId: json['calendarId'] as String?,
      meetingUrl: json['meetingUrl'] == null
          ? null
          : Uri.parse(json['meetingUrl'] as String),
      startsAtUtc: json['startsAtUtc'] == null
          ? null
          : DateTime.parse(json['startsAtUtc'] as String),
      endsAtUtc: json['endsAtUtc'] == null
          ? null
          : DateTime.parse(json['endsAtUtc'] as String),
      allDayEndDateExclusive: json['allDayEndDateExclusive'] == null
          ? null
          : _parseDate(json['allDayEndDateExclusive'] as String),
    );
  }

  static DateTime _parseDate(String text) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) {
      throw const FormatException('Invalid event date');
    }
    final date = DateTime.parse(text);
    if (date.toIso8601String().substring(0, 10) != text) {
      throw const FormatException('Invalid event date');
    }
    return date;
  }
}

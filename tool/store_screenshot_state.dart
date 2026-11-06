// Sample data for Play Store screenshots. Prints a DaylockState as JSON.
//
//   dart run tool/store_screenshot_state.dart progress   # Friday morning
//   dart run tool/store_screenshot_state.dart earned     # Friday evening
//
// The output is loaded into a web build's storage by the screenshot script;
// this file never touches real user data.
import 'dart:convert';

import 'package:daylock/models/area.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/daylock_state.dart';
import 'package:daylock/models/freedom_settings.dart';
import 'package:daylock/models/highlight.dart';
import 'package:daylock/models/plan_history.dart';
import 'package:daylock/models/task.dart';

final today = DateTime(2026, 11, 13);
final created = DateTime(2026, 9, 1);

Area area(String id, String name, String icon, int colour) =>
    Area(id: id, name: name, icon: icon, colour: colour, createdAt: created);

final areas = AreaBook([
  AreaBook.initial(
    createdAt: created,
  ).defaultArea.copyWith(name: 'Life', colour: 0xffc16e8b),
  area('mind', 'Mind', 'learning', 0xff9473c6),
  area('body', 'Body', 'fitness', 0xff348e88),
  area('career', 'Career', 'work', 0xffad802b),
]);

const _rotation = [
  ['Read 20 pages', 'mind'],
  ['Strength session', 'body'],
  ['Two hours of deep work', 'career'],
  ['Call home', Area.defaultId],
  ['Morning run', 'body'],
  ['Practise Spanish', 'mind'],
];

/// Five weeks of mostly kept days, a 12-day streak ending yesterday.
PlanHistory history() {
  var book = PlanHistory.empty;
  for (var back = 34; back >= 1; back--) {
    final date = DateTime(today.year, today.month, today.day - back);
    if (back == 21 || back == 27) continue; // days without a plan
    final kept = switch (back) {
      13 || 25 => 1, // missed most
      17 || 23 || 30 => 2, // some kept
      _ => 3,
    };
    book = book.archive(
      DailyPlan(
        date: date,
        isCommitted: true,
        tasks: [
          for (var i = 0; i < 3; i++)
            Task(
              name: _rotation[(back + i) % _rotation.length][0],
              areaId: _rotation[(back + i) % _rotation.length][1],
              isCompleted: i < kept,
              accumulatedFocusMilliseconds: i == 0 ? 25 * 60000 : 0,
            ),
        ],
      ),
    );
  }
  return book;
}

final highlights = HighlightBook([
  Highlight(
    id: 'driving',
    title: 'Passed my driving test',
    date: DateTime(2026, 11, 2),
    areaId: Area.defaultId,
  ),
  Highlight(
    id: 'thesis',
    title: 'First thesis chapter drafted',
    date: DateTime(2026, 10, 28),
    areaId: 'career',
    illustrationIcon: 'award',
  ),
  Highlight(
    id: 'run',
    title: 'Ran my first 10k',
    date: DateTime(2026, 10, 18),
    areaId: 'body',
  ),
  Highlight(
    id: 'books',
    title: 'Read 12 books this year',
    date: DateTime(2026, 10, 4),
    areaId: 'mind',
    illustrationIcon: 'learning',
  ),
]);

DaylockState state({required bool earned}) => DaylockState(
  areas: areas,
  history: history(),
  highlights: highlights,
  freedomSettings: const FreedomSettings(enabled: true, hour: 18, minute: 0),
  todayPlan: DailyPlan(
    date: today,
    isCommitted: true,
    tasks: [
      Task(name: 'Read 20 pages of Kahneman', areaId: 'mind', isCompleted: true),
      Task(
        name: 'Gym, upper body',
        areaId: 'body',
        isCompleted: earned,
        accumulatedFocusMilliseconds: 32 * 60000 + 14000,
      ),
      Task(
        name: 'Send the internship application',
        areaId: 'career',
        isCompleted: earned,
      ),
      Task(name: 'Call Grandma', isCompleted: true),
    ],
  ),
  tomorrowPlan: DailyPlan(
    date: today.add(const Duration(days: 1)),
    isCommitted: earned,
    tasks: [
      Task(name: 'Morning run, 5k', areaId: 'body'),
      Task(name: 'Finish chapter 3 notes', areaId: 'mind'),
      Task(name: 'Update my portfolio case study', areaId: 'career'),
      Task(name: 'Cook dinner for the family'),
    ],
  ),
);

void main(List<String> args) {
  final earned = args.isNotEmpty && args.first == 'earned';
  print(jsonEncode(state(earned: earned).toJson()));
}

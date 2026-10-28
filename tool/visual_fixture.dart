// Explicit, in-memory screenshot fixtures. Never imported by lib/main.dart.
// Run only on an emulator; this entry point never reads or writes user storage.
import 'package:flutter/material.dart';
import 'package:daylock/design/daylock_theme.dart';
import 'package:daylock/models/area.dart';
import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/freedom_settings.dart';
import 'package:daylock/models/highlight.dart';
import 'package:daylock/models/plan_history.dart';
import 'package:daylock/models/routine.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/screens/today_screen.dart';
import 'package:daylock/screens/plan_screen.dart';
import 'package:daylock/screens/journey_screen.dart';
import 'package:daylock/services/freedom_service.dart';
import 'package:daylock/services/journey_service.dart';
import 'package:daylock/services/routine_service.dart';

void main() => runApp(const VisualFixture());

final fixtureNow = DateTime(2026, 10, 27, 18, 17);
final fixtureAreas = AreaBook([
  AreaBook.initial(createdAt: fixtureNow).defaultArea,
  Area(
    id: 'gym',
    name: 'Gym',
    icon: 'fitness',
    colour: 0xff528cce,
    createdAt: fixtureNow,
  ),
  Area(
    id: 'pega',
    name: 'Pega',
    icon: 'work',
    colour: 0xff348e88,
    createdAt: fixtureNow,
  ),
  Area(
    id: 'cooking',
    name: 'Cooking',
    icon: 'creative',
    colour: 0xffad802b,
    createdAt: fixtureNow,
  ),
]);

DailyPlan fixtureToday({bool running = false}) => DailyPlan(
  date: fixtureNow,
  isCommitted: true,
  tasks: [
    Task(
      name: 'Pega',
      areaId: 'pega',
      isCompleted: !running,
      accumulatedFocusMilliseconds: running ? 5689000 : 7536000,
      focusStartedAt: running ? fixtureNow : null,
    ),
    Task(name: 'Wrist exercise', areaId: 'gym', isCompleted: !running),
    Task(name: 'Weigh yourself', isCompleted: true),
  ],
);

class VisualFixture extends StatefulWidget {
  final int initialState;
  const VisualFixture({super.key, this.initialState = 0});
  @override
  State<VisualFixture> createState() => _VisualFixtureState();
}

class _VisualFixtureState extends State<VisualFixture> {
  late int state = widget.initialState;
  @override
  Widget build(BuildContext context) {
    final page = state < 2
        ? 0
        : state < 4
        ? 1
        : 2;
    final today = fixtureToday(running: state == 1);
    final tomorrow = DailyPlan(
      date: DateTime(2026, 10, 28),
      tasks: state == 3
          ? [
              Task(name: 'Pega', areaId: 'pega'),
              Task(name: 'Gym', areaId: 'gym'),
              Task(name: 'Read'),
              Task(name: 'Plan weekend', areaId: 'cooking'),
            ]
          : [],
    );
    final highlights = HighlightBook([
      Highlight(
        id: 'driving',
        title: 'Driving licence',
        date: DateTime(2026, 10, 9),
        description: 'got two minors, very happy',
        areaId: Area.defaultId,
      ),
      Highlight(
        id: 'cert',
        title: 'Ba certification',
        date: DateTime(2026, 10, 8),
        areaId: 'pega',
      ),
    ]);
    final history = PlanHistory.empty.archive(
      DailyPlan(
        date: DateTime(2026, 10, 25),
        tasks: [
          for (var i = 0; i < 10; i++)
            Task(
              name: 'Earlier $i',
              isCompleted: true,
              accumulatedFocusMilliseconds: i == 0 ? 43164000 : 0,
            ),
        ],
      ),
    );
    return MaterialApp(
      theme: DaylockTheme.dark,
      debugShowCheckedModeBanner: false,
      home: RepaintBoundary(
        key: const ValueKey('visual-capture'),
        child: Scaffold(
          body: page == 0
              ? TodayScreen(
                  plan: today,
                  areas: fixtureAreas,
                  currentTime: fixtureNow,
                  freedomEligibility: const FreedomService().evaluate(
                    now: fixtureNow,
                    settings: const FreedomSettings(enabled: true),
                    todayPlan: today,
                    tomorrowPlan: tomorrow,
                  ),
                  onTaskChanged: () => setState(() {}),
                  onFocusToggled: (_) {},
                  onSettingsRequested: () {},
                )
              : page == 1
              ? PlanScreen(
                  plan: tomorrow,
                  areas: fixtureAreas,
                  onTaskCreated: (_) {},
                  onCommitTomorrow: () {},
                  onTaskEdited: (_, _) {},
                  onTaskRemoved: (_) {},
                  onTaskAreaChanged: (_, _) {},
                  onRoutineAction: (_, _) {},
                  routineSuggestions: [
                    RoutineSuggestion(
                      routineId: 'fixture',
                      routineName: 'Morning',
                      date: tomorrow.date,
                      revision: 1,
                      step: RoutineStep(
                        id: 'step',
                        name: 'Stretch',
                        type: TaskType.goal,
                      ),
                    ),
                  ],
                )
              : JourneyScreen(
                  areas: fixtureAreas,
                  highlights: highlights,
                  data: JourneyData(
                    areas: fixtureAreas,
                    history: history,
                    todayPlan: today,
                    now: fixtureNow,
                  ),
                  onAreaOpened: (_) {},
                  onHighlightOpened: (_) {},
                  onHighlightEdited: (_) {},
                  onAddHighlight: () {},
                  onAllHighlights: () {},
                  onDailyHistory: () {},
                  onPastChapters: () {},
                  onManageAreas: () {},
                ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: page,
            onDestinationSelected: (index) => setState(() {
              state = index == 0
                  ? (state == 0 ? 1 : 0)
                  : index == 1
                  ? (state == 2 ? 3 : 2)
                  : 4;
            }),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.today_outlined),
                selectedIcon: Icon(Icons.today),
                label: 'Today',
              ),
              NavigationDestination(
                icon: Icon(Icons.edit_note_outlined),
                selectedIcon: Icon(Icons.edit_note),
                label: 'Plan',
              ),
              NavigationDestination(
                icon: Icon(Icons.auto_stories_outlined),
                selectedIcon: Icon(Icons.auto_stories),
                label: 'Journey',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

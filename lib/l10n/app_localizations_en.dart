// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Daylock';

  @override
  String get appearanceDark => 'Dark';

  @override
  String get appearanceLight => 'Light';

  @override
  String get appearanceSystem => 'System';

  @override
  String get colourViolet => 'Violet';

  @override
  String get colourOcean => 'Ocean';

  @override
  String get colourForest => 'Forest';

  @override
  String get colourEmber => 'Ember';

  @override
  String get colourRose => 'Rose';

  @override
  String get colourMono => 'Mono';

  @override
  String get illustrationCelebration => 'Celebration';

  @override
  String get illustrationDriving => 'Driving';

  @override
  String get illustrationAward => 'Award';

  @override
  String get illustrationCooking => 'Cooking';

  @override
  String get illustrationTravel => 'Travel';

  @override
  String get illustrationFitness => 'Fitness';

  @override
  String get illustrationLearning => 'Learning';

  @override
  String get illustrationHealth => 'Health';

  @override
  String get illustrationWork => 'Work';

  @override
  String get illustrationHome => 'Home';

  @override
  String get illustrationPeople => 'People';

  @override
  String get illustrationCreativity => 'Creativity';

  @override
  String get illustrationSunrise => 'Sunrise';

  @override
  String get outcomeIncomplete => 'Incomplete';

  @override
  String get outcomeCompleted => 'Completed';

  @override
  String get outcomeExcused => 'Excused';

  @override
  String get sourceLocal => 'Local';

  @override
  String get sourceGoogle => 'Google Calendar';

  @override
  String get sourceMicrosoftPersonal => 'Microsoft Personal';

  @override
  String get sourceMicrosoftWorkSchool => 'Microsoft Work/School';

  @override
  String get freedomStateEarned => 'Earned';

  @override
  String get freedomStateNotEarned => 'Not earned';

  @override
  String get freedomStateControlOff => 'Control off';

  @override
  String get freedomStateUnknown => 'Unknown';

  @override
  String get listSeparator => ', ';

  @override
  String get repeatDaily => 'Daily';

  @override
  String repeatEveryDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count days',
      one: 'Every day',
    );
    return '$_temp0';
  }

  @override
  String get repeatWeekdays => 'Weekdays';

  @override
  String get repeatWeekends => 'Weekends';

  @override
  String get eventContinuesAllDay => 'Continues all day';

  @override
  String get eventEarlier => 'Earlier';

  @override
  String get eventNextDay => 'Next day';

  @override
  String eventUntil(String time) {
    return 'Until $time';
  }

  @override
  String get eventAllDay => 'All day';

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get durationUnderMinute => '<1 min';

  @override
  String durationHours(int hours) {
    return '$hours hr';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours hr $minutes min';
  }

  @override
  String get settingsFreedomControl => 'Freedom Control';

  @override
  String get settingsPlanningRoutines => 'Planning & Routines';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsRestrictedApps => 'Restricted Apps';

  @override
  String get settingsPermissionsDiagnostics => 'Permissions & Diagnostics';

  @override
  String get settingsManageRoutines => 'Manage routines';

  @override
  String routineCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count routines',
      one: '1 routine',
    );
    return '$_temp0';
  }

  @override
  String get settingsRoutinesIntro =>
      'Plan your next steps with recurring commitments.';

  @override
  String get settingsNotificationsUnavailable =>
      'Notification controls are unavailable on this device.';

  @override
  String get keepYourWord => 'Keep your word.';

  @override
  String get settingsAboutCommitments =>
      'Commitments, optional stopwatches and progress in the areas that matter.';

  @override
  String get settingsRestrictedIntro =>
      'Choose which supported Android apps to restrict until Freedom is earned.';

  @override
  String get settingsRestrictionsAndroidOnly =>
      'App restrictions are available on Android.';

  @override
  String get settingsDiagnosticsAndroidOnly =>
      'Accessibility diagnostics are available on Android.';

  @override
  String get freedomTime => 'Freedom Time';

  @override
  String get settingsRestrictionNeedsAttention =>
      'App restriction status needs attention';

  @override
  String settingsSelectedSwitchOn(int count) {
    return '$count selected, switch on';
  }

  @override
  String settingsSelectedSwitchOff(int count) {
    return '$count selected, switch off';
  }

  @override
  String get accessibility => 'Accessibility';

  @override
  String get statusUnavailable => 'Status unavailable';

  @override
  String get availableOnAndroid => 'Available on Android';

  @override
  String get serviceConnected => 'Service connected';

  @override
  String get waitingForConnection => 'Waiting for connection';

  @override
  String get serviceDisabled => 'Service disabled';

  @override
  String get settingsChooseInstalledApps => 'Choose installed Android apps';

  @override
  String get settingsFreedomSubtitle =>
      'Restricted apps, Freedom Time and permissions';

  @override
  String get on => 'On';

  @override
  String get off => 'Off';

  @override
  String get settingsPlanningSubtitle => 'Recurring commitments and planning';

  @override
  String get settingsAppearanceSubtitle => 'Theme, colours and Areas';

  @override
  String get settingsNotificationsSubtitle => 'Reminders and alerts';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsRunSetup => 'Run Setup Tutorial';

  @override
  String get settingsRunSetupSubtitle =>
      'Permissions, distractions and your first commitment';

  @override
  String get settingsTakeTour => 'Take the App Tour';

  @override
  String get settingsTakeTourSubtitle =>
      'A guided look at Today, Plan and Journey';

  @override
  String get settingsAboutSubtitle => 'App information';

  @override
  String get tagline => 'Plan your day. Earn your freedom.';

  @override
  String get freedomStatusUnavailable => 'Freedom status unavailable';

  @override
  String get freedomControlOff => 'Freedom Control is off';

  @override
  String get appearanceFollowsDevice => 'Follows your device appearance.';

  @override
  String appearanceFixed(String mode) {
    return '$mode appearance, in any device mode.';
  }

  @override
  String get appearanceColourTheme => 'COLOUR THEME';

  @override
  String get appearanceLivePreview => 'LIVE PREVIEW';

  @override
  String get manageAreas => 'Manage Areas';

  @override
  String activeAreas(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active Areas',
      one: '1 active Area',
    );
    return '$_temp0';
  }

  @override
  String get appearancePreviewLabel =>
      'Appearance preview. Example commitment styling.';

  @override
  String get today => 'Today';

  @override
  String get appearancePreviewComplete => '1 / 2 complete';

  @override
  String get appearancePreviewProgress => 'Example progress';

  @override
  String get appearancePreviewRecorded => '23:00 recorded';

  @override
  String keptTaskAnnouncement(String name) {
    return 'Kept $name';
  }

  @override
  String todayEarnedTomorrowLocked(String weekday) {
    return 'You kept your word and $weekday is already committed. Enjoy it.';
  }

  @override
  String get todayEarned => 'You kept your word. Enjoy it.';

  @override
  String get commitments => 'Commitments';

  @override
  String get taskActions => 'Task actions';

  @override
  String get showFewerCommitments => 'Show fewer commitments';

  @override
  String showAllCommitments(int count) {
    return 'Show all $count commitments';
  }

  @override
  String excusedCount(int count) {
    return '$count excused';
  }

  @override
  String keptName(String name) {
    return 'Kept: $name';
  }

  @override
  String get undo => 'Undo';

  @override
  String timedHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String timedMinutesSeconds(int minutes, int seconds) {
    return '${minutes}m ${seconds}s';
  }

  @override
  String timedSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get noEligibleCommitments => 'No eligible commitments';

  @override
  String keptOfEligible(int kept, int total) {
    return '$kept of $total kept';
  }

  @override
  String get excusedDontCount => 'Excused commitments don’t count';

  @override
  String get dayComplete => 'Day complete';

  @override
  String moreUntilSunUp(int count) {
    return '$count more and the sun is up';
  }

  @override
  String timedSuffix(String duration) {
    return '$duration timed';
  }

  @override
  String get commitmentsComplete => 'Commitments complete';

  @override
  String get todayRestrictionsInSettings =>
      'App restrictions are configured in Settings.';

  @override
  String get freedomEarned => 'Freedom earned';

  @override
  String get showFreedomDetails => 'Show Freedom details';

  @override
  String appsUnlockedAt(String time) {
    return 'Apps unlocked at $time';
  }

  @override
  String get freedomEarnedTitle => 'Freedom earned.';

  @override
  String get freedomNotYetEarned => 'Freedom not yet earned';

  @override
  String get freedomOffDetail => 'Earn your apps back by keeping your word.';

  @override
  String get appsStayLockedToday => 'Apps stay locked today';

  @override
  String get emptyDayDetail =>
      'An empty day doesn’t earn Freedom. Commit a plan for tomorrow.';

  @override
  String appsUnlockAt(String time) {
    return 'Apps unlock at $time';
  }

  @override
  String keepMoreToEarn(int count) {
    return 'Keep $count more to earn it';
  }

  @override
  String get commitTomorrowToEarn => 'Commit tomorrow’s plan to earn it';

  @override
  String get waitingForFreedomTime => 'Waiting for Freedom Time';

  @override
  String everythingKeptUnlockAt(String time) {
    return 'Everything’s kept. Apps unlock at $time';
  }

  @override
  String get turnOn => 'Turn on';

  @override
  String get hideFreedomDetails => 'Hide Freedom details';

  @override
  String get aClearDay => 'A clear day.';

  @override
  String allSetFor(String weekday) {
    return 'All set for $weekday.';
  }

  @override
  String get emptyTodayNoPlan =>
      'No commitments for today. Plan tomorrow, and tomorrow’s sun is yours to raise.';

  @override
  String get emptyTodayLocked =>
      'Nothing planned today, and tomorrow is locked in. Rest is the plan.';

  @override
  String weekdayCommitmentCount(String weekday, int count) {
    return '$weekday’s $count';
  }

  @override
  String get view => 'View';

  @override
  String get planTomorrow => 'Plan tomorrow';

  @override
  String get repeatNever => 'Never';

  @override
  String get repeatCustom => 'Custom…';

  @override
  String get repeat => 'Repeat';

  @override
  String get repeatClose => 'Close repeat options';

  @override
  String get repeatDaysOfWeek => 'Days of week';

  @override
  String get repeatEveryNDays => 'Every N days';

  @override
  String get repeatEvery => 'Every';

  @override
  String get repeatFewerDays => 'Fewer days';

  @override
  String get repeatMoreDays => 'More days';

  @override
  String get repeatPickOneDay => 'Pick at least one day.';

  @override
  String get repeatOnlyThisDay => 'Only this day. It won’t repeat.';

  @override
  String repeatNext(String dates) {
    return 'Next: $dates';
  }

  @override
  String get done => 'Done';

  @override
  String get editCommitment => 'Edit commitment';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get removeCommitmentTitle => 'Remove commitment?';

  @override
  String removeFromDraft(String name) {
    return 'Remove $name from tomorrow’s draft?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get remove => 'Remove';

  @override
  String areaFor(String name) {
    return 'Area for $name';
  }

  @override
  String lockInWeekdayQuestion(String weekday) {
    return 'Lock in $weekday?';
  }

  @override
  String lockInConfirmOne(String weekday) {
    return 'This locks your commitment for $weekday. You won’t be able to add or change it.';
  }

  @override
  String lockInConfirmMany(int count, String weekday) {
    return 'This locks your $count commitments for $weekday. You won’t be able to add or change them.';
  }

  @override
  String get keepPlanning => 'Keep planning';

  @override
  String get lockItIn => 'Lock it in';

  @override
  String get plan => 'Plan';

  @override
  String tomorrowDate(String date) {
    return 'Tomorrow · $date';
  }

  @override
  String get committed => 'Committed';

  @override
  String get draft => 'Draft';

  @override
  String get schedule => 'Schedule';

  @override
  String get noScheduledEventsTomorrow => 'No scheduled events for tomorrow.';

  @override
  String scheduledEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count scheduled events',
      one: '1 scheduled event',
    );
    return '$_temp0';
  }

  @override
  String commitmentsCount(int count) {
    return 'Commitments · $count';
  }

  @override
  String get add => 'Add';

  @override
  String get addACommitment => 'Add a commitment';

  @override
  String get noCommitmentsPlanned => 'No commitments planned yet.';

  @override
  String get tomorrowIsLocked => 'Tomorrow is locked.';

  @override
  String get addOneSmallStep => 'Add one small step for tomorrow.';

  @override
  String lockInWeekday(String weekday) {
    return 'Lock in $weekday';
  }

  @override
  String addOneToLockIn(String weekday) {
    return 'Add at least one commitment to lock in $weekday.';
  }

  @override
  String get locksThisCommitment =>
      'Locks this commitment. You can’t change it after.';

  @override
  String locksTheseCommitments(int count) {
    return 'Locks these $count. You can’t change them after.';
  }

  @override
  String archivedArea(String name) {
    return '$name (archived)';
  }

  @override
  String actionsFor(String name) {
    return 'Actions for $name';
  }

  @override
  String get removeCommitment => 'Remove commitment';

  @override
  String get tomorrowPlanCommitted => 'Tomorrow\'s plan is committed.';

  @override
  String get yourCommitmentsLocked => 'Your commitments are locked.';

  @override
  String get nextTomorrow => 'next: tomorrow';

  @override
  String nextDate(String date) {
    return 'next: $date';
  }

  @override
  String rotationSummary(int count, String name) {
    return '$count steps · up next: $name';
  }

  @override
  String get deleteRoutineTitle => 'Delete routine?';

  @override
  String deleteRoutineBody(String name) {
    return 'Stop repeating $name? Commitments already in your plans and history stay.';
  }

  @override
  String get delete => 'Delete';

  @override
  String get routines => 'Routines';

  @override
  String get routinesIntro =>
      'Routines add themselves to tomorrow’s plan on the days they’re due. Remove one from a plan to skip just that day. A rotation with several steps moves on only after a step stays in your plan.';

  @override
  String get createRoutineOrRotation => 'Create routine or rotation';

  @override
  String get noRoutinesYet => 'No routines yet.';

  @override
  String get edit => 'Edit';

  @override
  String get newRoutineStep => 'New routine step';

  @override
  String get editRoutineStep => 'Edit routine step';

  @override
  String get addStep => 'Add step';

  @override
  String get saveStep => 'Save step';

  @override
  String get createRoutine => 'Create routine';

  @override
  String get editRoutine => 'Edit routine';

  @override
  String get routineName => 'Routine name';

  @override
  String get routineRotationHelp =>
      'A rotation: each due day adds the next step, in this order. A step you remove comes back next time.';

  @override
  String get routineSingleHelp =>
      'Each due day adds this to tomorrow’s plan automatically. Add more steps to make a rotation.';

  @override
  String editStepN(int number) {
    return 'Edit step $number';
  }

  @override
  String moveStepUp(int number) {
    return 'Move step $number up';
  }

  @override
  String moveStepDown(int number) {
    return 'Move step $number down';
  }

  @override
  String removeStepN(int number) {
    return 'Remove step $number';
  }

  @override
  String get addCommitment => 'Add commitment';

  @override
  String get addRotationStep => 'Add rotation step';

  @override
  String get saveRoutine => 'Save routine';

  @override
  String get newCommitment => 'New commitment';

  @override
  String get partOfRotation => 'Part of a rotation. Change it in Routines.';

  @override
  String get commitmentHint => 'One small, specific step';

  @override
  String get closeEditor => 'Close editor';

  @override
  String get commitmentName => 'Commitment name';

  @override
  String get statusKept => 'Kept';

  @override
  String get statusNotKeptYet => 'Not kept yet';

  @override
  String durationRecorded(String duration) {
    return '$duration recorded';
  }

  @override
  String get excuseReason => 'Excuse reason';

  @override
  String get markCompleted => 'Mark completed';

  @override
  String get excuseTask => 'Excuse task';

  @override
  String get resetToIncomplete => 'Reset to incomplete';

  @override
  String get excuseCommitment => 'Excuse commitment';

  @override
  String get excusePrompt =>
      'What outside circumstance prevented you from completing it?';

  @override
  String get reason => 'Reason';

  @override
  String get enterShortReason => 'Enter a short reason.';

  @override
  String get shortenReason => 'Please shorten this reason.';

  @override
  String durationMinutesSeconds(int minutes, int seconds) {
    return '$minutes min $seconds s';
  }

  @override
  String get loadFailed => 'Could not load your saved commitments.';

  @override
  String get loadingDay => 'Getting your day ready.';

  @override
  String get retry => 'Retry';

  @override
  String get loadingCommitments => 'Loading commitments';

  @override
  String get journey => 'Journey';

  @override
  String dayStreakLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count day streak',
      one: '1 day streak',
    );
    return '$_temp0';
  }

  @override
  String dayStreakWord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'day streak',
      one: 'day streak',
    );
    return '$_temp0';
  }

  @override
  String get streakStartHint => 'Keep all of today to start one';

  @override
  String get streakLongestYet => 'Your longest yet';

  @override
  String streakLongest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Longest: $count days',
      one: 'Longest: 1 day',
    );
    return '$_temp0';
  }

  @override
  String get totalKept => 'kept';

  @override
  String get totalFocused => 'focused';

  @override
  String shortMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String shortHours(int hours) {
    return '${hours}h';
  }

  @override
  String get achievements => 'Achievements';

  @override
  String seeAll(int count) {
    return 'See all $count';
  }

  @override
  String get addAchievement => 'Add achievement';

  @override
  String get last5Weeks => 'Last 5 weeks';

  @override
  String get dailyHistory => 'Daily history';

  @override
  String get yourAreas => 'Your Areas';

  @override
  String get manage => 'Manage';

  @override
  String get pastChapters => 'Past Chapters';

  @override
  String get areasArchived => 'Areas you’ve archived';

  @override
  String achievementSemantics(String title, String date) {
    return 'Achievement: $title, $date';
  }

  @override
  String get areaUnavailable => 'Area unavailable';

  @override
  String get keepAMoment => 'Keep a moment that matters.';

  @override
  String get addAnAchievement => 'Add an achievement';

  @override
  String get achievementExamples =>
      'A driving licence, a first 10k, a finished chapter.';

  @override
  String last5WeeksKept(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Last 5 weeks: $count days fully kept',
      one: 'Last 5 weeks: 1 day fully kept',
    );
    return '$_temp0';
  }

  @override
  String get legendAllKept => 'All kept';

  @override
  String get legendSomeKept => 'Some kept';

  @override
  String get legendMissed => 'Missed';

  @override
  String keptThisWeek(int count) {
    return '$count this week';
  }

  @override
  String areaKeptThisWeek(String area, int count) {
    return '$area: $count kept this week';
  }

  @override
  String get last30Days => 'Last 30 days';

  @override
  String get allTime => 'All time';

  @override
  String completedCommitments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count completed commitments',
      one: '1 completed commitment',
    );
    return '$_temp0';
  }

  @override
  String recordedTime(String duration) {
    return '$duration recorded time';
  }

  @override
  String get stopwatchExplainer =>
      'Stopwatch time records actual effort, including incomplete commitments.';

  @override
  String get activityOverTime => 'ACTIVITY OVER TIME';

  @override
  String get trackedTime => 'Tracked time';

  @override
  String get achievementsPlace =>
      'A place for the moments you want to remember.';

  @override
  String get recordedCommitments => 'Recorded commitments';

  @override
  String recordsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records',
      one: '1 record',
    );
    return '$_temp0';
  }

  @override
  String get recordsEmpty => 'Your recorded commitments will appear here.';

  @override
  String get recordedTimeEmpty => 'Recorded time will appear here.';

  @override
  String get completedEmpty => 'Completed commitments will appear here.';

  @override
  String get activityDetails => 'Activity details';

  @override
  String activityRange(String from, String through, String value) {
    return '$from to $through: $value';
  }

  @override
  String activityDescriptionTime(String days) {
    return 'Last 30 days, recorded time. $days';
  }

  @override
  String activityDescriptionCompleted(String days) {
    return 'Last 30 days, completed commitments. $days';
  }

  @override
  String get thirtyDaysTime => '30 days · time';

  @override
  String get thirtyDaysCompleted => '30 days · completed';

  @override
  String completedCount(int count) {
    return '$count completed';
  }

  @override
  String get openSpace => 'Open space';

  @override
  String get openArea => 'Open Area';

  @override
  String get latestAchievement => 'Latest achievement';

  @override
  String get pastChaptersIntro => 'Parts of your life, kept here to revisit.';

  @override
  String get pastChaptersEmpty =>
      'Archived Areas will stay here, along with their history.';

  @override
  String get savePendingBeforeStopwatch =>
      'Save your pending changes before changing a stopwatch.';

  @override
  String get couldNotSaveAppearance => 'Could not save appearance settings.';

  @override
  String get couldNotSaveSetup =>
      'Could not save setup. Please retry from Settings.';

  @override
  String get tomorrowAlreadyCommitted =>
      'Tomorrow’s plan is already committed. Existing commitments are kept. Add another after the next day starts.';

  @override
  String get firstCommitmentHeading => 'Your first commitment · tomorrow';

  @override
  String pausedTask(String name) {
    return 'Paused $name.';
  }

  @override
  String removedForWeekday(String weekday) {
    return 'Removed for $weekday.';
  }

  @override
  String get stopRepeating => 'Stop repeating';

  @override
  String get stoppedRepeating => 'Stopped repeating.';

  @override
  String get achievementsIntro =>
      'Things you’re proud of: a driving licence, a first 10k, a finished chapter.';

  @override
  String get achievement => 'Achievement';

  @override
  String get achievementRemoved => 'This achievement has been removed.';

  @override
  String get deleteAchievementTitle => 'Delete achievement?';

  @override
  String deleteAchievementBody(String title) {
    return 'Remove “$title”? Your commitments and Areas will stay as they are.';
  }

  @override
  String get keepAchievement => 'Keep achievement';

  @override
  String get couldNotSaveChanges => 'Could not save your changes.';

  @override
  String get tourDayTitle => 'This is your day';

  @override
  String get tourDayBody =>
      'The sun climbs as you keep today’s commitments. Keep them all and it’s fully risen.';

  @override
  String get tourCommitmentsTitle => 'Today’s commitments';

  @override
  String get tourCommitmentsBody =>
      'Tap the circle to keep one. Tap the row to run a stopwatch, or excuse it with a reason if something really came up.';

  @override
  String get tourFreedomTitle => 'Freedom';

  @override
  String get tourFreedomBody =>
      'Apps you restrict open at Freedom Time, once today is kept and tomorrow is locked in. Tap here any time to see what’s left.';

  @override
  String get tourPlanTitle => 'Plan tomorrow';

  @override
  String get tourPlanBody =>
      'Each evening, plan tomorrow while today is still fresh. Pick a few things you’ll really do.';

  @override
  String get tourAddTitle => 'Add and repeat';

  @override
  String get tourAddBody =>
      'Add a commitment and give it an Area. Turn on Repeat for habits, and they fill themselves in on their days.';

  @override
  String get tourLockTitle => 'Lock it in';

  @override
  String get tourLockBody =>
      'When tomorrow looks right, lock it in. After that it can’t change. That’s what makes it a commitment.';

  @override
  String get tourJourneyTitle => 'Your Journey';

  @override
  String get tourJourneyBody =>
      'Every kept day counts here: your streak, the effort you put in, and the achievements you’re proud of.';

  @override
  String get tourAreasTitle => 'Areas';

  @override
  String get tourAreasBody =>
      'Each Area tracks one part of your life, like Body, Mind or Career. Add, rename or archive them here. Further down, open one to see its history.';

  @override
  String get tourSettingsTitle => 'Settings';

  @override
  String get tourSettingsBody =>
      'Freedom Time, app blocking, routines, reminders and colours live here. You can replay this tour from Settings too.';

  @override
  String stepOf(int current, int total) {
    return '$current of $total';
  }

  @override
  String get skipTour => 'Skip tour';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String tourStepSemantics(int current, int total) {
    return 'App tour, step $current of $total';
  }

  @override
  String get setupTourBody =>
      'We’ll walk through the real Today, Plan and Journey screens and point out what each part does. It takes about a minute, and you can skip it any time.';

  @override
  String get setupTestBody =>
      'Open a selected app and look for Daylock’s lock screen. Return here to see the result. Also open it normally from Home after leaving Daylock in the background: this test confirms only one opening. This uses your real Freedom conditions and never completes a goal for you.';

  @override
  String get setupFirstCommitmentBody =>
      'Today’s plan is already locked. Your first new commitment goes into tomorrow’s real plan. Apps unlock when all eligible commitments are complete, Freedom Time is reached, and tomorrow’s plan is committed. An empty day does not earn Freedom.';

  @override
  String get setupAccessibilityOemHelp =>
      'On Xiaomi / HyperOS, Samsung and Pixel, settings names vary. Choose this installed Daylock app’s service. If “Restricted settings” appears, review App info → Allow restricted settings only for a build you trust. If the service is enabled but disconnected, toggle it off and on once.';

  @override
  String get setupAccessibilityExplain =>
      'Daylock detects when a selected app opens and can show its lock screen or return Home. Screen contents are never read. Access is optional and can be revoked in Android Settings.';

  @override
  String get setupBlockingOptional =>
      'App blocking is optional. Without it, Daylock still plans your days and tracks your commitments. You can turn it on later in Settings.';

  @override
  String get setupXiaomiBody =>
      'HyperOS can pause Daylock in the background even while Accessibility shows enabled. A test inside Daylock may work while opening Instagram from Home does not.\n\nIn this app’s App info:\n• Autostart: on\n• Battery saver (or Power): No restrictions\n• Other permissions → Display pop-up windows while running in the background: allow\n\nSwiping Daylock away in Recents or using “Clean” can still stop blocking. If that happens, Today shows a warning: turn Daylock off and on in Accessibility.\n\nUse the settings for this installed Daylock app; Daylock Dev and the Play version have separate settings. Daylock cannot read these Xiaomi choices. Confirm them yourself below, then test normal app openings too.';

  @override
  String get setupLockNotConfirmed =>
      'Lock screen not confirmed. Check Accessibility is connected, then retry. Android may return Home or restrict the lock-screen launch. Open Permissions & Diagnostics in Settings for the recorded result.';

  @override
  String get setupVerified =>
      'Verified: Android displayed the Daylock lock screen.';

  @override
  String get setupSaveProgressFailed =>
      'Could not save setup progress. Please retry.';

  @override
  String get setupOpeningApp =>
      'Opening your selected app. Return to Daylock after checking the lock screen.';

  @override
  String get setupSaveConfirmationFailed =>
      'Could not save your confirmation. Please retry.';

  @override
  String get setupWelcomeBody =>
      'Plan your day. Earn your freedom. Keep your commitments before your distracting apps unlock.';

  @override
  String get setupWelcomePlan =>
      'Choose a few meaningful commitments the evening before.';

  @override
  String get setupBlockDistractions => 'Block distractions';

  @override
  String get setupWelcomeBlock => 'You choose which apps to restrict.';

  @override
  String get setupKeepYourWord => 'Keep your word';

  @override
  String get setupWelcomeKeep =>
      'Keep today’s commitments, then lock in tomorrow’s plan.';

  @override
  String get setupUnlockApps => 'Unlock apps';

  @override
  String get setupWelcomeUnlock =>
      'Reach your Freedom Time and enjoy your earned break.';

  @override
  String get setupXiaomiTitle => 'Xiaomi / Poco: keep blocking active';

  @override
  String get setupOpenAppInfo => 'Open Daylock App info';

  @override
  String get setupXiaomiConfirm =>
      'I changed these settings for this Daylock app';

  @override
  String get setupXiaomiConfirmNote =>
      'Your confirmation; not automatically verified.';

  @override
  String get setupAccessibilityTitle => 'Accessibility access · optional';

  @override
  String get setupBlockingAndroidOnly =>
      'Blocking is available on Android. You can still use the planner here.';

  @override
  String get setupAccessibilityConnected =>
      'Enabled and connected. Daylock is ready to detect selected apps.';

  @override
  String get setupAccessibilityWaiting =>
      'Enabled. Waiting for Android to connect the service. Tap Refresh after returning.';

  @override
  String get setupEnableAccessibility => 'Enable Accessibility';

  @override
  String get setupNotificationsTitle => 'Notifications · optional';

  @override
  String get setupNotificationsAllowed =>
      'Allowed. Local reminders and fallback restriction notices can appear.';

  @override
  String get setupNotificationsExplain =>
      'Allow local reminders and a notice when Android cannot display the lock screen. You can continue without notifications.';

  @override
  String get setupAllowNotifications => 'Allow notifications';

  @override
  String get setupRefreshPermissions => 'Refresh permission status';

  @override
  String get setupChooseAppsBody =>
      'Choose apps you want to open more intentionally. Your selections stay on this device.';

  @override
  String get setupRestrictionsEnableFreedom =>
      'Turning on app restrictions here also enables Freedom Control at your saved Freedom Time.';

  @override
  String get setupSaveBlockingFailed =>
      'Could not save blocking settings. Please retry.';

  @override
  String get setupAppSelectionAndroidOnly =>
      'Installed-app selection is available on Android.';

  @override
  String get setupOneSmallStep => 'One small step for tomorrow';

  @override
  String get setupSaveCommitmentFailed =>
      'Could not save your commitment. Please retry.';

  @override
  String get setupCreateCommitment => 'Create a commitment';

  @override
  String get setupAlreadyHasCommitment =>
      'Your plan already contains a commitment. You can continue without creating another.';

  @override
  String get setupTestTitle => 'Try your real app restriction';

  @override
  String get setupTestAndroidOnly => 'Blocking tests require the Android app.';

  @override
  String get setupChecking => 'Checking…';

  @override
  String get setupTestSelectedApp => 'Test a selected app';

  @override
  String get setupEnableFreedomAndRestrictions =>
      'Enable Freedom Control and app restrictions';

  @override
  String setupTestNeedsFreedom(String state) {
    return 'Current Freedom: $state. The real test needs Freedom Control on and Freedom not yet earned. You can leave setup and return from Settings when those conditions apply.';
  }

  @override
  String get setupAccessibilityNotConnected =>
      'Accessibility is not connected. Go back to permission setup.';

  @override
  String get setupConfirmXiaomi =>
      'Go back to Set Up App Blocking and confirm the Xiaomi battery setting so blocking keeps working.';

  @override
  String get setupRefreshRetry => 'Refresh and retry';

  @override
  String get setupReadyTitle => 'Make room for what matters';

  @override
  String get setupReadyBody =>
      'Your preferences and commitment are saved. Start with Today, plan tomorrow, and watch your Journey grow.';

  @override
  String get setupTourTitle => 'Take a quick tour';

  @override
  String get setupBlockingOff => 'App blocking is off';

  @override
  String get setupBlockingOffBody =>
      'Daylock won’t restrict any apps. If you want it later, open Settings and turn on app restrictions.';

  @override
  String get setupSkipTour => 'Skip the tour';

  @override
  String get previousStep => 'Previous step';

  @override
  String get saveAndLeave => 'Save & leave';

  @override
  String stepNOfM(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get getStarted => 'Get Started';

  @override
  String get continueWithoutBlocking => 'Continue without blocking';

  @override
  String get skipTestForNow => 'Skip test for now';

  @override
  String get finishSetup => 'Finish Setup';

  @override
  String get takeTheTour => 'Take the tour';

  @override
  String get goToDaylock => 'Go to Daylock';

  @override
  String get continueLabel => 'Continue';

  @override
  String get setupTitleWelcome => 'Take Back Control';

  @override
  String get setupTitleBlocking => 'Set Up App Blocking';

  @override
  String get setupTitleApps => 'Choose Your Distractions';

  @override
  String get setupTitleCommitment => 'Set Your First Commitment';

  @override
  String get setupTitleTest => 'You\'re Almost Ready!';

  @override
  String get setupTitleReady => 'You\'re All Set!';

  @override
  String get diagLockUnconfirmed =>
      'Lock screen: not confirmed; a fallback notification may be used.';

  @override
  String get diagLockFailedException =>
      'Lock screen: Android rejected or failed the launch request.';

  @override
  String get diagLockShown => 'Lock screen: visible and confirmed.';

  @override
  String get diagLockRequestedUnconfirmed =>
      'Lock screen: request returned; visibility is not confirmed yet.';

  @override
  String get diagLockAttempted => 'Lock screen: launch requested.';

  @override
  String get diagHomeRejected => 'Home action: Android rejected the request.';

  @override
  String get diagHomeAccepted => 'Home action: Android accepted the request.';

  @override
  String get diagHomeAttempted => 'Home action: requested.';

  @override
  String get diagRestrictionOther =>
      'Last restriction state could not be verified.';

  @override
  String get diagRestrictionSkippedLaunchThrottled =>
      'Restriction skipped: a lock-screen attempt is already in progress.';

  @override
  String get diagRestrictionSkippedFreedomDisabled =>
      'Restriction skipped: Freedom Control is off.';

  @override
  String get diagRestrictionSkippedFreedomEarned =>
      'Restriction skipped: Freedom is earned.';

  @override
  String get diagRestrictionSkippedStateChanged =>
      'Restriction skipped: Freedom state changed while opening the app.';

  @override
  String get diagRestrictionRetryingStateChanged =>
      'Freedom state changed during enforcement; checking it once more.';

  @override
  String get diagRestrictionSkippedLockAlreadyVisible =>
      'Restriction skipped: a Daylock lock screen was already visible.';

  @override
  String get diagRestrictionSkippedServiceInactive =>
      'Restriction skipped: the Accessibility service was no longer active.';

  @override
  String get diagRestrictionSkippedDeviceNotInteractive =>
      'Restriction skipped: the device was locked or not interactive.';

  @override
  String get diagRestrictionSkippedSelectionUnavailable =>
      'Restriction skipped: the selected app could not be verified.';

  @override
  String get diagRestrictionSkippedAccessibilityDisabled =>
      'Restriction skipped: Accessibility is no longer enabled.';

  @override
  String get diagRestrictionSkippedForegroundChangedBeforeNavigation =>
      'Restriction skipped: the foreground app changed before enforcement.';

  @override
  String get diagRestrictionHomeFailed =>
      'Last attempt: Android rejected Home navigation. Restriction could not be applied.';

  @override
  String get diagRestrictionLockLaunchUnconfirmed =>
      'Last attempt: lock screen was not confirmed. Android may restrict background launches.';

  @override
  String get diagRestrictionHomeOnly =>
      'Last attempt: Home requested; lock screen was not confirmed.';

  @override
  String get diagRestrictionLockFallbackUnavailable =>
      'Last attempt: lock screen not confirmed. Allow notifications and the App restriction notices channel in Android settings for fallback notices.';

  @override
  String get diagRestrictionLockFallbackPosted =>
      'Last attempt: lock screen not confirmed; app restriction notification posted. Android controls its delivery.';

  @override
  String get diagRestrictionLockLaunchRequested =>
      'Last attempt: lock screen requested; display not yet confirmed.';

  @override
  String get diagRestrictionStateUnknown =>
      'Last attempt: selected apps allowed while Freedom state was unavailable.';

  @override
  String get diagRestrictionLockShown =>
      'Last restriction attempt: Daylock lock screen shown.';

  @override
  String get diagRestrictionRecoveryShown =>
      'Last attempt: recovery screen shown. Open Daylock to refresh plans or disable blocking.';

  @override
  String get diagRestrictionRestrictionRecovery =>
      'Restriction needs Daylock to refresh Freedom state.';

  @override
  String get diagRestrictionRestrictionTriggered =>
      'Restriction triggered: starting the Daylock lock flow.';

  @override
  String get diagRestrictionEligibilityUnknown =>
      'Eligibility could not be confirmed; blocking is paused safely.';

  @override
  String get diagRestrictionEligibilityDisabled =>
      'Eligibility evaluated: Freedom Control is off; the app is allowed.';

  @override
  String get diagRestrictionEligibilityEarned =>
      'Eligibility evaluated: Freedom is earned; the app is allowed.';

  @override
  String get diagRestrictionEligibilityNotEarned =>
      'Eligibility evaluated: Freedom is not earned.';

  @override
  String get diagRestrictionDetectedSelectedApp =>
      'Selected app detected. Checking Freedom and restriction eligibility.';

  @override
  String get diagRestrictionTestRequested =>
      'Test requested: waiting for a fresh selected-app detection.';

  @override
  String get diagRestrictionSkippedEventDelayed =>
      'Android delivered the app-opening event too late. On Xiaomi / HyperOS, review Daylock’s App info → Power → No restrictions, then test opening a selected app from Home.';

  @override
  String get diagRestrictionNone => 'No restriction attempt yet.';

  @override
  String get diagEnableBlockingBody =>
      'When Freedom Control is on and Freedom is not earned, Daylock uses Accessibility to leave a selected app and show its own lock screen. Installed-app lists and selections stay on this device. It does not read screen content or collect browsing history. Only the latest selected-app detection and restriction result stay on this device. Other window package names are compared only to cancel a pending action if you switch apps; they are not retained. You can turn blocking off here or revoke Accessibility access at any time.\n\nFreedom inputs stay valid for their calendar date without reopening Daylock. If current state is missing or invalid, Daylock offers a recovery screen with Open Daylock and Disable Blocking; subsequent openings are allowed while recovery is needed. This is a voluntary restriction, not a tamper-proof or parental-control system.';

  @override
  String get diagPermissionBody =>
      'Daylock uses Android Accessibility to detect when a selected app opens, including while Daylock is in the background. It saves only the latest selected-app detection, Freedom status and restriction result on this device; nothing is sent to a server. Installed-app lists and selections stay on this device. It does not read screen content or collect browsing history. With the separate app restrictions switch enabled, it can return Home and show a branded Daylock lock screen when Freedom is not earned. Window package changes are compared only to cancel actions if you switch apps; other app names are not retained. It does not draw overlays or restrict unselected apps.\n\nYou choose whether to enable “Daylock app restrictions” in Android Accessibility Settings. You can disable it there at any time.';

  @override
  String get diagPermissionTitle => 'App restriction permission';

  @override
  String get diagAgreeOpenSettings => 'Agree and open Settings';

  @override
  String get diagEnableBlockingTitle => 'Enable app restrictions?';

  @override
  String get diagEnableBlocking => 'Enable blocking';

  @override
  String get diagAppRestrictionsLabel => 'APP RESTRICTIONS';

  @override
  String get diagAppRestrictionsIntro =>
      'Accessibility detects selected apps opening in the background. Optional blocking shows a Daylock lock screen or returns Home until Freedom is earned. If the screen cannot appear, a notification explains the block when Android permits it.';

  @override
  String get diagAppRestrictions => 'App restrictions';

  @override
  String get diagSeparateFromFreedom =>
      'Separate from Freedom Control. Off by default.';

  @override
  String get diagStatusUnavailable => 'App restriction status unavailable';

  @override
  String get diagRestrictionsOff => 'App restrictions: off';

  @override
  String get diagWaitingForAccessibility =>
      'App restrictions: waiting for Accessibility access';

  @override
  String get diagAllowedFreedomOff =>
      'Selected apps allowed — Freedom Control is off';

  @override
  String get diagAllowedFreedomEarned =>
      'Selected apps allowed — Freedom earned';

  @override
  String get diagBlockingPaused =>
      'Blocking paused — open Daylock to refresh Freedom state';

  @override
  String get diagRestrictionsReady =>
      'App restrictions ready — launch and navigation depend on Android';

  @override
  String get diagServiceStatusUnavailable => 'Service status unavailable';

  @override
  String get diagAndroidOnly =>
      'Native detection is available on Android only.';

  @override
  String get diagServiceDisabled => 'Accessibility service: disabled';

  @override
  String get diagServiceConnected =>
      'Accessibility service: enabled and connected';

  @override
  String get diagServiceWaiting =>
      'Accessibility service: enabled — waiting for Android to connect';

  @override
  String get diagBlockingSaveFailed =>
      'The blocking choice could not be saved. Disabling takes effect now, but may not survive a restart. Revoke Accessibility access if necessary.';

  @override
  String get diagNoDetectionYet => 'No selected app has been detected yet.';

  @override
  String diagLastDetection(String when) {
    return 'Last restricted-app detection: $when';
  }

  @override
  String diagFreedomAtDetection(String state) {
    return 'Freedom at that detection: $state';
  }

  @override
  String diagCurrentFreedom(String state) {
    return 'Current native Freedom state: $state';
  }

  @override
  String get diagFocusNeedsRefresh =>
      'An active Focus session needs Daylock to reconcile its timer. Native detection does not mark it complete.';

  @override
  String get diagStateUnavailable =>
      'Current dated state is unavailable. Open Daylock to reconcile plans or turn blocking off. Valid current-day inputs do not expire after five minutes.';

  @override
  String get diagRolloverReconciled =>
      'New day: using the saved plan for this date. Open Daylock to archive history and prepare the following day.';

  @override
  String get diagNoEligible =>
      'No eligible commitments. Empty or all-excused days do not earn Freedom.';

  @override
  String get diagDetectionSaveFailed =>
      'The latest detection could not be persisted and may not survive a restart.';

  @override
  String get diagTurnBlockingOff => 'Turn blocking off';

  @override
  String get diagSettingsPath =>
      'Android Settings → Accessibility → Downloaded/Installed apps → Daylock app restrictions. Turn the service on manually. Names vary by phone.';

  @override
  String get diagRestrictedSettings =>
      'If Android 15 shows “Restricted settings”, inspect Daylock’s App info for “Allow restricted settings” and confirm only for this development build you trust.';

  @override
  String get diagAvailableAndroidOnly => 'Available on Android only';

  @override
  String get diagServiceEnabledShort => 'Accessibility service: enabled';

  @override
  String get diagServiceDisconnected => 'Service disconnected';

  @override
  String get diagRestrictionsOn => 'App restrictions: on';

  @override
  String selectedAppsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected apps',
      one: '1 selected app',
    );
    return '$_temp0';
  }

  @override
  String diagNativeFreedom(String state) {
    return 'Native Freedom: $state';
  }

  @override
  String get diagTechnicalDetails => 'Technical details & setup';

  @override
  String diagLastPackage(String package) {
    return 'Last restricted package: $package';
  }

  @override
  String get openAccessibilitySettings => 'Open Accessibility Settings';

  @override
  String get refreshStatus => 'Refresh status';

  @override
  String get appsLoadFailed =>
      'Could not load installed apps. Your saved selections have not been replaced.';

  @override
  String get appsPausedAttention =>
      'Restrictions paused: status needs attention.';

  @override
  String get appsRestrictionsOff =>
      'App restrictions are off. Your selections are saved.';

  @override
  String get appsNoneSelected => 'No apps selected. Nothing is restricted.';

  @override
  String get appsWaitingAccessibility =>
      'Waiting for Accessibility access. Selected apps are not restricted.';

  @override
  String get appsFreedomOff =>
      'Freedom Control is off. Selected apps are accessible.';

  @override
  String get appsFreedomEarned =>
      'Freedom earned. Selected apps are accessible.';

  @override
  String get appsNeedsRefresh =>
      'Freedom status needs a refresh. Recovery is available; repeated openings are allowed.';

  @override
  String get appsRestricted =>
      'Selected apps are restricted until Freedom is earned.';

  @override
  String selectedCountLabel(int count) {
    return '$count SELECTED';
  }

  @override
  String get refreshApps => 'Refresh apps';

  @override
  String get appsMasterControl => 'Master control for all selected apps.';

  @override
  String get appsMasterSaveFailed =>
      'The master setting could not be saved. Turning it off applies now, but may not survive a restart.';

  @override
  String get appsChooseBelow =>
      'Choose apps below. Freedom Control and app restrictions are separate. System recovery apps are excluded.';

  @override
  String appsRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count unavailable or reinstalled apps removed from selection. Select them again if needed.',
      one: '1 unavailable or reinstalled app removed from selection. Select it again if needed.',
    );
    return '$_temp0';
  }

  @override
  String get appsNoneSelectedYet =>
      'No apps selected yet. Choose the apps you want to restrict.';

  @override
  String get searchApps => 'Search apps';

  @override
  String get appsSelectionRequiresAndroid =>
      'Installed-app selection requires Android.';

  @override
  String get retryAppDiscovery => 'Retry app discovery';

  @override
  String get appsNoneFound =>
      'No supported launchable apps were found in this Android profile.';

  @override
  String get appsNoMatches => 'No matching apps.';

  @override
  String get appIconUnavailable => 'App icon unavailable';

  @override
  String get savingSelection => 'Saving selection…';

  @override
  String get appsSelectionsStay =>
      'Selections stay on this device. New or reinstalled apps must be selected explicitly.';

  @override
  String get notifRunningStopwatchHelp =>
      'Shows a quiet notification with Pause while a stopwatch runs, and nudges you every 2 hours so it isn’t left on by mistake.';

  @override
  String get notifBlockedInSystem => 'Blocked in Android system settings';

  @override
  String get notifLabel => 'NOTIFICATIONS';

  @override
  String get notifPermissionAllowed => 'System permission: allowed';

  @override
  String get notifPermissionDenied => 'System permission: not allowed';

  @override
  String get notifNeedsAttention => 'Notification setup needs attention';

  @override
  String get notifChecking => 'Checking system permission…';

  @override
  String get notifUnavailable => 'Scheduled notifications unavailable';

  @override
  String get notifPermissionHelp => 'Permission help';

  @override
  String get notifOpenSettings => 'Open notification settings';

  @override
  String get notifPlanTomorrow => 'Plan Tomorrow';

  @override
  String get notifCommitmentReminder => 'Commitment Reminder';

  @override
  String get notifFreedom => 'Freedom Notifications';

  @override
  String get notifFreedomHelp =>
      'Uses Freedom Time when Freedom Control is enabled.';

  @override
  String get notifRunningStopwatch => 'Running Stopwatch';

  @override
  String get healthXiaomiTip =>
      'To stop it happening again on Xiaomi / Poco: in Daylock’s App info allow Autostart, set Battery saver to No restrictions, allow pop-ups while running in the background, and avoid swiping Daylock away in Recents.';

  @override
  String get healthOffBody =>
      'Accessibility access for Daylock is off, so your selected apps open freely. Turn it on to bring the lock back.';

  @override
  String get healthStoppedBody =>
      'Android stopped Daylock in the background, so your selected apps open freely. In Accessibility, turn Daylock off and on again.';

  @override
  String get healthStoppedTitle => 'App blocking has stopped';

  @override
  String get openAccessibility => 'Open Accessibility';

  @override
  String get openAppInfo => 'Open App info';

  @override
  String get conditionSatisfied => 'Satisfied';

  @override
  String get conditionRemaining => 'Remaining';

  @override
  String freedomTimeAt(String time) {
    return 'Freedom Time · $time';
  }

  @override
  String eligibleComplete(int kept, int total) {
    return '$kept / $total eligible commitments complete';
  }

  @override
  String get noEligibleRequired =>
      'No eligible commitments — completion is required to earn Freedom.';

  @override
  String get tomorrowPlanCommittedCondition => 'Tomorrow’s plan committed';

  @override
  String get planDateMismatch =>
      'Today’s plan does not match the current local date.';

  @override
  String availableAt(String time) {
    return 'Available at $time';
  }

  @override
  String get enableFreedomInSettings => 'Enable Freedom Control in Settings.';

  @override
  String get pauseStopwatch => 'Pause stopwatch';

  @override
  String get resumeStopwatch => 'Resume stopwatch';

  @override
  String get startStopwatch => 'Start stopwatch';

  @override
  String get keptLower => 'kept';

  @override
  String keepTask(String name) {
    return 'Keep $name';
  }

  @override
  String get recordedTimeLabel => 'Recorded time';

  @override
  String calendarDayExcusedNeutral(int count) {
    return 'No eligible commitments, $count excused, neutral';
  }

  @override
  String get calendarDayNeutral => 'No commitments, neutral';

  @override
  String get calendarDayUnrecorded => 'No recorded commitments, neutral';

  @override
  String calendarDayProgress(int kept, int total, int percent, int excused) {
    return '$kept of $total eligible commitments complete, $percent percent, $excused excused';
  }

  @override
  String get calendarTodaySuffix => ', Today';

  @override
  String calendarDayValue(String description, int count) {
    return '$description, $count scheduled events';
  }

  @override
  String get heatNeutral =>
      'Neutral: no eligible commitments, missing history or future date';

  @override
  String get heatZero => 'Recorded commitments: 0 percent complete';

  @override
  String get heatLow => 'More than 0 to 25 percent complete';

  @override
  String get heatMedium => 'More than 25 to 50 percent complete';

  @override
  String get heatHigh => 'More than 50 to less than 100 percent complete';

  @override
  String get heatComplete => '100 percent complete';

  @override
  String get heatLess => 'Less';

  @override
  String get heatMore => 'More';

  @override
  String get calTodayReadOnly =>
      'Today commitments, read-only. Manage commitments in Today.';

  @override
  String get calHistoryReadOnly => 'Commitment history, read-only';

  @override
  String get calTodayLabel => 'TODAY’S COMMITMENTS';

  @override
  String get calHistoryLabel => 'COMMITMENT HISTORY';

  @override
  String get calNoHistory => 'No commitment history recorded.';

  @override
  String get calNoCommitmentsToday => 'No commitments for today.';

  @override
  String get calNeutralDay => 'No commitments recorded. Neutral day.';

  @override
  String get calCompletionLabel => 'Commitment completion for selected date';

  @override
  String calRecordedTime(String duration) {
    return 'Recorded time: $duration';
  }

  @override
  String calCommitmentOutcome(String outcome) {
    return 'Commitment · $outcome';
  }

  @override
  String calReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get calReadOnlyCached => 'Read-only cached event';

  @override
  String editNamed(String name) {
    return 'Edit $name';
  }

  @override
  String deleteNamed(String name) {
    return 'Delete $name';
  }

  @override
  String get deleteEventTitle => 'Delete event?';

  @override
  String deleteEventBody(String title) {
    return 'Delete “$title” from your schedule?';
  }

  @override
  String get calReadOnlyCachedShort => 'Read-only · cached event';

  @override
  String get close => 'Close';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get calendar => 'Calendar';

  @override
  String get calendarAccounts => 'Calendar accounts';

  @override
  String get addEvent => 'Add event';

  @override
  String get scheduleLabel => 'SCHEDULE';

  @override
  String get noEventsScheduled => 'No events scheduled.';

  @override
  String get eventTimeFormat => 'Use HH:mm (00:00–23:59).';

  @override
  String get eventEndAfterStart => 'End must be after start.';

  @override
  String get readOnlyEvent => 'Read-only event';

  @override
  String get externalEventsReadOnly =>
      'External events can only be changed in their calendar.';

  @override
  String get editEvent => 'Edit event';

  @override
  String get title => 'Title';

  @override
  String get enterTitle => 'Enter a title.';

  @override
  String get startTimeOptional => 'Start time (optional)';

  @override
  String get endTimeOptional => 'End time (optional)';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get saveEvent => 'Save event';

  @override
  String get accountUpdateFailed =>
      'Could not update this account. Cached events are still available. Try again or reconnect.';

  @override
  String get disconnectAccountTitle => 'Disconnect account?';

  @override
  String disconnectAccountBody(String name) {
    return 'Remove $name and its cached events from Daylock? Your external calendar will stay unchanged.';
  }

  @override
  String get disconnect => 'Disconnect';

  @override
  String get externalCalendarsReadOnly =>
      'External calendars are read-only. Cached events are available offline.';

  @override
  String get providersDisabled =>
      'Account sign-in is not available for the disabled providers in this version.';

  @override
  String connectProvider(String provider) {
    return 'Connect $provider';
  }

  @override
  String get noConnectedAccounts => 'No connected accounts.';

  @override
  String get syncNow => 'Sync now';

  @override
  String get reconnect => 'Reconnect';

  @override
  String get notSyncedYet => 'Not synced yet';

  @override
  String lastSynced(String when) {
    return 'Last synced $when';
  }

  @override
  String get syncToLoad => 'Sync to load this account’s calendars.';

  @override
  String get chooseMonth => 'Choose month';

  @override
  String get previousYear => 'Previous year';

  @override
  String get year => 'Year';

  @override
  String get enterYear => 'Enter a year from 1 to 9999.';

  @override
  String get nextYear => 'Next year';

  @override
  String get showMonth => 'Show month';

  @override
  String get commitment => 'Commitment';

  @override
  String repeatsLabel(String rule) {
    return 'Repeats $rule';
  }

  @override
  String get areas => 'Areas';

  @override
  String get areasIntro =>
      'Give your commitments a home. Your default Area is used whenever no other Area is selected.';

  @override
  String get createArea => 'Create Area';

  @override
  String get archived => 'Archived';

  @override
  String get defaultAlwaysAvailable => 'Default · Always available';

  @override
  String get restore => 'Restore';

  @override
  String get archive => 'Archive';

  @override
  String get archivingExplainer =>
      'Archiving keeps existing commitments and history linked. New commitments use active Areas only.';

  @override
  String get editArea => 'Edit Area';

  @override
  String get areaName => 'Area name';

  @override
  String get icon => 'Icon';

  @override
  String get colour => 'Colour';

  @override
  String get saveArea => 'Save Area';

  @override
  String get areaIconLife => 'Life';

  @override
  String get areaColourLavender => 'Lavender';

  @override
  String get areaIconHealth => 'Health';

  @override
  String get areaIconWork => 'Work';

  @override
  String get areaIconLearning => 'Learning';

  @override
  String get areaIconHome => 'Home';

  @override
  String get areaIconPeople => 'People';

  @override
  String get areaIconCreative => 'Creative';

  @override
  String get areaIconFitness => 'Fitness';

  @override
  String get areaColourBlue => 'Blue';

  @override
  String get areaColourTeal => 'Teal';

  @override
  String get areaColourGreen => 'Green';

  @override
  String get areaColourAmber => 'Amber';

  @override
  String get areaColourRose => 'Rose';

  @override
  String get newAchievement => 'New achievement';

  @override
  String get editAchievement => 'Edit achievement';

  @override
  String get achievementPrompt => 'What are you proud of?';

  @override
  String get achievementHint => 'Passed my driving test';

  @override
  String get achievementNotes => 'A few words (optional)';

  @override
  String get linkToArea => 'Link to an Area';

  @override
  String get optional => 'Optional';

  @override
  String get previousAreaUnavailable =>
      'The previous Area is unavailable. Choose an Area or remove the link.';

  @override
  String get saveAchievement => 'Save achievement';

  @override
  String illustrationLabel(String name) {
    return 'Illustration: $name';
  }

  @override
  String illustrationAutomaticLabel(String name) {
    return 'Illustration: Automatic · $name';
  }

  @override
  String get illustrationHelp =>
      'Choose a look, or let the title and Area suggest one.';

  @override
  String get automatic => 'Automatic';

  @override
  String get area => 'Area';

  @override
  String get notifExplainAndroid =>
      'Android reminders may be delayed by battery saving or Do Not Disturb. App preferences below are separate from system permission.';

  @override
  String get notifExplainError =>
      'Notifications could not be updated. Reopen Daylock to retry.';

  @override
  String get notifExplainDefault =>
      'Scheduled notifications are available on Android.';

  @override
  String get notifExplainWebSupported =>
      'This browser supports notifications, but scheduled reminders are unavailable here. Safari, closed tabs and installed PWAs cannot deliver these reminders without a push service. Use Daylock on Android for scheduled notifications.';

  @override
  String get notifExplainWebUnsupported =>
      'This browser cannot deliver Daylock notifications. Scheduled reminders are available in the Android app; web/PWA controls are disabled.';

  @override
  String get detectionReadFailed =>
      'Could not read native detection status. Refresh or open Android Settings manually.';

  @override
  String get calFailAuthMicrosoft =>
      'Microsoft calendar access needs renewed permission. Reconnect this account. Your organisation may require administrator approval. Cached events are still available.';

  @override
  String get calFailAuthGoogle =>
      'Google calendar permission has expired or was removed. Reconnect this account. Cached events are still available.';

  @override
  String get calFailConfigMicrosoft =>
      'Microsoft sign-in is not configured correctly. Check the Entra client ID, native redirect URI and supported account types.';

  @override
  String get calFailConfigGoogle =>
      'Google sign-in is not configured correctly. Check the OAuth client ID, Android package and signing certificate.';

  @override
  String get calFailUnavailableMicrosoft =>
      'Microsoft Calendar is unavailable. Check your connection and try again. Work accounts need an accessible Exchange mailbox. Cached events are still available.';

  @override
  String get calFailUnavailableGoogle =>
      'Google Calendar is unavailable. Check your connection and try syncing again. Cached events are still available.';

  @override
  String get calFailResponseMicrosoft =>
      'Microsoft returned an incomplete or unsupported calendar response. Cached events are still available. Try again later.';

  @override
  String get calFailResponseGoogle =>
      'Google returned an incomplete or unsupported calendar response. Cached events are still available. Try again later.';

  @override
  String get calFailAdminConsent =>
      'Your organisation requires administrator approval or restricts this sign-in. Contact your IT administrator. Cached events are still available.';

  @override
  String get calFailAccountMismatch =>
      'Select the same Microsoft account and organisation when reconnecting. Existing accounts and cached events have been kept.';

  @override
  String get channelPlan => 'Plan Tomorrow';

  @override
  String get channelCommitments => 'Commitment reminders';

  @override
  String get channelFreedom => 'Freedom';

  @override
  String get channelFocus => 'Running stopwatch';

  @override
  String get selectionLoadFailed =>
      'Could not load or save restricted apps. Restrictions are paused. Refresh to retry.';

  @override
  String get selectionSaveFailed =>
      'App selection could not be saved. Restrictions are paused. Refresh to retry.';

  @override
  String totalAchievements(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'achievements',
      one: 'achievement',
    );
    return '$_temp0';
  }

  @override
  String get breaksTitle => 'Breaks';

  @override
  String get breaksIntro =>
      'Taken from the lock screen in the last 30 days, with your reasons.';

  @override
  String breakEntryTitle(String app, String when) {
    return '$app · $when';
  }

  @override
  String get diagRestrictionSkippedBreakActive =>
      'Restriction skipped: a 15-minute break is active.';
}

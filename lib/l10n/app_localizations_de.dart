// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Daylock';

  @override
  String get appearanceDark => 'Dunkel';

  @override
  String get appearanceLight => 'Hell';

  @override
  String get appearanceSystem => 'System';

  @override
  String get colourViolet => 'Violett';

  @override
  String get colourOcean => 'Ozean';

  @override
  String get colourForest => 'Wald';

  @override
  String get colourEmber => 'Glut';

  @override
  String get colourRose => 'Rosé';

  @override
  String get colourMono => 'Mono';

  @override
  String get illustrationCelebration => 'Feier';

  @override
  String get illustrationDriving => 'Fahren';

  @override
  String get illustrationAward => 'Auszeichnung';

  @override
  String get illustrationCooking => 'Kochen';

  @override
  String get illustrationTravel => 'Reisen';

  @override
  String get illustrationFitness => 'Fitness';

  @override
  String get illustrationLearning => 'Lernen';

  @override
  String get illustrationHealth => 'Gesundheit';

  @override
  String get illustrationWork => 'Arbeit';

  @override
  String get illustrationHome => 'Zuhause';

  @override
  String get illustrationPeople => 'Menschen';

  @override
  String get illustrationCreativity => 'Kreativität';

  @override
  String get illustrationSunrise => 'Sonnenaufgang';

  @override
  String get outcomeIncomplete => 'Offen';

  @override
  String get outcomeCompleted => 'Erledigt';

  @override
  String get outcomeExcused => 'Entschuldigt';

  @override
  String get sourceLocal => 'Lokal';

  @override
  String get sourceGoogle => 'Google Kalender';

  @override
  String get sourceMicrosoftPersonal => 'Microsoft privat';

  @override
  String get sourceMicrosoftWorkSchool => 'Microsoft Arbeit/Schule';

  @override
  String get freedomStateEarned => 'Verdient';

  @override
  String get freedomStateNotEarned => 'Nicht verdient';

  @override
  String get freedomStateControlOff => 'Kontrolle aus';

  @override
  String get freedomStateUnknown => 'Unbekannt';

  @override
  String get listSeparator => ', ';

  @override
  String get repeatDaily => 'Täglich';

  @override
  String repeatEveryDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Alle $count Tage',
      one: 'Jeden Tag',
    );
    return '$_temp0';
  }

  @override
  String get repeatWeekdays => 'Werktags';

  @override
  String get repeatWeekends => 'Am Wochenende';

  @override
  String get eventContinuesAllDay => 'Ganztägig (Fortsetzung)';

  @override
  String get eventEarlier => 'Früher';

  @override
  String get eventNextDay => 'Folgetag';

  @override
  String eventUntil(String time) {
    return 'Bis $time';
  }

  @override
  String get eventAllDay => 'Ganztägig';

  @override
  String durationMinutes(int minutes) {
    return '$minutes Min.';
  }

  @override
  String get durationUnderMinute => '<1 Min.';

  @override
  String durationHours(int hours) {
    return '$hours Std.';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours Std. $minutes Min.';
  }

  @override
  String get settingsFreedomControl => 'Freiheitskontrolle';

  @override
  String get settingsPlanningRoutines => 'Planung & Routinen';

  @override
  String get settingsAppearance => 'Darstellung';

  @override
  String get settingsNotifications => 'Benachrichtigungen';

  @override
  String get settingsAbout => 'Über Daylock';

  @override
  String get settingsRestrictedApps => 'Eingeschränkte Apps';

  @override
  String get settingsPermissionsDiagnostics => 'Berechtigungen & Diagnose';

  @override
  String get settingsManageRoutines => 'Routinen verwalten';

  @override
  String routineCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Routinen',
      one: '1 Routine',
    );
    return '$_temp0';
  }

  @override
  String get settingsRoutinesIntro =>
      'Plane deine nächsten Schritte mit wiederkehrenden Vorsätzen.';

  @override
  String get settingsNotificationsUnavailable =>
      'Benachrichtigungen sind auf diesem Gerät nicht verfügbar.';

  @override
  String get keepYourWord => 'Halte Wort.';

  @override
  String get settingsAboutCommitments =>
      'Vorsätze, optionale Stoppuhren und Fortschritt in den Bereichen, die dir wichtig sind.';

  @override
  String get settingsRestrictedIntro =>
      'Wähle aus, welche Android-Apps eingeschränkt werden, bis du dir Freiheit verdient hast.';

  @override
  String get settingsRestrictionsAndroidOnly =>
      'App-Einschränkungen sind unter Android verfügbar.';

  @override
  String get settingsDiagnosticsAndroidOnly =>
      'Die Bedienungshilfen-Diagnose ist unter Android verfügbar.';

  @override
  String get freedomTime => 'Freiheitszeit';

  @override
  String get settingsRestrictionNeedsAttention =>
      'Der Status der App-Einschränkungen braucht Aufmerksamkeit';

  @override
  String settingsSelectedSwitchOn(int count) {
    return '$count ausgewählt, an';
  }

  @override
  String settingsSelectedSwitchOff(int count) {
    return '$count ausgewählt, aus';
  }

  @override
  String get accessibility => 'Bedienungshilfen';

  @override
  String get statusUnavailable => 'Status nicht verfügbar';

  @override
  String get availableOnAndroid => 'Unter Android verfügbar';

  @override
  String get serviceConnected => 'Dienst verbunden';

  @override
  String get waitingForConnection => 'Warte auf Verbindung';

  @override
  String get serviceDisabled => 'Dienst deaktiviert';

  @override
  String get settingsChooseInstalledApps =>
      'Installierte Android-Apps auswählen';

  @override
  String get settingsFreedomSubtitle =>
      'Eingeschränkte Apps, Freiheitszeit und Berechtigungen';

  @override
  String get on => 'An';

  @override
  String get off => 'Aus';

  @override
  String get settingsPlanningSubtitle => 'Wiederkehrende Vorsätze und Planung';

  @override
  String get settingsAppearanceSubtitle => 'Design, Farben und Bereiche';

  @override
  String get settingsNotificationsSubtitle => 'Erinnerungen und Hinweise';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsRunSetup => 'Einrichtung erneut starten';

  @override
  String get settingsRunSetupSubtitle =>
      'Berechtigungen, Ablenkungen und dein erster Vorsatz';

  @override
  String get settingsTakeTour => 'App-Tour starten';

  @override
  String get settingsTakeTourSubtitle =>
      'Ein geführter Blick auf Heute, Planen und Weg';

  @override
  String get settingsAboutSubtitle => 'App-Informationen';

  @override
  String get tagline => 'Plane deinen Tag. Verdiene dir deine Freiheit.';

  @override
  String get freedomStatusUnavailable => 'Freiheitsstatus nicht verfügbar';

  @override
  String get freedomControlOff => 'Freiheitskontrolle ist aus';

  @override
  String get appearanceFollowsDevice => 'Folgt der Darstellung deines Geräts.';

  @override
  String appearanceFixed(String mode) {
    return 'Darstellung $mode, unabhängig vom Gerätemodus.';
  }

  @override
  String get appearanceColourTheme => 'Farbschema';

  @override
  String get appearanceLivePreview => 'Live-Vorschau';

  @override
  String get manageAreas => 'Bereiche verwalten';

  @override
  String activeAreas(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aktive Bereiche',
      one: '1 aktiver Bereich',
    );
    return '$_temp0';
  }

  @override
  String get appearancePreviewLabel =>
      'Vorschau der Darstellung. Beispiel für einen Vorsatz.';

  @override
  String get today => 'Heute';

  @override
  String get appearancePreviewComplete => '1 / 2 erledigt';

  @override
  String get appearancePreviewProgress => 'Beispielfortschritt';

  @override
  String get appearancePreviewRecorded => '23:00 erfasst';

  @override
  String keptTaskAnnouncement(String name) {
    return '$name gehalten';
  }

  @override
  String todayEarnedTomorrowLocked(String weekday) {
    return 'Du hast Wort gehalten und $weekday ist schon festgelegt. Genieß es.';
  }

  @override
  String get todayEarned => 'Du hast Wort gehalten. Genieß es.';

  @override
  String get commitments => 'Vorsätze';

  @override
  String get taskActions => 'Aktionen für den Vorsatz';

  @override
  String get showFewerCommitments => 'Weniger Vorsätze anzeigen';

  @override
  String showAllCommitments(int count) {
    return 'Alle $count Vorsätze anzeigen';
  }

  @override
  String excusedCount(int count) {
    return '$count entschuldigt';
  }

  @override
  String keptName(String name) {
    return 'Gehalten: $name';
  }

  @override
  String get undo => 'Rückgängig';

  @override
  String timedHoursMinutes(int hours, int minutes) {
    return '$hours Std. $minutes Min.';
  }

  @override
  String timedMinutesSeconds(int minutes, int seconds) {
    return '$minutes Min. $seconds Sek.';
  }

  @override
  String timedSeconds(int seconds) {
    return '$seconds Sek.';
  }

  @override
  String get noEligibleCommitments => 'Keine zählenden Vorsätze';

  @override
  String keptOfEligible(int kept, int total) {
    return '$kept von $total gehalten';
  }

  @override
  String get excusedDontCount => 'Entschuldigte Vorsätze zählen nicht';

  @override
  String get dayComplete => 'Tag geschafft';

  @override
  String moreUntilSunUp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Noch $count, dann geht die Sonne auf',
      one: 'Noch 1, dann geht die Sonne auf',
    );
    return '$_temp0';
  }

  @override
  String timedSuffix(String duration) {
    return '$duration gestoppt';
  }

  @override
  String get commitmentsComplete => 'Vorsätze erledigt';

  @override
  String get todayRestrictionsInSettings =>
      'App-Einschränkungen werden in den Einstellungen festgelegt.';

  @override
  String get freedomEarned => 'Freiheit verdient';

  @override
  String get showFreedomDetails => 'Freiheitsdetails anzeigen';

  @override
  String appsUnlockedAt(String time) {
    return 'Apps um $time freigegeben';
  }

  @override
  String get freedomEarnedTitle => 'Freiheit verdient.';

  @override
  String get freedomNotYetEarned => 'Freiheit noch nicht verdient';

  @override
  String get freedomOffDetail =>
      'Hol dir deine Apps zurück, indem du Wort hältst.';

  @override
  String get appsStayLockedToday => 'Apps bleiben heute gesperrt';

  @override
  String get emptyDayDetail =>
      'Ein leerer Tag bringt keine Freiheit. Lege einen Plan für morgen fest.';

  @override
  String appsUnlockAt(String time) {
    return 'Apps werden um $time freigegeben';
  }

  @override
  String keepMoreToEarn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Noch $count halten, um sie zu verdienen',
      one: 'Noch 1 halten, um sie zu verdienen',
    );
    return '$_temp0';
  }

  @override
  String get commitTomorrowToEarn =>
      'Lege den Plan für morgen fest, um sie zu verdienen';

  @override
  String get waitingForFreedomTime => 'Warten auf die Freiheitszeit';

  @override
  String everythingKeptUnlockAt(String time) {
    return 'Alles gehalten. Apps werden um $time freigegeben';
  }

  @override
  String get turnOn => 'Einschalten';

  @override
  String get hideFreedomDetails => 'Freiheitsdetails ausblenden';

  @override
  String get aClearDay => 'Ein freier Tag.';

  @override
  String allSetFor(String weekday) {
    return 'Alles bereit für $weekday.';
  }

  @override
  String get emptyTodayNoPlan =>
      'Heute keine Vorsätze. Plane morgen – die Sonne von morgen liegt in deiner Hand.';

  @override
  String get emptyTodayLocked =>
      'Heute nichts geplant, und morgen ist festgelegt. Ausruhen ist der Plan.';

  @override
  String weekdayCommitmentCount(String weekday, int count) {
    return '$weekday: $count';
  }

  @override
  String get view => 'Ansehen';

  @override
  String get planTomorrow => 'Morgen planen';

  @override
  String get repeatNever => 'Nie';

  @override
  String get repeatCustom => 'Benutzerdefiniert…';

  @override
  String get repeat => 'Wiederholen';

  @override
  String get repeatClose => 'Wiederholungsoptionen schließen';

  @override
  String get repeatDaysOfWeek => 'Wochentage';

  @override
  String get repeatEveryNDays => 'Alle N Tage';

  @override
  String get repeatEvery => 'Alle';

  @override
  String get repeatFewerDays => 'Weniger Tage';

  @override
  String get repeatMoreDays => 'Mehr Tage';

  @override
  String get repeatPickOneDay => 'Wähle mindestens einen Tag.';

  @override
  String get repeatOnlyThisDay => 'Nur dieser Tag. Keine Wiederholung.';

  @override
  String repeatNext(String dates) {
    return 'Nächste: $dates';
  }

  @override
  String get done => 'Fertig';

  @override
  String get editCommitment => 'Vorsatz bearbeiten';

  @override
  String get saveChanges => 'Änderungen speichern';

  @override
  String get removeCommitmentTitle => 'Vorsatz entfernen?';

  @override
  String removeFromDraft(String name) {
    return '$name aus dem Entwurf für morgen entfernen?';
  }

  @override
  String get cancel => 'Abbrechen';

  @override
  String get remove => 'Entfernen';

  @override
  String areaFor(String name) {
    return 'Bereich für $name';
  }

  @override
  String lockInWeekdayQuestion(String weekday) {
    return '$weekday festlegen?';
  }

  @override
  String lockInConfirmOne(String weekday) {
    return 'Damit wird dein Vorsatz für $weekday festgelegt. Du kannst danach nichts mehr hinzufügen oder ändern.';
  }

  @override
  String lockInConfirmMany(int count, String weekday) {
    return 'Damit werden deine $count Vorsätze für $weekday festgelegt. Du kannst danach nichts mehr hinzufügen oder ändern.';
  }

  @override
  String get keepPlanning => 'Weiter planen';

  @override
  String get lockItIn => 'Festlegen';

  @override
  String get plan => 'Planen';

  @override
  String tomorrowDate(String date) {
    return 'Morgen · $date';
  }

  @override
  String get committed => 'Festgelegt';

  @override
  String get draft => 'Entwurf';

  @override
  String get schedule => 'Termine';

  @override
  String get noScheduledEventsTomorrow => 'Morgen keine Termine.';

  @override
  String scheduledEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Termine',
      one: '1 Termin',
    );
    return '$_temp0';
  }

  @override
  String commitmentsCount(int count) {
    return 'Vorsätze · $count';
  }

  @override
  String get add => 'Hinzufügen';

  @override
  String get addACommitment => 'Vorsatz hinzufügen';

  @override
  String get noCommitmentsPlanned => 'Noch keine Vorsätze geplant.';

  @override
  String get tomorrowIsLocked => 'Morgen ist festgelegt.';

  @override
  String get addOneSmallStep => 'Füge einen kleinen Schritt für morgen hinzu.';

  @override
  String lockInWeekday(String weekday) {
    return '$weekday festlegen';
  }

  @override
  String addOneToLockIn(String weekday) {
    return 'Füge mindestens einen Vorsatz hinzu, um $weekday festzulegen.';
  }

  @override
  String get locksThisCommitment =>
      'Legt diesen Vorsatz fest. Danach kannst du ihn nicht mehr ändern.';

  @override
  String locksTheseCommitments(int count) {
    return 'Legt diese $count fest. Danach kannst du sie nicht mehr ändern.';
  }

  @override
  String archivedArea(String name) {
    return '$name (archiviert)';
  }

  @override
  String actionsFor(String name) {
    return 'Aktionen für $name';
  }

  @override
  String get removeCommitment => 'Vorsatz entfernen';

  @override
  String get tomorrowPlanCommitted => 'Der Plan für morgen ist festgelegt.';

  @override
  String get yourCommitmentsLocked => 'Deine Vorsätze sind festgelegt.';

  @override
  String get nextTomorrow => 'nächstes Mal: morgen';

  @override
  String nextDate(String date) {
    return 'nächstes Mal: $date';
  }

  @override
  String rotationSummary(int count, String name) {
    return '$count Schritte · als Nächstes: $name';
  }

  @override
  String get deleteRoutineTitle => 'Routine löschen?';

  @override
  String deleteRoutineBody(String name) {
    return '$name nicht mehr wiederholen? Vorsätze, die schon in deinen Plänen und im Verlauf sind, bleiben erhalten.';
  }

  @override
  String get delete => 'Löschen';

  @override
  String get routines => 'Routinen';

  @override
  String get routinesIntro =>
      'Routinen fügen sich an fälligen Tagen selbst in den Plan für morgen ein. Entferne eine aus einem Plan, um nur diesen Tag auszulassen. Eine Rotation mit mehreren Schritten geht erst weiter, wenn ein Schritt in deinem Plan bleibt.';

  @override
  String get createRoutineOrRotation => 'Routine oder Rotation erstellen';

  @override
  String get noRoutinesYet => 'Noch keine Routinen.';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get newRoutineStep => 'Neuer Schritt';

  @override
  String get editRoutineStep => 'Schritt bearbeiten';

  @override
  String get addStep => 'Schritt hinzufügen';

  @override
  String get saveStep => 'Schritt speichern';

  @override
  String get createRoutine => 'Routine erstellen';

  @override
  String get editRoutine => 'Routine bearbeiten';

  @override
  String get routineName => 'Name der Routine';

  @override
  String get routineRotationHelp =>
      'Eine Rotation: Jeder fällige Tag fügt den nächsten Schritt in dieser Reihenfolge hinzu. Ein entfernter Schritt kommt beim nächsten Mal wieder.';

  @override
  String get routineSingleHelp =>
      'An jedem fälligen Tag wird dies automatisch in den Plan für morgen eingefügt. Füge weitere Schritte hinzu, um eine Rotation zu erstellen.';

  @override
  String editStepN(int number) {
    return 'Schritt $number bearbeiten';
  }

  @override
  String moveStepUp(int number) {
    return 'Schritt $number nach oben';
  }

  @override
  String moveStepDown(int number) {
    return 'Schritt $number nach unten';
  }

  @override
  String removeStepN(int number) {
    return 'Schritt $number entfernen';
  }

  @override
  String get addCommitment => 'Vorsatz hinzufügen';

  @override
  String get addRotationStep => 'Rotationsschritt hinzufügen';

  @override
  String get saveRoutine => 'Routine speichern';

  @override
  String get newCommitment => 'Neuer Vorsatz';

  @override
  String get partOfRotation =>
      'Teil einer Rotation. Ändere sie unter Routinen.';

  @override
  String get commitmentHint => 'Ein kleiner, konkreter Schritt';

  @override
  String get closeEditor => 'Editor schließen';

  @override
  String get commitmentName => 'Name des Vorsatzes';

  @override
  String get statusKept => 'Gehalten';

  @override
  String get statusNotKeptYet => 'Noch nicht gehalten';

  @override
  String durationRecorded(String duration) {
    return '$duration erfasst';
  }

  @override
  String get excuseReason => 'Entschuldigungsgrund';

  @override
  String get markCompleted => 'Als erledigt markieren';

  @override
  String get excuseTask => 'Entschuldigen';

  @override
  String get resetToIncomplete => 'Auf offen zurücksetzen';

  @override
  String get excuseCommitment => 'Vorsatz entschuldigen';

  @override
  String get excusePrompt => 'Welcher äußere Umstand hat dich daran gehindert?';

  @override
  String get reason => 'Grund';

  @override
  String get enterShortReason => 'Gib einen kurzen Grund ein.';

  @override
  String get shortenReason => 'Bitte kürze diesen Grund.';

  @override
  String durationMinutesSeconds(int minutes, int seconds) {
    return '$minutes Min. $seconds Sek.';
  }

  @override
  String get loadFailed =>
      'Deine gespeicherten Vorsätze konnten nicht geladen werden.';

  @override
  String get loadingDay => 'Dein Tag wird vorbereitet.';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get loadingCommitments => 'Vorsätze werden geladen';

  @override
  String get journey => 'Weg';

  @override
  String dayStreakLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Serie von $count Tagen',
      one: 'Serie von 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String dayStreakWord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tage in Folge',
      one: 'Tag in Folge',
    );
    return '$_temp0';
  }

  @override
  String get streakStartHint => 'Halte heute alles, um eine zu beginnen';

  @override
  String get streakLongestYet => 'Deine längste bisher';

  @override
  String streakLongest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rekord: $count Tage',
      one: 'Rekord: 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get totalKept => 'gehalten';

  @override
  String get totalFocused => 'gestoppt';

  @override
  String shortMinutes(int minutes) {
    return '$minutes Min.';
  }

  @override
  String shortHours(int hours) {
    return '$hours Std.';
  }

  @override
  String get achievements => 'Erfolge';

  @override
  String seeAll(int count) {
    return 'Alle $count ansehen';
  }

  @override
  String get addAchievement => 'Erfolg hinzufügen';

  @override
  String get last5Weeks => 'Letzte 5 Wochen';

  @override
  String get dailyHistory => 'Tagesverlauf';

  @override
  String get yourAreas => 'Deine Bereiche';

  @override
  String get manage => 'Verwalten';

  @override
  String get pastChapters => 'Vergangene Kapitel';

  @override
  String get areasArchived => 'Archivierte Bereiche';

  @override
  String achievementSemantics(String title, String date) {
    return 'Erfolg: $title, $date';
  }

  @override
  String get areaUnavailable => 'Bereich nicht verfügbar';

  @override
  String get keepAMoment => 'Halte einen wichtigen Moment fest.';

  @override
  String get addAnAchievement => 'Erfolg hinzufügen';

  @override
  String get achievementExamples =>
      'Ein Führerschein, die ersten 10 km, ein abgeschlossenes Kapitel.';

  @override
  String last5WeeksKept(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Letzte 5 Wochen: $count Tage komplett gehalten',
      one: 'Letzte 5 Wochen: 1 Tag komplett gehalten',
    );
    return '$_temp0';
  }

  @override
  String get legendAllKept => 'Alles gehalten';

  @override
  String get legendSomeKept => 'Teilweise';

  @override
  String get legendMissed => 'Verpasst';

  @override
  String keptThisWeek(int count) {
    return '$count diese Woche';
  }

  @override
  String areaKeptThisWeek(String area, int count) {
    return '$area: $count diese Woche gehalten';
  }

  @override
  String get last30Days => 'Letzte 30 Tage';

  @override
  String get allTime => 'Gesamt';

  @override
  String completedCommitments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count erledigte Vorsätze',
      one: '1 erledigter Vorsatz',
    );
    return '$_temp0';
  }

  @override
  String recordedTime(String duration) {
    return '$duration erfasste Zeit';
  }

  @override
  String get stopwatchExplainer =>
      'Die Stoppuhr erfasst den echten Einsatz, auch bei nicht erledigten Vorsätzen.';

  @override
  String get activityOverTime => 'Aktivität im Zeitverlauf';

  @override
  String get trackedTime => 'Erfasste Zeit';

  @override
  String get achievementsPlace =>
      'Ein Ort für die Momente, an die du dich erinnern willst.';

  @override
  String get recordedCommitments => 'Erfasste Vorsätze';

  @override
  String recordsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge',
      one: '1 Eintrag',
    );
    return '$_temp0';
  }

  @override
  String get recordsEmpty => 'Deine erfassten Vorsätze erscheinen hier.';

  @override
  String get recordedTimeEmpty => 'Erfasste Zeit erscheint hier.';

  @override
  String get completedEmpty => 'Erledigte Vorsätze erscheinen hier.';

  @override
  String get activityDetails => 'Aktivitätsdetails';

  @override
  String activityRange(String from, String through, String value) {
    return '$from bis $through: $value';
  }

  @override
  String activityDescriptionTime(String days) {
    return 'Letzte 30 Tage, erfasste Zeit. $days';
  }

  @override
  String activityDescriptionCompleted(String days) {
    return 'Letzte 30 Tage, erledigte Vorsätze. $days';
  }

  @override
  String get thirtyDaysTime => '30 Tage · Zeit';

  @override
  String get thirtyDaysCompleted => '30 Tage · erledigt';

  @override
  String completedCount(int count) {
    return '$count erledigt';
  }

  @override
  String get openSpace => 'Freier Raum';

  @override
  String get openArea => 'Bereich öffnen';

  @override
  String get latestAchievement => 'Neuester Erfolg';

  @override
  String get pastChaptersIntro =>
      'Teile deines Lebens, hier aufbewahrt zum Wiederentdecken.';

  @override
  String get pastChaptersEmpty =>
      'Archivierte Bereiche bleiben hier, zusammen mit ihrem Verlauf.';

  @override
  String get savePendingBeforeStopwatch =>
      'Speichere deine offenen Änderungen, bevor du eine Stoppuhr änderst.';

  @override
  String get couldNotSaveAppearance =>
      'Die Darstellung konnte nicht gespeichert werden.';

  @override
  String get couldNotSaveSetup =>
      'Die Einrichtung konnte nicht gespeichert werden. Versuche es in den Einstellungen erneut.';

  @override
  String get tomorrowAlreadyCommitted =>
      'Der Plan für morgen ist bereits festgelegt. Bestehende Vorsätze bleiben erhalten. Füge einen weiteren hinzu, sobald der nächste Tag beginnt.';

  @override
  String get firstCommitmentHeading => 'Dein erster Vorsatz · morgen';

  @override
  String pausedTask(String name) {
    return '$name pausiert.';
  }

  @override
  String removedForWeekday(String weekday) {
    return 'Für $weekday entfernt.';
  }

  @override
  String get stopRepeating => 'Nicht mehr wiederholen';

  @override
  String get stoppedRepeating => 'Wird nicht mehr wiederholt.';

  @override
  String get achievementsIntro =>
      'Worauf du stolz bist: ein Führerschein, die ersten 10 km, ein abgeschlossenes Kapitel.';

  @override
  String get achievement => 'Erfolg';

  @override
  String get achievementRemoved => 'Dieser Erfolg wurde entfernt.';

  @override
  String get deleteAchievementTitle => 'Erfolg löschen?';

  @override
  String deleteAchievementBody(String title) {
    return '„$title“ entfernen? Deine Vorsätze und Bereiche bleiben, wie sie sind.';
  }

  @override
  String get keepAchievement => 'Erfolg behalten';

  @override
  String get couldNotSaveChanges =>
      'Deine Änderungen konnten nicht gespeichert werden.';

  @override
  String get tourDayTitle => 'Das ist dein Tag';

  @override
  String get tourDayBody =>
      'Die Sonne steigt, während du die heutigen Vorsätze hältst. Halte alle, und sie steht ganz oben.';

  @override
  String get tourCommitmentsTitle => 'Die heutigen Vorsätze';

  @override
  String get tourCommitmentsBody =>
      'Tippe auf den Kreis, um einen zu halten. Tippe auf die Zeile für eine Stoppuhr oder entschuldige ihn mit einem Grund, wenn wirklich etwas dazwischengekommen ist.';

  @override
  String get tourFreedomTitle => 'Freiheit';

  @override
  String get tourFreedomBody =>
      'Eingeschränkte Apps öffnen sich zur Freiheitszeit, sobald heute gehalten und morgen festgelegt ist. Tippe hier jederzeit, um zu sehen, was noch fehlt.';

  @override
  String get tourPlanTitle => 'Morgen planen';

  @override
  String get tourPlanBody =>
      'Plane jeden Abend den nächsten Tag, solange der heutige noch frisch ist. Wähle ein paar Dinge, die du wirklich tun wirst.';

  @override
  String get tourAddTitle => 'Hinzufügen und wiederholen';

  @override
  String get tourAddBody =>
      'Füge einen Vorsatz hinzu und gib ihm einen Bereich. Schalte Wiederholen für Gewohnheiten ein, dann tragen sie sich an ihren Tagen selbst ein.';

  @override
  String get tourLockTitle => 'Festlegen';

  @override
  String get tourLockBody =>
      'Wenn morgen gut aussieht, leg es fest. Danach lässt es sich nicht mehr ändern. Genau das macht es zu einem Vorsatz.';

  @override
  String get tourJourneyTitle => 'Dein Weg';

  @override
  String get tourJourneyBody =>
      'Jeder gehaltene Tag zählt hier: deine Serie, dein Einsatz und die Erfolge, auf die du stolz bist.';

  @override
  String get tourAreasTitle => 'Bereiche';

  @override
  String get tourAreasBody =>
      'Jeder Bereich verfolgt einen Teil deines Lebens, etwa Körper, Geist oder Karriere. Hier fügst du sie hinzu, benennst sie um oder archivierst sie. Weiter unten öffnest du einen, um seinen Verlauf zu sehen.';

  @override
  String get tourSettingsTitle => 'Einstellungen';

  @override
  String get tourSettingsBody =>
      'Freiheitszeit, App-Sperre, Routinen, Erinnerungen und Farben findest du hier. Du kannst diese Tour auch in den Einstellungen wiederholen.';

  @override
  String stepOf(int current, int total) {
    return '$current von $total';
  }

  @override
  String get skipTour => 'Tour überspringen';

  @override
  String get back => 'Zurück';

  @override
  String get next => 'Weiter';

  @override
  String tourStepSemantics(int current, int total) {
    return 'App-Tour, Schritt $current von $total';
  }

  @override
  String get setupTourBody =>
      'Wir gehen durch die echten Bildschirme Heute, Planen und Weg und zeigen, wofür jeder Teil da ist. Das dauert etwa eine Minute, und du kannst jederzeit überspringen.';

  @override
  String get setupTestBody =>
      'Öffne eine ausgewählte App und achte auf den Sperrbildschirm von Daylock. Komm hierher zurück, um das Ergebnis zu sehen. Öffne sie auch ganz normal vom Startbildschirm, nachdem Daylock im Hintergrund ist: Dieser Test bestätigt nur ein Öffnen. Er nutzt deine echten Freiheitsbedingungen und erledigt nie ein Ziel für dich.';

  @override
  String get setupFirstCommitmentBody =>
      'Der heutige Plan ist bereits festgelegt. Dein erster neuer Vorsatz kommt in den echten Plan für morgen. Apps werden freigegeben, wenn alle zählenden Vorsätze erledigt sind, die Freiheitszeit erreicht ist und der Plan für morgen festgelegt ist. Ein leerer Tag bringt keine Freiheit.';

  @override
  String get setupAccessibilityOemHelp =>
      'Bei Xiaomi / HyperOS, Samsung und Pixel heißen die Einstellungen unterschiedlich. Wähle den Dienst dieser installierten Daylock-App. Wenn „Eingeschränkte Einstellungen“ erscheint, prüfe App-Info → Eingeschränkte Einstellungen zulassen, nur für eine vertrauenswürdige Version. Wenn der Dienst aktiviert, aber nicht verbunden ist, schalte ihn einmal aus und wieder ein.';

  @override
  String get setupAccessibilityExplain =>
      'Daylock erkennt, wenn eine ausgewählte App geöffnet wird, und kann seinen Sperrbildschirm zeigen oder zum Startbildschirm zurückkehren. Bildschirminhalte werden nie gelesen. Der Zugriff ist optional und kann in den Android-Einstellungen widerrufen werden.';

  @override
  String get setupBlockingOptional =>
      'Die App-Sperre ist optional. Auch ohne sie plant Daylock deine Tage und verfolgt deine Vorsätze. Du kannst sie später in den Einstellungen einschalten.';

  @override
  String get setupXiaomiBody =>
      'HyperOS kann Daylock im Hintergrund pausieren, auch wenn die Bedienungshilfe als aktiviert angezeigt wird. Ein Test in Daylock kann funktionieren, während das Öffnen von Instagram vom Startbildschirm nicht klappt.\n\nIn der App-Info dieser App:\n• Autostart: an\n• Energiesparen (oder Akku): Keine Einschränkungen\n• Weitere Berechtigungen → Pop-up-Fenster im Hintergrund anzeigen: erlauben\n\nDaylock in den letzten Apps wegzuwischen oder „Bereinigen“ zu nutzen, kann die Sperre trotzdem stoppen. Dann zeigt Heute eine Warnung: Schalte Daylock in den Bedienungshilfen aus und wieder ein.\n\nNutze die Einstellungen dieser installierten Daylock-App; Daylock Dev und die Play-Version haben getrennte Einstellungen. Daylock kann diese Xiaomi-Optionen nicht auslesen. Bestätige sie unten selbst und teste dann auch normales Öffnen.';

  @override
  String get setupLockNotConfirmed =>
      'Sperrbildschirm nicht bestätigt. Prüfe, ob die Bedienungshilfe verbunden ist, und versuche es erneut. Android kann zum Startbildschirm zurückkehren oder das Öffnen des Sperrbildschirms einschränken. Öffne Berechtigungen & Diagnose in den Einstellungen, um das erfasste Ergebnis zu sehen.';

  @override
  String get setupVerified =>
      'Bestätigt: Android hat den Sperrbildschirm von Daylock angezeigt.';

  @override
  String get setupSaveProgressFailed =>
      'Der Fortschritt konnte nicht gespeichert werden. Bitte erneut versuchen.';

  @override
  String get setupOpeningApp =>
      'Deine ausgewählte App wird geöffnet. Komm zu Daylock zurück, nachdem du den Sperrbildschirm geprüft hast.';

  @override
  String get setupSaveConfirmationFailed =>
      'Deine Bestätigung konnte nicht gespeichert werden. Bitte erneut versuchen.';

  @override
  String get setupWelcomeBody =>
      'Plane deinen Tag. Verdiene dir deine Freiheit. Halte deine Vorsätze, bevor deine ablenkenden Apps freigegeben werden.';

  @override
  String get setupWelcomePlan =>
      'Wähle am Vorabend ein paar wichtige Vorsätze.';

  @override
  String get setupBlockDistractions => 'Ablenkungen sperren';

  @override
  String get setupWelcomeBlock =>
      'Du bestimmst, welche Apps eingeschränkt werden.';

  @override
  String get setupKeepYourWord => 'Wort halten';

  @override
  String get setupWelcomeKeep =>
      'Halte die heutigen Vorsätze und lege dann den Plan für morgen fest.';

  @override
  String get setupUnlockApps => 'Apps freigeben';

  @override
  String get setupWelcomeUnlock =>
      'Erreiche deine Freiheitszeit und genieß die verdiente Pause.';

  @override
  String get setupXiaomiTitle => 'Xiaomi / Poco: Sperre aktiv halten';

  @override
  String get setupOpenAppInfo => 'App-Info von Daylock öffnen';

  @override
  String get setupXiaomiConfirm =>
      'Ich habe diese Einstellungen für diese Daylock-App geändert';

  @override
  String get setupXiaomiConfirmNote =>
      'Deine Bestätigung; wird nicht automatisch geprüft.';

  @override
  String get setupAccessibilityTitle =>
      'Zugriff auf Bedienungshilfen · optional';

  @override
  String get setupBlockingAndroidOnly =>
      'Die Sperre ist unter Android verfügbar. Den Planer kannst du hier trotzdem nutzen.';

  @override
  String get setupAccessibilityConnected =>
      'Aktiviert und verbunden. Daylock kann ausgewählte Apps erkennen.';

  @override
  String get setupAccessibilityWaiting =>
      'Aktiviert. Warte darauf, dass Android den Dienst verbindet. Tippe nach der Rückkehr auf Aktualisieren.';

  @override
  String get setupEnableAccessibility => 'Bedienungshilfe aktivieren';

  @override
  String get setupNotificationsTitle => 'Benachrichtigungen · optional';

  @override
  String get setupNotificationsAllowed =>
      'Erlaubt. Lokale Erinnerungen und Ersatzhinweise zu Einschränkungen können erscheinen.';

  @override
  String get setupNotificationsExplain =>
      'Erlaube lokale Erinnerungen und einen Hinweis, wenn Android den Sperrbildschirm nicht anzeigen kann. Du kannst auch ohne Benachrichtigungen fortfahren.';

  @override
  String get setupAllowNotifications => 'Benachrichtigungen erlauben';

  @override
  String get setupRefreshPermissions => 'Berechtigungsstatus aktualisieren';

  @override
  String get setupChooseAppsBody =>
      'Wähle Apps, die du bewusster öffnen willst. Deine Auswahl bleibt auf diesem Gerät.';

  @override
  String get setupRestrictionsEnableFreedom =>
      'Wenn du hier App-Einschränkungen einschaltest, wird auch die Freiheitskontrolle zu deiner gespeicherten Freiheitszeit aktiviert.';

  @override
  String get setupSaveBlockingFailed =>
      'Die Sperreinstellungen konnten nicht gespeichert werden. Bitte erneut versuchen.';

  @override
  String get setupAppSelectionAndroidOnly =>
      'Die Auswahl installierter Apps ist unter Android verfügbar.';

  @override
  String get setupOneSmallStep => 'Ein kleiner Schritt für morgen';

  @override
  String get setupSaveCommitmentFailed =>
      'Dein Vorsatz konnte nicht gespeichert werden. Bitte erneut versuchen.';

  @override
  String get setupCreateCommitment => 'Vorsatz erstellen';

  @override
  String get setupAlreadyHasCommitment =>
      'Dein Plan enthält bereits einen Vorsatz. Du kannst fortfahren, ohne einen weiteren zu erstellen.';

  @override
  String get setupTestTitle => 'Teste deine echte App-Einschränkung';

  @override
  String get setupTestAndroidOnly => 'Sperrtests erfordern die Android-App.';

  @override
  String get setupChecking => 'Wird geprüft…';

  @override
  String get setupTestSelectedApp => 'Ausgewählte App testen';

  @override
  String get setupEnableFreedomAndRestrictions =>
      'Freiheitskontrolle und App-Einschränkungen aktivieren';

  @override
  String setupTestNeedsFreedom(String state) {
    return 'Aktuelle Freiheit: $state. Für den echten Test muss die Freiheitskontrolle an sein und die Freiheit noch nicht verdient. Du kannst die Einrichtung verlassen und über die Einstellungen zurückkehren, wenn diese Bedingungen gelten.';
  }

  @override
  String get setupAccessibilityNotConnected =>
      'Die Bedienungshilfe ist nicht verbunden. Geh zurück zur Berechtigungseinrichtung.';

  @override
  String get setupConfirmXiaomi =>
      'Geh zurück zu „App-Sperre einrichten“ und bestätige die Xiaomi-Akkueinstellung, damit die Sperre weiter funktioniert.';

  @override
  String get setupRefreshRetry => 'Aktualisieren und erneut versuchen';

  @override
  String get setupReadyTitle => 'Mach Platz für das, was zählt';

  @override
  String get setupReadyBody =>
      'Deine Einstellungen und dein Vorsatz sind gespeichert. Starte mit Heute, plane morgen und sieh deinen Weg wachsen.';

  @override
  String get setupTourTitle => 'Kurze Tour machen';

  @override
  String get setupBlockingOff => 'App-Sperre ist aus';

  @override
  String get setupBlockingOffBody =>
      'Daylock schränkt keine Apps ein. Wenn du das später willst, öffne die Einstellungen und schalte App-Einschränkungen ein.';

  @override
  String get setupSkipTour => 'Tour überspringen';

  @override
  String get previousStep => 'Vorheriger Schritt';

  @override
  String get saveAndLeave => 'Speichern & verlassen';

  @override
  String stepNOfM(int current, int total) {
    return 'Schritt $current von $total';
  }

  @override
  String get getStarted => 'Los geht’s';

  @override
  String get continueWithoutBlocking => 'Ohne Sperre fortfahren';

  @override
  String get skipTestForNow => 'Test vorerst überspringen';

  @override
  String get finishSetup => 'Einrichtung abschließen';

  @override
  String get takeTheTour => 'Tour starten';

  @override
  String get goToDaylock => 'Zu Daylock';

  @override
  String get continueLabel => 'Weiter';

  @override
  String get setupTitleWelcome => 'Hol dir die Kontrolle zurück';

  @override
  String get setupTitleBlocking => 'App-Sperre einrichten';

  @override
  String get setupTitleApps => 'Wähle deine Ablenkungen';

  @override
  String get setupTitleCommitment => 'Dein erster Vorsatz';

  @override
  String get setupTitleTest => 'Fast geschafft!';

  @override
  String get setupTitleReady => 'Alles bereit!';

  @override
  String get diagLockUnconfirmed =>
      'Sperrbildschirm: nicht bestätigt; eine Ersatzbenachrichtigung kann verwendet werden.';

  @override
  String get diagLockFailedException =>
      'Sperrbildschirm: Android hat das Öffnen abgelehnt oder es ist fehlgeschlagen.';

  @override
  String get diagLockShown => 'Sperrbildschirm: sichtbar und bestätigt.';

  @override
  String get diagLockRequestedUnconfirmed =>
      'Sperrbildschirm: Anfrage gesendet; Sichtbarkeit noch nicht bestätigt.';

  @override
  String get diagLockAttempted => 'Sperrbildschirm: Öffnen angefordert.';

  @override
  String get diagHomeRejected =>
      'Startbildschirm: Android hat die Anfrage abgelehnt.';

  @override
  String get diagHomeAccepted =>
      'Startbildschirm: Android hat die Anfrage angenommen.';

  @override
  String get diagHomeAttempted => 'Startbildschirm: angefordert.';

  @override
  String get diagRestrictionOther =>
      'Der letzte Einschränkungsstatus konnte nicht geprüft werden.';

  @override
  String get diagRestrictionSkippedLaunchThrottled =>
      'Einschränkung übersprungen: Ein Sperrbildschirm wird bereits geöffnet.';

  @override
  String get diagRestrictionSkippedFreedomDisabled =>
      'Einschränkung übersprungen: Freiheitskontrolle ist aus.';

  @override
  String get diagRestrictionSkippedFreedomEarned =>
      'Einschränkung übersprungen: Freiheit ist verdient.';

  @override
  String get diagRestrictionSkippedStateChanged =>
      'Einschränkung übersprungen: Der Freiheitsstatus hat sich beim Öffnen der App geändert.';

  @override
  String get diagRestrictionRetryingStateChanged =>
      'Der Freiheitsstatus hat sich während der Durchsetzung geändert; wird noch einmal geprüft.';

  @override
  String get diagRestrictionSkippedLockAlreadyVisible =>
      'Einschränkung übersprungen: Ein Daylock-Sperrbildschirm war bereits sichtbar.';

  @override
  String get diagRestrictionSkippedServiceInactive =>
      'Einschränkung übersprungen: Der Bedienungshilfen-Dienst war nicht mehr aktiv.';

  @override
  String get diagRestrictionSkippedDeviceNotInteractive =>
      'Einschränkung übersprungen: Das Gerät war gesperrt oder inaktiv.';

  @override
  String get diagRestrictionSkippedSelectionUnavailable =>
      'Einschränkung übersprungen: Die ausgewählte App konnte nicht geprüft werden.';

  @override
  String get diagRestrictionSkippedAccessibilityDisabled =>
      'Einschränkung übersprungen: Die Bedienungshilfe ist nicht mehr aktiviert.';

  @override
  String get diagRestrictionSkippedForegroundChangedBeforeNavigation =>
      'Einschränkung übersprungen: Die App im Vordergrund hat vor der Durchsetzung gewechselt.';

  @override
  String get diagRestrictionHomeFailed =>
      'Letzter Versuch: Android hat die Rückkehr zum Startbildschirm abgelehnt. Die Einschränkung konnte nicht angewendet werden.';

  @override
  String get diagRestrictionLockLaunchUnconfirmed =>
      'Letzter Versuch: Sperrbildschirm nicht bestätigt. Android kann Starts im Hintergrund einschränken.';

  @override
  String get diagRestrictionHomeOnly =>
      'Letzter Versuch: Startbildschirm angefordert; Sperrbildschirm nicht bestätigt.';

  @override
  String get diagRestrictionLockFallbackUnavailable =>
      'Letzter Versuch: Sperrbildschirm nicht bestätigt. Erlaube Benachrichtigungen und den Kanal „Hinweise zu App-Einschränkungen“ in den Android-Einstellungen für Ersatzhinweise.';

  @override
  String get diagRestrictionLockFallbackPosted =>
      'Letzter Versuch: Sperrbildschirm nicht bestätigt; Hinweis zur App-Einschränkung gesendet. Android steuert die Zustellung.';

  @override
  String get diagRestrictionLockLaunchRequested =>
      'Letzter Versuch: Sperrbildschirm angefordert; Anzeige noch nicht bestätigt.';

  @override
  String get diagRestrictionStateUnknown =>
      'Letzter Versuch: Ausgewählte Apps erlaubt, weil der Freiheitsstatus nicht verfügbar war.';

  @override
  String get diagRestrictionLockShown =>
      'Letzter Versuch: Daylock-Sperrbildschirm angezeigt.';

  @override
  String get diagRestrictionRecoveryShown =>
      'Letzter Versuch: Wiederherstellungsbildschirm angezeigt. Öffne Daylock, um die Pläne zu aktualisieren oder die Sperre auszuschalten.';

  @override
  String get diagRestrictionRestrictionRecovery =>
      'Die Einschränkung braucht eine Aktualisierung des Freiheitsstatus durch Daylock.';

  @override
  String get diagRestrictionRestrictionTriggered =>
      'Einschränkung ausgelöst: Daylock-Sperre wird gestartet.';

  @override
  String get diagRestrictionEligibilityUnknown =>
      'Berechtigung nicht bestätigt; die Sperre ist sicherheitshalber pausiert.';

  @override
  String get diagRestrictionEligibilityDisabled =>
      'Berechtigung geprüft: Freiheitskontrolle ist aus; die App ist erlaubt.';

  @override
  String get diagRestrictionEligibilityEarned =>
      'Berechtigung geprüft: Freiheit ist verdient; die App ist erlaubt.';

  @override
  String get diagRestrictionEligibilityNotEarned =>
      'Berechtigung geprüft: Freiheit ist nicht verdient.';

  @override
  String get diagRestrictionDetectedSelectedApp =>
      'Ausgewählte App erkannt. Freiheit und Einschränkung werden geprüft.';

  @override
  String get diagRestrictionTestRequested =>
      'Test angefordert: Warte auf eine neue Erkennung einer ausgewählten App.';

  @override
  String get diagRestrictionSkippedEventDelayed =>
      'Android hat das Öffnen der App zu spät gemeldet. Prüfe bei Xiaomi / HyperOS App-Info von Daylock → Akku → Keine Einschränkungen und teste dann das Öffnen einer ausgewählten App vom Startbildschirm.';

  @override
  String get diagRestrictionNone => 'Noch kein Einschränkungsversuch.';

  @override
  String get diagEnableBlockingBody =>
      'Wenn die Freiheitskontrolle an ist und die Freiheit nicht verdient ist, nutzt Daylock die Bedienungshilfen, um eine ausgewählte App zu verlassen und seinen eigenen Sperrbildschirm zu zeigen. Die Liste installierter Apps und deine Auswahl bleiben auf diesem Gerät. Bildschirminhalte werden nicht gelesen und kein Browserverlauf erfasst. Nur die letzte Erkennung und das letzte Einschränkungsergebnis bleiben auf diesem Gerät. Andere Fenster-Paketnamen werden nur verglichen, um eine ausstehende Aktion abzubrechen, wenn du die App wechselst; sie werden nicht gespeichert. Du kannst die Sperre hier ausschalten oder den Zugriff auf die Bedienungshilfen jederzeit widerrufen.\n\nFreiheitsdaten bleiben für ihr Datum gültig, ohne Daylock erneut zu öffnen. Fehlt der aktuelle Status oder ist er ungültig, bietet Daylock einen Wiederherstellungsbildschirm mit „Daylock öffnen“ und „Sperre ausschalten“; weitere Öffnungen sind erlaubt, solange eine Wiederherstellung nötig ist. Dies ist eine freiwillige Einschränkung, kein manipulationssicheres System und keine Kindersicherung.';

  @override
  String get diagPermissionBody =>
      'Daylock nutzt die Android-Bedienungshilfen, um zu erkennen, wenn eine ausgewählte App geöffnet wird, auch wenn Daylock im Hintergrund ist. Gespeichert werden auf diesem Gerät nur die letzte Erkennung, der Freiheitsstatus und das Einschränkungsergebnis; nichts wird an einen Server gesendet. Die Liste installierter Apps und deine Auswahl bleiben auf diesem Gerät. Bildschirminhalte werden nicht gelesen und kein Browserverlauf erfasst. Mit dem separaten Schalter für App-Einschränkungen kann Daylock zum Startbildschirm zurückkehren und einen Daylock-Sperrbildschirm zeigen, wenn die Freiheit nicht verdient ist. Fensterwechsel werden nur verglichen, um Aktionen abzubrechen, wenn du die App wechselst; andere App-Namen werden nicht gespeichert. Es werden keine Overlays gezeichnet und keine nicht ausgewählten Apps eingeschränkt.\n\nDu entscheidest, ob du „Daylock-App-Einschränkungen“ in den Android-Bedienungshilfen aktivierst. Du kannst sie dort jederzeit deaktivieren.';

  @override
  String get diagPermissionTitle => 'Berechtigung für App-Einschränkungen';

  @override
  String get diagAgreeOpenSettings => 'Zustimmen und Einstellungen öffnen';

  @override
  String get diagEnableBlockingTitle => 'App-Einschränkungen aktivieren?';

  @override
  String get diagEnableBlocking => 'Sperre aktivieren';

  @override
  String get diagAppRestrictionsLabel => 'App-Einschränkungen';

  @override
  String get diagAppRestrictionsIntro =>
      'Die Bedienungshilfe erkennt, wenn ausgewählte Apps im Hintergrund geöffnet werden. Die optionale Sperre zeigt einen Daylock-Sperrbildschirm oder kehrt zum Startbildschirm zurück, bis die Freiheit verdient ist. Kann der Bildschirm nicht erscheinen, erklärt eine Benachrichtigung die Sperre, sofern Android es erlaubt.';

  @override
  String get diagAppRestrictions => 'App-Einschränkungen';

  @override
  String get diagSeparateFromFreedom =>
      'Unabhängig von der Freiheitskontrolle. Standardmäßig aus.';

  @override
  String get diagStatusUnavailable =>
      'Status der App-Einschränkungen nicht verfügbar';

  @override
  String get diagRestrictionsOff => 'App-Einschränkungen: aus';

  @override
  String get diagWaitingForAccessibility =>
      'App-Einschränkungen: warten auf Zugriff auf Bedienungshilfen';

  @override
  String get diagAllowedFreedomOff =>
      'Ausgewählte Apps erlaubt — Freiheitskontrolle ist aus';

  @override
  String get diagAllowedFreedomEarned =>
      'Ausgewählte Apps erlaubt — Freiheit verdient';

  @override
  String get diagBlockingPaused =>
      'Sperre pausiert — öffne Daylock, um die Freiheit zu aktualisieren';

  @override
  String get diagRestrictionsReady =>
      'App-Einschränkungen bereit — Öffnen und Navigation hängen von Android ab';

  @override
  String get diagServiceStatusUnavailable => 'Dienststatus nicht verfügbar';

  @override
  String get diagAndroidOnly =>
      'Die native Erkennung ist nur unter Android verfügbar.';

  @override
  String get diagServiceDisabled => 'Bedienungshilfen-Dienst: deaktiviert';

  @override
  String get diagServiceConnected =>
      'Bedienungshilfen-Dienst: aktiviert und verbunden';

  @override
  String get diagServiceWaiting =>
      'Bedienungshilfen-Dienst: aktiviert — warte auf Verbindung durch Android';

  @override
  String get diagBlockingSaveFailed =>
      'Die Sperrauswahl konnte nicht gespeichert werden. Das Ausschalten wirkt sofort, übersteht aber eventuell keinen Neustart. Widerrufe bei Bedarf den Zugriff auf die Bedienungshilfen.';

  @override
  String get diagNoDetectionYet => 'Noch keine ausgewählte App erkannt.';

  @override
  String diagLastDetection(String when) {
    return 'Letzte Erkennung einer eingeschränkten App: $when';
  }

  @override
  String diagFreedomAtDetection(String state) {
    return 'Freiheit bei dieser Erkennung: $state';
  }

  @override
  String diagCurrentFreedom(String state) {
    return 'Aktueller nativer Freiheitsstatus: $state';
  }

  @override
  String get diagFocusNeedsRefresh =>
      'Eine aktive Fokussitzung muss von Daylock abgeglichen werden. Die native Erkennung markiert sie nicht als erledigt.';

  @override
  String get diagStateUnavailable =>
      'Der Status für heute ist nicht verfügbar. Öffne Daylock, um die Pläne abzugleichen, oder schalte die Sperre aus. Gültige Tagesdaten laufen nicht nach fünf Minuten ab.';

  @override
  String get diagRolloverReconciled =>
      'Neuer Tag: Der gespeicherte Plan für dieses Datum wird verwendet. Öffne Daylock, um den Verlauf zu archivieren und den nächsten Tag vorzubereiten.';

  @override
  String get diagNoEligible =>
      'Keine zählenden Vorsätze. Leere oder komplett entschuldigte Tage bringen keine Freiheit.';

  @override
  String get diagDetectionSaveFailed =>
      'Die letzte Erkennung konnte nicht gespeichert werden und übersteht eventuell keinen Neustart.';

  @override
  String get diagTurnBlockingOff => 'Sperre ausschalten';

  @override
  String get diagSettingsPath =>
      'Android-Einstellungen → Bedienungshilfen → Heruntergeladene/Installierte Apps → Daylock-App-Einschränkungen. Schalte den Dienst manuell ein. Die Namen variieren je nach Telefon.';

  @override
  String get diagRestrictedSettings =>
      'Wenn Android 15 „Eingeschränkte Einstellungen“ anzeigt, suche in der App-Info von Daylock nach „Eingeschränkte Einstellungen zulassen“ und bestätige nur für eine vertrauenswürdige Entwicklungsversion.';

  @override
  String get diagAvailableAndroidOnly => 'Nur unter Android verfügbar';

  @override
  String get diagServiceEnabledShort => 'Bedienungshilfen-Dienst: aktiviert';

  @override
  String get diagServiceDisconnected => 'Dienst getrennt';

  @override
  String get diagRestrictionsOn => 'App-Einschränkungen: an';

  @override
  String selectedAppsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ausgewählte Apps',
      one: '1 ausgewählte App',
    );
    return '$_temp0';
  }

  @override
  String diagNativeFreedom(String state) {
    return 'Native Freiheit: $state';
  }

  @override
  String get diagTechnicalDetails => 'Technische Details & Einrichtung';

  @override
  String diagLastPackage(String package) {
    return 'Letztes eingeschränktes Paket: $package';
  }

  @override
  String get openAccessibilitySettings => 'Bedienungshilfen öffnen';

  @override
  String get refreshStatus => 'Status aktualisieren';

  @override
  String get appsLoadFailed =>
      'Installierte Apps konnten nicht geladen werden. Deine gespeicherte Auswahl wurde nicht ersetzt.';

  @override
  String get appsPausedAttention =>
      'Einschränkungen pausiert: Der Status braucht Aufmerksamkeit.';

  @override
  String get appsRestrictionsOff =>
      'App-Einschränkungen sind aus. Deine Auswahl ist gespeichert.';

  @override
  String get appsNoneSelected =>
      'Keine Apps ausgewählt. Nichts ist eingeschränkt.';

  @override
  String get appsWaitingAccessibility =>
      'Warte auf Zugriff auf Bedienungshilfen. Ausgewählte Apps sind nicht eingeschränkt.';

  @override
  String get appsFreedomOff =>
      'Freiheitskontrolle ist aus. Ausgewählte Apps sind zugänglich.';

  @override
  String get appsFreedomEarned =>
      'Freiheit verdient. Ausgewählte Apps sind zugänglich.';

  @override
  String get appsNeedsRefresh =>
      'Der Freiheitsstatus muss aktualisiert werden. Eine Wiederherstellung ist verfügbar; wiederholtes Öffnen ist erlaubt.';

  @override
  String get appsRestricted =>
      'Ausgewählte Apps sind eingeschränkt, bis die Freiheit verdient ist.';

  @override
  String selectedCountLabel(int count) {
    return 'Ausgewählt: $count';
  }

  @override
  String get refreshApps => 'Apps aktualisieren';

  @override
  String get appsMasterControl => 'Hauptschalter für alle ausgewählten Apps.';

  @override
  String get appsMasterSaveFailed =>
      'Der Hauptschalter konnte nicht gespeichert werden. Das Ausschalten wirkt sofort, übersteht aber eventuell keinen Neustart.';

  @override
  String get appsChooseBelow =>
      'Wähle unten Apps aus. Freiheitskontrolle und App-Einschränkungen sind unabhängig. System-Wiederherstellungs-Apps sind ausgenommen.';

  @override
  String appsRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count nicht verfügbare oder neu installierte Apps wurden aus der Auswahl entfernt. Wähle sie bei Bedarf erneut aus.',
      one: '1 nicht verfügbare oder neu installierte App wurde aus der Auswahl entfernt. Wähle sie bei Bedarf erneut aus.',
    );
    return '$_temp0';
  }

  @override
  String get appsNoneSelectedYet =>
      'Noch keine Apps ausgewählt. Wähle die Apps, die du einschränken willst.';

  @override
  String get searchApps => 'Apps suchen';

  @override
  String get appsSelectionRequiresAndroid =>
      'Die Auswahl installierter Apps erfordert Android.';

  @override
  String get retryAppDiscovery => 'App-Suche wiederholen';

  @override
  String get appsNoneFound =>
      'In diesem Android-Profil wurden keine unterstützten Apps gefunden.';

  @override
  String get appsNoMatches => 'Keine passenden Apps.';

  @override
  String get appIconUnavailable => 'App-Symbol nicht verfügbar';

  @override
  String get savingSelection => 'Auswahl wird gespeichert…';

  @override
  String get appsSelectionsStay =>
      'Deine Auswahl bleibt auf diesem Gerät. Neue oder neu installierte Apps müssen ausdrücklich ausgewählt werden.';

  @override
  String get notifRunningStopwatchHelp =>
      'Zeigt eine dezente Benachrichtigung mit Pause, solange eine Stoppuhr läuft, und erinnert dich alle 2 Stunden daran, damit sie nicht versehentlich weiterläuft.';

  @override
  String get notifBlockedInSystem => 'In den Android-Einstellungen blockiert';

  @override
  String get notifLabel => 'Benachrichtigungen';

  @override
  String get notifPermissionAllowed => 'Systemberechtigung: erlaubt';

  @override
  String get notifPermissionDenied => 'Systemberechtigung: nicht erlaubt';

  @override
  String get notifNeedsAttention =>
      'Die Benachrichtigungseinrichtung braucht Aufmerksamkeit';

  @override
  String get notifChecking => 'Systemberechtigung wird geprüft…';

  @override
  String get notifUnavailable => 'Geplante Benachrichtigungen nicht verfügbar';

  @override
  String get notifPermissionHelp => 'Hilfe zur Berechtigung';

  @override
  String get notifOpenSettings => 'Benachrichtigungseinstellungen öffnen';

  @override
  String get notifPlanTomorrow => 'Morgen planen';

  @override
  String get notifCommitmentReminder => 'Vorsatz-Erinnerung';

  @override
  String get notifFreedom => 'Freiheitsbenachrichtigungen';

  @override
  String get notifFreedomHelp =>
      'Nutzt die Freiheitszeit, wenn die Freiheitskontrolle aktiviert ist.';

  @override
  String get notifRunningStopwatch => 'Laufende Stoppuhr';

  @override
  String get healthXiaomiTip =>
      'Damit es auf Xiaomi / Poco nicht wieder passiert: Erlaube in der App-Info von Daylock den Autostart, stelle Energiesparen auf „Keine Einschränkungen“, erlaube Pop-ups im Hintergrund und wische Daylock nicht aus den letzten Apps weg.';

  @override
  String get healthOffBody =>
      'Der Zugriff von Daylock auf die Bedienungshilfen ist aus, deshalb öffnen sich deine ausgewählten Apps frei. Schalte ihn ein, um die Sperre zurückzuholen.';

  @override
  String get healthStoppedBody =>
      'Android hat Daylock im Hintergrund beendet, deshalb öffnen sich deine ausgewählten Apps frei. Schalte Daylock in den Bedienungshilfen aus und wieder ein.';

  @override
  String get healthStoppedTitle => 'Die App-Sperre wurde gestoppt';

  @override
  String get openAccessibility => 'Bedienungshilfen öffnen';

  @override
  String get openAppInfo => 'App-Info öffnen';

  @override
  String get conditionSatisfied => 'Erfüllt';

  @override
  String get conditionRemaining => 'Offen';

  @override
  String freedomTimeAt(String time) {
    return 'Freiheitszeit · $time';
  }

  @override
  String eligibleComplete(int kept, int total) {
    return '$kept / $total zählende Vorsätze erledigt';
  }

  @override
  String get noEligibleRequired =>
      'Keine zählenden Vorsätze — für Freiheit müssen Vorsätze erledigt werden.';

  @override
  String get tomorrowPlanCommittedCondition => 'Plan für morgen festgelegt';

  @override
  String get planDateMismatch =>
      'Der heutige Plan passt nicht zum aktuellen lokalen Datum.';

  @override
  String availableAt(String time) {
    return 'Verfügbar um $time';
  }

  @override
  String get enableFreedomInSettings =>
      'Aktiviere die Freiheitskontrolle in den Einstellungen.';

  @override
  String get pauseStopwatch => 'Stoppuhr pausieren';

  @override
  String get resumeStopwatch => 'Stoppuhr fortsetzen';

  @override
  String get startStopwatch => 'Stoppuhr starten';

  @override
  String get keptLower => 'gehalten';

  @override
  String keepTask(String name) {
    return '$name halten';
  }

  @override
  String get recordedTimeLabel => 'Erfasste Zeit';

  @override
  String calendarDayExcusedNeutral(int count) {
    return 'Keine zählenden Vorsätze, $count entschuldigt, neutral';
  }

  @override
  String get calendarDayNeutral => 'Keine Vorsätze, neutral';

  @override
  String get calendarDayUnrecorded => 'Keine erfassten Vorsätze, neutral';

  @override
  String calendarDayProgress(int kept, int total, int percent, int excused) {
    return '$kept von $total zählenden Vorsätzen erledigt, $percent Prozent, $excused entschuldigt';
  }

  @override
  String get calendarTodaySuffix => ', heute';

  @override
  String calendarDayValue(String description, int count) {
    return '$description, $count Termine';
  }

  @override
  String get heatNeutral =>
      'Neutral: keine zählenden Vorsätze, fehlender Verlauf oder zukünftiges Datum';

  @override
  String get heatZero => 'Erfasste Vorsätze: 0 Prozent erledigt';

  @override
  String get heatLow => 'Mehr als 0 bis 25 Prozent erledigt';

  @override
  String get heatMedium => 'Mehr als 25 bis 50 Prozent erledigt';

  @override
  String get heatHigh => 'Mehr als 50 bis unter 100 Prozent erledigt';

  @override
  String get heatComplete => '100 Prozent erledigt';

  @override
  String get heatLess => 'Weniger';

  @override
  String get heatMore => 'Mehr';

  @override
  String get calTodayReadOnly =>
      'Heutige Vorsätze, schreibgeschützt. Verwalte sie unter Heute.';

  @override
  String get calHistoryReadOnly => 'Verlauf der Vorsätze, schreibgeschützt';

  @override
  String get calTodayLabel => 'Heutige Vorsätze';

  @override
  String get calHistoryLabel => 'Verlauf der Vorsätze';

  @override
  String get calNoHistory => 'Kein Verlauf erfasst.';

  @override
  String get calNoCommitmentsToday => 'Heute keine Vorsätze.';

  @override
  String get calNeutralDay => 'Keine Vorsätze erfasst. Neutraler Tag.';

  @override
  String get calCompletionLabel => 'Erledigte Vorsätze am gewählten Datum';

  @override
  String calRecordedTime(String duration) {
    return 'Erfasste Zeit: $duration';
  }

  @override
  String calCommitmentOutcome(String outcome) {
    return 'Vorsatz · $outcome';
  }

  @override
  String calReason(String reason) {
    return 'Grund: $reason';
  }

  @override
  String get calReadOnlyCached =>
      'Zwischengespeicherter Termin, schreibgeschützt';

  @override
  String editNamed(String name) {
    return '$name bearbeiten';
  }

  @override
  String deleteNamed(String name) {
    return '$name löschen';
  }

  @override
  String get deleteEventTitle => 'Termin löschen?';

  @override
  String deleteEventBody(String title) {
    return '„$title“ aus deinem Kalender löschen?';
  }

  @override
  String get calReadOnlyCachedShort => 'Schreibgeschützt · zwischengespeichert';

  @override
  String get close => 'Schließen';

  @override
  String get previousMonth => 'Vorheriger Monat';

  @override
  String get nextMonth => 'Nächster Monat';

  @override
  String get calendar => 'Kalender';

  @override
  String get calendarAccounts => 'Kalenderkonten';

  @override
  String get addEvent => 'Termin hinzufügen';

  @override
  String get scheduleLabel => 'Termine';

  @override
  String get noEventsScheduled => 'Keine Termine.';

  @override
  String get eventTimeFormat => 'Nutze HH:mm (00:00–23:59).';

  @override
  String get eventEndAfterStart => 'Das Ende muss nach dem Beginn liegen.';

  @override
  String get readOnlyEvent => 'Schreibgeschützter Termin';

  @override
  String get externalEventsReadOnly =>
      'Externe Termine können nur in ihrem Kalender geändert werden.';

  @override
  String get editEvent => 'Termin bearbeiten';

  @override
  String get title => 'Titel';

  @override
  String get enterTitle => 'Gib einen Titel ein.';

  @override
  String get startTimeOptional => 'Beginn (optional)';

  @override
  String get endTimeOptional => 'Ende (optional)';

  @override
  String get notesOptional => 'Notizen (optional)';

  @override
  String get saveEvent => 'Termin speichern';

  @override
  String get accountUpdateFailed =>
      'Dieses Konto konnte nicht aktualisiert werden. Zwischengespeicherte Termine sind weiter verfügbar. Versuche es erneut oder verbinde neu.';

  @override
  String get disconnectAccountTitle => 'Konto trennen?';

  @override
  String disconnectAccountBody(String name) {
    return '$name und die zwischengespeicherten Termine aus Daylock entfernen? Dein externer Kalender bleibt unverändert.';
  }

  @override
  String get disconnect => 'Trennen';

  @override
  String get externalCalendarsReadOnly =>
      'Externe Kalender sind schreibgeschützt. Zwischengespeicherte Termine sind offline verfügbar.';

  @override
  String get providersDisabled =>
      'Die Anmeldung ist für die deaktivierten Anbieter in dieser Version nicht verfügbar.';

  @override
  String connectProvider(String provider) {
    return '$provider verbinden';
  }

  @override
  String get noConnectedAccounts => 'Keine verbundenen Konten.';

  @override
  String get syncNow => 'Jetzt synchronisieren';

  @override
  String get reconnect => 'Neu verbinden';

  @override
  String get notSyncedYet => 'Noch nicht synchronisiert';

  @override
  String lastSynced(String when) {
    return 'Zuletzt synchronisiert $when';
  }

  @override
  String get syncToLoad =>
      'Synchronisiere, um die Kalender dieses Kontos zu laden.';

  @override
  String get chooseMonth => 'Monat wählen';

  @override
  String get previousYear => 'Vorheriges Jahr';

  @override
  String get year => 'Jahr';

  @override
  String get enterYear => 'Gib ein Jahr zwischen 1 und 9999 ein.';

  @override
  String get nextYear => 'Nächstes Jahr';

  @override
  String get showMonth => 'Monat anzeigen';

  @override
  String get commitment => 'Vorsatz';

  @override
  String repeatsLabel(String rule) {
    return 'Wiederholt sich: $rule';
  }

  @override
  String get areas => 'Bereiche';

  @override
  String get areasIntro =>
      'Gib deinen Vorsätzen ein Zuhause. Dein Standardbereich wird verwendet, wenn kein anderer gewählt ist.';

  @override
  String get createArea => 'Bereich erstellen';

  @override
  String get archived => 'Archiviert';

  @override
  String get defaultAlwaysAvailable => 'Standard · Immer verfügbar';

  @override
  String get restore => 'Wiederherstellen';

  @override
  String get archive => 'Archivieren';

  @override
  String get archivingExplainer =>
      'Beim Archivieren bleiben bestehende Vorsätze und Verlauf verknüpft. Neue Vorsätze nutzen nur aktive Bereiche.';

  @override
  String get editArea => 'Bereich bearbeiten';

  @override
  String get areaName => 'Name des Bereichs';

  @override
  String get icon => 'Symbol';

  @override
  String get colour => 'Farbe';

  @override
  String get saveArea => 'Bereich speichern';

  @override
  String get areaIconLife => 'Leben';

  @override
  String get areaColourLavender => 'Lavendel';

  @override
  String get areaIconHealth => 'Gesundheit';

  @override
  String get areaIconWork => 'Arbeit';

  @override
  String get areaIconLearning => 'Lernen';

  @override
  String get areaIconHome => 'Zuhause';

  @override
  String get areaIconPeople => 'Menschen';

  @override
  String get areaIconCreative => 'Kreativität';

  @override
  String get areaIconFitness => 'Fitness';

  @override
  String get areaColourBlue => 'Blau';

  @override
  String get areaColourTeal => 'Petrol';

  @override
  String get areaColourGreen => 'Grün';

  @override
  String get areaColourAmber => 'Bernstein';

  @override
  String get areaColourRose => 'Rosé';

  @override
  String get newAchievement => 'Neuer Erfolg';

  @override
  String get editAchievement => 'Erfolg bearbeiten';

  @override
  String get achievementPrompt => 'Worauf bist du stolz?';

  @override
  String get achievementHint => 'Führerscheinprüfung bestanden';

  @override
  String get achievementNotes => 'Ein paar Worte (optional)';

  @override
  String get linkToArea => 'Mit einem Bereich verknüpfen';

  @override
  String get optional => 'Optional';

  @override
  String get previousAreaUnavailable =>
      'Der vorherige Bereich ist nicht verfügbar. Wähle einen Bereich oder entferne die Verknüpfung.';

  @override
  String get saveAchievement => 'Erfolg speichern';

  @override
  String illustrationLabel(String name) {
    return 'Illustration: $name';
  }

  @override
  String illustrationAutomaticLabel(String name) {
    return 'Illustration: automatisch · $name';
  }

  @override
  String get illustrationHelp =>
      'Wähle einen Stil oder lass Titel und Bereich einen vorschlagen.';

  @override
  String get automatic => 'Automatisch';

  @override
  String get area => 'Bereich';

  @override
  String get notifExplainAndroid =>
      'Android-Erinnerungen können durch Energiesparen oder „Bitte nicht stören“ verzögert werden. Die App-Einstellungen unten sind unabhängig von der Systemberechtigung.';

  @override
  String get notifExplainError =>
      'Benachrichtigungen konnten nicht aktualisiert werden. Öffne Daylock erneut, um es noch einmal zu versuchen.';

  @override
  String get notifExplainDefault =>
      'Geplante Benachrichtigungen sind unter Android verfügbar.';

  @override
  String get notifExplainWebSupported =>
      'Dieser Browser unterstützt Benachrichtigungen, aber keine geplanten Erinnerungen. Safari, geschlossene Tabs und installierte PWAs können diese ohne Push-Dienst nicht empfangen. Nutze Daylock unter Android für geplante Benachrichtigungen.';

  @override
  String get notifExplainWebUnsupported =>
      'Dieser Browser kann keine Daylock-Benachrichtigungen empfangen. Geplante Erinnerungen gibt es in der Android-App; die Web-/PWA-Steuerung ist deaktiviert.';

  @override
  String get detectionReadFailed =>
      'Der Status der nativen Erkennung konnte nicht gelesen werden. Aktualisiere oder öffne die Android-Einstellungen manuell.';

  @override
  String get calFailAuthMicrosoft =>
      'Der Zugriff auf den Microsoft-Kalender muss erneuert werden. Verbinde dieses Konto neu. Deine Organisation verlangt eventuell die Zustimmung eines Administrators. Zwischengespeicherte Termine sind weiter verfügbar.';

  @override
  String get calFailAuthGoogle =>
      'Die Berechtigung für Google Kalender ist abgelaufen oder wurde entzogen. Verbinde dieses Konto neu. Zwischengespeicherte Termine sind weiter verfügbar.';

  @override
  String get calFailConfigMicrosoft =>
      'Die Microsoft-Anmeldung ist nicht richtig konfiguriert. Prüfe die Entra-Client-ID, die native Weiterleitungs-URI und die unterstützten Kontotypen.';

  @override
  String get calFailConfigGoogle =>
      'Die Google-Anmeldung ist nicht richtig konfiguriert. Prüfe die OAuth-Client-ID, das Android-Paket und das Signaturzertifikat.';

  @override
  String get calFailUnavailableMicrosoft =>
      'Der Microsoft-Kalender ist nicht verfügbar. Prüfe deine Verbindung und versuche es erneut. Arbeitskonten brauchen ein erreichbares Exchange-Postfach. Zwischengespeicherte Termine sind weiter verfügbar.';

  @override
  String get calFailUnavailableGoogle =>
      'Google Kalender ist nicht verfügbar. Prüfe deine Verbindung und synchronisiere erneut. Zwischengespeicherte Termine sind weiter verfügbar.';

  @override
  String get calFailResponseMicrosoft =>
      'Microsoft hat eine unvollständige oder nicht unterstützte Kalenderantwort geliefert. Zwischengespeicherte Termine sind weiter verfügbar. Versuche es später erneut.';

  @override
  String get calFailResponseGoogle =>
      'Google hat eine unvollständige oder nicht unterstützte Kalenderantwort geliefert. Zwischengespeicherte Termine sind weiter verfügbar. Versuche es später erneut.';

  @override
  String get calFailAdminConsent =>
      'Deine Organisation verlangt die Zustimmung eines Administrators oder schränkt diese Anmeldung ein. Wende dich an deine IT. Zwischengespeicherte Termine sind weiter verfügbar.';

  @override
  String get calFailAccountMismatch =>
      'Wähle beim erneuten Verbinden dasselbe Microsoft-Konto und dieselbe Organisation. Bestehende Konten und zwischengespeicherte Termine wurden behalten.';

  @override
  String get channelPlan => 'Morgen planen';

  @override
  String get channelCommitments => 'Vorsatz-Erinnerungen';

  @override
  String get channelFreedom => 'Freiheit';

  @override
  String get channelFocus => 'Laufende Stoppuhr';

  @override
  String get selectionLoadFailed =>
      'Eingeschränkte Apps konnten nicht geladen oder gespeichert werden. Die Einschränkungen sind pausiert. Aktualisiere, um es erneut zu versuchen.';

  @override
  String get selectionSaveFailed =>
      'Die App-Auswahl konnte nicht gespeichert werden. Die Einschränkungen sind pausiert. Aktualisiere, um es erneut zu versuchen.';
}

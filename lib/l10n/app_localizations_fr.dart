// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Daylock';

  @override
  String get appearanceDark => 'Sombre';

  @override
  String get appearanceLight => 'Clair';

  @override
  String get appearanceSystem => 'Système';

  @override
  String get colourViolet => 'Violet';

  @override
  String get colourOcean => 'Océan';

  @override
  String get colourForest => 'Forêt';

  @override
  String get colourEmber => 'Braise';

  @override
  String get colourRose => 'Rose';

  @override
  String get colourMono => 'Mono';

  @override
  String get illustrationCelebration => 'Fête';

  @override
  String get illustrationDriving => 'Conduite';

  @override
  String get illustrationAward => 'Récompense';

  @override
  String get illustrationCooking => 'Cuisine';

  @override
  String get illustrationTravel => 'Voyage';

  @override
  String get illustrationFitness => 'Sport';

  @override
  String get illustrationLearning => 'Apprentissage';

  @override
  String get illustrationHealth => 'Santé';

  @override
  String get illustrationWork => 'Travail';

  @override
  String get illustrationHome => 'Maison';

  @override
  String get illustrationPeople => 'Proches';

  @override
  String get illustrationCreativity => 'Créativité';

  @override
  String get illustrationSunrise => 'Lever du soleil';

  @override
  String get outcomeIncomplete => 'Non terminé';

  @override
  String get outcomeCompleted => 'Terminé';

  @override
  String get outcomeExcused => 'Excusé';

  @override
  String get sourceLocal => 'Local';

  @override
  String get sourceGoogle => 'Google Agenda';

  @override
  String get sourceMicrosoftPersonal => 'Microsoft personnel';

  @override
  String get sourceMicrosoftWorkSchool => 'Microsoft professionnel ou scolaire';

  @override
  String get freedomStateEarned => 'Gagnée';

  @override
  String get freedomStateNotEarned => 'Pas encore gagnée';

  @override
  String get freedomStateControlOff => 'Contrôle désactivé';

  @override
  String get freedomStateUnknown => 'Inconnu';

  @override
  String get listSeparator => ', ';

  @override
  String get repeatDaily => 'Tous les jours';

  @override
  String repeatEveryDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tous les $count jours',
      one: 'Tous les jours',
    );
    return '$_temp0';
  }

  @override
  String get repeatWeekdays => 'En semaine';

  @override
  String get repeatWeekends => 'Le week-end';

  @override
  String get eventContinuesAllDay => 'Toute la journée (suite)';

  @override
  String get eventEarlier => 'Avant';

  @override
  String get eventNextDay => 'Lendemain';

  @override
  String eventUntil(String time) {
    return 'Jusqu’à $time';
  }

  @override
  String get eventAllDay => 'Toute la journée';

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get durationUnderMinute => '<1 min';

  @override
  String durationHours(int hours) {
    return '$hours h';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get settingsFreedomControl => 'Contrôle de Liberté';

  @override
  String get settingsPlanningRoutines => 'Planification et routines';

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get settingsRestrictedApps => 'Applis restreintes';

  @override
  String get settingsPermissionsDiagnostics => 'Autorisations et diagnostic';

  @override
  String get settingsManageRoutines => 'Gérer les routines';

  @override
  String routineCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count routines',
      one: '$count routine',
    );
    return '$_temp0';
  }

  @override
  String get settingsRoutinesIntro =>
      'Planifiez vos prochaines étapes avec des engagements récurrents.';

  @override
  String get settingsNotificationsUnavailable =>
      'Les notifications ne sont pas disponibles sur cet appareil.';

  @override
  String get keepYourWord => 'Tenez parole.';

  @override
  String get settingsAboutCommitments =>
      'Des engagements, des chronomètres facultatifs et vos progrès dans ce qui compte.';

  @override
  String get settingsRestrictedIntro =>
      'Choisissez les applis Android à restreindre jusqu’à ce que la Liberté soit gagnée.';

  @override
  String get settingsRestrictionsAndroidOnly =>
      'Les restrictions d’applis sont disponibles sur Android.';

  @override
  String get settingsDiagnosticsAndroidOnly =>
      'Le diagnostic d’accessibilité est disponible sur Android.';

  @override
  String get freedomTime => 'Heure de Liberté';

  @override
  String get settingsRestrictionNeedsAttention =>
      'L’état des restrictions demande votre attention';

  @override
  String settingsSelectedSwitchOn(int count) {
    return '$count sélectionnée(s), activé';
  }

  @override
  String settingsSelectedSwitchOff(int count) {
    return '$count sélectionnée(s), désactivé';
  }

  @override
  String get accessibility => 'Accessibilité';

  @override
  String get statusUnavailable => 'État indisponible';

  @override
  String get availableOnAndroid => 'Disponible sur Android';

  @override
  String get serviceConnected => 'Service connecté';

  @override
  String get waitingForConnection => 'En attente de connexion';

  @override
  String get serviceDisabled => 'Service désactivé';

  @override
  String get settingsChooseInstalledApps =>
      'Choisir des applis Android installées';

  @override
  String get settingsFreedomSubtitle =>
      'Applis restreintes, Heure de Liberté et autorisations';

  @override
  String get on => 'Activé';

  @override
  String get off => 'Désactivé';

  @override
  String get settingsPlanningSubtitle =>
      'Engagements récurrents et planification';

  @override
  String get settingsAppearanceSubtitle => 'Thème, couleurs et domaines';

  @override
  String get settingsNotificationsSubtitle => 'Rappels et alertes';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsRunSetup => 'Relancer la configuration';

  @override
  String get settingsRunSetupSubtitle =>
      'Autorisations, distractions et premier engagement';

  @override
  String get settingsTakeTour => 'Faire la visite guidée';

  @override
  String get settingsTakeTourSubtitle =>
      'Un tour d’Aujourd’hui, de Planifier et de Parcours';

  @override
  String get settingsAboutSubtitle => 'Informations sur l’appli';

  @override
  String get tagline => 'Planifiez votre journée. Gagnez votre liberté.';

  @override
  String get freedomStatusUnavailable => 'État de la Liberté indisponible';

  @override
  String get freedomControlOff => 'Le Contrôle de Liberté est désactivé';

  @override
  String get appearanceFollowsDevice => 'Suit l’apparence de votre appareil.';

  @override
  String appearanceFixed(String mode) {
    return 'Apparence $mode, quel que soit le mode de l’appareil.';
  }

  @override
  String get appearanceColourTheme => 'Thème de couleur';

  @override
  String get appearanceLivePreview => 'Aperçu en direct';

  @override
  String get manageAreas => 'Gérer les domaines';

  @override
  String activeAreas(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count domaines actifs',
      one: '$count domaine actif',
    );
    return '$_temp0';
  }

  @override
  String get appearancePreviewLabel =>
      'Aperçu de l’apparence. Exemple de style d’engagement.';

  @override
  String get today => 'Aujourd’hui';

  @override
  String get appearancePreviewComplete => '1 / 2 terminé';

  @override
  String get appearancePreviewProgress => 'Exemple de progression';

  @override
  String get appearancePreviewRecorded => '23:00 enregistré';

  @override
  String keptTaskAnnouncement(String name) {
    return '$name tenu';
  }

  @override
  String todayEarnedTomorrowLocked(String weekday) {
    return 'Vous avez tenu parole et $weekday est déjà engagé. Profitez-en.';
  }

  @override
  String get todayEarned => 'Vous avez tenu parole. Profitez-en.';

  @override
  String get commitments => 'Engagements';

  @override
  String get taskActions => 'Actions de l’engagement';

  @override
  String get showFewerCommitments => 'Afficher moins d’engagements';

  @override
  String showAllCommitments(int count) {
    return 'Afficher les $count engagements';
  }

  @override
  String excusedCount(int count) {
    return '$count excusé(s)';
  }

  @override
  String keptName(String name) {
    return 'Tenu : $name';
  }

  @override
  String get undo => 'Annuler';

  @override
  String timedHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String timedMinutesSeconds(int minutes, int seconds) {
    return '$minutes min $seconds s';
  }

  @override
  String timedSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get noEligibleCommitments => 'Aucun engagement éligible';

  @override
  String keptOfEligible(int kept, int total) {
    return '$kept sur $total tenus';
  }

  @override
  String get excusedDontCount => 'Les engagements excusés ne comptent pas';

  @override
  String get dayComplete => 'Journée accomplie';

  @override
  String moreUntilSunUp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Encore $count et le soleil est levé',
      one: 'Encore $count et le soleil est levé',
    );
    return '$_temp0';
  }

  @override
  String timedSuffix(String duration) {
    return '$duration chronométrées';
  }

  @override
  String get commitmentsComplete => 'Engagements accomplis';

  @override
  String get todayRestrictionsInSettings =>
      'Les restrictions d’applis se règlent dans Réglages.';

  @override
  String get freedomEarned => 'Liberté gagnée';

  @override
  String get showFreedomDetails => 'Afficher le détail de la Liberté';

  @override
  String appsUnlockedAt(String time) {
    return 'Applis débloquées à $time';
  }

  @override
  String get freedomEarnedTitle => 'Liberté gagnée.';

  @override
  String get freedomNotYetEarned => 'Liberté pas encore gagnée';

  @override
  String get freedomOffDetail => 'Regagnez vos applis en tenant parole.';

  @override
  String get appsStayLockedToday => 'Les applis restent bloquées aujourd’hui';

  @override
  String get emptyDayDetail =>
      'Une journée vide ne fait pas gagner la Liberté. Engagez un plan pour demain.';

  @override
  String appsUnlockAt(String time) {
    return 'Applis débloquées à $time';
  }

  @override
  String keepMoreToEarn(int count) {
    return 'Encore $count à tenir pour la gagner';
  }

  @override
  String get commitTomorrowToEarn => 'Engagez le plan de demain pour la gagner';

  @override
  String get waitingForFreedomTime => 'En attendant l’Heure de Liberté';

  @override
  String everythingKeptUnlockAt(String time) {
    return 'Tout est tenu. Applis débloquées à $time';
  }

  @override
  String get turnOn => 'Activer';

  @override
  String get hideFreedomDetails => 'Masquer le détail de la Liberté';

  @override
  String get aClearDay => 'Une journée libre.';

  @override
  String allSetFor(String weekday) {
    return 'Tout est prêt pour $weekday.';
  }

  @override
  String get emptyTodayNoPlan =>
      'Aucun engagement aujourd’hui. Planifiez demain, et le soleil de demain ne dépendra que de vous.';

  @override
  String get emptyTodayLocked =>
      'Rien de prévu aujourd’hui, et demain est verrouillé. Le repos fait partie du plan.';

  @override
  String weekdayCommitmentCount(String weekday, int count) {
    return '$weekday : $count';
  }

  @override
  String get view => 'Voir';

  @override
  String get planTomorrow => 'Planifier demain';

  @override
  String get repeatNever => 'Jamais';

  @override
  String get repeatCustom => 'Personnalisé…';

  @override
  String get repeat => 'Répéter';

  @override
  String get repeatClose => 'Fermer les options de répétition';

  @override
  String get repeatDaysOfWeek => 'Jours de la semaine';

  @override
  String get repeatEveryNDays => 'Tous les N jours';

  @override
  String get repeatEvery => 'Tous les';

  @override
  String get repeatFewerDays => 'Moins de jours';

  @override
  String get repeatMoreDays => 'Plus de jours';

  @override
  String get repeatPickOneDay => 'Choisissez au moins un jour.';

  @override
  String get repeatOnlyThisDay => 'Uniquement ce jour. Pas de répétition.';

  @override
  String repeatNext(String dates) {
    return 'Prochains : $dates';
  }

  @override
  String get done => 'OK';

  @override
  String get editCommitment => 'Modifier l’engagement';

  @override
  String get saveChanges => 'Enregistrer';

  @override
  String get removeCommitmentTitle => 'Retirer l’engagement ?';

  @override
  String removeFromDraft(String name) {
    return 'Retirer $name du brouillon de demain ?';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get remove => 'Retirer';

  @override
  String areaFor(String name) {
    return 'Domaine de $name';
  }

  @override
  String lockInWeekdayQuestion(String weekday) {
    return 'Verrouiller $weekday ?';
  }

  @override
  String lockInConfirmOne(String weekday) {
    return 'Votre engagement pour $weekday sera verrouillé. Vous ne pourrez plus le modifier ni en ajouter.';
  }

  @override
  String lockInConfirmMany(int count, String weekday) {
    return 'Vos $count engagements pour $weekday seront verrouillés. Vous ne pourrez plus les modifier ni en ajouter.';
  }

  @override
  String get keepPlanning => 'Continuer à planifier';

  @override
  String get lockItIn => 'Verrouiller';

  @override
  String get plan => 'Planifier';

  @override
  String tomorrowDate(String date) {
    return 'Demain · $date';
  }

  @override
  String get committed => 'Engagé';

  @override
  String get draft => 'Brouillon';

  @override
  String get schedule => 'Agenda';

  @override
  String get noScheduledEventsTomorrow => 'Aucun événement prévu demain.';

  @override
  String scheduledEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count événements prévus',
      one: '$count événement prévu',
    );
    return '$_temp0';
  }

  @override
  String commitmentsCount(int count) {
    return 'Engagements · $count';
  }

  @override
  String get add => 'Ajouter';

  @override
  String get addACommitment => 'Ajouter un engagement';

  @override
  String get noCommitmentsPlanned => 'Aucun engagement prévu pour l’instant.';

  @override
  String get tomorrowIsLocked => 'Demain est verrouillé.';

  @override
  String get addOneSmallStep => 'Ajoutez un petit pas pour demain.';

  @override
  String lockInWeekday(String weekday) {
    return 'Verrouiller $weekday';
  }

  @override
  String addOneToLockIn(String weekday) {
    return 'Ajoutez au moins un engagement pour verrouiller $weekday.';
  }

  @override
  String get locksThisCommitment =>
      'Verrouille cet engagement. Vous ne pourrez plus le modifier.';

  @override
  String locksTheseCommitments(int count) {
    return 'Verrouille ces $count engagements. Vous ne pourrez plus les modifier.';
  }

  @override
  String archivedArea(String name) {
    return '$name (archivé)';
  }

  @override
  String actionsFor(String name) {
    return 'Actions pour $name';
  }

  @override
  String get removeCommitment => 'Retirer l’engagement';

  @override
  String get tomorrowPlanCommitted => 'Le plan de demain est engagé.';

  @override
  String get yourCommitmentsLocked => 'Vos engagements sont verrouillés.';

  @override
  String get nextTomorrow => 'prochain : demain';

  @override
  String nextDate(String date) {
    return 'prochain : $date';
  }

  @override
  String rotationSummary(int count, String name) {
    return '$count étapes · ensuite : $name';
  }

  @override
  String get deleteRoutineTitle => 'Supprimer la routine ?';

  @override
  String deleteRoutineBody(String name) {
    return 'Ne plus répéter $name ? Les engagements déjà dans vos plans et votre historique restent.';
  }

  @override
  String get delete => 'Supprimer';

  @override
  String get routines => 'Routines';

  @override
  String get routinesIntro =>
      'Les routines s’ajoutent d’elles-mêmes au plan de demain les jours prévus. Retirez-en une d’un plan pour sauter seulement ce jour-là. Une rotation à plusieurs étapes n’avance que lorsqu’une étape reste dans votre plan.';

  @override
  String get createRoutineOrRotation => 'Créer une routine ou une rotation';

  @override
  String get noRoutinesYet => 'Aucune routine pour l’instant.';

  @override
  String get edit => 'Modifier';

  @override
  String get newRoutineStep => 'Nouvelle étape';

  @override
  String get editRoutineStep => 'Modifier l’étape';

  @override
  String get addStep => 'Ajouter l’étape';

  @override
  String get saveStep => 'Enregistrer l’étape';

  @override
  String get createRoutine => 'Créer une routine';

  @override
  String get editRoutine => 'Modifier la routine';

  @override
  String get routineName => 'Nom de la routine';

  @override
  String get routineRotationHelp =>
      'Une rotation : chaque jour prévu ajoute l’étape suivante, dans cet ordre. Une étape retirée revient la fois suivante.';

  @override
  String get routineSingleHelp =>
      'Chaque jour prévu l’ajoute automatiquement au plan de demain. Ajoutez des étapes pour créer une rotation.';

  @override
  String editStepN(int number) {
    return 'Modifier l’étape $number';
  }

  @override
  String moveStepUp(int number) {
    return 'Monter l’étape $number';
  }

  @override
  String moveStepDown(int number) {
    return 'Descendre l’étape $number';
  }

  @override
  String removeStepN(int number) {
    return 'Retirer l’étape $number';
  }

  @override
  String get addCommitment => 'Ajouter l’engagement';

  @override
  String get addRotationStep => 'Ajouter une étape';

  @override
  String get saveRoutine => 'Enregistrer la routine';

  @override
  String get newCommitment => 'Nouvel engagement';

  @override
  String get partOfRotation =>
      'Fait partie d’une rotation. Modifiez-la dans Routines.';

  @override
  String get commitmentHint => 'Un petit pas précis';

  @override
  String get closeEditor => 'Fermer l’éditeur';

  @override
  String get commitmentName => 'Nom de l’engagement';

  @override
  String get statusKept => 'Tenu';

  @override
  String get statusNotKeptYet => 'Pas encore tenu';

  @override
  String durationRecorded(String duration) {
    return '$duration enregistrées';
  }

  @override
  String get excuseReason => 'Motif de l’excuse';

  @override
  String get markCompleted => 'Marquer comme terminé';

  @override
  String get excuseTask => 'Excuser';

  @override
  String get resetToIncomplete => 'Remettre à non terminé';

  @override
  String get excuseCommitment => 'Excuser l’engagement';

  @override
  String get excusePrompt =>
      'Quelle circonstance extérieure vous a empêché de le tenir ?';

  @override
  String get reason => 'Motif';

  @override
  String get enterShortReason => 'Indiquez un court motif.';

  @override
  String get shortenReason => 'Raccourcissez ce motif.';

  @override
  String durationMinutesSeconds(int minutes, int seconds) {
    return '$minutes min $seconds s';
  }

  @override
  String get loadFailed => 'Impossible de charger vos engagements enregistrés.';

  @override
  String get loadingDay => 'Préparation de votre journée.';

  @override
  String get retry => 'Réessayer';

  @override
  String get loadingCommitments => 'Chargement des engagements';

  @override
  String get journey => 'Parcours';

  @override
  String dayStreakLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Série de $count jours',
      one: 'Série de $count jour',
    );
    return '$_temp0';
  }

  @override
  String dayStreakWord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'jours de série',
      one: 'jour de série',
    );
    return '$_temp0';
  }

  @override
  String get streakStartHint => 'Tenez toute la journée pour en commencer une';

  @override
  String get streakLongestYet => 'Votre meilleure série';

  @override
  String streakLongest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Record : $count jours',
      one: 'Record : $count jour',
    );
    return '$_temp0';
  }

  @override
  String get totalKept => 'tenus';

  @override
  String get totalFocused => 'chronométrés';

  @override
  String shortMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String shortHours(int hours) {
    return '$hours h';
  }

  @override
  String get achievements => 'Réussites';

  @override
  String seeAll(int count) {
    return 'Tout voir ($count)';
  }

  @override
  String get addAchievement => 'Ajouter une réussite';

  @override
  String get last5Weeks => '5 dernières semaines';

  @override
  String get dailyHistory => 'Historique quotidien';

  @override
  String get yourAreas => 'Vos domaines';

  @override
  String get manage => 'Gérer';

  @override
  String get pastChapters => 'Chapitres passés';

  @override
  String get areasArchived => 'Domaines archivés';

  @override
  String achievementSemantics(String title, String date) {
    return 'Réussite : $title, $date';
  }

  @override
  String get areaUnavailable => 'Domaine indisponible';

  @override
  String get keepAMoment => 'Gardez un moment qui compte.';

  @override
  String get addAnAchievement => 'Ajouter une réussite';

  @override
  String get achievementExamples =>
      'Un permis de conduire, un premier 10 km, un chapitre terminé.';

  @override
  String last5WeeksKept(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '5 dernières semaines : $count jours entièrement tenus',
      one: '5 dernières semaines : $count jour entièrement tenu',
    );
    return '$_temp0';
  }

  @override
  String get legendAllKept => 'Tout tenu';

  @override
  String get legendSomeKept => 'En partie';

  @override
  String get legendMissed => 'Manqué';

  @override
  String keptThisWeek(int count) {
    return '$count cette semaine';
  }

  @override
  String areaKeptThisWeek(String area, int count) {
    return '$area : $count tenu(s) cette semaine';
  }

  @override
  String get last30Days => '30 derniers jours';

  @override
  String get allTime => 'Depuis le début';

  @override
  String completedCommitments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count engagements terminés',
      one: '$count engagement terminé',
    );
    return '$_temp0';
  }

  @override
  String recordedTime(String duration) {
    return '$duration de temps enregistré';
  }

  @override
  String get stopwatchExplainer =>
      'Le chronomètre mesure l’effort réel, y compris pour les engagements non terminés.';

  @override
  String get activityOverTime => 'Activité dans le temps';

  @override
  String get trackedTime => 'Temps suivi';

  @override
  String get achievementsPlace =>
      'Un endroit pour les moments dont vous voulez vous souvenir.';

  @override
  String get recordedCommitments => 'Engagements enregistrés';

  @override
  String recordsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entrées',
      one: '$count entrée',
    );
    return '$_temp0';
  }

  @override
  String get recordsEmpty => 'Vos engagements enregistrés apparaîtront ici.';

  @override
  String get recordedTimeEmpty => 'Le temps enregistré apparaîtra ici.';

  @override
  String get completedEmpty => 'Les engagements terminés apparaîtront ici.';

  @override
  String get activityDetails => 'Détail de l’activité';

  @override
  String activityRange(String from, String through, String value) {
    return 'Du $from au $through : $value';
  }

  @override
  String activityDescriptionTime(String days) {
    return '30 derniers jours, temps enregistré. $days';
  }

  @override
  String activityDescriptionCompleted(String days) {
    return '30 derniers jours, engagements terminés. $days';
  }

  @override
  String get thirtyDaysTime => '30 jours · temps';

  @override
  String get thirtyDaysCompleted => '30 jours · terminés';

  @override
  String completedCount(int count) {
    return '$count terminé(s)';
  }

  @override
  String get openSpace => 'Espace libre';

  @override
  String get openArea => 'Ouvrir le domaine';

  @override
  String get latestAchievement => 'Dernière réussite';

  @override
  String get pastChaptersIntro =>
      'Des parts de votre vie, gardées ici pour y revenir.';

  @override
  String get pastChaptersEmpty =>
      'Les domaines archivés resteront ici, avec leur historique.';

  @override
  String get savePendingBeforeStopwatch =>
      'Enregistrez vos modifications avant de changer un chronomètre.';

  @override
  String get couldNotSaveAppearance => 'Impossible d’enregistrer l’apparence.';

  @override
  String get couldNotSaveSetup =>
      'Impossible d’enregistrer la configuration. Réessayez depuis Réglages.';

  @override
  String get tomorrowAlreadyCommitted =>
      'Le plan de demain est déjà engagé. Les engagements existants sont conservés. Ajoutez-en un autre quand le jour suivant aura commencé.';

  @override
  String get firstCommitmentHeading => 'Votre premier engagement · demain';

  @override
  String pausedTask(String name) {
    return '$name en pause.';
  }

  @override
  String removedForWeekday(String weekday) {
    return 'Retiré pour $weekday.';
  }

  @override
  String get stopRepeating => 'Ne plus répéter';

  @override
  String get stoppedRepeating => 'Répétition arrêtée.';

  @override
  String get achievementsIntro =>
      'Ce dont vous êtes fier : un permis de conduire, un premier 10 km, un chapitre terminé.';

  @override
  String get achievement => 'Réussite';

  @override
  String get achievementRemoved => 'Cette réussite a été supprimée.';

  @override
  String get deleteAchievementTitle => 'Supprimer la réussite ?';

  @override
  String deleteAchievementBody(String title) {
    return 'Supprimer « $title » ? Vos engagements et domaines restent tels quels.';
  }

  @override
  String get keepAchievement => 'Garder la réussite';

  @override
  String get couldNotSaveChanges =>
      'Impossible d’enregistrer vos modifications.';

  @override
  String get tourDayTitle => 'Voici votre journée';

  @override
  String get tourDayBody =>
      'Le soleil monte à mesure que vous tenez vos engagements du jour. Tenez-les tous et il est au zénith.';

  @override
  String get tourCommitmentsTitle => 'Les engagements du jour';

  @override
  String get tourCommitmentsBody =>
      'Touchez le cercle pour en tenir un. Touchez la ligne pour lancer un chronomètre, ou excusez-le avec un motif si un imprévu est vraiment arrivé.';

  @override
  String get tourFreedomTitle => 'Liberté';

  @override
  String get tourFreedomBody =>
      'Les applis restreintes s’ouvrent à l’Heure de Liberté, une fois la journée tenue et demain verrouillé. Touchez ici à tout moment pour voir ce qu’il reste.';

  @override
  String get tourPlanTitle => 'Planifier demain';

  @override
  String get tourPlanBody =>
      'Chaque soir, planifiez demain tant que la journée est fraîche. Choisissez quelques choses que vous ferez vraiment.';

  @override
  String get tourAddTitle => 'Ajouter et répéter';

  @override
  String get tourAddBody =>
      'Ajoutez un engagement et donnez-lui un domaine. Activez Répéter pour vos habitudes : elles se remplissent toutes seules les jours voulus.';

  @override
  String get tourLockTitle => 'Verrouillez';

  @override
  String get tourLockBody =>
      'Quand demain vous convient, verrouillez-le. Ensuite, plus de changement possible. C’est ce qui en fait un engagement.';

  @override
  String get tourJourneyTitle => 'Votre parcours';

  @override
  String get tourJourneyBody =>
      'Chaque journée tenue compte ici : votre série, l’effort fourni et les réussites dont vous êtes fier.';

  @override
  String get tourAreasTitle => 'Domaines';

  @override
  String get tourAreasBody =>
      'Chaque domaine suit une part de votre vie, comme le Corps, l’Esprit ou la Carrière. Ajoutez-les, renommez-les ou archivez-les ici. Plus bas, ouvrez-en un pour voir son historique.';

  @override
  String get tourSettingsTitle => 'Réglages';

  @override
  String get tourSettingsBody =>
      'Heure de Liberté, blocage des applis, routines, rappels et couleurs se règlent ici. Vous pouvez aussi relancer cette visite depuis Réglages.';

  @override
  String stepOf(int current, int total) {
    return '$current sur $total';
  }

  @override
  String get skipTour => 'Passer la visite';

  @override
  String get back => 'Retour';

  @override
  String get next => 'Suivant';

  @override
  String tourStepSemantics(int current, int total) {
    return 'Visite guidée, étape $current sur $total';
  }

  @override
  String get setupTourBody =>
      'Nous parcourrons les vrais écrans Aujourd’hui, Planifier et Parcours en montrant à quoi sert chaque partie. Cela prend environ une minute, et vous pouvez passer à tout moment.';

  @override
  String get setupTestBody =>
      'Ouvrez une appli sélectionnée et vérifiez que l’écran de verrouillage de Daylock apparaît. Revenez ici pour voir le résultat. Ouvrez-la aussi normalement depuis l’écran d’accueil après avoir laissé Daylock en arrière-plan : ce test ne confirme qu’une seule ouverture. Il utilise vos vraies conditions de Liberté et ne termine jamais un objectif à votre place.';

  @override
  String get setupFirstCommitmentBody =>
      'Le plan d’aujourd’hui est déjà verrouillé. Votre premier nouvel engagement va dans le vrai plan de demain. Les applis se débloquent quand tous les engagements éligibles sont tenus, que l’Heure de Liberté est atteinte et que le plan de demain est engagé. Une journée vide ne fait pas gagner la Liberté.';

  @override
  String get setupAccessibilityOemHelp =>
      'Sur Xiaomi / HyperOS, Samsung et Pixel, les noms des réglages varient. Choisissez le service de cette appli Daylock installée. Si « Paramètres restreints » apparaît, consultez Infos sur l’appli → Autoriser les paramètres restreints, uniquement pour une version de confiance. Si le service est activé mais déconnecté, désactivez-le puis réactivez-le une fois.';

  @override
  String get setupAccessibilityExplain =>
      'Daylock détecte l’ouverture d’une appli sélectionnée et peut afficher son écran de verrouillage ou revenir à l’écran d’accueil. Le contenu de l’écran n’est jamais lu. L’accès est facultatif et peut être retiré dans les paramètres Android.';

  @override
  String get setupBlockingOptional =>
      'Le blocage des applis est facultatif. Sans lui, Daylock planifie quand même vos journées et suit vos engagements. Vous pourrez l’activer plus tard dans Réglages.';

  @override
  String get setupXiaomiBody =>
      'HyperOS peut mettre Daylock en pause en arrière-plan, même quand l’Accessibilité apparaît activée. Un test dans Daylock peut fonctionner alors qu’une ouverture d’Instagram depuis l’écran d’accueil ne l’est pas.\n\nDans les infos de cette appli :\n• Démarrage automatique : activé\n• Économiseur de batterie (ou Alimentation) : Aucune restriction\n• Autres autorisations → Afficher des fenêtres pop-up en arrière-plan : autoriser\n\nBalayer Daylock dans les applis récentes ou utiliser « Nettoyer » peut quand même arrêter le blocage. Dans ce cas, Aujourd’hui affiche un avertissement : désactivez puis réactivez Daylock dans l’Accessibilité.\n\nUtilisez les réglages de cette appli Daylock installée ; Daylock Dev et la version Play ont des réglages distincts. Daylock ne peut pas lire ces choix Xiaomi. Confirmez-les vous-même ci-dessous, puis testez aussi des ouvertures normales.';

  @override
  String get setupLockNotConfirmed =>
      'Écran de verrouillage non confirmé. Vérifiez que l’Accessibilité est connectée, puis réessayez. Android peut revenir à l’écran d’accueil ou restreindre l’ouverture de l’écran de verrouillage. Ouvrez Autorisations et diagnostic dans Réglages pour voir le résultat enregistré.';

  @override
  String get setupVerified =>
      'Vérifié : Android a affiché l’écran de verrouillage de Daylock.';

  @override
  String get setupSaveProgressFailed =>
      'Impossible d’enregistrer la progression. Réessayez.';

  @override
  String get setupOpeningApp =>
      'Ouverture de l’appli sélectionnée. Revenez dans Daylock après avoir vérifié l’écran de verrouillage.';

  @override
  String get setupSaveConfirmationFailed =>
      'Impossible d’enregistrer votre confirmation. Réessayez.';

  @override
  String get setupWelcomeBody =>
      'Planifiez votre journée. Gagnez votre liberté. Tenez vos engagements avant que vos applis de distraction ne se débloquent.';

  @override
  String get setupWelcomePlan =>
      'Choisissez la veille quelques engagements qui comptent.';

  @override
  String get setupBlockDistractions => 'Bloquer les distractions';

  @override
  String get setupWelcomeBlock => 'Vous choisissez les applis à restreindre.';

  @override
  String get setupKeepYourWord => 'Tenir parole';

  @override
  String get setupWelcomeKeep =>
      'Tenez les engagements du jour, puis verrouillez le plan de demain.';

  @override
  String get setupUnlockApps => 'Débloquer les applis';

  @override
  String get setupWelcomeUnlock =>
      'Atteignez votre Heure de Liberté et profitez de la pause méritée.';

  @override
  String get setupXiaomiTitle => 'Xiaomi / Poco : garder le blocage actif';

  @override
  String get setupOpenAppInfo => 'Ouvrir les infos de Daylock';

  @override
  String get setupXiaomiConfirm =>
      'J’ai modifié ces réglages pour cette appli Daylock';

  @override
  String get setupXiaomiConfirmNote =>
      'Votre confirmation ; non vérifiée automatiquement.';

  @override
  String get setupAccessibilityTitle => 'Accès Accessibilité · facultatif';

  @override
  String get setupBlockingAndroidOnly =>
      'Le blocage est disponible sur Android. Vous pouvez quand même utiliser le planificateur ici.';

  @override
  String get setupAccessibilityConnected =>
      'Activé et connecté. Daylock est prêt à détecter les applis sélectionnées.';

  @override
  String get setupAccessibilityWaiting =>
      'Activé. En attente de la connexion du service par Android. Touchez Actualiser à votre retour.';

  @override
  String get setupEnableAccessibility => 'Activer l’Accessibilité';

  @override
  String get setupNotificationsTitle => 'Notifications · facultatif';

  @override
  String get setupNotificationsAllowed =>
      'Autorisées. Des rappels locaux et des avis de restriction de secours peuvent apparaître.';

  @override
  String get setupNotificationsExplain =>
      'Autorisez les rappels locaux et un avis quand Android ne peut pas afficher l’écran de verrouillage. Vous pouvez continuer sans notifications.';

  @override
  String get setupAllowNotifications => 'Autoriser les notifications';

  @override
  String get setupRefreshPermissions => 'Actualiser l’état des autorisations';

  @override
  String get setupChooseAppsBody =>
      'Choisissez les applis que vous voulez ouvrir plus consciemment. Vos choix restent sur cet appareil.';

  @override
  String get setupRestrictionsEnableFreedom =>
      'Activer les restrictions ici active aussi le Contrôle de Liberté à votre Heure de Liberté enregistrée.';

  @override
  String get setupSaveBlockingFailed =>
      'Impossible d’enregistrer les réglages de blocage. Réessayez.';

  @override
  String get setupAppSelectionAndroidOnly =>
      'Le choix des applis installées est disponible sur Android.';

  @override
  String get setupOneSmallStep => 'Un petit pas pour demain';

  @override
  String get setupSaveCommitmentFailed =>
      'Impossible d’enregistrer votre engagement. Réessayez.';

  @override
  String get setupCreateCommitment => 'Créer un engagement';

  @override
  String get setupAlreadyHasCommitment =>
      'Votre plan contient déjà un engagement. Vous pouvez continuer sans en créer un autre.';

  @override
  String get setupTestTitle => 'Testez votre vraie restriction';

  @override
  String get setupTestAndroidOnly =>
      'Les tests de blocage nécessitent l’appli Android.';

  @override
  String get setupChecking => 'Vérification…';

  @override
  String get setupTestSelectedApp => 'Tester une appli sélectionnée';

  @override
  String get setupEnableFreedomAndRestrictions =>
      'Activer le Contrôle de Liberté et les restrictions';

  @override
  String setupTestNeedsFreedom(String state) {
    return 'Liberté actuelle : $state. Le vrai test exige que le Contrôle de Liberté soit activé et que la Liberté ne soit pas encore gagnée. Vous pouvez quitter la configuration et revenir depuis Réglages quand ces conditions sont réunies.';
  }

  @override
  String get setupAccessibilityNotConnected =>
      'L’Accessibilité n’est pas connectée. Revenez à la configuration des autorisations.';

  @override
  String get setupConfirmXiaomi =>
      'Revenez à Configurer le blocage et confirmez le réglage de batterie Xiaomi pour que le blocage continue de fonctionner.';

  @override
  String get setupRefreshRetry => 'Actualiser et réessayer';

  @override
  String get setupReadyTitle => 'Faites de la place pour l’essentiel';

  @override
  String get setupReadyBody =>
      'Vos préférences et votre engagement sont enregistrés. Commencez par Aujourd’hui, planifiez demain, et regardez votre Parcours grandir.';

  @override
  String get setupTourTitle => 'Faites une visite rapide';

  @override
  String get setupBlockingOff => 'Le blocage des applis est désactivé';

  @override
  String get setupBlockingOffBody =>
      'Daylock ne restreindra aucune appli. Si vous le voulez plus tard, ouvrez Réglages et activez les restrictions d’applis.';

  @override
  String get setupSkipTour => 'Passer la visite';

  @override
  String get previousStep => 'Étape précédente';

  @override
  String get saveAndLeave => 'Enregistrer et quitter';

  @override
  String stepNOfM(int current, int total) {
    return 'Étape $current sur $total';
  }

  @override
  String get getStarted => 'Commencer';

  @override
  String get continueWithoutBlocking => 'Continuer sans blocage';

  @override
  String get skipTestForNow => 'Passer le test pour l’instant';

  @override
  String get finishSetup => 'Terminer la configuration';

  @override
  String get takeTheTour => 'Faire la visite';

  @override
  String get goToDaylock => 'Aller dans Daylock';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get setupTitleWelcome => 'Reprenez le contrôle';

  @override
  String get setupTitleBlocking => 'Configurer le blocage';

  @override
  String get setupTitleApps => 'Choisissez vos distractions';

  @override
  String get setupTitleCommitment => 'Votre premier engagement';

  @override
  String get setupTitleTest => 'Vous y êtes presque !';

  @override
  String get setupTitleReady => 'Tout est prêt !';

  @override
  String get diagLockUnconfirmed =>
      'Écran de verrouillage : non confirmé ; une notification de secours peut être utilisée.';

  @override
  String get diagLockFailedException =>
      'Écran de verrouillage : Android a refusé ou fait échouer l’ouverture.';

  @override
  String get diagLockShown => 'Écran de verrouillage : visible et confirmé.';

  @override
  String get diagLockRequestedUnconfirmed =>
      'Écran de verrouillage : demande transmise ; affichage pas encore confirmé.';

  @override
  String get diagLockAttempted => 'Écran de verrouillage : ouverture demandée.';

  @override
  String get diagHomeRejected =>
      'Retour à l’accueil : Android a refusé la demande.';

  @override
  String get diagHomeAccepted =>
      'Retour à l’accueil : Android a accepté la demande.';

  @override
  String get diagHomeAttempted => 'Retour à l’accueil : demandé.';

  @override
  String get diagRestrictionOther =>
      'Impossible de vérifier le dernier état de restriction.';

  @override
  String get diagRestrictionSkippedLaunchThrottled =>
      'Restriction ignorée : un écran de verrouillage est déjà en cours d’ouverture.';

  @override
  String get diagRestrictionSkippedFreedomDisabled =>
      'Restriction ignorée : le Contrôle de Liberté est désactivé.';

  @override
  String get diagRestrictionSkippedFreedomEarned =>
      'Restriction ignorée : la Liberté est gagnée.';

  @override
  String get diagRestrictionSkippedStateChanged =>
      'Restriction ignorée : l’état de la Liberté a changé pendant l’ouverture de l’appli.';

  @override
  String get diagRestrictionRetryingStateChanged =>
      'L’état de la Liberté a changé pendant l’application ; nouvelle vérification.';

  @override
  String get diagRestrictionSkippedLockAlreadyVisible =>
      'Restriction ignorée : un écran de verrouillage Daylock était déjà visible.';

  @override
  String get diagRestrictionSkippedServiceInactive =>
      'Restriction ignorée : le service d’Accessibilité n’était plus actif.';

  @override
  String get diagRestrictionSkippedDeviceNotInteractive =>
      'Restriction ignorée : l’appareil était verrouillé ou inactif.';

  @override
  String get diagRestrictionSkippedSelectionUnavailable =>
      'Restriction ignorée : l’appli sélectionnée n’a pas pu être vérifiée.';

  @override
  String get diagRestrictionSkippedAccessibilityDisabled =>
      'Restriction ignorée : l’Accessibilité n’est plus activée.';

  @override
  String get diagRestrictionSkippedForegroundChangedBeforeNavigation =>
      'Restriction ignorée : l’appli au premier plan a changé avant l’application.';

  @override
  String get diagRestrictionHomeFailed =>
      'Dernière tentative : Android a refusé le retour à l’accueil. La restriction n’a pas pu être appliquée.';

  @override
  String get diagRestrictionLockLaunchUnconfirmed =>
      'Dernière tentative : écran de verrouillage non confirmé. Android peut restreindre les ouvertures en arrière-plan.';

  @override
  String get diagRestrictionHomeOnly =>
      'Dernière tentative : retour à l’accueil demandé ; écran de verrouillage non confirmé.';

  @override
  String get diagRestrictionLockFallbackUnavailable =>
      'Dernière tentative : écran de verrouillage non confirmé. Autorisez les notifications et le canal Avis de restriction dans les paramètres Android pour recevoir les avis de secours.';

  @override
  String get diagRestrictionLockFallbackPosted =>
      'Dernière tentative : écran de verrouillage non confirmé ; notification de restriction envoyée. Android gère sa remise.';

  @override
  String get diagRestrictionLockLaunchRequested =>
      'Dernière tentative : écran de verrouillage demandé ; affichage pas encore confirmé.';

  @override
  String get diagRestrictionStateUnknown =>
      'Dernière tentative : applis sélectionnées autorisées car l’état de la Liberté était indisponible.';

  @override
  String get diagRestrictionLockShown =>
      'Dernière tentative : écran de verrouillage Daylock affiché.';

  @override
  String get diagRestrictionRecoveryShown =>
      'Dernière tentative : écran de récupération affiché. Ouvrez Daylock pour actualiser les plans ou désactiver le blocage.';

  @override
  String get diagRestrictionRestrictionRecovery =>
      'La restriction nécessite que Daylock actualise l’état de la Liberté.';

  @override
  String get diagRestrictionRestrictionTriggered =>
      'Restriction déclenchée : ouverture du verrouillage Daylock.';

  @override
  String get diagRestrictionEligibilityUnknown =>
      'Éligibilité non confirmée ; le blocage est mis en pause par sécurité.';

  @override
  String get diagRestrictionEligibilityDisabled =>
      'Éligibilité évaluée : le Contrôle de Liberté est désactivé ; l’appli est autorisée.';

  @override
  String get diagRestrictionEligibilityEarned =>
      'Éligibilité évaluée : la Liberté est gagnée ; l’appli est autorisée.';

  @override
  String get diagRestrictionEligibilityNotEarned =>
      'Éligibilité évaluée : la Liberté n’est pas gagnée.';

  @override
  String get diagRestrictionDetectedSelectedApp =>
      'Appli sélectionnée détectée. Vérification de la Liberté et de la restriction.';

  @override
  String get diagRestrictionTestRequested =>
      'Test demandé : en attente d’une nouvelle détection d’appli sélectionnée.';

  @override
  String get diagRestrictionSkippedEventDelayed =>
      'Android a signalé l’ouverture de l’appli trop tard. Sur Xiaomi / HyperOS, vérifiez Infos sur l’appli Daylock → Alimentation → Aucune restriction, puis testez l’ouverture d’une appli sélectionnée depuis l’écran d’accueil.';

  @override
  String get diagRestrictionNone =>
      'Aucune tentative de restriction pour l’instant.';

  @override
  String get diagEnableBlockingBody =>
      'Quand le Contrôle de Liberté est activé et que la Liberté n’est pas gagnée, Daylock utilise l’Accessibilité pour quitter une appli sélectionnée et afficher son propre écran de verrouillage. La liste des applis installées et vos choix restent sur cet appareil. Daylock ne lit pas le contenu de l’écran et ne collecte pas l’historique de navigation. Seuls la dernière détection et le dernier résultat de restriction restent sur cet appareil. Les autres noms de paquets de fenêtres ne sont comparés que pour annuler une action en attente si vous changez d’appli ; ils ne sont pas conservés. Vous pouvez désactiver le blocage ici ou retirer l’accès Accessibilité à tout moment.\n\nLes données de Liberté restent valables pour leur date sans rouvrir Daylock. Si l’état actuel manque ou n’est pas valide, Daylock propose un écran de récupération avec Ouvrir Daylock et Désactiver le blocage ; les ouvertures suivantes sont autorisées tant qu’une récupération est nécessaire. Il s’agit d’une restriction volontaire, pas d’un système inviolable ni d’un contrôle parental.';

  @override
  String get diagPermissionBody =>
      'Daylock utilise l’Accessibilité Android pour détecter l’ouverture d’une appli sélectionnée, y compris quand Daylock est en arrière-plan. Il n’enregistre que la dernière détection, l’état de la Liberté et le résultat de la restriction sur cet appareil ; rien n’est envoyé à un serveur. La liste des applis installées et vos choix restent sur cet appareil. Il ne lit pas le contenu de l’écran et ne collecte pas l’historique de navigation. Avec l’interrupteur des restrictions activé, il peut revenir à l’écran d’accueil et afficher un écran de verrouillage Daylock quand la Liberté n’est pas gagnée. Les changements de fenêtre ne sont comparés que pour annuler une action si vous changez d’appli ; les autres noms d’applis ne sont pas conservés. Il n’affiche pas de superposition et ne restreint pas les applis non sélectionnées.\n\nC’est vous qui choisissez d’activer « Restrictions d’applis Daylock » dans les paramètres d’Accessibilité Android. Vous pouvez le désactiver à tout moment.';

  @override
  String get diagPermissionTitle => 'Autorisation de restriction des applis';

  @override
  String get diagAgreeOpenSettings => 'Accepter et ouvrir les paramètres';

  @override
  String get diagEnableBlockingTitle => 'Activer les restrictions d’applis ?';

  @override
  String get diagEnableBlocking => 'Activer le blocage';

  @override
  String get diagAppRestrictionsLabel => 'Restrictions d’applis';

  @override
  String get diagAppRestrictionsIntro =>
      'L’Accessibilité détecte l’ouverture des applis sélectionnées en arrière-plan. Le blocage facultatif affiche un écran de verrouillage Daylock ou revient à l’accueil jusqu’à ce que la Liberté soit gagnée. Si l’écran ne peut pas s’afficher, une notification explique le blocage quand Android le permet.';

  @override
  String get diagAppRestrictions => 'Restrictions d’applis';

  @override
  String get diagSeparateFromFreedom =>
      'Indépendant du Contrôle de Liberté. Désactivé par défaut.';

  @override
  String get diagStatusUnavailable => 'État des restrictions indisponible';

  @override
  String get diagRestrictionsOff => 'Restrictions d’applis : désactivées';

  @override
  String get diagWaitingForAccessibility =>
      'Restrictions d’applis : en attente de l’accès Accessibilité';

  @override
  String get diagAllowedFreedomOff =>
      'Applis sélectionnées autorisées — Contrôle de Liberté désactivé';

  @override
  String get diagAllowedFreedomEarned =>
      'Applis sélectionnées autorisées — Liberté gagnée';

  @override
  String get diagBlockingPaused =>
      'Blocage en pause — ouvrez Daylock pour actualiser la Liberté';

  @override
  String get diagRestrictionsReady =>
      'Restrictions prêtes — l’ouverture et la navigation dépendent d’Android';

  @override
  String get diagServiceStatusUnavailable => 'État du service indisponible';

  @override
  String get diagAndroidOnly =>
      'La détection native n’est disponible que sur Android.';

  @override
  String get diagServiceDisabled => 'Service d’Accessibilité : désactivé';

  @override
  String get diagServiceConnected =>
      'Service d’Accessibilité : activé et connecté';

  @override
  String get diagServiceWaiting =>
      'Service d’Accessibilité : activé — en attente de connexion par Android';

  @override
  String get diagBlockingSaveFailed =>
      'Le choix de blocage n’a pas pu être enregistré. La désactivation s’applique maintenant, mais peut ne pas survivre à un redémarrage. Retirez l’accès Accessibilité si nécessaire.';

  @override
  String get diagNoDetectionYet =>
      'Aucune appli sélectionnée détectée pour l’instant.';

  @override
  String diagLastDetection(String when) {
    return 'Dernière détection d’appli restreinte : $when';
  }

  @override
  String diagFreedomAtDetection(String state) {
    return 'Liberté lors de cette détection : $state';
  }

  @override
  String diagCurrentFreedom(String state) {
    return 'État natif actuel de la Liberté : $state';
  }

  @override
  String get diagFocusNeedsRefresh =>
      'Une session de concentration active doit être actualisée par Daylock. La détection native ne la marque pas comme terminée.';

  @override
  String get diagStateUnavailable =>
      'L’état du jour est indisponible. Ouvrez Daylock pour actualiser les plans ou désactivez le blocage. Les données valides du jour n’expirent pas après cinq minutes.';

  @override
  String get diagRolloverReconciled =>
      'Nouveau jour : le plan enregistré pour cette date est utilisé. Ouvrez Daylock pour archiver l’historique et préparer le jour suivant.';

  @override
  String get diagNoEligible =>
      'Aucun engagement éligible. Les journées vides ou entièrement excusées ne font pas gagner la Liberté.';

  @override
  String get diagDetectionSaveFailed =>
      'La dernière détection n’a pas pu être enregistrée et peut ne pas survivre à un redémarrage.';

  @override
  String get diagTurnBlockingOff => 'Désactiver le blocage';

  @override
  String get diagSettingsPath =>
      'Paramètres Android → Accessibilité → Applis téléchargées/installées → Restrictions d’applis Daylock. Activez le service manuellement. Les noms varient selon le téléphone.';

  @override
  String get diagRestrictedSettings =>
      'Si Android 15 affiche « Paramètres restreints », consultez les infos de l’appli Daylock pour « Autoriser les paramètres restreints » et ne confirmez que pour une version de développement de confiance.';

  @override
  String get diagAvailableAndroidOnly => 'Disponible uniquement sur Android';

  @override
  String get diagServiceEnabledShort => 'Service d’Accessibilité : activé';

  @override
  String get diagServiceDisconnected => 'Service déconnecté';

  @override
  String get diagRestrictionsOn => 'Restrictions d’applis : activées';

  @override
  String selectedAppsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count applis sélectionnées',
      one: '$count appli sélectionnée',
    );
    return '$_temp0';
  }

  @override
  String diagNativeFreedom(String state) {
    return 'Liberté native : $state';
  }

  @override
  String get diagTechnicalDetails => 'Détails techniques et configuration';

  @override
  String diagLastPackage(String package) {
    return 'Dernier paquet restreint : $package';
  }

  @override
  String get openAccessibilitySettings =>
      'Ouvrir les paramètres d’Accessibilité';

  @override
  String get refreshStatus => 'Actualiser l’état';

  @override
  String get appsLoadFailed =>
      'Impossible de charger les applis installées. Vos choix enregistrés n’ont pas été remplacés.';

  @override
  String get appsPausedAttention =>
      'Restrictions en pause : l’état demande votre attention.';

  @override
  String get appsRestrictionsOff =>
      'Les restrictions d’applis sont désactivées. Vos choix sont enregistrés.';

  @override
  String get appsNoneSelected =>
      'Aucune appli sélectionnée. Rien n’est restreint.';

  @override
  String get appsWaitingAccessibility =>
      'En attente de l’accès Accessibilité. Les applis sélectionnées ne sont pas restreintes.';

  @override
  String get appsFreedomOff =>
      'Le Contrôle de Liberté est désactivé. Les applis sélectionnées sont accessibles.';

  @override
  String get appsFreedomEarned =>
      'Liberté gagnée. Les applis sélectionnées sont accessibles.';

  @override
  String get appsNeedsRefresh =>
      'L’état de la Liberté doit être actualisé. Une récupération est disponible ; les ouvertures répétées sont autorisées.';

  @override
  String get appsRestricted =>
      'Les applis sélectionnées sont restreintes jusqu’à ce que la Liberté soit gagnée.';

  @override
  String selectedCountLabel(int count) {
    return 'Sélectionnées : $count';
  }

  @override
  String get refreshApps => 'Actualiser les applis';

  @override
  String get appsMasterControl =>
      'Commande principale pour toutes les applis sélectionnées.';

  @override
  String get appsMasterSaveFailed =>
      'Le réglage principal n’a pas pu être enregistré. La désactivation s’applique maintenant, mais peut ne pas survivre à un redémarrage.';

  @override
  String get appsChooseBelow =>
      'Choisissez les applis ci-dessous. Le Contrôle de Liberté et les restrictions d’applis sont indépendants. Les applis de secours du système sont exclues.';

  @override
  String appsRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count applis indisponibles ou réinstallées ont été retirées de la sélection. Sélectionnez-les à nouveau si besoin.',
      one:
          '$count appli indisponible ou réinstallée a été retirée de la sélection. Sélectionnez-la à nouveau si besoin.',
    );
    return '$_temp0';
  }

  @override
  String get appsNoneSelectedYet =>
      'Aucune appli sélectionnée pour l’instant. Choisissez celles que vous voulez restreindre.';

  @override
  String get searchApps => 'Rechercher des applis';

  @override
  String get appsSelectionRequiresAndroid =>
      'Le choix des applis installées nécessite Android.';

  @override
  String get retryAppDiscovery => 'Relancer la recherche d’applis';

  @override
  String get appsNoneFound =>
      'Aucune appli compatible trouvée dans ce profil Android.';

  @override
  String get appsNoMatches => 'Aucune appli correspondante.';

  @override
  String get appIconUnavailable => 'Icône indisponible';

  @override
  String get savingSelection => 'Enregistrement de la sélection…';

  @override
  String get appsSelectionsStay =>
      'Vos choix restent sur cet appareil. Les applis nouvelles ou réinstallées doivent être sélectionnées explicitement.';

  @override
  String get notifRunningStopwatchHelp =>
      'Affiche une notification discrète avec Pause pendant qu’un chronomètre tourne, et vous le rappelle toutes les 2 heures pour qu’il ne reste pas allumé par erreur.';

  @override
  String get notifBlockedInSystem => 'Bloqué dans les paramètres Android';

  @override
  String get notifLabel => 'Notifications';

  @override
  String get notifPermissionAllowed => 'Autorisation système : accordée';

  @override
  String get notifPermissionDenied => 'Autorisation système : refusée';

  @override
  String get notifNeedsAttention =>
      'La configuration des notifications demande votre attention';

  @override
  String get notifChecking => 'Vérification de l’autorisation système…';

  @override
  String get notifUnavailable => 'Notifications programmées indisponibles';

  @override
  String get notifPermissionHelp => 'Aide sur l’autorisation';

  @override
  String get notifOpenSettings => 'Ouvrir les paramètres de notification';

  @override
  String get notifPlanTomorrow => 'Planifier demain';

  @override
  String get notifCommitmentReminder => 'Rappel d’engagements';

  @override
  String get notifFreedom => 'Notifications de Liberté';

  @override
  String get notifFreedomHelp =>
      'Utilise l’Heure de Liberté quand le Contrôle de Liberté est activé.';

  @override
  String get notifRunningStopwatch => 'Chronomètre en cours';

  @override
  String get healthXiaomiTip =>
      'Pour éviter que cela se reproduise sur Xiaomi / Poco : dans les infos de l’appli Daylock, autorisez le démarrage automatique, réglez l’économiseur de batterie sur Aucune restriction, autorisez les pop-up en arrière-plan et évitez de balayer Daylock dans les applis récentes.';

  @override
  String get healthOffBody =>
      'L’accès Accessibilité de Daylock est désactivé, vos applis sélectionnées s’ouvrent donc librement. Activez-le pour rétablir le verrouillage.';

  @override
  String get healthStoppedBody =>
      'Android a arrêté Daylock en arrière-plan, vos applis sélectionnées s’ouvrent donc librement. Dans l’Accessibilité, désactivez puis réactivez Daylock.';

  @override
  String get healthStoppedTitle => 'Le blocage des applis s’est arrêté';

  @override
  String get openAccessibility => 'Ouvrir l’Accessibilité';

  @override
  String get openAppInfo => 'Ouvrir les infos de l’appli';

  @override
  String get conditionSatisfied => 'Rempli';

  @override
  String get conditionRemaining => 'Restant';

  @override
  String freedomTimeAt(String time) {
    return 'Heure de Liberté · $time';
  }

  @override
  String eligibleComplete(int kept, int total) {
    return '$kept / $total engagements éligibles tenus';
  }

  @override
  String get noEligibleRequired =>
      'Aucun engagement éligible — il faut en tenir pour gagner la Liberté.';

  @override
  String get tomorrowPlanCommittedCondition => 'Plan de demain engagé';

  @override
  String get planDateMismatch =>
      'Le plan du jour ne correspond pas à la date locale actuelle.';

  @override
  String availableAt(String time) {
    return 'Disponible à $time';
  }

  @override
  String get enableFreedomInSettings =>
      'Activez le Contrôle de Liberté dans Réglages.';

  @override
  String get pauseStopwatch => 'Mettre le chronomètre en pause';

  @override
  String get resumeStopwatch => 'Reprendre le chronomètre';

  @override
  String get startStopwatch => 'Lancer le chronomètre';

  @override
  String get keptLower => 'tenu';

  @override
  String keepTask(String name) {
    return 'Tenir $name';
  }

  @override
  String get recordedTimeLabel => 'Temps enregistré';

  @override
  String calendarDayExcusedNeutral(int count) {
    return 'Aucun engagement éligible, $count excusé(s), neutre';
  }

  @override
  String get calendarDayNeutral => 'Aucun engagement, neutre';

  @override
  String get calendarDayUnrecorded => 'Aucun engagement enregistré, neutre';

  @override
  String calendarDayProgress(int kept, int total, int percent, int excused) {
    return '$kept sur $total engagements éligibles tenus, $percent pour cent, $excused excusé(s)';
  }

  @override
  String get calendarTodaySuffix => ', aujourd’hui';

  @override
  String calendarDayValue(String description, int count) {
    return '$description, $count événement(s) prévu(s)';
  }

  @override
  String get heatNeutral =>
      'Neutre : aucun engagement éligible, historique manquant ou date future';

  @override
  String get heatZero => 'Engagements enregistrés : 0 pour cent tenus';

  @override
  String get heatLow => 'Plus de 0 à 25 pour cent tenus';

  @override
  String get heatMedium => 'Plus de 25 à 50 pour cent tenus';

  @override
  String get heatHigh => 'Plus de 50 à moins de 100 pour cent tenus';

  @override
  String get heatComplete => '100 pour cent tenus';

  @override
  String get heatLess => 'Moins';

  @override
  String get heatMore => 'Plus';

  @override
  String get calTodayReadOnly =>
      'Engagements du jour, en lecture seule. Gérez-les dans Aujourd’hui.';

  @override
  String get calHistoryReadOnly =>
      'Historique des engagements, en lecture seule';

  @override
  String get calTodayLabel => 'Engagements du jour';

  @override
  String get calHistoryLabel => 'Historique des engagements';

  @override
  String get calNoHistory => 'Aucun historique d’engagements enregistré.';

  @override
  String get calNoCommitmentsToday => 'Aucun engagement aujourd’hui.';

  @override
  String get calNeutralDay => 'Aucun engagement enregistré. Journée neutre.';

  @override
  String get calCompletionLabel => 'Engagements tenus à la date choisie';

  @override
  String calRecordedTime(String duration) {
    return 'Temps enregistré : $duration';
  }

  @override
  String calCommitmentOutcome(String outcome) {
    return 'Engagement · $outcome';
  }

  @override
  String calReason(String reason) {
    return 'Motif : $reason';
  }

  @override
  String get calReadOnlyCached => 'Événement en cache, lecture seule';

  @override
  String editNamed(String name) {
    return 'Modifier $name';
  }

  @override
  String deleteNamed(String name) {
    return 'Supprimer $name';
  }

  @override
  String get deleteEventTitle => 'Supprimer l’événement ?';

  @override
  String deleteEventBody(String title) {
    return 'Supprimer « $title » de votre agenda ?';
  }

  @override
  String get calReadOnlyCachedShort => 'Lecture seule · événement en cache';

  @override
  String get close => 'Fermer';

  @override
  String get previousMonth => 'Mois précédent';

  @override
  String get nextMonth => 'Mois suivant';

  @override
  String get calendar => 'Agenda';

  @override
  String get calendarAccounts => 'Comptes d’agenda';

  @override
  String get addEvent => 'Ajouter un événement';

  @override
  String get scheduleLabel => 'Agenda';

  @override
  String get noEventsScheduled => 'Aucun événement prévu.';

  @override
  String get eventTimeFormat => 'Utilisez HH:mm (00:00–23:59).';

  @override
  String get eventEndAfterStart => 'La fin doit être après le début.';

  @override
  String get readOnlyEvent => 'Événement en lecture seule';

  @override
  String get externalEventsReadOnly =>
      'Les événements externes ne peuvent être modifiés que dans leur agenda.';

  @override
  String get editEvent => 'Modifier l’événement';

  @override
  String get title => 'Titre';

  @override
  String get enterTitle => 'Saisissez un titre.';

  @override
  String get startTimeOptional => 'Heure de début (facultatif)';

  @override
  String get endTimeOptional => 'Heure de fin (facultatif)';

  @override
  String get notesOptional => 'Notes (facultatif)';

  @override
  String get saveEvent => 'Enregistrer l’événement';

  @override
  String get accountUpdateFailed =>
      'Impossible de mettre à jour ce compte. Les événements en cache restent disponibles. Réessayez ou reconnectez-vous.';

  @override
  String get disconnectAccountTitle => 'Déconnecter le compte ?';

  @override
  String disconnectAccountBody(String name) {
    return 'Retirer $name et ses événements en cache de Daylock ? Votre agenda externe ne sera pas modifié.';
  }

  @override
  String get disconnect => 'Déconnecter';

  @override
  String get externalCalendarsReadOnly =>
      'Les agendas externes sont en lecture seule. Les événements en cache sont disponibles hors ligne.';

  @override
  String get providersDisabled =>
      'La connexion n’est pas disponible pour les services désactivés dans cette version.';

  @override
  String connectProvider(String provider) {
    return 'Connecter $provider';
  }

  @override
  String get noConnectedAccounts => 'Aucun compte connecté.';

  @override
  String get syncNow => 'Synchroniser';

  @override
  String get reconnect => 'Reconnecter';

  @override
  String get notSyncedYet => 'Pas encore synchronisé';

  @override
  String lastSynced(String when) {
    return 'Dernière synchro $when';
  }

  @override
  String get syncToLoad =>
      'Synchronisez pour charger les agendas de ce compte.';

  @override
  String get chooseMonth => 'Choisir le mois';

  @override
  String get previousYear => 'Année précédente';

  @override
  String get year => 'Année';

  @override
  String get enterYear => 'Saisissez une année entre 1 et 9999.';

  @override
  String get nextYear => 'Année suivante';

  @override
  String get showMonth => 'Afficher le mois';

  @override
  String get commitment => 'Engagement';

  @override
  String repeatsLabel(String rule) {
    return 'Se répète : $rule';
  }

  @override
  String get areas => 'Domaines';

  @override
  String get areasIntro =>
      'Donnez un foyer à vos engagements. Votre domaine par défaut est utilisé quand aucun autre n’est choisi.';

  @override
  String get createArea => 'Créer un domaine';

  @override
  String get archived => 'Archivés';

  @override
  String get defaultAlwaysAvailable => 'Par défaut · Toujours disponible';

  @override
  String get restore => 'Restaurer';

  @override
  String get archive => 'Archiver';

  @override
  String get archivingExplainer =>
      'L’archivage garde les engagements et l’historique liés. Les nouveaux engagements n’utilisent que les domaines actifs.';

  @override
  String get editArea => 'Modifier le domaine';

  @override
  String get areaName => 'Nom du domaine';

  @override
  String get icon => 'Icône';

  @override
  String get colour => 'Couleur';

  @override
  String get saveArea => 'Enregistrer le domaine';

  @override
  String get areaIconLife => 'Vie';

  @override
  String get areaColourLavender => 'Lavande';

  @override
  String get areaIconHealth => 'Santé';

  @override
  String get areaIconWork => 'Travail';

  @override
  String get areaIconLearning => 'Apprentissage';

  @override
  String get areaIconHome => 'Maison';

  @override
  String get areaIconPeople => 'Proches';

  @override
  String get areaIconCreative => 'Créativité';

  @override
  String get areaIconFitness => 'Sport';

  @override
  String get areaColourBlue => 'Bleu';

  @override
  String get areaColourTeal => 'Sarcelle';

  @override
  String get areaColourGreen => 'Vert';

  @override
  String get areaColourAmber => 'Ambre';

  @override
  String get areaColourRose => 'Rose';

  @override
  String get newAchievement => 'Nouvelle réussite';

  @override
  String get editAchievement => 'Modifier la réussite';

  @override
  String get achievementPrompt => 'De quoi êtes-vous fier ?';

  @override
  String get achievementHint => 'J’ai eu mon permis';

  @override
  String get achievementNotes => 'Quelques mots (facultatif)';

  @override
  String get linkToArea => 'Lier à un domaine';

  @override
  String get optional => 'Facultatif';

  @override
  String get previousAreaUnavailable =>
      'Le domaine précédent n’est plus disponible. Choisissez un domaine ou retirez le lien.';

  @override
  String get saveAchievement => 'Enregistrer la réussite';

  @override
  String illustrationLabel(String name) {
    return 'Illustration : $name';
  }

  @override
  String illustrationAutomaticLabel(String name) {
    return 'Illustration : automatique · $name';
  }

  @override
  String get illustrationHelp =>
      'Choisissez un style, ou laissez le titre et le domaine en suggérer un.';

  @override
  String get automatic => 'Automatique';

  @override
  String get area => 'Domaine';

  @override
  String get notifExplainAndroid =>
      'Les rappels Android peuvent être retardés par l’économiseur de batterie ou Ne pas déranger. Les préférences ci-dessous sont distinctes de l’autorisation système.';

  @override
  String get notifExplainError =>
      'Impossible de mettre à jour les notifications. Rouvrez Daylock pour réessayer.';

  @override
  String get notifExplainDefault =>
      'Les notifications programmées sont disponibles sur Android.';

  @override
  String get notifExplainWebSupported =>
      'Ce navigateur prend en charge les notifications, mais pas les rappels programmés. Safari, les onglets fermés et les PWA installées ne peuvent pas les recevoir sans service push. Utilisez Daylock sur Android pour les notifications programmées.';

  @override
  String get notifExplainWebUnsupported =>
      'Ce navigateur ne peut pas recevoir les notifications Daylock. Les rappels programmés sont disponibles dans l’appli Android ; les commandes web/PWA sont désactivées.';

  @override
  String get detectionReadFailed =>
      'Impossible de lire l’état de la détection native. Actualisez ou ouvrez les paramètres Android manuellement.';

  @override
  String get calFailAuthMicrosoft =>
      'L’accès à l’agenda Microsoft doit être renouvelé. Reconnectez ce compte. Votre organisation peut exiger l’accord d’un administrateur. Les événements en cache restent disponibles.';

  @override
  String get calFailAuthGoogle =>
      'L’autorisation Google Agenda a expiré ou a été retirée. Reconnectez ce compte. Les événements en cache restent disponibles.';

  @override
  String get calFailConfigMicrosoft =>
      'La connexion Microsoft n’est pas correctement configurée. Vérifiez l’ID client Entra, l’URI de redirection native et les types de comptes pris en charge.';

  @override
  String get calFailConfigGoogle =>
      'La connexion Google n’est pas correctement configurée. Vérifiez l’ID client OAuth, le paquet Android et le certificat de signature.';

  @override
  String get calFailUnavailableMicrosoft =>
      'L’agenda Microsoft est indisponible. Vérifiez votre connexion et réessayez. Les comptes professionnels nécessitent une boîte Exchange accessible. Les événements en cache restent disponibles.';

  @override
  String get calFailUnavailableGoogle =>
      'Google Agenda est indisponible. Vérifiez votre connexion et relancez la synchronisation. Les événements en cache restent disponibles.';

  @override
  String get calFailResponseMicrosoft =>
      'Microsoft a renvoyé une réponse d’agenda incomplète ou non prise en charge. Les événements en cache restent disponibles. Réessayez plus tard.';

  @override
  String get calFailResponseGoogle =>
      'Google a renvoyé une réponse d’agenda incomplète ou non prise en charge. Les événements en cache restent disponibles. Réessayez plus tard.';

  @override
  String get calFailAdminConsent =>
      'Votre organisation exige l’accord d’un administrateur ou restreint cette connexion. Contactez votre administrateur informatique. Les événements en cache restent disponibles.';

  @override
  String get calFailAccountMismatch =>
      'Choisissez le même compte et la même organisation Microsoft lors de la reconnexion. Les comptes existants et les événements en cache ont été conservés.';

  @override
  String get channelPlan => 'Planifier demain';

  @override
  String get channelCommitments => 'Rappels d’engagements';

  @override
  String get channelFreedom => 'Liberté';

  @override
  String get channelFocus => 'Chronomètre en cours';

  @override
  String get selectionLoadFailed =>
      'Impossible de charger ou d’enregistrer les applis restreintes. Les restrictions sont en pause. Actualisez pour réessayer.';

  @override
  String get selectionSaveFailed =>
      'La sélection d’applis n’a pas pu être enregistrée. Les restrictions sont en pause. Actualisez pour réessayer.';

  @override
  String totalAchievements(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'réussites',
      one: 'réussite',
    );
    return '$_temp0';
  }

  @override
  String get breaksTitle => 'Pauses';

  @override
  String get breaksIntro =>
      'Prises depuis l’écran de verrouillage ces 30 derniers jours, avec vos motifs.';

  @override
  String breakEntryTitle(String app, String when) {
    return '$app · $when';
  }

  @override
  String get diagRestrictionSkippedBreakActive =>
      'Restriction ignorée : une pause de 15 minutes est en cours.';

  @override
  String get backupTitle => 'Sauvegarde et restauration';

  @override
  String get backupSubtitle =>
      'Gardez une copie de vos plans et de votre parcours';

  @override
  String get backupAutoTitle => 'La sauvegarde Android automatique est activée';

  @override
  String get backupAutoBody =>
      'Si la sauvegarde est activée dans les paramètres du téléphone, Google garde une copie de vos plans Daylock et la restaure sur un nouveau téléphone. Les connexions d’agenda et les autorisations de blocage ne sont pas incluses.';

  @override
  String get backupFileLabel => 'Fichier de sauvegarde';

  @override
  String get backupExport => 'Exporter une sauvegarde';

  @override
  String get backupExportBody =>
      'Enregistre vos plans, votre historique, vos domaines, routines, réussites et réglages dans un fichier de votre choix : Drive, Téléchargements ou ailleurs.';

  @override
  String get backupImport => 'Restaurer depuis un fichier';

  @override
  String get backupImportBody =>
      'Remplace tout le contenu de Daylock par celui d’un fichier de sauvegarde.';

  @override
  String get backupConfirmTitle => 'Remplacer vos données Daylock ?';

  @override
  String get backupConfirmBody =>
      'Tout le contenu de Daylock sera remplacé par cette sauvegarde. Impossible de revenir en arrière.';

  @override
  String get backupReplace => 'Remplacer';

  @override
  String get backupSaved => 'Sauvegarde enregistrée.';

  @override
  String get backupRestored => 'Sauvegarde restaurée.';

  @override
  String get backupNotDaylock => 'Ce fichier n’est pas une sauvegarde Daylock.';

  @override
  String get backupNewer =>
      'Cette sauvegarde vient d’une version plus récente de Daylock. Mettez d’abord l’appli à jour.';

  @override
  String get backupDamaged =>
      'Cette sauvegarde est endommagée et ne peut pas être restaurée.';

  @override
  String get backupFailed =>
      'Impossible d’enregistrer ou d’ouvrir le fichier. Essayez un autre emplacement.';

  @override
  String get backupAndroidOnly =>
      'Les fichiers de sauvegarde sont disponibles dans l’appli Android.';
}

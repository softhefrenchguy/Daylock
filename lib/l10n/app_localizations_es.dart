// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Daylock';

  @override
  String get appearanceDark => 'Oscuro';

  @override
  String get appearanceLight => 'Claro';

  @override
  String get appearanceSystem => 'Sistema';

  @override
  String get colourViolet => 'Violeta';

  @override
  String get colourOcean => 'Océano';

  @override
  String get colourForest => 'Bosque';

  @override
  String get colourEmber => 'Brasa';

  @override
  String get colourRose => 'Rosa';

  @override
  String get colourMono => 'Mono';

  @override
  String get illustrationCelebration => 'Celebración';

  @override
  String get illustrationDriving => 'Conducción';

  @override
  String get illustrationAward => 'Premio';

  @override
  String get illustrationCooking => 'Cocina';

  @override
  String get illustrationTravel => 'Viaje';

  @override
  String get illustrationFitness => 'Ejercicio';

  @override
  String get illustrationLearning => 'Aprendizaje';

  @override
  String get illustrationHealth => 'Salud';

  @override
  String get illustrationWork => 'Trabajo';

  @override
  String get illustrationHome => 'Hogar';

  @override
  String get illustrationPeople => 'Personas';

  @override
  String get illustrationCreativity => 'Creatividad';

  @override
  String get illustrationSunrise => 'Amanecer';

  @override
  String get outcomeIncomplete => 'Sin completar';

  @override
  String get outcomeCompleted => 'Completado';

  @override
  String get outcomeExcused => 'Justificado';

  @override
  String get sourceLocal => 'Local';

  @override
  String get sourceGoogle => 'Google Calendar';

  @override
  String get sourceMicrosoftPersonal => 'Microsoft personal';

  @override
  String get sourceMicrosoftWorkSchool => 'Microsoft trabajo o escuela';

  @override
  String get freedomStateEarned => 'Ganada';

  @override
  String get freedomStateNotEarned => 'No ganada';

  @override
  String get freedomStateControlOff => 'Control desactivado';

  @override
  String get freedomStateUnknown => 'Desconocido';

  @override
  String get listSeparator => ', ';

  @override
  String get repeatDaily => 'Cada día';

  @override
  String repeatEveryDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Cada $count días',
      one: 'Cada día',
    );
    return '$_temp0';
  }

  @override
  String get repeatWeekdays => 'Entre semana';

  @override
  String get repeatWeekends => 'Fines de semana';

  @override
  String get eventContinuesAllDay => 'Continúa todo el día';

  @override
  String get eventEarlier => 'Antes';

  @override
  String get eventNextDay => 'Día siguiente';

  @override
  String eventUntil(String time) {
    return 'Hasta las $time';
  }

  @override
  String get eventAllDay => 'Todo el día';

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
  String get settingsFreedomControl => 'Control de Libertad';

  @override
  String get settingsPlanningRoutines => 'Planificación y rutinas';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsNotifications => 'Notificaciones';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get settingsRestrictedApps => 'Apps restringidas';

  @override
  String get settingsPermissionsDiagnostics => 'Permisos y diagnóstico';

  @override
  String get settingsManageRoutines => 'Gestionar rutinas';

  @override
  String routineCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rutinas',
      one: '1 rutina',
    );
    return '$_temp0';
  }

  @override
  String get settingsRoutinesIntro =>
      'Planifica tus próximos pasos con compromisos recurrentes.';

  @override
  String get settingsNotificationsUnavailable =>
      'Las notificaciones no están disponibles en este dispositivo.';

  @override
  String get keepYourWord => 'Cumple tu palabra.';

  @override
  String get settingsAboutCommitments =>
      'Compromisos, cronómetros opcionales y progreso en lo que importa.';

  @override
  String get settingsRestrictedIntro =>
      'Elige qué apps de Android restringir hasta ganar la Libertad.';

  @override
  String get settingsRestrictionsAndroidOnly =>
      'Las restricciones de apps están disponibles en Android.';

  @override
  String get settingsDiagnosticsAndroidOnly =>
      'El diagnóstico de accesibilidad está disponible en Android.';

  @override
  String get freedomTime => 'Hora de Libertad';

  @override
  String get settingsRestrictionNeedsAttention =>
      'El estado de las restricciones requiere atención';

  @override
  String settingsSelectedSwitchOn(int count) {
    return '$count seleccionadas, activado';
  }

  @override
  String settingsSelectedSwitchOff(int count) {
    return '$count seleccionadas, desactivado';
  }

  @override
  String get accessibility => 'Accesibilidad';

  @override
  String get statusUnavailable => 'Estado no disponible';

  @override
  String get availableOnAndroid => 'Disponible en Android';

  @override
  String get serviceConnected => 'Servicio conectado';

  @override
  String get waitingForConnection => 'Esperando conexión';

  @override
  String get serviceDisabled => 'Servicio desactivado';

  @override
  String get settingsChooseInstalledApps => 'Elige apps de Android instaladas';

  @override
  String get settingsFreedomSubtitle =>
      'Apps restringidas, Hora de Libertad y permisos';

  @override
  String get on => 'Activado';

  @override
  String get off => 'Desactivado';

  @override
  String get settingsPlanningSubtitle =>
      'Compromisos recurrentes y planificación';

  @override
  String get settingsAppearanceSubtitle => 'Tema, colores y áreas';

  @override
  String get settingsNotificationsSubtitle => 'Recordatorios y avisos';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsRunSetup => 'Repetir la configuración';

  @override
  String get settingsRunSetupSubtitle =>
      'Permisos, distracciones y tu primer compromiso';

  @override
  String get settingsTakeTour => 'Hacer el recorrido';

  @override
  String get settingsTakeTourSubtitle =>
      'Un recorrido guiado por Hoy, Planificar y Camino';

  @override
  String get settingsAboutSubtitle => 'Información de la app';

  @override
  String get tagline => 'Planifica tu día. Gánate tu libertad.';

  @override
  String get freedomStatusUnavailable => 'Estado de la Libertad no disponible';

  @override
  String get freedomControlOff => 'El Control de Libertad está desactivado';

  @override
  String get appearanceFollowsDevice =>
      'Sigue la apariencia de tu dispositivo.';

  @override
  String appearanceFixed(String mode) {
    return 'Apariencia $mode, en cualquier modo del dispositivo.';
  }

  @override
  String get appearanceColourTheme => 'Tema de color';

  @override
  String get appearanceLivePreview => 'Vista previa';

  @override
  String get manageAreas => 'Gestionar áreas';

  @override
  String activeAreas(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count áreas activas',
      one: '1 área activa',
    );
    return '$_temp0';
  }

  @override
  String get appearancePreviewLabel =>
      'Vista previa de la apariencia. Estilo de compromiso de ejemplo.';

  @override
  String get today => 'Hoy';

  @override
  String get appearancePreviewComplete => '1 / 2 completado';

  @override
  String get appearancePreviewProgress => 'Progreso de ejemplo';

  @override
  String get appearancePreviewRecorded => '23:00 registrado';

  @override
  String keptTaskAnnouncement(String name) {
    return '$name cumplido';
  }

  @override
  String todayEarnedTomorrowLocked(String weekday) {
    return 'Cumpliste tu palabra y el $weekday ya está comprometido. Disfrútalo.';
  }

  @override
  String get todayEarned => 'Cumpliste tu palabra. Disfrútalo.';

  @override
  String get commitments => 'Compromisos';

  @override
  String get taskActions => 'Acciones del compromiso';

  @override
  String get showFewerCommitments => 'Mostrar menos compromisos';

  @override
  String showAllCommitments(int count) {
    return 'Mostrar los $count compromisos';
  }

  @override
  String excusedCount(int count) {
    return '$count justificados';
  }

  @override
  String keptName(String name) {
    return 'Cumplido: $name';
  }

  @override
  String get undo => 'Deshacer';

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
  String get noEligibleCommitments => 'Sin compromisos válidos';

  @override
  String keptOfEligible(int kept, int total) {
    return '$kept de $total cumplidos';
  }

  @override
  String get excusedDontCount => 'Los compromisos justificados no cuentan';

  @override
  String get dayComplete => 'Día completado';

  @override
  String moreUntilSunUp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count más y sale el sol',
      one: '1 más y sale el sol',
    );
    return '$_temp0';
  }

  @override
  String timedSuffix(String duration) {
    return '$duration cronometrados';
  }

  @override
  String get commitmentsComplete => 'Compromisos completados';

  @override
  String get todayRestrictionsInSettings =>
      'Las restricciones de apps se configuran en Ajustes.';

  @override
  String get freedomEarned => 'Libertad ganada';

  @override
  String get showFreedomDetails => 'Ver detalles de la Libertad';

  @override
  String appsUnlockedAt(String time) {
    return 'Apps desbloqueadas a las $time';
  }

  @override
  String get freedomEarnedTitle => 'Libertad ganada.';

  @override
  String get freedomNotYetEarned => 'Libertad aún no ganada';

  @override
  String get freedomOffDetail => 'Recupera tus apps cumpliendo tu palabra.';

  @override
  String get appsStayLockedToday => 'Las apps siguen bloqueadas hoy';

  @override
  String get emptyDayDetail =>
      'Un día vacío no gana Libertad. Compromete un plan para mañana.';

  @override
  String appsUnlockAt(String time) {
    return 'Las apps se desbloquean a las $time';
  }

  @override
  String keepMoreToEarn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Cumple $count más para ganarla',
      one: 'Cumple 1 más para ganarla',
    );
    return '$_temp0';
  }

  @override
  String get commitTomorrowToEarn =>
      'Compromete el plan de mañana para ganarla';

  @override
  String get waitingForFreedomTime => 'Esperando la Hora de Libertad';

  @override
  String everythingKeptUnlockAt(String time) {
    return 'Todo cumplido. Las apps se desbloquean a las $time';
  }

  @override
  String get turnOn => 'Activar';

  @override
  String get hideFreedomDetails => 'Ocultar detalles de la Libertad';

  @override
  String get aClearDay => 'Un día despejado.';

  @override
  String allSetFor(String weekday) {
    return 'Todo listo para el $weekday.';
  }

  @override
  String get emptyTodayNoPlan =>
      'Sin compromisos para hoy. Planifica mañana: el sol de mañana depende de ti.';

  @override
  String get emptyTodayLocked =>
      'Nada planeado hoy y mañana ya está fijado. Descansar es el plan.';

  @override
  String weekdayCommitmentCount(String weekday, int count) {
    return '$weekday: $count';
  }

  @override
  String get view => 'Ver';

  @override
  String get planTomorrow => 'Planificar mañana';

  @override
  String get repeatNever => 'Nunca';

  @override
  String get repeatCustom => 'Personalizado…';

  @override
  String get repeat => 'Repetir';

  @override
  String get repeatClose => 'Cerrar opciones de repetición';

  @override
  String get repeatDaysOfWeek => 'Días de la semana';

  @override
  String get repeatEveryNDays => 'Cada N días';

  @override
  String get repeatEvery => 'Cada';

  @override
  String get repeatFewerDays => 'Menos días';

  @override
  String get repeatMoreDays => 'Más días';

  @override
  String get repeatPickOneDay => 'Elige al menos un día.';

  @override
  String get repeatOnlyThisDay => 'Solo este día. No se repetirá.';

  @override
  String repeatNext(String dates) {
    return 'Próximos: $dates';
  }

  @override
  String get done => 'Listo';

  @override
  String get editCommitment => 'Editar compromiso';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get removeCommitmentTitle => '¿Quitar el compromiso?';

  @override
  String removeFromDraft(String name) {
    return '¿Quitar $name del borrador de mañana?';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get remove => 'Quitar';

  @override
  String areaFor(String name) {
    return 'Área de $name';
  }

  @override
  String lockInWeekdayQuestion(String weekday) {
    return '¿Fijar el $weekday?';
  }

  @override
  String lockInConfirmOne(String weekday) {
    return 'Esto fija tu compromiso para el $weekday. No podrás añadir ni cambiar nada.';
  }

  @override
  String lockInConfirmMany(int count, String weekday) {
    return 'Esto fija tus $count compromisos para el $weekday. No podrás añadir ni cambiar nada.';
  }

  @override
  String get keepPlanning => 'Seguir planificando';

  @override
  String get lockItIn => 'Fijarlo';

  @override
  String get plan => 'Planificar';

  @override
  String tomorrowDate(String date) {
    return 'Mañana · $date';
  }

  @override
  String get committed => 'Comprometido';

  @override
  String get draft => 'Borrador';

  @override
  String get schedule => 'Agenda';

  @override
  String get noScheduledEventsTomorrow => 'No hay eventos para mañana.';

  @override
  String scheduledEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eventos programados',
      one: '1 evento programado',
    );
    return '$_temp0';
  }

  @override
  String commitmentsCount(int count) {
    return 'Compromisos · $count';
  }

  @override
  String get add => 'Añadir';

  @override
  String get addACommitment => 'Añadir un compromiso';

  @override
  String get noCommitmentsPlanned => 'Aún no hay compromisos planeados.';

  @override
  String get tomorrowIsLocked => 'Mañana está fijado.';

  @override
  String get addOneSmallStep => 'Añade un pequeño paso para mañana.';

  @override
  String lockInWeekday(String weekday) {
    return 'Fijar el $weekday';
  }

  @override
  String addOneToLockIn(String weekday) {
    return 'Añade al menos un compromiso para fijar el $weekday.';
  }

  @override
  String get locksThisCommitment =>
      'Fija este compromiso. Después no podrás cambiarlo.';

  @override
  String locksTheseCommitments(int count) {
    return 'Fija estos $count. Después no podrás cambiarlos.';
  }

  @override
  String archivedArea(String name) {
    return '$name (archivada)';
  }

  @override
  String actionsFor(String name) {
    return 'Acciones para $name';
  }

  @override
  String get removeCommitment => 'Quitar compromiso';

  @override
  String get tomorrowPlanCommitted => 'El plan de mañana está comprometido.';

  @override
  String get yourCommitmentsLocked => 'Tus compromisos están fijados.';

  @override
  String get nextTomorrow => 'próximo: mañana';

  @override
  String nextDate(String date) {
    return 'próximo: $date';
  }

  @override
  String rotationSummary(int count, String name) {
    return '$count pasos · siguiente: $name';
  }

  @override
  String get deleteRoutineTitle => '¿Eliminar la rutina?';

  @override
  String deleteRoutineBody(String name) {
    return '¿Dejar de repetir $name? Los compromisos que ya están en tus planes e historial se mantienen.';
  }

  @override
  String get delete => 'Eliminar';

  @override
  String get routines => 'Rutinas';

  @override
  String get routinesIntro =>
      'Las rutinas se añaden solas al plan de mañana los días que tocan. Quita una de un plan para saltarte solo ese día. Una rotación con varios pasos solo avanza cuando un paso se queda en tu plan.';

  @override
  String get createRoutineOrRotation => 'Crear rutina o rotación';

  @override
  String get noRoutinesYet => 'Aún no hay rutinas.';

  @override
  String get edit => 'Editar';

  @override
  String get newRoutineStep => 'Nuevo paso';

  @override
  String get editRoutineStep => 'Editar paso';

  @override
  String get addStep => 'Añadir paso';

  @override
  String get saveStep => 'Guardar paso';

  @override
  String get createRoutine => 'Crear rutina';

  @override
  String get editRoutine => 'Editar rutina';

  @override
  String get routineName => 'Nombre de la rutina';

  @override
  String get routineRotationHelp =>
      'Una rotación: cada día que toca añade el siguiente paso, en este orden. Un paso que quites vuelve la próxima vez.';

  @override
  String get routineSingleHelp =>
      'Cada día que toca se añade automáticamente al plan de mañana. Añade más pasos para crear una rotación.';

  @override
  String editStepN(int number) {
    return 'Editar paso $number';
  }

  @override
  String moveStepUp(int number) {
    return 'Subir paso $number';
  }

  @override
  String moveStepDown(int number) {
    return 'Bajar paso $number';
  }

  @override
  String removeStepN(int number) {
    return 'Quitar paso $number';
  }

  @override
  String get addCommitment => 'Añadir compromiso';

  @override
  String get addRotationStep => 'Añadir paso de rotación';

  @override
  String get saveRoutine => 'Guardar rutina';

  @override
  String get newCommitment => 'Nuevo compromiso';

  @override
  String get partOfRotation =>
      'Forma parte de una rotación. Cámbiala en Rutinas.';

  @override
  String get commitmentHint => 'Un paso pequeño y concreto';

  @override
  String get closeEditor => 'Cerrar editor';

  @override
  String get commitmentName => 'Nombre del compromiso';

  @override
  String get statusKept => 'Cumplido';

  @override
  String get statusNotKeptYet => 'Aún sin cumplir';

  @override
  String durationRecorded(String duration) {
    return '$duration registrados';
  }

  @override
  String get excuseReason => 'Motivo de la justificación';

  @override
  String get markCompleted => 'Marcar como completado';

  @override
  String get excuseTask => 'Justificar';

  @override
  String get resetToIncomplete => 'Volver a sin completar';

  @override
  String get excuseCommitment => 'Justificar compromiso';

  @override
  String get excusePrompt => '¿Qué circunstancia externa te impidió cumplirlo?';

  @override
  String get reason => 'Motivo';

  @override
  String get enterShortReason => 'Escribe un motivo breve.';

  @override
  String get shortenReason => 'Acorta este motivo.';

  @override
  String durationMinutesSeconds(int minutes, int seconds) {
    return '$minutes min $seconds s';
  }

  @override
  String get loadFailed => 'No se pudieron cargar tus compromisos guardados.';

  @override
  String get loadingDay => 'Preparando tu día.';

  @override
  String get retry => 'Reintentar';

  @override
  String get loadingCommitments => 'Cargando compromisos';

  @override
  String get journey => 'Camino';

  @override
  String dayStreakLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Racha de $count días',
      one: 'Racha de 1 día',
    );
    return '$_temp0';
  }

  @override
  String dayStreakWord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'días de racha',
      one: 'día de racha',
    );
    return '$_temp0';
  }

  @override
  String get streakStartHint => 'Cumple todo hoy para empezar una';

  @override
  String get streakLongestYet => 'Tu mejor racha';

  @override
  String streakLongest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Récord: $count días',
      one: 'Récord: 1 día',
    );
    return '$_temp0';
  }

  @override
  String get totalKept => 'cumplidos';

  @override
  String get totalFocused => 'cronometrado';

  @override
  String shortMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String shortHours(int hours) {
    return '$hours h';
  }

  @override
  String get achievements => 'Logros';

  @override
  String seeAll(int count) {
    return 'Ver los $count';
  }

  @override
  String get addAchievement => 'Añadir logro';

  @override
  String get last5Weeks => 'Últimas 5 semanas';

  @override
  String get dailyHistory => 'Historial diario';

  @override
  String get yourAreas => 'Tus áreas';

  @override
  String get manage => 'Gestionar';

  @override
  String get pastChapters => 'Capítulos pasados';

  @override
  String get areasArchived => 'Áreas archivadas';

  @override
  String achievementSemantics(String title, String date) {
    return 'Logro: $title, $date';
  }

  @override
  String get areaUnavailable => 'Área no disponible';

  @override
  String get keepAMoment => 'Guarda un momento que importa.';

  @override
  String get addAnAchievement => 'Añadir un logro';

  @override
  String get achievementExamples =>
      'Un carné de conducir, unos primeros 10 km, un capítulo terminado.';

  @override
  String last5WeeksKept(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Últimas 5 semanas: $count días cumplidos por completo',
      one: 'Últimas 5 semanas: 1 día cumplido por completo',
    );
    return '$_temp0';
  }

  @override
  String get legendAllKept => 'Todo cumplido';

  @override
  String get legendSomeKept => 'En parte';

  @override
  String get legendMissed => 'Fallado';

  @override
  String keptThisWeek(int count) {
    return '$count esta semana';
  }

  @override
  String areaKeptThisWeek(String area, int count) {
    return '$area: $count cumplidos esta semana';
  }

  @override
  String get last30Days => 'Últimos 30 días';

  @override
  String get allTime => 'Desde siempre';

  @override
  String completedCommitments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count compromisos completados',
      one: '1 compromiso completado',
    );
    return '$_temp0';
  }

  @override
  String recordedTime(String duration) {
    return '$duration de tiempo registrado';
  }

  @override
  String get stopwatchExplainer =>
      'El cronómetro registra el esfuerzo real, incluso en compromisos sin completar.';

  @override
  String get activityOverTime => 'Actividad en el tiempo';

  @override
  String get trackedTime => 'Tiempo registrado';

  @override
  String get achievementsPlace =>
      'Un lugar para los momentos que quieres recordar.';

  @override
  String get recordedCommitments => 'Compromisos registrados';

  @override
  String recordsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count registros',
      one: '1 registro',
    );
    return '$_temp0';
  }

  @override
  String get recordsEmpty => 'Tus compromisos registrados aparecerán aquí.';

  @override
  String get recordedTimeEmpty => 'El tiempo registrado aparecerá aquí.';

  @override
  String get completedEmpty => 'Los compromisos completados aparecerán aquí.';

  @override
  String get activityDetails => 'Detalles de la actividad';

  @override
  String activityRange(String from, String through, String value) {
    return 'Del $from al $through: $value';
  }

  @override
  String activityDescriptionTime(String days) {
    return 'Últimos 30 días, tiempo registrado. $days';
  }

  @override
  String activityDescriptionCompleted(String days) {
    return 'Últimos 30 días, compromisos completados. $days';
  }

  @override
  String get thirtyDaysTime => '30 días · tiempo';

  @override
  String get thirtyDaysCompleted => '30 días · completados';

  @override
  String completedCount(int count) {
    return '$count completados';
  }

  @override
  String get openSpace => 'Espacio libre';

  @override
  String get openArea => 'Abrir área';

  @override
  String get latestAchievement => 'Último logro';

  @override
  String get pastChaptersIntro =>
      'Partes de tu vida, guardadas aquí para volver a ellas.';

  @override
  String get pastChaptersEmpty =>
      'Las áreas archivadas se quedarán aquí, con su historial.';

  @override
  String get savePendingBeforeStopwatch =>
      'Guarda tus cambios pendientes antes de cambiar un cronómetro.';

  @override
  String get couldNotSaveAppearance => 'No se pudo guardar la apariencia.';

  @override
  String get couldNotSaveSetup =>
      'No se pudo guardar la configuración. Vuelve a intentarlo desde Ajustes.';

  @override
  String get tomorrowAlreadyCommitted =>
      'El plan de mañana ya está comprometido. Se mantienen los compromisos existentes. Añade otro cuando empiece el día siguiente.';

  @override
  String get firstCommitmentHeading => 'Tu primer compromiso · mañana';

  @override
  String pausedTask(String name) {
    return '$name en pausa.';
  }

  @override
  String removedForWeekday(String weekday) {
    return 'Quitado para el $weekday.';
  }

  @override
  String get stopRepeating => 'Dejar de repetir';

  @override
  String get stoppedRepeating => 'Ya no se repite.';

  @override
  String get achievementsIntro =>
      'Cosas de las que estás orgulloso: un carné de conducir, unos primeros 10 km, un capítulo terminado.';

  @override
  String get achievement => 'Logro';

  @override
  String get achievementRemoved => 'Este logro se ha eliminado.';

  @override
  String get deleteAchievementTitle => '¿Eliminar el logro?';

  @override
  String deleteAchievementBody(String title) {
    return '¿Eliminar «$title»? Tus compromisos y áreas se quedan como están.';
  }

  @override
  String get keepAchievement => 'Conservar logro';

  @override
  String get couldNotSaveChanges => 'No se pudieron guardar tus cambios.';

  @override
  String get tourDayTitle => 'Este es tu día';

  @override
  String get tourDayBody =>
      'El sol sube a medida que cumples los compromisos de hoy. Cúmplelos todos y estará en lo más alto.';

  @override
  String get tourCommitmentsTitle => 'Los compromisos de hoy';

  @override
  String get tourCommitmentsBody =>
      'Toca el círculo para cumplir uno. Toca la fila para usar un cronómetro, o justifícalo con un motivo si de verdad surgió algo.';

  @override
  String get tourFreedomTitle => 'Libertad';

  @override
  String get tourFreedomBody =>
      'Las apps que restringes se abren a la Hora de Libertad, cuando hoy está cumplido y mañana está fijado. Toca aquí cuando quieras para ver lo que falta.';

  @override
  String get tourPlanTitle => 'Planificar mañana';

  @override
  String get tourPlanBody =>
      'Cada noche, planifica mañana mientras hoy sigue fresco. Elige unas pocas cosas que de verdad vayas a hacer.';

  @override
  String get tourAddTitle => 'Añadir y repetir';

  @override
  String get tourAddBody =>
      'Añade un compromiso y dale un área. Activa Repetir para tus hábitos y se rellenarán solos en sus días.';

  @override
  String get tourLockTitle => 'Fíjalo';

  @override
  String get tourLockBody =>
      'Cuando mañana se vea bien, fíjalo. Después ya no puede cambiar. Eso es lo que lo convierte en un compromiso.';

  @override
  String get tourJourneyTitle => 'Tu camino';

  @override
  String get tourJourneyBody =>
      'Cada día cumplido cuenta aquí: tu racha, el esfuerzo que pones y los logros de los que estás orgulloso.';

  @override
  String get tourAreasTitle => 'Áreas';

  @override
  String get tourAreasBody =>
      'Cada área sigue una parte de tu vida, como Cuerpo, Mente o Carrera. Añádelas, renómbralas o archívalas aquí. Más abajo, abre una para ver su historial.';

  @override
  String get tourSettingsTitle => 'Ajustes';

  @override
  String get tourSettingsBody =>
      'Aquí están la Hora de Libertad, el bloqueo de apps, las rutinas, los recordatorios y los colores. También puedes repetir este recorrido desde Ajustes.';

  @override
  String stepOf(int current, int total) {
    return '$current de $total';
  }

  @override
  String get skipTour => 'Saltar recorrido';

  @override
  String get back => 'Atrás';

  @override
  String get next => 'Siguiente';

  @override
  String tourStepSemantics(int current, int total) {
    return 'Recorrido de la app, paso $current de $total';
  }

  @override
  String get setupTourBody =>
      'Recorreremos las pantallas reales de Hoy, Planificar y Camino y te mostraremos para qué sirve cada parte. Lleva un minuto y puedes saltarlo cuando quieras.';

  @override
  String get setupTestBody =>
      'Abre una app seleccionada y busca la pantalla de bloqueo de Daylock. Vuelve aquí para ver el resultado. Ábrela también de forma normal desde Inicio tras dejar Daylock en segundo plano: esta prueba solo confirma una apertura. Usa tus condiciones reales de Libertad y nunca completa un objetivo por ti.';

  @override
  String get setupFirstCommitmentBody =>
      'El plan de hoy ya está fijado. Tu primer compromiso nuevo va al plan real de mañana. Las apps se desbloquean cuando todos los compromisos válidos están completos, se alcanza la Hora de Libertad y el plan de mañana está comprometido. Un día vacío no gana Libertad.';

  @override
  String get setupAccessibilityOemHelp =>
      'En Xiaomi / HyperOS, Samsung y Pixel los nombres de los ajustes varían. Elige el servicio de esta app Daylock instalada. Si aparece «Ajustes restringidos», revisa Información de la app → Permitir ajustes restringidos solo para una versión de confianza. Si el servicio está activado pero desconectado, desactívalo y actívalo una vez.';

  @override
  String get setupAccessibilityExplain =>
      'Daylock detecta cuándo se abre una app seleccionada y puede mostrar su pantalla de bloqueo o volver a Inicio. Nunca lee el contenido de la pantalla. El acceso es opcional y puedes retirarlo en los ajustes de Android.';

  @override
  String get setupBlockingOptional =>
      'El bloqueo de apps es opcional. Sin él, Daylock sigue planificando tus días y registrando tus compromisos. Puedes activarlo más tarde en Ajustes.';

  @override
  String get setupXiaomiBody =>
      'HyperOS puede pausar Daylock en segundo plano aunque Accesibilidad aparezca activada. Una prueba dentro de Daylock puede funcionar aunque abrir Instagram desde Inicio no.\n\nEn la información de esta app:\n• Inicio automático: activado\n• Ahorro de batería (o Energía): Sin restricciones\n• Otros permisos → Mostrar ventanas emergentes en segundo plano: permitir\n\nDeslizar Daylock en Recientes o usar «Limpiar» aún puede detener el bloqueo. Si pasa, Hoy muestra un aviso: desactiva y activa Daylock en Accesibilidad.\n\nUsa los ajustes de esta app Daylock instalada; Daylock Dev y la versión de Play tienen ajustes distintos. Daylock no puede leer estas opciones de Xiaomi. Confírmalas tú abajo y prueba también aperturas normales.';

  @override
  String get setupLockNotConfirmed =>
      'Pantalla de bloqueo no confirmada. Comprueba que Accesibilidad esté conectada y vuelve a intentarlo. Android puede volver a Inicio o restringir la apertura de la pantalla de bloqueo. Abre Permisos y diagnóstico en Ajustes para ver el resultado registrado.';

  @override
  String get setupVerified =>
      'Verificado: Android mostró la pantalla de bloqueo de Daylock.';

  @override
  String get setupSaveProgressFailed =>
      'No se pudo guardar el progreso. Vuelve a intentarlo.';

  @override
  String get setupOpeningApp =>
      'Abriendo tu app seleccionada. Vuelve a Daylock después de comprobar la pantalla de bloqueo.';

  @override
  String get setupSaveConfirmationFailed =>
      'No se pudo guardar tu confirmación. Vuelve a intentarlo.';

  @override
  String get setupWelcomeBody =>
      'Planifica tu día. Gánate tu libertad. Cumple tus compromisos antes de que se desbloqueen las apps que te distraen.';

  @override
  String get setupWelcomePlan =>
      'Elige la noche anterior unos pocos compromisos que importen.';

  @override
  String get setupBlockDistractions => 'Bloquea distracciones';

  @override
  String get setupWelcomeBlock => 'Tú eliges qué apps restringir.';

  @override
  String get setupKeepYourWord => 'Cumple tu palabra';

  @override
  String get setupWelcomeKeep =>
      'Cumple los compromisos de hoy y luego fija el plan de mañana.';

  @override
  String get setupUnlockApps => 'Desbloquea apps';

  @override
  String get setupWelcomeUnlock =>
      'Llega a tu Hora de Libertad y disfruta del descanso que te has ganado.';

  @override
  String get setupXiaomiTitle => 'Xiaomi / Poco: mantén el bloqueo activo';

  @override
  String get setupOpenAppInfo => 'Abrir información de Daylock';

  @override
  String get setupXiaomiConfirm =>
      'He cambiado estos ajustes para esta app Daylock';

  @override
  String get setupXiaomiConfirmNote =>
      'Tu confirmación; no se verifica automáticamente.';

  @override
  String get setupAccessibilityTitle => 'Acceso de Accesibilidad · opcional';

  @override
  String get setupBlockingAndroidOnly =>
      'El bloqueo está disponible en Android. Aquí puedes seguir usando el planificador.';

  @override
  String get setupAccessibilityConnected =>
      'Activado y conectado. Daylock está listo para detectar las apps seleccionadas.';

  @override
  String get setupAccessibilityWaiting =>
      'Activado. Esperando a que Android conecte el servicio. Toca Actualizar al volver.';

  @override
  String get setupEnableAccessibility => 'Activar Accesibilidad';

  @override
  String get setupNotificationsTitle => 'Notificaciones · opcional';

  @override
  String get setupNotificationsAllowed =>
      'Permitidas. Pueden aparecer recordatorios locales y avisos de restricción de respaldo.';

  @override
  String get setupNotificationsExplain =>
      'Permite recordatorios locales y un aviso cuando Android no puede mostrar la pantalla de bloqueo. Puedes continuar sin notificaciones.';

  @override
  String get setupAllowNotifications => 'Permitir notificaciones';

  @override
  String get setupRefreshPermissions => 'Actualizar estado de permisos';

  @override
  String get setupChooseAppsBody =>
      'Elige las apps que quieres abrir con más intención. Tu selección se queda en este dispositivo.';

  @override
  String get setupRestrictionsEnableFreedom =>
      'Activar aquí las restricciones de apps también activa el Control de Libertad a tu Hora de Libertad guardada.';

  @override
  String get setupSaveBlockingFailed =>
      'No se pudieron guardar los ajustes de bloqueo. Vuelve a intentarlo.';

  @override
  String get setupAppSelectionAndroidOnly =>
      'La selección de apps instaladas está disponible en Android.';

  @override
  String get setupOneSmallStep => 'Un pequeño paso para mañana';

  @override
  String get setupSaveCommitmentFailed =>
      'No se pudo guardar tu compromiso. Vuelve a intentarlo.';

  @override
  String get setupCreateCommitment => 'Crear un compromiso';

  @override
  String get setupAlreadyHasCommitment =>
      'Tu plan ya tiene un compromiso. Puedes continuar sin crear otro.';

  @override
  String get setupTestTitle => 'Prueba tu restricción real';

  @override
  String get setupTestAndroidOnly =>
      'Las pruebas de bloqueo requieren la app de Android.';

  @override
  String get setupChecking => 'Comprobando…';

  @override
  String get setupTestSelectedApp => 'Probar una app seleccionada';

  @override
  String get setupEnableFreedomAndRestrictions =>
      'Activar Control de Libertad y restricciones';

  @override
  String setupTestNeedsFreedom(String state) {
    return 'Libertad actual: $state. La prueba real necesita el Control de Libertad activado y la Libertad aún sin ganar. Puedes salir de la configuración y volver desde Ajustes cuando se cumplan esas condiciones.';
  }

  @override
  String get setupAccessibilityNotConnected =>
      'Accesibilidad no está conectada. Vuelve a la configuración de permisos.';

  @override
  String get setupConfirmXiaomi =>
      'Vuelve a Configurar el bloqueo y confirma el ajuste de batería de Xiaomi para que el bloqueo siga funcionando.';

  @override
  String get setupRefreshRetry => 'Actualizar y reintentar';

  @override
  String get setupReadyTitle => 'Haz espacio para lo que importa';

  @override
  String get setupReadyBody =>
      'Tus preferencias y tu compromiso están guardados. Empieza por Hoy, planifica mañana y mira crecer tu Camino.';

  @override
  String get setupTourTitle => 'Haz un recorrido rápido';

  @override
  String get setupBlockingOff => 'El bloqueo de apps está desactivado';

  @override
  String get setupBlockingOffBody =>
      'Daylock no restringirá ninguna app. Si lo quieres más adelante, abre Ajustes y activa las restricciones de apps.';

  @override
  String get setupSkipTour => 'Saltar el recorrido';

  @override
  String get previousStep => 'Paso anterior';

  @override
  String get saveAndLeave => 'Guardar y salir';

  @override
  String stepNOfM(int current, int total) {
    return 'Paso $current de $total';
  }

  @override
  String get getStarted => 'Empezar';

  @override
  String get continueWithoutBlocking => 'Continuar sin bloqueo';

  @override
  String get skipTestForNow => 'Saltar la prueba por ahora';

  @override
  String get finishSetup => 'Terminar configuración';

  @override
  String get takeTheTour => 'Hacer el recorrido';

  @override
  String get goToDaylock => 'Ir a Daylock';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get setupTitleWelcome => 'Recupera el control';

  @override
  String get setupTitleBlocking => 'Configura el bloqueo';

  @override
  String get setupTitleApps => 'Elige tus distracciones';

  @override
  String get setupTitleCommitment => 'Tu primer compromiso';

  @override
  String get setupTitleTest => '¡Ya casi está!';

  @override
  String get setupTitleReady => '¡Todo listo!';

  @override
  String get diagLockUnconfirmed =>
      'Pantalla de bloqueo: no confirmada; puede usarse una notificación de respaldo.';

  @override
  String get diagLockFailedException =>
      'Pantalla de bloqueo: Android rechazó o no completó la apertura.';

  @override
  String get diagLockShown => 'Pantalla de bloqueo: visible y confirmada.';

  @override
  String get diagLockRequestedUnconfirmed =>
      'Pantalla de bloqueo: solicitud enviada; visibilidad aún no confirmada.';

  @override
  String get diagLockAttempted => 'Pantalla de bloqueo: apertura solicitada.';

  @override
  String get diagHomeRejected =>
      'Volver a Inicio: Android rechazó la solicitud.';

  @override
  String get diagHomeAccepted =>
      'Volver a Inicio: Android aceptó la solicitud.';

  @override
  String get diagHomeAttempted => 'Volver a Inicio: solicitado.';

  @override
  String get diagRestrictionOther =>
      'No se pudo verificar el último estado de restricción.';

  @override
  String get diagRestrictionSkippedLaunchThrottled =>
      'Restricción omitida: ya hay un intento de pantalla de bloqueo en curso.';

  @override
  String get diagRestrictionSkippedFreedomDisabled =>
      'Restricción omitida: el Control de Libertad está desactivado.';

  @override
  String get diagRestrictionSkippedFreedomEarned =>
      'Restricción omitida: la Libertad está ganada.';

  @override
  String get diagRestrictionSkippedStateChanged =>
      'Restricción omitida: el estado de la Libertad cambió al abrir la app.';

  @override
  String get diagRestrictionRetryingStateChanged =>
      'El estado de la Libertad cambió durante la aplicación; se comprueba una vez más.';

  @override
  String get diagRestrictionSkippedLockAlreadyVisible =>
      'Restricción omitida: ya había una pantalla de bloqueo de Daylock visible.';

  @override
  String get diagRestrictionSkippedServiceInactive =>
      'Restricción omitida: el servicio de Accesibilidad ya no estaba activo.';

  @override
  String get diagRestrictionSkippedDeviceNotInteractive =>
      'Restricción omitida: el dispositivo estaba bloqueado o inactivo.';

  @override
  String get diagRestrictionSkippedSelectionUnavailable =>
      'Restricción omitida: no se pudo verificar la app seleccionada.';

  @override
  String get diagRestrictionSkippedAccessibilityDisabled =>
      'Restricción omitida: Accesibilidad ya no está activada.';

  @override
  String get diagRestrictionSkippedForegroundChangedBeforeNavigation =>
      'Restricción omitida: la app en primer plano cambió antes de aplicarla.';

  @override
  String get diagRestrictionHomeFailed =>
      'Último intento: Android rechazó volver a Inicio. No se pudo aplicar la restricción.';

  @override
  String get diagRestrictionLockLaunchUnconfirmed =>
      'Último intento: pantalla de bloqueo no confirmada. Android puede restringir aperturas en segundo plano.';

  @override
  String get diagRestrictionHomeOnly =>
      'Último intento: se pidió volver a Inicio; pantalla de bloqueo no confirmada.';

  @override
  String get diagRestrictionLockFallbackUnavailable =>
      'Último intento: pantalla de bloqueo no confirmada. Permite las notificaciones y el canal Avisos de restricción en los ajustes de Android para recibir avisos de respaldo.';

  @override
  String get diagRestrictionLockFallbackPosted =>
      'Último intento: pantalla de bloqueo no confirmada; se envió una notificación de restricción. Android controla su entrega.';

  @override
  String get diagRestrictionLockLaunchRequested =>
      'Último intento: pantalla de bloqueo solicitada; aún no confirmada.';

  @override
  String get diagRestrictionStateUnknown =>
      'Último intento: apps seleccionadas permitidas porque el estado de la Libertad no estaba disponible.';

  @override
  String get diagRestrictionLockShown =>
      'Último intento: se mostró la pantalla de bloqueo de Daylock.';

  @override
  String get diagRestrictionRecoveryShown =>
      'Último intento: se mostró la pantalla de recuperación. Abre Daylock para actualizar los planes o desactivar el bloqueo.';

  @override
  String get diagRestrictionRestrictionRecovery =>
      'La restricción necesita que Daylock actualice el estado de la Libertad.';

  @override
  String get diagRestrictionRestrictionTriggered =>
      'Restricción activada: iniciando el bloqueo de Daylock.';

  @override
  String get diagRestrictionEligibilityUnknown =>
      'No se pudo confirmar la elegibilidad; el bloqueo se pausa por seguridad.';

  @override
  String get diagRestrictionEligibilityDisabled =>
      'Elegibilidad evaluada: el Control de Libertad está desactivado; la app está permitida.';

  @override
  String get diagRestrictionEligibilityEarned =>
      'Elegibilidad evaluada: la Libertad está ganada; la app está permitida.';

  @override
  String get diagRestrictionEligibilityNotEarned =>
      'Elegibilidad evaluada: la Libertad no está ganada.';

  @override
  String get diagRestrictionDetectedSelectedApp =>
      'App seleccionada detectada. Comprobando la Libertad y la restricción.';

  @override
  String get diagRestrictionTestRequested =>
      'Prueba solicitada: esperando una nueva detección de app seleccionada.';

  @override
  String get diagRestrictionSkippedEventDelayed =>
      'Android avisó de la apertura de la app demasiado tarde. En Xiaomi / HyperOS, revisa Información de la app Daylock → Energía → Sin restricciones y prueba a abrir una app seleccionada desde Inicio.';

  @override
  String get diagRestrictionNone => 'Aún no hay intentos de restricción.';

  @override
  String get diagEnableBlockingBody =>
      'Cuando el Control de Libertad está activado y la Libertad no está ganada, Daylock usa Accesibilidad para salir de una app seleccionada y mostrar su propia pantalla de bloqueo. La lista de apps instaladas y tu selección se quedan en este dispositivo. No lee el contenido de la pantalla ni recoge el historial de navegación. Solo la última detección y el último resultado de restricción se quedan en este dispositivo. Los demás nombres de paquete de ventanas solo se comparan para cancelar una acción pendiente si cambias de app; no se guardan. Puedes desactivar el bloqueo aquí o retirar el acceso de Accesibilidad cuando quieras.\n\nLos datos de Libertad siguen siendo válidos para su fecha sin volver a abrir Daylock. Si el estado actual falta o no es válido, Daylock ofrece una pantalla de recuperación con Abrir Daylock y Desactivar bloqueo; las aperturas siguientes se permiten mientras haga falta recuperar. Es una restricción voluntaria, no un sistema inviolable ni de control parental.';

  @override
  String get diagPermissionBody =>
      'Daylock usa la Accesibilidad de Android para detectar cuándo se abre una app seleccionada, incluso con Daylock en segundo plano. Solo guarda en este dispositivo la última detección, el estado de la Libertad y el resultado de la restricción; no se envía nada a ningún servidor. La lista de apps instaladas y tu selección se quedan en este dispositivo. No lee el contenido de la pantalla ni recoge el historial de navegación. Con el interruptor de restricciones activado, puede volver a Inicio y mostrar una pantalla de bloqueo de Daylock cuando la Libertad no está ganada. Los cambios de ventana solo se comparan para cancelar acciones si cambias de app; los nombres de otras apps no se guardan. No dibuja superposiciones ni restringe apps no seleccionadas.\n\nTú decides si activas «Restricciones de apps de Daylock» en los ajustes de Accesibilidad de Android. Puedes desactivarlo ahí cuando quieras.';

  @override
  String get diagPermissionTitle => 'Permiso de restricción de apps';

  @override
  String get diagAgreeOpenSettings => 'Aceptar y abrir Ajustes';

  @override
  String get diagEnableBlockingTitle => '¿Activar restricciones de apps?';

  @override
  String get diagEnableBlocking => 'Activar bloqueo';

  @override
  String get diagAppRestrictionsLabel => 'Restricciones de apps';

  @override
  String get diagAppRestrictionsIntro =>
      'Accesibilidad detecta cuándo se abren las apps seleccionadas en segundo plano. El bloqueo opcional muestra una pantalla de bloqueo de Daylock o vuelve a Inicio hasta ganar la Libertad. Si la pantalla no puede aparecer, una notificación explica el bloqueo cuando Android lo permite.';

  @override
  String get diagAppRestrictions => 'Restricciones de apps';

  @override
  String get diagSeparateFromFreedom =>
      'Independiente del Control de Libertad. Desactivado por defecto.';

  @override
  String get diagStatusUnavailable =>
      'Estado de las restricciones no disponible';

  @override
  String get diagRestrictionsOff => 'Restricciones de apps: desactivadas';

  @override
  String get diagWaitingForAccessibility =>
      'Restricciones de apps: esperando acceso de Accesibilidad';

  @override
  String get diagAllowedFreedomOff =>
      'Apps seleccionadas permitidas — Control de Libertad desactivado';

  @override
  String get diagAllowedFreedomEarned =>
      'Apps seleccionadas permitidas — Libertad ganada';

  @override
  String get diagBlockingPaused =>
      'Bloqueo en pausa — abre Daylock para actualizar la Libertad';

  @override
  String get diagRestrictionsReady =>
      'Restricciones listas — la apertura y la navegación dependen de Android';

  @override
  String get diagServiceStatusUnavailable =>
      'Estado del servicio no disponible';

  @override
  String get diagAndroidOnly =>
      'La detección nativa solo está disponible en Android.';

  @override
  String get diagServiceDisabled => 'Servicio de Accesibilidad: desactivado';

  @override
  String get diagServiceConnected =>
      'Servicio de Accesibilidad: activado y conectado';

  @override
  String get diagServiceWaiting =>
      'Servicio de Accesibilidad: activado — esperando a que Android lo conecte';

  @override
  String get diagBlockingSaveFailed =>
      'No se pudo guardar la opción de bloqueo. La desactivación se aplica ahora, pero puede no sobrevivir a un reinicio. Retira el acceso de Accesibilidad si hace falta.';

  @override
  String get diagNoDetectionYet =>
      'Aún no se ha detectado ninguna app seleccionada.';

  @override
  String diagLastDetection(String when) {
    return 'Última detección de app restringida: $when';
  }

  @override
  String diagFreedomAtDetection(String state) {
    return 'Libertad en esa detección: $state';
  }

  @override
  String diagCurrentFreedom(String state) {
    return 'Estado nativo actual de la Libertad: $state';
  }

  @override
  String get diagFocusNeedsRefresh =>
      'Una sesión de concentración activa necesita que Daylock actualice su temporizador. La detección nativa no la marca como completada.';

  @override
  String get diagStateUnavailable =>
      'El estado del día no está disponible. Abre Daylock para actualizar los planes o desactiva el bloqueo. Los datos válidos del día no caducan a los cinco minutos.';

  @override
  String get diagRolloverReconciled =>
      'Nuevo día: se usa el plan guardado para esta fecha. Abre Daylock para archivar el historial y preparar el día siguiente.';

  @override
  String get diagNoEligible =>
      'Sin compromisos válidos. Los días vacíos o justificados por completo no ganan Libertad.';

  @override
  String get diagDetectionSaveFailed =>
      'No se pudo guardar la última detección y puede no sobrevivir a un reinicio.';

  @override
  String get diagTurnBlockingOff => 'Desactivar bloqueo';

  @override
  String get diagSettingsPath =>
      'Ajustes de Android → Accesibilidad → Apps descargadas/instaladas → Restricciones de apps de Daylock. Activa el servicio a mano. Los nombres varían según el teléfono.';

  @override
  String get diagRestrictedSettings =>
      'Si Android 15 muestra «Ajustes restringidos», busca «Permitir ajustes restringidos» en la información de la app Daylock y confírmalo solo para una versión de desarrollo de confianza.';

  @override
  String get diagAvailableAndroidOnly => 'Solo disponible en Android';

  @override
  String get diagServiceEnabledShort => 'Servicio de Accesibilidad: activado';

  @override
  String get diagServiceDisconnected => 'Servicio desconectado';

  @override
  String get diagRestrictionsOn => 'Restricciones de apps: activadas';

  @override
  String selectedAppsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps seleccionadas',
      one: '1 app seleccionada',
    );
    return '$_temp0';
  }

  @override
  String diagNativeFreedom(String state) {
    return 'Libertad nativa: $state';
  }

  @override
  String get diagTechnicalDetails => 'Detalles técnicos y configuración';

  @override
  String diagLastPackage(String package) {
    return 'Último paquete restringido: $package';
  }

  @override
  String get openAccessibilitySettings => 'Abrir ajustes de Accesibilidad';

  @override
  String get refreshStatus => 'Actualizar estado';

  @override
  String get appsLoadFailed =>
      'No se pudieron cargar las apps instaladas. Tu selección guardada no se ha reemplazado.';

  @override
  String get appsPausedAttention =>
      'Restricciones en pausa: el estado requiere atención.';

  @override
  String get appsRestrictionsOff =>
      'Las restricciones de apps están desactivadas. Tu selección está guardada.';

  @override
  String get appsNoneSelected =>
      'No hay apps seleccionadas. No se restringe nada.';

  @override
  String get appsWaitingAccessibility =>
      'Esperando acceso de Accesibilidad. Las apps seleccionadas no están restringidas.';

  @override
  String get appsFreedomOff =>
      'El Control de Libertad está desactivado. Las apps seleccionadas están accesibles.';

  @override
  String get appsFreedomEarned =>
      'Libertad ganada. Las apps seleccionadas están accesibles.';

  @override
  String get appsNeedsRefresh =>
      'Hay que actualizar el estado de la Libertad. Hay recuperación disponible; se permiten aperturas repetidas.';

  @override
  String get appsRestricted =>
      'Las apps seleccionadas están restringidas hasta ganar la Libertad.';

  @override
  String selectedCountLabel(int count) {
    return 'Seleccionadas: $count';
  }

  @override
  String get refreshApps => 'Actualizar apps';

  @override
  String get appsMasterControl =>
      'Control principal para todas las apps seleccionadas.';

  @override
  String get appsMasterSaveFailed =>
      'No se pudo guardar el ajuste principal. Desactivarlo se aplica ahora, pero puede no sobrevivir a un reinicio.';

  @override
  String get appsChooseBelow =>
      'Elige las apps abajo. El Control de Libertad y las restricciones de apps son independientes. Se excluyen las apps de recuperación del sistema.';

  @override
  String appsRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Se quitaron de la selección $count apps no disponibles o reinstaladas. Vuelve a seleccionarlas si hace falta.',
      one: 'Se quitó de la selección 1 app no disponible o reinstalada. Vuelve a seleccionarla si hace falta.',
    );
    return '$_temp0';
  }

  @override
  String get appsNoneSelectedYet =>
      'Aún no hay apps seleccionadas. Elige las que quieras restringir.';

  @override
  String get searchApps => 'Buscar apps';

  @override
  String get appsSelectionRequiresAndroid =>
      'La selección de apps instaladas requiere Android.';

  @override
  String get retryAppDiscovery => 'Volver a buscar apps';

  @override
  String get appsNoneFound =>
      'No se encontraron apps compatibles en este perfil de Android.';

  @override
  String get appsNoMatches => 'No hay apps que coincidan.';

  @override
  String get appIconUnavailable => 'Icono no disponible';

  @override
  String get savingSelection => 'Guardando selección…';

  @override
  String get appsSelectionsStay =>
      'Tu selección se queda en este dispositivo. Las apps nuevas o reinstaladas deben seleccionarse expresamente.';

  @override
  String get notifRunningStopwatchHelp =>
      'Muestra una notificación discreta con Pausa mientras un cronómetro funciona y te avisa cada 2 horas para que no se quede encendido por error.';

  @override
  String get notifBlockedInSystem => 'Bloqueado en los ajustes de Android';

  @override
  String get notifLabel => 'Notificaciones';

  @override
  String get notifPermissionAllowed => 'Permiso del sistema: concedido';

  @override
  String get notifPermissionDenied => 'Permiso del sistema: no concedido';

  @override
  String get notifNeedsAttention =>
      'La configuración de notificaciones requiere atención';

  @override
  String get notifChecking => 'Comprobando el permiso del sistema…';

  @override
  String get notifUnavailable => 'Notificaciones programadas no disponibles';

  @override
  String get notifPermissionHelp => 'Ayuda con el permiso';

  @override
  String get notifOpenSettings => 'Abrir ajustes de notificaciones';

  @override
  String get notifPlanTomorrow => 'Planificar mañana';

  @override
  String get notifCommitmentReminder => 'Recordatorio de compromisos';

  @override
  String get notifFreedom => 'Notificaciones de Libertad';

  @override
  String get notifFreedomHelp =>
      'Usa la Hora de Libertad cuando el Control de Libertad está activado.';

  @override
  String get notifRunningStopwatch => 'Cronómetro en marcha';

  @override
  String get healthXiaomiTip =>
      'Para que no vuelva a pasar en Xiaomi / Poco: en la información de la app Daylock permite el inicio automático, pon el ahorro de batería en Sin restricciones, permite ventanas emergentes en segundo plano y evita deslizar Daylock en Recientes.';

  @override
  String get healthOffBody =>
      'El acceso de Accesibilidad de Daylock está desactivado, así que tus apps seleccionadas se abren libremente. Actívalo para recuperar el bloqueo.';

  @override
  String get healthStoppedBody =>
      'Android detuvo Daylock en segundo plano, así que tus apps seleccionadas se abren libremente. En Accesibilidad, desactiva y vuelve a activar Daylock.';

  @override
  String get healthStoppedTitle => 'El bloqueo de apps se ha detenido';

  @override
  String get openAccessibility => 'Abrir Accesibilidad';

  @override
  String get openAppInfo => 'Abrir información de la app';

  @override
  String get conditionSatisfied => 'Cumplido';

  @override
  String get conditionRemaining => 'Pendiente';

  @override
  String freedomTimeAt(String time) {
    return 'Hora de Libertad · $time';
  }

  @override
  String eligibleComplete(int kept, int total) {
    return '$kept / $total compromisos válidos completados';
  }

  @override
  String get noEligibleRequired =>
      'Sin compromisos válidos — hay que completarlos para ganar la Libertad.';

  @override
  String get tomorrowPlanCommittedCondition => 'Plan de mañana comprometido';

  @override
  String get planDateMismatch =>
      'El plan de hoy no coincide con la fecha local actual.';

  @override
  String availableAt(String time) {
    return 'Disponible a las $time';
  }

  @override
  String get enableFreedomInSettings =>
      'Activa el Control de Libertad en Ajustes.';

  @override
  String get pauseStopwatch => 'Pausar cronómetro';

  @override
  String get resumeStopwatch => 'Reanudar cronómetro';

  @override
  String get startStopwatch => 'Iniciar cronómetro';

  @override
  String get keptLower => 'cumplido';

  @override
  String keepTask(String name) {
    return 'Cumplir $name';
  }

  @override
  String get recordedTimeLabel => 'Tiempo registrado';

  @override
  String calendarDayExcusedNeutral(int count) {
    return 'Sin compromisos válidos, $count justificados, neutro';
  }

  @override
  String get calendarDayNeutral => 'Sin compromisos, neutro';

  @override
  String get calendarDayUnrecorded => 'Sin compromisos registrados, neutro';

  @override
  String calendarDayProgress(int kept, int total, int percent, int excused) {
    return '$kept de $total compromisos válidos completados, $percent por ciento, $excused justificados';
  }

  @override
  String get calendarTodaySuffix => ', hoy';

  @override
  String calendarDayValue(String description, int count) {
    return '$description, $count eventos programados';
  }

  @override
  String get heatNeutral =>
      'Neutro: sin compromisos válidos, sin historial o fecha futura';

  @override
  String get heatZero => 'Compromisos registrados: 0 por ciento completado';

  @override
  String get heatLow => 'Más de 0 a 25 por ciento completado';

  @override
  String get heatMedium => 'Más de 25 a 50 por ciento completado';

  @override
  String get heatHigh => 'Más de 50 a menos de 100 por ciento completado';

  @override
  String get heatComplete => '100 por ciento completado';

  @override
  String get heatLess => 'Menos';

  @override
  String get heatMore => 'Más';

  @override
  String get calTodayReadOnly =>
      'Compromisos de hoy, solo lectura. Gestiónalos en Hoy.';

  @override
  String get calHistoryReadOnly => 'Historial de compromisos, solo lectura';

  @override
  String get calTodayLabel => 'Compromisos de hoy';

  @override
  String get calHistoryLabel => 'Historial de compromisos';

  @override
  String get calNoHistory => 'No hay historial de compromisos registrado.';

  @override
  String get calNoCommitmentsToday => 'Sin compromisos para hoy.';

  @override
  String get calNeutralDay => 'Sin compromisos registrados. Día neutro.';

  @override
  String get calCompletionLabel =>
      'Compromisos completados en la fecha elegida';

  @override
  String calRecordedTime(String duration) {
    return 'Tiempo registrado: $duration';
  }

  @override
  String calCommitmentOutcome(String outcome) {
    return 'Compromiso · $outcome';
  }

  @override
  String calReason(String reason) {
    return 'Motivo: $reason';
  }

  @override
  String get calReadOnlyCached => 'Evento en caché de solo lectura';

  @override
  String editNamed(String name) {
    return 'Editar $name';
  }

  @override
  String deleteNamed(String name) {
    return 'Eliminar $name';
  }

  @override
  String get deleteEventTitle => '¿Eliminar el evento?';

  @override
  String deleteEventBody(String title) {
    return '¿Eliminar «$title» de tu agenda?';
  }

  @override
  String get calReadOnlyCachedShort => 'Solo lectura · evento en caché';

  @override
  String get close => 'Cerrar';

  @override
  String get previousMonth => 'Mes anterior';

  @override
  String get nextMonth => 'Mes siguiente';

  @override
  String get calendar => 'Calendario';

  @override
  String get calendarAccounts => 'Cuentas de calendario';

  @override
  String get addEvent => 'Añadir evento';

  @override
  String get scheduleLabel => 'Agenda';

  @override
  String get noEventsScheduled => 'No hay eventos programados.';

  @override
  String get eventTimeFormat => 'Usa HH:mm (00:00–23:59).';

  @override
  String get eventEndAfterStart => 'El final debe ser posterior al inicio.';

  @override
  String get readOnlyEvent => 'Evento de solo lectura';

  @override
  String get externalEventsReadOnly =>
      'Los eventos externos solo se pueden cambiar en su calendario.';

  @override
  String get editEvent => 'Editar evento';

  @override
  String get title => 'Título';

  @override
  String get enterTitle => 'Escribe un título.';

  @override
  String get startTimeOptional => 'Hora de inicio (opcional)';

  @override
  String get endTimeOptional => 'Hora de fin (opcional)';

  @override
  String get notesOptional => 'Notas (opcional)';

  @override
  String get saveEvent => 'Guardar evento';

  @override
  String get accountUpdateFailed =>
      'No se pudo actualizar esta cuenta. Los eventos en caché siguen disponibles. Vuelve a intentarlo o reconéctala.';

  @override
  String get disconnectAccountTitle => '¿Desconectar la cuenta?';

  @override
  String disconnectAccountBody(String name) {
    return '¿Quitar $name y sus eventos en caché de Daylock? Tu calendario externo no cambiará.';
  }

  @override
  String get disconnect => 'Desconectar';

  @override
  String get externalCalendarsReadOnly =>
      'Los calendarios externos son de solo lectura. Los eventos en caché están disponibles sin conexión.';

  @override
  String get providersDisabled =>
      'El inicio de sesión no está disponible para los proveedores desactivados en esta versión.';

  @override
  String connectProvider(String provider) {
    return 'Conectar $provider';
  }

  @override
  String get noConnectedAccounts => 'No hay cuentas conectadas.';

  @override
  String get syncNow => 'Sincronizar ahora';

  @override
  String get reconnect => 'Reconectar';

  @override
  String get notSyncedYet => 'Aún sin sincronizar';

  @override
  String lastSynced(String when) {
    return 'Última sincronización $when';
  }

  @override
  String get syncToLoad =>
      'Sincroniza para cargar los calendarios de esta cuenta.';

  @override
  String get chooseMonth => 'Elegir mes';

  @override
  String get previousYear => 'Año anterior';

  @override
  String get year => 'Año';

  @override
  String get enterYear => 'Escribe un año entre 1 y 9999.';

  @override
  String get nextYear => 'Año siguiente';

  @override
  String get showMonth => 'Mostrar mes';

  @override
  String get commitment => 'Compromiso';

  @override
  String repeatsLabel(String rule) {
    return 'Se repite: $rule';
  }

  @override
  String get areas => 'Áreas';

  @override
  String get areasIntro =>
      'Dale un hogar a tus compromisos. Tu área predeterminada se usa cuando no eliges otra.';

  @override
  String get createArea => 'Crear área';

  @override
  String get archived => 'Archivadas';

  @override
  String get defaultAlwaysAvailable => 'Predeterminada · Siempre disponible';

  @override
  String get restore => 'Restaurar';

  @override
  String get archive => 'Archivar';

  @override
  String get archivingExplainer =>
      'Archivar mantiene vinculados los compromisos y el historial. Los compromisos nuevos solo usan áreas activas.';

  @override
  String get editArea => 'Editar área';

  @override
  String get areaName => 'Nombre del área';

  @override
  String get icon => 'Icono';

  @override
  String get colour => 'Color';

  @override
  String get saveArea => 'Guardar área';

  @override
  String get areaIconLife => 'Vida';

  @override
  String get areaColourLavender => 'Lavanda';

  @override
  String get areaIconHealth => 'Salud';

  @override
  String get areaIconWork => 'Trabajo';

  @override
  String get areaIconLearning => 'Aprendizaje';

  @override
  String get areaIconHome => 'Hogar';

  @override
  String get areaIconPeople => 'Personas';

  @override
  String get areaIconCreative => 'Creatividad';

  @override
  String get areaIconFitness => 'Ejercicio';

  @override
  String get areaColourBlue => 'Azul';

  @override
  String get areaColourTeal => 'Verde azulado';

  @override
  String get areaColourGreen => 'Verde';

  @override
  String get areaColourAmber => 'Ámbar';

  @override
  String get areaColourRose => 'Rosa';

  @override
  String get newAchievement => 'Nuevo logro';

  @override
  String get editAchievement => 'Editar logro';

  @override
  String get achievementPrompt => '¿De qué estás orgulloso?';

  @override
  String get achievementHint => 'Aprobé el examen de conducir';

  @override
  String get achievementNotes => 'Unas palabras (opcional)';

  @override
  String get linkToArea => 'Vincular a un área';

  @override
  String get optional => 'Opcional';

  @override
  String get previousAreaUnavailable =>
      'El área anterior no está disponible. Elige un área o quita el vínculo.';

  @override
  String get saveAchievement => 'Guardar logro';

  @override
  String illustrationLabel(String name) {
    return 'Ilustración: $name';
  }

  @override
  String illustrationAutomaticLabel(String name) {
    return 'Ilustración: automática · $name';
  }

  @override
  String get illustrationHelp =>
      'Elige un estilo o deja que el título y el área sugieran uno.';

  @override
  String get automatic => 'Automática';

  @override
  String get area => 'Área';

  @override
  String get notifExplainAndroid =>
      'Los recordatorios de Android pueden retrasarse por el ahorro de batería o No molestar. Las preferencias de abajo son independientes del permiso del sistema.';

  @override
  String get notifExplainError =>
      'No se pudieron actualizar las notificaciones. Vuelve a abrir Daylock para reintentarlo.';

  @override
  String get notifExplainDefault =>
      'Las notificaciones programadas están disponibles en Android.';

  @override
  String get notifExplainWebSupported =>
      'Este navegador admite notificaciones, pero aquí no hay recordatorios programados. Safari, las pestañas cerradas y las PWA instaladas no pueden recibirlos sin un servicio push. Usa Daylock en Android para las notificaciones programadas.';

  @override
  String get notifExplainWebUnsupported =>
      'Este navegador no puede recibir notificaciones de Daylock. Los recordatorios programados están disponibles en la app de Android; los controles web/PWA están desactivados.';

  @override
  String get detectionReadFailed =>
      'No se pudo leer el estado de la detección nativa. Actualiza o abre los ajustes de Android manualmente.';

  @override
  String get calFailAuthMicrosoft =>
      'El acceso al calendario de Microsoft necesita renovar el permiso. Reconecta esta cuenta. Tu organización puede exigir la aprobación de un administrador. Los eventos en caché siguen disponibles.';

  @override
  String get calFailAuthGoogle =>
      'El permiso de Google Calendar ha caducado o se ha retirado. Reconecta esta cuenta. Los eventos en caché siguen disponibles.';

  @override
  String get calFailConfigMicrosoft =>
      'El inicio de sesión de Microsoft no está bien configurado. Revisa el ID de cliente de Entra, la URI de redirección nativa y los tipos de cuenta admitidos.';

  @override
  String get calFailConfigGoogle =>
      'El inicio de sesión de Google no está bien configurado. Revisa el ID de cliente OAuth, el paquete de Android y el certificado de firma.';

  @override
  String get calFailUnavailableMicrosoft =>
      'El calendario de Microsoft no está disponible. Revisa tu conexión y vuelve a intentarlo. Las cuentas de trabajo necesitan un buzón de Exchange accesible. Los eventos en caché siguen disponibles.';

  @override
  String get calFailUnavailableGoogle =>
      'Google Calendar no está disponible. Revisa tu conexión y vuelve a sincronizar. Los eventos en caché siguen disponibles.';

  @override
  String get calFailResponseMicrosoft =>
      'Microsoft devolvió una respuesta de calendario incompleta o no compatible. Los eventos en caché siguen disponibles. Inténtalo más tarde.';

  @override
  String get calFailResponseGoogle =>
      'Google devolvió una respuesta de calendario incompleta o no compatible. Los eventos en caché siguen disponibles. Inténtalo más tarde.';

  @override
  String get calFailAdminConsent =>
      'Tu organización exige la aprobación de un administrador o restringe este inicio de sesión. Contacta con tu administrador de TI. Los eventos en caché siguen disponibles.';

  @override
  String get calFailAccountMismatch =>
      'Elige la misma cuenta y organización de Microsoft al reconectar. Se han conservado las cuentas y los eventos en caché.';

  @override
  String get channelPlan => 'Planificar mañana';

  @override
  String get channelCommitments => 'Recordatorios de compromisos';

  @override
  String get channelFreedom => 'Libertad';

  @override
  String get channelFocus => 'Cronómetro en marcha';

  @override
  String get selectionLoadFailed =>
      'No se pudieron cargar ni guardar las apps restringidas. Las restricciones están en pausa. Actualiza para reintentarlo.';

  @override
  String get selectionSaveFailed =>
      'No se pudo guardar la selección de apps. Las restricciones están en pausa. Actualiza para reintentarlo.';

  @override
  String totalAchievements(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'logros',
      one: 'logro',
    );
    return '$_temp0';
  }

  @override
  String get breaksTitle => 'Descansos';

  @override
  String get breaksIntro =>
      'Tomados desde la pantalla de bloqueo en los últimos 30 días, con tus motivos.';

  @override
  String breakEntryTitle(String app, String when) {
    return '$app · $when';
  }

  @override
  String get diagRestrictionSkippedBreakActive =>
      'Restricción omitida: hay un descanso de 15 minutos en curso.';
}

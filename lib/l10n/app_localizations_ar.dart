// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Daylock';

  @override
  String get appearanceDark => 'داكن';

  @override
  String get appearanceLight => 'فاتح';

  @override
  String get appearanceSystem => 'النظام';

  @override
  String get colourViolet => 'بنفسجي';

  @override
  String get colourOcean => 'محيط';

  @override
  String get colourForest => 'غابة';

  @override
  String get colourEmber => 'جمر';

  @override
  String get colourRose => 'وردي';

  @override
  String get colourMono => 'أحادي';

  @override
  String get illustrationCelebration => 'احتفال';

  @override
  String get illustrationDriving => 'قيادة';

  @override
  String get illustrationAward => 'جائزة';

  @override
  String get illustrationCooking => 'طبخ';

  @override
  String get illustrationTravel => 'سفر';

  @override
  String get illustrationFitness => 'لياقة';

  @override
  String get illustrationLearning => 'تعلّم';

  @override
  String get illustrationHealth => 'صحة';

  @override
  String get illustrationWork => 'عمل';

  @override
  String get illustrationHome => 'منزل';

  @override
  String get illustrationPeople => 'أشخاص';

  @override
  String get illustrationCreativity => 'إبداع';

  @override
  String get illustrationSunrise => 'شروق';

  @override
  String get outcomeIncomplete => 'غير مكتمل';

  @override
  String get outcomeCompleted => 'مكتمل';

  @override
  String get outcomeExcused => 'معفى';

  @override
  String get sourceLocal => 'محلي';

  @override
  String get sourceGoogle => 'تقويم Google';

  @override
  String get sourceMicrosoftPersonal => 'Microsoft شخصي';

  @override
  String get sourceMicrosoftWorkSchool => 'Microsoft للعمل أو الدراسة';

  @override
  String get freedomStateEarned => 'مكتسبة';

  @override
  String get freedomStateNotEarned => 'غير مكتسبة';

  @override
  String get freedomStateControlOff => 'التحكم متوقف';

  @override
  String get freedomStateUnknown => 'غير معروف';

  @override
  String get listSeparator => '، ';

  @override
  String get repeatDaily => 'يوميًا';

  @override
  String repeatEveryDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'كل $count يوم',
      many: 'كل $count يومًا',
      few: 'كل $count أيام',
      two: 'كل يومين',
      one: 'كل يوم',
    );
    return '$_temp0';
  }

  @override
  String get repeatWeekdays => 'أيام الأسبوع';

  @override
  String get repeatWeekends => 'عطلة نهاية الأسبوع';

  @override
  String get eventContinuesAllDay => 'يستمر طوال اليوم';

  @override
  String get eventEarlier => 'سابقًا';

  @override
  String get eventNextDay => 'اليوم التالي';

  @override
  String eventUntil(String time) {
    return 'حتى $time';
  }

  @override
  String get eventAllDay => 'طوال اليوم';

  @override
  String durationMinutes(int minutes) {
    return '$minutes د';
  }

  @override
  String get durationUnderMinute => 'أقل من دقيقة';

  @override
  String durationHours(int hours) {
    return '$hours س';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours س $minutes د';
  }

  @override
  String get settingsFreedomControl => 'التحكم في الحرية';

  @override
  String get settingsPlanningRoutines => 'التخطيط والروتين';

  @override
  String get settingsAppearance => 'المظهر';

  @override
  String get settingsNotifications => 'الإشعارات';

  @override
  String get settingsAbout => 'حول';

  @override
  String get settingsRestrictedApps => 'التطبيقات المقيّدة';

  @override
  String get settingsPermissionsDiagnostics => 'الأذونات والتشخيص';

  @override
  String get settingsManageRoutines => 'إدارة الروتين';

  @override
  String routineCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count روتين',
      many: '$count روتينًا',
      few: '$count روتينات',
      two: 'روتينان',
      one: 'روتين واحد',
      zero: 'لا روتين',
    );
    return '$_temp0';
  }

  @override
  String get settingsRoutinesIntro => 'خطّط لخطواتك القادمة بالتزامات متكررة.';

  @override
  String get settingsNotificationsUnavailable =>
      'الإشعارات غير متاحة على هذا الجهاز.';

  @override
  String get keepYourWord => 'أوفِ بوعدك.';

  @override
  String get settingsAboutCommitments =>
      'التزامات، وساعات إيقاف اختيارية، وتقدّم في المجالات التي تهمّك.';

  @override
  String get settingsRestrictedIntro =>
      'اختر تطبيقات Android التي تُقيَّد حتى تكسب الحرية.';

  @override
  String get settingsRestrictionsAndroidOnly =>
      'تقييد التطبيقات متاح على Android.';

  @override
  String get settingsDiagnosticsAndroidOnly =>
      'تشخيص سهولة الاستخدام متاح على Android.';

  @override
  String get freedomTime => 'وقت الحرية';

  @override
  String get settingsRestrictionNeedsAttention =>
      'حالة تقييد التطبيقات تحتاج إلى انتباه';

  @override
  String settingsSelectedSwitchOn(int count) {
    return 'المحدد: $count، مفعّل';
  }

  @override
  String settingsSelectedSwitchOff(int count) {
    return 'المحدد: $count، متوقف';
  }

  @override
  String get accessibility => 'سهولة الاستخدام';

  @override
  String get statusUnavailable => 'الحالة غير متاحة';

  @override
  String get availableOnAndroid => 'متاح على Android';

  @override
  String get serviceConnected => 'الخدمة متصلة';

  @override
  String get waitingForConnection => 'بانتظار الاتصال';

  @override
  String get serviceDisabled => 'الخدمة متوقفة';

  @override
  String get settingsChooseInstalledApps => 'اختر تطبيقات Android المثبتة';

  @override
  String get settingsFreedomSubtitle =>
      'التطبيقات المقيّدة ووقت الحرية والأذونات';

  @override
  String get on => 'مفعّل';

  @override
  String get off => 'متوقف';

  @override
  String get settingsPlanningSubtitle => 'الالتزامات المتكررة والتخطيط';

  @override
  String get settingsAppearanceSubtitle => 'السمة والألوان والمجالات';

  @override
  String get settingsNotificationsSubtitle => 'التذكيرات والتنبيهات';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsRunSetup => 'إعادة تشغيل الإعداد';

  @override
  String get settingsRunSetupSubtitle => 'الأذونات والمشتّتات والتزامك الأول';

  @override
  String get settingsTakeTour => 'جولة في التطبيق';

  @override
  String get settingsTakeTourSubtitle =>
      'نظرة موجّهة على اليوم والتخطيط والمسيرة';

  @override
  String get settingsAboutSubtitle => 'معلومات التطبيق';

  @override
  String get tagline => 'خطّط ليومك. واكسب حريتك.';

  @override
  String get freedomStatusUnavailable => 'حالة الحرية غير متاحة';

  @override
  String get freedomControlOff => 'التحكم في الحرية متوقف';

  @override
  String get appearanceFollowsDevice => 'يتبع مظهر جهازك.';

  @override
  String appearanceFixed(String mode) {
    return 'المظهر $mode في أي وضع للجهاز.';
  }

  @override
  String get appearanceColourTheme => 'سمة الألوان';

  @override
  String get appearanceLivePreview => 'معاينة مباشرة';

  @override
  String get manageAreas => 'إدارة المجالات';

  @override
  String activeAreas(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مجال نشط',
      many: '$count مجالًا نشطًا',
      few: '$count مجالات نشطة',
      two: 'مجالان نشطان',
      one: 'مجال نشط واحد',
      zero: 'لا مجالات نشطة',
    );
    return '$_temp0';
  }

  @override
  String get appearancePreviewLabel => 'معاينة المظهر. مثال على شكل الالتزام.';

  @override
  String get today => 'اليوم';

  @override
  String get appearancePreviewComplete => '1 / 2 مكتمل';

  @override
  String get appearancePreviewProgress => 'مثال على التقدم';

  @override
  String get appearancePreviewRecorded => '23:00 مسجّلة';

  @override
  String keptTaskAnnouncement(String name) {
    return 'تم إنجاز $name';
  }

  @override
  String todayEarnedTomorrowLocked(String weekday) {
    return 'وفيت بوعدك، و$weekday ملتزم به مسبقًا. استمتع.';
  }

  @override
  String get todayEarned => 'وفيت بوعدك. استمتع.';

  @override
  String get commitments => 'الالتزامات';

  @override
  String get taskActions => 'إجراءات الالتزام';

  @override
  String get showFewerCommitments => 'عرض التزامات أقل';

  @override
  String showAllCommitments(int count) {
    return 'عرض كل الالتزامات ($count)';
  }

  @override
  String excusedCount(int count) {
    return 'المعفى: $count';
  }

  @override
  String keptName(String name) {
    return 'تم: $name';
  }

  @override
  String get undo => 'تراجع';

  @override
  String timedHoursMinutes(int hours, int minutes) {
    return '$hours س $minutes د';
  }

  @override
  String timedMinutesSeconds(int minutes, int seconds) {
    return '$minutes د $seconds ث';
  }

  @override
  String timedSeconds(int seconds) {
    return '$seconds ث';
  }

  @override
  String get noEligibleCommitments => 'لا التزامات محتسبة';

  @override
  String keptOfEligible(int kept, int total) {
    return '$kept من $total منجزة';
  }

  @override
  String get excusedDontCount => 'الالتزامات المعفاة لا تُحتسب';

  @override
  String get dayComplete => 'اكتمل اليوم';

  @override
  String moreUntilSunUp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بقي $count وتشرق الشمس',
      two: 'بقي اثنان وتشرق الشمس',
      one: 'بقي واحد وتشرق الشمس',
    );
    return '$_temp0';
  }

  @override
  String timedSuffix(String duration) {
    return '$duration مؤقّتة';
  }

  @override
  String get commitmentsComplete => 'اكتملت الالتزامات';

  @override
  String get todayRestrictionsInSettings =>
      'يُضبط تقييد التطبيقات في الإعدادات.';

  @override
  String get freedomEarned => 'تم كسب الحرية';

  @override
  String get showFreedomDetails => 'عرض تفاصيل الحرية';

  @override
  String appsUnlockedAt(String time) {
    return 'فُتحت التطبيقات الساعة $time';
  }

  @override
  String get freedomEarnedTitle => 'تم كسب الحرية.';

  @override
  String get freedomNotYetEarned => 'لم تُكسب الحرية بعد';

  @override
  String get freedomOffDetail => 'استعد تطبيقاتك بالوفاء بوعدك.';

  @override
  String get appsStayLockedToday => 'تبقى التطبيقات مقفلة اليوم';

  @override
  String get emptyDayDetail => 'اليوم الفارغ لا يكسبك الحرية. التزم بخطة للغد.';

  @override
  String appsUnlockAt(String time) {
    return 'تُفتح التطبيقات الساعة $time';
  }

  @override
  String keepMoreToEarn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أنجز $count أخرى لتكسبها',
      two: 'أنجز اثنين آخرين لتكسبها',
      one: 'أنجز واحدًا آخر لتكسبها',
    );
    return '$_temp0';
  }

  @override
  String get commitTomorrowToEarn => 'التزم بخطة الغد لتكسبها';

  @override
  String get waitingForFreedomTime => 'بانتظار وقت الحرية';

  @override
  String everythingKeptUnlockAt(String time) {
    return 'أُنجز كل شيء. تُفتح التطبيقات الساعة $time';
  }

  @override
  String get turnOn => 'تفعيل';

  @override
  String get hideFreedomDetails => 'إخفاء تفاصيل الحرية';

  @override
  String get aClearDay => 'يوم صافٍ.';

  @override
  String allSetFor(String weekday) {
    return 'كل شيء جاهز ليوم $weekday.';
  }

  @override
  String get emptyTodayNoPlan =>
      'لا التزامات اليوم. خطّط للغد، فشمس الغد بين يديك.';

  @override
  String get emptyTodayLocked =>
      'لا شيء مخطط اليوم، والغد مثبّت. الراحة هي الخطة.';

  @override
  String weekdayCommitmentCount(String weekday, int count) {
    return '$weekday: $count';
  }

  @override
  String get view => 'عرض';

  @override
  String get planTomorrow => 'خطّط للغد';

  @override
  String get repeatNever => 'أبدًا';

  @override
  String get repeatCustom => 'مخصص…';

  @override
  String get repeat => 'التكرار';

  @override
  String get repeatClose => 'إغلاق خيارات التكرار';

  @override
  String get repeatDaysOfWeek => 'أيام الأسبوع';

  @override
  String get repeatEveryNDays => 'كل عدد من الأيام';

  @override
  String get repeatEvery => 'كل';

  @override
  String get repeatFewerDays => 'أيام أقل';

  @override
  String get repeatMoreDays => 'أيام أكثر';

  @override
  String get repeatPickOneDay => 'اختر يومًا واحدًا على الأقل.';

  @override
  String get repeatOnlyThisDay => 'هذا اليوم فقط. لن يتكرر.';

  @override
  String repeatNext(String dates) {
    return 'التالي: $dates';
  }

  @override
  String get done => 'تم';

  @override
  String get editCommitment => 'تعديل الالتزام';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get removeCommitmentTitle => 'إزالة الالتزام؟';

  @override
  String removeFromDraft(String name) {
    return 'إزالة $name من مسودة الغد؟';
  }

  @override
  String get cancel => 'إلغاء';

  @override
  String get remove => 'إزالة';

  @override
  String areaFor(String name) {
    return 'مجال $name';
  }

  @override
  String lockInWeekdayQuestion(String weekday) {
    return 'تثبيت يوم $weekday؟';
  }

  @override
  String lockInConfirmOne(String weekday) {
    return 'سيُثبَّت التزامك ليوم $weekday. لن تتمكن من إضافة شيء أو تغييره.';
  }

  @override
  String lockInConfirmMany(int count, String weekday) {
    return 'ستُثبَّت التزاماتك ($count) ليوم $weekday. لن تتمكن من إضافة شيء أو تغييرها.';
  }

  @override
  String get keepPlanning => 'متابعة التخطيط';

  @override
  String get lockItIn => 'تثبيت';

  @override
  String get plan => 'التخطيط';

  @override
  String tomorrowDate(String date) {
    return 'الغد · $date';
  }

  @override
  String get committed => 'ملتزم به';

  @override
  String get draft => 'مسودة';

  @override
  String get schedule => 'الجدول';

  @override
  String get noScheduledEventsTomorrow => 'لا أحداث مجدولة للغد.';

  @override
  String scheduledEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count حدث مجدول',
      many: '$count حدثًا مجدولًا',
      few: '$count أحداث مجدولة',
      two: 'حدثان مجدولان',
      one: 'حدث مجدول واحد',
      zero: 'لا أحداث مجدولة',
    );
    return '$_temp0';
  }

  @override
  String commitmentsCount(int count) {
    return 'الالتزامات · $count';
  }

  @override
  String get add => 'إضافة';

  @override
  String get addACommitment => 'إضافة التزام';

  @override
  String get noCommitmentsPlanned => 'لا التزامات مخططة بعد.';

  @override
  String get tomorrowIsLocked => 'الغد مثبّت.';

  @override
  String get addOneSmallStep => 'أضف خطوة صغيرة للغد.';

  @override
  String lockInWeekday(String weekday) {
    return 'تثبيت يوم $weekday';
  }

  @override
  String addOneToLockIn(String weekday) {
    return 'أضف التزامًا واحدًا على الأقل لتثبيت يوم $weekday.';
  }

  @override
  String get locksThisCommitment =>
      'يثبّت هذا الالتزام. لن تتمكن من تغييره بعدها.';

  @override
  String locksTheseCommitments(int count) {
    return 'يثبّت هذه الالتزامات ($count). لن تتمكن من تغييرها بعدها.';
  }

  @override
  String archivedArea(String name) {
    return '$name (مؤرشف)';
  }

  @override
  String actionsFor(String name) {
    return 'إجراءات $name';
  }

  @override
  String get removeCommitment => 'إزالة الالتزام';

  @override
  String get tomorrowPlanCommitted => 'خطة الغد ملتزم بها.';

  @override
  String get yourCommitmentsLocked => 'التزاماتك مثبّتة.';

  @override
  String get nextTomorrow => 'التالي: غدًا';

  @override
  String nextDate(String date) {
    return 'التالي: $date';
  }

  @override
  String rotationSummary(int count, String name) {
    return 'الخطوات: $count · التالية: $name';
  }

  @override
  String get deleteRoutineTitle => 'حذف الروتين؟';

  @override
  String deleteRoutineBody(String name) {
    return 'إيقاف تكرار $name؟ تبقى الالتزامات الموجودة في خططك وسجلك.';
  }

  @override
  String get delete => 'حذف';

  @override
  String get routines => 'الروتين';

  @override
  String get routinesIntro =>
      'يُضاف الروتين تلقائيًا إلى خطة الغد في أيامه. أزل أحدها من خطة لتتخطى ذلك اليوم فقط. التناوب متعدد الخطوات لا يتقدم إلا عندما تبقى الخطوة في خطتك.';

  @override
  String get createRoutineOrRotation => 'إنشاء روتين أو تناوب';

  @override
  String get noRoutinesYet => 'لا روتين بعد.';

  @override
  String get edit => 'تعديل';

  @override
  String get newRoutineStep => 'خطوة جديدة';

  @override
  String get editRoutineStep => 'تعديل الخطوة';

  @override
  String get addStep => 'إضافة الخطوة';

  @override
  String get saveStep => 'حفظ الخطوة';

  @override
  String get createRoutine => 'إنشاء روتين';

  @override
  String get editRoutine => 'تعديل الروتين';

  @override
  String get routineName => 'اسم الروتين';

  @override
  String get routineRotationHelp =>
      'تناوب: كل يوم مستحق يضيف الخطوة التالية بهذا الترتيب. الخطوة التي تزيلها تعود في المرة القادمة.';

  @override
  String get routineSingleHelp =>
      'يُضاف هذا تلقائيًا إلى خطة الغد في كل يوم مستحق. أضف خطوات أخرى لإنشاء تناوب.';

  @override
  String editStepN(int number) {
    return 'تعديل الخطوة $number';
  }

  @override
  String moveStepUp(int number) {
    return 'نقل الخطوة $number لأعلى';
  }

  @override
  String moveStepDown(int number) {
    return 'نقل الخطوة $number لأسفل';
  }

  @override
  String removeStepN(int number) {
    return 'إزالة الخطوة $number';
  }

  @override
  String get addCommitment => 'إضافة الالتزام';

  @override
  String get addRotationStep => 'إضافة خطوة تناوب';

  @override
  String get saveRoutine => 'حفظ الروتين';

  @override
  String get newCommitment => 'التزام جديد';

  @override
  String get partOfRotation => 'جزء من تناوب. غيّره من الروتين.';

  @override
  String get commitmentHint => 'خطوة صغيرة ومحددة';

  @override
  String get closeEditor => 'إغلاق المحرر';

  @override
  String get commitmentName => 'اسم الالتزام';

  @override
  String get statusKept => 'مُنجز';

  @override
  String get statusNotKeptYet => 'لم يُنجز بعد';

  @override
  String durationRecorded(String duration) {
    return '$duration مسجّلة';
  }

  @override
  String get excuseReason => 'سبب الإعفاء';

  @override
  String get markCompleted => 'وضع علامة مكتمل';

  @override
  String get excuseTask => 'إعفاء';

  @override
  String get resetToIncomplete => 'إعادة إلى غير مكتمل';

  @override
  String get excuseCommitment => 'إعفاء الالتزام';

  @override
  String get excusePrompt => 'ما الظرف الخارجي الذي منعك من إنجازه؟';

  @override
  String get reason => 'السبب';

  @override
  String get enterShortReason => 'اكتب سببًا قصيرًا.';

  @override
  String get shortenReason => 'يُرجى اختصار هذا السبب.';

  @override
  String durationMinutesSeconds(int minutes, int seconds) {
    return '$minutes د $seconds ث';
  }

  @override
  String get loadFailed => 'تعذّر تحميل التزاماتك المحفوظة.';

  @override
  String get loadingDay => 'جارٍ تجهيز يومك.';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get loadingCommitments => 'جارٍ تحميل الالتزامات';

  @override
  String get journey => 'المسيرة';

  @override
  String dayStreakLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'سلسلة $count يوم',
      many: 'سلسلة $count يومًا',
      few: 'سلسلة $count أيام',
      two: 'سلسلة يومين',
      one: 'سلسلة يوم واحد',
      zero: 'سلسلة 0 أيام',
    );
    return '$_temp0';
  }

  @override
  String dayStreakWord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'يوم متتالٍ',
      many: 'يومًا متتاليًا',
      few: 'أيام متتالية',
      two: 'يومان متتاليان',
      one: 'يوم متتالٍ',
    );
    return '$_temp0';
  }

  @override
  String get streakStartHint => 'أنجز كل التزامات اليوم لتبدأ سلسلة';

  @override
  String get streakLongestYet => 'أطول سلسلة لك';

  @override
  String streakLongest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'الأطول: $count يوم',
      many: 'الأطول: $count يومًا',
      few: 'الأطول: $count أيام',
      two: 'الأطول: يومان',
      one: 'الأطول: يوم واحد',
    );
    return '$_temp0';
  }

  @override
  String get totalKept => 'منجزة';

  @override
  String get totalFocused => 'مؤقّتة';

  @override
  String shortMinutes(int minutes) {
    return '$minutes د';
  }

  @override
  String shortHours(int hours) {
    return '$hours س';
  }

  @override
  String get achievements => 'الإنجازات';

  @override
  String seeAll(int count) {
    return 'عرض الكل ($count)';
  }

  @override
  String get addAchievement => 'إضافة إنجاز';

  @override
  String get last5Weeks => 'آخر 5 أسابيع';

  @override
  String get dailyHistory => 'السجل اليومي';

  @override
  String get yourAreas => 'مجالاتك';

  @override
  String get manage => 'إدارة';

  @override
  String get pastChapters => 'فصول سابقة';

  @override
  String get areasArchived => 'المجالات المؤرشفة';

  @override
  String achievementSemantics(String title, String date) {
    return 'إنجاز: $title، $date';
  }

  @override
  String get areaUnavailable => 'المجال غير متاح';

  @override
  String get keepAMoment => 'احتفظ بلحظة مهمة.';

  @override
  String get addAnAchievement => 'إضافة إنجاز';

  @override
  String get achievementExamples => 'رخصة قيادة، أول 10 كم، فصل مكتمل.';

  @override
  String last5WeeksKept(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'آخر 5 أسابيع: $count يوم منجز بالكامل',
      many: 'آخر 5 أسابيع: $count يومًا منجزًا بالكامل',
      few: 'آخر 5 أسابيع: $count أيام منجزة بالكامل',
      two: 'آخر 5 أسابيع: يومان منجزان بالكامل',
      one: 'آخر 5 أسابيع: يوم واحد منجز بالكامل',
      zero: 'آخر 5 أسابيع: لا أيام منجزة بالكامل',
    );
    return '$_temp0';
  }

  @override
  String get legendAllKept => 'كلها منجزة';

  @override
  String get legendSomeKept => 'بعضها منجز';

  @override
  String get legendMissed => 'فائت';

  @override
  String keptThisWeek(int count) {
    return '$count هذا الأسبوع';
  }

  @override
  String areaKeptThisWeek(String area, int count) {
    return '$area: $count منجزة هذا الأسبوع';
  }

  @override
  String get last30Days => 'آخر 30 يومًا';

  @override
  String get allTime => 'كل الأوقات';

  @override
  String completedCommitments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count التزام مكتمل',
      many: '$count التزامًا مكتملًا',
      few: '$count التزامات مكتملة',
      two: 'التزامان مكتملان',
      one: 'التزام مكتمل واحد',
      zero: 'لا التزامات مكتملة',
    );
    return '$_temp0';
  }

  @override
  String recordedTime(String duration) {
    return '$duration من الوقت المسجّل';
  }

  @override
  String get stopwatchExplainer =>
      'تسجّل ساعة الإيقاف الجهد الفعلي، حتى للالتزامات غير المكتملة.';

  @override
  String get activityOverTime => 'النشاط عبر الزمن';

  @override
  String get trackedTime => 'الوقت المتتبَّع';

  @override
  String get achievementsPlace => 'مكان للحظات التي تريد تذكّرها.';

  @override
  String get recordedCommitments => 'الالتزامات المسجّلة';

  @override
  String recordsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سجل',
      many: '$count سجلًا',
      few: '$count سجلات',
      two: 'سجلان',
      one: 'سجل واحد',
      zero: 'لا سجلات',
    );
    return '$_temp0';
  }

  @override
  String get recordsEmpty => 'ستظهر التزاماتك المسجّلة هنا.';

  @override
  String get recordedTimeEmpty => 'سيظهر الوقت المسجّل هنا.';

  @override
  String get completedEmpty => 'ستظهر الالتزامات المكتملة هنا.';

  @override
  String get activityDetails => 'تفاصيل النشاط';

  @override
  String activityRange(String from, String through, String value) {
    return 'من $from إلى $through: $value';
  }

  @override
  String activityDescriptionTime(String days) {
    return 'آخر 30 يومًا، الوقت المسجّل. $days';
  }

  @override
  String activityDescriptionCompleted(String days) {
    return 'آخر 30 يومًا، الالتزامات المكتملة. $days';
  }

  @override
  String get thirtyDaysTime => '30 يومًا · الوقت';

  @override
  String get thirtyDaysCompleted => '30 يومًا · المكتملة';

  @override
  String completedCount(int count) {
    return 'المكتملة: $count';
  }

  @override
  String get openSpace => 'مساحة مفتوحة';

  @override
  String get openArea => 'فتح المجال';

  @override
  String get latestAchievement => 'أحدث إنجاز';

  @override
  String get pastChaptersIntro => 'أجزاء من حياتك، محفوظة هنا لتعود إليها.';

  @override
  String get pastChaptersEmpty => 'ستبقى المجالات المؤرشفة هنا مع سجلها.';

  @override
  String get savePendingBeforeStopwatch =>
      'احفظ تغييراتك المعلّقة قبل تغيير ساعة إيقاف.';

  @override
  String get couldNotSaveAppearance => 'تعذّر حفظ إعدادات المظهر.';

  @override
  String get couldNotSaveSetup =>
      'تعذّر حفظ الإعداد. أعد المحاولة من الإعدادات.';

  @override
  String get tomorrowAlreadyCommitted =>
      'خطة الغد ملتزم بها مسبقًا. تبقى الالتزامات الحالية. أضف التزامًا آخر بعد بدء اليوم التالي.';

  @override
  String get firstCommitmentHeading => 'التزامك الأول · غدًا';

  @override
  String pausedTask(String name) {
    return 'تم إيقاف $name مؤقتًا.';
  }

  @override
  String removedForWeekday(String weekday) {
    return 'أُزيل ليوم $weekday.';
  }

  @override
  String get stopRepeating => 'إيقاف التكرار';

  @override
  String get stoppedRepeating => 'توقف التكرار.';

  @override
  String get achievementsIntro =>
      'أشياء تفخر بها: رخصة قيادة، أول 10 كم، فصل مكتمل.';

  @override
  String get achievement => 'إنجاز';

  @override
  String get achievementRemoved => 'تمت إزالة هذا الإنجاز.';

  @override
  String get deleteAchievementTitle => 'حذف الإنجاز؟';

  @override
  String deleteAchievementBody(String title) {
    return 'إزالة «$title»؟ تبقى التزاماتك ومجالاتك كما هي.';
  }

  @override
  String get keepAchievement => 'الاحتفاظ بالإنجاز';

  @override
  String get couldNotSaveChanges => 'تعذّر حفظ تغييراتك.';

  @override
  String get tourDayTitle => 'هذا يومك';

  @override
  String get tourDayBody =>
      'ترتفع الشمس كلما أنجزت التزامات اليوم. أنجزها كلها لتبلغ الشمس ذروتها.';

  @override
  String get tourCommitmentsTitle => 'التزامات اليوم';

  @override
  String get tourCommitmentsBody =>
      'انقر الدائرة لإنجاز التزام. انقر الصف لتشغيل ساعة إيقاف، أو اعفِه مع ذكر السبب إن طرأ أمر فعلًا.';

  @override
  String get tourFreedomTitle => 'الحرية';

  @override
  String get tourFreedomBody =>
      'تُفتح التطبيقات المقيّدة في وقت الحرية، بعد إنجاز اليوم وتثبيت الغد. انقر هنا في أي وقت لترى ما تبقّى.';

  @override
  String get tourPlanTitle => 'خطّط للغد';

  @override
  String get tourPlanBody =>
      'كل مساء، خطّط للغد ما دام اليوم حاضرًا في ذهنك. اختر أشياء قليلة ستفعلها حقًا.';

  @override
  String get tourAddTitle => 'أضف وكرّر';

  @override
  String get tourAddBody =>
      'أضف التزامًا وامنحه مجالًا. فعّل التكرار للعادات لتُضاف تلقائيًا في أيامها.';

  @override
  String get tourLockTitle => 'ثبّته';

  @override
  String get tourLockBody =>
      'عندما يبدو الغد مناسبًا، ثبّته. بعدها لا يمكن تغييره. وهذا ما يجعله التزامًا.';

  @override
  String get tourJourneyTitle => 'مسيرتك';

  @override
  String get tourJourneyBody =>
      'كل يوم منجز يُحتسب هنا: سلسلتك، والجهد الذي بذلته، والإنجازات التي تفخر بها.';

  @override
  String get tourAreasTitle => 'المجالات';

  @override
  String get tourAreasBody =>
      'كل مجال يتتبع جزءًا من حياتك، مثل الجسد أو العقل أو المسار المهني. أضفها أو أعد تسميتها أو أرشفها هنا. وفي الأسفل، افتح أحدها لترى سجله.';

  @override
  String get tourSettingsTitle => 'الإعدادات';

  @override
  String get tourSettingsBody =>
      'هنا وقت الحرية وحظر التطبيقات والروتين والتذكيرات والألوان. يمكنك أيضًا إعادة هذه الجولة من الإعدادات.';

  @override
  String stepOf(int current, int total) {
    return '$current من $total';
  }

  @override
  String get skipTour => 'تخطي الجولة';

  @override
  String get back => 'رجوع';

  @override
  String get next => 'التالي';

  @override
  String tourStepSemantics(int current, int total) {
    return 'جولة التطبيق، الخطوة $current من $total';
  }

  @override
  String get setupTourBody =>
      'سنتنقل عبر شاشات اليوم والتخطيط والمسيرة الحقيقية ونوضح دور كل جزء. يستغرق ذلك دقيقة تقريبًا، ويمكنك التخطي في أي وقت.';

  @override
  String get setupTestBody =>
      'افتح تطبيقًا محددًا وتحقق من ظهور شاشة قفل Daylock. عد إلى هنا لترى النتيجة. افتحه أيضًا بشكل عادي من الشاشة الرئيسية بعد ترك Daylock في الخلفية: هذا الاختبار يؤكد فتحًا واحدًا فقط. يستخدم شروط حريتك الفعلية ولا يُكمل أي هدف نيابة عنك.';

  @override
  String get setupFirstCommitmentBody =>
      'خطة اليوم مثبّتة مسبقًا. يذهب التزامك الجديد الأول إلى خطة الغد الفعلية. تُفتح التطبيقات عند إنجاز كل الالتزامات المحتسبة، وبلوغ وقت الحرية، والالتزام بخطة الغد. اليوم الفارغ لا يكسبك الحرية.';

  @override
  String get setupAccessibilityOemHelp =>
      'تختلف أسماء الإعدادات على Xiaomi / HyperOS وSamsung وPixel. اختر خدمة تطبيق Daylock المثبت هذا. إن ظهرت «إعدادات مقيّدة»، راجع معلومات التطبيق ← السماح بالإعدادات المقيّدة، فقط لإصدار تثق به. إن كانت الخدمة مفعّلة لكنها غير متصلة، أوقفها ثم فعّلها مرة واحدة.';

  @override
  String get setupAccessibilityExplain =>
      'يكتشف Daylock فتح تطبيق محدد ويمكنه عرض شاشة القفل أو العودة إلى الشاشة الرئيسية. لا يقرأ محتوى الشاشة أبدًا. الوصول اختياري ويمكن سحبه من إعدادات Android.';

  @override
  String get setupBlockingOptional =>
      'حظر التطبيقات اختياري. من دونه يظل Daylock يخطط لأيامك ويتابع التزاماتك. يمكنك تفعيله لاحقًا من الإعدادات.';

  @override
  String get setupXiaomiBody =>
      'قد يوقف HyperOS تطبيق Daylock في الخلفية حتى لو ظهرت ميزة سهولة الاستخدام مفعّلة. قد ينجح اختبار داخل Daylock بينما لا ينجح فتح Instagram من الشاشة الرئيسية.\n\nفي معلومات هذا التطبيق:\n• التشغيل التلقائي: مفعّل\n• توفير البطارية (أو الطاقة): بلا قيود\n• أذونات أخرى ← عرض النوافذ المنبثقة أثناء العمل في الخلفية: سماح\n\nقد يؤدي سحب Daylock من التطبيقات الأخيرة أو استخدام «تنظيف» إلى إيقاف الحظر. إن حدث ذلك، تعرض شاشة اليوم تحذيرًا: أوقف Daylock ثم فعّله في سهولة الاستخدام.\n\nاستخدم إعدادات تطبيق Daylock المثبت هذا؛ فلإصدار Daylock Dev وإصدار Play إعدادات منفصلة. لا يستطيع Daylock قراءة خيارات Xiaomi هذه. أكّدها بنفسك أدناه، ثم اختبر الفتح العادي أيضًا.';

  @override
  String get setupLockNotConfirmed =>
      'لم تُؤكَّد شاشة القفل. تحقق من اتصال سهولة الاستخدام ثم أعد المحاولة. قد يعود Android إلى الشاشة الرئيسية أو يقيّد فتح شاشة القفل. افتح الأذونات والتشخيص في الإعدادات لترى النتيجة المسجّلة.';

  @override
  String get setupVerified => 'تم التحقق: عرض Android شاشة قفل Daylock.';

  @override
  String get setupSaveProgressFailed => 'تعذّر حفظ تقدم الإعداد. أعد المحاولة.';

  @override
  String get setupOpeningApp =>
      'جارٍ فتح التطبيق المحدد. عد إلى Daylock بعد التحقق من شاشة القفل.';

  @override
  String get setupSaveConfirmationFailed => 'تعذّر حفظ تأكيدك. أعد المحاولة.';

  @override
  String get setupWelcomeBody =>
      'خطّط ليومك. واكسب حريتك. أنجز التزاماتك قبل أن تُفتح التطبيقات المشتّتة.';

  @override
  String get setupWelcomePlan =>
      'اختر في المساء السابق التزامات قليلة ذات معنى.';

  @override
  String get setupBlockDistractions => 'احظر المشتّتات';

  @override
  String get setupWelcomeBlock => 'أنت تختار التطبيقات التي تُقيَّد.';

  @override
  String get setupKeepYourWord => 'أوفِ بوعدك';

  @override
  String get setupWelcomeKeep => 'أنجز التزامات اليوم، ثم ثبّت خطة الغد.';

  @override
  String get setupUnlockApps => 'افتح التطبيقات';

  @override
  String get setupWelcomeUnlock =>
      'ابلغ وقت حريتك واستمتع بالراحة التي كسبتها.';

  @override
  String get setupXiaomiTitle => 'Xiaomi / Poco: أبقِ الحظر نشطًا';

  @override
  String get setupOpenAppInfo => 'فتح معلومات تطبيق Daylock';

  @override
  String get setupXiaomiConfirm => 'غيّرت هذه الإعدادات لتطبيق Daylock هذا';

  @override
  String get setupXiaomiConfirmNote => 'تأكيدك؛ لا يُتحقق منه تلقائيًا.';

  @override
  String get setupAccessibilityTitle => 'وصول سهولة الاستخدام · اختياري';

  @override
  String get setupBlockingAndroidOnly =>
      'الحظر متاح على Android. يمكنك استخدام المخطِّط هنا.';

  @override
  String get setupAccessibilityConnected =>
      'مفعّل ومتصل. Daylock جاهز لاكتشاف التطبيقات المحددة.';

  @override
  String get setupAccessibilityWaiting =>
      'مفعّل. بانتظار أن يربط Android الخدمة. انقر تحديث بعد العودة.';

  @override
  String get setupEnableAccessibility => 'تفعيل سهولة الاستخدام';

  @override
  String get setupNotificationsTitle => 'الإشعارات · اختيارية';

  @override
  String get setupNotificationsAllowed =>
      'مسموحة. قد تظهر تذكيرات محلية وإشعارات تقييد احتياطية.';

  @override
  String get setupNotificationsExplain =>
      'اسمح بالتذكيرات المحلية وبإشعار عندما يتعذّر على Android عرض شاشة القفل. يمكنك المتابعة دون إشعارات.';

  @override
  String get setupAllowNotifications => 'السماح بالإشعارات';

  @override
  String get setupRefreshPermissions => 'تحديث حالة الأذونات';

  @override
  String get setupChooseAppsBody =>
      'اختر التطبيقات التي تريد فتحها بوعي أكبر. تبقى اختياراتك على هذا الجهاز.';

  @override
  String get setupRestrictionsEnableFreedom =>
      'تفعيل تقييد التطبيقات هنا يفعّل أيضًا التحكم في الحرية في وقت حريتك المحفوظ.';

  @override
  String get setupSaveBlockingFailed =>
      'تعذّر حفظ إعدادات الحظر. أعد المحاولة.';

  @override
  String get setupAppSelectionAndroidOnly =>
      'اختيار التطبيقات المثبتة متاح على Android.';

  @override
  String get setupOneSmallStep => 'خطوة صغيرة للغد';

  @override
  String get setupSaveCommitmentFailed => 'تعذّر حفظ التزامك. أعد المحاولة.';

  @override
  String get setupCreateCommitment => 'إنشاء التزام';

  @override
  String get setupAlreadyHasCommitment =>
      'تحتوي خطتك على التزام بالفعل. يمكنك المتابعة دون إنشاء آخر.';

  @override
  String get setupTestTitle => 'جرّب التقييد الفعلي للتطبيق';

  @override
  String get setupTestAndroidOnly => 'تتطلب اختبارات الحظر تطبيق Android.';

  @override
  String get setupChecking => 'جارٍ التحقق…';

  @override
  String get setupTestSelectedApp => 'اختبار تطبيق محدد';

  @override
  String get setupEnableFreedomAndRestrictions =>
      'تفعيل التحكم في الحرية وتقييد التطبيقات';

  @override
  String setupTestNeedsFreedom(String state) {
    return 'الحرية الحالية: $state. يحتاج الاختبار الفعلي إلى تفعيل التحكم في الحرية وعدم كسب الحرية بعد. يمكنك مغادرة الإعداد والعودة من الإعدادات عند تحقق هذه الشروط.';
  }

  @override
  String get setupAccessibilityNotConnected =>
      'سهولة الاستخدام غير متصلة. عد إلى إعداد الأذونات.';

  @override
  String get setupConfirmXiaomi =>
      'عد إلى إعداد حظر التطبيقات وأكّد إعداد بطارية Xiaomi ليستمر الحظر في العمل.';

  @override
  String get setupRefreshRetry => 'تحديث وإعادة المحاولة';

  @override
  String get setupReadyTitle => 'أفسح المجال لما يهمّ';

  @override
  String get setupReadyBody =>
      'حُفظت تفضيلاتك والتزامك. ابدأ باليوم، وخطّط للغد، وشاهد مسيرتك تنمو.';

  @override
  String get setupTourTitle => 'جولة سريعة';

  @override
  String get setupBlockingOff => 'حظر التطبيقات متوقف';

  @override
  String get setupBlockingOffBody =>
      'لن يقيّد Daylock أي تطبيق. إن أردت ذلك لاحقًا، افتح الإعدادات وفعّل تقييد التطبيقات.';

  @override
  String get setupSkipTour => 'تخطي الجولة';

  @override
  String get previousStep => 'الخطوة السابقة';

  @override
  String get saveAndLeave => 'حفظ ومغادرة';

  @override
  String stepNOfM(int current, int total) {
    return 'الخطوة $current من $total';
  }

  @override
  String get getStarted => 'ابدأ';

  @override
  String get continueWithoutBlocking => 'المتابعة دون حظر';

  @override
  String get skipTestForNow => 'تخطي الاختبار الآن';

  @override
  String get finishSetup => 'إنهاء الإعداد';

  @override
  String get takeTheTour => 'ابدأ الجولة';

  @override
  String get goToDaylock => 'الانتقال إلى Daylock';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get setupTitleWelcome => 'استعد السيطرة';

  @override
  String get setupTitleBlocking => 'إعداد حظر التطبيقات';

  @override
  String get setupTitleApps => 'اختر مشتّتاتك';

  @override
  String get setupTitleCommitment => 'التزامك الأول';

  @override
  String get setupTitleTest => 'أوشكت على الانتهاء!';

  @override
  String get setupTitleReady => 'كل شيء جاهز!';

  @override
  String get diagLockUnconfirmed =>
      'شاشة القفل: غير مؤكدة؛ قد يُستخدم إشعار احتياطي.';

  @override
  String get diagLockFailedException =>
      'شاشة القفل: رفض Android طلب الفتح أو فشل.';

  @override
  String get diagLockShown => 'شاشة القفل: ظاهرة ومؤكدة.';

  @override
  String get diagLockRequestedUnconfirmed =>
      'شاشة القفل: أُرسل الطلب؛ لم يُؤكَّد ظهورها بعد.';

  @override
  String get diagLockAttempted => 'شاشة القفل: طُلب فتحها.';

  @override
  String get diagHomeRejected => 'العودة للرئيسية: رفض Android الطلب.';

  @override
  String get diagHomeAccepted => 'العودة للرئيسية: قبل Android الطلب.';

  @override
  String get diagHomeAttempted => 'العودة للرئيسية: مطلوبة.';

  @override
  String get diagRestrictionOther => 'تعذّر التحقق من آخر حالة تقييد.';

  @override
  String get diagRestrictionSkippedLaunchThrottled =>
      'تم تخطي التقييد: هناك محاولة جارية لفتح شاشة القفل.';

  @override
  String get diagRestrictionSkippedFreedomDisabled =>
      'تم تخطي التقييد: التحكم في الحرية متوقف.';

  @override
  String get diagRestrictionSkippedFreedomEarned =>
      'تم تخطي التقييد: الحرية مكتسبة.';

  @override
  String get diagRestrictionSkippedStateChanged =>
      'تم تخطي التقييد: تغيّرت حالة الحرية أثناء فتح التطبيق.';

  @override
  String get diagRestrictionRetryingStateChanged =>
      'تغيّرت حالة الحرية أثناء التطبيق؛ جارٍ التحقق مرة أخرى.';

  @override
  String get diagRestrictionSkippedLockAlreadyVisible =>
      'تم تخطي التقييد: شاشة قفل Daylock ظاهرة بالفعل.';

  @override
  String get diagRestrictionSkippedServiceInactive =>
      'تم تخطي التقييد: لم تعد خدمة سهولة الاستخدام نشطة.';

  @override
  String get diagRestrictionSkippedDeviceNotInteractive =>
      'تم تخطي التقييد: كان الجهاز مقفلًا أو غير نشط.';

  @override
  String get diagRestrictionSkippedSelectionUnavailable =>
      'تم تخطي التقييد: تعذّر التحقق من التطبيق المحدد.';

  @override
  String get diagRestrictionSkippedAccessibilityDisabled =>
      'تم تخطي التقييد: لم تعد سهولة الاستخدام مفعّلة.';

  @override
  String get diagRestrictionSkippedForegroundChangedBeforeNavigation =>
      'تم تخطي التقييد: تغيّر التطبيق في الواجهة قبل التطبيق.';

  @override
  String get diagRestrictionHomeFailed =>
      'آخر محاولة: رفض Android العودة للرئيسية. تعذّر تطبيق التقييد.';

  @override
  String get diagRestrictionLockLaunchUnconfirmed =>
      'آخر محاولة: لم تُؤكَّد شاشة القفل. قد يقيّد Android الفتح في الخلفية.';

  @override
  String get diagRestrictionHomeOnly =>
      'آخر محاولة: طُلبت العودة للرئيسية؛ لم تُؤكَّد شاشة القفل.';

  @override
  String get diagRestrictionLockFallbackUnavailable =>
      'آخر محاولة: لم تُؤكَّد شاشة القفل. اسمح بالإشعارات وبقناة إشعارات تقييد التطبيقات في إعدادات Android لتلقي الإشعارات الاحتياطية.';

  @override
  String get diagRestrictionLockFallbackPosted =>
      'آخر محاولة: لم تُؤكَّد شاشة القفل؛ أُرسل إشعار تقييد. يتحكم Android في توصيله.';

  @override
  String get diagRestrictionLockLaunchRequested =>
      'آخر محاولة: طُلبت شاشة القفل؛ لم يُؤكَّد ظهورها بعد.';

  @override
  String get diagRestrictionStateUnknown =>
      'آخر محاولة: سُمح بالتطبيقات المحددة لأن حالة الحرية لم تكن متاحة.';

  @override
  String get diagRestrictionLockShown => 'آخر محاولة: ظهرت شاشة قفل Daylock.';

  @override
  String get diagRestrictionRecoveryShown =>
      'آخر محاولة: ظهرت شاشة الاسترداد. افتح Daylock لتحديث الخطط أو إيقاف الحظر.';

  @override
  String get diagRestrictionRestrictionRecovery =>
      'يحتاج التقييد إلى أن يحدّث Daylock حالة الحرية.';

  @override
  String get diagRestrictionRestrictionTriggered =>
      'بدأ التقييد: جارٍ تشغيل قفل Daylock.';

  @override
  String get diagRestrictionEligibilityUnknown =>
      'تعذّر تأكيد الأهلية؛ أُوقف الحظر مؤقتًا احتياطًا.';

  @override
  String get diagRestrictionEligibilityDisabled =>
      'قُيّمت الأهلية: التحكم في الحرية متوقف؛ التطبيق مسموح.';

  @override
  String get diagRestrictionEligibilityEarned =>
      'قُيّمت الأهلية: الحرية مكتسبة؛ التطبيق مسموح.';

  @override
  String get diagRestrictionEligibilityNotEarned =>
      'قُيّمت الأهلية: الحرية غير مكتسبة.';

  @override
  String get diagRestrictionDetectedSelectedApp =>
      'اكتُشف تطبيق محدد. جارٍ التحقق من الحرية والتقييد.';

  @override
  String get diagRestrictionTestRequested =>
      'طُلب اختبار: بانتظار اكتشاف جديد لتطبيق محدد.';

  @override
  String get diagRestrictionSkippedEventDelayed =>
      'أبلغ Android عن فتح التطبيق متأخرًا جدًا. على Xiaomi / HyperOS، راجع معلومات تطبيق Daylock ← الطاقة ← بلا قيود، ثم اختبر فتح تطبيق محدد من الشاشة الرئيسية.';

  @override
  String get diagRestrictionNone => 'لا محاولات تقييد بعد.';

  @override
  String get diagEnableBlockingBody =>
      'عندما يكون التحكم في الحرية مفعّلًا والحرية غير مكتسبة، يستخدم Daylock سهولة الاستخدام لمغادرة التطبيق المحدد وعرض شاشة القفل الخاصة به. تبقى قائمة التطبيقات المثبتة واختياراتك على هذا الجهاز. لا يقرأ محتوى الشاشة ولا يجمع سجل التصفح. يبقى على هذا الجهاز فقط آخر اكتشاف وآخر نتيجة تقييد. تُقارَن أسماء حزم النوافذ الأخرى فقط لإلغاء إجراء معلّق إن انتقلت إلى تطبيق آخر؛ ولا يُحتفظ بها. يمكنك إيقاف الحظر هنا أو سحب وصول سهولة الاستخدام في أي وقت.\n\nتبقى بيانات الحرية صالحة لتاريخها دون إعادة فتح Daylock. إن كانت الحالة الحالية مفقودة أو غير صالحة، يعرض Daylock شاشة استرداد بخياري فتح Daylock وإيقاف الحظر؛ ويُسمح بالفتح التالي ما دام الاسترداد مطلوبًا. هذا تقييد طوعي، وليس نظامًا مقاومًا للتلاعب ولا رقابة أبوية.';

  @override
  String get diagPermissionBody =>
      'يستخدم Daylock ميزة سهولة الاستخدام في Android لاكتشاف فتح تطبيق محدد، حتى عندما يكون Daylock في الخلفية. يحفظ على هذا الجهاز فقط آخر اكتشاف وحالة الحرية ونتيجة التقييد؛ ولا يُرسل شيء إلى أي خادم. تبقى قائمة التطبيقات المثبتة واختياراتك على هذا الجهاز. لا يقرأ محتوى الشاشة ولا يجمع سجل التصفح. مع تفعيل مفتاح تقييد التطبيقات المنفصل، يمكنه العودة إلى الشاشة الرئيسية وعرض شاشة قفل Daylock عندما لا تكون الحرية مكتسبة. تُقارَن تغييرات النوافذ فقط لإلغاء الإجراءات إن انتقلت إلى تطبيق آخر؛ ولا يُحتفظ بأسماء التطبيقات الأخرى. لا يرسم طبقات فوق الشاشة ولا يقيّد التطبيقات غير المحددة.\n\nأنت تقرر تفعيل «تقييد تطبيقات Daylock» في إعدادات سهولة الاستخدام في Android. ويمكنك إيقافه هناك في أي وقت.';

  @override
  String get diagPermissionTitle => 'إذن تقييد التطبيقات';

  @override
  String get diagAgreeOpenSettings => 'موافقة وفتح الإعدادات';

  @override
  String get diagEnableBlockingTitle => 'تفعيل تقييد التطبيقات؟';

  @override
  String get diagEnableBlocking => 'تفعيل الحظر';

  @override
  String get diagAppRestrictionsLabel => 'تقييد التطبيقات';

  @override
  String get diagAppRestrictionsIntro =>
      'تكتشف سهولة الاستخدام فتح التطبيقات المحددة في الخلفية. يعرض الحظر الاختياري شاشة قفل Daylock أو يعود إلى الشاشة الرئيسية حتى تُكسب الحرية. إن تعذّر ظهور الشاشة، يشرح إشعار سبب الحظر عندما يسمح Android.';

  @override
  String get diagAppRestrictions => 'تقييد التطبيقات';

  @override
  String get diagSeparateFromFreedom =>
      'منفصل عن التحكم في الحرية. متوقف افتراضيًا.';

  @override
  String get diagStatusUnavailable => 'حالة تقييد التطبيقات غير متاحة';

  @override
  String get diagRestrictionsOff => 'تقييد التطبيقات: متوقف';

  @override
  String get diagWaitingForAccessibility =>
      'تقييد التطبيقات: بانتظار وصول سهولة الاستخدام';

  @override
  String get diagAllowedFreedomOff =>
      'التطبيقات المحددة مسموحة — التحكم في الحرية متوقف';

  @override
  String get diagAllowedFreedomEarned =>
      'التطبيقات المحددة مسموحة — الحرية مكتسبة';

  @override
  String get diagBlockingPaused =>
      'الحظر متوقف مؤقتًا — افتح Daylock لتحديث حالة الحرية';

  @override
  String get diagRestrictionsReady =>
      'تقييد التطبيقات جاهز — الفتح والتنقل يعتمدان على Android';

  @override
  String get diagServiceStatusUnavailable => 'حالة الخدمة غير متاحة';

  @override
  String get diagAndroidOnly => 'الاكتشاف الأصلي متاح على Android فقط.';

  @override
  String get diagServiceDisabled => 'خدمة سهولة الاستخدام: متوقفة';

  @override
  String get diagServiceConnected => 'خدمة سهولة الاستخدام: مفعّلة ومتصلة';

  @override
  String get diagServiceWaiting =>
      'خدمة سهولة الاستخدام: مفعّلة — بانتظار اتصال Android';

  @override
  String get diagBlockingSaveFailed =>
      'تعذّر حفظ خيار الحظر. يسري الإيقاف الآن، لكنه قد لا يستمر بعد إعادة التشغيل. اسحب وصول سهولة الاستخدام إن لزم.';

  @override
  String get diagNoDetectionYet => 'لم يُكتشف أي تطبيق محدد بعد.';

  @override
  String diagLastDetection(String when) {
    return 'آخر اكتشاف لتطبيق مقيّد: $when';
  }

  @override
  String diagFreedomAtDetection(String state) {
    return 'الحرية عند ذلك الاكتشاف: $state';
  }

  @override
  String diagCurrentFreedom(String state) {
    return 'حالة الحرية الأصلية الحالية: $state';
  }

  @override
  String get diagFocusNeedsRefresh =>
      'جلسة تركيز نشطة تحتاج إلى أن يحدّث Daylock مؤقتها. الاكتشاف الأصلي لا يعتبرها مكتملة.';

  @override
  String get diagStateUnavailable =>
      'حالة اليوم غير متاحة. افتح Daylock لتحديث الخطط أو أوقف الحظر. بيانات اليوم الصالحة لا تنتهي بعد خمس دقائق.';

  @override
  String get diagRolloverReconciled =>
      'يوم جديد: تُستخدم الخطة المحفوظة لهذا التاريخ. افتح Daylock لأرشفة السجل وتجهيز اليوم التالي.';

  @override
  String get diagNoEligible =>
      'لا التزامات محتسبة. الأيام الفارغة أو المعفاة بالكامل لا تكسبك الحرية.';

  @override
  String get diagDetectionSaveFailed =>
      'تعذّر حفظ آخر اكتشاف، وقد لا يستمر بعد إعادة التشغيل.';

  @override
  String get diagTurnBlockingOff => 'إيقاف الحظر';

  @override
  String get diagSettingsPath =>
      'إعدادات Android ← سهولة الاستخدام ← التطبيقات المنزّلة/المثبتة ← تقييد تطبيقات Daylock. فعّل الخدمة يدويًا. تختلف الأسماء حسب الهاتف.';

  @override
  String get diagRestrictedSettings =>
      'إن عرض Android 15 «إعدادات مقيّدة»، ابحث في معلومات تطبيق Daylock عن «السماح بالإعدادات المقيّدة» وأكّد فقط لإصدار تطوير تثق به.';

  @override
  String get diagAvailableAndroidOnly => 'متاح على Android فقط';

  @override
  String get diagServiceEnabledShort => 'خدمة سهولة الاستخدام: مفعّلة';

  @override
  String get diagServiceDisconnected => 'الخدمة غير متصلة';

  @override
  String get diagRestrictionsOn => 'تقييد التطبيقات: مفعّل';

  @override
  String selectedAppsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تطبيق محدد',
      many: '$count تطبيقًا محددًا',
      few: '$count تطبيقات محددة',
      two: 'تطبيقان محددان',
      one: 'تطبيق محدد واحد',
      zero: 'لا تطبيقات محددة',
    );
    return '$_temp0';
  }

  @override
  String diagNativeFreedom(String state) {
    return 'الحرية الأصلية: $state';
  }

  @override
  String get diagTechnicalDetails => 'التفاصيل التقنية والإعداد';

  @override
  String diagLastPackage(String package) {
    return 'آخر حزمة مقيّدة: $package';
  }

  @override
  String get openAccessibilitySettings => 'فتح إعدادات سهولة الاستخدام';

  @override
  String get refreshStatus => 'تحديث الحالة';

  @override
  String get appsLoadFailed =>
      'تعذّر تحميل التطبيقات المثبتة. لم تُستبدل اختياراتك المحفوظة.';

  @override
  String get appsPausedAttention =>
      'التقييد متوقف مؤقتًا: الحالة تحتاج إلى انتباه.';

  @override
  String get appsRestrictionsOff => 'تقييد التطبيقات متوقف. اختياراتك محفوظة.';

  @override
  String get appsNoneSelected => 'لا تطبيقات محددة. لا شيء مقيّد.';

  @override
  String get appsWaitingAccessibility =>
      'بانتظار وصول سهولة الاستخدام. التطبيقات المحددة غير مقيّدة.';

  @override
  String get appsFreedomOff =>
      'التحكم في الحرية متوقف. التطبيقات المحددة متاحة.';

  @override
  String get appsFreedomEarned => 'تم كسب الحرية. التطبيقات المحددة متاحة.';

  @override
  String get appsNeedsRefresh =>
      'تحتاج حالة الحرية إلى تحديث. الاسترداد متاح؛ يُسمح بالفتح المتكرر.';

  @override
  String get appsRestricted => 'التطبيقات المحددة مقيّدة حتى تُكسب الحرية.';

  @override
  String selectedCountLabel(int count) {
    return 'المحدد: $count';
  }

  @override
  String get refreshApps => 'تحديث التطبيقات';

  @override
  String get appsMasterControl => 'التحكم الرئيسي لكل التطبيقات المحددة.';

  @override
  String get appsMasterSaveFailed =>
      'تعذّر حفظ الإعداد الرئيسي. يسري الإيقاف الآن، لكنه قد لا يستمر بعد إعادة التشغيل.';

  @override
  String get appsChooseBelow =>
      'اختر التطبيقات أدناه. التحكم في الحرية وتقييد التطبيقات منفصلان. تُستثنى تطبيقات الاسترداد في النظام.';

  @override
  String appsRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'أُزيل من الاختيار $count من التطبيقات غير المتاحة أو المعاد تثبيتها. اخترها مجددًا إن لزم.',
      two: 'أُزيل من الاختيار تطبيقان غير متاحين أو أُعيد تثبيتهما. اخترهما مجددًا إن لزم.',
      one: 'أُزيل من الاختيار تطبيق واحد غير متاح أو أُعيد تثبيته. اختره مجددًا إن لزم.',
    );
    return '$_temp0';
  }

  @override
  String get appsNoneSelectedYet =>
      'لا تطبيقات محددة بعد. اختر التطبيقات التي تريد تقييدها.';

  @override
  String get searchApps => 'البحث في التطبيقات';

  @override
  String get appsSelectionRequiresAndroid =>
      'يتطلب اختيار التطبيقات المثبتة Android.';

  @override
  String get retryAppDiscovery => 'إعادة البحث عن التطبيقات';

  @override
  String get appsNoneFound => 'لم يُعثر على تطبيقات مدعومة في ملف Android هذا.';

  @override
  String get appsNoMatches => 'لا تطبيقات مطابقة.';

  @override
  String get appIconUnavailable => 'أيقونة التطبيق غير متاحة';

  @override
  String get savingSelection => 'جارٍ حفظ الاختيار…';

  @override
  String get appsSelectionsStay =>
      'تبقى اختياراتك على هذا الجهاز. يجب اختيار التطبيقات الجديدة أو المعاد تثبيتها صراحة.';

  @override
  String get notifRunningStopwatchHelp =>
      'يعرض إشعارًا هادئًا مع زر إيقاف مؤقت أثناء عمل ساعة الإيقاف، ويذكّرك كل ساعتين حتى لا تبقى تعمل بالخطأ.';

  @override
  String get notifBlockedInSystem => 'محظور في إعدادات نظام Android';

  @override
  String get notifLabel => 'الإشعارات';

  @override
  String get notifPermissionAllowed => 'إذن النظام: مسموح';

  @override
  String get notifPermissionDenied => 'إذن النظام: غير مسموح';

  @override
  String get notifNeedsAttention => 'إعداد الإشعارات يحتاج إلى انتباه';

  @override
  String get notifChecking => 'جارٍ التحقق من إذن النظام…';

  @override
  String get notifUnavailable => 'الإشعارات المجدولة غير متاحة';

  @override
  String get notifPermissionHelp => 'مساعدة الإذن';

  @override
  String get notifOpenSettings => 'فتح إعدادات الإشعارات';

  @override
  String get notifPlanTomorrow => 'خطّط للغد';

  @override
  String get notifCommitmentReminder => 'تذكير الالتزامات';

  @override
  String get notifFreedom => 'إشعارات الحرية';

  @override
  String get notifFreedomHelp =>
      'يستخدم وقت الحرية عند تفعيل التحكم في الحرية.';

  @override
  String get notifRunningStopwatch => 'ساعة الإيقاف العاملة';

  @override
  String get healthXiaomiTip =>
      'لمنع تكرار ذلك على Xiaomi / Poco: في معلومات تطبيق Daylock اسمح بالتشغيل التلقائي، واضبط توفير البطارية على بلا قيود، واسمح بالنوافذ المنبثقة في الخلفية، وتجنب سحب Daylock من التطبيقات الأخيرة.';

  @override
  String get healthOffBody =>
      'وصول سهولة الاستخدام لتطبيق Daylock متوقف، لذا تُفتح تطبيقاتك المحددة بحرية. فعّله لإعادة القفل.';

  @override
  String get healthStoppedBody =>
      'أوقف Android تطبيق Daylock في الخلفية، لذا تُفتح تطبيقاتك المحددة بحرية. في سهولة الاستخدام، أوقف Daylock ثم فعّله مجددًا.';

  @override
  String get healthStoppedTitle => 'توقف حظر التطبيقات';

  @override
  String get openAccessibility => 'فتح سهولة الاستخدام';

  @override
  String get openAppInfo => 'فتح معلومات التطبيق';

  @override
  String get conditionSatisfied => 'متحقق';

  @override
  String get conditionRemaining => 'متبقٍ';

  @override
  String freedomTimeAt(String time) {
    return 'وقت الحرية · $time';
  }

  @override
  String eligibleComplete(int kept, int total) {
    return '$kept / $total من الالتزامات المحتسبة مكتملة';
  }

  @override
  String get noEligibleRequired =>
      'لا التزامات محتسبة — الإنجاز مطلوب لكسب الحرية.';

  @override
  String get tomorrowPlanCommittedCondition => 'الالتزام بخطة الغد';

  @override
  String get planDateMismatch => 'خطة اليوم لا تطابق التاريخ المحلي الحالي.';

  @override
  String availableAt(String time) {
    return 'متاح الساعة $time';
  }

  @override
  String get enableFreedomInSettings => 'فعّل التحكم في الحرية من الإعدادات.';

  @override
  String get pauseStopwatch => 'إيقاف ساعة الإيقاف مؤقتًا';

  @override
  String get resumeStopwatch => 'استئناف ساعة الإيقاف';

  @override
  String get startStopwatch => 'تشغيل ساعة الإيقاف';

  @override
  String get keptLower => 'مُنجز';

  @override
  String keepTask(String name) {
    return 'إنجاز $name';
  }

  @override
  String get recordedTimeLabel => 'الوقت المسجّل';

  @override
  String calendarDayExcusedNeutral(int count) {
    return 'لا التزامات محتسبة، المعفى: $count، محايد';
  }

  @override
  String get calendarDayNeutral => 'لا التزامات، محايد';

  @override
  String get calendarDayUnrecorded => 'لا التزامات مسجّلة، محايد';

  @override
  String calendarDayProgress(int kept, int total, int percent, int excused) {
    return '$kept من $total من الالتزامات المحتسبة مكتملة، $percent بالمئة، المعفى: $excused';
  }

  @override
  String get calendarTodaySuffix => '، اليوم';

  @override
  String calendarDayValue(String description, int count) {
    return '$description، الأحداث المجدولة: $count';
  }

  @override
  String get heatNeutral =>
      'محايد: لا التزامات محتسبة، أو سجل مفقود، أو تاريخ مستقبلي';

  @override
  String get heatZero => 'الالتزامات المسجّلة: 0 بالمئة مكتملة';

  @override
  String get heatLow => 'أكثر من 0 حتى 25 بالمئة مكتملة';

  @override
  String get heatMedium => 'أكثر من 25 حتى 50 بالمئة مكتملة';

  @override
  String get heatHigh => 'أكثر من 50 وأقل من 100 بالمئة مكتملة';

  @override
  String get heatComplete => '100 بالمئة مكتملة';

  @override
  String get heatLess => 'أقل';

  @override
  String get heatMore => 'أكثر';

  @override
  String get calTodayReadOnly => 'التزامات اليوم، للقراءة فقط. أدرها من اليوم.';

  @override
  String get calHistoryReadOnly => 'سجل الالتزامات، للقراءة فقط';

  @override
  String get calTodayLabel => 'التزامات اليوم';

  @override
  String get calHistoryLabel => 'سجل الالتزامات';

  @override
  String get calNoHistory => 'لا سجل التزامات.';

  @override
  String get calNoCommitmentsToday => 'لا التزامات اليوم.';

  @override
  String get calNeutralDay => 'لا التزامات مسجّلة. يوم محايد.';

  @override
  String get calCompletionLabel => 'إنجاز الالتزامات في التاريخ المحدد';

  @override
  String calRecordedTime(String duration) {
    return 'الوقت المسجّل: $duration';
  }

  @override
  String calCommitmentOutcome(String outcome) {
    return 'التزام · $outcome';
  }

  @override
  String calReason(String reason) {
    return 'السبب: $reason';
  }

  @override
  String get calReadOnlyCached => 'حدث مخزّن مؤقتًا للقراءة فقط';

  @override
  String editNamed(String name) {
    return 'تعديل $name';
  }

  @override
  String deleteNamed(String name) {
    return 'حذف $name';
  }

  @override
  String get deleteEventTitle => 'حذف الحدث؟';

  @override
  String deleteEventBody(String title) {
    return 'حذف «$title» من جدولك؟';
  }

  @override
  String get calReadOnlyCachedShort => 'للقراءة فقط · حدث مخزّن مؤقتًا';

  @override
  String get close => 'إغلاق';

  @override
  String get previousMonth => 'الشهر السابق';

  @override
  String get nextMonth => 'الشهر التالي';

  @override
  String get calendar => 'التقويم';

  @override
  String get calendarAccounts => 'حسابات التقويم';

  @override
  String get addEvent => 'إضافة حدث';

  @override
  String get scheduleLabel => 'الجدول';

  @override
  String get noEventsScheduled => 'لا أحداث مجدولة.';

  @override
  String get eventTimeFormat => 'استخدم HH:mm (00:00–23:59).';

  @override
  String get eventEndAfterStart => 'يجب أن تكون النهاية بعد البداية.';

  @override
  String get readOnlyEvent => 'حدث للقراءة فقط';

  @override
  String get externalEventsReadOnly =>
      'لا يمكن تغيير الأحداث الخارجية إلا في تقويمها.';

  @override
  String get editEvent => 'تعديل الحدث';

  @override
  String get title => 'العنوان';

  @override
  String get enterTitle => 'اكتب عنوانًا.';

  @override
  String get startTimeOptional => 'وقت البدء (اختياري)';

  @override
  String get endTimeOptional => 'وقت الانتهاء (اختياري)';

  @override
  String get notesOptional => 'ملاحظات (اختيارية)';

  @override
  String get saveEvent => 'حفظ الحدث';

  @override
  String get accountUpdateFailed =>
      'تعذّر تحديث هذا الحساب. لا تزال الأحداث المخزّنة متاحة. أعد المحاولة أو أعد الاتصال.';

  @override
  String get disconnectAccountTitle => 'قطع اتصال الحساب؟';

  @override
  String disconnectAccountBody(String name) {
    return 'إزالة $name وأحداثه المخزّنة من Daylock؟ سيبقى تقويمك الخارجي دون تغيير.';
  }

  @override
  String get disconnect => 'قطع الاتصال';

  @override
  String get externalCalendarsReadOnly =>
      'التقويمات الخارجية للقراءة فقط. الأحداث المخزّنة متاحة دون اتصال.';

  @override
  String get providersDisabled =>
      'تسجيل الدخول غير متاح للخدمات المعطّلة في هذا الإصدار.';

  @override
  String connectProvider(String provider) {
    return 'ربط $provider';
  }

  @override
  String get noConnectedAccounts => 'لا حسابات مرتبطة.';

  @override
  String get syncNow => 'مزامنة الآن';

  @override
  String get reconnect => 'إعادة الربط';

  @override
  String get notSyncedYet => 'لم تتم المزامنة بعد';

  @override
  String lastSynced(String when) {
    return 'آخر مزامنة $when';
  }

  @override
  String get syncToLoad => 'زامِن لتحميل تقويمات هذا الحساب.';

  @override
  String get chooseMonth => 'اختر الشهر';

  @override
  String get previousYear => 'السنة السابقة';

  @override
  String get year => 'السنة';

  @override
  String get enterYear => 'اكتب سنة من 1 إلى 9999.';

  @override
  String get nextYear => 'السنة التالية';

  @override
  String get showMonth => 'عرض الشهر';

  @override
  String get commitment => 'التزام';

  @override
  String repeatsLabel(String rule) {
    return 'يتكرر: $rule';
  }

  @override
  String get areas => 'المجالات';

  @override
  String get areasIntro =>
      'امنح التزاماتك مكانًا. يُستخدم مجالك الافتراضي عندما لا تختار مجالًا آخر.';

  @override
  String get createArea => 'إنشاء مجال';

  @override
  String get archived => 'مؤرشفة';

  @override
  String get defaultAlwaysAvailable => 'افتراضي · متاح دائمًا';

  @override
  String get restore => 'استعادة';

  @override
  String get archive => 'أرشفة';

  @override
  String get archivingExplainer =>
      'الأرشفة تُبقي الالتزامات والسجل مرتبطة. الالتزامات الجديدة تستخدم المجالات النشطة فقط.';

  @override
  String get editArea => 'تعديل المجال';

  @override
  String get areaName => 'اسم المجال';

  @override
  String get icon => 'الأيقونة';

  @override
  String get colour => 'اللون';

  @override
  String get saveArea => 'حفظ المجال';

  @override
  String get areaIconLife => 'الحياة';

  @override
  String get areaColourLavender => 'خزامي';

  @override
  String get areaIconHealth => 'الصحة';

  @override
  String get areaIconWork => 'العمل';

  @override
  String get areaIconLearning => 'التعلّم';

  @override
  String get areaIconHome => 'المنزل';

  @override
  String get areaIconPeople => 'الناس';

  @override
  String get areaIconCreative => 'الإبداع';

  @override
  String get areaIconFitness => 'اللياقة';

  @override
  String get areaColourBlue => 'أزرق';

  @override
  String get areaColourTeal => 'أزرق مخضر';

  @override
  String get areaColourGreen => 'أخضر';

  @override
  String get areaColourAmber => 'كهرماني';

  @override
  String get areaColourRose => 'وردي';

  @override
  String get newAchievement => 'إنجاز جديد';

  @override
  String get editAchievement => 'تعديل الإنجاز';

  @override
  String get achievementPrompt => 'بماذا تفخر؟';

  @override
  String get achievementHint => 'نجحت في اختبار القيادة';

  @override
  String get achievementNotes => 'بضع كلمات (اختياري)';

  @override
  String get linkToArea => 'ربط بمجال';

  @override
  String get optional => 'اختياري';

  @override
  String get previousAreaUnavailable =>
      'المجال السابق غير متاح. اختر مجالًا أو أزل الربط.';

  @override
  String get saveAchievement => 'حفظ الإنجاز';

  @override
  String illustrationLabel(String name) {
    return 'الرسم: $name';
  }

  @override
  String illustrationAutomaticLabel(String name) {
    return 'الرسم: تلقائي · $name';
  }

  @override
  String get illustrationHelp =>
      'اختر شكلًا، أو دع العنوان والمجال يقترحان واحدًا.';

  @override
  String get automatic => 'تلقائي';

  @override
  String get area => 'المجال';

  @override
  String get notifExplainAndroid =>
      'قد تتأخر تذكيرات Android بسبب توفير البطارية أو وضع عدم الإزعاج. تفضيلات التطبيق أدناه منفصلة عن إذن النظام.';

  @override
  String get notifExplainError =>
      'تعذّر تحديث الإشعارات. أعد فتح Daylock للمحاولة مجددًا.';

  @override
  String get notifExplainDefault => 'الإشعارات المجدولة متاحة على Android.';

  @override
  String get notifExplainWebSupported =>
      'يدعم هذا المتصفح الإشعارات، لكن التذكيرات المجدولة غير متاحة هنا. لا يمكن لـ Safari أو علامات التبويب المغلقة أو تطبيقات PWA المثبتة تلقي هذه التذكيرات دون خدمة دفع. استخدم Daylock على Android للإشعارات المجدولة.';

  @override
  String get notifExplainWebUnsupported =>
      'لا يستطيع هذا المتصفح تلقي إشعارات Daylock. التذكيرات المجدولة متاحة في تطبيق Android؛ عناصر تحكم الويب/PWA معطّلة.';

  @override
  String get detectionReadFailed =>
      'تعذّرت قراءة حالة الاكتشاف الأصلي. حدّث أو افتح إعدادات Android يدويًا.';

  @override
  String get calFailAuthMicrosoft =>
      'يحتاج الوصول إلى تقويم Microsoft إلى تجديد الإذن. أعد ربط هذا الحساب. قد تتطلب مؤسستك موافقة المسؤول. لا تزال الأحداث المخزّنة متاحة.';

  @override
  String get calFailAuthGoogle =>
      'انتهى إذن تقويم Google أو سُحب. أعد ربط هذا الحساب. لا تزال الأحداث المخزّنة متاحة.';

  @override
  String get calFailConfigMicrosoft =>
      'تسجيل الدخول إلى Microsoft غير مضبوط بشكل صحيح. تحقق من معرّف عميل Entra وعنوان إعادة التوجيه الأصلي وأنواع الحسابات المدعومة.';

  @override
  String get calFailConfigGoogle =>
      'تسجيل الدخول إلى Google غير مضبوط بشكل صحيح. تحقق من معرّف عميل OAuth وحزمة Android وشهادة التوقيع.';

  @override
  String get calFailUnavailableMicrosoft =>
      'تقويم Microsoft غير متاح. تحقق من اتصالك وأعد المحاولة. تحتاج حسابات العمل إلى صندوق بريد Exchange متاح. لا تزال الأحداث المخزّنة متاحة.';

  @override
  String get calFailUnavailableGoogle =>
      'تقويم Google غير متاح. تحقق من اتصالك وأعد المزامنة. لا تزال الأحداث المخزّنة متاحة.';

  @override
  String get calFailResponseMicrosoft =>
      'أعادت Microsoft استجابة تقويم ناقصة أو غير مدعومة. لا تزال الأحداث المخزّنة متاحة. أعد المحاولة لاحقًا.';

  @override
  String get calFailResponseGoogle =>
      'أعادت Google استجابة تقويم ناقصة أو غير مدعومة. لا تزال الأحداث المخزّنة متاحة. أعد المحاولة لاحقًا.';

  @override
  String get calFailAdminConsent =>
      'تتطلب مؤسستك موافقة المسؤول أو تقيّد تسجيل الدخول هذا. تواصل مع مسؤول تقنية المعلومات. لا تزال الأحداث المخزّنة متاحة.';

  @override
  String get calFailAccountMismatch =>
      'اختر حساب Microsoft والمؤسسة نفسيهما عند إعادة الربط. تم الاحتفاظ بالحسابات الحالية والأحداث المخزّنة.';

  @override
  String get channelPlan => 'خطّط للغد';

  @override
  String get channelCommitments => 'تذكيرات الالتزامات';

  @override
  String get channelFreedom => 'الحرية';

  @override
  String get channelFocus => 'ساعة الإيقاف العاملة';

  @override
  String get selectionLoadFailed =>
      'تعذّر تحميل التطبيقات المقيّدة أو حفظها. التقييد متوقف مؤقتًا. حدّث لإعادة المحاولة.';

  @override
  String get selectionSaveFailed =>
      'تعذّر حفظ اختيار التطبيقات. التقييد متوقف مؤقتًا. حدّث لإعادة المحاولة.';

  @override
  String totalAchievements(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'إنجازًا',
      few: 'إنجازات',
      two: 'إنجازان',
      one: 'إنجاز',
    );
    return '$_temp0';
  }

  @override
  String get breaksTitle => 'الاستراحات';

  @override
  String get breaksIntro => 'أُخذت من شاشة القفل خلال آخر 30 يومًا، مع أسبابك.';

  @override
  String breakEntryTitle(String app, String when) {
    return '$app · $when';
  }

  @override
  String get diagRestrictionSkippedBreakActive =>
      'تم تخطي التقييد: استراحة 15 دقيقة نشطة.';

  @override
  String get backupTitle => 'النسخ الاحتياطي والاستعادة';

  @override
  String get backupSubtitle => 'احتفظ بنسخة من خططك ومسيرتك';

  @override
  String get backupAutoTitle => 'النسخ الاحتياطي التلقائي في Android مفعّل';

  @override
  String get backupAutoBody =>
      'عند تفعيل النسخ الاحتياطي في إعدادات هاتفك، تحتفظ Google بنسخة من خطط Daylock وتستعيدها على هاتف جديد. لا تُضمَّن تسجيلات دخول التقويم ولا أذونات الحظر.';

  @override
  String get backupFileLabel => 'ملف النسخ الاحتياطي';

  @override
  String get backupExport => 'تصدير ملف النسخ الاحتياطي';

  @override
  String get backupExportBody =>
      'يحفظ خططك وسجلك ومجالاتك وروتينك وإنجازاتك وإعداداتك في ملف تختاره: Drive أو التنزيلات أو أي مكان آخر.';

  @override
  String get backupImport => 'الاستعادة من ملف';

  @override
  String get backupImportBody =>
      'يستبدل كل ما في Daylock بمحتوى ملف النسخ الاحتياطي.';

  @override
  String get backupConfirmTitle => 'استبدال بيانات Daylock؟';

  @override
  String get backupConfirmBody =>
      'سيُستبدل كل ما في Daylock بهذه النسخة. لا يمكن التراجع عن ذلك.';

  @override
  String get backupReplace => 'استبدال';

  @override
  String get backupSaved => 'تم حفظ النسخة الاحتياطية.';

  @override
  String get backupRestored => 'تمت استعادة النسخة الاحتياطية.';

  @override
  String get backupNotDaylock => 'هذا الملف ليس نسخة احتياطية من Daylock.';

  @override
  String get backupNewer =>
      'هذه النسخة من إصدار أحدث من Daylock. حدّث التطبيق أولًا.';

  @override
  String get backupDamaged => 'هذه النسخة تالفة ولا يمكن استعادتها.';

  @override
  String get backupFailed => 'تعذّر حفظ الملف أو فتحه. جرّب موقعًا آخر.';

  @override
  String get backupAndroidOnly =>
      'ملفات النسخ الاحتياطي متاحة في تطبيق Android.';
}

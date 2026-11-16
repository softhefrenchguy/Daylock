import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Daylock'**
  String get appTitle;

  /// No description provided for @appearanceDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceDark;

  /// No description provided for @appearanceLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appearanceLight;

  /// No description provided for @appearanceSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get appearanceSystem;

  /// No description provided for @colourViolet.
  ///
  /// In en, this message translates to:
  /// **'Violet'**
  String get colourViolet;

  /// No description provided for @colourOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean'**
  String get colourOcean;

  /// No description provided for @colourForest.
  ///
  /// In en, this message translates to:
  /// **'Forest'**
  String get colourForest;

  /// No description provided for @colourEmber.
  ///
  /// In en, this message translates to:
  /// **'Ember'**
  String get colourEmber;

  /// No description provided for @colourRose.
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get colourRose;

  /// No description provided for @colourMono.
  ///
  /// In en, this message translates to:
  /// **'Mono'**
  String get colourMono;

  /// No description provided for @illustrationCelebration.
  ///
  /// In en, this message translates to:
  /// **'Celebration'**
  String get illustrationCelebration;

  /// No description provided for @illustrationDriving.
  ///
  /// In en, this message translates to:
  /// **'Driving'**
  String get illustrationDriving;

  /// No description provided for @illustrationAward.
  ///
  /// In en, this message translates to:
  /// **'Award'**
  String get illustrationAward;

  /// No description provided for @illustrationCooking.
  ///
  /// In en, this message translates to:
  /// **'Cooking'**
  String get illustrationCooking;

  /// No description provided for @illustrationTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get illustrationTravel;

  /// No description provided for @illustrationFitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get illustrationFitness;

  /// No description provided for @illustrationLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get illustrationLearning;

  /// No description provided for @illustrationHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get illustrationHealth;

  /// No description provided for @illustrationWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get illustrationWork;

  /// No description provided for @illustrationHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get illustrationHome;

  /// No description provided for @illustrationPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get illustrationPeople;

  /// No description provided for @illustrationCreativity.
  ///
  /// In en, this message translates to:
  /// **'Creativity'**
  String get illustrationCreativity;

  /// No description provided for @illustrationSunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get illustrationSunrise;

  /// No description provided for @outcomeIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get outcomeIncomplete;

  /// No description provided for @outcomeCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get outcomeCompleted;

  /// No description provided for @outcomeExcused.
  ///
  /// In en, this message translates to:
  /// **'Excused'**
  String get outcomeExcused;

  /// No description provided for @sourceLocal.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get sourceLocal;

  /// No description provided for @sourceGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google Calendar'**
  String get sourceGoogle;

  /// No description provided for @sourceMicrosoftPersonal.
  ///
  /// In en, this message translates to:
  /// **'Microsoft Personal'**
  String get sourceMicrosoftPersonal;

  /// No description provided for @sourceMicrosoftWorkSchool.
  ///
  /// In en, this message translates to:
  /// **'Microsoft Work/School'**
  String get sourceMicrosoftWorkSchool;

  /// No description provided for @freedomStateEarned.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get freedomStateEarned;

  /// No description provided for @freedomStateNotEarned.
  ///
  /// In en, this message translates to:
  /// **'Not earned'**
  String get freedomStateNotEarned;

  /// No description provided for @freedomStateControlOff.
  ///
  /// In en, this message translates to:
  /// **'Control off'**
  String get freedomStateControlOff;

  /// No description provided for @freedomStateUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get freedomStateUnknown;

  /// No description provided for @listSeparator.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get listSeparator;

  /// No description provided for @repeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get repeatDaily;

  /// No description provided for @repeatEveryDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every day} other{Every {count} days}}'**
  String repeatEveryDays(int count);

  /// No description provided for @repeatWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get repeatWeekdays;

  /// No description provided for @repeatWeekends.
  ///
  /// In en, this message translates to:
  /// **'Weekends'**
  String get repeatWeekends;

  /// No description provided for @eventContinuesAllDay.
  ///
  /// In en, this message translates to:
  /// **'Continues all day'**
  String get eventContinuesAllDay;

  /// No description provided for @eventEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get eventEarlier;

  /// No description provided for @eventNextDay.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get eventNextDay;

  /// No description provided for @eventUntil.
  ///
  /// In en, this message translates to:
  /// **'Until {time}'**
  String eventUntil(String time);

  /// No description provided for @eventAllDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get eventAllDay;

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationMinutes(int minutes);

  /// No description provided for @durationUnderMinute.
  ///
  /// In en, this message translates to:
  /// **'<1 min'**
  String get durationUnderMinute;

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} hr'**
  String durationHours(int hours);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} hr {minutes} min'**
  String durationHoursMinutes(int hours, int minutes);

  /// No description provided for @settingsFreedomControl.
  ///
  /// In en, this message translates to:
  /// **'Freedom Control'**
  String get settingsFreedomControl;

  /// No description provided for @settingsPlanningRoutines.
  ///
  /// In en, this message translates to:
  /// **'Planning & Routines'**
  String get settingsPlanningRoutines;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsRestrictedApps.
  ///
  /// In en, this message translates to:
  /// **'Restricted Apps'**
  String get settingsRestrictedApps;

  /// No description provided for @settingsPermissionsDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Permissions & Diagnostics'**
  String get settingsPermissionsDiagnostics;

  /// No description provided for @settingsManageRoutines.
  ///
  /// In en, this message translates to:
  /// **'Manage routines'**
  String get settingsManageRoutines;

  /// No description provided for @routineCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 routine} other{{count} routines}}'**
  String routineCount(int count);

  /// No description provided for @settingsRoutinesIntro.
  ///
  /// In en, this message translates to:
  /// **'Plan your next steps with recurring commitments.'**
  String get settingsRoutinesIntro;

  /// No description provided for @settingsNotificationsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Notification controls are unavailable on this device.'**
  String get settingsNotificationsUnavailable;

  /// No description provided for @keepYourWord.
  ///
  /// In en, this message translates to:
  /// **'Keep your word.'**
  String get keepYourWord;

  /// No description provided for @settingsAboutCommitments.
  ///
  /// In en, this message translates to:
  /// **'Commitments, optional stopwatches and progress in the areas that matter.'**
  String get settingsAboutCommitments;

  /// No description provided for @settingsRestrictedIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose which supported Android apps to restrict until Freedom is earned.'**
  String get settingsRestrictedIntro;

  /// No description provided for @settingsRestrictionsAndroidOnly.
  ///
  /// In en, this message translates to:
  /// **'App restrictions are available on Android.'**
  String get settingsRestrictionsAndroidOnly;

  /// No description provided for @settingsDiagnosticsAndroidOnly.
  ///
  /// In en, this message translates to:
  /// **'Accessibility diagnostics are available on Android.'**
  String get settingsDiagnosticsAndroidOnly;

  /// No description provided for @freedomTime.
  ///
  /// In en, this message translates to:
  /// **'Freedom Time'**
  String get freedomTime;

  /// No description provided for @settingsRestrictionNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'App restriction status needs attention'**
  String get settingsRestrictionNeedsAttention;

  /// No description provided for @settingsSelectedSwitchOn.
  ///
  /// In en, this message translates to:
  /// **'{count} selected, switch on'**
  String settingsSelectedSwitchOn(int count);

  /// No description provided for @settingsSelectedSwitchOff.
  ///
  /// In en, this message translates to:
  /// **'{count} selected, switch off'**
  String settingsSelectedSwitchOff(int count);

  /// No description provided for @accessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get accessibility;

  /// No description provided for @statusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Status unavailable'**
  String get statusUnavailable;

  /// No description provided for @availableOnAndroid.
  ///
  /// In en, this message translates to:
  /// **'Available on Android'**
  String get availableOnAndroid;

  /// No description provided for @serviceConnected.
  ///
  /// In en, this message translates to:
  /// **'Service connected'**
  String get serviceConnected;

  /// No description provided for @waitingForConnection.
  ///
  /// In en, this message translates to:
  /// **'Waiting for connection'**
  String get waitingForConnection;

  /// No description provided for @serviceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Service disabled'**
  String get serviceDisabled;

  /// No description provided for @settingsChooseInstalledApps.
  ///
  /// In en, this message translates to:
  /// **'Choose installed Android apps'**
  String get settingsChooseInstalledApps;

  /// No description provided for @settingsFreedomSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Restricted apps, Freedom Time and permissions'**
  String get settingsFreedomSubtitle;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @settingsPlanningSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Recurring commitments and planning'**
  String get settingsPlanningSubtitle;

  /// No description provided for @settingsAppearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Theme, colours and Areas'**
  String get settingsAppearanceSubtitle;

  /// No description provided for @settingsNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders and alerts'**
  String get settingsNotificationsSubtitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsRunSetup.
  ///
  /// In en, this message translates to:
  /// **'Run Setup Tutorial'**
  String get settingsRunSetup;

  /// No description provided for @settingsRunSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions, distractions and your first commitment'**
  String get settingsRunSetupSubtitle;

  /// No description provided for @settingsTakeTour.
  ///
  /// In en, this message translates to:
  /// **'Take the App Tour'**
  String get settingsTakeTour;

  /// No description provided for @settingsTakeTourSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A guided look at Today, Plan and Journey'**
  String get settingsTakeTourSubtitle;

  /// No description provided for @settingsAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App information'**
  String get settingsAboutSubtitle;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Plan your day. Earn your freedom.'**
  String get tagline;

  /// No description provided for @freedomStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Freedom status unavailable'**
  String get freedomStatusUnavailable;

  /// No description provided for @freedomControlOff.
  ///
  /// In en, this message translates to:
  /// **'Freedom Control is off'**
  String get freedomControlOff;

  /// No description provided for @appearanceFollowsDevice.
  ///
  /// In en, this message translates to:
  /// **'Follows your device appearance.'**
  String get appearanceFollowsDevice;

  /// No description provided for @appearanceFixed.
  ///
  /// In en, this message translates to:
  /// **'{mode} appearance, in any device mode.'**
  String appearanceFixed(String mode);

  /// No description provided for @appearanceColourTheme.
  ///
  /// In en, this message translates to:
  /// **'COLOUR THEME'**
  String get appearanceColourTheme;

  /// No description provided for @appearanceLivePreview.
  ///
  /// In en, this message translates to:
  /// **'LIVE PREVIEW'**
  String get appearanceLivePreview;

  /// No description provided for @manageAreas.
  ///
  /// In en, this message translates to:
  /// **'Manage Areas'**
  String get manageAreas;

  /// No description provided for @activeAreas.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 active Area} other{{count} active Areas}}'**
  String activeAreas(int count);

  /// No description provided for @appearancePreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Appearance preview. Example commitment styling.'**
  String get appearancePreviewLabel;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @appearancePreviewComplete.
  ///
  /// In en, this message translates to:
  /// **'1 / 2 complete'**
  String get appearancePreviewComplete;

  /// No description provided for @appearancePreviewProgress.
  ///
  /// In en, this message translates to:
  /// **'Example progress'**
  String get appearancePreviewProgress;

  /// No description provided for @appearancePreviewRecorded.
  ///
  /// In en, this message translates to:
  /// **'23:00 recorded'**
  String get appearancePreviewRecorded;

  /// No description provided for @keptTaskAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Kept {name}'**
  String keptTaskAnnouncement(String name);

  /// No description provided for @todayEarnedTomorrowLocked.
  ///
  /// In en, this message translates to:
  /// **'You kept your word and {weekday} is already committed. Enjoy it.'**
  String todayEarnedTomorrowLocked(String weekday);

  /// No description provided for @todayEarned.
  ///
  /// In en, this message translates to:
  /// **'You kept your word. Enjoy it.'**
  String get todayEarned;

  /// No description provided for @commitments.
  ///
  /// In en, this message translates to:
  /// **'Commitments'**
  String get commitments;

  /// No description provided for @taskActions.
  ///
  /// In en, this message translates to:
  /// **'Task actions'**
  String get taskActions;

  /// No description provided for @showFewerCommitments.
  ///
  /// In en, this message translates to:
  /// **'Show fewer commitments'**
  String get showFewerCommitments;

  /// No description provided for @showAllCommitments.
  ///
  /// In en, this message translates to:
  /// **'Show all {count} commitments'**
  String showAllCommitments(int count);

  /// No description provided for @excusedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} excused'**
  String excusedCount(int count);

  /// No description provided for @keptName.
  ///
  /// In en, this message translates to:
  /// **'Kept: {name}'**
  String keptName(String name);

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @timedHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String timedHoursMinutes(int hours, int minutes);

  /// No description provided for @timedMinutesSeconds.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m {seconds}s'**
  String timedMinutesSeconds(int minutes, int seconds);

  /// No description provided for @timedSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String timedSeconds(int seconds);

  /// No description provided for @noEligibleCommitments.
  ///
  /// In en, this message translates to:
  /// **'No eligible commitments'**
  String get noEligibleCommitments;

  /// No description provided for @keptOfEligible.
  ///
  /// In en, this message translates to:
  /// **'{kept} of {total} kept'**
  String keptOfEligible(int kept, int total);

  /// No description provided for @excusedDontCount.
  ///
  /// In en, this message translates to:
  /// **'Excused commitments don’t count'**
  String get excusedDontCount;

  /// No description provided for @dayComplete.
  ///
  /// In en, this message translates to:
  /// **'Day complete'**
  String get dayComplete;

  /// No description provided for @moreUntilSunUp.
  ///
  /// In en, this message translates to:
  /// **'{count} more and the sun is up'**
  String moreUntilSunUp(int count);

  /// No description provided for @timedSuffix.
  ///
  /// In en, this message translates to:
  /// **'{duration} timed'**
  String timedSuffix(String duration);

  /// No description provided for @commitmentsComplete.
  ///
  /// In en, this message translates to:
  /// **'Commitments complete'**
  String get commitmentsComplete;

  /// No description provided for @todayRestrictionsInSettings.
  ///
  /// In en, this message translates to:
  /// **'App restrictions are configured in Settings.'**
  String get todayRestrictionsInSettings;

  /// No description provided for @freedomEarned.
  ///
  /// In en, this message translates to:
  /// **'Freedom earned'**
  String get freedomEarned;

  /// No description provided for @showFreedomDetails.
  ///
  /// In en, this message translates to:
  /// **'Show Freedom details'**
  String get showFreedomDetails;

  /// No description provided for @appsUnlockedAt.
  ///
  /// In en, this message translates to:
  /// **'Apps unlocked at {time}'**
  String appsUnlockedAt(String time);

  /// No description provided for @freedomEarnedTitle.
  ///
  /// In en, this message translates to:
  /// **'Freedom earned.'**
  String get freedomEarnedTitle;

  /// No description provided for @freedomNotYetEarned.
  ///
  /// In en, this message translates to:
  /// **'Freedom not yet earned'**
  String get freedomNotYetEarned;

  /// No description provided for @freedomOffDetail.
  ///
  /// In en, this message translates to:
  /// **'Earn your apps back by keeping your word.'**
  String get freedomOffDetail;

  /// No description provided for @appsStayLockedToday.
  ///
  /// In en, this message translates to:
  /// **'Apps stay locked today'**
  String get appsStayLockedToday;

  /// No description provided for @emptyDayDetail.
  ///
  /// In en, this message translates to:
  /// **'An empty day doesn’t earn Freedom. Commit a plan for tomorrow.'**
  String get emptyDayDetail;

  /// No description provided for @appsUnlockAt.
  ///
  /// In en, this message translates to:
  /// **'Apps unlock at {time}'**
  String appsUnlockAt(String time);

  /// No description provided for @keepMoreToEarn.
  ///
  /// In en, this message translates to:
  /// **'Keep {count} more to earn it'**
  String keepMoreToEarn(int count);

  /// No description provided for @commitTomorrowToEarn.
  ///
  /// In en, this message translates to:
  /// **'Commit tomorrow’s plan to earn it'**
  String get commitTomorrowToEarn;

  /// No description provided for @waitingForFreedomTime.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Freedom Time'**
  String get waitingForFreedomTime;

  /// No description provided for @everythingKeptUnlockAt.
  ///
  /// In en, this message translates to:
  /// **'Everything’s kept. Apps unlock at {time}'**
  String everythingKeptUnlockAt(String time);

  /// No description provided for @turnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get turnOn;

  /// No description provided for @hideFreedomDetails.
  ///
  /// In en, this message translates to:
  /// **'Hide Freedom details'**
  String get hideFreedomDetails;

  /// No description provided for @aClearDay.
  ///
  /// In en, this message translates to:
  /// **'A clear day.'**
  String get aClearDay;

  /// No description provided for @allSetFor.
  ///
  /// In en, this message translates to:
  /// **'All set for {weekday}.'**
  String allSetFor(String weekday);

  /// No description provided for @emptyTodayNoPlan.
  ///
  /// In en, this message translates to:
  /// **'No commitments for today. Plan tomorrow, and tomorrow’s sun is yours to raise.'**
  String get emptyTodayNoPlan;

  /// No description provided for @emptyTodayLocked.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned today, and tomorrow is locked in. Rest is the plan.'**
  String get emptyTodayLocked;

  /// No description provided for @weekdayCommitmentCount.
  ///
  /// In en, this message translates to:
  /// **'{weekday}’s {count}'**
  String weekdayCommitmentCount(String weekday, int count);

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @planTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Plan tomorrow'**
  String get planTomorrow;

  /// No description provided for @repeatNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get repeatNever;

  /// No description provided for @repeatCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get repeatCustom;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @repeatClose.
  ///
  /// In en, this message translates to:
  /// **'Close repeat options'**
  String get repeatClose;

  /// No description provided for @repeatDaysOfWeek.
  ///
  /// In en, this message translates to:
  /// **'Days of week'**
  String get repeatDaysOfWeek;

  /// No description provided for @repeatEveryNDays.
  ///
  /// In en, this message translates to:
  /// **'Every N days'**
  String get repeatEveryNDays;

  /// No description provided for @repeatEvery.
  ///
  /// In en, this message translates to:
  /// **'Every'**
  String get repeatEvery;

  /// No description provided for @repeatFewerDays.
  ///
  /// In en, this message translates to:
  /// **'Fewer days'**
  String get repeatFewerDays;

  /// No description provided for @repeatMoreDays.
  ///
  /// In en, this message translates to:
  /// **'More days'**
  String get repeatMoreDays;

  /// No description provided for @repeatPickOneDay.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one day.'**
  String get repeatPickOneDay;

  /// No description provided for @repeatOnlyThisDay.
  ///
  /// In en, this message translates to:
  /// **'Only this day. It won’t repeat.'**
  String get repeatOnlyThisDay;

  /// No description provided for @repeatNext.
  ///
  /// In en, this message translates to:
  /// **'Next: {dates}'**
  String repeatNext(String dates);

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @editCommitment.
  ///
  /// In en, this message translates to:
  /// **'Edit commitment'**
  String get editCommitment;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @removeCommitmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove commitment?'**
  String get removeCommitmentTitle;

  /// No description provided for @removeFromDraft.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from tomorrow’s draft?'**
  String removeFromDraft(String name);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @areaFor.
  ///
  /// In en, this message translates to:
  /// **'Area for {name}'**
  String areaFor(String name);

  /// No description provided for @lockInWeekdayQuestion.
  ///
  /// In en, this message translates to:
  /// **'Lock in {weekday}?'**
  String lockInWeekdayQuestion(String weekday);

  /// No description provided for @lockInConfirmOne.
  ///
  /// In en, this message translates to:
  /// **'This locks your commitment for {weekday}. You won’t be able to add or change it.'**
  String lockInConfirmOne(String weekday);

  /// No description provided for @lockInConfirmMany.
  ///
  /// In en, this message translates to:
  /// **'This locks your {count} commitments for {weekday}. You won’t be able to add or change them.'**
  String lockInConfirmMany(int count, String weekday);

  /// No description provided for @keepPlanning.
  ///
  /// In en, this message translates to:
  /// **'Keep planning'**
  String get keepPlanning;

  /// No description provided for @lockItIn.
  ///
  /// In en, this message translates to:
  /// **'Lock it in'**
  String get lockItIn;

  /// No description provided for @plan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get plan;

  /// No description provided for @tomorrowDate.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow · {date}'**
  String tomorrowDate(String date);

  /// No description provided for @committed.
  ///
  /// In en, this message translates to:
  /// **'Committed'**
  String get committed;

  /// No description provided for @draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @noScheduledEventsTomorrow.
  ///
  /// In en, this message translates to:
  /// **'No scheduled events for tomorrow.'**
  String get noScheduledEventsTomorrow;

  /// No description provided for @scheduledEvents.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 scheduled event} other{{count} scheduled events}}'**
  String scheduledEvents(int count);

  /// No description provided for @commitmentsCount.
  ///
  /// In en, this message translates to:
  /// **'Commitments · {count}'**
  String commitmentsCount(int count);

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addACommitment.
  ///
  /// In en, this message translates to:
  /// **'Add a commitment'**
  String get addACommitment;

  /// No description provided for @noCommitmentsPlanned.
  ///
  /// In en, this message translates to:
  /// **'No commitments planned yet.'**
  String get noCommitmentsPlanned;

  /// No description provided for @tomorrowIsLocked.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow is locked.'**
  String get tomorrowIsLocked;

  /// No description provided for @addOneSmallStep.
  ///
  /// In en, this message translates to:
  /// **'Add one small step for tomorrow.'**
  String get addOneSmallStep;

  /// No description provided for @lockInWeekday.
  ///
  /// In en, this message translates to:
  /// **'Lock in {weekday}'**
  String lockInWeekday(String weekday);

  /// No description provided for @addOneToLockIn.
  ///
  /// In en, this message translates to:
  /// **'Add at least one commitment to lock in {weekday}.'**
  String addOneToLockIn(String weekday);

  /// No description provided for @locksThisCommitment.
  ///
  /// In en, this message translates to:
  /// **'Locks this commitment. You can’t change it after.'**
  String get locksThisCommitment;

  /// No description provided for @locksTheseCommitments.
  ///
  /// In en, this message translates to:
  /// **'Locks these {count}. You can’t change them after.'**
  String locksTheseCommitments(int count);

  /// No description provided for @archivedArea.
  ///
  /// In en, this message translates to:
  /// **'{name} (archived)'**
  String archivedArea(String name);

  /// No description provided for @actionsFor.
  ///
  /// In en, this message translates to:
  /// **'Actions for {name}'**
  String actionsFor(String name);

  /// No description provided for @removeCommitment.
  ///
  /// In en, this message translates to:
  /// **'Remove commitment'**
  String get removeCommitment;

  /// No description provided for @tomorrowPlanCommitted.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow\'s plan is committed.'**
  String get tomorrowPlanCommitted;

  /// No description provided for @yourCommitmentsLocked.
  ///
  /// In en, this message translates to:
  /// **'Your commitments are locked.'**
  String get yourCommitmentsLocked;

  /// No description provided for @nextTomorrow.
  ///
  /// In en, this message translates to:
  /// **'next: tomorrow'**
  String get nextTomorrow;

  /// No description provided for @nextDate.
  ///
  /// In en, this message translates to:
  /// **'next: {date}'**
  String nextDate(String date);

  /// No description provided for @rotationSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} steps · up next: {name}'**
  String rotationSummary(int count, String name);

  /// No description provided for @deleteRoutineTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete routine?'**
  String get deleteRoutineTitle;

  /// No description provided for @deleteRoutineBody.
  ///
  /// In en, this message translates to:
  /// **'Stop repeating {name}? Commitments already in your plans and history stay.'**
  String deleteRoutineBody(String name);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @routines.
  ///
  /// In en, this message translates to:
  /// **'Routines'**
  String get routines;

  /// No description provided for @routinesIntro.
  ///
  /// In en, this message translates to:
  /// **'Routines add themselves to tomorrow’s plan on the days they’re due. Remove one from a plan to skip just that day. A rotation with several steps moves on only after a step stays in your plan.'**
  String get routinesIntro;

  /// No description provided for @createRoutineOrRotation.
  ///
  /// In en, this message translates to:
  /// **'Create routine or rotation'**
  String get createRoutineOrRotation;

  /// No description provided for @noRoutinesYet.
  ///
  /// In en, this message translates to:
  /// **'No routines yet.'**
  String get noRoutinesYet;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @newRoutineStep.
  ///
  /// In en, this message translates to:
  /// **'New routine step'**
  String get newRoutineStep;

  /// No description provided for @editRoutineStep.
  ///
  /// In en, this message translates to:
  /// **'Edit routine step'**
  String get editRoutineStep;

  /// No description provided for @addStep.
  ///
  /// In en, this message translates to:
  /// **'Add step'**
  String get addStep;

  /// No description provided for @saveStep.
  ///
  /// In en, this message translates to:
  /// **'Save step'**
  String get saveStep;

  /// No description provided for @createRoutine.
  ///
  /// In en, this message translates to:
  /// **'Create routine'**
  String get createRoutine;

  /// No description provided for @editRoutine.
  ///
  /// In en, this message translates to:
  /// **'Edit routine'**
  String get editRoutine;

  /// No description provided for @routineName.
  ///
  /// In en, this message translates to:
  /// **'Routine name'**
  String get routineName;

  /// No description provided for @routineRotationHelp.
  ///
  /// In en, this message translates to:
  /// **'A rotation: each due day adds the next step, in this order. A step you remove comes back next time.'**
  String get routineRotationHelp;

  /// No description provided for @routineSingleHelp.
  ///
  /// In en, this message translates to:
  /// **'Each due day adds this to tomorrow’s plan automatically. Add more steps to make a rotation.'**
  String get routineSingleHelp;

  /// No description provided for @editStepN.
  ///
  /// In en, this message translates to:
  /// **'Edit step {number}'**
  String editStepN(int number);

  /// No description provided for @moveStepUp.
  ///
  /// In en, this message translates to:
  /// **'Move step {number} up'**
  String moveStepUp(int number);

  /// No description provided for @moveStepDown.
  ///
  /// In en, this message translates to:
  /// **'Move step {number} down'**
  String moveStepDown(int number);

  /// No description provided for @removeStepN.
  ///
  /// In en, this message translates to:
  /// **'Remove step {number}'**
  String removeStepN(int number);

  /// No description provided for @addCommitment.
  ///
  /// In en, this message translates to:
  /// **'Add commitment'**
  String get addCommitment;

  /// No description provided for @addRotationStep.
  ///
  /// In en, this message translates to:
  /// **'Add rotation step'**
  String get addRotationStep;

  /// No description provided for @saveRoutine.
  ///
  /// In en, this message translates to:
  /// **'Save routine'**
  String get saveRoutine;

  /// No description provided for @newCommitment.
  ///
  /// In en, this message translates to:
  /// **'New commitment'**
  String get newCommitment;

  /// No description provided for @partOfRotation.
  ///
  /// In en, this message translates to:
  /// **'Part of a rotation. Change it in Routines.'**
  String get partOfRotation;

  /// No description provided for @commitmentHint.
  ///
  /// In en, this message translates to:
  /// **'One small, specific step'**
  String get commitmentHint;

  /// No description provided for @closeEditor.
  ///
  /// In en, this message translates to:
  /// **'Close editor'**
  String get closeEditor;

  /// No description provided for @commitmentName.
  ///
  /// In en, this message translates to:
  /// **'Commitment name'**
  String get commitmentName;

  /// No description provided for @statusKept.
  ///
  /// In en, this message translates to:
  /// **'Kept'**
  String get statusKept;

  /// No description provided for @statusNotKeptYet.
  ///
  /// In en, this message translates to:
  /// **'Not kept yet'**
  String get statusNotKeptYet;

  /// No description provided for @durationRecorded.
  ///
  /// In en, this message translates to:
  /// **'{duration} recorded'**
  String durationRecorded(String duration);

  /// No description provided for @excuseReason.
  ///
  /// In en, this message translates to:
  /// **'Excuse reason'**
  String get excuseReason;

  /// No description provided for @markCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark completed'**
  String get markCompleted;

  /// No description provided for @excuseTask.
  ///
  /// In en, this message translates to:
  /// **'Excuse task'**
  String get excuseTask;

  /// No description provided for @resetToIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Reset to incomplete'**
  String get resetToIncomplete;

  /// No description provided for @excuseCommitment.
  ///
  /// In en, this message translates to:
  /// **'Excuse commitment'**
  String get excuseCommitment;

  /// No description provided for @excusePrompt.
  ///
  /// In en, this message translates to:
  /// **'What outside circumstance prevented you from completing it?'**
  String get excusePrompt;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @enterShortReason.
  ///
  /// In en, this message translates to:
  /// **'Enter a short reason.'**
  String get enterShortReason;

  /// No description provided for @shortenReason.
  ///
  /// In en, this message translates to:
  /// **'Please shorten this reason.'**
  String get shortenReason;

  /// No description provided for @durationMinutesSeconds.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min {seconds} s'**
  String durationMinutesSeconds(int minutes, int seconds);

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your saved commitments.'**
  String get loadFailed;

  /// No description provided for @loadingDay.
  ///
  /// In en, this message translates to:
  /// **'Getting your day ready.'**
  String get loadingDay;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loadingCommitments.
  ///
  /// In en, this message translates to:
  /// **'Loading commitments'**
  String get loadingCommitments;

  /// No description provided for @journey.
  ///
  /// In en, this message translates to:
  /// **'Journey'**
  String get journey;

  /// No description provided for @dayStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day streak} other{{count} day streak}}'**
  String dayStreakLabel(int count);

  /// No description provided for @dayStreakWord.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{day streak} other{day streak}}'**
  String dayStreakWord(int count);

  /// No description provided for @streakStartHint.
  ///
  /// In en, this message translates to:
  /// **'Keep all of today to start one'**
  String get streakStartHint;

  /// No description provided for @streakLongestYet.
  ///
  /// In en, this message translates to:
  /// **'Your longest yet'**
  String get streakLongestYet;

  /// No description provided for @streakLongest.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Longest: 1 day} other{Longest: {count} days}}'**
  String streakLongest(int count);

  /// No description provided for @totalKept.
  ///
  /// In en, this message translates to:
  /// **'kept'**
  String get totalKept;

  /// No description provided for @totalFocused.
  ///
  /// In en, this message translates to:
  /// **'focused'**
  String get totalFocused;

  /// No description provided for @shortMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String shortMinutes(int minutes);

  /// No description provided for @shortHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String shortHours(int hours);

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all {count}'**
  String seeAll(int count);

  /// No description provided for @addAchievement.
  ///
  /// In en, this message translates to:
  /// **'Add achievement'**
  String get addAchievement;

  /// No description provided for @last5Weeks.
  ///
  /// In en, this message translates to:
  /// **'Last 5 weeks'**
  String get last5Weeks;

  /// No description provided for @dailyHistory.
  ///
  /// In en, this message translates to:
  /// **'Daily history'**
  String get dailyHistory;

  /// No description provided for @yourAreas.
  ///
  /// In en, this message translates to:
  /// **'Your Areas'**
  String get yourAreas;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @pastChapters.
  ///
  /// In en, this message translates to:
  /// **'Past Chapters'**
  String get pastChapters;

  /// No description provided for @areasArchived.
  ///
  /// In en, this message translates to:
  /// **'Areas you’ve archived'**
  String get areasArchived;

  /// No description provided for @achievementSemantics.
  ///
  /// In en, this message translates to:
  /// **'Achievement: {title}, {date}'**
  String achievementSemantics(String title, String date);

  /// No description provided for @areaUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Area unavailable'**
  String get areaUnavailable;

  /// No description provided for @keepAMoment.
  ///
  /// In en, this message translates to:
  /// **'Keep a moment that matters.'**
  String get keepAMoment;

  /// No description provided for @addAnAchievement.
  ///
  /// In en, this message translates to:
  /// **'Add an achievement'**
  String get addAnAchievement;

  /// No description provided for @achievementExamples.
  ///
  /// In en, this message translates to:
  /// **'A driving licence, a first 10k, a finished chapter.'**
  String get achievementExamples;

  /// No description provided for @last5WeeksKept.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Last 5 weeks: 1 day fully kept} other{Last 5 weeks: {count} days fully kept}}'**
  String last5WeeksKept(int count);

  /// No description provided for @legendAllKept.
  ///
  /// In en, this message translates to:
  /// **'All kept'**
  String get legendAllKept;

  /// No description provided for @legendSomeKept.
  ///
  /// In en, this message translates to:
  /// **'Some kept'**
  String get legendSomeKept;

  /// No description provided for @legendMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get legendMissed;

  /// No description provided for @keptThisWeek.
  ///
  /// In en, this message translates to:
  /// **'{count} this week'**
  String keptThisWeek(int count);

  /// No description provided for @areaKeptThisWeek.
  ///
  /// In en, this message translates to:
  /// **'{area}: {count} kept this week'**
  String areaKeptThisWeek(String area, int count);

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get last30Days;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get allTime;

  /// No description provided for @completedCommitments.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 completed commitment} other{{count} completed commitments}}'**
  String completedCommitments(int count);

  /// No description provided for @recordedTime.
  ///
  /// In en, this message translates to:
  /// **'{duration} recorded time'**
  String recordedTime(String duration);

  /// No description provided for @stopwatchExplainer.
  ///
  /// In en, this message translates to:
  /// **'Stopwatch time records actual effort, including incomplete commitments.'**
  String get stopwatchExplainer;

  /// No description provided for @activityOverTime.
  ///
  /// In en, this message translates to:
  /// **'ACTIVITY OVER TIME'**
  String get activityOverTime;

  /// No description provided for @trackedTime.
  ///
  /// In en, this message translates to:
  /// **'Tracked time'**
  String get trackedTime;

  /// No description provided for @achievementsPlace.
  ///
  /// In en, this message translates to:
  /// **'A place for the moments you want to remember.'**
  String get achievementsPlace;

  /// No description provided for @recordedCommitments.
  ///
  /// In en, this message translates to:
  /// **'Recorded commitments'**
  String get recordedCommitments;

  /// No description provided for @recordsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 record} other{{count} records}}'**
  String recordsCount(int count);

  /// No description provided for @recordsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your recorded commitments will appear here.'**
  String get recordsEmpty;

  /// No description provided for @recordedTimeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Recorded time will appear here.'**
  String get recordedTimeEmpty;

  /// No description provided for @completedEmpty.
  ///
  /// In en, this message translates to:
  /// **'Completed commitments will appear here.'**
  String get completedEmpty;

  /// No description provided for @activityDetails.
  ///
  /// In en, this message translates to:
  /// **'Activity details'**
  String get activityDetails;

  /// No description provided for @activityRange.
  ///
  /// In en, this message translates to:
  /// **'{from} to {through}: {value}'**
  String activityRange(String from, String through, String value);

  /// No description provided for @activityDescriptionTime.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days, recorded time. {days}'**
  String activityDescriptionTime(String days);

  /// No description provided for @activityDescriptionCompleted.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days, completed commitments. {days}'**
  String activityDescriptionCompleted(String days);

  /// No description provided for @thirtyDaysTime.
  ///
  /// In en, this message translates to:
  /// **'30 days · time'**
  String get thirtyDaysTime;

  /// No description provided for @thirtyDaysCompleted.
  ///
  /// In en, this message translates to:
  /// **'30 days · completed'**
  String get thirtyDaysCompleted;

  /// No description provided for @completedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} completed'**
  String completedCount(int count);

  /// No description provided for @openSpace.
  ///
  /// In en, this message translates to:
  /// **'Open space'**
  String get openSpace;

  /// No description provided for @openArea.
  ///
  /// In en, this message translates to:
  /// **'Open Area'**
  String get openArea;

  /// No description provided for @latestAchievement.
  ///
  /// In en, this message translates to:
  /// **'Latest achievement'**
  String get latestAchievement;

  /// No description provided for @pastChaptersIntro.
  ///
  /// In en, this message translates to:
  /// **'Parts of your life, kept here to revisit.'**
  String get pastChaptersIntro;

  /// No description provided for @pastChaptersEmpty.
  ///
  /// In en, this message translates to:
  /// **'Archived Areas will stay here, along with their history.'**
  String get pastChaptersEmpty;

  /// No description provided for @savePendingBeforeStopwatch.
  ///
  /// In en, this message translates to:
  /// **'Save your pending changes before changing a stopwatch.'**
  String get savePendingBeforeStopwatch;

  /// No description provided for @couldNotSaveAppearance.
  ///
  /// In en, this message translates to:
  /// **'Could not save appearance settings.'**
  String get couldNotSaveAppearance;

  /// No description provided for @couldNotSaveSetup.
  ///
  /// In en, this message translates to:
  /// **'Could not save setup. Please retry from Settings.'**
  String get couldNotSaveSetup;

  /// No description provided for @tomorrowAlreadyCommitted.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow’s plan is already committed. Existing commitments are kept. Add another after the next day starts.'**
  String get tomorrowAlreadyCommitted;

  /// No description provided for @firstCommitmentHeading.
  ///
  /// In en, this message translates to:
  /// **'Your first commitment · tomorrow'**
  String get firstCommitmentHeading;

  /// No description provided for @pausedTask.
  ///
  /// In en, this message translates to:
  /// **'Paused {name}.'**
  String pausedTask(String name);

  /// No description provided for @removedForWeekday.
  ///
  /// In en, this message translates to:
  /// **'Removed for {weekday}.'**
  String removedForWeekday(String weekday);

  /// No description provided for @stopRepeating.
  ///
  /// In en, this message translates to:
  /// **'Stop repeating'**
  String get stopRepeating;

  /// No description provided for @stoppedRepeating.
  ///
  /// In en, this message translates to:
  /// **'Stopped repeating.'**
  String get stoppedRepeating;

  /// No description provided for @achievementsIntro.
  ///
  /// In en, this message translates to:
  /// **'Things you’re proud of: a driving licence, a first 10k, a finished chapter.'**
  String get achievementsIntro;

  /// No description provided for @achievement.
  ///
  /// In en, this message translates to:
  /// **'Achievement'**
  String get achievement;

  /// No description provided for @achievementRemoved.
  ///
  /// In en, this message translates to:
  /// **'This achievement has been removed.'**
  String get achievementRemoved;

  /// No description provided for @deleteAchievementTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete achievement?'**
  String get deleteAchievementTitle;

  /// No description provided for @deleteAchievementBody.
  ///
  /// In en, this message translates to:
  /// **'Remove “{title}”? Your commitments and Areas will stay as they are.'**
  String deleteAchievementBody(String title);

  /// No description provided for @keepAchievement.
  ///
  /// In en, this message translates to:
  /// **'Keep achievement'**
  String get keepAchievement;

  /// No description provided for @couldNotSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Could not save your changes.'**
  String get couldNotSaveChanges;

  /// No description provided for @tourDayTitle.
  ///
  /// In en, this message translates to:
  /// **'This is your day'**
  String get tourDayTitle;

  /// No description provided for @tourDayBody.
  ///
  /// In en, this message translates to:
  /// **'The sun climbs as you keep today’s commitments. Keep them all and it’s fully risen.'**
  String get tourDayBody;

  /// No description provided for @tourCommitmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Today’s commitments'**
  String get tourCommitmentsTitle;

  /// No description provided for @tourCommitmentsBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the circle to keep one. Tap the row to run a stopwatch, or excuse it with a reason if something really came up.'**
  String get tourCommitmentsBody;

  /// No description provided for @tourFreedomTitle.
  ///
  /// In en, this message translates to:
  /// **'Freedom'**
  String get tourFreedomTitle;

  /// No description provided for @tourFreedomBody.
  ///
  /// In en, this message translates to:
  /// **'Apps you restrict open at Freedom Time, once today is kept and tomorrow is locked in. Tap here any time to see what’s left.'**
  String get tourFreedomBody;

  /// No description provided for @tourPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan tomorrow'**
  String get tourPlanTitle;

  /// No description provided for @tourPlanBody.
  ///
  /// In en, this message translates to:
  /// **'Each evening, plan tomorrow while today is still fresh. Pick a few things you’ll really do.'**
  String get tourPlanBody;

  /// No description provided for @tourAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add and repeat'**
  String get tourAddTitle;

  /// No description provided for @tourAddBody.
  ///
  /// In en, this message translates to:
  /// **'Add a commitment and give it an Area. Turn on Repeat for habits, and they fill themselves in on their days.'**
  String get tourAddBody;

  /// No description provided for @tourLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Lock it in'**
  String get tourLockTitle;

  /// No description provided for @tourLockBody.
  ///
  /// In en, this message translates to:
  /// **'When tomorrow looks right, lock it in. After that it can’t change. That’s what makes it a commitment.'**
  String get tourLockBody;

  /// No description provided for @tourJourneyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Journey'**
  String get tourJourneyTitle;

  /// No description provided for @tourJourneyBody.
  ///
  /// In en, this message translates to:
  /// **'Every kept day counts here: your streak, the effort you put in, and the achievements you’re proud of.'**
  String get tourJourneyBody;

  /// No description provided for @tourAreasTitle.
  ///
  /// In en, this message translates to:
  /// **'Areas'**
  String get tourAreasTitle;

  /// No description provided for @tourAreasBody.
  ///
  /// In en, this message translates to:
  /// **'Each Area tracks one part of your life, like Body, Mind or Career. Add, rename or archive them here. Further down, open one to see its history.'**
  String get tourAreasBody;

  /// No description provided for @tourSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tourSettingsTitle;

  /// No description provided for @tourSettingsBody.
  ///
  /// In en, this message translates to:
  /// **'Freedom Time, app blocking, routines, reminders and colours live here. You can replay this tour from Settings too.'**
  String get tourSettingsBody;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String stepOf(int current, int total);

  /// No description provided for @skipTour.
  ///
  /// In en, this message translates to:
  /// **'Skip tour'**
  String get skipTour;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @tourStepSemantics.
  ///
  /// In en, this message translates to:
  /// **'App tour, step {current} of {total}'**
  String tourStepSemantics(int current, int total);

  /// No description provided for @setupTourBody.
  ///
  /// In en, this message translates to:
  /// **'We’ll walk through the real Today, Plan and Journey screens and point out what each part does. It takes about a minute, and you can skip it any time.'**
  String get setupTourBody;

  /// No description provided for @setupTestBody.
  ///
  /// In en, this message translates to:
  /// **'Open a selected app and look for Daylock’s lock screen. Return here to see the result. Also open it normally from Home after leaving Daylock in the background: this test confirms only one opening. This uses your real Freedom conditions and never completes a goal for you.'**
  String get setupTestBody;

  /// No description provided for @setupFirstCommitmentBody.
  ///
  /// In en, this message translates to:
  /// **'Today’s plan is already locked. Your first new commitment goes into tomorrow’s real plan. Apps unlock when all eligible commitments are complete, Freedom Time is reached, and tomorrow’s plan is committed. An empty day does not earn Freedom.'**
  String get setupFirstCommitmentBody;

  /// No description provided for @setupAccessibilityOemHelp.
  ///
  /// In en, this message translates to:
  /// **'On Xiaomi / HyperOS, Samsung and Pixel, settings names vary. Choose this installed Daylock app’s service. If “Restricted settings” appears, review App info → Allow restricted settings only for a build you trust. If the service is enabled but disconnected, toggle it off and on once.'**
  String get setupAccessibilityOemHelp;

  /// No description provided for @setupAccessibilityExplain.
  ///
  /// In en, this message translates to:
  /// **'Daylock detects when a selected app opens and can show its lock screen or return Home. Screen contents are never read. Access is optional and can be revoked in Android Settings.'**
  String get setupAccessibilityExplain;

  /// No description provided for @setupBlockingOptional.
  ///
  /// In en, this message translates to:
  /// **'App blocking is optional. Without it, Daylock still plans your days and tracks your commitments. You can turn it on later in Settings.'**
  String get setupBlockingOptional;

  /// No description provided for @setupXiaomiBody.
  ///
  /// In en, this message translates to:
  /// **'HyperOS can pause Daylock in the background even while Accessibility shows enabled. A test inside Daylock may work while opening Instagram from Home does not.\n\nIn this app’s App info:\n• Autostart: on\n• Battery saver (or Power): No restrictions\n• Other permissions → Display pop-up windows while running in the background: allow\n\nSwiping Daylock away in Recents or using “Clean” can still stop blocking. If that happens, Today shows a warning: turn Daylock off and on in Accessibility.\n\nUse the settings for this installed Daylock app; Daylock Dev and the Play version have separate settings. Daylock cannot read these Xiaomi choices. Confirm them yourself below, then test normal app openings too.'**
  String get setupXiaomiBody;

  /// No description provided for @setupLockNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Lock screen not confirmed. Check Accessibility is connected, then retry. Android may return Home or restrict the lock-screen launch. Open Permissions & Diagnostics in Settings for the recorded result.'**
  String get setupLockNotConfirmed;

  /// No description provided for @setupVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified: Android displayed the Daylock lock screen.'**
  String get setupVerified;

  /// No description provided for @setupSaveProgressFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save setup progress. Please retry.'**
  String get setupSaveProgressFailed;

  /// No description provided for @setupOpeningApp.
  ///
  /// In en, this message translates to:
  /// **'Opening your selected app. Return to Daylock after checking the lock screen.'**
  String get setupOpeningApp;

  /// No description provided for @setupSaveConfirmationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your confirmation. Please retry.'**
  String get setupSaveConfirmationFailed;

  /// No description provided for @setupWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Plan your day. Earn your freedom. Keep your commitments before your distracting apps unlock.'**
  String get setupWelcomeBody;

  /// No description provided for @setupWelcomePlan.
  ///
  /// In en, this message translates to:
  /// **'Choose a few meaningful commitments the evening before.'**
  String get setupWelcomePlan;

  /// No description provided for @setupBlockDistractions.
  ///
  /// In en, this message translates to:
  /// **'Block distractions'**
  String get setupBlockDistractions;

  /// No description provided for @setupWelcomeBlock.
  ///
  /// In en, this message translates to:
  /// **'You choose which apps to restrict.'**
  String get setupWelcomeBlock;

  /// No description provided for @setupKeepYourWord.
  ///
  /// In en, this message translates to:
  /// **'Keep your word'**
  String get setupKeepYourWord;

  /// No description provided for @setupWelcomeKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep today’s commitments, then lock in tomorrow’s plan.'**
  String get setupWelcomeKeep;

  /// No description provided for @setupUnlockApps.
  ///
  /// In en, this message translates to:
  /// **'Unlock apps'**
  String get setupUnlockApps;

  /// No description provided for @setupWelcomeUnlock.
  ///
  /// In en, this message translates to:
  /// **'Reach your Freedom Time and enjoy your earned break.'**
  String get setupWelcomeUnlock;

  /// No description provided for @setupXiaomiTitle.
  ///
  /// In en, this message translates to:
  /// **'Xiaomi / Poco: keep blocking active'**
  String get setupXiaomiTitle;

  /// No description provided for @setupOpenAppInfo.
  ///
  /// In en, this message translates to:
  /// **'Open Daylock App info'**
  String get setupOpenAppInfo;

  /// No description provided for @setupXiaomiConfirm.
  ///
  /// In en, this message translates to:
  /// **'I changed these settings for this Daylock app'**
  String get setupXiaomiConfirm;

  /// No description provided for @setupXiaomiConfirmNote.
  ///
  /// In en, this message translates to:
  /// **'Your confirmation; not automatically verified.'**
  String get setupXiaomiConfirmNote;

  /// No description provided for @setupAccessibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Accessibility access · optional'**
  String get setupAccessibilityTitle;

  /// No description provided for @setupBlockingAndroidOnly.
  ///
  /// In en, this message translates to:
  /// **'Blocking is available on Android. You can still use the planner here.'**
  String get setupBlockingAndroidOnly;

  /// No description provided for @setupAccessibilityConnected.
  ///
  /// In en, this message translates to:
  /// **'Enabled and connected. Daylock is ready to detect selected apps.'**
  String get setupAccessibilityConnected;

  /// No description provided for @setupAccessibilityWaiting.
  ///
  /// In en, this message translates to:
  /// **'Enabled. Waiting for Android to connect the service. Tap Refresh after returning.'**
  String get setupAccessibilityWaiting;

  /// No description provided for @setupEnableAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Enable Accessibility'**
  String get setupEnableAccessibility;

  /// No description provided for @setupNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications · optional'**
  String get setupNotificationsTitle;

  /// No description provided for @setupNotificationsAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed. Local reminders and fallback restriction notices can appear.'**
  String get setupNotificationsAllowed;

  /// No description provided for @setupNotificationsExplain.
  ///
  /// In en, this message translates to:
  /// **'Allow local reminders and a notice when Android cannot display the lock screen. You can continue without notifications.'**
  String get setupNotificationsExplain;

  /// No description provided for @setupAllowNotifications.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get setupAllowNotifications;

  /// No description provided for @setupRefreshPermissions.
  ///
  /// In en, this message translates to:
  /// **'Refresh permission status'**
  String get setupRefreshPermissions;

  /// No description provided for @setupChooseAppsBody.
  ///
  /// In en, this message translates to:
  /// **'Choose apps you want to open more intentionally. Your selections stay on this device.'**
  String get setupChooseAppsBody;

  /// No description provided for @setupRestrictionsEnableFreedom.
  ///
  /// In en, this message translates to:
  /// **'Turning on app restrictions here also enables Freedom Control at your saved Freedom Time.'**
  String get setupRestrictionsEnableFreedom;

  /// No description provided for @setupSaveBlockingFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save blocking settings. Please retry.'**
  String get setupSaveBlockingFailed;

  /// No description provided for @setupAppSelectionAndroidOnly.
  ///
  /// In en, this message translates to:
  /// **'Installed-app selection is available on Android.'**
  String get setupAppSelectionAndroidOnly;

  /// No description provided for @setupOneSmallStep.
  ///
  /// In en, this message translates to:
  /// **'One small step for tomorrow'**
  String get setupOneSmallStep;

  /// No description provided for @setupSaveCommitmentFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your commitment. Please retry.'**
  String get setupSaveCommitmentFailed;

  /// No description provided for @setupCreateCommitment.
  ///
  /// In en, this message translates to:
  /// **'Create a commitment'**
  String get setupCreateCommitment;

  /// No description provided for @setupAlreadyHasCommitment.
  ///
  /// In en, this message translates to:
  /// **'Your plan already contains a commitment. You can continue without creating another.'**
  String get setupAlreadyHasCommitment;

  /// No description provided for @setupTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Try your real app restriction'**
  String get setupTestTitle;

  /// No description provided for @setupTestAndroidOnly.
  ///
  /// In en, this message translates to:
  /// **'Blocking tests require the Android app.'**
  String get setupTestAndroidOnly;

  /// No description provided for @setupChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get setupChecking;

  /// No description provided for @setupTestSelectedApp.
  ///
  /// In en, this message translates to:
  /// **'Test a selected app'**
  String get setupTestSelectedApp;

  /// No description provided for @setupEnableFreedomAndRestrictions.
  ///
  /// In en, this message translates to:
  /// **'Enable Freedom Control and app restrictions'**
  String get setupEnableFreedomAndRestrictions;

  /// No description provided for @setupTestNeedsFreedom.
  ///
  /// In en, this message translates to:
  /// **'Current Freedom: {state}. The real test needs Freedom Control on and Freedom not yet earned. You can leave setup and return from Settings when those conditions apply.'**
  String setupTestNeedsFreedom(String state);

  /// No description provided for @setupAccessibilityNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Accessibility is not connected. Go back to permission setup.'**
  String get setupAccessibilityNotConnected;

  /// No description provided for @setupConfirmXiaomi.
  ///
  /// In en, this message translates to:
  /// **'Go back to Set Up App Blocking and confirm the Xiaomi battery setting so blocking keeps working.'**
  String get setupConfirmXiaomi;

  /// No description provided for @setupRefreshRetry.
  ///
  /// In en, this message translates to:
  /// **'Refresh and retry'**
  String get setupRefreshRetry;

  /// No description provided for @setupReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Make room for what matters'**
  String get setupReadyTitle;

  /// No description provided for @setupReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Your preferences and commitment are saved. Start with Today, plan tomorrow, and watch your Journey grow.'**
  String get setupReadyBody;

  /// No description provided for @setupTourTitle.
  ///
  /// In en, this message translates to:
  /// **'Take a quick tour'**
  String get setupTourTitle;

  /// No description provided for @setupBlockingOff.
  ///
  /// In en, this message translates to:
  /// **'App blocking is off'**
  String get setupBlockingOff;

  /// No description provided for @setupBlockingOffBody.
  ///
  /// In en, this message translates to:
  /// **'Daylock won’t restrict any apps. If you want it later, open Settings and turn on app restrictions.'**
  String get setupBlockingOffBody;

  /// No description provided for @setupSkipTour.
  ///
  /// In en, this message translates to:
  /// **'Skip the tour'**
  String get setupSkipTour;

  /// No description provided for @previousStep.
  ///
  /// In en, this message translates to:
  /// **'Previous step'**
  String get previousStep;

  /// No description provided for @saveAndLeave.
  ///
  /// In en, this message translates to:
  /// **'Save & leave'**
  String get saveAndLeave;

  /// No description provided for @stepNOfM.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepNOfM(int current, int total);

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @continueWithoutBlocking.
  ///
  /// In en, this message translates to:
  /// **'Continue without blocking'**
  String get continueWithoutBlocking;

  /// No description provided for @skipTestForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip test for now'**
  String get skipTestForNow;

  /// No description provided for @finishSetup.
  ///
  /// In en, this message translates to:
  /// **'Finish Setup'**
  String get finishSetup;

  /// No description provided for @takeTheTour.
  ///
  /// In en, this message translates to:
  /// **'Take the tour'**
  String get takeTheTour;

  /// No description provided for @goToDaylock.
  ///
  /// In en, this message translates to:
  /// **'Go to Daylock'**
  String get goToDaylock;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @setupTitleWelcome.
  ///
  /// In en, this message translates to:
  /// **'Take Back Control'**
  String get setupTitleWelcome;

  /// No description provided for @setupTitleBlocking.
  ///
  /// In en, this message translates to:
  /// **'Set Up App Blocking'**
  String get setupTitleBlocking;

  /// No description provided for @setupTitleApps.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Distractions'**
  String get setupTitleApps;

  /// No description provided for @setupTitleCommitment.
  ///
  /// In en, this message translates to:
  /// **'Set Your First Commitment'**
  String get setupTitleCommitment;

  /// No description provided for @setupTitleTest.
  ///
  /// In en, this message translates to:
  /// **'You\'re Almost Ready!'**
  String get setupTitleTest;

  /// No description provided for @setupTitleReady.
  ///
  /// In en, this message translates to:
  /// **'You\'re All Set!'**
  String get setupTitleReady;

  /// No description provided for @diagLockUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Lock screen: not confirmed; a fallback notification may be used.'**
  String get diagLockUnconfirmed;

  /// No description provided for @diagLockFailedException.
  ///
  /// In en, this message translates to:
  /// **'Lock screen: Android rejected or failed the launch request.'**
  String get diagLockFailedException;

  /// No description provided for @diagLockShown.
  ///
  /// In en, this message translates to:
  /// **'Lock screen: visible and confirmed.'**
  String get diagLockShown;

  /// No description provided for @diagLockRequestedUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Lock screen: request returned; visibility is not confirmed yet.'**
  String get diagLockRequestedUnconfirmed;

  /// No description provided for @diagLockAttempted.
  ///
  /// In en, this message translates to:
  /// **'Lock screen: launch requested.'**
  String get diagLockAttempted;

  /// No description provided for @diagHomeRejected.
  ///
  /// In en, this message translates to:
  /// **'Home action: Android rejected the request.'**
  String get diagHomeRejected;

  /// No description provided for @diagHomeAccepted.
  ///
  /// In en, this message translates to:
  /// **'Home action: Android accepted the request.'**
  String get diagHomeAccepted;

  /// No description provided for @diagHomeAttempted.
  ///
  /// In en, this message translates to:
  /// **'Home action: requested.'**
  String get diagHomeAttempted;

  /// No description provided for @diagRestrictionOther.
  ///
  /// In en, this message translates to:
  /// **'Last restriction state could not be verified.'**
  String get diagRestrictionOther;

  /// No description provided for @diagRestrictionSkippedLaunchThrottled.
  ///
  /// In en, this message translates to:
  /// **'Restriction skipped: a lock-screen attempt is already in progress.'**
  String get diagRestrictionSkippedLaunchThrottled;

  /// No description provided for @diagRestrictionSkippedFreedomDisabled.
  ///
  /// In en, this message translates to:
  /// **'Restriction skipped: Freedom Control is off.'**
  String get diagRestrictionSkippedFreedomDisabled;

  /// No description provided for @diagRestrictionSkippedFreedomEarned.
  ///
  /// In en, this message translates to:
  /// **'Restriction skipped: Freedom is earned.'**
  String get diagRestrictionSkippedFreedomEarned;

  /// No description provided for @diagRestrictionSkippedStateChanged.
  ///
  /// In en, this message translates to:
  /// **'Restriction skipped: Freedom state changed while opening the app.'**
  String get diagRestrictionSkippedStateChanged;

  /// No description provided for @diagRestrictionRetryingStateChanged.
  ///
  /// In en, this message translates to:
  /// **'Freedom state changed during enforcement; checking it once more.'**
  String get diagRestrictionRetryingStateChanged;

  /// No description provided for @diagRestrictionSkippedLockAlreadyVisible.
  ///
  /// In en, this message translates to:
  /// **'Restriction skipped: a Daylock lock screen was already visible.'**
  String get diagRestrictionSkippedLockAlreadyVisible;

  /// No description provided for @diagRestrictionSkippedServiceInactive.
  ///
  /// In en, this message translates to:
  /// **'Restriction skipped: the Accessibility service was no longer active.'**
  String get diagRestrictionSkippedServiceInactive;

  /// No description provided for @diagRestrictionSkippedDeviceNotInteractive.
  ///
  /// In en, this message translates to:
  /// **'Restriction skipped: the device was locked or not interactive.'**
  String get diagRestrictionSkippedDeviceNotInteractive;

  /// No description provided for @diagRestrictionSkippedSelectionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Restriction skipped: the selected app could not be verified.'**
  String get diagRestrictionSkippedSelectionUnavailable;

  /// No description provided for @diagRestrictionSkippedAccessibilityDisabled.
  ///
  /// In en, this message translates to:
  /// **'Restriction skipped: Accessibility is no longer enabled.'**
  String get diagRestrictionSkippedAccessibilityDisabled;

  /// No description provided for @diagRestrictionSkippedForegroundChangedBeforeNavigation.
  ///
  /// In en, this message translates to:
  /// **'Restriction skipped: the foreground app changed before enforcement.'**
  String get diagRestrictionSkippedForegroundChangedBeforeNavigation;

  /// No description provided for @diagRestrictionHomeFailed.
  ///
  /// In en, this message translates to:
  /// **'Last attempt: Android rejected Home navigation. Restriction could not be applied.'**
  String get diagRestrictionHomeFailed;

  /// No description provided for @diagRestrictionLockLaunchUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Last attempt: lock screen was not confirmed. Android may restrict background launches.'**
  String get diagRestrictionLockLaunchUnconfirmed;

  /// No description provided for @diagRestrictionHomeOnly.
  ///
  /// In en, this message translates to:
  /// **'Last attempt: Home requested; lock screen was not confirmed.'**
  String get diagRestrictionHomeOnly;

  /// No description provided for @diagRestrictionLockFallbackUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Last attempt: lock screen not confirmed. Allow notifications and the App restriction notices channel in Android settings for fallback notices.'**
  String get diagRestrictionLockFallbackUnavailable;

  /// No description provided for @diagRestrictionLockFallbackPosted.
  ///
  /// In en, this message translates to:
  /// **'Last attempt: lock screen not confirmed; app restriction notification posted. Android controls its delivery.'**
  String get diagRestrictionLockFallbackPosted;

  /// No description provided for @diagRestrictionLockLaunchRequested.
  ///
  /// In en, this message translates to:
  /// **'Last attempt: lock screen requested; display not yet confirmed.'**
  String get diagRestrictionLockLaunchRequested;

  /// No description provided for @diagRestrictionStateUnknown.
  ///
  /// In en, this message translates to:
  /// **'Last attempt: selected apps allowed while Freedom state was unavailable.'**
  String get diagRestrictionStateUnknown;

  /// No description provided for @diagRestrictionLockShown.
  ///
  /// In en, this message translates to:
  /// **'Last restriction attempt: Daylock lock screen shown.'**
  String get diagRestrictionLockShown;

  /// No description provided for @diagRestrictionRecoveryShown.
  ///
  /// In en, this message translates to:
  /// **'Last attempt: recovery screen shown. Open Daylock to refresh plans or disable blocking.'**
  String get diagRestrictionRecoveryShown;

  /// No description provided for @diagRestrictionRestrictionRecovery.
  ///
  /// In en, this message translates to:
  /// **'Restriction needs Daylock to refresh Freedom state.'**
  String get diagRestrictionRestrictionRecovery;

  /// No description provided for @diagRestrictionRestrictionTriggered.
  ///
  /// In en, this message translates to:
  /// **'Restriction triggered: starting the Daylock lock flow.'**
  String get diagRestrictionRestrictionTriggered;

  /// No description provided for @diagRestrictionEligibilityUnknown.
  ///
  /// In en, this message translates to:
  /// **'Eligibility could not be confirmed; blocking is paused safely.'**
  String get diagRestrictionEligibilityUnknown;

  /// No description provided for @diagRestrictionEligibilityDisabled.
  ///
  /// In en, this message translates to:
  /// **'Eligibility evaluated: Freedom Control is off; the app is allowed.'**
  String get diagRestrictionEligibilityDisabled;

  /// No description provided for @diagRestrictionEligibilityEarned.
  ///
  /// In en, this message translates to:
  /// **'Eligibility evaluated: Freedom is earned; the app is allowed.'**
  String get diagRestrictionEligibilityEarned;

  /// No description provided for @diagRestrictionEligibilityNotEarned.
  ///
  /// In en, this message translates to:
  /// **'Eligibility evaluated: Freedom is not earned.'**
  String get diagRestrictionEligibilityNotEarned;

  /// No description provided for @diagRestrictionDetectedSelectedApp.
  ///
  /// In en, this message translates to:
  /// **'Selected app detected. Checking Freedom and restriction eligibility.'**
  String get diagRestrictionDetectedSelectedApp;

  /// No description provided for @diagRestrictionTestRequested.
  ///
  /// In en, this message translates to:
  /// **'Test requested: waiting for a fresh selected-app detection.'**
  String get diagRestrictionTestRequested;

  /// No description provided for @diagRestrictionSkippedEventDelayed.
  ///
  /// In en, this message translates to:
  /// **'Android delivered the app-opening event too late. On Xiaomi / HyperOS, review Daylock’s App info → Power → No restrictions, then test opening a selected app from Home.'**
  String get diagRestrictionSkippedEventDelayed;

  /// No description provided for @diagRestrictionNone.
  ///
  /// In en, this message translates to:
  /// **'No restriction attempt yet.'**
  String get diagRestrictionNone;

  /// No description provided for @diagEnableBlockingBody.
  ///
  /// In en, this message translates to:
  /// **'When Freedom Control is on and Freedom is not earned, Daylock uses Accessibility to leave a selected app and show its own lock screen. Installed-app lists and selections stay on this device. It does not read screen content or collect browsing history. Only the latest selected-app detection and restriction result stay on this device. Other window package names are compared only to cancel a pending action if you switch apps; they are not retained. You can turn blocking off here or revoke Accessibility access at any time.\n\nFreedom inputs stay valid for their calendar date without reopening Daylock. If current state is missing or invalid, Daylock offers a recovery screen with Open Daylock and Disable Blocking; subsequent openings are allowed while recovery is needed. This is a voluntary restriction, not a tamper-proof or parental-control system.'**
  String get diagEnableBlockingBody;

  /// No description provided for @diagPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Daylock uses Android Accessibility to detect when a selected app opens, including while Daylock is in the background. It saves only the latest selected-app detection, Freedom status and restriction result on this device; nothing is sent to a server. Installed-app lists and selections stay on this device. It does not read screen content or collect browsing history. With the separate app restrictions switch enabled, it can return Home and show a branded Daylock lock screen when Freedom is not earned. Window package changes are compared only to cancel actions if you switch apps; other app names are not retained. It does not draw overlays or restrict unselected apps.\n\nYou choose whether to enable “Daylock app restrictions” in Android Accessibility Settings. You can disable it there at any time.'**
  String get diagPermissionBody;

  /// No description provided for @diagPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'App restriction permission'**
  String get diagPermissionTitle;

  /// No description provided for @diagAgreeOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Agree and open Settings'**
  String get diagAgreeOpenSettings;

  /// No description provided for @diagEnableBlockingTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable app restrictions?'**
  String get diagEnableBlockingTitle;

  /// No description provided for @diagEnableBlocking.
  ///
  /// In en, this message translates to:
  /// **'Enable blocking'**
  String get diagEnableBlocking;

  /// No description provided for @diagAppRestrictionsLabel.
  ///
  /// In en, this message translates to:
  /// **'APP RESTRICTIONS'**
  String get diagAppRestrictionsLabel;

  /// No description provided for @diagAppRestrictionsIntro.
  ///
  /// In en, this message translates to:
  /// **'Accessibility detects selected apps opening in the background. Optional blocking shows a Daylock lock screen or returns Home until Freedom is earned. If the screen cannot appear, a notification explains the block when Android permits it.'**
  String get diagAppRestrictionsIntro;

  /// No description provided for @diagAppRestrictions.
  ///
  /// In en, this message translates to:
  /// **'App restrictions'**
  String get diagAppRestrictions;

  /// No description provided for @diagSeparateFromFreedom.
  ///
  /// In en, this message translates to:
  /// **'Separate from Freedom Control. Off by default.'**
  String get diagSeparateFromFreedom;

  /// No description provided for @diagStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'App restriction status unavailable'**
  String get diagStatusUnavailable;

  /// No description provided for @diagRestrictionsOff.
  ///
  /// In en, this message translates to:
  /// **'App restrictions: off'**
  String get diagRestrictionsOff;

  /// No description provided for @diagWaitingForAccessibility.
  ///
  /// In en, this message translates to:
  /// **'App restrictions: waiting for Accessibility access'**
  String get diagWaitingForAccessibility;

  /// No description provided for @diagAllowedFreedomOff.
  ///
  /// In en, this message translates to:
  /// **'Selected apps allowed — Freedom Control is off'**
  String get diagAllowedFreedomOff;

  /// No description provided for @diagAllowedFreedomEarned.
  ///
  /// In en, this message translates to:
  /// **'Selected apps allowed — Freedom earned'**
  String get diagAllowedFreedomEarned;

  /// No description provided for @diagBlockingPaused.
  ///
  /// In en, this message translates to:
  /// **'Blocking paused — open Daylock to refresh Freedom state'**
  String get diagBlockingPaused;

  /// No description provided for @diagRestrictionsReady.
  ///
  /// In en, this message translates to:
  /// **'App restrictions ready — launch and navigation depend on Android'**
  String get diagRestrictionsReady;

  /// No description provided for @diagServiceStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Service status unavailable'**
  String get diagServiceStatusUnavailable;

  /// No description provided for @diagAndroidOnly.
  ///
  /// In en, this message translates to:
  /// **'Native detection is available on Android only.'**
  String get diagAndroidOnly;

  /// No description provided for @diagServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Accessibility service: disabled'**
  String get diagServiceDisabled;

  /// No description provided for @diagServiceConnected.
  ///
  /// In en, this message translates to:
  /// **'Accessibility service: enabled and connected'**
  String get diagServiceConnected;

  /// No description provided for @diagServiceWaiting.
  ///
  /// In en, this message translates to:
  /// **'Accessibility service: enabled — waiting for Android to connect'**
  String get diagServiceWaiting;

  /// No description provided for @diagBlockingSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The blocking choice could not be saved. Disabling takes effect now, but may not survive a restart. Revoke Accessibility access if necessary.'**
  String get diagBlockingSaveFailed;

  /// No description provided for @diagNoDetectionYet.
  ///
  /// In en, this message translates to:
  /// **'No selected app has been detected yet.'**
  String get diagNoDetectionYet;

  /// No description provided for @diagLastDetection.
  ///
  /// In en, this message translates to:
  /// **'Last restricted-app detection: {when}'**
  String diagLastDetection(String when);

  /// No description provided for @diagFreedomAtDetection.
  ///
  /// In en, this message translates to:
  /// **'Freedom at that detection: {state}'**
  String diagFreedomAtDetection(String state);

  /// No description provided for @diagCurrentFreedom.
  ///
  /// In en, this message translates to:
  /// **'Current native Freedom state: {state}'**
  String diagCurrentFreedom(String state);

  /// No description provided for @diagFocusNeedsRefresh.
  ///
  /// In en, this message translates to:
  /// **'An active Focus session needs Daylock to reconcile its timer. Native detection does not mark it complete.'**
  String get diagFocusNeedsRefresh;

  /// No description provided for @diagStateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Current dated state is unavailable. Open Daylock to reconcile plans or turn blocking off. Valid current-day inputs do not expire after five minutes.'**
  String get diagStateUnavailable;

  /// No description provided for @diagRolloverReconciled.
  ///
  /// In en, this message translates to:
  /// **'New day: using the saved plan for this date. Open Daylock to archive history and prepare the following day.'**
  String get diagRolloverReconciled;

  /// No description provided for @diagNoEligible.
  ///
  /// In en, this message translates to:
  /// **'No eligible commitments. Empty or all-excused days do not earn Freedom.'**
  String get diagNoEligible;

  /// No description provided for @diagDetectionSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The latest detection could not be persisted and may not survive a restart.'**
  String get diagDetectionSaveFailed;

  /// No description provided for @diagTurnBlockingOff.
  ///
  /// In en, this message translates to:
  /// **'Turn blocking off'**
  String get diagTurnBlockingOff;

  /// No description provided for @diagSettingsPath.
  ///
  /// In en, this message translates to:
  /// **'Android Settings → Accessibility → Downloaded/Installed apps → Daylock app restrictions. Turn the service on manually. Names vary by phone.'**
  String get diagSettingsPath;

  /// No description provided for @diagRestrictedSettings.
  ///
  /// In en, this message translates to:
  /// **'If Android 15 shows “Restricted settings”, inspect Daylock’s App info for “Allow restricted settings” and confirm only for this development build you trust.'**
  String get diagRestrictedSettings;

  /// No description provided for @diagAvailableAndroidOnly.
  ///
  /// In en, this message translates to:
  /// **'Available on Android only'**
  String get diagAvailableAndroidOnly;

  /// No description provided for @diagServiceEnabledShort.
  ///
  /// In en, this message translates to:
  /// **'Accessibility service: enabled'**
  String get diagServiceEnabledShort;

  /// No description provided for @diagServiceDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Service disconnected'**
  String get diagServiceDisconnected;

  /// No description provided for @diagRestrictionsOn.
  ///
  /// In en, this message translates to:
  /// **'App restrictions: on'**
  String get diagRestrictionsOn;

  /// No description provided for @selectedAppsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 selected app} other{{count} selected apps}}'**
  String selectedAppsCount(int count);

  /// No description provided for @diagNativeFreedom.
  ///
  /// In en, this message translates to:
  /// **'Native Freedom: {state}'**
  String diagNativeFreedom(String state);

  /// No description provided for @diagTechnicalDetails.
  ///
  /// In en, this message translates to:
  /// **'Technical details & setup'**
  String get diagTechnicalDetails;

  /// No description provided for @diagLastPackage.
  ///
  /// In en, this message translates to:
  /// **'Last restricted package: {package}'**
  String diagLastPackage(String package);

  /// No description provided for @openAccessibilitySettings.
  ///
  /// In en, this message translates to:
  /// **'Open Accessibility Settings'**
  String get openAccessibilitySettings;

  /// No description provided for @refreshStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh status'**
  String get refreshStatus;

  /// No description provided for @appsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load installed apps. Your saved selections have not been replaced.'**
  String get appsLoadFailed;

  /// No description provided for @appsPausedAttention.
  ///
  /// In en, this message translates to:
  /// **'Restrictions paused: status needs attention.'**
  String get appsPausedAttention;

  /// No description provided for @appsRestrictionsOff.
  ///
  /// In en, this message translates to:
  /// **'App restrictions are off. Your selections are saved.'**
  String get appsRestrictionsOff;

  /// No description provided for @appsNoneSelected.
  ///
  /// In en, this message translates to:
  /// **'No apps selected. Nothing is restricted.'**
  String get appsNoneSelected;

  /// No description provided for @appsWaitingAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Accessibility access. Selected apps are not restricted.'**
  String get appsWaitingAccessibility;

  /// No description provided for @appsFreedomOff.
  ///
  /// In en, this message translates to:
  /// **'Freedom Control is off. Selected apps are accessible.'**
  String get appsFreedomOff;

  /// No description provided for @appsFreedomEarned.
  ///
  /// In en, this message translates to:
  /// **'Freedom earned. Selected apps are accessible.'**
  String get appsFreedomEarned;

  /// No description provided for @appsNeedsRefresh.
  ///
  /// In en, this message translates to:
  /// **'Freedom status needs a refresh. Recovery is available; repeated openings are allowed.'**
  String get appsNeedsRefresh;

  /// No description provided for @appsRestricted.
  ///
  /// In en, this message translates to:
  /// **'Selected apps are restricted until Freedom is earned.'**
  String get appsRestricted;

  /// No description provided for @selectedCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} SELECTED'**
  String selectedCountLabel(int count);

  /// No description provided for @refreshApps.
  ///
  /// In en, this message translates to:
  /// **'Refresh apps'**
  String get refreshApps;

  /// No description provided for @appsMasterControl.
  ///
  /// In en, this message translates to:
  /// **'Master control for all selected apps.'**
  String get appsMasterControl;

  /// No description provided for @appsMasterSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The master setting could not be saved. Turning it off applies now, but may not survive a restart.'**
  String get appsMasterSaveFailed;

  /// No description provided for @appsChooseBelow.
  ///
  /// In en, this message translates to:
  /// **'Choose apps below. Freedom Control and app restrictions are separate. System recovery apps are excluded.'**
  String get appsChooseBelow;

  /// No description provided for @appsRemoved.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unavailable or reinstalled app removed from selection. Select it again if needed.} other{{count} unavailable or reinstalled apps removed from selection. Select them again if needed.}}'**
  String appsRemoved(int count);

  /// No description provided for @appsNoneSelectedYet.
  ///
  /// In en, this message translates to:
  /// **'No apps selected yet. Choose the apps you want to restrict.'**
  String get appsNoneSelectedYet;

  /// No description provided for @searchApps.
  ///
  /// In en, this message translates to:
  /// **'Search apps'**
  String get searchApps;

  /// No description provided for @appsSelectionRequiresAndroid.
  ///
  /// In en, this message translates to:
  /// **'Installed-app selection requires Android.'**
  String get appsSelectionRequiresAndroid;

  /// No description provided for @retryAppDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Retry app discovery'**
  String get retryAppDiscovery;

  /// No description provided for @appsNoneFound.
  ///
  /// In en, this message translates to:
  /// **'No supported launchable apps were found in this Android profile.'**
  String get appsNoneFound;

  /// No description provided for @appsNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matching apps.'**
  String get appsNoMatches;

  /// No description provided for @appIconUnavailable.
  ///
  /// In en, this message translates to:
  /// **'App icon unavailable'**
  String get appIconUnavailable;

  /// No description provided for @savingSelection.
  ///
  /// In en, this message translates to:
  /// **'Saving selection…'**
  String get savingSelection;

  /// No description provided for @appsSelectionsStay.
  ///
  /// In en, this message translates to:
  /// **'Selections stay on this device. New or reinstalled apps must be selected explicitly.'**
  String get appsSelectionsStay;

  /// No description provided for @notifRunningStopwatchHelp.
  ///
  /// In en, this message translates to:
  /// **'Shows a quiet notification with Pause while a stopwatch runs, and nudges you every 2 hours so it isn’t left on by mistake.'**
  String get notifRunningStopwatchHelp;

  /// No description provided for @notifBlockedInSystem.
  ///
  /// In en, this message translates to:
  /// **'Blocked in Android system settings'**
  String get notifBlockedInSystem;

  /// No description provided for @notifLabel.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get notifLabel;

  /// No description provided for @notifPermissionAllowed.
  ///
  /// In en, this message translates to:
  /// **'System permission: allowed'**
  String get notifPermissionAllowed;

  /// No description provided for @notifPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'System permission: not allowed'**
  String get notifPermissionDenied;

  /// No description provided for @notifNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Notification setup needs attention'**
  String get notifNeedsAttention;

  /// No description provided for @notifChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking system permission…'**
  String get notifChecking;

  /// No description provided for @notifUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Scheduled notifications unavailable'**
  String get notifUnavailable;

  /// No description provided for @notifPermissionHelp.
  ///
  /// In en, this message translates to:
  /// **'Permission help'**
  String get notifPermissionHelp;

  /// No description provided for @notifOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open notification settings'**
  String get notifOpenSettings;

  /// No description provided for @notifPlanTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Plan Tomorrow'**
  String get notifPlanTomorrow;

  /// No description provided for @notifCommitmentReminder.
  ///
  /// In en, this message translates to:
  /// **'Commitment Reminder'**
  String get notifCommitmentReminder;

  /// No description provided for @notifFreedom.
  ///
  /// In en, this message translates to:
  /// **'Freedom Notifications'**
  String get notifFreedom;

  /// No description provided for @notifFreedomHelp.
  ///
  /// In en, this message translates to:
  /// **'Uses Freedom Time when Freedom Control is enabled.'**
  String get notifFreedomHelp;

  /// No description provided for @notifRunningStopwatch.
  ///
  /// In en, this message translates to:
  /// **'Running Stopwatch'**
  String get notifRunningStopwatch;

  /// No description provided for @healthXiaomiTip.
  ///
  /// In en, this message translates to:
  /// **'To stop it happening again on Xiaomi / Poco: in Daylock’s App info allow Autostart, set Battery saver to No restrictions, allow pop-ups while running in the background, and avoid swiping Daylock away in Recents.'**
  String get healthXiaomiTip;

  /// No description provided for @healthOffBody.
  ///
  /// In en, this message translates to:
  /// **'Accessibility access for Daylock is off, so your selected apps open freely. Turn it on to bring the lock back.'**
  String get healthOffBody;

  /// No description provided for @healthStoppedBody.
  ///
  /// In en, this message translates to:
  /// **'Android stopped Daylock in the background, so your selected apps open freely. In Accessibility, turn Daylock off and on again.'**
  String get healthStoppedBody;

  /// No description provided for @healthStoppedTitle.
  ///
  /// In en, this message translates to:
  /// **'App blocking has stopped'**
  String get healthStoppedTitle;

  /// No description provided for @openAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Open Accessibility'**
  String get openAccessibility;

  /// No description provided for @openAppInfo.
  ///
  /// In en, this message translates to:
  /// **'Open App info'**
  String get openAppInfo;

  /// No description provided for @conditionSatisfied.
  ///
  /// In en, this message translates to:
  /// **'Satisfied'**
  String get conditionSatisfied;

  /// No description provided for @conditionRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get conditionRemaining;

  /// No description provided for @freedomTimeAt.
  ///
  /// In en, this message translates to:
  /// **'Freedom Time · {time}'**
  String freedomTimeAt(String time);

  /// No description provided for @eligibleComplete.
  ///
  /// In en, this message translates to:
  /// **'{kept} / {total} eligible commitments complete'**
  String eligibleComplete(int kept, int total);

  /// No description provided for @noEligibleRequired.
  ///
  /// In en, this message translates to:
  /// **'No eligible commitments — completion is required to earn Freedom.'**
  String get noEligibleRequired;

  /// No description provided for @tomorrowPlanCommittedCondition.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow’s plan committed'**
  String get tomorrowPlanCommittedCondition;

  /// No description provided for @planDateMismatch.
  ///
  /// In en, this message translates to:
  /// **'Today’s plan does not match the current local date.'**
  String get planDateMismatch;

  /// No description provided for @availableAt.
  ///
  /// In en, this message translates to:
  /// **'Available at {time}'**
  String availableAt(String time);

  /// No description provided for @enableFreedomInSettings.
  ///
  /// In en, this message translates to:
  /// **'Enable Freedom Control in Settings.'**
  String get enableFreedomInSettings;

  /// No description provided for @pauseStopwatch.
  ///
  /// In en, this message translates to:
  /// **'Pause stopwatch'**
  String get pauseStopwatch;

  /// No description provided for @resumeStopwatch.
  ///
  /// In en, this message translates to:
  /// **'Resume stopwatch'**
  String get resumeStopwatch;

  /// No description provided for @startStopwatch.
  ///
  /// In en, this message translates to:
  /// **'Start stopwatch'**
  String get startStopwatch;

  /// No description provided for @keptLower.
  ///
  /// In en, this message translates to:
  /// **'kept'**
  String get keptLower;

  /// No description provided for @keepTask.
  ///
  /// In en, this message translates to:
  /// **'Keep {name}'**
  String keepTask(String name);

  /// No description provided for @recordedTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Recorded time'**
  String get recordedTimeLabel;

  /// No description provided for @calendarDayExcusedNeutral.
  ///
  /// In en, this message translates to:
  /// **'No eligible commitments, {count} excused, neutral'**
  String calendarDayExcusedNeutral(int count);

  /// No description provided for @calendarDayNeutral.
  ///
  /// In en, this message translates to:
  /// **'No commitments, neutral'**
  String get calendarDayNeutral;

  /// No description provided for @calendarDayUnrecorded.
  ///
  /// In en, this message translates to:
  /// **'No recorded commitments, neutral'**
  String get calendarDayUnrecorded;

  /// No description provided for @calendarDayProgress.
  ///
  /// In en, this message translates to:
  /// **'{kept} of {total} eligible commitments complete, {percent} percent, {excused} excused'**
  String calendarDayProgress(int kept, int total, int percent, int excused);

  /// No description provided for @calendarTodaySuffix.
  ///
  /// In en, this message translates to:
  /// **', Today'**
  String get calendarTodaySuffix;

  /// No description provided for @calendarDayValue.
  ///
  /// In en, this message translates to:
  /// **'{description}, {count} scheduled events'**
  String calendarDayValue(String description, int count);

  /// No description provided for @heatNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral: no eligible commitments, missing history or future date'**
  String get heatNeutral;

  /// No description provided for @heatZero.
  ///
  /// In en, this message translates to:
  /// **'Recorded commitments: 0 percent complete'**
  String get heatZero;

  /// No description provided for @heatLow.
  ///
  /// In en, this message translates to:
  /// **'More than 0 to 25 percent complete'**
  String get heatLow;

  /// No description provided for @heatMedium.
  ///
  /// In en, this message translates to:
  /// **'More than 25 to 50 percent complete'**
  String get heatMedium;

  /// No description provided for @heatHigh.
  ///
  /// In en, this message translates to:
  /// **'More than 50 to less than 100 percent complete'**
  String get heatHigh;

  /// No description provided for @heatComplete.
  ///
  /// In en, this message translates to:
  /// **'100 percent complete'**
  String get heatComplete;

  /// No description provided for @heatLess.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get heatLess;

  /// No description provided for @heatMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get heatMore;

  /// No description provided for @calTodayReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Today commitments, read-only. Manage commitments in Today.'**
  String get calTodayReadOnly;

  /// No description provided for @calHistoryReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Commitment history, read-only'**
  String get calHistoryReadOnly;

  /// No description provided for @calTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'TODAY’S COMMITMENTS'**
  String get calTodayLabel;

  /// No description provided for @calHistoryLabel.
  ///
  /// In en, this message translates to:
  /// **'COMMITMENT HISTORY'**
  String get calHistoryLabel;

  /// No description provided for @calNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No commitment history recorded.'**
  String get calNoHistory;

  /// No description provided for @calNoCommitmentsToday.
  ///
  /// In en, this message translates to:
  /// **'No commitments for today.'**
  String get calNoCommitmentsToday;

  /// No description provided for @calNeutralDay.
  ///
  /// In en, this message translates to:
  /// **'No commitments recorded. Neutral day.'**
  String get calNeutralDay;

  /// No description provided for @calCompletionLabel.
  ///
  /// In en, this message translates to:
  /// **'Commitment completion for selected date'**
  String get calCompletionLabel;

  /// No description provided for @calRecordedTime.
  ///
  /// In en, this message translates to:
  /// **'Recorded time: {duration}'**
  String calRecordedTime(String duration);

  /// No description provided for @calCommitmentOutcome.
  ///
  /// In en, this message translates to:
  /// **'Commitment · {outcome}'**
  String calCommitmentOutcome(String outcome);

  /// No description provided for @calReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String calReason(String reason);

  /// No description provided for @calReadOnlyCached.
  ///
  /// In en, this message translates to:
  /// **'Read-only cached event'**
  String get calReadOnlyCached;

  /// No description provided for @editNamed.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String editNamed(String name);

  /// No description provided for @deleteNamed.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}'**
  String deleteNamed(String name);

  /// No description provided for @deleteEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete event?'**
  String get deleteEventTitle;

  /// No description provided for @deleteEventBody.
  ///
  /// In en, this message translates to:
  /// **'Delete “{title}” from your schedule?'**
  String deleteEventBody(String title);

  /// No description provided for @calReadOnlyCachedShort.
  ///
  /// In en, this message translates to:
  /// **'Read-only · cached event'**
  String get calReadOnlyCachedShort;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @calendarAccounts.
  ///
  /// In en, this message translates to:
  /// **'Calendar accounts'**
  String get calendarAccounts;

  /// No description provided for @addEvent.
  ///
  /// In en, this message translates to:
  /// **'Add event'**
  String get addEvent;

  /// No description provided for @scheduleLabel.
  ///
  /// In en, this message translates to:
  /// **'SCHEDULE'**
  String get scheduleLabel;

  /// No description provided for @noEventsScheduled.
  ///
  /// In en, this message translates to:
  /// **'No events scheduled.'**
  String get noEventsScheduled;

  /// No description provided for @eventTimeFormat.
  ///
  /// In en, this message translates to:
  /// **'Use HH:mm (00:00–23:59).'**
  String get eventTimeFormat;

  /// No description provided for @eventEndAfterStart.
  ///
  /// In en, this message translates to:
  /// **'End must be after start.'**
  String get eventEndAfterStart;

  /// No description provided for @readOnlyEvent.
  ///
  /// In en, this message translates to:
  /// **'Read-only event'**
  String get readOnlyEvent;

  /// No description provided for @externalEventsReadOnly.
  ///
  /// In en, this message translates to:
  /// **'External events can only be changed in their calendar.'**
  String get externalEventsReadOnly;

  /// No description provided for @editEvent.
  ///
  /// In en, this message translates to:
  /// **'Edit event'**
  String get editEvent;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @enterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a title.'**
  String get enterTitle;

  /// No description provided for @startTimeOptional.
  ///
  /// In en, this message translates to:
  /// **'Start time (optional)'**
  String get startTimeOptional;

  /// No description provided for @endTimeOptional.
  ///
  /// In en, this message translates to:
  /// **'End time (optional)'**
  String get endTimeOptional;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @saveEvent.
  ///
  /// In en, this message translates to:
  /// **'Save event'**
  String get saveEvent;

  /// No description provided for @accountUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update this account. Cached events are still available. Try again or reconnect.'**
  String get accountUpdateFailed;

  /// No description provided for @disconnectAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect account?'**
  String get disconnectAccountTitle;

  /// No description provided for @disconnectAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} and its cached events from Daylock? Your external calendar will stay unchanged.'**
  String disconnectAccountBody(String name);

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @externalCalendarsReadOnly.
  ///
  /// In en, this message translates to:
  /// **'External calendars are read-only. Cached events are available offline.'**
  String get externalCalendarsReadOnly;

  /// No description provided for @providersDisabled.
  ///
  /// In en, this message translates to:
  /// **'Account sign-in is not available for the disabled providers in this version.'**
  String get providersDisabled;

  /// No description provided for @connectProvider.
  ///
  /// In en, this message translates to:
  /// **'Connect {provider}'**
  String connectProvider(String provider);

  /// No description provided for @noConnectedAccounts.
  ///
  /// In en, this message translates to:
  /// **'No connected accounts.'**
  String get noConnectedAccounts;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @reconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get reconnect;

  /// No description provided for @notSyncedYet.
  ///
  /// In en, this message translates to:
  /// **'Not synced yet'**
  String get notSyncedYet;

  /// No description provided for @lastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced {when}'**
  String lastSynced(String when);

  /// No description provided for @syncToLoad.
  ///
  /// In en, this message translates to:
  /// **'Sync to load this account’s calendars.'**
  String get syncToLoad;

  /// No description provided for @chooseMonth.
  ///
  /// In en, this message translates to:
  /// **'Choose month'**
  String get chooseMonth;

  /// No description provided for @previousYear.
  ///
  /// In en, this message translates to:
  /// **'Previous year'**
  String get previousYear;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @enterYear.
  ///
  /// In en, this message translates to:
  /// **'Enter a year from 1 to 9999.'**
  String get enterYear;

  /// No description provided for @nextYear.
  ///
  /// In en, this message translates to:
  /// **'Next year'**
  String get nextYear;

  /// No description provided for @showMonth.
  ///
  /// In en, this message translates to:
  /// **'Show month'**
  String get showMonth;

  /// No description provided for @commitment.
  ///
  /// In en, this message translates to:
  /// **'Commitment'**
  String get commitment;

  /// No description provided for @repeatsLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeats {rule}'**
  String repeatsLabel(String rule);

  /// No description provided for @areas.
  ///
  /// In en, this message translates to:
  /// **'Areas'**
  String get areas;

  /// No description provided for @areasIntro.
  ///
  /// In en, this message translates to:
  /// **'Give your commitments a home. Your default Area is used whenever no other Area is selected.'**
  String get areasIntro;

  /// No description provided for @createArea.
  ///
  /// In en, this message translates to:
  /// **'Create Area'**
  String get createArea;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archived;

  /// No description provided for @defaultAlwaysAvailable.
  ///
  /// In en, this message translates to:
  /// **'Default · Always available'**
  String get defaultAlwaysAvailable;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @archivingExplainer.
  ///
  /// In en, this message translates to:
  /// **'Archiving keeps existing commitments and history linked. New commitments use active Areas only.'**
  String get archivingExplainer;

  /// No description provided for @editArea.
  ///
  /// In en, this message translates to:
  /// **'Edit Area'**
  String get editArea;

  /// No description provided for @areaName.
  ///
  /// In en, this message translates to:
  /// **'Area name'**
  String get areaName;

  /// No description provided for @icon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get icon;

  /// No description provided for @colour.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get colour;

  /// No description provided for @saveArea.
  ///
  /// In en, this message translates to:
  /// **'Save Area'**
  String get saveArea;

  /// No description provided for @areaIconLife.
  ///
  /// In en, this message translates to:
  /// **'Life'**
  String get areaIconLife;

  /// No description provided for @areaColourLavender.
  ///
  /// In en, this message translates to:
  /// **'Lavender'**
  String get areaColourLavender;

  /// No description provided for @areaIconHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get areaIconHealth;

  /// No description provided for @areaIconWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get areaIconWork;

  /// No description provided for @areaIconLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get areaIconLearning;

  /// No description provided for @areaIconHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get areaIconHome;

  /// No description provided for @areaIconPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get areaIconPeople;

  /// No description provided for @areaIconCreative.
  ///
  /// In en, this message translates to:
  /// **'Creative'**
  String get areaIconCreative;

  /// No description provided for @areaIconFitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get areaIconFitness;

  /// No description provided for @areaColourBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get areaColourBlue;

  /// No description provided for @areaColourTeal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get areaColourTeal;

  /// No description provided for @areaColourGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get areaColourGreen;

  /// No description provided for @areaColourAmber.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get areaColourAmber;

  /// No description provided for @areaColourRose.
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get areaColourRose;

  /// No description provided for @newAchievement.
  ///
  /// In en, this message translates to:
  /// **'New achievement'**
  String get newAchievement;

  /// No description provided for @editAchievement.
  ///
  /// In en, this message translates to:
  /// **'Edit achievement'**
  String get editAchievement;

  /// No description provided for @achievementPrompt.
  ///
  /// In en, this message translates to:
  /// **'What are you proud of?'**
  String get achievementPrompt;

  /// No description provided for @achievementHint.
  ///
  /// In en, this message translates to:
  /// **'Passed my driving test'**
  String get achievementHint;

  /// No description provided for @achievementNotes.
  ///
  /// In en, this message translates to:
  /// **'A few words (optional)'**
  String get achievementNotes;

  /// No description provided for @linkToArea.
  ///
  /// In en, this message translates to:
  /// **'Link to an Area'**
  String get linkToArea;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @previousAreaUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The previous Area is unavailable. Choose an Area or remove the link.'**
  String get previousAreaUnavailable;

  /// No description provided for @saveAchievement.
  ///
  /// In en, this message translates to:
  /// **'Save achievement'**
  String get saveAchievement;

  /// No description provided for @illustrationLabel.
  ///
  /// In en, this message translates to:
  /// **'Illustration: {name}'**
  String illustrationLabel(String name);

  /// No description provided for @illustrationAutomaticLabel.
  ///
  /// In en, this message translates to:
  /// **'Illustration: Automatic · {name}'**
  String illustrationAutomaticLabel(String name);

  /// No description provided for @illustrationHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose a look, or let the title and Area suggest one.'**
  String get illustrationHelp;

  /// No description provided for @automatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get automatic;

  /// No description provided for @area.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get area;

  /// No description provided for @notifExplainAndroid.
  ///
  /// In en, this message translates to:
  /// **'Android reminders may be delayed by battery saving or Do Not Disturb. App preferences below are separate from system permission.'**
  String get notifExplainAndroid;

  /// No description provided for @notifExplainError.
  ///
  /// In en, this message translates to:
  /// **'Notifications could not be updated. Reopen Daylock to retry.'**
  String get notifExplainError;

  /// No description provided for @notifExplainDefault.
  ///
  /// In en, this message translates to:
  /// **'Scheduled notifications are available on Android.'**
  String get notifExplainDefault;

  /// No description provided for @notifExplainWebSupported.
  ///
  /// In en, this message translates to:
  /// **'This browser supports notifications, but scheduled reminders are unavailable here. Safari, closed tabs and installed PWAs cannot deliver these reminders without a push service. Use Daylock on Android for scheduled notifications.'**
  String get notifExplainWebSupported;

  /// No description provided for @notifExplainWebUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This browser cannot deliver Daylock notifications. Scheduled reminders are available in the Android app; web/PWA controls are disabled.'**
  String get notifExplainWebUnsupported;

  /// No description provided for @detectionReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read native detection status. Refresh or open Android Settings manually.'**
  String get detectionReadFailed;

  /// No description provided for @calFailAuthMicrosoft.
  ///
  /// In en, this message translates to:
  /// **'Microsoft calendar access needs renewed permission. Reconnect this account. Your organisation may require administrator approval. Cached events are still available.'**
  String get calFailAuthMicrosoft;

  /// No description provided for @calFailAuthGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google calendar permission has expired or was removed. Reconnect this account. Cached events are still available.'**
  String get calFailAuthGoogle;

  /// No description provided for @calFailConfigMicrosoft.
  ///
  /// In en, this message translates to:
  /// **'Microsoft sign-in is not configured correctly. Check the Entra client ID, native redirect URI and supported account types.'**
  String get calFailConfigMicrosoft;

  /// No description provided for @calFailConfigGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in is not configured correctly. Check the OAuth client ID, Android package and signing certificate.'**
  String get calFailConfigGoogle;

  /// No description provided for @calFailUnavailableMicrosoft.
  ///
  /// In en, this message translates to:
  /// **'Microsoft Calendar is unavailable. Check your connection and try again. Work accounts need an accessible Exchange mailbox. Cached events are still available.'**
  String get calFailUnavailableMicrosoft;

  /// No description provided for @calFailUnavailableGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google Calendar is unavailable. Check your connection and try syncing again. Cached events are still available.'**
  String get calFailUnavailableGoogle;

  /// No description provided for @calFailResponseMicrosoft.
  ///
  /// In en, this message translates to:
  /// **'Microsoft returned an incomplete or unsupported calendar response. Cached events are still available. Try again later.'**
  String get calFailResponseMicrosoft;

  /// No description provided for @calFailResponseGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google returned an incomplete or unsupported calendar response. Cached events are still available. Try again later.'**
  String get calFailResponseGoogle;

  /// No description provided for @calFailAdminConsent.
  ///
  /// In en, this message translates to:
  /// **'Your organisation requires administrator approval or restricts this sign-in. Contact your IT administrator. Cached events are still available.'**
  String get calFailAdminConsent;

  /// No description provided for @calFailAccountMismatch.
  ///
  /// In en, this message translates to:
  /// **'Select the same Microsoft account and organisation when reconnecting. Existing accounts and cached events have been kept.'**
  String get calFailAccountMismatch;

  /// No description provided for @channelPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan Tomorrow'**
  String get channelPlan;

  /// No description provided for @channelCommitments.
  ///
  /// In en, this message translates to:
  /// **'Commitment reminders'**
  String get channelCommitments;

  /// No description provided for @channelFreedom.
  ///
  /// In en, this message translates to:
  /// **'Freedom'**
  String get channelFreedom;

  /// No description provided for @channelFocus.
  ///
  /// In en, this message translates to:
  /// **'Running stopwatch'**
  String get channelFocus;

  /// No description provided for @selectionLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load or save restricted apps. Restrictions are paused. Refresh to retry.'**
  String get selectionLoadFailed;

  /// No description provided for @selectionSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'App selection could not be saved. Restrictions are paused. Refresh to retry.'**
  String get selectionSaveFailed;

  /// No description provided for @totalAchievements.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{achievement} other{achievements}}'**
  String totalAchievements(int count);

  /// No description provided for @breaksTitle.
  ///
  /// In en, this message translates to:
  /// **'Breaks'**
  String get breaksTitle;

  /// No description provided for @breaksIntro.
  ///
  /// In en, this message translates to:
  /// **'Taken from the lock screen in the last 30 days, with your reasons.'**
  String get breaksIntro;

  /// No description provided for @breakEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'{app} · {when}'**
  String breakEntryTitle(String app, String when);

  /// No description provided for @diagRestrictionSkippedBreakActive.
  ///
  /// In en, this message translates to:
  /// **'Restriction skipped: a 15-minute break is active.'**
  String get diagRestrictionSkippedBreakActive;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'de', 'en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

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
    Locale('en'),
    Locale('ru'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'AutoDoctor'**
  String get appTitle;

  /// Label for language settings
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Use the system language
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// Russian language name
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get russian;

  /// English language name
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Plan navigation tab label
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get navPlan;

  /// No description provided for @maintenancePlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Maintenance plan'**
  String get maintenancePlanTitle;

  /// No description provided for @navJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get navJournal;

  /// No description provided for @navAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get navAssistant;

  /// Condition / State navigation tab label
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get navState;

  /// No description provided for @navAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get navAnalytics;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @historyCompletenessBanner.
  ///
  /// In en, this message translates to:
  /// **'Service history is {percent}% complete. Refine — about 3 min'**
  String historyCompletenessBanner(int percent);

  /// No description provided for @historyCompletenessCta.
  ///
  /// In en, this message translates to:
  /// **'Refine history'**
  String get historyCompletenessCta;

  /// No description provided for @openState.
  ///
  /// In en, this message translates to:
  /// **'Open Condition'**
  String get openState;

  /// No description provided for @openAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Open analytics'**
  String get openAnalytics;

  /// No description provided for @stateTitle.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get stateTitle;

  /// No description provided for @stateNeedsData.
  ///
  /// In en, this message translates to:
  /// **'Needs data'**
  String get stateNeedsData;

  /// No description provided for @stateUsedPercent.
  ///
  /// In en, this message translates to:
  /// **'Used {percent}%'**
  String stateUsedPercent(int percent);

  /// No description provided for @stateWearRemaining.
  ///
  /// In en, this message translates to:
  /// **'Wear {wear}% · remaining {remaining}%'**
  String stateWearRemaining(int wear, int remaining);

  /// No description provided for @stateInspectionStatus.
  ///
  /// In en, this message translates to:
  /// **'Inspection status'**
  String get stateInspectionStatus;

  /// No description provided for @stateEmpty.
  ///
  /// In en, this message translates to:
  /// **'No condition items for this vehicle yet.'**
  String get stateEmpty;

  /// No description provided for @stateGate.
  ///
  /// In en, this message translates to:
  /// **'Condition tiles appear after you add a vehicle.'**
  String get stateGate;

  /// No description provided for @planNearestWork.
  ///
  /// In en, this message translates to:
  /// **'Next work'**
  String get planNearestWork;

  /// No description provided for @planRoadLabel.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get planRoadLabel;

  /// No description provided for @planRemainingList.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get planRemainingList;

  /// No description provided for @planAnalyticsStrip.
  ///
  /// In en, this message translates to:
  /// **'At a glance'**
  String get planAnalyticsStrip;

  /// No description provided for @planNearestCount.
  ///
  /// In en, this message translates to:
  /// **'Nearest: {count}'**
  String planNearestCount(int count);

  /// No description provided for @historySaveAndNext.
  ///
  /// In en, this message translates to:
  /// **'Save and continue'**
  String get historySaveAndNext;

  /// No description provided for @historyFinishLater.
  ///
  /// In en, this message translates to:
  /// **'Finish later'**
  String get historyFinishLater;

  /// No description provided for @historyNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get historyNever;

  /// No description provided for @historyAdditional.
  ///
  /// In en, this message translates to:
  /// **'Additional'**
  String get historyAdditional;

  /// No description provided for @historyWearToggle.
  ///
  /// In en, this message translates to:
  /// **'Enter wear / remaining'**
  String get historyWearToggle;

  /// No description provided for @historyRemainingPercent.
  ///
  /// In en, this message translates to:
  /// **'Remaining, %'**
  String get historyRemainingPercent;

  /// No description provided for @historyInstallDate.
  ///
  /// In en, this message translates to:
  /// **'Install date'**
  String get historyInstallDate;

  /// No description provided for @historyInstallMileage.
  ///
  /// In en, this message translates to:
  /// **'Install mileage, km'**
  String get historyInstallMileage;

  /// No description provided for @historyNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get historyNoteOptional;

  /// No description provided for @historyReplacementDate.
  ///
  /// In en, this message translates to:
  /// **'Replacement date'**
  String get historyReplacementDate;

  /// No description provided for @historyReplacementMileage.
  ///
  /// In en, this message translates to:
  /// **'Replacement mileage, km'**
  String get historyReplacementMileage;

  /// No description provided for @historyCheckDate.
  ///
  /// In en, this message translates to:
  /// **'Check date'**
  String get historyCheckDate;

  /// No description provided for @moreAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get moreAnalytics;

  /// No description provided for @moreAnalyticsDetail.
  ///
  /// In en, this message translates to:
  /// **'Confirmed amounts, categories, mileage'**
  String get moreAnalyticsDetail;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @understood.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get understood;

  /// No description provided for @example.
  ///
  /// In en, this message translates to:
  /// **'Example'**
  String get example;

  /// No description provided for @exampleSemantics.
  ///
  /// In en, this message translates to:
  /// **'Demonstration example'**
  String get exampleSemantics;

  /// No description provided for @previewNoCar.
  ///
  /// In en, this message translates to:
  /// **'Preview with no vehicle. {message}'**
  String previewNoCar(String message);

  /// No description provided for @previewGarageEmpty.
  ///
  /// In en, this message translates to:
  /// **'Preview · garage empty'**
  String get previewGarageEmpty;

  /// No description provided for @addVehicle.
  ///
  /// In en, this message translates to:
  /// **'Add vehicle'**
  String get addVehicle;

  /// No description provided for @previewUnavailableHint.
  ///
  /// In en, this message translates to:
  /// **'Example. Action unavailable without a vehicle'**
  String get previewUnavailableHint;

  /// No description provided for @demoEntry.
  ///
  /// In en, this message translates to:
  /// **'Demo · entry'**
  String get demoEntry;

  /// No description provided for @vehicleStatusNoCar.
  ///
  /// In en, this message translates to:
  /// **'Vehicle status · no car'**
  String get vehicleStatusNoCar;

  /// No description provided for @garageEmpty.
  ///
  /// In en, this message translates to:
  /// **'Garage is empty'**
  String get garageEmpty;

  /// No description provided for @addVehicleSemantics.
  ///
  /// In en, this message translates to:
  /// **'Add vehicle. Open setup'**
  String get addVehicleSemantics;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Notification history will appear after you add a vehicle.'**
  String get notificationsEmpty;

  /// No description provided for @notificationsForVehicle.
  ///
  /// In en, this message translates to:
  /// **'Notifications · {make} {model}'**
  String notificationsForVehicle(String make, String model);

  /// No description provided for @notificationsNoNew.
  ///
  /// In en, this message translates to:
  /// **'No new notifications'**
  String get notificationsNoNew;

  /// No description provided for @guestProfile.
  ///
  /// In en, this message translates to:
  /// **'Guest profile'**
  String get guestProfile;

  /// No description provided for @openGuestProfile.
  ///
  /// In en, this message translates to:
  /// **'Open guest profile'**
  String get openGuestProfile;

  /// No description provided for @guestProfileInitial.
  ///
  /// In en, this message translates to:
  /// **'G'**
  String get guestProfileInitial;

  /// No description provided for @guestProfileFuture.
  ///
  /// In en, this message translates to:
  /// **'Sign-in and synchronization will be available in later stages.'**
  String get guestProfileFuture;

  /// No description provided for @addEvent.
  ///
  /// In en, this message translates to:
  /// **'Add event'**
  String get addEvent;

  /// No description provided for @addEventJournalSemantics.
  ///
  /// In en, this message translates to:
  /// **'Add an event to the journal'**
  String get addEventJournalSemantics;

  /// No description provided for @quickAddTechnical.
  ///
  /// In en, this message translates to:
  /// **'Command menu · vehicle required'**
  String get quickAddTechnical;

  /// No description provided for @quickAddPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview of the next step. Select a vehicle to open the form and save an entry.'**
  String get quickAddPreview;

  /// No description provided for @quickAddFuel.
  ///
  /// In en, this message translates to:
  /// **'Refueling'**
  String get quickAddFuel;

  /// No description provided for @quickAddService.
  ///
  /// In en, this message translates to:
  /// **'Service or repair'**
  String get quickAddService;

  /// No description provided for @quickAddExpense.
  ///
  /// In en, this message translates to:
  /// **'Other expense'**
  String get quickAddExpense;

  /// No description provided for @quickAddMileage.
  ///
  /// In en, this message translates to:
  /// **'Update mileage'**
  String get quickAddMileage;

  /// No description provided for @unavailableWithoutVehicle.
  ///
  /// In en, this message translates to:
  /// **'{label}. Unavailable without a vehicle'**
  String unavailableWithoutVehicle(String label);

  /// No description provided for @addVehicleFirst.
  ///
  /// In en, this message translates to:
  /// **'Add a vehicle first'**
  String get addVehicleFirst;

  /// No description provided for @aiCentralTab.
  ///
  /// In en, this message translates to:
  /// **'AI, center tab'**
  String get aiCentralTab;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI assistant'**
  String get aiAssistant;

  /// No description provided for @cockpitDemo.
  ///
  /// In en, this message translates to:
  /// **'Cockpit module · demo mode'**
  String get cockpitDemo;

  /// No description provided for @planPreviewGate.
  ///
  /// In en, this message translates to:
  /// **'This is only a design preview. Your personal plan will appear after you add a vehicle.'**
  String get planPreviewGate;

  /// No description provided for @consumablesRailSemantics.
  ///
  /// In en, this message translates to:
  /// **'Consumables, demonstration vertical area with independent scrolling'**
  String get consumablesRailSemantics;

  /// No description provided for @timelineSemantics.
  ///
  /// In en, this message translates to:
  /// **'Detailed demonstration timeline with independent scrolling'**
  String get timelineSemantics;

  /// No description provided for @closeConsumablesBarrier.
  ///
  /// In en, this message translates to:
  /// **'Close consumables list'**
  String get closeConsumablesBarrier;

  /// No description provided for @consumables.
  ///
  /// In en, this message translates to:
  /// **'Consumables'**
  String get consumables;

  /// No description provided for @consumablesSheetSemantics.
  ///
  /// In en, this message translates to:
  /// **'Consumables. Modal panel. Demonstration list'**
  String get consumablesSheetSemantics;

  /// No description provided for @consumablesProjection.
  ///
  /// In en, this message translates to:
  /// **'Projection · demo / no car'**
  String get consumablesProjection;

  /// No description provided for @closeConsumables.
  ///
  /// In en, this message translates to:
  /// **'Close consumables panel'**
  String get closeConsumables;

  /// No description provided for @consumablesDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'The examples below do not relate to a real vehicle and are not recommendations.'**
  String get consumablesDisclaimer;

  /// No description provided for @selectedConsumable.
  ///
  /// In en, this message translates to:
  /// **'Selected consumable: {label}'**
  String selectedConsumable(String label);

  /// No description provided for @consumableRailSemantics.
  ///
  /// In en, this message translates to:
  /// **'{title}. {state}. Example without a vehicle. Open full list and details'**
  String consumableRailSemantics(String title, String state);

  /// No description provided for @consumableRowSemantics.
  ///
  /// In en, this message translates to:
  /// **'{title}. {state}'**
  String consumableRowSemantics(String title, String state);

  /// No description provided for @intervalFraction.
  ///
  /// In en, this message translates to:
  /// **'Demonstration share of the service interval used: {percent}%. This is not physical wear.'**
  String intervalFraction(int percent);

  /// No description provided for @conditionNoPercent.
  ///
  /// In en, this message translates to:
  /// **'{state}. Percentage and value are not shown.'**
  String conditionNoPercent(String state);

  /// No description provided for @oilTitle.
  ///
  /// In en, this message translates to:
  /// **'Engine oil'**
  String get oilTitle;

  /// No description provided for @oilState.
  ///
  /// In en, this message translates to:
  /// **'Warning: due soon'**
  String get oilState;

  /// No description provided for @oilDue.
  ///
  /// In en, this message translates to:
  /// **'Example: in 1,200 km or 2 months'**
  String get oilDue;

  /// No description provided for @intervalEarlierBasis.
  ///
  /// In en, this message translates to:
  /// **'Time and mileage interval; the earlier threshold applies.'**
  String get intervalEarlierBasis;

  /// No description provided for @manufacturerSource.
  ///
  /// In en, this message translates to:
  /// **'Example basis: verified manufacturer service schedule.'**
  String get manufacturerSource;

  /// No description provided for @triggerMileage.
  ///
  /// In en, this message translates to:
  /// **'Effective trigger: mileage'**
  String get triggerMileage;

  /// No description provided for @brakesTitle.
  ///
  /// In en, this message translates to:
  /// **'Brake pads'**
  String get brakesTitle;

  /// No description provided for @brakesState.
  ///
  /// In en, this message translates to:
  /// **'Inspection required, no measurement'**
  String get brakesState;

  /// No description provided for @brakesDue.
  ///
  /// In en, this message translates to:
  /// **'Next inspection: after adding a vehicle'**
  String get brakesDue;

  /// No description provided for @conditionBasis.
  ///
  /// In en, this message translates to:
  /// **'Condition-based item; no percentage is calculated without an actual measurement.'**
  String get conditionBasis;

  /// No description provided for @inspectionRuleSource.
  ///
  /// In en, this message translates to:
  /// **'Example basis: periodic inspection rule.'**
  String get inspectionRuleSource;

  /// No description provided for @triggerInspection.
  ///
  /// In en, this message translates to:
  /// **'Effective trigger: inspection'**
  String get triggerInspection;

  /// No description provided for @lastInspectionUnknown.
  ///
  /// In en, this message translates to:
  /// **'Last inspection: unknown'**
  String get lastInspectionUnknown;

  /// No description provided for @coolantTitle.
  ///
  /// In en, this message translates to:
  /// **'Coolant'**
  String get coolantTitle;

  /// No description provided for @coolantState.
  ///
  /// In en, this message translates to:
  /// **'Dangerously close to due'**
  String get coolantState;

  /// No description provided for @coolantDue.
  ///
  /// In en, this message translates to:
  /// **'Example: in 3 weeks or 600 km'**
  String get coolantDue;

  /// No description provided for @publishedRuleSource.
  ///
  /// In en, this message translates to:
  /// **'Example basis: published maintenance rule.'**
  String get publishedRuleSource;

  /// No description provided for @triggerTime.
  ///
  /// In en, this message translates to:
  /// **'Effective trigger: time'**
  String get triggerTime;

  /// No description provided for @airFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Air filter'**
  String get airFilterTitle;

  /// No description provided for @normalInterval.
  ///
  /// In en, this message translates to:
  /// **'Normal interval'**
  String get normalInterval;

  /// No description provided for @airFilterDue.
  ///
  /// In en, this message translates to:
  /// **'Example: in 7,500 km'**
  String get airFilterDue;

  /// No description provided for @verifiedMileageBasis.
  ///
  /// In en, this message translates to:
  /// **'Mileage share of a verified interval.'**
  String get verifiedMileageBasis;

  /// No description provided for @tiresTitle.
  ///
  /// In en, this message translates to:
  /// **'Tires'**
  String get tiresTitle;

  /// No description provided for @tiresState.
  ///
  /// In en, this message translates to:
  /// **'Inspection state unknown, no measurement'**
  String get tiresState;

  /// No description provided for @tiresDue.
  ///
  /// In en, this message translates to:
  /// **'Next inspection: date not calculated'**
  String get tiresDue;

  /// No description provided for @tiresBasis.
  ///
  /// In en, this message translates to:
  /// **'Condition-based item; physical wear is not calculated.'**
  String get tiresBasis;

  /// No description provided for @inspectionRecommendationSource.
  ///
  /// In en, this message translates to:
  /// **'Example basis: general inspection recommendation.'**
  String get inspectionRecommendationSource;

  /// No description provided for @triggerUnknown.
  ///
  /// In en, this message translates to:
  /// **'Effective trigger: unknown'**
  String get triggerUnknown;

  /// No description provided for @categoryMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Service and repair'**
  String get categoryMaintenance;

  /// No description provided for @categoryParts.
  ///
  /// In en, this message translates to:
  /// **'Parts'**
  String get categoryParts;

  /// No description provided for @categoryFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get categoryFuel;

  /// No description provided for @categoryInspection.
  ///
  /// In en, this message translates to:
  /// **'Inspection'**
  String get categoryInspection;

  /// No description provided for @categoryDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get categoryDocument;

  /// No description provided for @categoryMileage.
  ///
  /// In en, this message translates to:
  /// **'Mileage'**
  String get categoryMileage;

  /// No description provided for @categoryExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get categoryExpense;

  /// No description provided for @categoryReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get categoryReminder;

  /// No description provided for @indicatorVerified.
  ///
  /// In en, this message translates to:
  /// **'Source verified'**
  String get indicatorVerified;

  /// No description provided for @indicatorCost.
  ///
  /// In en, this message translates to:
  /// **'Has cost'**
  String get indicatorCost;

  /// No description provided for @indicatorGrouped.
  ///
  /// In en, this message translates to:
  /// **'Event group'**
  String get indicatorGrouped;

  /// No description provided for @indicatorForecast.
  ///
  /// In en, this message translates to:
  /// **'Estimated period'**
  String get indicatorForecast;

  /// No description provided for @indicatorUnknownHistory.
  ///
  /// In en, this message translates to:
  /// **'History unknown'**
  String get indicatorUnknownHistory;

  /// No description provided for @importanceInformation.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get importanceInformation;

  /// No description provided for @importanceRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Recommendation'**
  String get importanceRecommendation;

  /// No description provided for @importanceRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get importanceRequired;

  /// No description provided for @importanceCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical attention'**
  String get importanceCritical;

  /// No description provided for @importanceSemantics.
  ///
  /// In en, this message translates to:
  /// **'Importance: {label}'**
  String importanceSemantics(String label);

  /// No description provided for @eventCategorySemantics.
  ///
  /// In en, this message translates to:
  /// **'{event}. Category: {category}'**
  String eventCategorySemantics(String event, String category);

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @demoNotVehicleData.
  ///
  /// In en, this message translates to:
  /// **'Demonstration example, not vehicle data'**
  String get demoNotVehicleData;

  /// No description provided for @nowSemantics.
  ///
  /// In en, this message translates to:
  /// **'Now. Demonstration calculation point; actual mileage is unavailable'**
  String get nowSemantics;

  /// No description provided for @nowExample.
  ///
  /// In en, this message translates to:
  /// **'Now · example without an odometer reading'**
  String get nowExample;

  /// No description provided for @timelineFuelTime.
  ///
  /// In en, this message translates to:
  /// **'Example · July 14, 18:40'**
  String get timelineFuelTime;

  /// No description provided for @demoMileage84120.
  ///
  /// In en, this message translates to:
  /// **'84,120 km'**
  String get demoMileage84120;

  /// No description provided for @demoMileage83900.
  ///
  /// In en, this message translates to:
  /// **'83,900 km'**
  String get demoMileage83900;

  /// No description provided for @timelineFuelTitle.
  ///
  /// In en, this message translates to:
  /// **'Refueling'**
  String get timelineFuelTitle;

  /// No description provided for @timelineFuelDetail.
  ///
  /// In en, this message translates to:
  /// **'Demonstration of a grouped actual entry'**
  String get timelineFuelDetail;

  /// No description provided for @timelineServiceTime.
  ///
  /// In en, this message translates to:
  /// **'Example · July 10'**
  String get timelineServiceTime;

  /// No description provided for @timelineServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Scheduled service'**
  String get timelineServiceTitle;

  /// No description provided for @timelineServiceDetail.
  ///
  /// In en, this message translates to:
  /// **'Past event without future importance'**
  String get timelineServiceDetail;

  /// No description provided for @timelineExpenseTime.
  ///
  /// In en, this message translates to:
  /// **'Example · July 8'**
  String get timelineExpenseTime;

  /// No description provided for @timelineExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Other expense'**
  String get timelineExpenseTitle;

  /// No description provided for @timelineExpenseDetail.
  ///
  /// In en, this message translates to:
  /// **'Category shown as a separate primary emblem'**
  String get timelineExpenseDetail;

  /// No description provided for @timelineMileageTime.
  ///
  /// In en, this message translates to:
  /// **'Example · in about 9–12 months'**
  String get timelineMileageTime;

  /// No description provided for @timelineMileageTitle.
  ///
  /// In en, this message translates to:
  /// **'Mileage update estimate'**
  String get timelineMileageTitle;

  /// No description provided for @timelineMileageDetail.
  ///
  /// In en, this message translates to:
  /// **'Broad forecast, not an odometer reading'**
  String get timelineMileageDetail;

  /// No description provided for @statusEstimate.
  ///
  /// In en, this message translates to:
  /// **'Status: estimate'**
  String get statusEstimate;

  /// No description provided for @timelineBrakesTime.
  ///
  /// In en, this message translates to:
  /// **'Example · next month'**
  String get timelineBrakesTime;

  /// No description provided for @timelineBrakesTitle.
  ///
  /// In en, this message translates to:
  /// **'Brake system inspection'**
  String get timelineBrakesTitle;

  /// No description provided for @timelineBrakesDetail.
  ///
  /// In en, this message translates to:
  /// **'No measurement; physical inspection required'**
  String get timelineBrakesDetail;

  /// No description provided for @statusSoon.
  ///
  /// In en, this message translates to:
  /// **'Status: soon'**
  String get statusSoon;

  /// No description provided for @timelineFilterTime.
  ///
  /// In en, this message translates to:
  /// **'Example · by September 30'**
  String get timelineFilterTime;

  /// No description provided for @timelineFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace air filter'**
  String get timelineFilterTitle;

  /// No description provided for @timelineFilterDetail.
  ///
  /// In en, this message translates to:
  /// **'Scheduled example; personal due date not calculated'**
  String get timelineFilterDetail;

  /// No description provided for @mileageThreshold.
  ///
  /// In en, this message translates to:
  /// **'or at the mileage threshold'**
  String get mileageThreshold;

  /// No description provided for @statusCurrent.
  ///
  /// In en, this message translates to:
  /// **'Status: current'**
  String get statusCurrent;

  /// No description provided for @timelineDocumentTime.
  ///
  /// In en, this message translates to:
  /// **'Example · due date has passed'**
  String get timelineDocumentTime;

  /// No description provided for @timelineDocumentTitle.
  ///
  /// In en, this message translates to:
  /// **'Check required document'**
  String get timelineDocumentTitle;

  /// No description provided for @timelineDocumentDetail.
  ///
  /// In en, this message translates to:
  /// **'Overdue state is shown separately from importance'**
  String get timelineDocumentDetail;

  /// No description provided for @statusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Status: overdue'**
  String get statusOverdue;

  /// No description provided for @timelineReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Example · selected date'**
  String get timelineReminderTime;

  /// No description provided for @timelineReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal reminder'**
  String get timelineReminderTitle;

  /// No description provided for @timelineReminderDetail.
  ///
  /// In en, this message translates to:
  /// **'Created by the user and is not a service schedule'**
  String get timelineReminderDetail;

  /// No description provided for @statusPlanned.
  ///
  /// In en, this message translates to:
  /// **'Status: planned'**
  String get statusPlanned;

  /// No description provided for @journalGate.
  ///
  /// In en, this message translates to:
  /// **'The full timeline will appear after you add a vehicle and confirmed entries.'**
  String get journalGate;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get filterService;

  /// No description provided for @filterFuel.
  ///
  /// In en, this message translates to:
  /// **'Refueling'**
  String get filterFuel;

  /// No description provided for @filterOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get filterOther;

  /// No description provided for @journalDemoDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Only a muted example structure is shown below — this is not your vehicle history.'**
  String get journalDemoDisclaimer;

  /// No description provided for @journalServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Example · Service'**
  String get journalServiceTitle;

  /// No description provided for @journalServiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Confirmed work, date and mileage'**
  String get journalServiceSubtitle;

  /// No description provided for @journalFuelTitle.
  ///
  /// In en, this message translates to:
  /// **'Example · Refueling'**
  String get journalFuelTitle;

  /// No description provided for @journalFuelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Consumption and additional fuel data'**
  String get journalFuelSubtitle;

  /// No description provided for @journalExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Example · Other expense'**
  String get journalExpenseTitle;

  /// No description provided for @journalExpenseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Category, date and confirmed amount'**
  String get journalExpenseSubtitle;

  /// No description provided for @topicsExample.
  ///
  /// In en, this message translates to:
  /// **'Topics · example'**
  String get topicsExample;

  /// No description provided for @topicSuspension.
  ///
  /// In en, this message translates to:
  /// **'Suspension'**
  String get topicSuspension;

  /// No description provided for @topicPaint.
  ///
  /// In en, this message translates to:
  /// **'Paint'**
  String get topicPaint;

  /// No description provided for @topicElectronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get topicElectronics;

  /// No description provided for @assistantGate.
  ///
  /// In en, this message translates to:
  /// **'AI uses vehicle data. Add a vehicle first.'**
  String get assistantGate;

  /// No description provided for @topics.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get topics;

  /// No description provided for @chatQuestion.
  ///
  /// In en, this message translates to:
  /// **'What should I check first, and how urgently should I visit a service center?'**
  String get chatQuestion;

  /// No description provided for @chatAnswer.
  ///
  /// In en, this message translates to:
  /// **'An answer based on this vehicle\'s history will appear here.'**
  String get chatAnswer;

  /// No description provided for @messageFieldUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Message field unavailable. Add a vehicle first'**
  String get messageFieldUnavailable;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @sendingDisabled.
  ///
  /// In en, this message translates to:
  /// **'Sending is disabled: no vehicle selected.'**
  String get sendingDisabled;

  /// No description provided for @selectedVehicleContext.
  ///
  /// In en, this message translates to:
  /// **'Selected vehicle · {make} {model}'**
  String selectedVehicleContext(String make, String model);

  /// No description provided for @aiUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The AI assistant is not connected yet'**
  String get aiUnavailable;

  /// No description provided for @aiAvailableAfterConnection.
  ///
  /// In en, this message translates to:
  /// **'Available after AI is connected'**
  String get aiAvailableAfterConnection;

  /// No description provided for @aiTopicsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Topics will be available after the AI assistant is connected.'**
  String get aiTopicsUnavailable;

  /// No description provided for @journalLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading service records…'**
  String get journalLoading;

  /// No description provided for @journalLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load service records.'**
  String get journalLoadError;

  /// No description provided for @journalForVehicle.
  ///
  /// In en, this message translates to:
  /// **'Journal · {make} {model}'**
  String journalForVehicle(String make, String model);

  /// No description provided for @analyticsForVehicle.
  ///
  /// In en, this message translates to:
  /// **'Analytics · {make} {model}'**
  String analyticsForVehicle(String make, String model);

  /// No description provided for @analyticsPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing analytics from confirmed records…'**
  String get analyticsPreparing;

  /// No description provided for @analyticsNoData.
  ///
  /// In en, this message translates to:
  /// **'There are no confirmed records for analytics yet.'**
  String get analyticsNoData;

  /// No description provided for @analyticsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load analytics data.'**
  String get analyticsLoadError;

  /// No description provided for @consumablesRedirecting.
  ///
  /// In en, this message translates to:
  /// **'Opening the current plan and consumables for the selected vehicle…'**
  String get consumablesRedirecting;

  /// No description provided for @analyticsGate.
  ///
  /// In en, this message translates to:
  /// **'Analytics will appear after you add a vehicle and confirmed entries.'**
  String get analyticsGate;

  /// No description provided for @analyticsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Only confirmed data will appear here. Amounts, charts, and conclusions are not calculated yet.'**
  String get analyticsEmpty;

  /// No description provided for @confirmedAmounts.
  ///
  /// In en, this message translates to:
  /// **'Confirmed amounts'**
  String get confirmedAmounts;

  /// No description provided for @currentMonthYear.
  ///
  /// In en, this message translates to:
  /// **'For the current month and year'**
  String get currentMonthYear;

  /// No description provided for @expenseCategories.
  ///
  /// In en, this message translates to:
  /// **'Expense categories'**
  String get expenseCategories;

  /// No description provided for @confirmedDistribution.
  ///
  /// In en, this message translates to:
  /// **'Distribution of confirmed entries'**
  String get confirmedDistribution;

  /// No description provided for @confirmedMileage.
  ///
  /// In en, this message translates to:
  /// **'Confirmed mileage'**
  String get confirmedMileage;

  /// No description provided for @odometerDynamics.
  ///
  /// In en, this message translates to:
  /// **'Dynamics based on saved odometer readings'**
  String get odometerDynamics;

  /// No description provided for @fuelConsumptionFuture.
  ///
  /// In en, this message translates to:
  /// **'Fuel consumption will appear only when enough high-quality data is available.'**
  String get fuelConsumptionFuture;

  /// No description provided for @structureWithoutData.
  ///
  /// In en, this message translates to:
  /// **'{title}. {detail}. Structure without data'**
  String structureWithoutData(String title, String detail);

  /// No description provided for @allConsumables.
  ///
  /// In en, this message translates to:
  /// **'All consumables'**
  String get allConsumables;

  /// No description provided for @allConsumablesGate.
  ///
  /// In en, this message translates to:
  /// **'The full list is based on a verified schedule, plan, and history of a specific vehicle.'**
  String get allConsumablesGate;

  /// No description provided for @oilFilters.
  ///
  /// In en, this message translates to:
  /// **'Oil and filters'**
  String get oilFilters;

  /// No description provided for @oilFiltersDetail.
  ///
  /// In en, this message translates to:
  /// **'Interval item: time and mileage progress are shown separately; the earlier threshold applies.'**
  String get oilFiltersDetail;

  /// No description provided for @technicalFluids.
  ///
  /// In en, this message translates to:
  /// **'Technical fluids'**
  String get technicalFluids;

  /// No description provided for @technicalFluidsDetail.
  ///
  /// In en, this message translates to:
  /// **'An interval item appears only when an applicable verified rule exists.'**
  String get technicalFluidsDetail;

  /// No description provided for @brakesDetail.
  ///
  /// In en, this message translates to:
  /// **'Condition-based: last check, measurement when available, and next inspection.'**
  String get brakesDetail;

  /// No description provided for @tiresDetail.
  ///
  /// In en, this message translates to:
  /// **'Condition-based: without an invented wear percentage or physical remaining life.'**
  String get tiresDetail;

  /// No description provided for @demoConsumableHint.
  ///
  /// In en, this message translates to:
  /// **'Demonstration consumable, not vehicle data'**
  String get demoConsumableHint;

  /// No description provided for @demoTechnicalRail.
  ///
  /// In en, this message translates to:
  /// **'Example · technical rail'**
  String get demoTechnicalRail;

  /// No description provided for @moreGate.
  ///
  /// In en, this message translates to:
  /// **'Settings are available for preview. Vehicle functions are disabled.'**
  String get moreGate;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App settings'**
  String get appSettings;

  /// No description provided for @unitsThemeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Units, theme, and language'**
  String get unitsThemeLanguage;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @feedbackDetail.
  ///
  /// In en, this message translates to:
  /// **'Report a problem or idea'**
  String get feedbackDetail;

  /// No description provided for @vehicleReminders.
  ///
  /// In en, this message translates to:
  /// **'Vehicle reminders'**
  String get vehicleReminders;

  /// No description provided for @controlChannel.
  ///
  /// In en, this message translates to:
  /// **'Control channel'**
  String get controlChannel;

  /// No description provided for @localPreviewFuture.
  ///
  /// In en, this message translates to:
  /// **'Local preview. Integration will be available later.'**
  String get localPreviewFuture;

  /// No description provided for @languagePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languagePickerTitle;

  /// No description provided for @selectedLanguage.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selectedLanguage;

  /// No description provided for @garageSetupStep1.
  ///
  /// In en, this message translates to:
  /// **'Garage setup · step 01'**
  String get garageSetupStep1;

  /// No description provided for @secureInitializing.
  ///
  /// In en, this message translates to:
  /// **'Secure channel · initializing'**
  String get secureInitializing;

  /// No description provided for @preparingSecureSetup.
  ///
  /// In en, this message translates to:
  /// **'Preparing secure vehicle setup…'**
  String get preparingSecureSetup;

  /// No description provided for @consentProtocol.
  ///
  /// In en, this message translates to:
  /// **'Consent protocol · step 01 / 02'**
  String get consentProtocol;

  /// No description provided for @consents.
  ///
  /// In en, this message translates to:
  /// **'Consents'**
  String get consents;

  /// No description provided for @consentsIntro.
  ///
  /// In en, this message translates to:
  /// **'To continue, accept the required consent. Analytics is optional and does not affect core features.'**
  String get consentsIntro;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version: {version}'**
  String versionLabel(String version);

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @connectionFault.
  ///
  /// In en, this message translates to:
  /// **'Connection fault'**
  String get connectionFault;

  /// No description provided for @bootstrapUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unable to prepare vehicle setup.'**
  String get bootstrapUnavailable;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Unable to contact the server. Check your connection.'**
  String get networkError;

  /// No description provided for @unexpectedResponse.
  ///
  /// In en, this message translates to:
  /// **'The server returned an unexpected response.'**
  String get unexpectedResponse;

  /// No description provided for @requestIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Request ID: {requestId}'**
  String requestIdLabel(String requestId);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @garageSetupStep2.
  ///
  /// In en, this message translates to:
  /// **'Garage setup · step 02'**
  String get garageSetupStep2;

  /// No description provided for @vinEntry.
  ///
  /// In en, this message translates to:
  /// **'VIN entry'**
  String get vinEntry;

  /// No description provided for @vinInterfaceOffline.
  ///
  /// In en, this message translates to:
  /// **'VIN interface · offline'**
  String get vinInterfaceOffline;

  /// No description provided for @addStage.
  ///
  /// In en, this message translates to:
  /// **'Setup stage'**
  String get addStage;

  /// No description provided for @stepTwoOfTwo.
  ///
  /// In en, this message translates to:
  /// **'02 / 02'**
  String get stepTwoOfTwo;

  /// No description provided for @nextStage.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get nextStage;

  /// No description provided for @vinStubDetail.
  ///
  /// In en, this message translates to:
  /// **'Consents have been saved.'**
  String get vinStubDetail;

  /// No description provided for @vehicleDetailsStep.
  ///
  /// In en, this message translates to:
  /// **'Garage setup · vehicle data'**
  String get vehicleDetailsStep;

  /// No description provided for @vehicleDetails.
  ///
  /// In en, this message translates to:
  /// **'Vehicle details'**
  String get vehicleDetails;

  /// No description provided for @vin.
  ///
  /// In en, this message translates to:
  /// **'VIN'**
  String get vin;

  /// No description provided for @vinValidation.
  ///
  /// In en, this message translates to:
  /// **'Enter a 17-character VIN without I, O, or Q.'**
  String get vinValidation;

  /// No description provided for @vinOptionalHelper.
  ///
  /// In en, this message translates to:
  /// **'Without a VIN, automatic data collection and precise configuration identification will not be available in the future.'**
  String get vinOptionalHelper;

  /// No description provided for @collectVinData.
  ///
  /// In en, this message translates to:
  /// **'Collect data by VIN'**
  String get collectVinData;

  /// No description provided for @vinProviderTitle.
  ///
  /// In en, this message translates to:
  /// **'VIN data'**
  String get vinProviderTitle;

  /// No description provided for @vinProviderInfo.
  ///
  /// In en, this message translates to:
  /// **'The VIN provider is not connected yet. Enter and confirm the data manually — the app will not add invented details.'**
  String get vinProviderInfo;

  /// No description provided for @continueManually.
  ///
  /// In en, this message translates to:
  /// **'Continue manually'**
  String get continueManually;

  /// No description provided for @vehicleMake.
  ///
  /// In en, this message translates to:
  /// **'Make'**
  String get vehicleMake;

  /// No description provided for @vehicleMakeOther.
  ///
  /// In en, this message translates to:
  /// **'Enter make'**
  String get vehicleMakeOther;

  /// No description provided for @vehicleModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get vehicleModel;

  /// No description provided for @vehicleModelOther.
  ///
  /// In en, this message translates to:
  /// **'Enter model'**
  String get vehicleModelOther;

  /// No description provided for @otherModel.
  ///
  /// In en, this message translates to:
  /// **'Other model'**
  String get otherModel;

  /// No description provided for @productionYear.
  ///
  /// In en, this message translates to:
  /// **'Production year'**
  String get productionYear;

  /// No description provided for @mileageKm.
  ///
  /// In en, this message translates to:
  /// **'Mileage, km'**
  String get mileageKm;

  /// No description provided for @fuelType.
  ///
  /// In en, this message translates to:
  /// **'Fuel type'**
  String get fuelType;

  /// No description provided for @engineDisplacement.
  ///
  /// In en, this message translates to:
  /// **'Engine displacement, cc'**
  String get engineDisplacement;

  /// No description provided for @transmissionType.
  ///
  /// In en, this message translates to:
  /// **'Transmission type'**
  String get transmissionType;

  /// No description provided for @transmissionGears.
  ///
  /// In en, this message translates to:
  /// **'Number of gears'**
  String get transmissionGears;

  /// No description provided for @moreVehicleDetails.
  ///
  /// In en, this message translates to:
  /// **'More details'**
  String get moreVehicleDetails;

  /// No description provided for @optionalDetailsAccuracy.
  ///
  /// In en, this message translates to:
  /// **'More detail improves recommendation accuracy. Specific OEM recommendations still require a verified configuration.'**
  String get optionalDetailsAccuracy;

  /// No description provided for @generation.
  ///
  /// In en, this message translates to:
  /// **'Generation'**
  String get generation;

  /// No description provided for @engineCode.
  ///
  /// In en, this message translates to:
  /// **'Engine code'**
  String get engineCode;

  /// No description provided for @powerKw.
  ///
  /// In en, this message translates to:
  /// **'Power, kW'**
  String get powerKw;

  /// No description provided for @drivetrain.
  ///
  /// In en, this message translates to:
  /// **'Drivetrain'**
  String get drivetrain;

  /// No description provided for @market.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get market;

  /// No description provided for @firstUseDate.
  ///
  /// In en, this message translates to:
  /// **'First use date'**
  String get firstUseDate;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @reviewVehicle.
  ///
  /// In en, this message translates to:
  /// **'Review details'**
  String get reviewVehicle;

  /// No description provided for @requiredTextValidation.
  ///
  /// In en, this message translates to:
  /// **'Required, up to 100 characters.'**
  String get requiredTextValidation;

  /// No description provided for @max100Validation.
  ///
  /// In en, this message translates to:
  /// **'Up to 100 characters.'**
  String get max100Validation;

  /// No description provided for @yearValidation.
  ///
  /// In en, this message translates to:
  /// **'Enter a year from 1886 to 2100.'**
  String get yearValidation;

  /// No description provided for @nonNegativeValidation.
  ///
  /// In en, this message translates to:
  /// **'Enter a non-negative whole number.'**
  String get nonNegativeValidation;

  /// No description provided for @displacementValidation.
  ///
  /// In en, this message translates to:
  /// **'Enter a value from 1 to 20,000.'**
  String get displacementValidation;

  /// No description provided for @gearsValidation.
  ///
  /// In en, this message translates to:
  /// **'Enter 1 to 12 gears.'**
  String get gearsValidation;

  /// No description provided for @powerValidation.
  ///
  /// In en, this message translates to:
  /// **'Enter a value above 0 and no more than 2000.'**
  String get powerValidation;

  /// No description provided for @selectValueValidation.
  ///
  /// In en, this message translates to:
  /// **'Select a value.'**
  String get selectValueValidation;

  /// No description provided for @fuelPetrol.
  ///
  /// In en, this message translates to:
  /// **'Petrol'**
  String get fuelPetrol;

  /// No description provided for @fuelDiesel.
  ///
  /// In en, this message translates to:
  /// **'Diesel'**
  String get fuelDiesel;

  /// No description provided for @fuelHybrid.
  ///
  /// In en, this message translates to:
  /// **'Hybrid'**
  String get fuelHybrid;

  /// No description provided for @fuelElectric.
  ///
  /// In en, this message translates to:
  /// **'Electric'**
  String get fuelElectric;

  /// No description provided for @fuelLpg.
  ///
  /// In en, this message translates to:
  /// **'LPG'**
  String get fuelLpg;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @transmissionManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get transmissionManual;

  /// No description provided for @transmissionAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get transmissionAutomatic;

  /// No description provided for @transmissionCvt.
  ///
  /// In en, this message translates to:
  /// **'CVT'**
  String get transmissionCvt;

  /// No description provided for @transmissionRobotized.
  ///
  /// In en, this message translates to:
  /// **'Robotized'**
  String get transmissionRobotized;

  /// No description provided for @drivetrainFwd.
  ///
  /// In en, this message translates to:
  /// **'Front-wheel drive'**
  String get drivetrainFwd;

  /// No description provided for @drivetrainRwd.
  ///
  /// In en, this message translates to:
  /// **'Rear-wheel drive'**
  String get drivetrainRwd;

  /// No description provided for @drivetrainAwd.
  ///
  /// In en, this message translates to:
  /// **'All-wheel drive'**
  String get drivetrainAwd;

  /// No description provided for @drivetrainFourWd.
  ///
  /// In en, this message translates to:
  /// **'Four-wheel drive'**
  String get drivetrainFourWd;

  /// No description provided for @confirmVehicleStep.
  ///
  /// In en, this message translates to:
  /// **'Garage setup · confirmation'**
  String get confirmVehicleStep;

  /// No description provided for @confirmVehicleTitle.
  ///
  /// In en, this message translates to:
  /// **'Review your vehicle'**
  String get confirmVehicleTitle;

  /// No description provided for @vehicleIdentitySection.
  ///
  /// In en, this message translates to:
  /// **'Identification'**
  String get vehicleIdentitySection;

  /// No description provided for @vehicleTechnicalSection.
  ///
  /// In en, this message translates to:
  /// **'Technical details'**
  String get vehicleTechnicalSection;

  /// No description provided for @vehicleAdditionalSection.
  ///
  /// In en, this message translates to:
  /// **'Additional details'**
  String get vehicleAdditionalSection;

  /// No description provided for @dataSource.
  ///
  /// In en, this message translates to:
  /// **'Data source'**
  String get dataSource;

  /// No description provided for @dataSourceUser.
  ///
  /// In en, this message translates to:
  /// **'Entered and confirmed by the user'**
  String get dataSourceUser;

  /// No description provided for @vehicleCreateError.
  ///
  /// In en, this message translates to:
  /// **'Unable to create the vehicle profile.'**
  String get vehicleCreateError;

  /// No description provided for @vehicleConflictHelp.
  ///
  /// In en, this message translates to:
  /// **'Review the data or return to editing. The profile may already exist or the limit may have been reached.'**
  String get vehicleConflictHelp;

  /// No description provided for @editVehicle.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get editVehicle;

  /// No description provided for @createVehicle.
  ///
  /// In en, this message translates to:
  /// **'Create profile'**
  String get createVehicle;

  /// No description provided for @firstPlanStep.
  ///
  /// In en, this message translates to:
  /// **'Vehicle profile · ready'**
  String get firstPlanStep;

  /// No description provided for @firstPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Preparing plan'**
  String get firstPlanTitle;

  /// No description provided for @firstPlanPreparing.
  ///
  /// In en, this message translates to:
  /// **'{make} {model}: profile created'**
  String firstPlanPreparing(String make, String model);

  /// No description provided for @firstPlanHonestStatus.
  ///
  /// In en, this message translates to:
  /// **'The plan is being prepared. Specific schedules and dates will appear only after applicable data is available.'**
  String get firstPlanHonestStatus;

  /// No description provided for @openPlan.
  ///
  /// In en, this message translates to:
  /// **'Go to plan'**
  String get openPlan;

  /// No description provided for @vehicleStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active vehicle'**
  String get vehicleStatusActive;

  /// No description provided for @openVehicleProfile.
  ///
  /// In en, this message translates to:
  /// **'Open vehicle profile summary'**
  String get openVehicleProfile;

  /// No description provided for @vehicleProfileBasicSummary.
  ///
  /// In en, this message translates to:
  /// **'Vehicle profile'**
  String get vehicleProfileBasicSummary;

  /// No description provided for @vehicleMileageSummary.
  ///
  /// In en, this message translates to:
  /// **'Mileage: {mileage} {unit}.'**
  String vehicleMileageSummary(int mileage, String unit);

  /// No description provided for @profileCreatedPlanPreparing.
  ///
  /// In en, this message translates to:
  /// **'{make} {model}: profile created · plan is being prepared. The timeline below is an illustrative preview.'**
  String profileCreatedPlanPreparing(String make, String model);

  /// No description provided for @featurePreparingForVehicle.
  ///
  /// In en, this message translates to:
  /// **'The vehicle profile has been created. This feature is still being prepared.'**
  String get featurePreparingForVehicle;

  /// No description provided for @loadingRealPlan.
  ///
  /// In en, this message translates to:
  /// **'Loading the real plan for {vehicle}'**
  String loadingRealPlan(String vehicle);

  /// No description provided for @planNotReadyYet.
  ///
  /// In en, this message translates to:
  /// **'The plan is marked ready only after a successful server response.'**
  String get planNotReadyYet;

  /// No description provided for @vehicleMaintenancePlan.
  ///
  /// In en, this message translates to:
  /// **'Maintenance plan · {vehicle}'**
  String vehicleMaintenancePlan(String vehicle);

  /// No description provided for @planItemsCount.
  ///
  /// In en, this message translates to:
  /// **'Maintenance items: {count}'**
  String planItemsCount(int count);

  /// No description provided for @editorialNotManufacturer.
  ///
  /// In en, this message translates to:
  /// **'AutoDoctor editorial methodology · not a manufacturer schedule'**
  String get editorialNotManufacturer;

  /// No description provided for @sourceEditorialBaseline.
  ///
  /// In en, this message translates to:
  /// **'Editorial baseline, not OEM'**
  String get sourceEditorialBaseline;

  /// No description provided for @sourceOfficialOem.
  ///
  /// In en, this message translates to:
  /// **'Official manufacturer source'**
  String get sourceOfficialOem;

  /// No description provided for @sourceRegulatory.
  ///
  /// In en, this message translates to:
  /// **'Regulatory source'**
  String get sourceRegulatory;

  /// No description provided for @unknownValue.
  ///
  /// In en, this message translates to:
  /// **'Unknown value'**
  String get unknownValue;

  /// No description provided for @warningEditorialBaseline.
  ///
  /// In en, this message translates to:
  /// **'The plan uses the AutoDoctor editorial baseline, not a manufacturer schedule.'**
  String get warningEditorialBaseline;

  /// No description provided for @warningHistoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Service history is missing, so due dates and overdue status are not calculated.'**
  String get warningHistoryRequired;

  /// No description provided for @warningMileageMissing.
  ///
  /// In en, this message translates to:
  /// **'Mileage is missing, so mileage-based recommendations cannot be refined.'**
  String get warningMileageMissing;

  /// No description provided for @warningUnknown.
  ///
  /// In en, this message translates to:
  /// **'The server returned an additional warning.'**
  String get warningUnknown;

  /// No description provided for @planPreparingError.
  ///
  /// In en, this message translates to:
  /// **'The server is still preparing the plan. The vehicle is saved — retry the request.'**
  String get planPreparingError;

  /// No description provided for @planLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load the maintenance plan.'**
  String get planLoadError;

  /// No description provided for @roadmapEmpty.
  ///
  /// In en, this message translates to:
  /// **'There are no applicable plan items or consumables for this vehicle yet.'**
  String get roadmapEmpty;

  /// No description provided for @timelineEmpty.
  ///
  /// In en, this message translates to:
  /// **'There are no future plan items yet.'**
  String get timelineEmpty;

  /// No description provided for @nowHistoryUnknown.
  ///
  /// In en, this message translates to:
  /// **'Now · confirmed mileage not provided'**
  String get nowHistoryUnknown;

  /// No description provided for @nowAtMileage.
  ///
  /// In en, this message translates to:
  /// **'Now · {mileage} {unit}'**
  String nowAtMileage(int mileage, String unit);

  /// No description provided for @statusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Status: unknown'**
  String get statusUnknown;

  /// No description provided for @statusCurrentReal.
  ///
  /// In en, this message translates to:
  /// **'Status: current'**
  String get statusCurrentReal;

  /// No description provided for @statusSoonReal.
  ///
  /// In en, this message translates to:
  /// **'Status: soon'**
  String get statusSoonReal;

  /// No description provided for @statusOverdueReal.
  ///
  /// In en, this message translates to:
  /// **'Status: overdue'**
  String get statusOverdueReal;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Status: completed'**
  String get statusCompleted;

  /// No description provided for @statusNotApplicable.
  ///
  /// In en, this message translates to:
  /// **'Not applicable'**
  String get statusNotApplicable;

  /// No description provided for @intervalMileage.
  ///
  /// In en, this message translates to:
  /// **'{value} km interval'**
  String intervalMileage(int value);

  /// No description provided for @intervalDays.
  ///
  /// In en, this message translates to:
  /// **'{value}-day interval'**
  String intervalDays(int value);

  /// No description provided for @intervalNotSpecified.
  ///
  /// In en, this message translates to:
  /// **'Interval not specified'**
  String get intervalNotSpecified;

  /// No description provided for @historyNotSpecified.
  ///
  /// In en, this message translates to:
  /// **'History not specified'**
  String get historyNotSpecified;

  /// No description provided for @inspectionRequired.
  ///
  /// In en, this message translates to:
  /// **'Inspection required'**
  String get inspectionRequired;

  /// No description provided for @inspectionRequiredNoWear.
  ///
  /// In en, this message translates to:
  /// **'Inspection required. No wear percentage is calculated.'**
  String get inspectionRequiredNoWear;

  /// No description provided for @intervalUsedFraction.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of the verified interval used; this is not physical wear.'**
  String intervalUsedFraction(int percent);

  /// No description provided for @quickAddTechnicalActive.
  ///
  /// In en, this message translates to:
  /// **'Command menu · active vehicle'**
  String get quickAddTechnicalActive;

  /// No description provided for @quickAddActiveHint.
  ///
  /// In en, this message translates to:
  /// **'Choose an available action for the active vehicle.'**
  String get quickAddActiveHint;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @specifyServiceHistory.
  ///
  /// In en, this message translates to:
  /// **'Specify service history'**
  String get specifyServiceHistory;

  /// No description provided for @refineServiceHistory.
  ///
  /// In en, this message translates to:
  /// **'Refine service history'**
  String get refineServiceHistory;

  /// No description provided for @skipAndOpenPlan.
  ///
  /// In en, this message translates to:
  /// **'Skip and open plan'**
  String get skipAndOpenPlan;

  /// No description provided for @historyWizardLabel.
  ///
  /// In en, this message translates to:
  /// **'Service history'**
  String get historyWizardLabel;

  /// No description provided for @historySingleLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected item history'**
  String get historySingleLabel;

  /// No description provided for @historyWizardTitle.
  ///
  /// In en, this message translates to:
  /// **'What has already been done?'**
  String get historyWizardTitle;

  /// No description provided for @skipAll.
  ///
  /// In en, this message translates to:
  /// **'Skip all'**
  String get skipAll;

  /// No description provided for @skipItem.
  ///
  /// In en, this message translates to:
  /// **'Skip item'**
  String get skipItem;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @historyProgress.
  ///
  /// In en, this message translates to:
  /// **'Item {current} of {total}'**
  String historyProgress(int current, int total);

  /// No description provided for @historyDoneKnown.
  ///
  /// In en, this message translates to:
  /// **'Done — date or mileage known'**
  String get historyDoneKnown;

  /// No description provided for @historyDoneUnknown.
  ///
  /// In en, this message translates to:
  /// **'Done, but I do not remember when'**
  String get historyDoneUnknown;

  /// No description provided for @historyNotDone.
  ///
  /// In en, this message translates to:
  /// **'Not done'**
  String get historyNotDone;

  /// No description provided for @historyUnknown.
  ///
  /// In en, this message translates to:
  /// **'I do not know'**
  String get historyUnknown;

  /// No description provided for @historyNotApplicable.
  ///
  /// In en, this message translates to:
  /// **'Not applicable'**
  String get historyNotApplicable;

  /// No description provided for @historyChooseDate.
  ///
  /// In en, this message translates to:
  /// **'Choose date'**
  String get historyChooseDate;

  /// No description provided for @historyMileage.
  ///
  /// In en, this message translates to:
  /// **'Mileage when performed, km'**
  String get historyMileage;

  /// No description provided for @historyKnownHint.
  ///
  /// In en, this message translates to:
  /// **'Enter at least a date or mileage.'**
  String get historyKnownHint;

  /// No description provided for @historyKnownRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a date or valid mileage.'**
  String get historyKnownRequired;

  /// No description provided for @historyMileageMax.
  ///
  /// In en, this message translates to:
  /// **'Mileage cannot exceed the current value: {mileage} km.'**
  String historyMileageMax(int mileage);

  /// No description provided for @historySaveError.
  ///
  /// In en, this message translates to:
  /// **'Unable to save history. Your answers remain on screen — retry.'**
  String get historySaveError;

  /// No description provided for @historyUnknownCheckNow.
  ///
  /// In en, this message translates to:
  /// **'History unknown — we recommend checking/performing it now'**
  String get historyUnknownCheckNow;

  /// No description provided for @specifyHistory.
  ///
  /// In en, this message translates to:
  /// **'Specify history'**
  String get specifyHistory;

  /// No description provided for @editHistory.
  ///
  /// In en, this message translates to:
  /// **'Edit history'**
  String get editHistory;

  /// No description provided for @timeProgress.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of the time interval used.'**
  String timeProgress(int percent);

  /// No description provided for @mileageProgress.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of the mileage interval used.'**
  String mileageProgress(int percent);

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Next date: {date}'**
  String dueDate(String date);

  /// No description provided for @dueMileage.
  ///
  /// In en, this message translates to:
  /// **'Next mileage: {mileage} {unit}'**
  String dueMileage(int mileage, String unit);

  /// No description provided for @lastInspectionDate.
  ///
  /// In en, this message translates to:
  /// **'Last inspection: {date}. No wear percentage is calculated.'**
  String lastInspectionDate(String date);

  /// No description provided for @nextInspectionDue.
  ///
  /// In en, this message translates to:
  /// **'Next inspection: {due}'**
  String nextInspectionDue(String due);

  /// No description provided for @refineMileage.
  ///
  /// In en, this message translates to:
  /// **'Refine'**
  String get refineMileage;

  /// No description provided for @setMileage.
  ///
  /// In en, this message translates to:
  /// **'Set mileage'**
  String get setMileage;

  /// No description provided for @currentMileage.
  ///
  /// In en, this message translates to:
  /// **'Current mileage'**
  String get currentMileage;

  /// No description provided for @mileageDecreaseNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Mileage cannot be lower than the current value.'**
  String get mileageDecreaseNotAllowed;

  /// No description provided for @mileageUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Unable to update mileage.'**
  String get mileageUpdateError;

  /// No description provided for @versionConflict.
  ///
  /// In en, this message translates to:
  /// **'The vehicle changed on another device. Reload and try again.'**
  String get versionConflict;

  /// No description provided for @addService.
  ///
  /// In en, this message translates to:
  /// **'Add service'**
  String get addService;

  /// No description provided for @addServiceRecord.
  ///
  /// In en, this message translates to:
  /// **'Add service record'**
  String get addServiceRecord;

  /// No description provided for @serviceRecordFactHint.
  ///
  /// In en, this message translates to:
  /// **'This adds a factual service record; it does not declare unknown history.'**
  String get serviceRecordFactHint;

  /// No description provided for @serviceDate.
  ///
  /// In en, this message translates to:
  /// **'Service date'**
  String get serviceDate;

  /// No description provided for @serviceMileage.
  ///
  /// In en, this message translates to:
  /// **'Mileage at service'**
  String get serviceMileage;

  /// No description provided for @serviceNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get serviceNote;

  /// No description provided for @serviceSaveError.
  ///
  /// In en, this message translates to:
  /// **'Unable to save the service record. Check the data and retry.'**
  String get serviceSaveError;

  /// No description provided for @serviceSaved.
  ///
  /// In en, this message translates to:
  /// **'Service record added'**
  String get serviceSaved;

  /// No description provided for @lastServiceUnknown.
  ///
  /// In en, this message translates to:
  /// **'Last service: unknown'**
  String get lastServiceUnknown;

  /// No description provided for @lastServiceDate.
  ///
  /// In en, this message translates to:
  /// **'Last service: {date}'**
  String lastServiceDate(String date);

  /// No description provided for @lastServiceMileage.
  ///
  /// In en, this message translates to:
  /// **'at {mileage} {unit}'**
  String lastServiceMileage(int mileage, String unit);

  /// No description provided for @nowMarker.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get nowMarker;

  /// No description provided for @nextDue.
  ///
  /// In en, this message translates to:
  /// **'Next due'**
  String get nextDue;

  /// No description provided for @limitingTime.
  ///
  /// In en, this message translates to:
  /// **'Limiting interval: time'**
  String get limitingTime;

  /// No description provided for @limitingMileage.
  ///
  /// In en, this message translates to:
  /// **'Limiting interval: mileage'**
  String get limitingMileage;

  /// No description provided for @limitingUnknown.
  ///
  /// In en, this message translates to:
  /// **'Limiting interval: not determined'**
  String get limitingUnknown;

  /// No description provided for @planLegend.
  ///
  /// In en, this message translates to:
  /// **'Plan legend'**
  String get planLegend;

  /// No description provided for @legendActionLevel.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get legendActionLevel;

  /// No description provided for @legendBasis.
  ///
  /// In en, this message translates to:
  /// **'Basis'**
  String get legendBasis;

  /// No description provided for @actionInfo.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get actionInfo;

  /// No description provided for @actionRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Recommendation'**
  String get actionRecommendation;

  /// No description provided for @actionAttention.
  ///
  /// In en, this message translates to:
  /// **'Attention'**
  String get actionAttention;

  /// No description provided for @actionRequired.
  ///
  /// In en, this message translates to:
  /// **'Action required'**
  String get actionRequired;

  /// No description provided for @actionCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get actionCritical;

  /// No description provided for @actionInfoExplanation.
  ///
  /// In en, this message translates to:
  /// **'For awareness; no action is currently needed.'**
  String get actionInfoExplanation;

  /// No description provided for @actionRecommendationExplanation.
  ///
  /// In en, this message translates to:
  /// **'Worth doing when convenient.'**
  String get actionRecommendationExplanation;

  /// No description provided for @actionAttentionExplanation.
  ///
  /// In en, this message translates to:
  /// **'Plan this soon.'**
  String get actionAttentionExplanation;

  /// No description provided for @actionRequiredExplanation.
  ///
  /// In en, this message translates to:
  /// **'Check or perform this without delay.'**
  String get actionRequiredExplanation;

  /// No description provided for @actionCriticalExplanation.
  ///
  /// In en, this message translates to:
  /// **'Act immediately for safety or reliability.'**
  String get actionCriticalExplanation;

  /// No description provided for @basisConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get basisConfirmed;

  /// No description provided for @basisForecast.
  ///
  /// In en, this message translates to:
  /// **'Forecast'**
  String get basisForecast;

  /// No description provided for @basisMissingData.
  ///
  /// In en, this message translates to:
  /// **'Missing data'**
  String get basisMissingData;

  /// No description provided for @basisConfirmedExplanation.
  ///
  /// In en, this message translates to:
  /// **'Based on recorded facts or observations.'**
  String get basisConfirmedExplanation;

  /// No description provided for @basisForecastExplanation.
  ///
  /// In en, this message translates to:
  /// **'An explicit estimate, not a confirmed fact.'**
  String get basisForecastExplanation;

  /// No description provided for @basisMissingDataExplanation.
  ///
  /// In en, this message translates to:
  /// **'More history or an inspection is needed.'**
  String get basisMissingDataExplanation;

  /// No description provided for @iconCategorySemantics.
  ///
  /// In en, this message translates to:
  /// **'Category: {label}'**
  String iconCategorySemantics(String label);

  /// No description provided for @serviceTimelineEmpty.
  ///
  /// In en, this message translates to:
  /// **'No service records yet'**
  String get serviceTimelineEmpty;

  /// No description provided for @performed.
  ///
  /// In en, this message translates to:
  /// **'Performed'**
  String get performed;

  /// No description provided for @preliminaryEstimate.
  ///
  /// In en, this message translates to:
  /// **'Preliminary estimate'**
  String get preliminaryEstimate;

  /// No description provided for @forecastAnnualDistance.
  ///
  /// In en, this message translates to:
  /// **'{label}: {distance} {unit}/year'**
  String forecastAnnualDistance(String label, int distance, String unit);

  /// No description provided for @forecastWindow.
  ///
  /// In en, this message translates to:
  /// **'Orientation window: {from}–{to}'**
  String forecastWindow(String from, String to);

  /// No description provided for @selectServiceWork.
  ///
  /// In en, this message translates to:
  /// **'Select one plan item'**
  String get selectServiceWork;

  /// No description provided for @selectServiceWorkHint.
  ///
  /// In en, this message translates to:
  /// **'Select exactly one applicable plan item.'**
  String get selectServiceWorkHint;

  /// No description provided for @wearSpecify.
  ///
  /// In en, this message translates to:
  /// **'Enter wear'**
  String get wearSpecify;

  /// No description provided for @wearPercent.
  ///
  /// In en, this message translates to:
  /// **'Wear, % (0 = no wear, 100 = fully worn)'**
  String get wearPercent;

  /// No description provided for @wearRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining: {percent}%'**
  String wearRemaining(int percent);

  /// No description provided for @wearMeasured.
  ///
  /// In en, this message translates to:
  /// **'Measured wear: {percent}%'**
  String wearMeasured(int percent);

  /// No description provided for @wearDate.
  ///
  /// In en, this message translates to:
  /// **'Measurement date'**
  String get wearDate;

  /// No description provided for @wearSource.
  ///
  /// In en, this message translates to:
  /// **'Measurement source'**
  String get wearSource;

  /// No description provided for @wearSourceSelf.
  ///
  /// In en, this message translates to:
  /// **'Self-inspection'**
  String get wearSourceSelf;

  /// No description provided for @wearSourceWorkshop.
  ///
  /// In en, this message translates to:
  /// **'Workshop'**
  String get wearSourceWorkshop;

  /// No description provided for @wearNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get wearNote;

  /// No description provided for @wearValidation.
  ///
  /// In en, this message translates to:
  /// **'Enter wear from 0 to 100.'**
  String get wearValidation;

  /// No description provided for @wearSaveError.
  ///
  /// In en, this message translates to:
  /// **'Unable to save wear measurement.'**
  String get wearSaveError;

  /// No description provided for @conditionObservationDateSource.
  ///
  /// In en, this message translates to:
  /// **'{date} · {source}'**
  String conditionObservationDateSource(String date, String source);
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
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

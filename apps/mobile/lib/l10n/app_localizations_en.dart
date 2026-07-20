// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AutoDoctor';

  @override
  String get language => 'Language';

  @override
  String get system => 'System';

  @override
  String get russian => 'Russian';

  @override
  String get english => 'English';

  @override
  String get navPlan => 'Plan';

  @override
  String get maintenancePlanTitle => 'Maintenance plan';

  @override
  String get navJournal => 'Journal';

  @override
  String get navAssistant => 'AI';

  @override
  String get navState => 'Condition';

  @override
  String get navAnalytics => 'Analytics';

  @override
  String get navMore => 'More';

  @override
  String historyCompletenessBanner(int percent) {
    return 'Service history is $percent% complete. Refine — about 3 min';
  }

  @override
  String get historyCompletenessCta => 'Refine history';

  @override
  String get openState => 'Open Condition';

  @override
  String get openAnalytics => 'Open analytics';

  @override
  String get stateTitle => 'Condition';

  @override
  String get stateSubtitle => 'Resource and wear scale. Open a card to update.';

  @override
  String get stateNeedsData => 'Needs data';

  @override
  String stateUsedPercent(int percent) {
    return 'Used $percent%';
  }

  @override
  String stateWearRemaining(int wear, int remaining) {
    return 'Wear $wear% · remaining $remaining%';
  }

  @override
  String get stateWearCaption => 'wear';

  @override
  String get stateTriggerTime => 'time';

  @override
  String get stateTriggerMileage => 'mileage';

  @override
  String get stateScaleCaption => 'life';

  @override
  String stateLastServiceShort(String date) {
    return 'serviced $date';
  }

  @override
  String get stateLastServiceUnknownShort => 'service unknown';

  @override
  String get stateUpdateSection => 'Update data';

  @override
  String get stateNoteField => 'Note';

  @override
  String get stateNoteHint => 'Replacement, top-up, comment…';

  @override
  String get stateWearField => 'Wear, %';

  @override
  String get stateWearHint => '0 = new or no wear';

  @override
  String get stateLaborCost => 'Labor cost';

  @override
  String get statePartsCost => 'Parts cost';

  @override
  String get stateUpdateDate => 'Date';

  @override
  String get stateUpdateMileage => 'Mileage';

  @override
  String get stateUpdateSave => 'Save';

  @override
  String get stateUpdateSaveEdit => 'Save changes';

  @override
  String get stateCancelEdit => 'Cancel edit';

  @override
  String get stateEditRecord => 'Edit record';

  @override
  String get stateDeleteRecord => 'Delete record';

  @override
  String get stateDeleteConfirm => 'Delete this service record?';

  @override
  String get stateServiceHistory => 'Service dates';

  @override
  String get stateServiceHistoryEmpty => 'No records yet';

  @override
  String get stateUpdateError =>
      'Could not save. Check the fields and try again.';

  @override
  String stateEditingBanner(String date) {
    return 'Editing record from $date';
  }

  @override
  String get stateCurrentFacts => 'Current facts';

  @override
  String get stateInspectionStatus => 'Inspection status';

  @override
  String get stateEmpty => 'No condition items for this vehicle yet.';

  @override
  String get stateGate => 'Condition tiles appear after you add a vehicle.';

  @override
  String get planNearestWork => 'Next work';

  @override
  String get planRoadLabel => 'Service road';

  @override
  String get planTimelineLabel => 'Timeline';

  @override
  String get planRemainingList => 'Later';

  @override
  String get planAnalyticsStrip => 'At a glance';

  @override
  String planNearestCount(int count) {
    return 'Nearest: $count';
  }

  @override
  String get historySaveAndNext => 'Save and continue';

  @override
  String get historyFinishLater => 'Finish later';

  @override
  String get historyNever => 'Never';

  @override
  String get historyAdditional => 'Additional';

  @override
  String get historyWearToggle => 'Enter wear / remaining';

  @override
  String get historyRemainingPercent => 'Remaining, %';

  @override
  String get historyInstallDate => 'Install date';

  @override
  String get historyInstallMileage => 'Install mileage, km';

  @override
  String get historyNoteOptional => 'Note (optional)';

  @override
  String get historyReplacementDate => 'Replacement date';

  @override
  String get historyReplacementMileage => 'Replacement mileage, km';

  @override
  String get historyCheckDate => 'Check date';

  @override
  String get moreAnalytics => 'Analytics';

  @override
  String get moreAnalyticsDetail => 'Confirmed amounts, categories, mileage';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get understood => 'Got it';

  @override
  String get example => 'Example';

  @override
  String get exampleSemantics => 'Demonstration example';

  @override
  String previewNoCar(String message) {
    return 'Preview with no vehicle. $message';
  }

  @override
  String get previewGarageEmpty => 'Preview · garage empty';

  @override
  String get addVehicle => 'Add vehicle';

  @override
  String get previewUnavailableHint =>
      'Example. Action unavailable without a vehicle';

  @override
  String get demoEntry => 'Demo · entry';

  @override
  String get vehicleStatusNoCar => 'Vehicle status · no car';

  @override
  String get garageEmpty => 'Garage is empty';

  @override
  String get addVehicleSemantics => 'Add vehicle. Open setup';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsEmpty =>
      'Notification history will appear after you add a vehicle.';

  @override
  String notificationsForVehicle(String make, String model) {
    return 'Notifications · $make $model';
  }

  @override
  String get notificationsNoNew => 'No new notifications';

  @override
  String get guestProfile => 'Guest profile';

  @override
  String get openGuestProfile => 'Open guest profile';

  @override
  String get guestProfileInitial => 'G';

  @override
  String get guestProfileFuture =>
      'Sign-in and synchronization will be available in later stages.';

  @override
  String get addEvent => 'Add event';

  @override
  String get addEventJournalSemantics => 'Add an event to the journal';

  @override
  String get quickAddTechnical => 'Command menu · vehicle required';

  @override
  String get quickAddPreview =>
      'Preview of the next step. Select a vehicle to open the form and save an entry.';

  @override
  String get quickAddFuel => 'Refueling';

  @override
  String get quickAddService => 'Service or repair';

  @override
  String get quickAddExpense => 'Other expense';

  @override
  String get quickAddMileage => 'Update mileage';

  @override
  String unavailableWithoutVehicle(String label) {
    return '$label. Unavailable without a vehicle';
  }

  @override
  String get addVehicleFirst => 'Add a vehicle first';

  @override
  String get aiCentralTab => 'AI, center tab';

  @override
  String get aiAssistant => 'AI assistant';

  @override
  String get cockpitDemo => 'Cockpit module · demo mode';

  @override
  String get planPreviewGate =>
      'This is only a design preview. Your personal plan will appear after you add a vehicle.';

  @override
  String get consumablesRailSemantics =>
      'Consumables, demonstration vertical area with independent scrolling';

  @override
  String get timelineSemantics =>
      'Detailed demonstration timeline with independent scrolling';

  @override
  String get closeConsumablesBarrier => 'Close consumables list';

  @override
  String get consumables => 'Consumables';

  @override
  String get consumablesSheetSemantics =>
      'Consumables. Modal panel. Demonstration list';

  @override
  String get consumablesProjection => 'Projection · demo / no car';

  @override
  String get closeConsumables => 'Close consumables panel';

  @override
  String get consumablesDisclaimer =>
      'The examples below do not relate to a real vehicle and are not recommendations.';

  @override
  String selectedConsumable(String label) {
    return 'Selected consumable: $label';
  }

  @override
  String consumableRailSemantics(String title, String state) {
    return '$title. $state. Example without a vehicle. Open full list and details';
  }

  @override
  String consumableRowSemantics(String title, String state) {
    return '$title. $state';
  }

  @override
  String intervalFraction(int percent) {
    return 'Demonstration share of the service interval used: $percent%. This is not physical wear.';
  }

  @override
  String conditionNoPercent(String state) {
    return '$state. Percentage and value are not shown.';
  }

  @override
  String get oilTitle => 'Engine oil';

  @override
  String get oilState => 'Warning: due soon';

  @override
  String get oilDue => 'Example: in 1,200 km or 2 months';

  @override
  String get intervalEarlierBasis =>
      'Time and mileage interval; the earlier threshold applies.';

  @override
  String get manufacturerSource =>
      'Example basis: verified manufacturer service schedule.';

  @override
  String get triggerMileage => 'Effective trigger: mileage';

  @override
  String get brakesTitle => 'Brake pads';

  @override
  String get brakesState => 'Inspection required, no measurement';

  @override
  String get brakesDue => 'Next inspection: after adding a vehicle';

  @override
  String get conditionBasis =>
      'Condition-based item; no percentage is calculated without an actual measurement.';

  @override
  String get inspectionRuleSource => 'Example basis: periodic inspection rule.';

  @override
  String get triggerInspection => 'Effective trigger: inspection';

  @override
  String get lastInspectionUnknown => 'Last inspection: unknown';

  @override
  String get coolantTitle => 'Coolant';

  @override
  String get coolantState => 'Dangerously close to due';

  @override
  String get coolantDue => 'Example: in 3 weeks or 600 km';

  @override
  String get publishedRuleSource =>
      'Example basis: published maintenance rule.';

  @override
  String get triggerTime => 'Effective trigger: time';

  @override
  String get airFilterTitle => 'Air filter';

  @override
  String get normalInterval => 'Normal interval';

  @override
  String get airFilterDue => 'Example: in 7,500 km';

  @override
  String get verifiedMileageBasis => 'Mileage share of a verified interval.';

  @override
  String get tiresTitle => 'Tires';

  @override
  String get tiresState => 'Inspection state unknown, no measurement';

  @override
  String get tiresDue => 'Next inspection: date not calculated';

  @override
  String get tiresBasis =>
      'Condition-based item; physical wear is not calculated.';

  @override
  String get inspectionRecommendationSource =>
      'Example basis: general inspection recommendation.';

  @override
  String get triggerUnknown => 'Effective trigger: unknown';

  @override
  String get categoryMaintenance => 'Service and repair';

  @override
  String get categoryParts => 'Parts';

  @override
  String get categoryFuel => 'Fuel';

  @override
  String get categoryInspection => 'Inspection';

  @override
  String get categoryDocument => 'Document';

  @override
  String get categoryMileage => 'Mileage';

  @override
  String get categoryExpense => 'Expense';

  @override
  String get categoryReminder => 'Reminder';

  @override
  String get indicatorVerified => 'Source verified';

  @override
  String get indicatorCost => 'Has cost';

  @override
  String get indicatorGrouped => 'Event group';

  @override
  String get indicatorForecast => 'Estimated period';

  @override
  String get indicatorUnknownHistory => 'History unknown';

  @override
  String get importanceInformation => 'Information';

  @override
  String get importanceRecommendation => 'Recommendation';

  @override
  String get importanceRequired => 'Required';

  @override
  String get importanceCritical => 'Critical attention';

  @override
  String importanceSemantics(String label) {
    return 'Importance: $label';
  }

  @override
  String eventCategorySemantics(String event, String category) {
    return '$event. Category: $category';
  }

  @override
  String get overdue => 'Overdue';

  @override
  String get demoNotVehicleData => 'Demonstration example, not vehicle data';

  @override
  String get nowSemantics =>
      'Now. Demonstration calculation point; actual mileage is unavailable';

  @override
  String get nowExample => 'Now · example without an odometer reading';

  @override
  String get timelineFuelTime => 'Example · July 14, 18:40';

  @override
  String get demoMileage84120 => '84,120 km';

  @override
  String get demoMileage83900 => '83,900 km';

  @override
  String get timelineFuelTitle => 'Refueling';

  @override
  String get timelineFuelDetail => 'Demonstration of a grouped actual entry';

  @override
  String get timelineServiceTime => 'Example · July 10';

  @override
  String get timelineServiceTitle => 'Scheduled service';

  @override
  String get timelineServiceDetail => 'Past event without future importance';

  @override
  String get timelineExpenseTime => 'Example · July 8';

  @override
  String get timelineExpenseTitle => 'Other expense';

  @override
  String get timelineExpenseDetail =>
      'Category shown as a separate primary emblem';

  @override
  String get timelineMileageTime => 'Example · in about 9–12 months';

  @override
  String get timelineMileageTitle => 'Mileage update estimate';

  @override
  String get timelineMileageDetail => 'Broad forecast, not an odometer reading';

  @override
  String get statusEstimate => 'Status: estimate';

  @override
  String get timelineBrakesTime => 'Example · next month';

  @override
  String get timelineBrakesTitle => 'Brake system inspection';

  @override
  String get timelineBrakesDetail =>
      'No measurement; physical inspection required';

  @override
  String get statusSoon => 'Status: soon';

  @override
  String get timelineFilterTime => 'Example · by September 30';

  @override
  String get timelineFilterTitle => 'Replace air filter';

  @override
  String get timelineFilterDetail =>
      'Scheduled example; personal due date not calculated';

  @override
  String get mileageThreshold => 'or at the mileage threshold';

  @override
  String get statusCurrent => 'Status: current';

  @override
  String get timelineDocumentTime => 'Example · due date has passed';

  @override
  String get timelineDocumentTitle => 'Check required document';

  @override
  String get timelineDocumentDetail =>
      'Overdue state is shown separately from importance';

  @override
  String get statusOverdue => 'Status: overdue';

  @override
  String get timelineReminderTime => 'Example · selected date';

  @override
  String get timelineReminderTitle => 'Personal reminder';

  @override
  String get timelineReminderDetail =>
      'Created by the user and is not a service schedule';

  @override
  String get statusPlanned => 'Status: planned';

  @override
  String get journalGate =>
      'The full timeline will appear after you add a vehicle and confirmed entries.';

  @override
  String get filterAll => 'All';

  @override
  String get filterService => 'Service';

  @override
  String get filterFuel => 'Refueling';

  @override
  String get filterOther => 'Other';

  @override
  String get journalDemoDisclaimer =>
      'Only a muted example structure is shown below — this is not your vehicle history.';

  @override
  String get journalServiceTitle => 'Example · Service';

  @override
  String get journalServiceSubtitle => 'Confirmed work, date and mileage';

  @override
  String get journalFuelTitle => 'Example · Refueling';

  @override
  String get journalFuelSubtitle => 'Consumption and additional fuel data';

  @override
  String get journalExpenseTitle => 'Example · Other expense';

  @override
  String get journalExpenseSubtitle => 'Category, date and confirmed amount';

  @override
  String get topicsExample => 'Topics · example';

  @override
  String get topicSuspension => 'Suspension';

  @override
  String get topicPaint => 'Paint';

  @override
  String get topicElectronics => 'Electronics';

  @override
  String get assistantGate => 'AI uses vehicle data. Add a vehicle first.';

  @override
  String get topics => 'Topics';

  @override
  String get chatQuestion =>
      'What should I check first, and how urgently should I visit a service center?';

  @override
  String get chatAnswer =>
      'An answer based on this vehicle\'s history will appear here.';

  @override
  String get messageFieldUnavailable =>
      'Message field unavailable. Add a vehicle first';

  @override
  String get message => 'Message';

  @override
  String get sendingDisabled => 'Sending is disabled: no vehicle selected.';

  @override
  String selectedVehicleContext(String make, String model) {
    return 'Selected vehicle · $make $model';
  }

  @override
  String get aiUnavailable => 'The AI assistant is not connected yet';

  @override
  String get aiAvailableAfterConnection => 'Available after AI is connected';

  @override
  String get aiTopicsUnavailable =>
      'Topics will be available after the AI assistant is connected.';

  @override
  String get journalLoading => 'Loading service records…';

  @override
  String get journalLoadError => 'Unable to load service records.';

  @override
  String journalForVehicle(String make, String model) {
    return 'Journal · $make $model';
  }

  @override
  String analyticsForVehicle(String make, String model) {
    return 'Analytics · $make $model';
  }

  @override
  String get analyticsPreparing =>
      'Preparing analytics from confirmed records…';

  @override
  String get analyticsNoData =>
      'There are no confirmed records for analytics yet.';

  @override
  String get analyticsLoadError => 'Unable to load analytics data.';

  @override
  String get consumablesRedirecting =>
      'Opening the current plan and consumables for the selected vehicle…';

  @override
  String get analyticsGate =>
      'Analytics will appear after you add a vehicle and confirmed entries.';

  @override
  String get analyticsEmpty =>
      'Only confirmed data will appear here. Amounts, charts, and conclusions are not calculated yet.';

  @override
  String get confirmedAmounts => 'Confirmed amounts';

  @override
  String get currentMonthYear => 'For the current month and year';

  @override
  String get expenseCategories => 'Expense categories';

  @override
  String get confirmedDistribution => 'Distribution of confirmed entries';

  @override
  String get confirmedMileage => 'Confirmed mileage';

  @override
  String get odometerDynamics => 'Dynamics based on saved odometer readings';

  @override
  String get fuelConsumptionFuture =>
      'Fuel consumption will appear only when enough high-quality data is available.';

  @override
  String structureWithoutData(String title, String detail) {
    return '$title. $detail. Structure without data';
  }

  @override
  String get allConsumables => 'All consumables';

  @override
  String get allConsumablesGate =>
      'The full list is based on a verified schedule, plan, and history of a specific vehicle.';

  @override
  String get oilFilters => 'Oil and filters';

  @override
  String get oilFiltersDetail =>
      'Interval item: time and mileage progress are shown separately; the earlier threshold applies.';

  @override
  String get technicalFluids => 'Technical fluids';

  @override
  String get technicalFluidsDetail =>
      'An interval item appears only when an applicable verified rule exists.';

  @override
  String get brakesDetail =>
      'Condition-based: last check, measurement when available, and next inspection.';

  @override
  String get tiresDetail =>
      'Condition-based: without an invented wear percentage or physical remaining life.';

  @override
  String get demoConsumableHint => 'Demonstration consumable, not vehicle data';

  @override
  String get demoTechnicalRail => 'Example · technical rail';

  @override
  String get moreGate =>
      'Settings are available for preview. Vehicle functions are disabled.';

  @override
  String get appSettings => 'App settings';

  @override
  String get unitsThemeLanguage => 'Units, theme, and language';

  @override
  String get feedback => 'Feedback';

  @override
  String get feedbackDetail => 'Report a problem or idea';

  @override
  String get vehicleReminders => 'Vehicle reminders';

  @override
  String get controlChannel => 'Control channel';

  @override
  String get localPreviewFuture =>
      'Local preview. Integration will be available later.';

  @override
  String get languagePickerTitle => 'Language';

  @override
  String get selectedLanguage => 'Selected';

  @override
  String get garageSetupStep1 => 'Garage setup · step 01';

  @override
  String get secureInitializing => 'Secure channel · initializing';

  @override
  String get preparingSecureSetup => 'Preparing secure vehicle setup…';

  @override
  String get consentProtocol => 'Consent protocol · step 01 / 02';

  @override
  String get consents => 'Consents';

  @override
  String get consentsIntro =>
      'To continue, accept the required consent. Analytics is optional and does not affect core features.';

  @override
  String get required => 'Required';

  @override
  String get optional => 'Optional';

  @override
  String versionLabel(String version) {
    return 'Version: $version';
  }

  @override
  String get continueAction => 'Continue';

  @override
  String get connectionFault => 'Connection fault';

  @override
  String get bootstrapUnavailable => 'Unable to prepare vehicle setup.';

  @override
  String get networkError =>
      'Unable to contact the server. Check your connection.';

  @override
  String get unexpectedResponse =>
      'The server returned an unexpected response.';

  @override
  String requestIdLabel(String requestId) {
    return 'Request ID: $requestId';
  }

  @override
  String get retry => 'Retry';

  @override
  String get garageSetupStep2 => 'Garage setup · step 02';

  @override
  String get vinEntry => 'VIN entry';

  @override
  String get vinInterfaceOffline => 'VIN interface · offline';

  @override
  String get addStage => 'Setup stage';

  @override
  String get stepTwoOfTwo => '02 / 02';

  @override
  String get nextStage => 'Next step';

  @override
  String get vinStubDetail => 'Consents have been saved.';

  @override
  String get vehicleDetailsStep => 'Garage setup · vehicle data';

  @override
  String get vehicleDetails => 'Vehicle details';

  @override
  String get vin => 'VIN';

  @override
  String get vinValidation => 'Enter a 17-character VIN without I, O, or Q.';

  @override
  String get vinOptionalHelper =>
      'Without a VIN, automatic data collection and precise configuration identification will not be available in the future.';

  @override
  String get collectVinData => 'Collect data by VIN';

  @override
  String get vinProviderTitle => 'VIN data';

  @override
  String get vinProviderInfo =>
      'The VIN provider is not connected yet. Enter and confirm the data manually — the app will not add invented details.';

  @override
  String get continueManually => 'Continue manually';

  @override
  String get vehicleMake => 'Make';

  @override
  String get vehicleMakeOther => 'Enter make';

  @override
  String get vehicleModel => 'Model';

  @override
  String get vehicleModelOther => 'Enter model';

  @override
  String get otherModel => 'Other model';

  @override
  String get productionYear => 'Production year';

  @override
  String get mileageKm => 'Mileage, km';

  @override
  String get fuelType => 'Fuel type';

  @override
  String get engineDisplacement => 'Engine displacement, cc';

  @override
  String get transmissionType => 'Transmission type';

  @override
  String get transmissionGears => 'Number of gears';

  @override
  String get moreVehicleDetails => 'More details';

  @override
  String get optionalDetailsAccuracy =>
      'More detail improves recommendation accuracy. Specific OEM recommendations still require a verified configuration.';

  @override
  String get generation => 'Generation';

  @override
  String get engineCode => 'Engine code';

  @override
  String get powerKw => 'Power, kW';

  @override
  String get drivetrain => 'Drivetrain';

  @override
  String get market => 'Market';

  @override
  String get firstUseDate => 'First use date';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get reviewVehicle => 'Review details';

  @override
  String get requiredTextValidation => 'Required, up to 100 characters.';

  @override
  String get max100Validation => 'Up to 100 characters.';

  @override
  String get yearValidation => 'Enter a year from 1886 to 2100.';

  @override
  String get nonNegativeValidation => 'Enter a non-negative whole number.';

  @override
  String get displacementValidation => 'Enter a value from 1 to 20,000.';

  @override
  String get gearsValidation => 'Enter 1 to 12 gears.';

  @override
  String get powerValidation => 'Enter a value above 0 and no more than 2000.';

  @override
  String get selectValueValidation => 'Select a value.';

  @override
  String get fuelPetrol => 'Petrol';

  @override
  String get fuelDiesel => 'Diesel';

  @override
  String get fuelHybrid => 'Hybrid';

  @override
  String get fuelElectric => 'Electric';

  @override
  String get fuelLpg => 'LPG';

  @override
  String get other => 'Other';

  @override
  String get transmissionManual => 'Manual';

  @override
  String get transmissionAutomatic => 'Automatic';

  @override
  String get transmissionCvt => 'CVT';

  @override
  String get transmissionRobotized => 'Robotized';

  @override
  String get drivetrainFwd => 'Front-wheel drive';

  @override
  String get drivetrainRwd => 'Rear-wheel drive';

  @override
  String get drivetrainAwd => 'All-wheel drive';

  @override
  String get drivetrainFourWd => 'Four-wheel drive';

  @override
  String get confirmVehicleStep => 'Garage setup · confirmation';

  @override
  String get confirmVehicleTitle => 'Review your vehicle';

  @override
  String get vehicleIdentitySection => 'Identification';

  @override
  String get vehicleTechnicalSection => 'Technical details';

  @override
  String get vehicleAdditionalSection => 'Additional details';

  @override
  String get dataSource => 'Data source';

  @override
  String get dataSourceUser => 'Entered and confirmed by the user';

  @override
  String get vehicleCreateError => 'Unable to create the vehicle profile.';

  @override
  String get vehicleConflictHelp =>
      'Review the data or return to editing. The profile may already exist or the limit may have been reached.';

  @override
  String get editVehicle => 'Edit details';

  @override
  String get createVehicle => 'Create profile';

  @override
  String get firstPlanStep => 'Vehicle profile · ready';

  @override
  String get firstPlanTitle => 'Preparing plan';

  @override
  String firstPlanPreparing(String make, String model) {
    return '$make $model: profile created';
  }

  @override
  String get firstPlanHonestStatus =>
      'The plan is being prepared. Specific schedules and dates will appear only after applicable data is available.';

  @override
  String get openPlan => 'Go to plan';

  @override
  String get vehicleStatusActive => 'Active vehicle';

  @override
  String get openVehicleProfile => 'Open vehicle profile summary';

  @override
  String get vehicleProfileBasicSummary => 'Vehicle profile';

  @override
  String vehicleMileageSummary(int mileage, String unit) {
    return 'Mileage: $mileage $unit.';
  }

  @override
  String profileCreatedPlanPreparing(String make, String model) {
    return '$make $model: profile created · plan is being prepared. The timeline below is an illustrative preview.';
  }

  @override
  String get featurePreparingForVehicle =>
      'The vehicle profile has been created. This feature is still being prepared.';

  @override
  String loadingRealPlan(String vehicle) {
    return 'Loading the real plan for $vehicle';
  }

  @override
  String get planNotReadyYet =>
      'The plan is marked ready only after a successful server response.';

  @override
  String vehicleMaintenancePlan(String vehicle) {
    return 'Maintenance plan · $vehicle';
  }

  @override
  String planItemsCount(int count) {
    return 'Maintenance items: $count';
  }

  @override
  String get editorialNotManufacturer =>
      'AutoDoctor editorial methodology · not a manufacturer schedule';

  @override
  String get sourceEditorialBaseline => 'Editorial baseline, not OEM';

  @override
  String get sourceOfficialOem => 'Official manufacturer source';

  @override
  String get sourceRegulatory => 'Regulatory source';

  @override
  String get unknownValue => 'Unknown value';

  @override
  String get warningEditorialBaseline =>
      'The plan uses the AutoDoctor editorial baseline, not a manufacturer schedule.';

  @override
  String get warningHistoryRequired =>
      'Service history is missing, so due dates and overdue status are not calculated.';

  @override
  String get warningMileageMissing =>
      'Mileage is missing, so mileage-based recommendations cannot be refined.';

  @override
  String get warningUnknown => 'The server returned an additional warning.';

  @override
  String get planPreparingError =>
      'The server is still preparing the plan. The vehicle is saved — retry the request.';

  @override
  String get planLoadError => 'Unable to load the maintenance plan.';

  @override
  String get roadmapEmpty =>
      'There are no applicable plan items or consumables for this vehicle yet.';

  @override
  String get timelineEmpty => 'There are no future plan items yet.';

  @override
  String get nowHistoryUnknown => 'Now · confirmed mileage not provided';

  @override
  String nowAtMileage(int mileage, String unit) {
    return 'Now · $mileage $unit';
  }

  @override
  String get statusUnknown => 'Status: unknown';

  @override
  String get statusCurrentReal => 'Status: current';

  @override
  String get statusSoonReal => 'Status: soon';

  @override
  String get statusOverdueReal => 'Status: overdue';

  @override
  String get statusCompleted => 'Status: completed';

  @override
  String get statusNotApplicable => 'Not applicable';

  @override
  String intervalMileage(int value) {
    return '$value km interval';
  }

  @override
  String intervalDays(int value) {
    return '$value-day interval';
  }

  @override
  String get intervalNotSpecified => 'Interval not specified';

  @override
  String get historyNotSpecified => 'History not specified';

  @override
  String get inspectionRequired => 'Inspection required';

  @override
  String get inspectionRequiredNoWear =>
      'Inspection required. No wear percentage is calculated.';

  @override
  String intervalUsedFraction(int percent) {
    return '$percent% of the verified interval used; this is not physical wear.';
  }

  @override
  String get quickAddTechnicalActive => 'Command menu · active vehicle';

  @override
  String get quickAddActiveHint =>
      'Choose an available action for the active vehicle.';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get specifyServiceHistory => 'Specify service history';

  @override
  String get refineServiceHistory => 'Refine service history';

  @override
  String get skipAndOpenPlan => 'Skip and open plan';

  @override
  String get historyWizardLabel => 'Service history';

  @override
  String get historySingleLabel => 'Selected item history';

  @override
  String get historyWizardTitle => 'What has already been done?';

  @override
  String get skipAll => 'Skip all';

  @override
  String get skipItem => 'Skip item';

  @override
  String get next => 'Next';

  @override
  String get save => 'Save';

  @override
  String historyProgress(int current, int total) {
    return 'Item $current of $total';
  }

  @override
  String get historyDoneKnown => 'Done — date or mileage known';

  @override
  String get historyDoneUnknown => 'Done, but I do not remember when';

  @override
  String get historyNotDone => 'Not done';

  @override
  String get historyUnknown => 'I do not know';

  @override
  String get historyNotApplicable => 'Not applicable';

  @override
  String get historyChooseDate => 'Choose date';

  @override
  String get historyMileage => 'Mileage when performed, km';

  @override
  String get historyKnownHint => 'Enter at least a date or mileage.';

  @override
  String get historyKnownRequired => 'Enter a date or valid mileage.';

  @override
  String historyMileageMax(int mileage) {
    return 'Mileage cannot exceed the current value: $mileage km.';
  }

  @override
  String get historySaveError =>
      'Unable to save history. Your answers remain on screen — retry.';

  @override
  String get historyUnknownCheckNow =>
      'History unknown — we recommend checking/performing it now';

  @override
  String get specifyHistory => 'Specify history';

  @override
  String get editHistory => 'Edit history';

  @override
  String timeProgress(int percent) {
    return '$percent% of the time interval used.';
  }

  @override
  String mileageProgress(int percent) {
    return '$percent% of the mileage interval used.';
  }

  @override
  String dueDate(String date) {
    return 'Next date: $date';
  }

  @override
  String dueMileage(int mileage, String unit) {
    return 'Next mileage: $mileage $unit';
  }

  @override
  String lastInspectionDate(String date) {
    return 'Last inspection: $date. No wear percentage is calculated.';
  }

  @override
  String nextInspectionDue(String due) {
    return 'Next inspection: $due';
  }

  @override
  String get refineMileage => 'Refine';

  @override
  String get setMileage => 'Set mileage';

  @override
  String get currentMileage => 'Current mileage';

  @override
  String get mileageDecreaseNotAllowed =>
      'Mileage cannot be lower than the current value.';

  @override
  String get mileageUpdateError => 'Unable to update mileage.';

  @override
  String get versionConflict =>
      'The vehicle changed on another device. Reload and try again.';

  @override
  String get addService => 'Add service';

  @override
  String get addServiceRecord => 'Add service record';

  @override
  String get serviceRecordFactHint =>
      'This adds a factual service record; it does not declare unknown history.';

  @override
  String get serviceDate => 'Service date';

  @override
  String get serviceMileage => 'Mileage at service';

  @override
  String get serviceNote => 'Note (optional)';

  @override
  String get serviceSaveError =>
      'Unable to save the service record. Check the data and retry.';

  @override
  String get serviceSaved => 'Service record added';

  @override
  String get lastServiceUnknown => 'Last service: unknown';

  @override
  String lastServiceDate(String date) {
    return 'Last service: $date';
  }

  @override
  String lastServiceMileage(int mileage, String unit) {
    return 'at $mileage $unit';
  }

  @override
  String get nowMarker => 'Now';

  @override
  String get nextDue => 'Next due';

  @override
  String get limitingTime => 'Limiting interval: time';

  @override
  String get limitingMileage => 'Limiting interval: mileage';

  @override
  String get limitingUnknown => 'Limiting interval: not determined';

  @override
  String get planLegend => 'Plan legend';

  @override
  String get legendActionLevel => 'Action';

  @override
  String get legendBasis => 'Basis';

  @override
  String get actionInfo => 'Information';

  @override
  String get actionRecommendation => 'Recommendation';

  @override
  String get actionAttention => 'Attention';

  @override
  String get actionRequired => 'Action required';

  @override
  String get actionCritical => 'Critical';

  @override
  String get actionInfoExplanation =>
      'For awareness; no action is currently needed.';

  @override
  String get actionRecommendationExplanation => 'Worth doing when convenient.';

  @override
  String get actionAttentionExplanation => 'Plan this soon.';

  @override
  String get actionRequiredExplanation =>
      'Check or perform this without delay.';

  @override
  String get actionCriticalExplanation =>
      'Act immediately for safety or reliability.';

  @override
  String get basisConfirmed => 'Confirmed';

  @override
  String get basisForecast => 'Forecast';

  @override
  String get basisMissingData => 'Missing data';

  @override
  String get basisConfirmedExplanation =>
      'Based on recorded facts or observations.';

  @override
  String get basisForecastExplanation =>
      'An explicit estimate, not a confirmed fact.';

  @override
  String get basisMissingDataExplanation =>
      'More history or an inspection is needed.';

  @override
  String iconCategorySemantics(String label) {
    return 'Category: $label';
  }

  @override
  String get serviceTimelineEmpty => 'No service records yet';

  @override
  String get performed => 'Performed';

  @override
  String get preliminaryEstimate => 'Preliminary estimate';

  @override
  String forecastAnnualDistance(String label, int distance, String unit) {
    return '$label: $distance $unit/year';
  }

  @override
  String forecastWindow(String from, String to) {
    return 'Orientation window: $from–$to';
  }

  @override
  String get selectServiceWork => 'Select one plan item';

  @override
  String get selectServiceWorkHint =>
      'Select exactly one applicable plan item.';

  @override
  String get wearSpecify => 'Enter wear';

  @override
  String get wearPercent => 'Wear, % (0 = no wear, 100 = fully worn)';

  @override
  String wearRemaining(int percent) {
    return 'Remaining: $percent%';
  }

  @override
  String wearMeasured(int percent) {
    return 'Measured wear: $percent%';
  }

  @override
  String get wearDate => 'Measurement date';

  @override
  String get wearSource => 'Measurement source';

  @override
  String get wearSourceSelf => 'Self-inspection';

  @override
  String get wearSourceWorkshop => 'Workshop';

  @override
  String get wearNote => 'Note (optional)';

  @override
  String get wearValidation => 'Enter wear from 0 to 100.';

  @override
  String get wearSaveError => 'Unable to save wear measurement.';

  @override
  String conditionObservationDateSource(String date, String source) {
    return '$date · $source';
  }
}

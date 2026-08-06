import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';

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
    Locale('pl'),
  ];

  /// Application name, shown in the launcher and title bar.
  ///
  /// In en, this message translates to:
  /// **'LubeLogger'**
  String get appTitle;

  /// Title of the login / server setup screen.
  ///
  /// In en, this message translates to:
  /// **'Connect to server'**
  String get connectToServer;

  /// No description provided for @setupIntro.
  ///
  /// In en, this message translates to:
  /// **'Enter your LubeLogger server address and API key to get started.'**
  String get setupIntro;

  /// No description provided for @serverAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Server address'**
  String get serverAddressLabel;

  /// No description provided for @serverAddressHint.
  ///
  /// In en, this message translates to:
  /// **'https://lubelogger.example.com'**
  String get serverAddressHint;

  /// No description provided for @serverAddressHelper.
  ///
  /// In en, this message translates to:
  /// **'Full URL of your LubeLogger instance.'**
  String get serverAddressHelper;

  /// No description provided for @apiKeyExplain.
  ///
  /// In en, this message translates to:
  /// **'Generate an API key in LubeLogger under Settings. Recommended: no expiry and scoped access.'**
  String get apiKeyExplain;

  /// No description provided for @apiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get apiKeyLabel;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connecting;

  /// Button on the login screen that fills in the demo credentials.
  ///
  /// In en, this message translates to:
  /// **'Try the demo'**
  String get tryDemo;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @garageEmpty.
  ///
  /// In en, this message translates to:
  /// **'No vehicles yet. Add your first one to get started.'**
  String get garageEmpty;

  /// No description provided for @garageLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your garage. Pull to retry.'**
  String get garageLoadError;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get settingsUnits;

  /// No description provided for @settingsCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get settingsCurrency;

  /// No description provided for @settingsDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get settingsDistance;

  /// No description provided for @settingsFuelEconomy.
  ///
  /// In en, this message translates to:
  /// **'Fuel economy'**
  String get settingsFuelEconomy;

  /// No description provided for @settingsDateFormat.
  ///
  /// In en, this message translates to:
  /// **'Date format'**
  String get settingsDateFormat;

  /// No description provided for @settingsDateSeparator.
  ///
  /// In en, this message translates to:
  /// **'Date separator'**
  String get settingsDateSeparator;

  /// No description provided for @settingsServer.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get settingsServer;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsStorageBase.
  ///
  /// In en, this message translates to:
  /// **'Server data'**
  String get settingsStorageBase;

  /// No description provided for @baseMetric.
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get baseMetric;

  /// No description provided for @baseImperial.
  ///
  /// In en, this message translates to:
  /// **'Imperial'**
  String get baseImperial;

  /// No description provided for @currencyAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic ({symbol})'**
  String currencyAuto(String symbol);

  /// No description provided for @settingsUnitsMetricNote.
  ///
  /// In en, this message translates to:
  /// **'Set the units your LubeLogger server stores values in (metric = km & litres). The app converts them to your chosen display units.'**
  String get settingsUnitsMetricNote;

  /// No description provided for @settingsVisibleTabs.
  ///
  /// In en, this message translates to:
  /// **'Visible tabs'**
  String get settingsVisibleTabs;

  /// No description provided for @settingsVisibleTabsNote.
  ///
  /// In en, this message translates to:
  /// **'Choose which record tabs appear on the vehicle screen and in the add menu, and drag to reorder them. The Dashboard is always shown first.'**
  String get settingsVisibleTabsNote;

  /// No description provided for @dashLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this vehicle. Pull to retry.'**
  String get dashLoadError;

  /// No description provided for @statDistanceTraveled.
  ///
  /// In en, this message translates to:
  /// **'Distance Traveled'**
  String get statDistanceTraveled;

  /// No description provided for @statTotalCost.
  ///
  /// In en, this message translates to:
  /// **'Total Cost'**
  String get statTotalCost;

  /// No description provided for @statAvgEconomy.
  ///
  /// In en, this message translates to:
  /// **'Average Fuel Economy'**
  String get statAvgEconomy;

  /// No description provided for @chartExpensesByType.
  ///
  /// In en, this message translates to:
  /// **'Expenses by Type'**
  String get chartExpensesByType;

  /// No description provided for @chartExpensesDistanceByMonth.
  ///
  /// In en, this message translates to:
  /// **'Expenses and Distance by Month'**
  String get chartExpensesDistanceByMonth;

  /// No description provided for @chartRemindersByUrgency.
  ///
  /// In en, this message translates to:
  /// **'Reminders by Urgency'**
  String get chartRemindersByUrgency;

  /// No description provided for @chartFuelMileageByMonth.
  ///
  /// In en, this message translates to:
  /// **'Fuel Mileage by Month'**
  String get chartFuelMileageByMonth;

  /// No description provided for @chartNoData.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get chartNoData;

  /// No description provided for @chartNoReminders.
  ///
  /// In en, this message translates to:
  /// **'No reminders'**
  String get chartNoReminders;

  /// No description provided for @legendExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get legendExpenses;

  /// No description provided for @legendDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get legendDistance;

  /// No description provided for @catService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get catService;

  /// No description provided for @catRepairs.
  ///
  /// In en, this message translates to:
  /// **'Repairs'**
  String get catRepairs;

  /// No description provided for @catUpgrades.
  ///
  /// In en, this message translates to:
  /// **'Upgrades'**
  String get catUpgrades;

  /// No description provided for @catFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get catFuel;

  /// No description provided for @catTax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get catTax;

  /// No description provided for @catSupply.
  ///
  /// In en, this message translates to:
  /// **'Supplies'**
  String get catSupply;

  /// No description provided for @catPlan.
  ///
  /// In en, this message translates to:
  /// **'Planner'**
  String get catPlan;

  /// No description provided for @catReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get catReminder;

  /// No description provided for @catNote.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get catNote;

  /// No description provided for @catEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get catEquipment;

  /// No description provided for @planPriorityCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get planPriorityCritical;

  /// No description provided for @planPriorityNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get planPriorityNormal;

  /// No description provided for @planPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get planPriorityLow;

  /// No description provided for @planProgressBacklog.
  ///
  /// In en, this message translates to:
  /// **'Backlog'**
  String get planProgressBacklog;

  /// No description provided for @planProgressInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get planProgressInProgress;

  /// No description provided for @planProgressTesting.
  ///
  /// In en, this message translates to:
  /// **'Testing'**
  String get planProgressTesting;

  /// No description provided for @planProgressDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get planProgressDone;

  /// No description provided for @equipmentEquipped.
  ///
  /// In en, this message translates to:
  /// **'Equipped'**
  String get equipmentEquipped;

  /// No description provided for @equipmentRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get equipmentRemoved;

  /// No description provided for @notePinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get notePinned;

  /// No description provided for @tabDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get tabDashboard;

  /// No description provided for @tabOdometer.
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get tabOdometer;

  /// No description provided for @colDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get colDate;

  /// No description provided for @colOdometer.
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get colOdometer;

  /// No description provided for @colDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get colDescription;

  /// No description provided for @colCost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get colCost;

  /// No description provided for @recordsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No records yet.'**
  String get recordsEmpty;

  /// No description provided for @fuelPillRecords.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 record} other{{count} records}}'**
  String fuelPillRecords(int count);

  /// No description provided for @fuelPillAvg.
  ///
  /// In en, this message translates to:
  /// **'Avg {value}'**
  String fuelPillAvg(String value);

  /// No description provided for @fuelPillMin.
  ///
  /// In en, this message translates to:
  /// **'Min {value}'**
  String fuelPillMin(String value);

  /// No description provided for @fuelPillMax.
  ///
  /// In en, this message translates to:
  /// **'Max {value}'**
  String fuelPillMax(String value);

  /// No description provided for @fuelPillDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance {value}'**
  String fuelPillDistance(String value);

  /// No description provided for @fuelPillFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel {value}'**
  String fuelPillFuel(String value);

  /// No description provided for @fuelPillCost.
  ///
  /// In en, this message translates to:
  /// **'Cost {value}'**
  String fuelPillCost(String value);

  /// No description provided for @addRecordTitle.
  ///
  /// In en, this message translates to:
  /// **'Add record'**
  String get addRecordTitle;

  /// No description provided for @formFuelTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Fuel Record'**
  String get formFuelTitle;

  /// No description provided for @formFuelEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Fuel Record'**
  String get formFuelEditTitle;

  /// No description provided for @formOdometerTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Odometer Reading'**
  String get formOdometerTitle;

  /// No description provided for @formOdometerEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Odometer Reading'**
  String get formOdometerEditTitle;

  /// No description provided for @formServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Service Record'**
  String get formServiceTitle;

  /// No description provided for @formServiceEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Service Record'**
  String get formServiceEditTitle;

  /// No description provided for @formRepairTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Repair Record'**
  String get formRepairTitle;

  /// No description provided for @formRepairEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Repair Record'**
  String get formRepairEditTitle;

  /// No description provided for @formUpgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Upgrade Record'**
  String get formUpgradeTitle;

  /// No description provided for @formUpgradeEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Upgrade Record'**
  String get formUpgradeEditTitle;

  /// No description provided for @formTaxTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Tax Record'**
  String get formTaxTitle;

  /// No description provided for @formTaxEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Tax Record'**
  String get formTaxEditTitle;

  /// No description provided for @formSupplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Supply Record'**
  String get formSupplyTitle;

  /// No description provided for @formSupplyEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Supply Record'**
  String get formSupplyEditTitle;

  /// No description provided for @formSupplyPartNumber.
  ///
  /// In en, this message translates to:
  /// **'Part number (optional)'**
  String get formSupplyPartNumber;

  /// No description provided for @formSupplyPartSupplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier (optional)'**
  String get formSupplyPartSupplier;

  /// No description provided for @formSupplyQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get formSupplyQuantity;

  /// No description provided for @formPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Planner Item'**
  String get formPlanTitle;

  /// No description provided for @formPlanEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Planner Item'**
  String get formPlanEditTitle;

  /// No description provided for @formPlanType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get formPlanType;

  /// No description provided for @formPlanPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get formPlanPriority;

  /// No description provided for @formPlanProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get formPlanProgress;

  /// No description provided for @formReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Reminder'**
  String get formReminderTitle;

  /// No description provided for @formReminderEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Reminder'**
  String get formReminderEditTitle;

  /// No description provided for @formReminderMetric.
  ///
  /// In en, this message translates to:
  /// **'Remind by'**
  String get formReminderMetric;

  /// No description provided for @formReminderMetricDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get formReminderMetricDate;

  /// No description provided for @formReminderMetricOdometer.
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get formReminderMetricOdometer;

  /// No description provided for @formReminderMetricBoth.
  ///
  /// In en, this message translates to:
  /// **'Date & odometer'**
  String get formReminderMetricBoth;

  /// No description provided for @formReminderDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get formReminderDueDate;

  /// No description provided for @formReminderDueOdometer.
  ///
  /// In en, this message translates to:
  /// **'Due odometer ({unit})'**
  String formReminderDueOdometer(String unit);

  /// No description provided for @formNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get formNoteTitle;

  /// No description provided for @formNoteEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Note'**
  String get formNoteEditTitle;

  /// No description provided for @formNoteTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get formNoteTitleLabel;

  /// No description provided for @formNoteBodyLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get formNoteBodyLabel;

  /// No description provided for @formNotePinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get formNotePinned;

  /// No description provided for @formEquipmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Equipment'**
  String get formEquipmentTitle;

  /// No description provided for @formEquipmentEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Equipment'**
  String get formEquipmentEditTitle;

  /// No description provided for @formEquipmentNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get formEquipmentNameLabel;

  /// No description provided for @formEquipmentEquipped.
  ///
  /// In en, this message translates to:
  /// **'Equipped'**
  String get formEquipmentEquipped;

  /// No description provided for @formVehicleTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Vehicle'**
  String get formVehicleTitle;

  /// No description provided for @formVehicleEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Vehicle'**
  String get formVehicleEditTitle;

  /// No description provided for @formVehicleYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get formVehicleYear;

  /// No description provided for @formVehicleMake.
  ///
  /// In en, this message translates to:
  /// **'Make'**
  String get formVehicleMake;

  /// No description provided for @formVehicleModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get formVehicleModel;

  /// No description provided for @formVehicleLicensePlate.
  ///
  /// In en, this message translates to:
  /// **'License plate'**
  String get formVehicleLicensePlate;

  /// No description provided for @formVehicleFuelType.
  ///
  /// In en, this message translates to:
  /// **'Fuel type'**
  String get formVehicleFuelType;

  /// No description provided for @formVehicleUseHours.
  ///
  /// In en, this message translates to:
  /// **'Track engine hours instead of odometer'**
  String get formVehicleUseHours;

  /// No description provided for @formVehicleOdometerOptional.
  ///
  /// In en, this message translates to:
  /// **'Odometer optional'**
  String get formVehicleOdometerOptional;

  /// No description provided for @fuelTypeGasoline.
  ///
  /// In en, this message translates to:
  /// **'Gasoline'**
  String get fuelTypeGasoline;

  /// No description provided for @fuelTypeDiesel.
  ///
  /// In en, this message translates to:
  /// **'Diesel'**
  String get fuelTypeDiesel;

  /// No description provided for @fuelTypeElectric.
  ///
  /// In en, this message translates to:
  /// **'Electric'**
  String get fuelTypeElectric;

  /// No description provided for @vehicleAdded.
  ///
  /// In en, this message translates to:
  /// **'Vehicle added'**
  String get vehicleAdded;

  /// No description provided for @vehicleAddError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add the vehicle. Try again.'**
  String get vehicleAddError;

  /// No description provided for @vehicleUpdated.
  ///
  /// In en, this message translates to:
  /// **'Vehicle updated'**
  String get vehicleUpdated;

  /// No description provided for @vehicleUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the vehicle. Try again.'**
  String get vehicleUpdateError;

  /// No description provided for @vehicleDeleted.
  ///
  /// In en, this message translates to:
  /// **'Vehicle deleted'**
  String get vehicleDeleted;

  /// No description provided for @vehicleDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the vehicle. Try again.'**
  String get vehicleDeleteError;

  /// No description provided for @confirmDeleteVehicleTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this vehicle?'**
  String get confirmDeleteVehicleTitle;

  /// No description provided for @confirmDeleteVehicleMessage.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes the vehicle and all of its records. This can\'t be undone.'**
  String get confirmDeleteVehicleMessage;

  /// No description provided for @confirmDeleteVehicleFinalTitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete {vehicle}?'**
  String confirmDeleteVehicleFinalTitle(String vehicle);

  /// No description provided for @confirmDeleteVehicleFinalMessage.
  ///
  /// In en, this message translates to:
  /// **'This is your last chance to cancel. The vehicle and every record for it will be gone for good.'**
  String get confirmDeleteVehicleFinalMessage;

  /// No description provided for @actionDeletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get actionDeletePermanently;

  /// No description provided for @vehicleDeleteUnsupportedTitle.
  ///
  /// In en, this message translates to:
  /// **'Server update required'**
  String get vehicleDeleteUnsupportedTitle;

  /// No description provided for @vehicleDeleteUnsupportedMessage.
  ///
  /// In en, this message translates to:
  /// **'Deleting a vehicle requires LubeLogger {required} or newer, but your server is running {current}. Update the server to use this.'**
  String vehicleDeleteUnsupportedMessage(String required, String current);

  /// No description provided for @actionOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get actionOk;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @formOdometerLabel.
  ///
  /// In en, this message translates to:
  /// **'Odometer reading ({unit})'**
  String formOdometerLabel(String unit);

  /// No description provided for @formFuelLabel.
  ///
  /// In en, this message translates to:
  /// **'Fuel consumed ({unit})'**
  String formFuelLabel(String unit);

  /// No description provided for @formFillToFull.
  ///
  /// In en, this message translates to:
  /// **'Filled to full'**
  String get formFillToFull;

  /// No description provided for @formMissedFuelUp.
  ///
  /// In en, this message translates to:
  /// **'Missed fuel-up (skip economy)'**
  String get formMissedFuelUp;

  /// No description provided for @formTagsOptional.
  ///
  /// In en, this message translates to:
  /// **'Tags (optional)'**
  String get formTagsOptional;

  /// No description provided for @formNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get formNotesOptional;

  /// No description provided for @attachmentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Attachments (optional)'**
  String get attachmentsLabel;

  /// No description provided for @attachmentAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add file'**
  String get attachmentAddButton;

  /// No description provided for @attachmentUploadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t upload the file. Try again.'**
  String get attachmentUploadError;

  /// No description provided for @attachmentOpenError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the file.'**
  String get attachmentOpenError;

  /// No description provided for @quickActionAddFuel.
  ///
  /// In en, this message translates to:
  /// **'Add fuel'**
  String get quickActionAddFuel;

  /// No description provided for @quickActionAddOdometer.
  ///
  /// In en, this message translates to:
  /// **'Add odometer'**
  String get quickActionAddOdometer;

  /// No description provided for @quickActionSelectVehicle.
  ///
  /// In en, this message translates to:
  /// **'Select vehicle'**
  String get quickActionSelectVehicle;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get validationRequired;

  /// No description provided for @validationNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get validationNumber;

  /// No description provided for @recordAdded.
  ///
  /// In en, this message translates to:
  /// **'Record added'**
  String get recordAdded;

  /// No description provided for @recordAddError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add the record. Try again.'**
  String get recordAddError;

  /// No description provided for @recordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Record updated'**
  String get recordUpdated;

  /// No description provided for @recordUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the record. Try again.'**
  String get recordUpdateError;

  /// No description provided for @recordDeleted.
  ///
  /// In en, this message translates to:
  /// **'Record deleted'**
  String get recordDeleted;

  /// No description provided for @recordDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the record. Try again.'**
  String get recordDeleteError;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this record?'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone.'**
  String get confirmDeleteMessage;

  /// No description provided for @urgencyNotUrgent.
  ///
  /// In en, this message translates to:
  /// **'Not Urgent'**
  String get urgencyNotUrgent;

  /// No description provided for @urgencyUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgencyUrgent;

  /// No description provided for @urgencyVeryUrgent.
  ///
  /// In en, this message translates to:
  /// **'Very Urgent'**
  String get urgencyVeryUrgent;

  /// No description provided for @urgencyPastDue.
  ///
  /// In en, this message translates to:
  /// **'Past Due'**
  String get urgencyPastDue;

  /// Confirmation after a successful connection.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {name}'**
  String signedInAs(String name);

  /// No description provided for @errMissingUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter the server address.'**
  String get errMissingUrl;

  /// No description provided for @errMissingApiKey.
  ///
  /// In en, this message translates to:
  /// **'Enter your API key.'**
  String get errMissingApiKey;

  /// No description provided for @errServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the server. Check the address and your network.'**
  String get errServerUnreachable;

  /// No description provided for @errUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed or the key lacks the required permission.'**
  String get errUnauthorized;

  /// No description provided for @errForbidden.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission for this action.'**
  String get errForbidden;

  /// No description provided for @errBadResponse.
  ///
  /// In en, this message translates to:
  /// **'Unexpected server response (HTTP {status}).'**
  String errBadResponse(int status);

  /// No description provided for @errBadCertificate.
  ///
  /// In en, this message translates to:
  /// **'The server\'s security certificate could not be verified.'**
  String get errBadCertificate;

  /// No description provided for @errConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection error. Please try again.'**
  String get errConnection;

  /// No description provided for @errMalformedResponse.
  ///
  /// In en, this message translates to:
  /// **'The server response could not be understood.'**
  String get errMalformedResponse;

  /// No description provided for @errInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid username or password.'**
  String get errInvalidCredentials;

  /// No description provided for @errApiKeyRejected.
  ///
  /// In en, this message translates to:
  /// **'The API key was rejected by the server.'**
  String get errApiKeyRejected;

  /// App version + build number, shown in Settings > About.
  ///
  /// In en, this message translates to:
  /// **'Version {version} ({build})'**
  String appVersion(String version, String build);

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get openSourceLicenses;

  /// No description provided for @serverVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Server version {version}'**
  String serverVersionLabel(String version);

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available: {version}'**
  String updateAvailable(String version);

  /// No description provided for @settingsBackup.
  ///
  /// In en, this message translates to:
  /// **'Create backup'**
  String get settingsBackup;

  /// No description provided for @backupCreated.
  ///
  /// In en, this message translates to:
  /// **'Backup created on the server.'**
  String get backupCreated;

  /// No description provided for @backupError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the backup. Try again.'**
  String get backupError;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleRoot.
  ///
  /// In en, this message translates to:
  /// **'Root'**
  String get roleRoot;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsNote.
  ///
  /// In en, this message translates to:
  /// **'Check for past-due reminders in the background (about every 3 hours) and post a notification. Each reminder notifies once until it\'s resolved.'**
  String get settingsNotificationsNote;

  /// No description provided for @notifRemindersToggle.
  ///
  /// In en, this message translates to:
  /// **'Past-due reminders'**
  String get notifRemindersToggle;

  /// No description provided for @notifPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notification permission is required. Enable it in system settings.'**
  String get notifPermissionDenied;

  /// No description provided for @notifReminderChannelName.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get notifReminderChannelName;

  /// No description provided for @notifReminderChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Past-due vehicle maintenance reminders'**
  String get notifReminderChannelDescription;

  /// No description provided for @notifReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder past due'**
  String get notifReminderTitle;

  /// No description provided for @notifReminderBody.
  ///
  /// In en, this message translates to:
  /// **'{vehicle}: {description}'**
  String notifReminderBody(String vehicle, String description);

  /// No description provided for @settingsDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get settingsDiagnostics;

  /// No description provided for @settingsDiagnosticsNote.
  ///
  /// In en, this message translates to:
  /// **'Record what the app does while you reproduce a problem, then review the log and save it or report it.'**
  String get settingsDiagnosticsNote;

  /// No description provided for @bugReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a bug'**
  String get bugReportTitle;

  /// No description provided for @bugReportIntroHeader.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get bugReportIntroHeader;

  /// No description provided for @bugReportIntroBody.
  ///
  /// In en, this message translates to:
  /// **'Start recording, reproduce the problem, then come back and finish. The app writes down what it does — screens you open, buttons you press, requests to the server and errors — so the report says more than “it does not work”.'**
  String get bugReportIntroBody;

  /// No description provided for @bugReportPrivacyHeader.
  ///
  /// In en, this message translates to:
  /// **'What ends up in the log'**
  String get bugReportPrivacyHeader;

  /// No description provided for @bugReportPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'Never your API key, your password or the text you type. Your server address is reduced to its shape: http or https, a name or an IP, and the port. What goes to the server and comes back keeps its field names, numbers and dates — plates, notes and anything you wrote are replaced by their length. It also notes your phone\'s model and Android version, and how you set units and date format, because a fix usually turns on one of those. You review everything before it leaves the phone.'**
  String get bugReportPrivacyBody;

  /// No description provided for @bugReportStart.
  ///
  /// In en, this message translates to:
  /// **'Start recording'**
  String get bugReportStart;

  /// No description provided for @bugReportRecordingHeader.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get bugReportRecordingHeader;

  /// No description provided for @bugReportRecordingBody.
  ///
  /// In en, this message translates to:
  /// **'Go back to the app and reproduce the problem. The recording bar stays with you — drag it aside or collapse it if it gets in the way, and use it to mark the moment it breaks and to finish.'**
  String get bugReportRecordingBody;

  /// No description provided for @bugReportLimit.
  ///
  /// In en, this message translates to:
  /// **'A recording stops by itself after {minutes} minutes.'**
  String bugReportLimit(int minutes);

  /// No description provided for @bugReportLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Recording finished — the {minutes} minute limit was reached.'**
  String bugReportLimitReached(int minutes);

  /// No description provided for @bugReportSizeLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Recording finished — the log reached its {megabytes} MB limit.'**
  String bugReportSizeLimitReached(int megabytes);

  /// No description provided for @bugReportMark.
  ///
  /// In en, this message translates to:
  /// **'Mark the moment'**
  String get bugReportMark;

  /// No description provided for @bugReportMarked.
  ///
  /// In en, this message translates to:
  /// **'Moment marked'**
  String get bugReportMarked;

  /// No description provided for @bugReportStop.
  ///
  /// In en, this message translates to:
  /// **'Finish recording'**
  String get bugReportStop;

  /// No description provided for @bugReportStopShort.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get bugReportStopShort;

  /// No description provided for @bugReportShow.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get bugReportShow;

  /// No description provided for @bugReportBannerLabel.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get bugReportBannerLabel;

  /// No description provided for @bugReportBarMove.
  ///
  /// In en, this message translates to:
  /// **'Move the recording bar'**
  String get bugReportBarMove;

  /// No description provided for @bugReportBarCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse the recording bar'**
  String get bugReportBarCollapse;

  /// No description provided for @bugReportBarExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand the recording bar'**
  String get bugReportBarExpand;

  /// No description provided for @bugReportRecoveredHeader.
  ///
  /// In en, this message translates to:
  /// **'A recording survived a crash'**
  String get bugReportRecoveredHeader;

  /// No description provided for @bugReportRecoveredBody.
  ///
  /// In en, this message translates to:
  /// **'The app closed while it was recording. What it had written down is still on the phone — look at it, or throw it away.'**
  String get bugReportRecoveredBody;

  /// No description provided for @bugReportReviewHeader.
  ///
  /// In en, this message translates to:
  /// **'Review before sending'**
  String get bugReportReviewHeader;

  /// No description provided for @bugReportReviewBody.
  ///
  /// In en, this message translates to:
  /// **'This is everything that was recorded. Read it through — below you choose whether it stays on the phone or goes out as a public issue.'**
  String get bugReportReviewBody;

  /// No description provided for @bugReportSummary.
  ///
  /// In en, this message translates to:
  /// **'{records} records · {errors} errors · {warnings} warnings'**
  String bugReportSummary(int records, int errors, int warnings);

  /// No description provided for @bugReportMarkers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 marked moment} other{{count} marked moments}}'**
  String bugReportMarkers(int count);

  /// No description provided for @bugReportTruncated.
  ///
  /// In en, this message translates to:
  /// **'The session was long — the oldest records were dropped.'**
  String get bugReportTruncated;

  /// No description provided for @bugReportEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing was recorded.'**
  String get bugReportEmpty;

  /// No description provided for @bugReportShowRaw.
  ///
  /// In en, this message translates to:
  /// **'Show raw log'**
  String get bugReportShowRaw;

  /// No description provided for @bugReportHideRaw.
  ///
  /// In en, this message translates to:
  /// **'Hide raw log'**
  String get bugReportHideRaw;

  /// No description provided for @bugReportRawClipped.
  ///
  /// In en, this message translates to:
  /// **'The first {kb} kB are not shown here. The file you save holds the whole session.'**
  String bugReportRawClipped(int kb);

  /// No description provided for @bugReportDestinationFile.
  ///
  /// In en, this message translates to:
  /// **'Save to a file'**
  String get bugReportDestinationFile;

  /// No description provided for @bugReportDestinationIssue.
  ///
  /// In en, this message translates to:
  /// **'Report on GitHub'**
  String get bugReportDestinationIssue;

  /// No description provided for @bugReportDestinationFileBody.
  ///
  /// In en, this message translates to:
  /// **'The log is saved where you choose and stays on your phone. You decide whether to send it anywhere.'**
  String get bugReportDestinationFileBody;

  /// No description provided for @bugReportDestinationIssueBody.
  ///
  /// In en, this message translates to:
  /// **'The log and your description are posted as a public issue on GitHub, where anyone can read them and they stay for good. Go through the log below first.'**
  String get bugReportDestinationIssueBody;

  /// No description provided for @bugReportDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'What went wrong?'**
  String get bugReportDescriptionLabel;

  /// No description provided for @bugReportDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'What you were doing, what you expected, what happened instead.'**
  String get bugReportDescriptionHint;

  /// No description provided for @bugReportDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Say what went wrong — a log with no description is nearly unusable.'**
  String get bugReportDescriptionRequired;

  /// No description provided for @bugReportSave.
  ///
  /// In en, this message translates to:
  /// **'Save to a file'**
  String get bugReportSave;

  /// No description provided for @bugReportSaveShort.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get bugReportSaveShort;

  /// No description provided for @bugReportSaved.
  ///
  /// In en, this message translates to:
  /// **'Log saved to the file'**
  String get bugReportSaved;

  /// No description provided for @bugReportSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The log could not be saved.'**
  String get bugReportSaveFailed;

  /// No description provided for @bugReportSend.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get bugReportSend;

  /// No description provided for @bugReportSending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get bugReportSending;

  /// No description provided for @bugReportSendWaiting.
  ///
  /// In en, this message translates to:
  /// **'Sending in {clock}'**
  String bugReportSendWaiting(String clock);

  /// No description provided for @bugReportSendWaitingBody.
  ///
  /// In en, this message translates to:
  /// **'The relay spaces reports out. You can leave this screen — it goes on its own.'**
  String get bugReportSendWaitingBody;

  /// No description provided for @bugReportSent.
  ///
  /// In en, this message translates to:
  /// **'Report sent'**
  String get bugReportSent;

  /// No description provided for @bugReportSentBody.
  ///
  /// In en, this message translates to:
  /// **'Thank you. The issue is open and the log is attached to it.'**
  String get bugReportSentBody;

  /// No description provided for @bugReportOpenIssue.
  ///
  /// In en, this message translates to:
  /// **'Open the issue'**
  String get bugReportOpenIssue;

  /// No description provided for @bugReportDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get bugReportDone;

  /// No description provided for @bugReportSendFailedNotYet.
  ///
  /// In en, this message translates to:
  /// **'The relay is not accepting reports right now. Try again later, or save the log to a file.'**
  String get bugReportSendFailedNotYet;

  /// No description provided for @bugReportSendFailedRefused.
  ///
  /// In en, this message translates to:
  /// **'The relay refused this report. Save the log to a file and attach it yourself.'**
  String get bugReportSendFailedRefused;

  /// No description provided for @bugReportSendFailedDuplicate.
  ///
  /// In en, this message translates to:
  /// **'This one has already been reported.'**
  String get bugReportSendFailedDuplicate;

  /// No description provided for @bugReportSendFailedUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the relay. Check the connection, or save the log to a file.'**
  String get bugReportSendFailedUnreachable;

  /// No description provided for @bugReportSendFailedRejected.
  ///
  /// In en, this message translates to:
  /// **'The relay rejected this report. Save the log to a file and attach it yourself.'**
  String get bugReportSendFailedRejected;

  /// No description provided for @bugReportSendFailedDemo.
  ///
  /// In en, this message translates to:
  /// **'Demo mode does not publish reports. Save the log to a file instead.'**
  String get bugReportSendFailedDemo;

  /// No description provided for @bugReportDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get bugReportDiscard;

  /// No description provided for @bugReportDiscardQuestion.
  ///
  /// In en, this message translates to:
  /// **'Discard this recording?'**
  String get bugReportDiscardQuestion;

  /// No description provided for @bugReportDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'The log will be deleted from the phone.'**
  String get bugReportDiscardBody;

  /// No description provided for @bugReportDiscardBodyQueued.
  ///
  /// In en, this message translates to:
  /// **'The log will be deleted from the phone and the queued report cancelled.'**
  String get bugReportDiscardBodyQueued;
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
      <String>['en', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

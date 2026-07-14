// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LubeLogger';

  @override
  String get connectToServer => 'Connect to server';

  @override
  String get setupIntro =>
      'Enter your LubeLogger server address and API key to get started.';

  @override
  String get serverAddressLabel => 'Server address';

  @override
  String get serverAddressHint => 'https://lubelogger.example.com';

  @override
  String get serverAddressHelper => 'Full URL of your LubeLogger instance.';

  @override
  String get apiKeyExplain =>
      'Generate an API key in LubeLogger under Settings. Recommended: no expiry and scoped access.';

  @override
  String get apiKeyLabel => 'API key';

  @override
  String get connect => 'Connect';

  @override
  String get connecting => 'Connecting…';

  @override
  String get logout => 'Log out';

  @override
  String get retry => 'Retry';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get garageEmpty =>
      'No vehicles yet. Add your first one to get started.';

  @override
  String get garageLoadError => 'Couldn\'t load your garage. Pull to retry.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsUnits => 'Units';

  @override
  String get settingsCurrency => 'Currency';

  @override
  String get settingsDistance => 'Distance';

  @override
  String get settingsFuelEconomy => 'Fuel economy';

  @override
  String get settingsDateFormat => 'Date format';

  @override
  String get settingsDateSeparator => 'Date separator';

  @override
  String get settingsServer => 'Server';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsStorageBase => 'Server data';

  @override
  String get baseMetric => 'Metric';

  @override
  String get baseImperial => 'Imperial';

  @override
  String currencyAuto(String symbol) {
    return 'Automatic ($symbol)';
  }

  @override
  String get settingsUnitsMetricNote =>
      'Set the units your LubeLogger server stores values in (metric = km & litres). The app converts them to your chosen display units.';

  @override
  String get settingsVisibleTabs => 'Visible tabs';

  @override
  String get settingsVisibleTabsNote =>
      'Choose which record tabs appear on the vehicle screen and in the add menu.';

  @override
  String get dashLoadError => 'Couldn\'t load this vehicle. Pull to retry.';

  @override
  String get statDistanceTraveled => 'Distance Traveled';

  @override
  String get statTotalCost => 'Total Cost';

  @override
  String get statAvgEconomy => 'Average Fuel Economy';

  @override
  String get chartExpensesByType => 'Expenses by Type';

  @override
  String get chartExpensesDistanceByMonth => 'Expenses and Distance by Month';

  @override
  String get chartRemindersByUrgency => 'Reminders by Urgency';

  @override
  String get chartFuelMileageByMonth => 'Fuel Mileage by Month';

  @override
  String get chartNoData => 'No data yet';

  @override
  String get chartNoReminders => 'No reminders';

  @override
  String get legendExpenses => 'Expenses';

  @override
  String get legendDistance => 'Distance';

  @override
  String get catService => 'Service';

  @override
  String get catRepairs => 'Repairs';

  @override
  String get catUpgrades => 'Upgrades';

  @override
  String get catFuel => 'Fuel';

  @override
  String get catTax => 'Tax';

  @override
  String get catSupply => 'Supplies';

  @override
  String get catPlan => 'Planner';

  @override
  String get catReminder => 'Reminders';

  @override
  String get catNote => 'Notes';

  @override
  String get catEquipment => 'Equipment';

  @override
  String get planPriorityCritical => 'Critical';

  @override
  String get planPriorityNormal => 'Normal';

  @override
  String get planPriorityLow => 'Low';

  @override
  String get planProgressBacklog => 'Backlog';

  @override
  String get planProgressInProgress => 'In progress';

  @override
  String get planProgressTesting => 'Testing';

  @override
  String get planProgressDone => 'Done';

  @override
  String get equipmentEquipped => 'Equipped';

  @override
  String get equipmentRemoved => 'Removed';

  @override
  String get notePinned => 'Pinned';

  @override
  String get tabDashboard => 'Dashboard';

  @override
  String get tabOdometer => 'Odometer';

  @override
  String get colDate => 'Date';

  @override
  String get colOdometer => 'Odometer';

  @override
  String get colDescription => 'Description';

  @override
  String get colCost => 'Cost';

  @override
  String get recordsEmpty => 'No records yet.';

  @override
  String fuelPillRecords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records',
      one: '1 record',
    );
    return '$_temp0';
  }

  @override
  String fuelPillAvg(String value) {
    return 'Avg $value';
  }

  @override
  String fuelPillMin(String value) {
    return 'Min $value';
  }

  @override
  String fuelPillMax(String value) {
    return 'Max $value';
  }

  @override
  String fuelPillDistance(String value) {
    return 'Distance $value';
  }

  @override
  String fuelPillFuel(String value) {
    return 'Fuel $value';
  }

  @override
  String fuelPillCost(String value) {
    return 'Cost $value';
  }

  @override
  String get addRecordTitle => 'Add record';

  @override
  String get formFuelTitle => 'Add Fuel Record';

  @override
  String get formFuelEditTitle => 'Edit Fuel Record';

  @override
  String formOdometerLabel(String unit) {
    return 'Odometer reading ($unit)';
  }

  @override
  String formFuelLabel(String unit) {
    return 'Fuel consumed ($unit)';
  }

  @override
  String get formFillToFull => 'Filled to full';

  @override
  String get formMissedFuelUp => 'Missed fuel-up (skip economy)';

  @override
  String get formTagsOptional => 'Tags (optional)';

  @override
  String get formNotesOptional => 'Notes (optional)';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionSave => 'Save';

  @override
  String get actionDelete => 'Delete';

  @override
  String get validationRequired => 'Required';

  @override
  String get validationNumber => 'Enter a valid number';

  @override
  String get recordAdded => 'Record added';

  @override
  String get recordAddError => 'Couldn\'t add the record. Try again.';

  @override
  String get recordUpdated => 'Record updated';

  @override
  String get recordUpdateError => 'Couldn\'t save the record. Try again.';

  @override
  String get recordDeleted => 'Record deleted';

  @override
  String get recordDeleteError => 'Couldn\'t delete the record. Try again.';

  @override
  String get confirmDeleteTitle => 'Delete this record?';

  @override
  String get confirmDeleteMessage => 'This can\'t be undone.';

  @override
  String get urgencyNotUrgent => 'Not Urgent';

  @override
  String get urgencyUrgent => 'Urgent';

  @override
  String get urgencyVeryUrgent => 'Very Urgent';

  @override
  String get urgencyPastDue => 'Past Due';

  @override
  String signedInAs(String name) {
    return 'Signed in as $name';
  }

  @override
  String get errMissingUrl => 'Enter the server address.';

  @override
  String get errMissingApiKey => 'Enter your API key.';

  @override
  String get errServerUnreachable =>
      'Cannot reach the server. Check the address and your network.';

  @override
  String get errUnauthorized =>
      'Authentication failed or the key lacks the required permission.';

  @override
  String get errForbidden => 'You do not have permission for this action.';

  @override
  String errBadResponse(int status) {
    return 'Unexpected server response (HTTP $status).';
  }

  @override
  String get errBadCertificate =>
      'The server\'s security certificate could not be verified.';

  @override
  String get errConnection => 'Connection error. Please try again.';

  @override
  String get errMalformedResponse =>
      'The server response could not be understood.';

  @override
  String get errInvalidCredentials => 'Invalid username or password.';

  @override
  String get errApiKeyRejected => 'The API key was rejected by the server.';

  @override
  String appVersion(String version, String build) {
    return 'Version $version ($build)';
  }

  @override
  String get openSourceLicenses => 'Open source licenses';
}

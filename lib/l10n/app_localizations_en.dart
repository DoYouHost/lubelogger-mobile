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
  String get tryDemo => 'Try the demo';

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
      'Choose which record tabs appear on the vehicle screen and in the add menu, and drag to reorder them. The Dashboard is always shown first.';

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
  String cardAttachments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attachments',
      one: '1 attachment',
    );
    return '$_temp0';
  }

  @override
  String get cardHasNote => 'Has a note';

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
  String get formOdometerTitle => 'Add Odometer Reading';

  @override
  String get formOdometerEditTitle => 'Edit Odometer Reading';

  @override
  String get formServiceTitle => 'Add Service Record';

  @override
  String get formServiceEditTitle => 'Edit Service Record';

  @override
  String get formRepairTitle => 'Add Repair Record';

  @override
  String get formRepairEditTitle => 'Edit Repair Record';

  @override
  String get formUpgradeTitle => 'Add Upgrade Record';

  @override
  String get formUpgradeEditTitle => 'Edit Upgrade Record';

  @override
  String get formTaxTitle => 'Add Tax Record';

  @override
  String get formTaxEditTitle => 'Edit Tax Record';

  @override
  String get formSupplyTitle => 'Add Supply Record';

  @override
  String get formSupplyEditTitle => 'Edit Supply Record';

  @override
  String get formSupplyPartNumber => 'Part number (optional)';

  @override
  String get formSupplyPartSupplier => 'Supplier (optional)';

  @override
  String get formSupplyQuantity => 'Quantity';

  @override
  String get formPlanTitle => 'Add Planner Item';

  @override
  String get formPlanEditTitle => 'Edit Planner Item';

  @override
  String get formPlanType => 'Type';

  @override
  String get formPlanPriority => 'Priority';

  @override
  String get formPlanProgress => 'Progress';

  @override
  String get formReminderTitle => 'Add Reminder';

  @override
  String get formReminderEditTitle => 'Edit Reminder';

  @override
  String get formReminderMetric => 'Remind by';

  @override
  String get formReminderMetricDate => 'Date';

  @override
  String get formReminderMetricOdometer => 'Odometer';

  @override
  String get formReminderMetricBoth => 'Date & odometer';

  @override
  String get formReminderDueDate => 'Due date';

  @override
  String formReminderDueOdometer(String unit) {
    return 'Due odometer ($unit)';
  }

  @override
  String get formNoteTitle => 'Add Note';

  @override
  String get formNoteEditTitle => 'Edit Note';

  @override
  String get formNoteTitleLabel => 'Title';

  @override
  String get formNoteBodyLabel => 'Note';

  @override
  String get formNotePinned => 'Pinned';

  @override
  String get formEquipmentTitle => 'Add Equipment';

  @override
  String get formEquipmentEditTitle => 'Edit Equipment';

  @override
  String get formEquipmentNameLabel => 'Name';

  @override
  String get formEquipmentEquipped => 'Equipped';

  @override
  String get formVehicleTitle => 'Add Vehicle';

  @override
  String get formVehicleEditTitle => 'Edit Vehicle';

  @override
  String get formVehicleYear => 'Year';

  @override
  String get formVehicleMake => 'Make';

  @override
  String get formVehicleModel => 'Model';

  @override
  String get formVehicleLicensePlate => 'License plate';

  @override
  String get formVehicleFuelType => 'Fuel type';

  @override
  String get formVehicleUseHours => 'Track engine hours instead of odometer';

  @override
  String get formVehicleOdometerOptional => 'Odometer optional';

  @override
  String get fuelTypeGasoline => 'Gasoline';

  @override
  String get fuelTypeDiesel => 'Diesel';

  @override
  String get fuelTypeElectric => 'Electric';

  @override
  String get vehicleAdded => 'Vehicle added';

  @override
  String get vehicleAddError => 'Couldn\'t add the vehicle. Try again.';

  @override
  String get vehicleUpdated => 'Vehicle updated';

  @override
  String get vehicleUpdateError => 'Couldn\'t save the vehicle. Try again.';

  @override
  String get vehicleDeleted => 'Vehicle deleted';

  @override
  String get vehicleDeleteError => 'Couldn\'t delete the vehicle. Try again.';

  @override
  String get confirmDeleteVehicleTitle => 'Delete this vehicle?';

  @override
  String get confirmDeleteVehicleMessage =>
      'This permanently deletes the vehicle and all of its records. This can\'t be undone.';

  @override
  String confirmDeleteVehicleFinalTitle(String vehicle) {
    return 'Permanently delete $vehicle?';
  }

  @override
  String get confirmDeleteVehicleFinalMessage =>
      'This is your last chance to cancel. The vehicle and every record for it will be gone for good.';

  @override
  String get actionDeletePermanently => 'Delete permanently';

  @override
  String get vehicleDeleteUnsupportedTitle => 'Server update required';

  @override
  String vehicleDeleteUnsupportedMessage(String required, String current) {
    return 'Deleting a vehicle requires LubeLogger $required or newer, but your server is running $current. Update the server to use this.';
  }

  @override
  String get actionOk => 'OK';

  @override
  String get actionEdit => 'Edit';

  @override
  String formOdometerLabel(String unit) {
    return 'Odometer reading ($unit)';
  }

  @override
  String formOdometerLast(String value) {
    return 'Last reading: $value';
  }

  @override
  String formOdometerBackwards(String value) {
    return 'Below the last reading ($value).';
  }

  @override
  String get formOdometerBackwardsTitle => 'Reading goes backwards';

  @override
  String formOdometerBackwardsMessage(String value) {
    return 'This reading is lower than the last one ($value). Odometers normally only go up. Save it anyway?';
  }

  @override
  String get actionSaveAnyway => 'Save anyway';

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
  String get attachmentsLabel => 'Attachments (optional)';

  @override
  String get attachmentAddButton => 'Add file';

  @override
  String get attachmentUploadError => 'Couldn\'t upload the file. Try again.';

  @override
  String get attachmentOpenError => 'Couldn\'t open the file.';

  @override
  String get extraFieldsLabel => 'Custom fields';

  @override
  String get formStateOfCharge => 'State of charge';

  @override
  String formStateOfChargeRange(int start, int end) {
    return '$start% → $end%';
  }

  @override
  String get quickActionAddFuel => 'Add fuel';

  @override
  String get quickActionAddOdometer => 'Add odometer';

  @override
  String get quickActionSelectVehicle => 'Select vehicle';

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
  String get errUnsupportedByServer =>
      'Your LubeLogger server is too old for this action. Update the server to use it.';

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

  @override
  String serverVersionLabel(String version) {
    return 'Server version $version';
  }

  @override
  String updateAvailable(String version) {
    return 'Update available: $version';
  }

  @override
  String get settingsBackup => 'Create backup';

  @override
  String get backupCreated => 'Backup created on the server.';

  @override
  String get backupError => 'Couldn\'t create the backup. Try again.';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleRoot => 'Root';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsNote =>
      'Check for past-due reminders in the background (about every 3 hours) and post a notification. Each reminder notifies once until it\'s resolved.';

  @override
  String get notifRemindersToggle => 'Past-due reminders';

  @override
  String get notifPermissionDenied =>
      'Notification permission is required. Enable it in system settings.';

  @override
  String get notifReminderChannelName => 'Reminders';

  @override
  String get notifReminderChannelDescription =>
      'Past-due vehicle maintenance reminders';

  @override
  String get notifReminderTitle => 'Reminder past due';

  @override
  String notifReminderBody(String vehicle, String description) {
    return '$vehicle: $description';
  }

  @override
  String get settingsDiagnostics => 'Bugs and ideas';

  @override
  String get settingsDiagnosticsNote =>
      'Report a bug with a recording of what the app was doing, or ask for a change or a new feature.';

  @override
  String get bugReportTitle => 'Report a bug or an idea';

  @override
  String get bugReportIntroHeader => 'How it works';

  @override
  String get bugReportPrivacyHeader => 'What ends up in the log';

  @override
  String get bugReportStart => 'Start recording';

  @override
  String get bugReportRecordingHeader => 'Recording';

  @override
  String get bugReportRecordingBody =>
      'Go back and reproduce it. The bar follows you — use it to mark the moment it breaks, and to finish.';

  @override
  String bugReportLimit(int minutes) {
    return 'A recording stops by itself after $minutes minutes.';
  }

  @override
  String bugReportLimitReached(int minutes) {
    return 'Recording finished — the $minutes minute limit was reached.';
  }

  @override
  String bugReportSizeLimitReached(int megabytes) {
    return 'Recording finished — the log reached its $megabytes MB limit.';
  }

  @override
  String get bugReportMark => 'Mark the moment';

  @override
  String get bugReportMarked => 'Moment marked';

  @override
  String get bugReportStop => 'Finish recording';

  @override
  String get bugReportStopShort => 'Finish';

  @override
  String get bugReportShow => 'Show';

  @override
  String get bugReportBannerLabel => 'Recording';

  @override
  String get bugReportBarMove => 'Move the recording bar';

  @override
  String get bugReportBarCollapse => 'Collapse the recording bar';

  @override
  String get bugReportBarExpand => 'Expand the recording bar';

  @override
  String get bugReportRecoveredHeader => 'A recording survived a crash';

  @override
  String get bugReportRecoveredBody =>
      'The app closed while it was recording. What it had written down is still on the phone — look at it, or throw it away.';

  @override
  String get bugReportReviewHeader => 'Review before sending';

  @override
  String get bugReportReviewBody =>
      'This is everything that was recorded. Read it through — below you choose whether it stays on the phone or goes out as a public issue.';

  @override
  String bugReportSummary(int records, int errors, int warnings) {
    return '$records records · $errors errors · $warnings warnings';
  }

  @override
  String bugReportMarkers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count marked moments',
      one: '1 marked moment',
    );
    return '$_temp0';
  }

  @override
  String get bugReportTruncated =>
      'The session was long — the oldest records were dropped.';

  @override
  String get bugReportEmpty => 'Nothing was recorded.';

  @override
  String get bugReportShowRaw => 'Show raw log';

  @override
  String get bugReportHideRaw => 'Hide raw log';

  @override
  String bugReportRawClipped(int kb) {
    return 'The first $kb kB are not shown here. The file you save holds the whole session.';
  }

  @override
  String get bugReportDestinationFile => 'Save to a file';

  @override
  String get bugReportDestinationIssue => 'Report on GitHub';

  @override
  String get bugReportDestinationFileBody =>
      'The log is saved where you choose and stays on your phone. You decide whether to send it anywhere.';

  @override
  String get bugReportDestinationIssueBody =>
      'The log and your description are posted as a public issue on GitHub, where anyone can read them and they stay for good. Go through the log below first.';

  @override
  String get bugReportDescriptionLabel => 'What went wrong?';

  @override
  String get bugReportDescriptionHint =>
      'What you were doing, what you expected, what happened instead.';

  @override
  String get bugReportDescriptionRequired =>
      'Say what went wrong — a log with no description is nearly unusable.';

  @override
  String get bugReportSave => 'Save to a file';

  @override
  String get bugReportSaveShort => 'Save';

  @override
  String get bugReportSaved => 'Log saved to the file';

  @override
  String get bugReportSaveFailed => 'The log could not be saved.';

  @override
  String get bugReportSend => 'Report';

  @override
  String get bugReportSending => 'Sending…';

  @override
  String bugReportSendWaiting(String clock) {
    return 'Sending in $clock';
  }

  @override
  String get bugReportSendWaitingBody =>
      'The relay spaces reports out. You can leave this screen — it goes on its own.';

  @override
  String get bugReportSent => 'Report sent';

  @override
  String get bugReportSentBody =>
      'Thank you. The issue is open and the log is attached to it.';

  @override
  String get bugReportOpenIssue => 'Open the issue';

  @override
  String get bugReportDone => 'Done';

  @override
  String get bugReportSendFailedNotYet =>
      'The relay is not accepting reports right now. Try again later, or save the log to a file.';

  @override
  String get bugReportSendFailedRefused =>
      'The relay refused this report. Save the log to a file and attach it yourself.';

  @override
  String get bugReportSendFailedDuplicate =>
      'This one has already been reported.';

  @override
  String get bugReportSendFailedUnreachable =>
      'Could not reach the relay. Check the connection, or save the log to a file.';

  @override
  String get bugReportSendFailedRejected =>
      'The relay rejected this report. Save the log to a file and attach it yourself.';

  @override
  String get bugReportSendFailedDemo =>
      'Demo mode does not publish reports. Save the log to a file instead.';

  @override
  String get bugReportDiscard => 'Discard';

  @override
  String get bugReportDiscardQuestion => 'Discard this recording?';

  @override
  String get bugReportDiscardBody => 'The log will be deleted from the phone.';

  @override
  String get bugReportDiscardBodyQueued =>
      'The log will be deleted from the phone and the queued report cancelled.';

  @override
  String get bugReportKindQuestion => 'What are you reporting?';

  @override
  String get bugReportKindBug => 'Bug';

  @override
  String get bugReportKindChange => 'Change';

  @override
  String get bugReportKindFeature => 'Feature';

  @override
  String get bugReportChangeHeader => 'Request a change';

  @override
  String get bugReportChangeBody =>
      'Something works, but not the way it should.';

  @override
  String get bugReportFeatureHeader => 'Request a feature';

  @override
  String get bugReportFeatureBody => 'Something the app cannot do yet.';

  @override
  String get bugReportRequestPrivacyHeader => 'What gets sent';

  @override
  String get bugReportChangeLabel => 'What should change?';

  @override
  String get bugReportChangeHint =>
      'What it does now, and what it should do instead.';

  @override
  String get bugReportFeatureLabel => 'What is missing?';

  @override
  String get bugReportFeatureHint =>
      'What you want to do, and why the app does not let you.';

  @override
  String get bugReportRequestRequired =>
      'Write what you are asking for — an empty request cannot be acted on.';

  @override
  String get bugReportRequestSentBody => 'Thank you. The issue is open.';

  @override
  String get bugReportCancelSend => 'Cancel sending';

  @override
  String get bugReportStepRecord => 'Start recording';

  @override
  String get bugReportStepReproduce => 'Reproduce the problem';

  @override
  String get bugReportStepFinish => 'Come back and finish';

  @override
  String get bugReportLogScreens => 'Screens you open and buttons you press';

  @override
  String get bugReportLogRequests => 'Requests to the server and its answers';

  @override
  String get bugReportLogErrors => 'Errors, including the ones you never see';

  @override
  String get bugReportLogSetup =>
      'App and server version, your phone, your units and date format';

  @override
  String get bugReportLogNoKey => 'Your API key or password';

  @override
  String get bugReportLogNoTyping => 'The text you type';

  @override
  String get bugReportLogNoAddress =>
      'Your server address — only http or https, name or IP, and the port';

  @override
  String get bugReportLogNoData =>
      'Plates, notes, your records — only how long they were';

  @override
  String get bugReportReviewFirst =>
      'You read all of it before it leaves the phone.';

  @override
  String get bugReportRequestWhatYouWrite => 'What you write';

  @override
  String get bugReportRequestVersions => 'App and server version';

  @override
  String get bugReportRequestNoLog => 'No log, no recording';

  @override
  String get bugReportRequestNoData =>
      'Nothing about your vehicles or your phone';

  @override
  String get bugReportRequestPublic =>
      'It becomes a public issue on GitHub — anyone can read it, and it stays.';

  @override
  String fuelPillEnergy(String value) {
    return 'Energy $value';
  }

  @override
  String formEnergyLabel(String unit) {
    return 'Energy charged ($unit)';
  }

  @override
  String get statAvgConsumption => 'Average Consumption';

  @override
  String get chartConsumptionByMonth => 'Consumption by Month';

  @override
  String get planDoneReadOnly =>
      'This plan is done. LubeLogger\'s API refuses to store a finished plan, and every state it would accept sends it backwards — so it can be read and deleted here, but not edited. Change it on the planner board.';

  @override
  String get syncTitle => 'Sync';

  @override
  String get syncOffline => 'The server isn\'t answering.';

  @override
  String syncLastContact(String time) {
    return 'Server last answered $time.';
  }

  @override
  String syncPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes waiting to be sent',
      one: '1 change waiting to be sent',
    );
    return '$_temp0';
  }

  @override
  String get syncNothingPending =>
      'Everything you have saved is on the server.';

  @override
  String get syncSendNow => 'Send now';

  @override
  String get syncSending => 'Sending…';

  @override
  String syncSentResult(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes sent',
      one: '1 change sent',
    );
    return '$_temp0';
  }

  @override
  String get syncStillOffline =>
      'Still no answer from the server — they stay queued.';

  @override
  String syncAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attempts',
      one: '1 attempt',
    );
    return '$_temp0';
  }

  @override
  String get syncRejectedTitle => 'Refused by the server';

  @override
  String get syncRejectedExplain =>
      'The server answered and turned these down, so sending them again would only repeat it. Read why, then dismiss.';

  @override
  String get syncDiscard => 'Discard';

  @override
  String get syncDiscardAll => 'Discard all';

  @override
  String syncOpAdd(String type) {
    return 'Add $type';
  }

  @override
  String syncOpUpdate(String type) {
    return 'Edit $type';
  }

  @override
  String syncOpDelete(String type) {
    return 'Delete $type';
  }

  @override
  String get syncTypeVehicle => 'Vehicle';

  @override
  String get syncPendingTooltip => 'Changes waiting to be sent';

  @override
  String get syncOfflineTooltip => 'No connection to the server';

  @override
  String get settingsOfflineSection => 'Offline';

  @override
  String get settingsBackgroundRefresh => 'Refresh in the background';

  @override
  String get settingsBackgroundRefreshSub =>
      'Keeps the stored copy current, so the app opens on your records instead of a spinner.';

  @override
  String get settingsStoredData => 'Stored data';

  @override
  String settingsStoredDataSize(String size) {
    return '$size on this phone';
  }

  @override
  String get settingsClearStoredData => 'Clear';

  @override
  String get settingsStoredDataCleared => 'Stored data cleared.';
}

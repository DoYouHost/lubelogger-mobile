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

  /// No description provided for @settingsServer.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get settingsServer;

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

  /// No description provided for @dashLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this vehicle. Pull to retry.'**
  String get dashLoadError;

  /// No description provided for @statLastOdometer.
  ///
  /// In en, this message translates to:
  /// **'Last Reported Odometer'**
  String get statLastOdometer;

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

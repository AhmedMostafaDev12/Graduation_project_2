import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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
    Locale('ar'),
  ];

  /// Caregiver shell C1 destination
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get caregiverHome;

  /// Caregiver shell C3 destination
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get caregiverPeople;

  /// Reminders destination in both shells
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// Caregiver shell C18 destination
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get caregiverMore;

  /// Accessible label for caregiver center action opening C9
  ///
  /// In en, this message translates to:
  /// **'Add reminder'**
  String get addReminder;

  /// Patient shell P1 destination
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get patientToday;

  /// Patient shell P4 destination
  ///
  /// In en, this message translates to:
  /// **'My Day'**
  String get patientMyDay;

  /// Patient shell P7 destination
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get patientGames;

  /// Accessible label for patient center action opening P6
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get ask;

  /// App brand accessibility label
  ///
  /// In en, this message translates to:
  /// **'Remori'**
  String get appName;

  /// A0 two-line tagline
  ///
  /// In en, this message translates to:
  /// **'A quiet layer of memory\nthat stays with you.'**
  String get splashTagline;

  /// A0 button opening A1
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// A0 support caption
  ///
  /// In en, this message translates to:
  /// **'Support for everyday moments.'**
  String get splashSupport;

  /// A1 introduction
  ///
  /// In en, this message translates to:
  /// **'Memory support for people living with Alzheimer\'s, and for the people who care for them.'**
  String get modeSelectIntro;

  /// A1 caregiver choice opening A2
  ///
  /// In en, this message translates to:
  /// **'I\'m a caregiver'**
  String get modeCaregiver;

  /// A1 patient phone choice opening A2 for caregiver setup
  ///
  /// In en, this message translates to:
  /// **'This is the patient\'s phone'**
  String get modePatientPhone;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Caregiver Log in'**
  String get loginTitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailHint;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get forgotPassword;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get logIn;

  /// No description provided for @loggingIn.
  ///
  /// In en, this message translates to:
  /// **'Logging in…'**
  String get loggingIn;

  /// No description provided for @orLabel.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orLabel;

  /// No description provided for @continueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueGoogle;

  /// No description provided for @continueFacebook.
  ///
  /// In en, this message translates to:
  /// **'Continue with Facebook'**
  String get continueFacebook;

  /// No description provided for @patientPhoneSetup.
  ///
  /// In en, this message translates to:
  /// **'Setting up patient phone for the first time?'**
  String get patientPhoneSetup;

  /// No description provided for @logInSetupPatient.
  ///
  /// In en, this message translates to:
  /// **'Log In and set up for a patient'**
  String get logInSetupPatient;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// No description provided for @loginInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password'**
  String get loginInvalidCredentials;

  /// No description provided for @loginConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again'**
  String get loginConnectionError;

  /// No description provided for @loginRetry.
  ///
  /// In en, this message translates to:
  /// **'Unable to log in. Please try again in a moment.'**
  String get loginRetry;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

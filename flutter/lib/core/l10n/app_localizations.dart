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

  /// No description provided for @signupTitle.
  ///
  /// In en, this message translates to:
  /// **'Caregiver sign up'**
  String get signupTitle;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullNameLabel;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get fullNameHint;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'+201000000000'**
  String get phoneHint;

  /// No description provided for @alreadyAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyAccount;

  /// No description provided for @signupLogIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get signupLogIn;

  /// No description provided for @signingUp.
  ///
  /// In en, this message translates to:
  /// **'Signing up…'**
  String get signingUp;

  /// No description provided for @signupPasswordLength.
  ///
  /// In en, this message translates to:
  /// **'Use 8–128 characters'**
  String get signupPasswordLength;

  /// No description provided for @signupEmailTaken.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists. Please log in.'**
  String get signupEmailTaken;

  /// No description provided for @signupCheckFields.
  ///
  /// In en, this message translates to:
  /// **'Check the highlighted fields and try again.'**
  String get signupCheckFields;

  /// No description provided for @signupInvalidField.
  ///
  /// In en, this message translates to:
  /// **'Check this field'**
  String get signupInvalidField;

  /// No description provided for @signupRetry.
  ///
  /// In en, this message translates to:
  /// **'Unable to sign up. Please try again in a moment.'**
  String get signupRetry;

  /// No description provided for @signupAccountCreated.
  ///
  /// In en, this message translates to:
  /// **'Your account was created. Please log in to continue.'**
  String get signupAccountCreated;

  /// No description provided for @newPatient.
  ///
  /// In en, this message translates to:
  /// **'New patient'**
  String get newPatient;

  /// No description provided for @patientStepOne.
  ///
  /// In en, this message translates to:
  /// **'Step 1 of 3'**
  String get patientStepOne;

  /// No description provided for @patientName.
  ///
  /// In en, this message translates to:
  /// **'Patient\'s full name'**
  String get patientName;

  /// No description provided for @patientNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter patient\'s full name'**
  String get patientNameHint;

  /// No description provided for @patientRelationship.
  ///
  /// In en, this message translates to:
  /// **'Your relationship to the patient'**
  String get patientRelationship;

  /// No description provided for @patientBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Date of birth (optional)'**
  String get patientBirthDate;

  /// No description provided for @patientDateHint.
  ///
  /// In en, this message translates to:
  /// **'DD / MM / YYYY'**
  String get patientDateHint;

  /// No description provided for @patientLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preferred language'**
  String get patientLanguage;

  /// No description provided for @patientEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get patientEnglish;

  /// No description provided for @patientArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية Arabic'**
  String get patientArabic;

  /// No description provided for @patientTimezone.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get patientTimezone;

  /// No description provided for @patientConsent.
  ///
  /// In en, this message translates to:
  /// **'Consent'**
  String get patientConsent;

  /// No description provided for @conversationMemory.
  ///
  /// In en, this message translates to:
  /// **'Conversation memory'**
  String get conversationMemory;

  /// No description provided for @conversationMemoryDetail.
  ///
  /// In en, this message translates to:
  /// **'The household agrees to conversation memory. Audio is deleted after transcription.'**
  String get conversationMemoryDetail;

  /// No description provided for @cloudProcessing.
  ///
  /// In en, this message translates to:
  /// **'Allow Cloud AI processing'**
  String get cloudProcessing;

  /// No description provided for @cloudProcessingDetail.
  ///
  /// In en, this message translates to:
  /// **'Transcription, photo review, and summaries'**
  String get cloudProcessingDetail;

  /// No description provided for @consentLater.
  ///
  /// In en, this message translates to:
  /// **'Consent can be changed or revoked later in More → Consent.'**
  String get consentLater;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @patientCreating.
  ///
  /// In en, this message translates to:
  /// **'Creating patient…'**
  String get patientCreating;

  /// No description provided for @patientCreateRetry.
  ///
  /// In en, this message translates to:
  /// **'Unable to create the patient. Please try again in a moment.'**
  String get patientCreateRetry;

  /// No description provided for @patientInvalidDate.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid date as DD / MM / YYYY'**
  String get patientInvalidDate;

  /// No description provided for @patientLoginAgain.
  ///
  /// In en, this message translates to:
  /// **'Please log in again to continue.'**
  String get patientLoginAgain;

  /// No description provided for @pairGlasses.
  ///
  /// In en, this message translates to:
  /// **'Pair glasses'**
  String get pairGlasses;

  /// No description provided for @pairStepTwo.
  ///
  /// In en, this message translates to:
  /// **'Step 2 of 3'**
  String get pairStepTwo;

  /// No description provided for @pairScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan glasses QR code'**
  String get pairScanTitle;

  /// No description provided for @pairScanPosition.
  ///
  /// In en, this message translates to:
  /// **'Position the code inside the scan area.'**
  String get pairScanPosition;

  /// No description provided for @pairCameraHint.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at the QR code on the glasses case.'**
  String get pairCameraHint;

  /// No description provided for @pairScanButton.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get pairScanButton;

  /// No description provided for @pairContinueHint.
  ///
  /// In en, this message translates to:
  /// **'You can continue after your glasses are linked.'**
  String get pairContinueHint;

  /// No description provided for @pairScanStep.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code'**
  String get pairScanStep;

  /// No description provided for @pairScanStepDetail.
  ///
  /// In en, this message translates to:
  /// **'Read the code on the glasses case.'**
  String get pairScanStepDetail;

  /// No description provided for @pairConnectStep.
  ///
  /// In en, this message translates to:
  /// **'Connect securely'**
  String get pairConnectStep;

  /// No description provided for @pairBluetoothPending.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth connection is still pending.'**
  String get pairBluetoothPending;

  /// No description provided for @pairConfirmStep.
  ///
  /// In en, this message translates to:
  /// **'Confirm pairing'**
  String get pairConfirmStep;

  /// No description provided for @pairConfirmDetail.
  ///
  /// In en, this message translates to:
  /// **'Associate the glasses with this patient.'**
  String get pairConfirmDetail;

  /// No description provided for @pairDeviceStatus.
  ///
  /// In en, this message translates to:
  /// **'Device status'**
  String get pairDeviceStatus;

  /// No description provided for @pairStatusInitial.
  ///
  /// In en, this message translates to:
  /// **'Your pairing status and device details will appear here.'**
  String get pairStatusInitial;

  /// No description provided for @pairLinkedPending.
  ///
  /// In en, this message translates to:
  /// **'Glasses linked. Bluetooth connection is still pending.'**
  String get pairLinkedPending;

  /// No description provided for @pairNeedsPatient.
  ///
  /// In en, this message translates to:
  /// **'Return to patient setup to continue.'**
  String get pairNeedsPatient;

  /// No description provided for @pairLinking.
  ///
  /// In en, this message translates to:
  /// **'Linking glasses…'**
  String get pairLinking;

  /// No description provided for @pairAlreadyPaired.
  ///
  /// In en, this message translates to:
  /// **'These glasses are paired with someone else.'**
  String get pairAlreadyPaired;

  /// No description provided for @pairPatientMissing.
  ///
  /// In en, this message translates to:
  /// **'This patient is no longer available. Return to patient setup.'**
  String get pairPatientMissing;

  /// No description provided for @pairInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Check the QR code on the glasses case and try again.'**
  String get pairInvalidCode;

  /// No description provided for @pairSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The glasses were linked, but saving on this phone failed. Please retry.'**
  String get pairSaveFailed;

  /// No description provided for @pairRetrySave.
  ///
  /// In en, this message translates to:
  /// **'Retry pairing'**
  String get pairRetrySave;

  /// No description provided for @pairRetry.
  ///
  /// In en, this message translates to:
  /// **'Unable to link the glasses. Please try again in a moment.'**
  String get pairRetry;

  /// No description provided for @pairCameraPermission.
  ///
  /// In en, this message translates to:
  /// **'Allow camera access in your phone settings, then scan again.'**
  String get pairCameraPermission;

  /// No description provided for @pairCameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The camera is unavailable. Please try scanning again.'**
  String get pairCameraUnavailable;

  /// Scanned glasses-case serial in A5 status; never a device token
  ///
  /// In en, this message translates to:
  /// **'Serial: {serial}'**
  String pairSerial(String serial);

  /// No description provided for @permissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissionsTitle;

  /// No description provided for @permissionsStep.
  ///
  /// In en, this message translates to:
  /// **'Step 3 of 3'**
  String get permissionsStep;

  /// No description provided for @permissionsIntro.
  ///
  /// In en, this message translates to:
  /// **'Remori needs these permissions to help keep the glasses connected throughout the day.'**
  String get permissionsIntro;

  /// No description provided for @permissionsCaregiverIntro.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications to receive reminders on this phone.'**
  String get permissionsCaregiverIntro;

  /// No description provided for @permissionBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth'**
  String get permissionBluetooth;

  /// No description provided for @permissionBluetoothDetail.
  ///
  /// In en, this message translates to:
  /// **'Connect to the glasses'**
  String get permissionBluetoothDetail;

  /// No description provided for @permissionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get permissionNotifications;

  /// No description provided for @permissionNotificationsDetail.
  ///
  /// In en, this message translates to:
  /// **'Receive reminders on the phone'**
  String get permissionNotificationsDetail;

  /// No description provided for @permissionLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get permissionLocation;

  /// No description provided for @permissionLocationDetail.
  ///
  /// In en, this message translates to:
  /// **'For location-related assistance'**
  String get permissionLocationDetail;

  /// No description provided for @permissionBackground.
  ///
  /// In en, this message translates to:
  /// **'Background activity'**
  String get permissionBackground;

  /// No description provided for @permissionBackgroundDetail.
  ///
  /// In en, this message translates to:
  /// **'Keep the glasses connected and syncing'**
  String get permissionBackgroundDetail;

  /// No description provided for @permissionGranted.
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get permissionGranted;

  /// No description provided for @permissionAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get permissionAllow;

  /// No description provided for @permissionChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get permissionChecking;

  /// No description provided for @permissionLimited.
  ///
  /// In en, this message translates to:
  /// **'Limited access'**
  String get permissionLimited;

  /// No description provided for @permissionSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get permissionSettings;

  /// No description provided for @permissionsHandoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready for handover?'**
  String get permissionsHandoverTitle;

  /// No description provided for @permissionsHandoverPending.
  ///
  /// In en, this message translates to:
  /// **'Patient handover will be available when the glasses connection is ready. You can continue in caregiver mode now.'**
  String get permissionsHandoverPending;

  /// No description provided for @permissionsPatientMode.
  ///
  /// In en, this message translates to:
  /// **'Give phone to patient → patient mode'**
  String get permissionsPatientMode;

  /// No description provided for @permissionsCaregiverMode.
  ///
  /// In en, this message translates to:
  /// **'Continue on caregiver mode'**
  String get permissionsCaregiverMode;

  /// No description provided for @permissionsReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to update permissions. Please try again.'**
  String get permissionsReadFailed;

  /// No description provided for @permissionsUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Manage permissions on an Android or iOS phone. You can continue in caregiver mode.'**
  String get permissionsUnsupported;

  /// No description provided for @permissionsHandoverReady.
  ///
  /// In en, this message translates to:
  /// **'Once setup is complete, hand this phone to the patient to enter Patient Mode.'**
  String get permissionsHandoverReady;

  /// No description provided for @permissionsHandoverFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to enter Patient Mode. Check your connection and try again.'**
  String get permissionsHandoverFailed;
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

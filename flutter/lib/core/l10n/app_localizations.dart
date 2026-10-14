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

  /// No description provided for @homeSwitchPatient.
  ///
  /// In en, this message translates to:
  /// **'Switch patient'**
  String get homeSwitchPatient;

  /// No description provided for @homeLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading Home…'**
  String get homeLoading;

  /// No description provided for @homeLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load Home. Check your connection and try again.'**
  String get homeLoadFailed;

  /// No description provided for @homeOffline.
  ///
  /// In en, this message translates to:
  /// **'Showing saved data. Unable to update Home.'**
  String get homeOffline;

  /// No description provided for @homeRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get homeRetry;

  /// No description provided for @homeNoPatients.
  ///
  /// In en, this message translates to:
  /// **'No patients are linked to your account yet.'**
  String get homeNoPatients;

  /// No description provided for @homeGlasses.
  ///
  /// In en, this message translates to:
  /// **'Glasses'**
  String get homeGlasses;

  /// No description provided for @homeConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get homeConnected;

  /// No description provided for @homeDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get homeDisconnected;

  /// No description provided for @homeNotPaired.
  ///
  /// In en, this message translates to:
  /// **'Not paired'**
  String get homeNotPaired;

  /// No description provided for @homeUnknown.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get homeUnknown;

  /// No description provided for @homeMemoryOff.
  ///
  /// In en, this message translates to:
  /// **'Memory: Off'**
  String get homeMemoryOff;

  /// No description provided for @homeMemoryPaused.
  ///
  /// In en, this message translates to:
  /// **'Memory: Paused'**
  String get homeMemoryPaused;

  /// No description provided for @homeMemoryCapturing.
  ///
  /// In en, this message translates to:
  /// **'Memory: Capturing'**
  String get homeMemoryCapturing;

  /// No description provided for @homeMemoryEnabled.
  ///
  /// In en, this message translates to:
  /// **'Memory: Enabled'**
  String get homeMemoryEnabled;

  /// No description provided for @homeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get homeJustNow;

  /// No description provided for @homeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =0{just now} =1{1 min ago} other{{minutes} min ago}}'**
  String homeMinutesAgo(int minutes);

  /// No description provided for @homeDeviceDetail.
  ///
  /// In en, this message translates to:
  /// **'Last seen {time} · Battery {battery}'**
  String homeDeviceDetail(String time, String battery);

  /// No description provided for @homeOpenJournal.
  ///
  /// In en, this message translates to:
  /// **'Open journal ›'**
  String get homeOpenJournal;

  /// No description provided for @homeCachedDay.
  ///
  /// In en, this message translates to:
  /// **'Saved statistics for {date}'**
  String homeCachedDay(String date);

  /// No description provided for @homePeopleMet.
  ///
  /// In en, this message translates to:
  /// **'people met'**
  String get homePeopleMet;

  /// No description provided for @homeRemindersDone.
  ///
  /// In en, this message translates to:
  /// **'reminders done'**
  String get homeRemindersDone;

  /// No description provided for @homeSnoozed.
  ///
  /// In en, this message translates to:
  /// **'snoozed'**
  String get homeSnoozed;

  /// No description provided for @homeReminderProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} / {total}'**
  String homeReminderProgress(String done, String total);

  /// No description provided for @homeAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get homeAlerts;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// No description provided for @homeNoAlerts.
  ///
  /// In en, this message translates to:
  /// **'No recent alerts for this patient.'**
  String get homeNoAlerts;

  /// No description provided for @homeMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get homeMissed;

  /// No description provided for @homeNewFace.
  ///
  /// In en, this message translates to:
  /// **'New face'**
  String get homeNewFace;

  /// No description provided for @homeLowBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get homeLowBattery;

  /// No description provided for @homeSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get homeSummary;

  /// No description provided for @homeAlert.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get homeAlert;

  /// No description provided for @homeDailySummary.
  ///
  /// In en, this message translates to:
  /// **'AI daily summary'**
  String get homeDailySummary;

  /// No description provided for @homePhaseTwo.
  ///
  /// In en, this message translates to:
  /// **'Phase 2'**
  String get homePhaseTwo;

  /// No description provided for @homeSummaryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Daily summaries will be available in Phase 2.'**
  String get homeSummaryUnavailable;

  /// No description provided for @homeReadMore.
  ///
  /// In en, this message translates to:
  /// **'Read more ›'**
  String get homeReadMore;

  /// No description provided for @peopleAdd.
  ///
  /// In en, this message translates to:
  /// **'+ Add person'**
  String get peopleAdd;

  /// No description provided for @peopleActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get peopleActiveLabel;

  /// No description provided for @peopleActive.
  ///
  /// In en, this message translates to:
  /// **'Active ({count})'**
  String peopleActive(String count);

  /// No description provided for @peopleArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get peopleArchived;

  /// No description provided for @peopleReviewCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new face to review} other{{count} new faces to review}}'**
  String peopleReviewCount(int count);

  /// No description provided for @peopleLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading people…'**
  String get peopleLoading;

  /// No description provided for @peopleLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load people. Check your connection and try again.'**
  String get peopleLoadFailed;

  /// No description provided for @peopleOffline.
  ///
  /// In en, this message translates to:
  /// **'Showing saved people. Unable to update the list.'**
  String get peopleOffline;

  /// No description provided for @peopleNoActive.
  ///
  /// In en, this message translates to:
  /// **'No active people have been added yet.'**
  String get peopleNoActive;

  /// No description provided for @peopleNoArchived.
  ///
  /// In en, this message translates to:
  /// **'No archived people.'**
  String get peopleNoArchived;

  /// No description provided for @peopleSon.
  ///
  /// In en, this message translates to:
  /// **'Son'**
  String get peopleSon;

  /// No description provided for @peopleDaughter.
  ///
  /// In en, this message translates to:
  /// **'Daughter'**
  String get peopleDaughter;

  /// No description provided for @peopleDoctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get peopleDoctor;

  /// No description provided for @peopleNurse.
  ///
  /// In en, this message translates to:
  /// **'Nurse'**
  String get peopleNurse;

  /// No description provided for @personUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Select a patient you manage from Home, then try again.'**
  String get personUnavailable;

  /// No description provided for @personAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add person'**
  String get personAddTitle;

  /// No description provided for @personPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos (1–5)'**
  String get personPhotos;

  /// No description provided for @personCamera.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get personCamera;

  /// No description provided for @personGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get personGallery;

  /// No description provided for @personRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get personRemovePhoto;

  /// No description provided for @personPhotoSlot.
  ///
  /// In en, this message translates to:
  /// **'Photo {number}'**
  String personPhotoSlot(int number);

  /// No description provided for @personPhotoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Choose a photo no larger than 4 MB.'**
  String get personPhotoTooLarge;

  /// No description provided for @personPhotoUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Choose a JPEG or PNG photo.'**
  String get personPhotoUnsupported;

  /// No description provided for @personPhotoPickFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the photo. Check permissions and try again.'**
  String get personPhotoPickFailed;

  /// No description provided for @personPhotosRequired.
  ///
  /// In en, this message translates to:
  /// **'Add at least one photo.'**
  String get personPhotosRequired;

  /// No description provided for @personPhotoInvalid.
  ///
  /// In en, this message translates to:
  /// **'Photo {number}: unable to use this photo. Please replace it.'**
  String personPhotoInvalid(int number);

  /// No description provided for @personPhotoTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: a clear face, good light, one person per photo. Different angles help.'**
  String get personPhotoTip;

  /// No description provided for @personName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get personName;

  /// No description provided for @personNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter full name'**
  String get personNameHint;

  /// No description provided for @personRelationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get personRelationship;

  /// No description provided for @personRelationshipHint.
  ///
  /// In en, this message translates to:
  /// **'Enter relationship'**
  String get personRelationshipHint;

  /// No description provided for @personConsent.
  ///
  /// In en, this message translates to:
  /// **'This person agreed to be recognized by Remori.'**
  String get personConsent;

  /// No description provided for @personConsentRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirm this person’s consent before saving.'**
  String get personConsentRequired;

  /// No description provided for @personCacheRetry.
  ///
  /// In en, this message translates to:
  /// **'Person saved. Tap Save person again to finish updating the list.'**
  String get personCacheRetry;

  /// No description provided for @personSaveUncertain.
  ///
  /// In en, this message translates to:
  /// **'Unable to confirm the save. Check People before trying again to avoid adding this person twice.'**
  String get personSaveUncertain;

  /// No description provided for @personSaveRetry.
  ///
  /// In en, this message translates to:
  /// **'Unable to save this person. Check the fields and photos, then try again.'**
  String get personSaveRetry;

  /// No description provided for @personSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get personSaving;

  /// No description provided for @personSave.
  ///
  /// In en, this message translates to:
  /// **'Save person'**
  String get personSave;

  /// No description provided for @detailTitle.
  ///
  /// In en, this message translates to:
  /// **'Person detail'**
  String get detailTitle;

  /// No description provided for @detailEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get detailEdit;

  /// No description provided for @detailSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get detailSave;

  /// No description provided for @detailCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get detailCancel;

  /// No description provided for @detailAddPhotos.
  ///
  /// In en, this message translates to:
  /// **'+ Add photos'**
  String get detailAddPhotos;

  /// No description provided for @detailSavePhotos.
  ///
  /// In en, this message translates to:
  /// **'Save photos'**
  String get detailSavePhotos;

  /// No description provided for @detailEnrolledBy.
  ///
  /// In en, this message translates to:
  /// **'{relationship} · enrolled by {name}'**
  String detailEnrolledBy(String relationship, String name);

  /// No description provided for @detailPhotoCount.
  ///
  /// In en, this message translates to:
  /// **'Enrolled photos ({count})'**
  String detailPhotoCount(String count);

  /// No description provided for @detailPhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Enrolled photo'**
  String get detailPhotoLabel;

  /// No description provided for @detailPhotoTip.
  ///
  /// In en, this message translates to:
  /// **'More photos from different angles improve recognition.'**
  String get detailPhotoTip;

  /// No description provided for @detailArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive person'**
  String get detailArchive;

  /// No description provided for @detailArchiveHint.
  ///
  /// In en, this message translates to:
  /// **'Archived people are no longer announced. You\'ll be asked to confirm.'**
  String get detailArchiveHint;

  /// No description provided for @detailArchiveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Archive this person? Their photos and face data will be deleted. Past journal entries keep their name.'**
  String get detailArchiveConfirm;

  /// No description provided for @detailRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this enrolled photo and its face data?'**
  String get detailRemoveConfirm;

  /// No description provided for @detailArchived.
  ///
  /// In en, this message translates to:
  /// **'This person is archived.'**
  String get detailArchived;

  /// No description provided for @detailLastPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add another photo first, or archive the person.'**
  String get detailLastPhoto;

  /// No description provided for @detailTooManyPhotos.
  ///
  /// In en, this message translates to:
  /// **'A person can have up to 20 photos. Remove a photo first.'**
  String get detailTooManyPhotos;

  /// No description provided for @detailGone.
  ///
  /// In en, this message translates to:
  /// **'This person or photo is no longer available. Refresh the list.'**
  String get detailGone;

  /// No description provided for @detailSavedRefresh.
  ///
  /// In en, this message translates to:
  /// **'Changes saved. Refresh to finish updating this page.'**
  String get detailSavedRefresh;

  /// No description provided for @detailRetryMessage.
  ///
  /// In en, this message translates to:
  /// **'Unable to confirm the change. Refresh to check the current details before trying again.'**
  String get detailRetryMessage;

  /// No description provided for @reminderAdd.
  ///
  /// In en, this message translates to:
  /// **'+ Add'**
  String get reminderAdd;

  /// No description provided for @reminderToday.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get reminderToday;

  /// No description provided for @reminderTodayDate.
  ///
  /// In en, this message translates to:
  /// **'TODAY · {date}'**
  String reminderTodayDate(String date);

  /// No description provided for @reminderAll.
  ///
  /// In en, this message translates to:
  /// **'ALL REMINDERS'**
  String get reminderAll;

  /// No description provided for @reminderMed.
  ///
  /// In en, this message translates to:
  /// **'Med'**
  String get reminderMed;

  /// No description provided for @reminderAppt.
  ///
  /// In en, this message translates to:
  /// **'Appt'**
  String get reminderAppt;

  /// No description provided for @reminderTask.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get reminderTask;

  /// No description provided for @reminderDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get reminderDone;

  /// No description provided for @reminderDoneVia.
  ///
  /// In en, this message translates to:
  /// **'Done · {via}'**
  String reminderDoneVia(String via);

  /// No description provided for @reminderVoice.
  ///
  /// In en, this message translates to:
  /// **'voice'**
  String get reminderVoice;

  /// No description provided for @reminderApp.
  ///
  /// In en, this message translates to:
  /// **'app'**
  String get reminderApp;

  /// No description provided for @reminderCaregiver.
  ///
  /// In en, this message translates to:
  /// **'caregiver'**
  String get reminderCaregiver;

  /// No description provided for @reminderPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get reminderPending;

  /// No description provided for @reminderMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get reminderMissed;

  /// No description provided for @reminderSnoozed.
  ///
  /// In en, this message translates to:
  /// **'Snoozed'**
  String get reminderSnoozed;

  /// No description provided for @reminderSnoozedUntil.
  ///
  /// In en, this message translates to:
  /// **'Snoozed → {time}'**
  String reminderSnoozedUntil(String time);

  /// No description provided for @reminderNoLogs.
  ///
  /// In en, this message translates to:
  /// **'No reminder activity recorded today.'**
  String get reminderNoLogs;

  /// No description provided for @reminderNoSavedToday.
  ///
  /// In en, this message translates to:
  /// **'No saved reminder activity for today.'**
  String get reminderNoSavedToday;

  /// No description provided for @reminderNone.
  ///
  /// In en, this message translates to:
  /// **'No reminders have been added yet.'**
  String get reminderNone;

  /// No description provided for @reminderCustomSchedule.
  ///
  /// In en, this message translates to:
  /// **'Scheduled reminder'**
  String get reminderCustomSchedule;

  /// No description provided for @reminderDaily.
  ///
  /// In en, this message translates to:
  /// **'Every day at {times}'**
  String reminderDaily(String times);

  /// No description provided for @reminderWeekly.
  ///
  /// In en, this message translates to:
  /// **'{days} at {times}'**
  String reminderWeekly(String days, String times);

  /// No description provided for @reminderJoin.
  ///
  /// In en, this message translates to:
  /// **'{first} and {last}'**
  String reminderJoin(String first, String last);

  /// No description provided for @reminderMonday.
  ///
  /// In en, this message translates to:
  /// **'Mondays'**
  String get reminderMonday;

  /// No description provided for @reminderTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesdays'**
  String get reminderTuesday;

  /// No description provided for @reminderWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesdays'**
  String get reminderWednesday;

  /// No description provided for @reminderThursday.
  ///
  /// In en, this message translates to:
  /// **'Thursdays'**
  String get reminderThursday;

  /// No description provided for @reminderFriday.
  ///
  /// In en, this message translates to:
  /// **'Fridays'**
  String get reminderFriday;

  /// No description provided for @reminderSaturday.
  ///
  /// In en, this message translates to:
  /// **'Saturdays'**
  String get reminderSaturday;

  /// No description provided for @reminderSunday.
  ///
  /// In en, this message translates to:
  /// **'Sundays'**
  String get reminderSunday;

  /// No description provided for @reminderEnabledLabel.
  ///
  /// In en, this message translates to:
  /// **'Enabled: {title}'**
  String reminderEnabledLabel(String title);

  /// No description provided for @reminderSavedRetry.
  ///
  /// In en, this message translates to:
  /// **'Change saved. Retry to finish updating the list.'**
  String get reminderSavedRetry;

  /// No description provided for @reminderOffline.
  ///
  /// In en, this message translates to:
  /// **'Showing saved reminders. Unable to update; retry to check the latest state.'**
  String get reminderOffline;

  /// No description provided for @reminderLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load reminders. Check your connection and try again.'**
  String get reminderLoadFailed;
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

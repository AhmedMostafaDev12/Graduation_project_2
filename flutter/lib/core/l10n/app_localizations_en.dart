// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get caregiverHome => 'Home';

  @override
  String get caregiverPeople => 'People';

  @override
  String get reminders => 'Reminders';

  @override
  String get caregiverMore => 'More';

  @override
  String get addReminder => 'Add reminder';

  @override
  String get patientToday => 'Today';

  @override
  String get patientMyDay => 'My Day';

  @override
  String get patientGames => 'Games';

  @override
  String get ask => 'Ask';

  @override
  String get appName => 'Remori';

  @override
  String get splashTagline => 'A quiet layer of memory\nthat stays with you.';

  @override
  String get getStarted => 'Get Started';

  @override
  String get splashSupport => 'Support for everyday moments.';

  @override
  String get modeSelectIntro =>
      'Memory support for people living with Alzheimer\'s, and for the people who care for them.';

  @override
  String get modeCaregiver => 'I\'m a caregiver';

  @override
  String get modePatientPhone => 'This is the patient\'s phone';

  @override
  String get loginTitle => 'Caregiver Log in';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'Enter your email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get forgotPassword => 'Forgot password';

  @override
  String get logIn => 'Log In';

  @override
  String get loggingIn => 'Logging in…';

  @override
  String get orLabel => 'OR';

  @override
  String get continueGoogle => 'Continue with Google';

  @override
  String get continueFacebook => 'Continue with Facebook';

  @override
  String get patientPhoneSetup =>
      'Setting up patient phone for the first time?';

  @override
  String get logInSetupPatient => 'Log In and set up for a patient';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get signUp => 'Sign up';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get requiredField => 'This field is required';

  @override
  String get loginInvalidCredentials => 'Wrong email or password';

  @override
  String get loginConnectionError => 'Check your connection and try again';

  @override
  String get loginRetry => 'Unable to log in. Please try again in a moment.';

  @override
  String get signupTitle => 'Caregiver sign up';

  @override
  String get fullNameLabel => 'Full name';

  @override
  String get fullNameHint => 'Aya Waleed Mohamed';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get phoneHint => '+201000000000';

  @override
  String get alreadyAccount => 'Already have an account?';

  @override
  String get signupLogIn => 'Log in';

  @override
  String get signingUp => 'Signing up…';

  @override
  String get signupPasswordLength => 'Use 8–128 characters';

  @override
  String get signupEmailTaken =>
      'An account with this email already exists. Please log in.';

  @override
  String get signupCheckFields => 'Check the highlighted fields and try again.';

  @override
  String get signupInvalidField => 'Check this field';

  @override
  String get signupRetry => 'Unable to sign up. Please try again in a moment.';

  @override
  String get signupAccountCreated =>
      'Your account was created. Please log in to continue.';

  @override
  String get newPatient => 'New patient';

  @override
  String get patientStepOne => 'Step 1 of 3';

  @override
  String get patientName => 'Patient\'s full name';

  @override
  String get patientNameHint => 'Fatma Mahmoud';

  @override
  String get patientRelationship => 'Your relationship to the patient';

  @override
  String get patientBirthDate => 'Date of birth (optional)';

  @override
  String get patientDateHint => 'DD / MM / YYYY';

  @override
  String get patientLanguage => 'Preferred language';

  @override
  String get patientEnglish => 'English';

  @override
  String get patientArabic => 'العربية Arabic';

  @override
  String get patientTimezone => 'Timezone';

  @override
  String get patientConsent => 'Consent';

  @override
  String get conversationMemory => 'Conversation memory';

  @override
  String get conversationMemoryDetail =>
      'The household agrees to conversation memory. Audio is deleted after transcription.';

  @override
  String get cloudProcessing => 'Allow Cloud AI processing';

  @override
  String get cloudProcessingDetail =>
      'Transcription, photo review, and summaries';

  @override
  String get consentLater =>
      'Consent can be changed or revoked later in More → Consent.';

  @override
  String get continueLabel => 'Continue';

  @override
  String get patientCreating => 'Creating patient…';

  @override
  String get patientCreateRetry =>
      'Unable to create the patient. Please try again in a moment.';

  @override
  String get patientInvalidDate => 'Enter a valid date as DD / MM / YYYY';

  @override
  String get patientLoginAgain => 'Please log in again to continue.';

  @override
  String get pairGlasses => 'Pair glasses';

  @override
  String get pairStepTwo => 'Step 2 of 3';

  @override
  String get pairScanTitle => 'Scan glasses QR code';

  @override
  String get pairScanPosition => 'Position the code inside the scan area.';

  @override
  String get pairCameraHint =>
      'Point your camera at the QR code on the glasses case.';

  @override
  String get pairScanButton => 'Scan QR code';

  @override
  String get pairContinueHint =>
      'You can continue after your glasses are linked.';

  @override
  String get pairScanStep => 'Scan the QR code';

  @override
  String get pairScanStepDetail => 'Read the code on the glasses case.';

  @override
  String get pairConnectStep => 'Connect securely';

  @override
  String get pairBluetoothPending => 'Bluetooth connection is still pending.';

  @override
  String get pairConfirmStep => 'Confirm pairing';

  @override
  String get pairConfirmDetail => 'Associate the glasses with this patient.';

  @override
  String get pairDeviceStatus => 'Device status';

  @override
  String get pairStatusInitial =>
      'Your pairing status and device details will appear here.';

  @override
  String get pairLinkedPending =>
      'Glasses linked. Bluetooth connection is still pending.';

  @override
  String get pairNeedsPatient => 'Return to patient setup to continue.';

  @override
  String get pairLinking => 'Linking glasses…';

  @override
  String get pairAlreadyPaired => 'These glasses are paired with someone else.';

  @override
  String get pairPatientMissing =>
      'This patient is no longer available. Return to patient setup.';

  @override
  String get pairInvalidCode =>
      'Check the QR code on the glasses case and try again.';

  @override
  String get pairSaveFailed =>
      'The glasses were linked, but saving on this phone failed. Please retry.';

  @override
  String get pairRetrySave => 'Retry pairing';

  @override
  String get pairRetry =>
      'Unable to link the glasses. Please try again in a moment.';

  @override
  String get pairCameraPermission =>
      'Allow camera access in your phone settings, then scan again.';

  @override
  String get pairCameraUnavailable =>
      'The camera is unavailable. Please try scanning again.';

  @override
  String pairSerial(String serial) {
    return 'Serial: $serial';
  }
}

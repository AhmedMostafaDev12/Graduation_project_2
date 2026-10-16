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

  /// No description provided for @gameObjectCup.
  ///
  /// In en, this message translates to:
  /// **'Cup'**
  String get gameObjectCup;

  /// No description provided for @gameObjectKey.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get gameObjectKey;

  /// No description provided for @gameObjectBook.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get gameObjectBook;

  /// No description provided for @gameObjectFlower.
  ///
  /// In en, this message translates to:
  /// **'Flower'**
  String get gameObjectFlower;

  /// No description provided for @gamePicturePrompt.
  ///
  /// In en, this message translates to:
  /// **'What is in the picture?'**
  String get gamePicturePrompt;

  /// No description provided for @gameWordsStudy.
  ///
  /// In en, this message translates to:
  /// **'Take your time. Remember these three words.'**
  String get gameWordsStudy;

  /// No description provided for @gameWordsRecall.
  ///
  /// In en, this message translates to:
  /// **'Which word did you see?'**
  String get gameWordsRecall;

  /// No description provided for @gameWordsReady.
  ///
  /// In en, this message translates to:
  /// **'I’m ready'**
  String get gameWordsReady;

  /// No description provided for @gameWordsAgain.
  ///
  /// In en, this message translates to:
  /// **'See the words again'**
  String get gameWordsAgain;

  /// No description provided for @gameNextPicture.
  ///
  /// In en, this message translates to:
  /// **'Next picture'**
  String get gameNextPicture;

  /// No description provided for @gameTryAnother.
  ///
  /// In en, this message translates to:
  /// **'Take your time. Try another answer.'**
  String get gameTryAnother;

  /// No description provided for @gameUiOnlyNotice.
  ///
  /// In en, this message translates to:
  /// **'You can try this activity. Results aren’t saved yet.'**
  String get gameUiOnlyNotice;

  /// No description provided for @cardGameInstruction.
  ///
  /// In en, this message translates to:
  /// **'Find the two cards that match'**
  String get cardGameInstruction;

  /// No description provided for @cardGameNeedPeople.
  ///
  /// In en, this message translates to:
  /// **'Ask your caregiver to add photos of two people you know before playing.'**
  String get cardGameNeedPeople;

  /// No description provided for @cardGameUnavailable.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t get the photos ready. You can try again.'**
  String get cardGameUnavailable;

  /// No description provided for @cardGameEncouragement.
  ///
  /// In en, this message translates to:
  /// **'Well done! Keep going'**
  String get cardGameEncouragement;

  /// No description provided for @cardGameDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get cardGameDone;

  /// No description provided for @cardGameSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t save your game yet. Please try again.'**
  String get cardGameSaveFailed;

  /// No description provided for @cardGameWellDone.
  ///
  /// In en, this message translates to:
  /// **'Well done!'**
  String get cardGameWellDone;

  /// No description provided for @cardGameScore.
  ///
  /// In en, this message translates to:
  /// **'Score: {score} out of 2'**
  String cardGameScore(int score);

  /// No description provided for @cardGameDuration.
  ///
  /// In en, this message translates to:
  /// **'Time: {time}'**
  String cardGameDuration(String time);

  /// No description provided for @cardGameAgain.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get cardGameAgain;

  /// No description provided for @cardGameBackGames.
  ///
  /// In en, this message translates to:
  /// **'Back to games'**
  String get cardGameBackGames;

  /// No description provided for @cardGameResultUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This game result is not available right now.'**
  String get cardGameResultUnavailable;

  /// No description provided for @cardGameHidden.
  ///
  /// In en, this message translates to:
  /// **'Card {number}, face down'**
  String cardGameHidden(int number);

  /// No description provided for @cardGamePerson.
  ///
  /// In en, this message translates to:
  /// **'Photo of {name}'**
  String cardGamePerson(String name);

  /// No description provided for @patientGameCards.
  ///
  /// In en, this message translates to:
  /// **'Card game'**
  String get patientGameCards;

  /// No description provided for @patientGamePicture.
  ///
  /// In en, this message translates to:
  /// **'Name the picture'**
  String get patientGamePicture;

  /// No description provided for @patientGameWords.
  ///
  /// In en, this message translates to:
  /// **'Remember the words'**
  String get patientGameWords;

  /// No description provided for @patientGameLastScore.
  ///
  /// In en, this message translates to:
  /// **'Last score: {score}'**
  String patientGameLastScore(String score);

  /// No description provided for @patientGameNone.
  ///
  /// In en, this message translates to:
  /// **'No games yet'**
  String get patientGameNone;

  /// No description provided for @patientGameUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Last score is not available yet'**
  String get patientGameUnavailable;

  /// No description provided for @patientGamesPending.
  ///
  /// In en, this message translates to:
  /// **'The other games will be available soon.'**
  String get patientGamesPending;

  /// No description provided for @patientGamesOffline.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t check your latest scores. You can try again.'**
  String get patientGamesOffline;

  /// No description provided for @patientMemoryBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get patientMemoryBack;

  /// No description provided for @patientMemoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your memory'**
  String get patientMemoryTitle;

  /// No description provided for @patientMemoryMet.
  ///
  /// In en, this message translates to:
  /// **'You met {name}'**
  String patientMemoryMet(String name);

  /// No description provided for @patientMemoryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This memory is not available right now.'**
  String get patientMemoryUnavailable;

  /// No description provided for @patientMemoryPhotoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Your photo is not available right now.'**
  String get patientMemoryPhotoUnavailable;

  /// No description provided for @patientMemoryVideoPending.
  ///
  /// In en, this message translates to:
  /// **'This is a video memory. Watching videos will be available later.'**
  String get patientMemoryVideoPending;

  /// No description provided for @patientMemoryDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get patientMemoryDelete;

  /// No description provided for @patientMemoryDeleteHelp.
  ///
  /// In en, this message translates to:
  /// **'We’ll ask before deleting'**
  String get patientMemoryDeleteHelp;

  /// No description provided for @patientMemoryDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this memory?'**
  String get patientMemoryDeleteTitle;

  /// No description provided for @patientMemoryDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'The photo or video will be permanently deleted. You can keep it instead.'**
  String get patientMemoryDeleteConfirm;

  /// No description provided for @patientMemoryKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep memory'**
  String get patientMemoryKeep;

  /// No description provided for @patientMemoryRemovedPending.
  ///
  /// In en, this message translates to:
  /// **'The memory was deleted. Tap Retry to finish.'**
  String get patientMemoryRemovedPending;

  /// No description provided for @patientMemoryUncertain.
  ///
  /// In en, this message translates to:
  /// **'Let’s check your memory before trying again.'**
  String get patientMemoryUncertain;

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

  /// No description provided for @reminderEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit reminder'**
  String get reminderEditTitle;

  /// No description provided for @reminderTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get reminderTitleLabel;

  /// No description provided for @reminderTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Blood pressure pill'**
  String get reminderTitleHint;

  /// No description provided for @reminderSpeechLabel.
  ///
  /// In en, this message translates to:
  /// **'What the glasses will say'**
  String get reminderSpeechLabel;

  /// No description provided for @reminderSpeechHint.
  ///
  /// In en, this message translates to:
  /// **'ميعاد دواء الضغط'**
  String get reminderSpeechHint;

  /// No description provided for @reminderTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get reminderTypeLabel;

  /// No description provided for @reminderMedication.
  ///
  /// In en, this message translates to:
  /// **'Medication'**
  String get reminderMedication;

  /// No description provided for @reminderAppointment.
  ///
  /// In en, this message translates to:
  /// **'Appointment'**
  String get reminderAppointment;

  /// No description provided for @reminderRepeatLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get reminderRepeatLabel;

  /// No description provided for @reminderOnce.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get reminderOnce;

  /// No description provided for @reminderRepeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get reminderRepeatDaily;

  /// No description provided for @reminderRepeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get reminderRepeatWeekly;

  /// No description provided for @reminderTimesLabel.
  ///
  /// In en, this message translates to:
  /// **'Time(s)'**
  String get reminderTimesLabel;

  /// No description provided for @reminderTimeHint.
  ///
  /// In en, this message translates to:
  /// **'09:00'**
  String get reminderTimeHint;

  /// No description provided for @reminderAddTime.
  ///
  /// In en, this message translates to:
  /// **'+ Add time'**
  String get reminderAddTime;

  /// No description provided for @reminderRemoveTime.
  ///
  /// In en, this message translates to:
  /// **'Remove time'**
  String get reminderRemoveTime;

  /// No description provided for @reminderStartsLabel.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get reminderStartsLabel;

  /// No description provided for @reminderTimezoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get reminderTimezoneLabel;

  /// No description provided for @reminderSave.
  ///
  /// In en, this message translates to:
  /// **'Save reminder'**
  String get reminderSave;

  /// No description provided for @reminderSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get reminderSaving;

  /// No description provided for @reminderDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete reminder'**
  String get reminderDelete;

  /// No description provided for @reminderDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this reminder? Recorded activity will be kept.'**
  String get reminderDeleteConfirm;

  /// No description provided for @reminderUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This reminder is unavailable or you do not have permission to edit it.'**
  String get reminderUnavailable;

  /// No description provided for @reminderTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a title (up to 120 characters).'**
  String get reminderTitleRequired;

  /// No description provided for @reminderSpeechTooLong.
  ///
  /// In en, this message translates to:
  /// **'Use up to 200 characters for the spoken text.'**
  String get reminderSpeechTooLong;

  /// No description provided for @reminderTimesRequired.
  ///
  /// In en, this message translates to:
  /// **'Select 1–4 different times.'**
  String get reminderTimesRequired;

  /// No description provided for @reminderDaysRequired.
  ///
  /// In en, this message translates to:
  /// **'Select at least one day.'**
  String get reminderDaysRequired;

  /// No description provided for @reminderTimezoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid timezone, such as Africa/Cairo.'**
  String get reminderTimezoneInvalid;

  /// No description provided for @reminderStartGap.
  ///
  /// In en, this message translates to:
  /// **'A selected time does not exist on the start day because the clocks change. Choose another time.'**
  String get reminderStartGap;

  /// No description provided for @reminderSchedulePreserved.
  ///
  /// In en, this message translates to:
  /// **'This schedule is kept unchanged. You can edit the title, spoken text and type.'**
  String get reminderSchedulePreserved;

  /// No description provided for @reminderWriteFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to save the change. Please try again.'**
  String get reminderWriteFailed;

  /// No description provided for @reminderWriteUncertain.
  ///
  /// In en, this message translates to:
  /// **'Unable to confirm the change. Check the reminder list before trying again.'**
  String get reminderWriteUncertain;

  /// No description provided for @reminderFieldInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the highlighted fields.'**
  String get reminderFieldInvalid;

  /// No description provided for @reminderWeekdaySunday.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get reminderWeekdaySunday;

  /// No description provided for @reminderWeekdayMonday.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get reminderWeekdayMonday;

  /// No description provided for @reminderWeekdayTuesday.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get reminderWeekdayTuesday;

  /// No description provided for @reminderWeekdayWednesday.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get reminderWeekdayWednesday;

  /// No description provided for @reminderWeekdayThursday.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get reminderWeekdayThursday;

  /// No description provided for @reminderWeekdayFriday.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get reminderWeekdayFriday;

  /// No description provided for @reminderWeekdaySaturday.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get reminderWeekdaySaturday;

  /// No description provided for @alertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alertsTitle;

  /// No description provided for @alertsUnread.
  ///
  /// In en, this message translates to:
  /// **'{count} unread'**
  String alertsUnread(String count);

  /// No description provided for @alertsToday.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get alertsToday;

  /// No description provided for @alertsYesterday.
  ///
  /// In en, this message translates to:
  /// **'YESTERDAY'**
  String get alertsYesterday;

  /// No description provided for @alertsSomeoneNew.
  ///
  /// In en, this message translates to:
  /// **'Someone new'**
  String get alertsSomeoneNew;

  /// No description provided for @alertsLowBattery.
  ///
  /// In en, this message translates to:
  /// **'Low battery'**
  String get alertsLowBattery;

  /// No description provided for @alertsMissedMedication.
  ///
  /// In en, this message translates to:
  /// **'Missed medication'**
  String get alertsMissedMedication;

  /// No description provided for @alertsDeviceOffline.
  ///
  /// In en, this message translates to:
  /// **'Device offline'**
  String get alertsDeviceOffline;

  /// No description provided for @alertsSummaryReady.
  ///
  /// In en, this message translates to:
  /// **'Daily summary ready'**
  String get alertsSummaryReady;

  /// No description provided for @alertsUnknownDescription.
  ///
  /// In en, this message translates to:
  /// **'Someone new has been flagged for {patient}. Review when available.'**
  String alertsUnknownDescription(String patient);

  /// No description provided for @alertsBatteryDescription.
  ///
  /// In en, this message translates to:
  /// **'The glasses battery is low for {patient}.'**
  String alertsBatteryDescription(String patient);

  /// No description provided for @alertsMissedDescription.
  ///
  /// In en, this message translates to:
  /// **'A medication reminder was not confirmed for {patient}.'**
  String alertsMissedDescription(String patient);

  /// No description provided for @alertsOfflineDescription.
  ///
  /// In en, this message translates to:
  /// **'The device has lost contact for {patient}.'**
  String alertsOfflineDescription(String patient);

  /// No description provided for @alertsSummaryDescription.
  ///
  /// In en, this message translates to:
  /// **'A daily summary is ready for {patient}.'**
  String alertsSummaryDescription(String patient);

  /// No description provided for @alertsOtherDescription.
  ///
  /// In en, this message translates to:
  /// **'There is an alert for {patient}.'**
  String alertsOtherDescription(String patient);

  /// No description provided for @alertsNone.
  ///
  /// In en, this message translates to:
  /// **'No alerts yet.'**
  String get alertsNone;

  /// No description provided for @alertsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to update alerts. Check your connection and try again.'**
  String get alertsLoadFailed;

  /// No description provided for @alertsCached.
  ///
  /// In en, this message translates to:
  /// **'Showing saved alerts. Retry to check the latest state.'**
  String get alertsCached;

  /// No description provided for @alertsReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to mark the alert as read. Please try again.'**
  String get alertsReadFailed;

  /// No description provided for @alertsCacheRetry.
  ///
  /// In en, this message translates to:
  /// **'Alert marked as read. Retry to finish updating this phone.'**
  String get alertsCacheRetry;

  /// No description provided for @alertsDestinationPending.
  ///
  /// In en, this message translates to:
  /// **'Alert read. This destination will be available when its screen is ready.'**
  String get alertsDestinationPending;

  /// No description provided for @unknownFacesTitle.
  ///
  /// In en, this message translates to:
  /// **'New faces to review'**
  String get unknownFacesTitle;

  /// No description provided for @unknownFacesIntro.
  ///
  /// In en, this message translates to:
  /// **'People the glasses saw on 3 or more different days. Only you can name them; the glasses never guess.'**
  String get unknownFacesIntro;

  /// No description provided for @unknownFacesSeen.
  ///
  /// In en, this message translates to:
  /// **'Seen {times} times on {days} days'**
  String unknownFacesSeen(String times, String days);

  /// No description provided for @unknownFacesDates.
  ///
  /// In en, this message translates to:
  /// **'First seen {first} · last seen {last}'**
  String unknownFacesDates(String first, String last);

  /// No description provided for @unknownFacesTodayTime.
  ///
  /// In en, this message translates to:
  /// **'today {time}'**
  String unknownFacesTodayTime(String time);

  /// No description provided for @unknownFacesRetention.
  ///
  /// In en, this message translates to:
  /// **'Photos of unknown people are deleted after 30 days, or right away if you dismiss them.'**
  String get unknownFacesRetention;

  /// No description provided for @unknownFacesPending.
  ///
  /// In en, this message translates to:
  /// **'Face review will be available when the review screen is ready.'**
  String get unknownFacesPending;

  /// No description provided for @unknownFacesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No new faces to review yet.'**
  String get unknownFacesEmpty;

  /// No description provided for @unknownFacesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to update new faces. Check your connection and try again.'**
  String get unknownFacesLoadFailed;

  /// No description provided for @unknownFacesOffline.
  ///
  /// In en, this message translates to:
  /// **'Showing saved counts and dates. Photos require a successful refresh.'**
  String get unknownFacesOffline;

  /// No description provided for @unknownFacePhoto.
  ///
  /// In en, this message translates to:
  /// **'Unknown person photo'**
  String get unknownFacePhoto;

  /// No description provided for @unknownFacePhotoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Photo unavailable'**
  String get unknownFacePhotoUnavailable;

  /// No description provided for @unknownFacesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This patient\'s new faces are unavailable.'**
  String get unknownFacesUnavailable;

  /// No description provided for @unknownDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Who is this?'**
  String get unknownDetailTitle;

  /// No description provided for @unknownDetailKnow.
  ///
  /// In en, this message translates to:
  /// **'I know them'**
  String get unknownDetailKnow;

  /// No description provided for @unknownDetailNameHint.
  ///
  /// In en, this message translates to:
  /// **'Dr. Hany'**
  String get unknownDetailNameHint;

  /// No description provided for @unknownDetailRelationshipHint.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get unknownDetailRelationshipHint;

  /// No description provided for @unknownDetailConsent.
  ///
  /// In en, this message translates to:
  /// **'This person agreed to be recognized.'**
  String get unknownDetailConsent;

  /// No description provided for @unknownDetailSave.
  ///
  /// In en, this message translates to:
  /// **'Save as a known person'**
  String get unknownDetailSave;

  /// No description provided for @unknownDetailDismiss.
  ///
  /// In en, this message translates to:
  /// **'Stranger, dismiss'**
  String get unknownDetailDismiss;

  /// No description provided for @unknownDetailDeleteHint.
  ///
  /// In en, this message translates to:
  /// **'Dismissing deletes these photos.'**
  String get unknownDetailDeleteHint;

  /// No description provided for @unknownDetailDismissConfirm.
  ///
  /// In en, this message translates to:
  /// **'Dismiss this stranger? Their photos will be deleted immediately. Journal sightings will remain without photos.'**
  String get unknownDetailDismissConfirm;

  /// No description provided for @unknownDetailUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This face is no longer available. Return to New faces to check the list.'**
  String get unknownDetailUnavailable;

  /// No description provided for @unknownDetailCacheRetry.
  ///
  /// In en, this message translates to:
  /// **'Decision saved. Retry to finish updating this phone.'**
  String get unknownDetailCacheRetry;

  /// No description provided for @unknownDetailUncertain.
  ///
  /// In en, this message translates to:
  /// **'Unable to confirm the decision. Refresh to check its current state before trying again.'**
  String get unknownDetailUncertain;

  /// No description provided for @unknownDetailNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name (up to 80 characters).'**
  String get unknownDetailNameRequired;

  /// No description provided for @unknownDetailRelationshipRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a relationship (up to 40 characters).'**
  String get unknownDetailRelationshipRequired;

  /// No description provided for @unknownDetailSummary.
  ///
  /// In en, this message translates to:
  /// **'Seen {times} times on {days} different days · first {first} · last {last}'**
  String unknownDetailSummary(
    String times,
    String days,
    String first,
    String last,
  );

  /// No description provided for @placesTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved places'**
  String get placesTitle;

  /// No description provided for @placesAdd.
  ///
  /// In en, this message translates to:
  /// **'+ Add'**
  String get placesAdd;

  /// No description provided for @placesIntro.
  ///
  /// In en, this message translates to:
  /// **'Used when the patient asks the glasses \"Where am I?\". The phone matches its location to the nearest saved place.'**
  String get placesIntro;

  /// No description provided for @placesRadius.
  ///
  /// In en, this message translates to:
  /// **'Radius {meters} m'**
  String placesRadius(String meters);

  /// No description provided for @placesEditingPending.
  ///
  /// In en, this message translates to:
  /// **'Adding and editing places will be available when the place editor is ready.'**
  String get placesEditingPending;

  /// No description provided for @placesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved places yet.'**
  String get placesEmpty;

  /// No description provided for @placesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Saved places are unavailable. Select a patient and try again.'**
  String get placesUnavailable;

  /// No description provided for @placesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to update saved places. Check your connection and try again.'**
  String get placesLoadFailed;

  /// No description provided for @placesOffline.
  ///
  /// In en, this message translates to:
  /// **'Showing saved places. Retry to check the latest list.'**
  String get placesOffline;

  /// No description provided for @placeEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit place'**
  String get placeEditTitle;

  /// No description provided for @placeName.
  ///
  /// In en, this message translates to:
  /// **'Place name'**
  String get placeName;

  /// No description provided for @placeNameHint.
  ///
  /// In en, this message translates to:
  /// **'Home · البيت'**
  String get placeNameHint;

  /// No description provided for @placeSave.
  ///
  /// In en, this message translates to:
  /// **'Save place'**
  String get placeSave;

  /// No description provided for @placeDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete place'**
  String get placeDelete;

  /// No description provided for @placeDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this saved place? It will no longer be used for Where am I?'**
  String get placeDeleteConfirm;

  /// No description provided for @placeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This place is unavailable or you do not have permission to edit it.'**
  String get placeUnavailable;

  /// No description provided for @placeNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a place name (up to 80 characters).'**
  String get placeNameRequired;

  /// No description provided for @placeSelectPoint.
  ///
  /// In en, this message translates to:
  /// **'Select the place on the map before saving.'**
  String get placeSelectPoint;

  /// No description provided for @placeLocating.
  ///
  /// In en, this message translates to:
  /// **'Finding this phone\'s location...'**
  String get placeLocating;

  /// No description provided for @placeDragPin.
  ///
  /// In en, this message translates to:
  /// **'Drag the pin to the place'**
  String get placeDragPin;

  /// No description provided for @placePin.
  ///
  /// In en, this message translates to:
  /// **'Selected place pin; drag to move'**
  String get placePin;

  /// No description provided for @placeAttribution.
  ///
  /// In en, this message translates to:
  /// **'© OpenStreetMap contributors'**
  String get placeAttribution;

  /// No description provided for @placeMapUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The map is unavailable. Check your connection and try again.'**
  String get placeMapUnavailable;

  /// No description provided for @placeRadiusLabel.
  ///
  /// In en, this message translates to:
  /// **'Radius: {meters} m'**
  String placeRadiusLabel(String meters);

  /// No description provided for @placeRadiusMinimum.
  ///
  /// In en, this message translates to:
  /// **'50 m'**
  String get placeRadiusMinimum;

  /// No description provided for @placeRadiusMaximum.
  ///
  /// In en, this message translates to:
  /// **'500 m'**
  String get placeRadiusMaximum;

  /// No description provided for @placeRadiusPreserved.
  ///
  /// In en, this message translates to:
  /// **'The saved radius is kept unchanged until you move the slider.'**
  String get placeRadiusPreserved;

  /// No description provided for @placeCacheRetry.
  ///
  /// In en, this message translates to:
  /// **'Change saved. Retry to finish updating this phone.'**
  String get placeCacheRetry;

  /// No description provided for @placeWriteUncertain.
  ///
  /// In en, this message translates to:
  /// **'Unable to confirm the change. Return to Saved places and refresh before trying again.'**
  String get placeWriteUncertain;

  /// No description provided for @placeWriteFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to save the change. Check the details and try again.'**
  String get placeWriteFailed;

  /// No description provided for @journalAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get journalAll;

  /// No description provided for @journalPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get journalPeople;

  /// No description provided for @journalTalk.
  ///
  /// In en, this message translates to:
  /// **'Talk'**
  String get journalTalk;

  /// No description provided for @journalQuestions.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get journalQuestions;

  /// No description provided for @journalMedia.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get journalMedia;

  /// No description provided for @journalDocs.
  ///
  /// In en, this message translates to:
  /// **'Docs'**
  String get journalDocs;

  /// No description provided for @journalTitle.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get journalTitle;

  /// No description provided for @journalPreviousDay.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get journalPreviousDay;

  /// No description provided for @journalNextDay.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get journalNextDay;

  /// No description provided for @journalLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh the journal. Please try again.'**
  String get journalLoadFailed;

  /// No description provided for @journalOffline.
  ///
  /// In en, this message translates to:
  /// **'Showing saved journal text. Photos require a successful refresh.'**
  String get journalOffline;

  /// No description provided for @journalOfflineStatus.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get journalOfflineStatus;

  /// No description provided for @journalNoSavedEntries.
  ///
  /// In en, this message translates to:
  /// **'No saved journal entries for this day.'**
  String get journalNoSavedEntries;

  /// No description provided for @journalSavedExplanation.
  ///
  /// In en, this message translates to:
  /// **'Showing what\'s saved on this phone. New items appear when you\'re back online.'**
  String get journalSavedExplanation;

  /// No description provided for @journalUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Choose a patient to view their journal.'**
  String get journalUnavailable;

  /// No description provided for @journalEmpty.
  ///
  /// In en, this message translates to:
  /// **'No journal entries for this day and filter.'**
  String get journalEmpty;

  /// No description provided for @journalDetailsPending.
  ///
  /// In en, this message translates to:
  /// **'Document details will be available when their screen is ready.'**
  String get journalDetailsPending;

  /// No description provided for @journalEncounter.
  ///
  /// In en, this message translates to:
  /// **'Encounter'**
  String get journalEncounter;

  /// No description provided for @journalConversation.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get journalConversation;

  /// No description provided for @journalQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question asked'**
  String get journalQuestion;

  /// No description provided for @journalReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get journalReminder;

  /// No description provided for @journalRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get journalRecording;

  /// No description provided for @journalDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get journalDocument;

  /// No description provided for @journalNotable.
  ///
  /// In en, this message translates to:
  /// **'Notable moment'**
  String get journalNotable;

  /// No description provided for @journalGame.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get journalGame;

  /// No description provided for @journalNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get journalNote;

  /// No description provided for @journalActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get journalActivity;

  /// No description provided for @journalUnknownPerson.
  ///
  /// In en, this message translates to:
  /// **'Unknown person'**
  String get journalUnknownPerson;

  /// No description provided for @journalRecorded.
  ///
  /// In en, this message translates to:
  /// **'Recording captured'**
  String get journalRecorded;

  /// No description provided for @journalReminderActivity.
  ///
  /// In en, this message translates to:
  /// **'Reminder activity recorded.'**
  String get journalReminderActivity;

  /// No description provided for @journalPaused.
  ///
  /// In en, this message translates to:
  /// **'Memory paused'**
  String get journalPaused;

  /// No description provided for @journalResumed.
  ///
  /// In en, this message translates to:
  /// **'Memory resumed'**
  String get journalResumed;

  /// No description provided for @journalPreviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Photo preview unavailable'**
  String get journalPreviewUnavailable;

  /// No description provided for @journalPreview.
  ///
  /// In en, this message translates to:
  /// **'Journal photo preview'**
  String get journalPreview;

  /// No description provided for @journalRecordingDuration.
  ///
  /// In en, this message translates to:
  /// **'Recorded · {duration}'**
  String journalRecordingDuration(String duration);

  /// No description provided for @journalWithPerson.
  ///
  /// In en, this message translates to:
  /// **'with {name}'**
  String journalWithPerson(String name);

  /// No description provided for @journalConversationDuration.
  ///
  /// In en, this message translates to:
  /// **'with {name} · {minutes} min'**
  String journalConversationDuration(String name, String minutes);

  /// No description provided for @mediaPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get mediaPhoto;

  /// No description provided for @mediaVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get mediaVideo;

  /// No description provided for @mediaUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This media is no longer available.'**
  String get mediaUnavailable;

  /// No description provided for @mediaDeletePhoto.
  ///
  /// In en, this message translates to:
  /// **'Delete photo'**
  String get mediaDeletePhoto;

  /// No description provided for @mediaDeleteVideo.
  ///
  /// In en, this message translates to:
  /// **'Delete video'**
  String get mediaDeleteVideo;

  /// No description provided for @mediaDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this item permanently? The file will be removed and the deletion recorded in the audit log.'**
  String get mediaDeleteConfirm;

  /// No description provided for @mediaPhotoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Photo unavailable. Refresh while online to view it.'**
  String get mediaPhotoUnavailable;

  /// No description provided for @mediaVideoPending.
  ///
  /// In en, this message translates to:
  /// **'Video playback will be available when the video viewer is ready.'**
  String get mediaVideoPending;

  /// No description provided for @mediaEncounter.
  ///
  /// In en, this message translates to:
  /// **'Encounter with {name} ({relationship})'**
  String mediaEncounter(String name, String relationship);

  /// No description provided for @mediaKeyframe.
  ///
  /// In en, this message translates to:
  /// **'keyframe from the glasses'**
  String get mediaKeyframe;

  /// No description provided for @mediaDocumentCapture.
  ///
  /// In en, this message translates to:
  /// **'document captured by the glasses'**
  String get mediaDocumentCapture;

  /// No description provided for @mediaNotableCapture.
  ///
  /// In en, this message translates to:
  /// **'moment captured by the glasses'**
  String get mediaNotableCapture;

  /// No description provided for @mediaRequested.
  ///
  /// In en, this message translates to:
  /// **'recorded at the patient’s request'**
  String get mediaRequested;

  /// No description provided for @mediaCaptured.
  ///
  /// In en, this message translates to:
  /// **'captured by the glasses'**
  String get mediaCaptured;

  /// No description provided for @mediaAiTags.
  ///
  /// In en, this message translates to:
  /// **'AI tags:'**
  String get mediaAiTags;

  /// No description provided for @mediaKept.
  ///
  /// In en, this message translates to:
  /// **'Kept'**
  String get mediaKept;

  /// No description provided for @mediaPin.
  ///
  /// In en, this message translates to:
  /// **'Pin to keep'**
  String get mediaPin;

  /// No description provided for @mediaExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get mediaExpired;

  /// No description provided for @mediaAutoDeletes.
  ///
  /// In en, this message translates to:
  /// **'Auto-deletes in {days} days'**
  String mediaAutoDeletes(String days);

  /// No description provided for @mediaRetentionNote.
  ///
  /// In en, this message translates to:
  /// **'Photos of other people expire after 30 days unless pinned'**
  String get mediaRetentionNote;

  /// No description provided for @mediaCacheFailed.
  ///
  /// In en, this message translates to:
  /// **'The change was saved. Retry to update the saved information on this phone.'**
  String get mediaCacheFailed;

  /// No description provided for @mediaUncertain.
  ///
  /// In en, this message translates to:
  /// **'The change could not be confirmed. Refresh before trying again.'**
  String get mediaUncertain;

  /// No description provided for @mediaOffline.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh. Saved information is available; photos need an online refresh.'**
  String get mediaOffline;

  /// No description provided for @mediaAuditNote.
  ///
  /// In en, this message translates to:
  /// **'You’ll be asked to confirm deletion. Deletions are recorded in the audit log.'**
  String get mediaAuditNote;

  /// No description provided for @documentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documentsTitle;

  /// No description provided for @documentsAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get documentsAll;

  /// No description provided for @documentsReceipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get documentsReceipts;

  /// No description provided for @documentsBills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get documentsBills;

  /// No description provided for @documentsMedicationLabels.
  ///
  /// In en, this message translates to:
  /// **'Medication labels'**
  String get documentsMedicationLabels;

  /// No description provided for @documentsReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get documentsReceipt;

  /// No description provided for @documentsBill.
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get documentsBill;

  /// No description provided for @documentsMedicationLabel.
  ///
  /// In en, this message translates to:
  /// **'Medication label'**
  String get documentsMedicationLabel;

  /// No description provided for @documentsOther.
  ///
  /// In en, this message translates to:
  /// **'Other document'**
  String get documentsOther;

  /// No description provided for @documentsIntro.
  ///
  /// In en, this message translates to:
  /// **'Captured by the glasses and read automatically.'**
  String get documentsIntro;

  /// No description provided for @documentsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh documents. Please try again.'**
  String get documentsLoadFailed;

  /// No description provided for @documentsOffline.
  ///
  /// In en, this message translates to:
  /// **'Showing saved documents. Photos require an online refresh.'**
  String get documentsOffline;

  /// No description provided for @documentsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Choose a patient to view their documents.'**
  String get documentsUnavailable;

  /// No description provided for @documentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No documents in this category yet.'**
  String get documentsEmpty;

  /// No description provided for @documentsDetailPending.
  ///
  /// In en, this message translates to:
  /// **'Document details will be available when their screen is ready.'**
  String get documentsDetailPending;

  /// No description provided for @documentsPreviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Document preview unavailable'**
  String get documentsPreviewUnavailable;

  /// No description provided for @documentsPreview.
  ///
  /// In en, this message translates to:
  /// **'Document preview'**
  String get documentsPreview;

  /// No description provided for @documentDetailUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This document is unavailable for the selected patient.'**
  String get documentDetailUnavailable;

  /// No description provided for @documentDetailOffline.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh. Showing saved document information; the photo needs an online refresh.'**
  String get documentDetailOffline;

  /// No description provided for @documentDetailPhotoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Photo unavailable. Refresh while online to view it.'**
  String get documentDetailPhotoUnavailable;

  /// No description provided for @documentDetailPhoto.
  ///
  /// In en, this message translates to:
  /// **'Document photo'**
  String get documentDetailPhoto;

  /// No description provided for @documentDetailCaptured.
  ///
  /// In en, this message translates to:
  /// **'Captured {date}'**
  String documentDetailCaptured(String date);

  /// No description provided for @documentDetailFullText.
  ///
  /// In en, this message translates to:
  /// **'Full text read from the photo'**
  String get documentDetailFullText;

  /// No description provided for @documentDetailNoText.
  ///
  /// In en, this message translates to:
  /// **'No text was read from this photo.'**
  String get documentDetailNoText;

  /// No description provided for @documentFieldAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get documentFieldAmount;

  /// No description provided for @documentFieldDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get documentFieldDate;

  /// No description provided for @documentFieldItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get documentFieldItems;

  /// No description provided for @documentFieldStore.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get documentFieldStore;

  /// No description provided for @documentFieldCompany.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get documentFieldCompany;

  /// No description provided for @documentFieldDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get documentFieldDueDate;

  /// No description provided for @documentFieldMedicine.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get documentFieldMedicine;

  /// No description provided for @documentFieldStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get documentFieldStrength;

  /// No description provided for @documentFieldInstructions.
  ///
  /// In en, this message translates to:
  /// **'How to take'**
  String get documentFieldInstructions;

  /// No description provided for @documentFieldExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get documentFieldExpires;

  /// No description provided for @deviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get deviceTitle;

  /// No description provided for @deviceGlasses.
  ///
  /// In en, this message translates to:
  /// **'Remori glasses'**
  String get deviceGlasses;

  /// No description provided for @deviceConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get deviceConnected;

  /// No description provided for @deviceOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get deviceOffline;

  /// No description provided for @deviceStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Status unavailable'**
  String get deviceStatusUnavailable;

  /// No description provided for @deviceSerial.
  ///
  /// In en, this message translates to:
  /// **'Serial'**
  String get deviceSerial;

  /// No description provided for @deviceFirmware.
  ///
  /// In en, this message translates to:
  /// **'Firmware'**
  String get deviceFirmware;

  /// No description provided for @deviceBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get deviceBattery;

  /// No description provided for @deviceLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen'**
  String get deviceLastSeen;

  /// No description provided for @deviceUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get deviceUnknown;

  /// No description provided for @deviceJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get deviceJustNow;

  /// No description provided for @deviceMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 min ago} other{{count} min ago}}'**
  String deviceMinutesAgo(int count);

  /// No description provided for @deviceHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String deviceHoursAgo(int count);

  /// No description provided for @deviceDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String deviceDaysAgo(int count);

  /// No description provided for @deviceMemory.
  ///
  /// In en, this message translates to:
  /// **'Conversation memory'**
  String get deviceMemory;

  /// No description provided for @deviceMemoryHelp.
  ///
  /// In en, this message translates to:
  /// **'When off, the glasses stop capturing speech. Face recognition and reminders keep working. The patient can also pause it with a long press on the glasses.'**
  String get deviceMemoryHelp;

  /// No description provided for @deviceHeartbeatHelp.
  ///
  /// In en, this message translates to:
  /// **'Connected means a heartbeat was received in the last 5 minutes. It does not confirm a direct Bluetooth connection. Offline values are last saved readings.'**
  String get deviceHeartbeatHelp;

  /// No description provided for @deviceRepair.
  ///
  /// In en, this message translates to:
  /// **'Re-pair glasses'**
  String get deviceRepair;

  /// No description provided for @deviceUnpair.
  ///
  /// In en, this message translates to:
  /// **'Unpair glasses'**
  String get deviceUnpair;

  /// No description provided for @deviceUnpairConfirm.
  ///
  /// In en, this message translates to:
  /// **'Unpair {serial}? Its patient phone token will stop working. You will need to pair the glasses again to reconnect.'**
  String deviceUnpairConfirm(String serial);

  /// No description provided for @deviceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Select an available patient to view their glasses.'**
  String get deviceUnavailable;

  /// No description provided for @deviceNone.
  ///
  /// In en, this message translates to:
  /// **'No glasses are paired with this patient.'**
  String get deviceNone;

  /// No description provided for @deviceLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh. Showing saved device readings. Check your connection and try again.'**
  String get deviceLoadFailed;

  /// No description provided for @deviceSavedLocallyPending.
  ///
  /// In en, this message translates to:
  /// **'The change was saved. Retry to finish updating this phone.'**
  String get deviceSavedLocallyPending;

  /// No description provided for @deviceUncertain.
  ///
  /// In en, this message translates to:
  /// **'The change could not be confirmed. Refresh before making another change.'**
  String get deviceUncertain;

  /// No description provided for @moreTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTitle;

  /// No description provided for @morePatientGroup.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get morePatientGroup;

  /// No description provided for @morePatientProfile.
  ///
  /// In en, this message translates to:
  /// **'Patient profile'**
  String get morePatientProfile;

  /// No description provided for @moreCaregivers.
  ///
  /// In en, this message translates to:
  /// **'Caregivers'**
  String get moreCaregivers;

  /// No description provided for @moreCaregiversPending.
  ///
  /// In en, this message translates to:
  /// **'Caregiver management coming soon.'**
  String get moreCaregiversPending;

  /// No description provided for @moreConsents.
  ///
  /// In en, this message translates to:
  /// **'Consent records'**
  String get moreConsents;

  /// No description provided for @moreConversationConsent.
  ///
  /// In en, this message translates to:
  /// **'Conversation memory'**
  String get moreConversationConsent;

  /// No description provided for @moreCloudConsent.
  ///
  /// In en, this message translates to:
  /// **'Cloud AI processing'**
  String get moreCloudConsent;

  /// No description provided for @moreFaceConsent.
  ///
  /// In en, this message translates to:
  /// **'Face enrollment'**
  String get moreFaceConsent;

  /// No description provided for @moreFaceConsentFor.
  ///
  /// In en, this message translates to:
  /// **'Face enrollment · {name}'**
  String moreFaceConsentFor(String name);

  /// No description provided for @moreGiven.
  ///
  /// In en, this message translates to:
  /// **'given {date}'**
  String moreGiven(String date);

  /// No description provided for @moreRevoked.
  ///
  /// In en, this message translates to:
  /// **'revoked {date}'**
  String moreRevoked(String date);

  /// No description provided for @moreRevoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get moreRevoke;

  /// No description provided for @moreRevokeTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke consent?'**
  String get moreRevokeTitle;

  /// No description provided for @moreRevokeHelp.
  ///
  /// In en, this message translates to:
  /// **'This removes permission for future processing covered by this consent. Existing records are not deleted.'**
  String get moreRevokeHelp;

  /// No description provided for @moreRevokeFaceHelp.
  ///
  /// In en, this message translates to:
  /// **'This archives the enrolled person and deletes their face data. The glasses will stop recognizing them.'**
  String get moreRevokeFaceHelp;

  /// No description provided for @moreNoConsents.
  ///
  /// In en, this message translates to:
  /// **'No consent records.'**
  String get moreNoConsents;

  /// No description provided for @moreConsentsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Consent records are unavailable. Retry to check them.'**
  String get moreConsentsUnavailable;

  /// No description provided for @moreJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get moreJournal;

  /// No description provided for @moreJournalHelp.
  ///
  /// In en, this message translates to:
  /// **'The day, hour by hour'**
  String get moreJournalHelp;

  /// No description provided for @morePlaces.
  ///
  /// In en, this message translates to:
  /// **'Saved places'**
  String get morePlaces;

  /// No description provided for @morePlacesHelp.
  ///
  /// In en, this message translates to:
  /// **'Places for “Where am I?”'**
  String get morePlacesHelp;

  /// No description provided for @morePlacesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No saved places for “Where am I?”} =1{1 place for “Where am I?”} other{{count} places for “Where am I?”}}'**
  String morePlacesCount(int count);

  /// No description provided for @moreDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get moreDocuments;

  /// No description provided for @moreDocumentsHelp.
  ///
  /// In en, this message translates to:
  /// **'Receipts, bills, medication labels'**
  String get moreDocumentsHelp;

  /// No description provided for @moreDeviceHelp.
  ///
  /// In en, this message translates to:
  /// **'Glasses · memory switch'**
  String get moreDeviceHelp;

  /// No description provided for @moreDeviceSerial.
  ///
  /// In en, this message translates to:
  /// **'Glasses {serial} · memory switch'**
  String moreDeviceSerial(String serial);

  /// No description provided for @moreAccountGroup.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get moreAccountGroup;

  /// No description provided for @moreMyAccount.
  ///
  /// In en, this message translates to:
  /// **'My account'**
  String get moreMyAccount;

  /// No description provided for @moreAccountUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Account details are unavailable.'**
  String get moreAccountUnavailable;

  /// No description provided for @moreConnectedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Connected accounts'**
  String get moreConnectedAccounts;

  /// No description provided for @moreConnectedPending.
  ///
  /// In en, this message translates to:
  /// **'Account linking coming soon.'**
  String get moreConnectedPending;

  /// No description provided for @moreLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get moreLogout;

  /// No description provided for @moreUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Account details are unavailable. Check your connection and try again.'**
  String get moreUnavailable;

  /// No description provided for @moreNoPatient.
  ///
  /// In en, this message translates to:
  /// **'Select a patient from Home.'**
  String get moreNoPatient;

  /// No description provided for @moreOffline.
  ///
  /// In en, this message translates to:
  /// **'Could not complete the request. Showing saved information. Check your connection and try again.'**
  String get moreOffline;

  /// No description provided for @morePending.
  ///
  /// In en, this message translates to:
  /// **'The change was saved. Retry to finish updating this phone.'**
  String get morePending;

  /// No description provided for @moreUncertain.
  ///
  /// In en, this message translates to:
  /// **'The change could not be confirmed. Refresh before making another change.'**
  String get moreUncertain;

  /// No description provided for @moreFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get moreFullName;

  /// No description provided for @moreNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter patient\'s full name'**
  String get moreNameHint;

  /// No description provided for @moreLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preferred language'**
  String get moreLanguage;

  /// No description provided for @moreArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get moreArabic;

  /// No description provided for @moreEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get moreEnglish;

  /// No description provided for @moreTimezone.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get moreTimezone;

  /// No description provided for @moreTimezoneHint.
  ///
  /// In en, this message translates to:
  /// **'Africa/Cairo'**
  String get moreTimezoneHint;

  /// No description provided for @moreProfileInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a name (up to 120 characters) and a valid time zone, such as Africa/Cairo.'**
  String get moreProfileInvalid;

  /// No description provided for @moreSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get moreSave;

  /// No description provided for @caregiversUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Select an available patient to view their caregivers.'**
  String get caregiversUnavailable;

  /// No description provided for @caregiversManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get caregiversManager;

  /// No description provided for @caregiversViewer.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get caregiversViewer;

  /// No description provided for @caregiversPrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get caregiversPrimary;

  /// No description provided for @caregiversYou.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String caregiversYou(String name);

  /// No description provided for @caregiversPermissionHelp.
  ///
  /// In en, this message translates to:
  /// **'Managers can edit people, reminders and places. Viewers can only look.'**
  String get caregiversPermissionHelp;

  /// No description provided for @caregiversAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a caregiver'**
  String get caregiversAddTitle;

  /// No description provided for @caregiversExistingAccountHelp.
  ///
  /// In en, this message translates to:
  /// **'Use an existing caregiver account\'s email. No invitation email is sent.'**
  String get caregiversExistingAccountHelp;

  /// No description provided for @caregiversEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get caregiversEmail;

  /// No description provided for @caregiversEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter caregiver\'s email'**
  String get caregiversEmailHint;

  /// No description provided for @caregiversEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get caregiversEmailInvalid;

  /// No description provided for @caregiversRelationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get caregiversRelationship;

  /// No description provided for @caregiversRelationshipHint.
  ///
  /// In en, this message translates to:
  /// **'Relationship to the patient'**
  String get caregiversRelationshipHint;

  /// No description provided for @caregiversRelationshipInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter their relationship to the patient.'**
  String get caregiversRelationshipInvalid;

  /// No description provided for @caregiversPermission.
  ///
  /// In en, this message translates to:
  /// **'Permission'**
  String get caregiversPermission;

  /// No description provided for @caregiversAdd.
  ///
  /// In en, this message translates to:
  /// **'Add caregiver'**
  String get caregiversAdd;

  /// No description provided for @caregiversAdded.
  ///
  /// In en, this message translates to:
  /// **'Caregiver added.'**
  String get caregiversAdded;

  /// No description provided for @caregiversPending.
  ///
  /// In en, this message translates to:
  /// **'Caregiver added. Retry to finish updating this phone.'**
  String get caregiversPending;

  /// No description provided for @caregiversUncertain.
  ///
  /// In en, this message translates to:
  /// **'The result could not be confirmed. Refresh the caregiver list before trying again.'**
  String get caregiversUncertain;

  /// No description provided for @caregiversNotFound.
  ///
  /// In en, this message translates to:
  /// **'No caregiver account was found with that email. They need to create an account first.'**
  String get caregiversNotFound;

  /// No description provided for @caregiversAlreadyLinked.
  ///
  /// In en, this message translates to:
  /// **'This caregiver is already linked. Refresh to see the latest list.'**
  String get caregiversAlreadyLinked;

  /// No description provided for @caregiversManagerOnly.
  ///
  /// In en, this message translates to:
  /// **'Only a managing caregiver can add another caregiver. Refresh to check your access.'**
  String get caregiversManagerOnly;

  /// No description provided for @caregiversOffline.
  ///
  /// In en, this message translates to:
  /// **'Could not complete the request. Showing saved caregivers. Check your connection and try again.'**
  String get caregiversOffline;

  /// No description provided for @caregiversEmpty.
  ///
  /// In en, this message translates to:
  /// **'No linked caregivers are saved.'**
  String get caregiversEmpty;

  /// No description provided for @caregiversListUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The caregiver list is unavailable. Retry to check it.'**
  String get caregiversListUnavailable;

  /// No description provided for @caregiversMoreHelp.
  ///
  /// In en, this message translates to:
  /// **'Linked caregivers and permissions'**
  String get caregiversMoreHelp;

  /// No description provided for @caregiversLinkedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No linked caregivers} =1{1 linked caregiver} other{{count} linked caregivers}}'**
  String caregiversLinkedCount(int count);

  /// No description provided for @todayGettingReady.
  ///
  /// In en, this message translates to:
  /// **'Getting your day ready'**
  String get todayGettingReady;

  /// No description provided for @todayMemoryOff.
  ///
  /// In en, this message translates to:
  /// **'Memory is off'**
  String get todayMemoryOff;

  /// No description provided for @todayMemoryUnknown.
  ///
  /// In en, this message translates to:
  /// **'Memory status unavailable'**
  String get todayMemoryUnknown;

  /// No description provided for @todayMemoryPaused.
  ///
  /// In en, this message translates to:
  /// **'Memory is paused'**
  String get todayMemoryPaused;

  /// No description provided for @todayMemoryOn.
  ///
  /// In en, this message translates to:
  /// **'Memory is working'**
  String get todayMemoryOn;

  /// No description provided for @todayGlassesConnected.
  ///
  /// In en, this message translates to:
  /// **'Glasses connected'**
  String get todayGlassesConnected;

  /// No description provided for @todayGlassesAway.
  ///
  /// In en, this message translates to:
  /// **'Glasses not connected'**
  String get todayGlassesAway;

  /// No description provided for @todayGlassesDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Glasses not connected'**
  String get todayGlassesDisconnected;

  /// No description provided for @todayGlassesCheck.
  ///
  /// In en, this message translates to:
  /// **'Make sure the glasses are switched on and near the phone.'**
  String get todayGlassesCheck;

  /// No description provided for @todayTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get todayTryAgain;

  /// No description provided for @todayReconnectUnavailable.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t connect yet. You can try again.'**
  String get todayReconnectUnavailable;

  /// No description provided for @todayOffline.
  ///
  /// In en, this message translates to:
  /// **'You can keep using your saved day. Updates will arrive when connected.'**
  String get todayOffline;

  /// No description provided for @todayNextReminder.
  ///
  /// In en, this message translates to:
  /// **'Next reminder'**
  String get todayNextReminder;

  /// No description provided for @todayNoReminder.
  ///
  /// In en, this message translates to:
  /// **'No reminders for now'**
  String get todayNoReminder;

  /// No description provided for @todayDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get todayDone;

  /// No description provided for @todayLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get todayLater;

  /// No description provided for @todayPeopleMet.
  ///
  /// In en, this message translates to:
  /// **'People you met today'**
  String get todayPeopleMet;

  /// No description provided for @todayNoPeople.
  ///
  /// In en, this message translates to:
  /// **'People you meet will appear here'**
  String get todayNoPeople;

  /// No description provided for @todayAskLater.
  ///
  /// In en, this message translates to:
  /// **'Ask (Phase 2)'**
  String get todayAskLater;

  /// No description provided for @patientRemindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s reminders'**
  String get patientRemindersTitle;

  /// No description provided for @patientRemindersEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your reminders will appear here'**
  String get patientRemindersEmpty;

  /// No description provided for @patientReminderPending.
  ///
  /// In en, this message translates to:
  /// **'Still to do'**
  String get patientReminderPending;

  /// No description provided for @patientReminderSnoozed.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get patientReminderSnoozed;

  /// No description provided for @patientReminderMissed.
  ///
  /// In en, this message translates to:
  /// **'Time has passed'**
  String get patientReminderMissed;

  /// No description provided for @patientAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Time for {title}'**
  String patientAlertTitle(String title);

  /// No description provided for @patientAlertUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Your reminders are in Reminders'**
  String get patientAlertUnavailable;

  /// No description provided for @patientAlertSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'That wasn\'t saved yet. Please try again.'**
  String get patientAlertSaveFailed;

  /// No description provided for @patientAlertBack.
  ///
  /// In en, this message translates to:
  /// **'Back to reminders'**
  String get patientAlertBack;

  /// No description provided for @patientDayToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get patientDayToday;

  /// No description provided for @patientDayYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get patientDayYesterday;

  /// No description provided for @patientDayOffline.
  ///
  /// In en, this message translates to:
  /// **'Your saved day is here. Updates will arrive when connected.'**
  String get patientDayOffline;

  /// No description provided for @patientDayEmpty.
  ///
  /// In en, this message translates to:
  /// **'Moments from your day will appear here'**
  String get patientDayEmpty;

  /// No description provided for @patientDayDetailPending.
  ///
  /// In en, this message translates to:
  /// **'Memory details will be available soon.'**
  String get patientDayDetailPending;

  /// No description provided for @patientDayMet.
  ///
  /// In en, this message translates to:
  /// **'You met {name} at {time}'**
  String patientDayMet(String name, String time);

  /// No description provided for @patientDayEncounter.
  ///
  /// In en, this message translates to:
  /// **'You met someone at {time}'**
  String patientDayEncounter(String time);

  /// No description provided for @patientDayTalk.
  ///
  /// In en, this message translates to:
  /// **'A conversation at {time}'**
  String patientDayTalk(String time);

  /// No description provided for @patientDayReminder.
  ///
  /// In en, this message translates to:
  /// **'A reminder at {time}'**
  String patientDayReminder(String time);

  /// No description provided for @patientDayRecording.
  ///
  /// In en, this message translates to:
  /// **'A recording at {time}'**
  String patientDayRecording(String time);

  /// No description provided for @patientDayMoment.
  ///
  /// In en, this message translates to:
  /// **'A moment at {time}'**
  String patientDayMoment(String time);

  /// No description provided for @patientDayDocument.
  ///
  /// In en, this message translates to:
  /// **'A document at {time}'**
  String patientDayDocument(String time);

  /// No description provided for @patientDayQuestion.
  ///
  /// In en, this message translates to:
  /// **'You asked a question at {time}'**
  String patientDayQuestion(String time);

  /// No description provided for @patientDayGame.
  ///
  /// In en, this message translates to:
  /// **'A game at {time}'**
  String patientDayGame(String time);

  /// No description provided for @patientDayPaused.
  ///
  /// In en, this message translates to:
  /// **'Memory paused at {time}'**
  String patientDayPaused(String time);

  /// No description provided for @patientDayResumed.
  ///
  /// In en, this message translates to:
  /// **'Memory resumed at {time}'**
  String patientDayResumed(String time);

  /// No description provided for @patientDayEvent.
  ///
  /// In en, this message translates to:
  /// **'A moment from your day at {time}'**
  String patientDayEvent(String time);
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

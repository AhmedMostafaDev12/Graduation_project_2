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
  String get fullNameHint => 'Enter your full name';

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
  String get patientNameHint => 'Enter patient\'s full name';

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

  @override
  String get permissionsTitle => 'Permissions';

  @override
  String get permissionsStep => 'Step 3 of 3';

  @override
  String get permissionsIntro =>
      'Remori needs these permissions to help keep the glasses connected throughout the day.';

  @override
  String get permissionsCaregiverIntro =>
      'Allow notifications to receive reminders on this phone.';

  @override
  String get permissionBluetooth => 'Bluetooth';

  @override
  String get permissionBluetoothDetail => 'Connect to the glasses';

  @override
  String get permissionNotifications => 'Notifications';

  @override
  String get permissionNotificationsDetail => 'Receive reminders on the phone';

  @override
  String get permissionLocation => 'Location';

  @override
  String get permissionLocationDetail => 'For location-related assistance';

  @override
  String get permissionBackground => 'Background activity';

  @override
  String get permissionBackgroundDetail =>
      'Keep the glasses connected and syncing';

  @override
  String get permissionGranted => 'Granted';

  @override
  String get permissionAllow => 'Allow';

  @override
  String get permissionChecking => 'Checking…';

  @override
  String get permissionLimited => 'Limited access';

  @override
  String get permissionSettings => 'Settings';

  @override
  String get permissionsHandoverTitle => 'Ready for handover?';

  @override
  String get permissionsHandoverPending =>
      'Patient handover will be available when the glasses connection is ready. You can continue in caregiver mode now.';

  @override
  String get permissionsPatientMode => 'Give phone to patient → patient mode';

  @override
  String get permissionsCaregiverMode => 'Continue on caregiver mode';

  @override
  String get permissionsReadFailed =>
      'Unable to update permissions. Please try again.';

  @override
  String get permissionsUnsupported =>
      'Manage permissions on an Android or iOS phone. You can continue in caregiver mode.';

  @override
  String get permissionsHandoverReady =>
      'Once setup is complete, hand this phone to the patient to enter Patient Mode.';

  @override
  String get permissionsHandoverFailed =>
      'Unable to enter Patient Mode. Check your connection and try again.';

  @override
  String get homeSwitchPatient => 'Switch patient';

  @override
  String get homeLoading => 'Loading Home…';

  @override
  String get homeLoadFailed =>
      'Unable to load Home. Check your connection and try again.';

  @override
  String get homeOffline => 'Showing saved data. Unable to update Home.';

  @override
  String get homeRetry => 'Retry';

  @override
  String get homeNoPatients => 'No patients are linked to your account yet.';

  @override
  String get homeGlasses => 'Glasses';

  @override
  String get homeConnected => 'Connected';

  @override
  String get homeDisconnected => 'Disconnected';

  @override
  String get homeNotPaired => 'Not paired';

  @override
  String get homeUnknown => '—';

  @override
  String get homeMemoryOff => 'Memory: Off';

  @override
  String get homeMemoryPaused => 'Memory: Paused';

  @override
  String get homeMemoryCapturing => 'Memory: Capturing';

  @override
  String get homeMemoryEnabled => 'Memory: Enabled';

  @override
  String get homeJustNow => 'just now';

  @override
  String homeMinutesAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min ago',
      one: '1 min ago',
      zero: 'just now',
    );
    return '$_temp0';
  }

  @override
  String homeDeviceDetail(String time, String battery) {
    return 'Last seen $time · Battery $battery';
  }

  @override
  String get homeOpenJournal => 'Open journal ›';

  @override
  String homeCachedDay(String date) {
    return 'Saved statistics for $date';
  }

  @override
  String get homePeopleMet => 'people met';

  @override
  String get homeRemindersDone => 'reminders done';

  @override
  String get homeSnoozed => 'snoozed';

  @override
  String homeReminderProgress(String done, String total) {
    return '$done / $total';
  }

  @override
  String get homeAlerts => 'Alerts';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeNoAlerts => 'No recent alerts for this patient.';

  @override
  String get homeMissed => 'Missed';

  @override
  String get homeNewFace => 'New face';

  @override
  String get homeLowBattery => 'Battery';

  @override
  String get homeSummary => 'Summary';

  @override
  String get homeAlert => 'Alert';

  @override
  String get homeDailySummary => 'AI daily summary';

  @override
  String get homePhaseTwo => 'Phase 2';

  @override
  String get homeSummaryUnavailable =>
      'Daily summaries will be available in Phase 2.';

  @override
  String get homeReadMore => 'Read more ›';

  @override
  String get peopleAdd => '+ Add person';

  @override
  String get peopleActiveLabel => 'Active';

  @override
  String peopleActive(String count) {
    return 'Active ($count)';
  }

  @override
  String get peopleArchived => 'Archived';

  @override
  String peopleReviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new faces to review',
      one: '1 new face to review',
    );
    return '$_temp0';
  }

  @override
  String get peopleLoading => 'Loading people…';

  @override
  String get peopleLoadFailed =>
      'Unable to load people. Check your connection and try again.';

  @override
  String get peopleOffline =>
      'Showing saved people. Unable to update the list.';

  @override
  String get peopleNoActive => 'No active people have been added yet.';

  @override
  String get peopleNoArchived => 'No archived people.';

  @override
  String get peopleSon => 'Son';

  @override
  String get peopleDaughter => 'Daughter';

  @override
  String get peopleDoctor => 'Doctor';

  @override
  String get peopleNurse => 'Nurse';

  @override
  String get personUnavailable =>
      'Select a patient you manage from Home, then try again.';

  @override
  String get personAddTitle => 'Add person';

  @override
  String get personPhotos => 'Photos (1–5)';

  @override
  String get personCamera => 'Take photo';

  @override
  String get personGallery => 'Choose from gallery';

  @override
  String get personRemovePhoto => 'Remove photo';

  @override
  String personPhotoSlot(int number) {
    return 'Photo $number';
  }

  @override
  String get personPhotoTooLarge => 'Choose a photo no larger than 4 MB.';

  @override
  String get personPhotoUnsupported => 'Choose a JPEG or PNG photo.';

  @override
  String get personPhotoPickFailed =>
      'Unable to open the photo. Check permissions and try again.';

  @override
  String get personPhotosRequired => 'Add at least one photo.';

  @override
  String personPhotoInvalid(int number) {
    return 'Photo $number: unable to use this photo. Please replace it.';
  }

  @override
  String get personPhotoTip =>
      'Tip: a clear face, good light, one person per photo. Different angles help.';

  @override
  String get personName => 'Name';

  @override
  String get personNameHint => 'Enter full name';

  @override
  String get personRelationship => 'Relationship';

  @override
  String get personRelationshipHint => 'Enter relationship';

  @override
  String get personConsent => 'This person agreed to be recognized by Remori.';

  @override
  String get personConsentRequired =>
      'Confirm this person’s consent before saving.';

  @override
  String get personCacheRetry =>
      'Person saved. Tap Save person again to finish updating the list.';

  @override
  String get personSaveUncertain =>
      'Unable to confirm the save. Check People before trying again to avoid adding this person twice.';

  @override
  String get personSaveRetry =>
      'Unable to save this person. Check the fields and photos, then try again.';

  @override
  String get personSaving => 'Saving…';

  @override
  String get personSave => 'Save person';

  @override
  String get detailTitle => 'Person detail';

  @override
  String get detailEdit => 'Edit';

  @override
  String get detailSave => 'Save changes';

  @override
  String get detailCancel => 'Cancel';

  @override
  String get detailAddPhotos => '+ Add photos';

  @override
  String get detailSavePhotos => 'Save photos';

  @override
  String detailEnrolledBy(String relationship, String name) {
    return '$relationship · enrolled by $name';
  }

  @override
  String detailPhotoCount(String count) {
    return 'Enrolled photos ($count)';
  }

  @override
  String get detailPhotoLabel => 'Enrolled photo';

  @override
  String get detailPhotoTip =>
      'More photos from different angles improve recognition.';

  @override
  String get detailArchive => 'Archive person';

  @override
  String get detailArchiveHint =>
      'Archived people are no longer announced. You\'ll be asked to confirm.';

  @override
  String get detailArchiveConfirm =>
      'Archive this person? Their photos and face data will be deleted. Past journal entries keep their name.';

  @override
  String get detailRemoveConfirm =>
      'Remove this enrolled photo and its face data?';

  @override
  String get detailArchived => 'This person is archived.';

  @override
  String get detailLastPhoto =>
      'Add another photo first, or archive the person.';

  @override
  String get detailTooManyPhotos =>
      'A person can have up to 20 photos. Remove a photo first.';

  @override
  String get detailGone =>
      'This person or photo is no longer available. Refresh the list.';

  @override
  String get detailSavedRefresh =>
      'Changes saved. Refresh to finish updating this page.';

  @override
  String get detailRetryMessage =>
      'Unable to confirm the change. Refresh to check the current details before trying again.';

  @override
  String get reminderAdd => '+ Add';

  @override
  String get reminderToday => 'TODAY';

  @override
  String reminderTodayDate(String date) {
    return 'TODAY · $date';
  }

  @override
  String get reminderAll => 'ALL REMINDERS';

  @override
  String get reminderMed => 'Med';

  @override
  String get reminderAppt => 'Appt';

  @override
  String get reminderTask => 'Task';

  @override
  String get reminderDone => 'Done';

  @override
  String reminderDoneVia(String via) {
    return 'Done · $via';
  }

  @override
  String get reminderVoice => 'voice';

  @override
  String get reminderApp => 'app';

  @override
  String get reminderCaregiver => 'caregiver';

  @override
  String get reminderPending => 'Pending';

  @override
  String get reminderMissed => 'Missed';

  @override
  String get reminderSnoozed => 'Snoozed';

  @override
  String reminderSnoozedUntil(String time) {
    return 'Snoozed → $time';
  }

  @override
  String get reminderNoLogs => 'No reminder activity recorded today.';

  @override
  String get reminderNoSavedToday => 'No saved reminder activity for today.';

  @override
  String get reminderNone => 'No reminders have been added yet.';

  @override
  String get reminderCustomSchedule => 'Scheduled reminder';

  @override
  String reminderDaily(String times) {
    return 'Every day at $times';
  }

  @override
  String reminderWeekly(String days, String times) {
    return '$days at $times';
  }

  @override
  String reminderJoin(String first, String last) {
    return '$first and $last';
  }

  @override
  String get reminderMonday => 'Mondays';

  @override
  String get reminderTuesday => 'Tuesdays';

  @override
  String get reminderWednesday => 'Wednesdays';

  @override
  String get reminderThursday => 'Thursdays';

  @override
  String get reminderFriday => 'Fridays';

  @override
  String get reminderSaturday => 'Saturdays';

  @override
  String get reminderSunday => 'Sundays';

  @override
  String reminderEnabledLabel(String title) {
    return 'Enabled: $title';
  }

  @override
  String get reminderSavedRetry =>
      'Change saved. Retry to finish updating the list.';

  @override
  String get reminderOffline =>
      'Showing saved reminders. Unable to update; retry to check the latest state.';

  @override
  String get reminderLoadFailed =>
      'Unable to load reminders. Check your connection and try again.';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get patientGameCards => 'Card game';

  @override
  String get patientGamePicture => 'Name the picture';

  @override
  String get patientGameWords => 'Remember the words';

  @override
  String patientGameLastScore(String score) {
    return 'Last score: $score';
  }

  @override
  String get patientGameNone => 'No games yet';

  @override
  String get patientGameUnavailable => 'Last score is not available yet';

  @override
  String get patientGamesPending => 'Playing games will be available soon.';

  @override
  String get patientGamesOffline =>
      'We couldn’t check your latest scores. You can try again.';

  @override
  String get patientMemoryBack => 'Back';

  @override
  String get patientMemoryTitle => 'Your memory';

  @override
  String patientMemoryMet(String name) {
    return 'You met $name';
  }

  @override
  String get patientMemoryUnavailable =>
      'This memory is not available right now.';

  @override
  String get patientMemoryPhotoUnavailable =>
      'Your photo is not available right now.';

  @override
  String get patientMemoryVideoPending =>
      'This is a video memory. Watching videos will be available later.';

  @override
  String get patientMemoryDelete => 'Delete';

  @override
  String get patientMemoryDeleteHelp => 'We’ll ask before deleting';

  @override
  String get patientMemoryDeleteTitle => 'Delete this memory?';

  @override
  String get patientMemoryDeleteConfirm =>
      'The photo or video will be permanently deleted. You can keep it instead.';

  @override
  String get patientMemoryKeep => 'Keep memory';

  @override
  String get patientMemoryRemovedPending =>
      'The memory was deleted. Tap Retry to finish.';

  @override
  String get patientMemoryUncertain =>
      'Let’s check your memory before trying again.';

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

  @override
  String get reminderEditTitle => 'Edit reminder';

  @override
  String get reminderTitleLabel => 'Title';

  @override
  String get reminderTitleHint => 'Blood pressure pill';

  @override
  String get reminderSpeechLabel => 'What the glasses will say';

  @override
  String get reminderSpeechHint => 'ميعاد دواء الضغط';

  @override
  String get reminderTypeLabel => 'Type';

  @override
  String get reminderMedication => 'Medication';

  @override
  String get reminderAppointment => 'Appointment';

  @override
  String get reminderRepeatLabel => 'Repeat';

  @override
  String get reminderOnce => 'Once';

  @override
  String get reminderRepeatDaily => 'Daily';

  @override
  String get reminderRepeatWeekly => 'Weekly';

  @override
  String get reminderTimesLabel => 'Time(s)';

  @override
  String get reminderTimeHint => '09:00';

  @override
  String get reminderAddTime => '+ Add time';

  @override
  String get reminderRemoveTime => 'Remove time';

  @override
  String get reminderStartsLabel => 'Starts';

  @override
  String get reminderTimezoneLabel => 'Timezone';

  @override
  String get reminderSave => 'Save reminder';

  @override
  String get reminderSaving => 'Saving…';

  @override
  String get reminderDelete => 'Delete reminder';

  @override
  String get reminderDeleteConfirm =>
      'Delete this reminder? Recorded activity will be kept.';

  @override
  String get reminderUnavailable =>
      'This reminder is unavailable or you do not have permission to edit it.';

  @override
  String get reminderTitleRequired => 'Enter a title (up to 120 characters).';

  @override
  String get reminderSpeechTooLong =>
      'Use up to 200 characters for the spoken text.';

  @override
  String get reminderTimesRequired => 'Select 1–4 different times.';

  @override
  String get reminderDaysRequired => 'Select at least one day.';

  @override
  String get reminderTimezoneInvalid =>
      'Enter a valid timezone, such as Africa/Cairo.';

  @override
  String get reminderStartGap =>
      'A selected time does not exist on the start day because the clocks change. Choose another time.';

  @override
  String get reminderSchedulePreserved =>
      'This schedule is kept unchanged. You can edit the title, spoken text and type.';

  @override
  String get reminderWriteFailed =>
      'Unable to save the change. Please try again.';

  @override
  String get reminderWriteUncertain =>
      'Unable to confirm the change. Check the reminder list before trying again.';

  @override
  String get reminderFieldInvalid => 'Check the highlighted fields.';

  @override
  String get reminderWeekdaySunday => 'S';

  @override
  String get reminderWeekdayMonday => 'M';

  @override
  String get reminderWeekdayTuesday => 'T';

  @override
  String get reminderWeekdayWednesday => 'W';

  @override
  String get reminderWeekdayThursday => 'T';

  @override
  String get reminderWeekdayFriday => 'F';

  @override
  String get reminderWeekdaySaturday => 'S';

  @override
  String get alertsTitle => 'Alerts';

  @override
  String alertsUnread(String count) {
    return '$count unread';
  }

  @override
  String get alertsToday => 'TODAY';

  @override
  String get alertsYesterday => 'YESTERDAY';

  @override
  String get alertsSomeoneNew => 'Someone new';

  @override
  String get alertsLowBattery => 'Low battery';

  @override
  String get alertsMissedMedication => 'Missed medication';

  @override
  String get alertsDeviceOffline => 'Device offline';

  @override
  String get alertsSummaryReady => 'Daily summary ready';

  @override
  String alertsUnknownDescription(String patient) {
    return 'Someone new has been flagged for $patient. Review when available.';
  }

  @override
  String alertsBatteryDescription(String patient) {
    return 'The glasses battery is low for $patient.';
  }

  @override
  String alertsMissedDescription(String patient) {
    return 'A medication reminder was not confirmed for $patient.';
  }

  @override
  String alertsOfflineDescription(String patient) {
    return 'The device has lost contact for $patient.';
  }

  @override
  String alertsSummaryDescription(String patient) {
    return 'A daily summary is ready for $patient.';
  }

  @override
  String alertsOtherDescription(String patient) {
    return 'There is an alert for $patient.';
  }

  @override
  String get alertsNone => 'No alerts yet.';

  @override
  String get alertsLoadFailed =>
      'Unable to update alerts. Check your connection and try again.';

  @override
  String get alertsCached =>
      'Showing saved alerts. Retry to check the latest state.';

  @override
  String get alertsReadFailed =>
      'Unable to mark the alert as read. Please try again.';

  @override
  String get alertsCacheRetry =>
      'Alert marked as read. Retry to finish updating this phone.';

  @override
  String get alertsDestinationPending =>
      'Alert read. This destination will be available when its screen is ready.';

  @override
  String get unknownFacesTitle => 'New faces to review';

  @override
  String get unknownFacesIntro =>
      'People the glasses saw on 3 or more different days. Only you can name them; the glasses never guess.';

  @override
  String unknownFacesSeen(String times, String days) {
    return 'Seen $times times on $days days';
  }

  @override
  String unknownFacesDates(String first, String last) {
    return 'First seen $first · last seen $last';
  }

  @override
  String unknownFacesTodayTime(String time) {
    return 'today $time';
  }

  @override
  String get unknownFacesRetention =>
      'Photos of unknown people are deleted after 30 days, or right away if you dismiss them.';

  @override
  String get unknownFacesPending =>
      'Face review will be available when the review screen is ready.';

  @override
  String get unknownFacesEmpty => 'No new faces to review yet.';

  @override
  String get unknownFacesLoadFailed =>
      'Unable to update new faces. Check your connection and try again.';

  @override
  String get unknownFacesOffline =>
      'Showing saved counts and dates. Photos require a successful refresh.';

  @override
  String get unknownFacePhoto => 'Unknown person photo';

  @override
  String get unknownFacePhotoUnavailable => 'Photo unavailable';

  @override
  String get unknownFacesUnavailable =>
      'This patient\'s new faces are unavailable.';

  @override
  String get unknownDetailTitle => 'Who is this?';

  @override
  String get unknownDetailKnow => 'I know them';

  @override
  String get unknownDetailNameHint => 'Dr. Hany';

  @override
  String get unknownDetailRelationshipHint => 'Doctor';

  @override
  String get unknownDetailConsent => 'This person agreed to be recognized.';

  @override
  String get unknownDetailSave => 'Save as a known person';

  @override
  String get unknownDetailDismiss => 'Stranger, dismiss';

  @override
  String get unknownDetailDeleteHint => 'Dismissing deletes these photos.';

  @override
  String get unknownDetailDismissConfirm =>
      'Dismiss this stranger? Their photos will be deleted immediately. Journal sightings will remain without photos.';

  @override
  String get unknownDetailUnavailable =>
      'This face is no longer available. Return to New faces to check the list.';

  @override
  String get unknownDetailCacheRetry =>
      'Decision saved. Retry to finish updating this phone.';

  @override
  String get unknownDetailUncertain =>
      'Unable to confirm the decision. Refresh to check its current state before trying again.';

  @override
  String get unknownDetailNameRequired => 'Enter a name (up to 80 characters).';

  @override
  String get unknownDetailRelationshipRequired =>
      'Enter a relationship (up to 40 characters).';

  @override
  String unknownDetailSummary(
    String times,
    String days,
    String first,
    String last,
  ) {
    return 'Seen $times times on $days different days · first $first · last $last';
  }

  @override
  String get placesTitle => 'Saved places';

  @override
  String get placesAdd => '+ Add';

  @override
  String get placesIntro =>
      'Used when the patient asks the glasses \"Where am I?\". The phone matches its location to the nearest saved place.';

  @override
  String placesRadius(String meters) {
    return 'Radius $meters m';
  }

  @override
  String get placesEditingPending =>
      'Adding and editing places will be available when the place editor is ready.';

  @override
  String get placesEmpty => 'No saved places yet.';

  @override
  String get placesUnavailable =>
      'Saved places are unavailable. Select a patient and try again.';

  @override
  String get placesLoadFailed =>
      'Unable to update saved places. Check your connection and try again.';

  @override
  String get placesOffline =>
      'Showing saved places. Retry to check the latest list.';

  @override
  String get placeEditTitle => 'Edit place';

  @override
  String get placeName => 'Place name';

  @override
  String get placeNameHint => 'Home · البيت';

  @override
  String get placeSave => 'Save place';

  @override
  String get placeDelete => 'Delete place';

  @override
  String get placeDeleteConfirm =>
      'Delete this saved place? It will no longer be used for Where am I?';

  @override
  String get placeUnavailable =>
      'This place is unavailable or you do not have permission to edit it.';

  @override
  String get placeNameRequired => 'Enter a place name (up to 80 characters).';

  @override
  String get placeSelectPoint => 'Select the place on the map before saving.';

  @override
  String get placeLocating => 'Finding this phone\'s location...';

  @override
  String get placeDragPin => 'Drag the pin to the place';

  @override
  String get placePin => 'Selected place pin; drag to move';

  @override
  String get placeAttribution => '© OpenStreetMap contributors';

  @override
  String get placeMapUnavailable =>
      'The map is unavailable. Check your connection and try again.';

  @override
  String placeRadiusLabel(String meters) {
    return 'Radius: $meters m';
  }

  @override
  String get placeRadiusMinimum => '50 m';

  @override
  String get placeRadiusMaximum => '500 m';

  @override
  String get placeRadiusPreserved =>
      'The saved radius is kept unchanged until you move the slider.';

  @override
  String get placeCacheRetry =>
      'Change saved. Retry to finish updating this phone.';

  @override
  String get placeWriteUncertain =>
      'Unable to confirm the change. Return to Saved places and refresh before trying again.';

  @override
  String get placeWriteFailed =>
      'Unable to save the change. Check the details and try again.';

  @override
  String get journalAll => 'All';

  @override
  String get journalPeople => 'People';

  @override
  String get journalTalk => 'Talk';

  @override
  String get journalQuestions => 'Questions';

  @override
  String get journalMedia => 'Media';

  @override
  String get journalDocs => 'Docs';

  @override
  String get journalTitle => 'Journal';

  @override
  String get journalPreviousDay => 'Previous day';

  @override
  String get journalNextDay => 'Next day';

  @override
  String get journalLoadFailed =>
      'Could not refresh the journal. Please try again.';

  @override
  String get journalOffline =>
      'Showing saved journal text. Photos require a successful refresh.';

  @override
  String get journalUnavailable => 'Choose a patient to view their journal.';

  @override
  String get journalEmpty => 'No journal entries for this day and filter.';

  @override
  String get journalDetailsPending =>
      'Document details will be available when their screen is ready.';

  @override
  String get journalEncounter => 'Encounter';

  @override
  String get journalConversation => 'Conversation';

  @override
  String get journalQuestion => 'Question asked';

  @override
  String get journalReminder => 'Reminder';

  @override
  String get journalRecording => 'Recording';

  @override
  String get journalDocument => 'Document';

  @override
  String get journalNotable => 'Notable moment';

  @override
  String get journalGame => 'Game';

  @override
  String get journalNote => 'Note';

  @override
  String get journalActivity => 'Activity';

  @override
  String get journalUnknownPerson => 'Unknown person';

  @override
  String get journalRecorded => 'Recording captured';

  @override
  String get journalReminderActivity => 'Reminder activity recorded.';

  @override
  String get journalPaused => 'Memory paused';

  @override
  String get journalResumed => 'Memory resumed';

  @override
  String get journalPreviewUnavailable => 'Photo preview unavailable';

  @override
  String get journalPreview => 'Journal photo preview';

  @override
  String journalRecordingDuration(String duration) {
    return 'Recorded · $duration';
  }

  @override
  String journalWithPerson(String name) {
    return 'with $name';
  }

  @override
  String journalConversationDuration(String name, String minutes) {
    return 'with $name · $minutes min';
  }

  @override
  String get mediaPhoto => 'Photo';

  @override
  String get mediaVideo => 'Video';

  @override
  String get mediaUnavailable => 'This media is no longer available.';

  @override
  String get mediaDeletePhoto => 'Delete photo';

  @override
  String get mediaDeleteVideo => 'Delete video';

  @override
  String get mediaDeleteConfirm =>
      'Delete this item permanently? The file will be removed and the deletion recorded in the audit log.';

  @override
  String get mediaPhotoUnavailable =>
      'Photo unavailable. Refresh while online to view it.';

  @override
  String get mediaVideoPending =>
      'Video playback will be available when the video viewer is ready.';

  @override
  String mediaEncounter(String name, String relationship) {
    return 'Encounter with $name ($relationship)';
  }

  @override
  String get mediaKeyframe => 'keyframe from the glasses';

  @override
  String get mediaDocumentCapture => 'document captured by the glasses';

  @override
  String get mediaNotableCapture => 'moment captured by the glasses';

  @override
  String get mediaRequested => 'recorded at the patient’s request';

  @override
  String get mediaCaptured => 'captured by the glasses';

  @override
  String get mediaAiTags => 'AI tags:';

  @override
  String get mediaKept => 'Kept';

  @override
  String get mediaPin => 'Pin to keep';

  @override
  String get mediaExpired => 'Expired';

  @override
  String mediaAutoDeletes(String days) {
    return 'Auto-deletes in $days days';
  }

  @override
  String get mediaRetentionNote =>
      'Photos of other people expire after 30 days unless pinned';

  @override
  String get mediaCacheFailed =>
      'The change was saved. Retry to update the saved information on this phone.';

  @override
  String get mediaUncertain =>
      'The change could not be confirmed. Refresh before trying again.';

  @override
  String get mediaOffline =>
      'Could not refresh. Saved information is available; photos need an online refresh.';

  @override
  String get mediaAuditNote =>
      'You’ll be asked to confirm deletion. Deletions are recorded in the audit log.';

  @override
  String get documentsTitle => 'Documents';

  @override
  String get documentsAll => 'All';

  @override
  String get documentsReceipts => 'Receipts';

  @override
  String get documentsBills => 'Bills';

  @override
  String get documentsMedicationLabels => 'Medication labels';

  @override
  String get documentsReceipt => 'Receipt';

  @override
  String get documentsBill => 'Bill';

  @override
  String get documentsMedicationLabel => 'Medication label';

  @override
  String get documentsOther => 'Other document';

  @override
  String get documentsIntro =>
      'Captured by the glasses and read automatically.';

  @override
  String get documentsLoadFailed =>
      'Could not refresh documents. Please try again.';

  @override
  String get documentsOffline =>
      'Showing saved documents. Photos require an online refresh.';

  @override
  String get documentsUnavailable =>
      'Choose a patient to view their documents.';

  @override
  String get documentsEmpty => 'No documents in this category yet.';

  @override
  String get documentsDetailPending =>
      'Document details will be available when their screen is ready.';

  @override
  String get documentsPreviewUnavailable => 'Document preview unavailable';

  @override
  String get documentsPreview => 'Document preview';

  @override
  String get documentDetailUnavailable =>
      'This document is unavailable for the selected patient.';

  @override
  String get documentDetailOffline =>
      'Could not refresh. Showing saved document information; the photo needs an online refresh.';

  @override
  String get documentDetailPhotoUnavailable =>
      'Photo unavailable. Refresh while online to view it.';

  @override
  String get documentDetailPhoto => 'Document photo';

  @override
  String documentDetailCaptured(String date) {
    return 'Captured $date';
  }

  @override
  String get documentDetailFullText => 'Full text read from the photo';

  @override
  String get documentDetailNoText => 'No text was read from this photo.';

  @override
  String get documentFieldAmount => 'Amount';

  @override
  String get documentFieldDate => 'Date';

  @override
  String get documentFieldItems => 'Items';

  @override
  String get documentFieldStore => 'Store';

  @override
  String get documentFieldCompany => 'Company';

  @override
  String get documentFieldDueDate => 'Due date';

  @override
  String get documentFieldMedicine => 'Medicine';

  @override
  String get documentFieldStrength => 'Strength';

  @override
  String get documentFieldInstructions => 'How to take';

  @override
  String get documentFieldExpires => 'Expires';

  @override
  String get deviceTitle => 'Device';

  @override
  String get deviceGlasses => 'Remori glasses';

  @override
  String get deviceConnected => 'Connected';

  @override
  String get deviceOffline => 'Offline';

  @override
  String get deviceStatusUnavailable => 'Status unavailable';

  @override
  String get deviceSerial => 'Serial';

  @override
  String get deviceFirmware => 'Firmware';

  @override
  String get deviceBattery => 'Battery';

  @override
  String get deviceLastSeen => 'Last seen';

  @override
  String get deviceUnknown => 'Unavailable';

  @override
  String get deviceJustNow => 'Just now';

  @override
  String deviceMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min ago',
      one: '1 min ago',
    );
    return '$_temp0';
  }

  @override
  String deviceHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String deviceDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get deviceMemory => 'Conversation memory';

  @override
  String get deviceMemoryHelp =>
      'When off, the glasses stop capturing speech. Face recognition and reminders keep working. The patient can also pause it with a long press on the glasses.';

  @override
  String get deviceHeartbeatHelp =>
      'Connected means a heartbeat was received in the last 5 minutes. It does not confirm a direct Bluetooth connection. Offline values are last saved readings.';

  @override
  String get deviceRepair => 'Re-pair glasses';

  @override
  String get deviceUnpair => 'Unpair glasses';

  @override
  String deviceUnpairConfirm(String serial) {
    return 'Unpair $serial? Its patient phone token will stop working. You will need to pair the glasses again to reconnect.';
  }

  @override
  String get deviceUnavailable =>
      'Select an available patient to view their glasses.';

  @override
  String get deviceNone => 'No glasses are paired with this patient.';

  @override
  String get deviceLoadFailed =>
      'Could not refresh. Showing saved device readings. Check your connection and try again.';

  @override
  String get deviceSavedLocallyPending =>
      'The change was saved. Retry to finish updating this phone.';

  @override
  String get deviceUncertain =>
      'The change could not be confirmed. Refresh before making another change.';

  @override
  String get moreTitle => 'More';

  @override
  String get morePatientGroup => 'Patient';

  @override
  String get morePatientProfile => 'Patient profile';

  @override
  String get moreCaregivers => 'Caregivers';

  @override
  String get moreCaregiversPending => 'Caregiver management coming soon.';

  @override
  String get moreConsents => 'Consent records';

  @override
  String get moreConversationConsent => 'Conversation memory';

  @override
  String get moreCloudConsent => 'Cloud AI processing';

  @override
  String get moreFaceConsent => 'Face enrollment';

  @override
  String moreFaceConsentFor(String name) {
    return 'Face enrollment · $name';
  }

  @override
  String moreGiven(String date) {
    return 'given $date';
  }

  @override
  String moreRevoked(String date) {
    return 'revoked $date';
  }

  @override
  String get moreRevoke => 'Revoke';

  @override
  String get moreRevokeTitle => 'Revoke consent?';

  @override
  String get moreRevokeHelp =>
      'This removes permission for future processing covered by this consent. Existing records are not deleted.';

  @override
  String get moreRevokeFaceHelp =>
      'This archives the enrolled person and deletes their face data. The glasses will stop recognizing them.';

  @override
  String get moreNoConsents => 'No consent records.';

  @override
  String get moreConsentsUnavailable =>
      'Consent records are unavailable. Retry to check them.';

  @override
  String get moreJournal => 'Journal';

  @override
  String get moreJournalHelp => 'The day, hour by hour';

  @override
  String get morePlaces => 'Saved places';

  @override
  String get morePlacesHelp => 'Places for “Where am I?”';

  @override
  String morePlacesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places for “Where am I?”',
      one: '1 place for “Where am I?”',
      zero: 'No saved places for “Where am I?”',
    );
    return '$_temp0';
  }

  @override
  String get moreDocuments => 'Documents';

  @override
  String get moreDocumentsHelp => 'Receipts, bills, medication labels';

  @override
  String get moreDeviceHelp => 'Glasses · memory switch';

  @override
  String moreDeviceSerial(String serial) {
    return 'Glasses $serial · memory switch';
  }

  @override
  String get moreAccountGroup => 'Account';

  @override
  String get moreMyAccount => 'My account';

  @override
  String get moreAccountUnavailable => 'Account details are unavailable.';

  @override
  String get moreConnectedAccounts => 'Connected accounts';

  @override
  String get moreConnectedPending => 'Account linking coming soon.';

  @override
  String get moreLogout => 'Log out';

  @override
  String get moreUnavailable =>
      'Account details are unavailable. Check your connection and try again.';

  @override
  String get moreNoPatient => 'Select a patient from Home.';

  @override
  String get moreOffline =>
      'Could not complete the request. Showing saved information. Check your connection and try again.';

  @override
  String get morePending =>
      'The change was saved. Retry to finish updating this phone.';

  @override
  String get moreUncertain =>
      'The change could not be confirmed. Refresh before making another change.';

  @override
  String get moreFullName => 'Full name';

  @override
  String get moreNameHint => 'Enter patient\'s full name';

  @override
  String get moreLanguage => 'Preferred language';

  @override
  String get moreArabic => 'Arabic';

  @override
  String get moreEnglish => 'English';

  @override
  String get moreTimezone => 'Time zone';

  @override
  String get moreTimezoneHint => 'Africa/Cairo';

  @override
  String get moreProfileInvalid =>
      'Enter a name (up to 120 characters) and a valid time zone, such as Africa/Cairo.';

  @override
  String get moreSave => 'Save';

  @override
  String get caregiversUnavailable =>
      'Select an available patient to view their caregivers.';

  @override
  String get caregiversManager => 'Manager';

  @override
  String get caregiversViewer => 'Viewer';

  @override
  String get caregiversPrimary => 'Primary';

  @override
  String caregiversYou(String name) {
    return '$name (you)';
  }

  @override
  String get caregiversPermissionHelp =>
      'Managers can edit people, reminders and places. Viewers can only look.';

  @override
  String get caregiversAddTitle => 'Add a caregiver';

  @override
  String get caregiversExistingAccountHelp =>
      'Use an existing caregiver account\'s email. No invitation email is sent.';

  @override
  String get caregiversEmail => 'Email';

  @override
  String get caregiversEmailHint => 'Enter caregiver\'s email';

  @override
  String get caregiversEmailInvalid => 'Enter a valid email address.';

  @override
  String get caregiversRelationship => 'Relationship';

  @override
  String get caregiversRelationshipHint => 'Relationship to the patient';

  @override
  String get caregiversRelationshipInvalid =>
      'Enter their relationship to the patient.';

  @override
  String get caregiversPermission => 'Permission';

  @override
  String get caregiversAdd => 'Add caregiver';

  @override
  String get caregiversAdded => 'Caregiver added.';

  @override
  String get caregiversPending =>
      'Caregiver added. Retry to finish updating this phone.';

  @override
  String get caregiversUncertain =>
      'The result could not be confirmed. Refresh the caregiver list before trying again.';

  @override
  String get caregiversNotFound =>
      'No caregiver account was found with that email. They need to create an account first.';

  @override
  String get caregiversAlreadyLinked =>
      'This caregiver is already linked. Refresh to see the latest list.';

  @override
  String get caregiversManagerOnly =>
      'Only a managing caregiver can add another caregiver. Refresh to check your access.';

  @override
  String get caregiversOffline =>
      'Could not complete the request. Showing saved caregivers. Check your connection and try again.';

  @override
  String get caregiversEmpty => 'No linked caregivers are saved.';

  @override
  String get caregiversListUnavailable =>
      'The caregiver list is unavailable. Retry to check it.';

  @override
  String get caregiversMoreHelp => 'Linked caregivers and permissions';

  @override
  String caregiversLinkedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count linked caregivers',
      one: '1 linked caregiver',
      zero: 'No linked caregivers',
    );
    return '$_temp0';
  }

  @override
  String get todayGettingReady => 'Getting your day ready';

  @override
  String get todayMemoryOff => 'Memory is off';

  @override
  String get todayMemoryUnknown => 'Memory status unavailable';

  @override
  String get todayMemoryPaused => 'Memory is paused';

  @override
  String get todayMemoryOn => 'Memory is working';

  @override
  String get todayGlassesConnected => 'Glasses connected';

  @override
  String get todayGlassesAway => 'Glasses not connected';

  @override
  String get todayOffline =>
      'You can keep using your saved day. Updates will arrive when connected.';

  @override
  String get todayNextReminder => 'Next reminder';

  @override
  String get todayNoReminder => 'No reminders for now';

  @override
  String get todayDone => 'Done';

  @override
  String get todayLater => 'Later';

  @override
  String get todayPeopleMet => 'People you met today';

  @override
  String get todayNoPeople => 'People you meet will appear here';

  @override
  String get todayAskLater => 'Ask (Phase 2)';

  @override
  String get patientRemindersTitle => 'Today\'s reminders';

  @override
  String get patientRemindersEmpty => 'Your reminders will appear here';

  @override
  String get patientReminderPending => 'Still to do';

  @override
  String get patientReminderSnoozed => 'Later';

  @override
  String get patientReminderMissed => 'Time has passed';

  @override
  String patientAlertTitle(String title) {
    return 'Time for $title';
  }

  @override
  String get patientAlertUnavailable => 'Your reminders are in Reminders';

  @override
  String get patientAlertSaveFailed =>
      'That wasn\'t saved yet. Please try again.';

  @override
  String get patientAlertBack => 'Back to reminders';

  @override
  String get patientDayToday => 'Today';

  @override
  String get patientDayYesterday => 'Yesterday';

  @override
  String get patientDayOffline =>
      'Your saved day is here. Updates will arrive when connected.';

  @override
  String get patientDayEmpty => 'Moments from your day will appear here';

  @override
  String get patientDayDetailPending =>
      'Memory details will be available soon.';

  @override
  String patientDayMet(String name, String time) {
    return 'You met $name at $time';
  }

  @override
  String patientDayEncounter(String time) {
    return 'You met someone at $time';
  }

  @override
  String patientDayTalk(String time) {
    return 'A conversation at $time';
  }

  @override
  String patientDayReminder(String time) {
    return 'A reminder at $time';
  }

  @override
  String patientDayRecording(String time) {
    return 'A recording at $time';
  }

  @override
  String patientDayMoment(String time) {
    return 'A moment at $time';
  }

  @override
  String patientDayDocument(String time) {
    return 'A document at $time';
  }

  @override
  String patientDayQuestion(String time) {
    return 'You asked a question at $time';
  }

  @override
  String patientDayGame(String time) {
    return 'A game at $time';
  }

  @override
  String patientDayPaused(String time) {
    return 'Memory paused at $time';
  }

  @override
  String patientDayResumed(String time) {
    return 'Memory resumed at $time';
  }

  @override
  String patientDayEvent(String time) {
    return 'A moment from your day at $time';
  }
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get patientMemoryBack => 'رجوع';

  @override
  String get patientMemoryTitle => 'ذكراك';

  @override
  String patientMemoryMet(String name) {
    return 'قابلت $name';
  }

  @override
  String get patientMemoryUnavailable => 'الذكرى دي مش متاحة دلوقتي.';

  @override
  String get patientMemoryPhotoUnavailable => 'صورتك مش متاحة دلوقتي.';

  @override
  String get patientMemoryVideoPending =>
      'دي ذكرى فيديو. مشاهدة الفيديو هتكون متاحة بعدين.';

  @override
  String get patientMemoryDelete => 'امسح';

  @override
  String get patientMemoryDeleteHelp => 'هنسألك قبل ما نمسح';

  @override
  String get patientMemoryDeleteTitle => 'نمسح الذكرى دي؟';

  @override
  String get patientMemoryDeleteConfirm =>
      'الصورة أو الفيديو هيتحذف نهائيًا. تقدر تحتفظ بيه بدل ما تمسحه.';

  @override
  String get patientMemoryKeep => 'احتفظ بالذكرى';

  @override
  String get patientMemoryRemovedPending =>
      'الذكرى اتمسحت. اضغط حاول تاني عشان نكمّل.';

  @override
  String get patientMemoryUncertain =>
      'خلينا نطمن على الذكرى قبل ما نحاول تاني.';

  @override
  String get caregiverHome => 'الرئيسية';

  @override
  String get caregiverPeople => 'الأشخاص';

  @override
  String get reminders => 'التذكيرات';

  @override
  String get caregiverMore => 'المزيد';

  @override
  String get addReminder => 'إضافة تذكير';

  @override
  String get patientToday => 'اليوم';

  @override
  String get patientMyDay => 'يومي';

  @override
  String get patientGames => 'الألعاب';

  @override
  String get ask => 'اسأل';

  @override
  String get appName => 'ريموري';

  @override
  String get splashTagline => 'طبقة هادئة من الذاكرة\nترافقك دائمًا.';

  @override
  String get getStarted => 'ابدأ الآن';

  @override
  String get splashSupport => 'دعم للحظاتك اليومية.';

  @override
  String get modeSelectIntro =>
      'دعم للذاكرة للأشخاص الذين يعيشون مع ألزهايمر، ولمن يعتنون بهم.';

  @override
  String get modeCaregiver => 'أنا مقدم رعاية';

  @override
  String get modePatientPhone => 'هذا هاتف المريض';

  @override
  String get loginTitle => 'تسجيل دخول مقدم الرعاية';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get emailHint => 'أدخل بريدك الإلكتروني';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get passwordHint => 'أدخل كلمة المرور';

  @override
  String get forgotPassword => 'نسيت كلمة المرور';

  @override
  String get logIn => 'تسجيل الدخول';

  @override
  String get loggingIn => 'جارٍ تسجيل الدخول…';

  @override
  String get orLabel => 'أو';

  @override
  String get continueGoogle => 'المتابعة باستخدام Google';

  @override
  String get continueFacebook => 'المتابعة باستخدام Facebook';

  @override
  String get patientPhoneSetup => 'هل تُعدّ هاتف المريض لأول مرة؟';

  @override
  String get logInSetupPatient => 'تسجيل الدخول وإعداد هاتف المريض';

  @override
  String get noAccount => 'ليس لديك حساب؟';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get requiredField => 'هذا الحقل مطلوب';

  @override
  String get loginInvalidCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة';

  @override
  String get loginConnectionError => 'تحقق من اتصالك وحاول مرة أخرى';

  @override
  String get loginRetry => 'تعذر تسجيل الدخول. حاول مرة أخرى بعد قليل.';

  @override
  String get signupTitle => 'إنشاء حساب مقدم الرعاية';

  @override
  String get fullNameLabel => 'الاسم الكامل';

  @override
  String get fullNameHint => 'أدخل اسمك الكامل';

  @override
  String get phoneLabel => 'الهاتف';

  @override
  String get phoneHint => '+201000000000';

  @override
  String get alreadyAccount => 'لديك حساب بالفعل؟';

  @override
  String get signupLogIn => 'تسجيل الدخول';

  @override
  String get signingUp => 'جارٍ إنشاء الحساب…';

  @override
  String get signupPasswordLength => 'استخدم من 8 إلى 128 حرفًا';

  @override
  String get signupEmailTaken =>
      'يوجد حساب بهذا البريد الإلكتروني. سجّل الدخول.';

  @override
  String get signupCheckFields => 'تحقق من الحقول المحددة وحاول مرة أخرى.';

  @override
  String get signupInvalidField => 'تحقق من هذا الحقل';

  @override
  String get signupRetry => 'تعذر إنشاء الحساب. حاول مرة أخرى بعد قليل.';

  @override
  String get signupAccountCreated => 'تم إنشاء حسابك. سجّل الدخول للمتابعة.';

  @override
  String get newPatient => 'مريض جديد';

  @override
  String get patientStepOne => 'الخطوة 1 من 3';

  @override
  String get patientName => 'اسم المريض الكامل';

  @override
  String get patientNameHint => 'أدخل اسم المريض الكامل';

  @override
  String get patientRelationship => 'علاقتك بالمريض';

  @override
  String get patientBirthDate => 'تاريخ الميلاد (اختياري)';

  @override
  String get patientDateHint => 'DD / MM / YYYY';

  @override
  String get patientLanguage => 'اللغة المفضلة';

  @override
  String get patientEnglish => 'English الإنجليزية';

  @override
  String get patientArabic => 'العربية';

  @override
  String get patientTimezone => 'المنطقة الزمنية';

  @override
  String get patientConsent => 'الموافقة';

  @override
  String get conversationMemory => 'ذاكرة المحادثات';

  @override
  String get conversationMemoryDetail =>
      'توافق الأسرة على حفظ ذاكرة المحادثات. يُحذف الصوت بعد تحويله إلى نص.';

  @override
  String get cloudProcessing => 'السماح بمعالجة الذكاء الاصطناعي السحابية';

  @override
  String get cloudProcessingDetail =>
      'تحويل الصوت إلى نص، ومراجعة الصور، والملخصات';

  @override
  String get consentLater =>
      'يمكن تغيير الموافقة أو سحبها لاحقًا من المزيد ← الموافقة.';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get patientCreating => 'جارٍ إنشاء ملف المريض…';

  @override
  String get patientCreateRetry =>
      'تعذر إنشاء ملف المريض. حاول مرة أخرى بعد قليل.';

  @override
  String get patientInvalidDate => 'أدخل تاريخًا صحيحًا بصيغة DD / MM / YYYY';

  @override
  String get patientLoginAgain => 'سجّل الدخول مرة أخرى للمتابعة.';

  @override
  String get pairGlasses => 'ربط النظارة';

  @override
  String get pairStepTwo => 'الخطوة 2 من 3';

  @override
  String get pairScanTitle => 'امسح رمز QR للنظارة';

  @override
  String get pairScanPosition => 'ضع الرمز داخل منطقة المسح.';

  @override
  String get pairCameraHint => 'وجّه الكاميرا إلى رمز QR على علبة النظارة.';

  @override
  String get pairScanButton => 'مسح رمز QR';

  @override
  String get pairContinueHint => 'يمكنك المتابعة بعد ربط النظارة بالمريض.';

  @override
  String get pairScanStep => 'امسح رمز QR';

  @override
  String get pairScanStepDetail => 'اقرأ الرمز على علبة النظارة.';

  @override
  String get pairConnectStep => 'الاتصال بأمان';

  @override
  String get pairBluetoothPending => 'لم يكتمل اتصال البلوتوث بعد.';

  @override
  String get pairConfirmStep => 'تأكيد الربط';

  @override
  String get pairConfirmDetail => 'اربط النظارة بهذا المريض.';

  @override
  String get pairDeviceStatus => 'حالة الجهاز';

  @override
  String get pairStatusInitial => 'ستظهر هنا حالة الربط وتفاصيل الجهاز.';

  @override
  String get pairLinkedPending =>
      'تم ربط النظارة بالمريض. لم يكتمل اتصال البلوتوث بعد.';

  @override
  String get pairNeedsPatient => 'عُد إلى إعداد المريض للمتابعة.';

  @override
  String get pairLinking => 'جارٍ ربط النظارة…';

  @override
  String get pairAlreadyPaired => 'هذه النظارة مرتبطة بمريض آخر.';

  @override
  String get pairPatientMissing =>
      'لم يعد هذا المريض متاحًا. عُد إلى إعداد المريض.';

  @override
  String get pairInvalidCode =>
      'تحقق من رمز QR على علبة النظارة وحاول مرة أخرى.';

  @override
  String get pairSaveFailed =>
      'تم ربط النظارة، لكن تعذر الحفظ على هذا الهاتف. حاول مرة أخرى.';

  @override
  String get pairRetrySave => 'إعادة محاولة الربط';

  @override
  String get pairRetry => 'تعذر ربط النظارة. حاول مرة أخرى بعد قليل.';

  @override
  String get pairCameraPermission =>
      'اسمح باستخدام الكاميرا من إعدادات الهاتف، ثم أعد المسح.';

  @override
  String get pairCameraUnavailable =>
      'الكاميرا غير متاحة. حاول المسح مرة أخرى.';

  @override
  String pairSerial(String serial) {
    return 'الرقم التسلسلي: $serial';
  }

  @override
  String get permissionsTitle => 'الأذونات';

  @override
  String get permissionsStep => 'الخطوة 3 من 3';

  @override
  String get permissionsIntro =>
      'يحتاج ريموري إلى هذه الأذونات للمساعدة في إبقاء النظارة متصلة طوال اليوم.';

  @override
  String get permissionsCaregiverIntro =>
      'اسمح بالإشعارات لتلقي التذكيرات على هذا الهاتف.';

  @override
  String get permissionBluetooth => 'البلوتوث';

  @override
  String get permissionBluetoothDetail => 'الاتصال بالنظارة';

  @override
  String get permissionNotifications => 'الإشعارات';

  @override
  String get permissionNotificationsDetail => 'تلقي التذكيرات على الهاتف';

  @override
  String get permissionLocation => 'الموقع';

  @override
  String get permissionLocationDetail => 'للمساعدة المتعلقة بالموقع';

  @override
  String get permissionBackground => 'النشاط في الخلفية';

  @override
  String get permissionBackgroundDetail =>
      'إبقاء النظارة متصلة ومزامنة البيانات';

  @override
  String get permissionGranted => 'مسموح';

  @override
  String get permissionAllow => 'السماح';

  @override
  String get permissionChecking => 'جارٍ التحقق…';

  @override
  String get permissionLimited => 'وصول محدود';

  @override
  String get permissionSettings => 'الإعدادات';

  @override
  String get permissionsHandoverTitle => 'هل أنت مستعد لتسليم الهاتف؟';

  @override
  String get permissionsHandoverPending =>
      'سيتاح تسليم الهاتف للمريض عندما يصبح اتصال النظارة جاهزًا. يمكنك المتابعة في وضع مقدم الرعاية الآن.';

  @override
  String get permissionsPatientMode => 'إعطاء الهاتف للمريض ← وضع المريض';

  @override
  String get permissionsCaregiverMode => 'المتابعة في وضع مقدم الرعاية';

  @override
  String get permissionsReadFailed => 'تعذر تحديث الأذونات. حاول مرة أخرى.';

  @override
  String get permissionsUnsupported =>
      'يمكن إدارة الأذونات على هاتف أندرويد أو آيفون. يمكنك المتابعة في وضع مقدم الرعاية.';

  @override
  String get permissionsHandoverReady =>
      'بعد اكتمال الإعداد، أعطِ هذا الهاتف للمريض للدخول إلى وضع المريض.';

  @override
  String get permissionsHandoverFailed =>
      'تعذّر الدخول إلى وضع المريض. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get homeSwitchPatient => 'تغيير المريض';

  @override
  String get homeLoading => 'جارٍ تحميل الصفحة الرئيسية…';

  @override
  String get homeLoadFailed =>
      'تعذّر تحميل الصفحة الرئيسية. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get homeOffline =>
      'نعرض البيانات المحفوظة. تعذّر تحديث الصفحة الرئيسية.';

  @override
  String get homeRetry => 'إعادة المحاولة';

  @override
  String get homeNoPatients => 'لا يوجد مرضى مرتبطون بحسابك حتى الآن.';

  @override
  String get homeGlasses => 'النظارة';

  @override
  String get homeConnected => 'متصلة';

  @override
  String get homeDisconnected => 'غير متصلة';

  @override
  String get homeNotPaired => 'غير مقترنة';

  @override
  String get homeUnknown => '—';

  @override
  String get homeMemoryOff => 'الذاكرة: متوقفة';

  @override
  String get homeMemoryPaused => 'الذاكرة: متوقفة مؤقتًا';

  @override
  String get homeMemoryCapturing => 'الذاكرة: تسجّل';

  @override
  String get homeMemoryEnabled => 'الذاكرة: مفعّلة';

  @override
  String get homeJustNow => 'الآن';

  @override
  String homeMinutesAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'منذ $minutes دقيقة',
      many: 'منذ $minutes دقيقة',
      few: 'منذ $minutes دقائق',
      two: 'منذ دقيقتين',
      one: 'منذ دقيقة',
      zero: 'الآن',
    );
    return '$_temp0';
  }

  @override
  String homeDeviceDetail(String time, String battery) {
    return 'آخر اتصال $time · البطارية $battery';
  }

  @override
  String get homeOpenJournal => 'فتح سجل اليوم ‹';

  @override
  String homeCachedDay(String date) {
    return 'إحصاءات محفوظة ليوم $date';
  }

  @override
  String get homePeopleMet => 'أشخاص التقاهم';

  @override
  String get homeRemindersDone => 'تذكيرات مكتملة';

  @override
  String get homeSnoozed => 'مؤجلة';

  @override
  String homeReminderProgress(String done, String total) {
    return '$done / $total';
  }

  @override
  String get homeAlerts => 'التنبيهات';

  @override
  String get homeSeeAll => 'عرض الكل';

  @override
  String get homeNoAlerts => 'لا توجد تنبيهات حديثة لهذا المريض.';

  @override
  String get homeMissed => 'فائت';

  @override
  String get homeNewFace => 'وجه جديد';

  @override
  String get homeLowBattery => 'البطارية';

  @override
  String get homeSummary => 'الملخص';

  @override
  String get homeAlert => 'تنبيه';

  @override
  String get homeDailySummary => 'الملخص اليومي بالذكاء الاصطناعي';

  @override
  String get homePhaseTwo => 'المرحلة الثانية';

  @override
  String get homeSummaryUnavailable =>
      'ستتوفر الملخصات اليومية في المرحلة الثانية.';

  @override
  String get homeReadMore => 'اقرأ المزيد ‹';

  @override
  String get peopleAdd => '+ إضافة شخص';

  @override
  String get peopleActiveLabel => 'النشطون';

  @override
  String peopleActive(String count) {
    return 'النشطون ($count)';
  }

  @override
  String get peopleArchived => 'المؤرشفون';

  @override
  String peopleReviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count وجهًا جديدًا للمراجعة',
      few: '$count وجوه جديدة للمراجعة',
      two: 'وجهان جديدان للمراجعة',
      one: 'وجه جديد للمراجعة',
    );
    return '$_temp0';
  }

  @override
  String get peopleLoading => 'جارٍ تحميل الأشخاص…';

  @override
  String get peopleLoadFailed =>
      'تعذّر تحميل الأشخاص. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get peopleOffline => 'نعرض الأشخاص المحفوظين. تعذّر تحديث القائمة.';

  @override
  String get peopleNoActive => 'لم تتم إضافة أشخاص نشطين بعد.';

  @override
  String get peopleNoArchived => 'لا يوجد أشخاص مؤرشفون.';

  @override
  String get peopleSon => 'ابن';

  @override
  String get peopleDaughter => 'ابنة';

  @override
  String get peopleDoctor => 'طبيب';

  @override
  String get peopleNurse => 'ممرضة';

  @override
  String get personUnavailable =>
      'اختر مريضًا تدير حسابه من الرئيسية، ثم حاول مرة أخرى.';

  @override
  String get personAddTitle => 'إضافة شخص';

  @override
  String get personPhotos => 'الصور (١–٥)';

  @override
  String get personCamera => 'التقاط صورة';

  @override
  String get personGallery => 'اختيار من المعرض';

  @override
  String get personRemovePhoto => 'إزالة الصورة';

  @override
  String personPhotoSlot(int number) {
    return 'الصورة $number';
  }

  @override
  String get personPhotoTooLarge => 'اختر صورة لا يتجاوز حجمها ٤ ميجابايت.';

  @override
  String get personPhotoUnsupported => 'اختر صورة بصيغة JPEG أو PNG.';

  @override
  String get personPhotoPickFailed =>
      'تعذّر فتح الصورة. تحقق من الأذونات وحاول مرة أخرى.';

  @override
  String get personPhotosRequired => 'أضف صورة واحدة على الأقل.';

  @override
  String personPhotoInvalid(int number) {
    return 'الصورة $number: لا يمكن استخدام هذه الصورة. يرجى استبدالها.';
  }

  @override
  String get personPhotoTip =>
      'نصيحة: وجه واضح وإضاءة جيدة وشخص واحد في كل صورة. تساعد الزوايا المختلفة.';

  @override
  String get personName => 'الاسم';

  @override
  String get personNameHint => 'أدخل الاسم الكامل';

  @override
  String get personRelationship => 'صلة القرابة';

  @override
  String get personRelationshipHint => 'أدخل صلة القرابة';

  @override
  String get personConsent => 'وافق هذا الشخص على أن يتعرّف عليه ريموري.';

  @override
  String get personConsentRequired => 'أكد موافقة هذا الشخص قبل الحفظ.';

  @override
  String get personCacheRetry =>
      'تم حفظ الشخص. اضغط حفظ الشخص مجددًا لإكمال تحديث القائمة.';

  @override
  String get personSaveUncertain =>
      'تعذّر تأكيد الحفظ. تحقق من قائمة الأشخاص قبل المحاولة مجددًا لتجنب إضافة الشخص مرتين.';

  @override
  String get personSaveRetry =>
      'تعذّر حفظ الشخص. تحقق من الحقول والصور ثم حاول مجددًا.';

  @override
  String get personSaving => 'جارٍ الحفظ…';

  @override
  String get personSave => 'حفظ الشخص';

  @override
  String get detailTitle => 'تفاصيل الشخص';

  @override
  String get detailEdit => 'تعديل';

  @override
  String get detailSave => 'حفظ التغييرات';

  @override
  String get detailCancel => 'إلغاء';

  @override
  String get detailAddPhotos => '+ إضافة صور';

  @override
  String get detailSavePhotos => 'حفظ الصور';

  @override
  String detailEnrolledBy(String relationship, String name) {
    return '$relationship · أضافه $name';
  }

  @override
  String detailPhotoCount(String count) {
    return 'الصور المسجلة ($count)';
  }

  @override
  String get detailPhotoLabel => 'صورة مسجلة';

  @override
  String get detailPhotoTip =>
      'تساعد الصور الإضافية من زوايا مختلفة على تحسين التعرّف.';

  @override
  String get detailArchive => 'أرشفة الشخص';

  @override
  String get detailArchiveHint =>
      'لن يتم الإعلان عن الأشخاص المؤرشفين. سيُطلب منك التأكيد.';

  @override
  String get detailArchiveConfirm =>
      'هل تريد أرشفة هذا الشخص؟ ستُحذف صوره وبيانات وجهه. تحتفظ اليوميات السابقة باسمه.';

  @override
  String get detailRemoveConfirm =>
      'هل تريد حذف هذه الصورة المسجلة وبيانات وجهها؟';

  @override
  String get detailArchived => 'هذا الشخص مؤرشف.';

  @override
  String get detailLastPhoto => 'أضف صورة أخرى أولًا، أو أرشف الشخص.';

  @override
  String get detailTooManyPhotos =>
      'يمكن تسجيل ٢٠ صورة للشخص. احذف صورة أولًا.';

  @override
  String get detailGone =>
      'لم يعد هذا الشخص أو هذه الصورة متاحًا. حدّث القائمة.';

  @override
  String get detailSavedRefresh =>
      'تم حفظ التغييرات. حدّث الصفحة لإكمال عرضها.';

  @override
  String get detailRetryMessage =>
      'تعذّر تأكيد التغيير. حدّث الصفحة للتحقق من التفاصيل الحالية قبل المحاولة مجددًا.';

  @override
  String get reminderAdd => '+ إضافة';

  @override
  String get reminderToday => 'اليوم';

  @override
  String reminderTodayDate(String date) {
    return 'اليوم · $date';
  }

  @override
  String get reminderAll => 'كل التذكيرات';

  @override
  String get reminderMed => 'دواء';

  @override
  String get reminderAppt => 'موعد';

  @override
  String get reminderTask => 'مهمة';

  @override
  String get reminderDone => 'تم';

  @override
  String reminderDoneVia(String via) {
    return 'تم · $via';
  }

  @override
  String get reminderVoice => 'بالصوت';

  @override
  String get reminderApp => 'بالتطبيق';

  @override
  String get reminderCaregiver => 'بمقدم الرعاية';

  @override
  String get reminderPending => 'قيد الانتظار';

  @override
  String get reminderMissed => 'فات الموعد';

  @override
  String get reminderSnoozed => 'مؤجّل';

  @override
  String reminderSnoozedUntil(String time) {
    return 'مؤجّل ← $time';
  }

  @override
  String get reminderNoLogs => 'لم يُسجَّل نشاط للتذكيرات اليوم.';

  @override
  String get reminderNoSavedToday => 'لا يوجد نشاط محفوظ للتذكيرات اليوم.';

  @override
  String get reminderNone => 'لم تتم إضافة تذكيرات بعد.';

  @override
  String get reminderCustomSchedule => 'تذكير مجدول';

  @override
  String reminderDaily(String times) {
    return 'يوميًا الساعة $times';
  }

  @override
  String reminderWeekly(String days, String times) {
    return '$days الساعة $times';
  }

  @override
  String reminderJoin(String first, String last) {
    return '$first و$last';
  }

  @override
  String get reminderMonday => 'كل يوم اثنين';

  @override
  String get reminderTuesday => 'كل يوم ثلاثاء';

  @override
  String get reminderWednesday => 'كل يوم أربعاء';

  @override
  String get reminderThursday => 'كل يوم خميس';

  @override
  String get reminderFriday => 'كل يوم جمعة';

  @override
  String get reminderSaturday => 'كل يوم سبت';

  @override
  String get reminderSunday => 'كل يوم أحد';

  @override
  String reminderEnabledLabel(String title) {
    return 'مفعّل: $title';
  }

  @override
  String get reminderSavedRetry =>
      'تم حفظ التغيير. حاول مجددًا لإكمال تحديث القائمة.';

  @override
  String get reminderOffline =>
      'نعرض التذكيرات المحفوظة. تعذّر تحديثها؛ حاول مجددًا للتحقق من الحالة الحالية.';

  @override
  String get reminderLoadFailed =>
      'تعذّر تحميل التذكيرات. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get reminderEditTitle => 'تعديل التذكير';

  @override
  String get reminderTitleLabel => 'العنوان';

  @override
  String get reminderTitleHint => 'دواء ضغط الدم';

  @override
  String get reminderSpeechLabel => 'ما ستقوله النظارة';

  @override
  String get reminderSpeechHint => 'ميعاد دواء الضغط';

  @override
  String get reminderTypeLabel => 'النوع';

  @override
  String get reminderMedication => 'دواء';

  @override
  String get reminderAppointment => 'موعد';

  @override
  String get reminderRepeatLabel => 'التكرار';

  @override
  String get reminderOnce => 'مرة واحدة';

  @override
  String get reminderRepeatDaily => 'يوميًا';

  @override
  String get reminderRepeatWeekly => 'أسبوعيًا';

  @override
  String get reminderTimesLabel => 'الأوقات';

  @override
  String get reminderTimeHint => '٠٩:٠٠';

  @override
  String get reminderAddTime => '+ إضافة وقت';

  @override
  String get reminderRemoveTime => 'إزالة الوقت';

  @override
  String get reminderStartsLabel => 'يبدأ في';

  @override
  String get reminderTimezoneLabel => 'المنطقة الزمنية';

  @override
  String get reminderSave => 'حفظ التذكير';

  @override
  String get reminderSaving => 'جارٍ الحفظ…';

  @override
  String get reminderDelete => 'حذف التذكير';

  @override
  String get reminderDeleteConfirm =>
      'هل تريد حذف هذا التذكير؟ سيُحتفظ بالنشاط المسجل.';

  @override
  String get reminderUnavailable =>
      'هذا التذكير غير متاح أو ليس لديك صلاحية تعديله.';

  @override
  String get reminderTitleRequired => 'أدخل عنوانًا لا يتجاوز ١٢٠ حرفًا.';

  @override
  String get reminderSpeechTooLong => 'استخدم نصًا منطوقًا لا يتجاوز ٢٠٠ حرف.';

  @override
  String get reminderTimesRequired =>
      'اختر من وقت واحد إلى أربعة أوقات مختلفة.';

  @override
  String get reminderDaysRequired => 'اختر يومًا واحدًا على الأقل.';

  @override
  String get reminderTimezoneInvalid =>
      'أدخل منطقة زمنية صحيحة، مثل Africa/Cairo.';

  @override
  String get reminderStartGap =>
      'أحد الأوقات المختارة غير موجود في يوم البداية بسبب تغيير الساعة. اختر وقتًا آخر.';

  @override
  String get reminderSchedulePreserved =>
      'سيُحتفظ بهذا الجدول دون تغيير. يمكنك تعديل العنوان والنص المنطوق والنوع.';

  @override
  String get reminderWriteFailed => 'تعذر حفظ التغيير. حاول مرة أخرى.';

  @override
  String get reminderWriteUncertain =>
      'تعذر تأكيد التغيير. راجع قائمة التذكيرات قبل المحاولة مرة أخرى.';

  @override
  String get reminderFieldInvalid => 'راجع الحقول المحددة.';

  @override
  String get reminderWeekdaySunday => 'ح';

  @override
  String get reminderWeekdayMonday => 'ن';

  @override
  String get reminderWeekdayTuesday => 'ث';

  @override
  String get reminderWeekdayWednesday => 'ر';

  @override
  String get reminderWeekdayThursday => 'خ';

  @override
  String get reminderWeekdayFriday => 'ج';

  @override
  String get reminderWeekdaySaturday => 'س';

  @override
  String get alertsTitle => 'التنبيهات';

  @override
  String alertsUnread(String count) {
    return '$count غير مقروءة';
  }

  @override
  String get alertsToday => 'اليوم';

  @override
  String get alertsYesterday => 'أمس';

  @override
  String get alertsSomeoneNew => 'شخص جديد';

  @override
  String get alertsLowBattery => 'بطارية منخفضة';

  @override
  String get alertsMissedMedication => 'دواء لم يُؤكد';

  @override
  String get alertsDeviceOffline => 'الجهاز غير متصل';

  @override
  String get alertsSummaryReady => 'ملخص اليوم جاهز';

  @override
  String alertsUnknownDescription(String patient) {
    return 'تم رصد شخص جديد لدى $patient. يمكن مراجعته عند توفر الصفحة.';
  }

  @override
  String alertsBatteryDescription(String patient) {
    return 'بطارية نظارة $patient منخفضة.';
  }

  @override
  String alertsMissedDescription(String patient) {
    return 'لم يُؤكد تذكير دواء لدى $patient.';
  }

  @override
  String alertsOfflineDescription(String patient) {
    return 'انقطع الاتصال بجهاز $patient.';
  }

  @override
  String alertsSummaryDescription(String patient) {
    return 'ملخص يوم $patient جاهز.';
  }

  @override
  String alertsOtherDescription(String patient) {
    return 'يوجد تنبيه يخص $patient.';
  }

  @override
  String get alertsNone => 'لا توجد تنبيهات بعد.';

  @override
  String get alertsLoadFailed =>
      'تعذر تحديث التنبيهات. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get alertsCached =>
      'تُعرض التنبيهات المحفوظة. أعد المحاولة للتحقق من آخر تحديث.';

  @override
  String get alertsReadFailed =>
      'تعذر وضع علامة مقروء على التنبيه. حاول مرة أخرى.';

  @override
  String get alertsCacheRetry =>
      'تمت قراءة التنبيه. أعد المحاولة لإكمال التحديث على هذا الهاتف.';

  @override
  String get alertsDestinationPending =>
      'تمت قراءة التنبيه. ستتوفر وجهته عند اكتمال الصفحة الخاصة بها.';

  @override
  String get unknownFacesTitle => 'وجوه جديدة للمراجعة';

  @override
  String get unknownFacesIntro =>
      'أشخاص رأتهم النظارة في ثلاثة أيام مختلفة أو أكثر. أنت وحدك تسميهم؛ النظارة لا تخمّن أبدًا.';

  @override
  String unknownFacesSeen(String times, String days) {
    return 'شوهد $times مرات في $days أيام';
  }

  @override
  String unknownFacesDates(String first, String last) {
    return 'أول ظهور $first · آخر ظهور $last';
  }

  @override
  String unknownFacesTodayTime(String time) {
    return 'اليوم $time';
  }

  @override
  String get unknownFacesRetention =>
      'تُحذف صور الأشخاص غير المعروفين بعد ٣٠ يومًا، أو فورًا إذا تجاهلتهم.';

  @override
  String get unknownFacesPending =>
      'ستتوفر مراجعة الوجوه عند اكتمال صفحة المراجعة.';

  @override
  String get unknownFacesEmpty => 'لا توجد وجوه جديدة للمراجعة بعد.';

  @override
  String get unknownFacesLoadFailed =>
      'تعذر تحديث الوجوه الجديدة. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get unknownFacesOffline =>
      'تُعرض الأعداد والتواريخ المحفوظة. تتطلب الصور تحديثًا ناجحًا.';

  @override
  String get unknownFacePhoto => 'صورة شخص غير معروف';

  @override
  String get unknownFacePhotoUnavailable => 'الصورة غير متاحة';

  @override
  String get unknownFacesUnavailable => 'الوجوه الجديدة لهذا المريض غير متاحة.';

  @override
  String get unknownDetailTitle => 'من هذا الشخص؟';

  @override
  String get unknownDetailKnow => 'أعرف هذا الشخص';

  @override
  String get unknownDetailNameHint => 'د. هاني';

  @override
  String get unknownDetailRelationshipHint => 'طبيب';

  @override
  String get unknownDetailConsent => 'وافق هذا الشخص على التعرّف عليه.';

  @override
  String get unknownDetailSave => 'حفظ كشخص معروف';

  @override
  String get unknownDetailDismiss => 'شخص غريب، تجاهل';

  @override
  String get unknownDetailDeleteHint => 'التجاهل يحذف هذه الصور.';

  @override
  String get unknownDetailDismissConfirm =>
      'هل تريد تجاهل هذا الشخص الغريب؟ ستُحذف صوره فورًا. ستبقى مرات رؤيته في سجل اليوم دون صور.';

  @override
  String get unknownDetailUnavailable =>
      'لم يعد هذا الوجه متاحًا. ارجع إلى الوجوه الجديدة للتحقق من القائمة.';

  @override
  String get unknownDetailCacheRetry =>
      'تم حفظ القرار. أعد المحاولة لإكمال تحديث هذا الهاتف.';

  @override
  String get unknownDetailUncertain =>
      'تعذّر تأكيد القرار. حدّث الصفحة للتحقق من حالته قبل المحاولة مجددًا.';

  @override
  String get unknownDetailNameRequired => 'أدخل اسمًا (حتى ٨٠ حرفًا).';

  @override
  String get unknownDetailRelationshipRequired =>
      'أدخل صلة القرابة أو العلاقة (حتى ٤٠ حرفًا).';

  @override
  String unknownDetailSummary(
    String times,
    String days,
    String first,
    String last,
  ) {
    return 'شوهد $times مرات في $days أيام مختلفة · أول مرة $first · آخر مرة $last';
  }

  @override
  String get placesTitle => 'الأماكن المحفوظة';

  @override
  String get placesAdd => '+ إضافة';

  @override
  String get placesIntro =>
      'تُستخدم عندما يسأل المريض النظارة «أين أنا؟». يطابق الهاتف موقعه مع أقرب مكان محفوظ.';

  @override
  String placesRadius(String meters) {
    return 'نطاق $meters م';
  }

  @override
  String get placesEditingPending =>
      'ستتوفر إضافة الأماكن وتعديلها عند اكتمال محرر الأماكن.';

  @override
  String get placesEmpty => 'لا توجد أماكن محفوظة بعد.';

  @override
  String get placesUnavailable =>
      'الأماكن المحفوظة غير متاحة. اختر مريضًا وأعد المحاولة.';

  @override
  String get placesLoadFailed =>
      'تعذّر تحديث الأماكن المحفوظة. تحقق من اتصالك وأعد المحاولة.';

  @override
  String get placesOffline =>
      'نعرض الأماكن المحفوظة. أعد المحاولة للتحقق من أحدث قائمة.';

  @override
  String get placeEditTitle => 'تعديل المكان';

  @override
  String get placeName => 'اسم المكان';

  @override
  String get placeNameHint => 'البيت · Home';

  @override
  String get placeSave => 'حفظ المكان';

  @override
  String get placeDelete => 'حذف المكان';

  @override
  String get placeDeleteConfirm =>
      'هل تريد حذف هذا المكان المحفوظ؟ لن يُستخدم بعد ذلك للإجابة عن «أين أنا؟».';

  @override
  String get placeUnavailable => 'هذا المكان غير متاح أو ليس لديك إذن بتعديله.';

  @override
  String get placeNameRequired => 'أدخل اسمًا للمكان (حتى ٨٠ حرفًا).';

  @override
  String get placeSelectPoint => 'اختر المكان على الخريطة قبل الحفظ.';

  @override
  String get placeLocating => 'جارٍ تحديد موقع هذا الهاتف…';

  @override
  String get placeDragPin => 'اسحب العلامة إلى المكان';

  @override
  String get placePin => 'علامة المكان المختار؛ اسحبها لتغيير الموقع';

  @override
  String get placeAttribution => '© مساهمو OpenStreetMap';

  @override
  String get placeMapUnavailable =>
      'الخريطة غير متاحة. تحقق من اتصالك وأعد المحاولة.';

  @override
  String placeRadiusLabel(String meters) {
    return 'النطاق: $meters م';
  }

  @override
  String get placeRadiusMinimum => '٥٠ م';

  @override
  String get placeRadiusMaximum => '٥٠٠ م';

  @override
  String get placeRadiusPreserved =>
      'يبقى النطاق المحفوظ كما هو حتى تحرّك شريط النطاق.';

  @override
  String get placeCacheRetry =>
      'تم حفظ التغيير. أعد المحاولة لإكمال تحديث هذا الهاتف.';

  @override
  String get placeWriteUncertain =>
      'تعذّر تأكيد التغيير. ارجع إلى الأماكن المحفوظة وحدّث القائمة قبل المحاولة مجددًا.';

  @override
  String get placeWriteFailed =>
      'تعذّر حفظ التغيير. تحقق من التفاصيل وأعد المحاولة.';

  @override
  String get journalAll => 'الكل';

  @override
  String get journalPeople => 'الأشخاص';

  @override
  String get journalTalk => 'المحادثات';

  @override
  String get journalQuestions => 'الأسئلة';

  @override
  String get journalMedia => 'الوسائط';

  @override
  String get journalDocs => 'المستندات';

  @override
  String get journalTitle => 'اليوميات';

  @override
  String get journalPreviousDay => 'اليوم السابق';

  @override
  String get journalNextDay => 'اليوم التالي';

  @override
  String get journalLoadFailed => 'تعذر تحديث اليوميات. حاول مرة أخرى.';

  @override
  String get journalOffline =>
      'نعرض النص المحفوظ من اليوميات. تتطلب الصور تحديثًا ناجحًا.';

  @override
  String get journalUnavailable => 'اختر مريضًا لعرض يومياته.';

  @override
  String get journalEmpty => 'لا توجد أحداث لهذا اليوم ضمن هذا التصنيف.';

  @override
  String get journalDetailsPending =>
      'ستتاح تفاصيل المستندات عند اكتمال شاشتها.';

  @override
  String get journalEncounter => 'لقاء';

  @override
  String get journalConversation => 'محادثة';

  @override
  String get journalQuestion => 'سؤال';

  @override
  String get journalReminder => 'تذكير';

  @override
  String get journalRecording => 'تسجيل';

  @override
  String get journalDocument => 'مستند';

  @override
  String get journalNotable => 'لحظة مميزة';

  @override
  String get journalGame => 'لعبة';

  @override
  String get journalNote => 'ملاحظة';

  @override
  String get journalActivity => 'حدث';

  @override
  String get journalUnknownPerson => 'شخص غير معروف';

  @override
  String get journalRecorded => 'تم التقاط تسجيل';

  @override
  String get journalReminderActivity => 'تم تسجيل حدث تذكير.';

  @override
  String get journalPaused => 'تم إيقاف الذاكرة مؤقتًا';

  @override
  String get journalResumed => 'تم استئناف الذاكرة';

  @override
  String get journalPreviewUnavailable => 'معاينة الصورة غير متاحة';

  @override
  String get journalPreview => 'معاينة صورة من اليوميات';

  @override
  String journalRecordingDuration(String duration) {
    return 'تسجيل · $duration';
  }

  @override
  String journalWithPerson(String name) {
    return 'مع $name';
  }

  @override
  String journalConversationDuration(String name, String minutes) {
    return 'مع $name · $minutes دقيقة';
  }

  @override
  String get mediaPhoto => 'صورة';

  @override
  String get mediaVideo => 'فيديو';

  @override
  String get mediaUnavailable => 'لم تعد هذه الوسائط متاحة.';

  @override
  String get mediaDeletePhoto => 'حذف الصورة';

  @override
  String get mediaDeleteVideo => 'حذف الفيديو';

  @override
  String get mediaDeleteConfirm =>
      'هل تريد حذف هذا العنصر نهائيًا؟ سيُحذف الملف ويُسجّل الحذف في سجل التدقيق.';

  @override
  String get mediaPhotoUnavailable =>
      'الصورة غير متاحة. حدّث الصفحة أثناء الاتصال لعرضها.';

  @override
  String get mediaVideoPending =>
      'ستتاح مشاهدة الفيديو عند اكتمال شاشة الفيديو.';

  @override
  String mediaEncounter(String name, String relationship) {
    return 'لقاء مع $name ($relationship)';
  }

  @override
  String get mediaKeyframe => 'صورة من النظارة أثناء اللقاء';

  @override
  String get mediaDocumentCapture => 'مستند التقطته النظارة';

  @override
  String get mediaNotableCapture => 'لحظة التقطتها النظارة';

  @override
  String get mediaRequested => 'تسجيل بطلب المريض';

  @override
  String get mediaCaptured => 'التقطته النظارة';

  @override
  String get mediaAiTags => 'وسوم الذكاء الاصطناعي:';

  @override
  String get mediaKept => 'محفوظة';

  @override
  String get mediaPin => 'تثبيت للاحتفاظ';

  @override
  String get mediaExpired => 'انتهت الصلاحية';

  @override
  String mediaAutoDeletes(String days) {
    return 'تُحذف تلقائيًا خلال $days يومًا';
  }

  @override
  String get mediaRetentionNote =>
      'تنتهي صلاحية صور الآخرين بعد ٣٠ يومًا ما لم تُثبّت';

  @override
  String get mediaCacheFailed =>
      'تم حفظ التغيير. أعد المحاولة لتحديث المعلومات المحفوظة على هذا الهاتف.';

  @override
  String get mediaUncertain =>
      'تعذر تأكيد التغيير. حدّث الصفحة قبل المحاولة مجددًا.';

  @override
  String get mediaOffline =>
      'تعذر التحديث. المعلومات المحفوظة متاحة؛ عرض الصور يتطلب تحديثًا عبر الإنترنت.';

  @override
  String get mediaAuditNote =>
      'سيُطلب منك تأكيد الحذف. تُسجّل عمليات الحذف في سجل التدقيق.';

  @override
  String get documentsTitle => 'المستندات';

  @override
  String get documentsAll => 'الكل';

  @override
  String get documentsReceipts => 'الإيصالات';

  @override
  String get documentsBills => 'الفواتير';

  @override
  String get documentsMedicationLabels => 'ملصقات الأدوية';

  @override
  String get documentsReceipt => 'إيصال';

  @override
  String get documentsBill => 'فاتورة';

  @override
  String get documentsMedicationLabel => 'ملصق دواء';

  @override
  String get documentsOther => 'مستند آخر';

  @override
  String get documentsIntro => 'تلتقطها النظارة وتُقرأ تلقائيًا.';

  @override
  String get documentsLoadFailed => 'تعذر تحديث المستندات. حاول مرة أخرى.';

  @override
  String get documentsOffline =>
      'نعرض المستندات المحفوظة. تتطلب الصور تحديثًا عبر الإنترنت.';

  @override
  String get documentsUnavailable => 'اختر مريضًا لعرض مستنداته.';

  @override
  String get documentsEmpty => 'لا توجد مستندات في هذا التصنيف حتى الآن.';

  @override
  String get documentsDetailPending =>
      'ستتاح تفاصيل المستندات عند اكتمال شاشتها.';

  @override
  String get documentsPreviewUnavailable => 'معاينة المستند غير متاحة';

  @override
  String get documentsPreview => 'معاينة مستند';

  @override
  String get documentDetailUnavailable => 'هذا المستند غير متاح للمريض المحدد.';

  @override
  String get documentDetailOffline =>
      'تعذر التحديث. نعرض معلومات المستند المحفوظة؛ تتطلب الصورة تحديثًا عبر الإنترنت.';

  @override
  String get documentDetailPhotoUnavailable =>
      'الصورة غير متاحة. حدّث الصفحة أثناء الاتصال لعرضها.';

  @override
  String get documentDetailPhoto => 'صورة المستند';

  @override
  String documentDetailCaptured(String date) {
    return 'التُقط في $date';
  }

  @override
  String get documentDetailFullText => 'النص الكامل المقروء من الصورة';

  @override
  String get documentDetailNoText => 'لم يُقرأ أي نص من هذه الصورة.';

  @override
  String get documentFieldAmount => 'المبلغ';

  @override
  String get documentFieldDate => 'التاريخ';

  @override
  String get documentFieldItems => 'الأصناف';

  @override
  String get documentFieldStore => 'المتجر';

  @override
  String get documentFieldCompany => 'الشركة';

  @override
  String get documentFieldDueDate => 'تاريخ الاستحقاق';

  @override
  String get documentFieldMedicine => 'الدواء';

  @override
  String get documentFieldStrength => 'التركيز';

  @override
  String get documentFieldInstructions => 'طريقة الاستخدام';

  @override
  String get documentFieldExpires => 'تاريخ الانتهاء';

  @override
  String get deviceTitle => 'الجهاز';

  @override
  String get deviceGlasses => 'نظارة ريموري';

  @override
  String get deviceConnected => 'متصلة';

  @override
  String get deviceOffline => 'غير متصلة';

  @override
  String get deviceStatusUnavailable => 'الحالة غير متاحة';

  @override
  String get deviceSerial => 'الرقم التسلسلي';

  @override
  String get deviceFirmware => 'إصدار البرنامج';

  @override
  String get deviceBattery => 'البطارية';

  @override
  String get deviceLastSeen => 'آخر اتصال';

  @override
  String get deviceUnknown => 'غير متاح';

  @override
  String get deviceJustNow => 'الآن';

  @override
  String deviceMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count دقيقة',
      many: 'منذ $count دقيقة',
      few: 'منذ $count دقائق',
      two: 'منذ دقيقتين',
      one: 'منذ دقيقة',
      zero: 'الآن',
    );
    return '$_temp0';
  }

  @override
  String deviceHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count ساعة',
      many: 'منذ $count ساعة',
      few: 'منذ $count ساعات',
      two: 'منذ ساعتين',
      one: 'منذ ساعة',
    );
    return '$_temp0';
  }

  @override
  String deviceDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count يوم',
      many: 'منذ $count يومًا',
      few: 'منذ $count أيام',
      two: 'منذ يومين',
      one: 'منذ يوم',
    );
    return '$_temp0';
  }

  @override
  String get deviceMemory => 'ذاكرة المحادثات';

  @override
  String get deviceMemoryHelp =>
      'عند إيقافها، تتوقف النظارة عن التقاط الكلام. يستمر التعرف على الوجوه والتذكيرات. يمكن للمريض أيضًا إيقافها مؤقتًا بضغطة مطوّلة على النظارة.';

  @override
  String get deviceHeartbeatHelp =>
      'متصلة تعني وصول إشارة من الجهاز خلال آخر ٥ دقائق، ولا تؤكد اتصال بلوتوث مباشرًا. عند انقطاع الشبكة، تظهر آخر قراءات محفوظة.';

  @override
  String get deviceRepair => 'إعادة إقران النظارة';

  @override
  String get deviceUnpair => 'إلغاء إقران النظارة';

  @override
  String deviceUnpairConfirm(String serial) {
    return 'هل تريد إلغاء إقران $serial؟ سيتوقف رمز هاتف المريض عن العمل. ستحتاج إلى إقران النظارة مجددًا لإعادة الاتصال.';
  }

  @override
  String get deviceUnavailable => 'اختر مريضًا متاحًا لعرض نظارته.';

  @override
  String get deviceNone => 'لا توجد نظارة مقترنة بهذا المريض.';

  @override
  String get deviceLoadFailed =>
      'تعذر التحديث. تظهر قراءات الجهاز المحفوظة. تحقق من اتصالك وحاول مجددًا.';

  @override
  String get deviceSavedLocallyPending =>
      'حُفظ التغيير. أعد المحاولة لإكمال تحديث هذا الهاتف.';

  @override
  String get deviceUncertain =>
      'تعذر تأكيد التغيير. حدّث البيانات قبل إجراء تغيير آخر.';

  @override
  String get moreTitle => 'المزيد';

  @override
  String get morePatientGroup => 'المريض';

  @override
  String get morePatientProfile => 'ملف المريض';

  @override
  String get moreCaregivers => 'مقدمو الرعاية';

  @override
  String get moreCaregiversPending => 'ستتوفر إدارة مقدمي الرعاية قريبًا.';

  @override
  String get moreConsents => 'سجلات الموافقة';

  @override
  String get moreConversationConsent => 'ذاكرة المحادثات';

  @override
  String get moreCloudConsent => 'المعالجة السحابية بالذكاء الاصطناعي';

  @override
  String get moreFaceConsent => 'تسجيل الوجه';

  @override
  String moreFaceConsentFor(String name) {
    return 'تسجيل الوجه · $name';
  }

  @override
  String moreGiven(String date) {
    return 'مُنحت في $date';
  }

  @override
  String moreRevoked(String date) {
    return 'سُحبت في $date';
  }

  @override
  String get moreRevoke => 'سحب';

  @override
  String get moreRevokeTitle => 'هل تريد سحب الموافقة؟';

  @override
  String get moreRevokeHelp =>
      'يُلغي هذا الإذن بالمعالجة المستقبلية التي تشملها هذه الموافقة. لا تُحذف السجلات الحالية.';

  @override
  String get moreRevokeFaceHelp =>
      'سيُؤرشف هذا الشخص وتُحذف بيانات وجهه. ستتوقف النظارة عن التعرف عليه.';

  @override
  String get moreNoConsents => 'لا توجد سجلات موافقة.';

  @override
  String get moreConsentsUnavailable =>
      'سجلات الموافقة غير متاحة. أعد المحاولة للتحقق منها.';

  @override
  String get moreJournal => 'اليوميات';

  @override
  String get moreJournalHelp => 'اليوم، ساعة بساعة';

  @override
  String get morePlaces => 'الأماكن المحفوظة';

  @override
  String get morePlacesHelp => 'أماكن لسؤال «أين أنا؟»';

  @override
  String morePlacesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مكان لسؤال «أين أنا؟»',
      many: '$count مكانًا لسؤال «أين أنا؟»',
      few: '$count أماكن لسؤال «أين أنا؟»',
      two: 'مكانان لسؤال «أين أنا؟»',
      one: 'مكان واحد لسؤال «أين أنا؟»',
      zero: 'لا توجد أماكن محفوظة لسؤال «أين أنا؟»',
    );
    return '$_temp0';
  }

  @override
  String get moreDocuments => 'المستندات';

  @override
  String get moreDocumentsHelp => 'الإيصالات والفواتير وملصقات الأدوية';

  @override
  String get moreDeviceHelp => 'النظارة · مفتاح الذاكرة';

  @override
  String moreDeviceSerial(String serial) {
    return 'النظارة $serial · مفتاح الذاكرة';
  }

  @override
  String get moreAccountGroup => 'الحساب';

  @override
  String get moreMyAccount => 'حسابي';

  @override
  String get moreAccountUnavailable => 'تفاصيل الحساب غير متاحة.';

  @override
  String get moreConnectedAccounts => 'الحسابات المرتبطة';

  @override
  String get moreConnectedPending => 'سيتوفر ربط الحسابات قريبًا.';

  @override
  String get moreLogout => 'تسجيل الخروج';

  @override
  String get moreUnavailable =>
      'تفاصيل الحساب غير متاحة. تحقق من اتصالك وحاول مجددًا.';

  @override
  String get moreNoPatient => 'اختر مريضًا من الرئيسية.';

  @override
  String get moreOffline =>
      'تعذر إكمال الطلب. تظهر المعلومات المحفوظة. تحقق من اتصالك وحاول مجددًا.';

  @override
  String get morePending =>
      'حُفظ التغيير. أعد المحاولة لإكمال تحديث هذا الهاتف.';

  @override
  String get moreUncertain =>
      'تعذر تأكيد التغيير. حدّث البيانات قبل إجراء تغيير آخر.';

  @override
  String get moreFullName => 'الاسم الكامل';

  @override
  String get moreNameHint => 'أدخل الاسم الكامل للمريض';

  @override
  String get moreLanguage => 'اللغة المفضلة';

  @override
  String get moreArabic => 'العربية';

  @override
  String get moreEnglish => 'الإنجليزية';

  @override
  String get moreTimezone => 'المنطقة الزمنية';

  @override
  String get moreTimezoneHint => 'Africa/Cairo';

  @override
  String get moreProfileInvalid =>
      'أدخل اسمًا لا يتجاوز ١٢٠ حرفًا ومنطقة زمنية صحيحة مثل Africa/Cairo.';

  @override
  String get moreSave => 'حفظ';

  @override
  String get caregiversUnavailable => 'اختر مريضًا متاحًا لعرض مقدمي الرعاية.';

  @override
  String get caregiversManager => 'مدير';

  @override
  String get caregiversViewer => 'مشاهد';

  @override
  String get caregiversPrimary => 'أساسي';

  @override
  String caregiversYou(String name) {
    return '$name (أنت)';
  }

  @override
  String get caregiversPermissionHelp =>
      'يمكن للمديرين تعديل الأشخاص والتذكيرات والأماكن. يمكن للمشاهدين الاطلاع فقط.';

  @override
  String get caregiversAddTitle => 'إضافة مقدم رعاية';

  @override
  String get caregiversExistingAccountHelp =>
      'استخدم البريد الإلكتروني لحساب مقدم رعاية موجود. لا تُرسل رسالة دعوة.';

  @override
  String get caregiversEmail => 'البريد الإلكتروني';

  @override
  String get caregiversEmailHint => 'أدخل بريد مقدم الرعاية الإلكتروني';

  @override
  String get caregiversEmailInvalid => 'أدخل بريدًا إلكترونيًا صحيحًا.';

  @override
  String get caregiversRelationship => 'صلة القرابة';

  @override
  String get caregiversRelationshipHint => 'العلاقة بالمريض';

  @override
  String get caregiversRelationshipInvalid => 'أدخل علاقته بالمريض.';

  @override
  String get caregiversPermission => 'الصلاحية';

  @override
  String get caregiversAdd => 'إضافة مقدم رعاية';

  @override
  String get caregiversAdded => 'أُضيف مقدم الرعاية.';

  @override
  String get caregiversPending =>
      'أُضيف مقدم الرعاية. أعد المحاولة لإكمال تحديث هذا الهاتف.';

  @override
  String get caregiversUncertain =>
      'تعذر تأكيد النتيجة. حدّث قائمة مقدمي الرعاية قبل المحاولة مجددًا.';

  @override
  String get caregiversNotFound =>
      'لم يُعثر على حساب مقدم رعاية بهذا البريد الإلكتروني. يجب إنشاء حساب أولًا.';

  @override
  String get caregiversAlreadyLinked =>
      'مقدم الرعاية مرتبط بالفعل. حدّث القائمة للاطلاع على أحدث البيانات.';

  @override
  String get caregiversManagerOnly =>
      'يمكن لمقدم الرعاية المدير فقط إضافة مقدم رعاية آخر. حدّث البيانات للتحقق من صلاحيتك.';

  @override
  String get caregiversOffline =>
      'تعذر إكمال الطلب. تظهر بيانات مقدمي الرعاية المحفوظة. تحقق من اتصالك وحاول مجددًا.';

  @override
  String get caregiversEmpty => 'لا توجد بيانات محفوظة لمقدمي رعاية مرتبطين.';

  @override
  String get caregiversListUnavailable =>
      'قائمة مقدمي الرعاية غير متاحة. أعد المحاولة للتحقق منها.';

  @override
  String get caregiversMoreHelp => 'مقدمو الرعاية المرتبطون والصلاحيات';

  @override
  String caregiversLinkedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مقدم رعاية مرتبط',
      many: '$count مقدم رعاية مرتبطًا',
      few: '$count مقدمي رعاية مرتبطين',
      two: 'مقدما رعاية مرتبطان',
      one: 'مقدم رعاية واحد مرتبط',
      zero: 'لا يوجد مقدمو رعاية مرتبطون',
    );
    return '$_temp0';
  }

  @override
  String get todayGettingReady => 'بنجهّز يومك';

  @override
  String get todayMemoryOff => 'الذاكرة مقفولة';

  @override
  String get todayMemoryUnknown => 'حالة الذاكرة مش متاحة دلوقتي';

  @override
  String get todayMemoryPaused => 'الذاكرة متوقفة مؤقتًا';

  @override
  String get todayMemoryOn => 'الذاكرة شغالة';

  @override
  String get todayGlassesConnected => 'النظارة متوصلة';

  @override
  String get todayGlassesAway => 'النظارة مش متوصلة';

  @override
  String get todayOffline =>
      'تقدر تكمّل باليوم المحفوظ. التحديثات هتوصل لما الاتصال يرجع.';

  @override
  String get todayNextReminder => 'التذكير الجاي';

  @override
  String get todayNoReminder => 'مفيش تذكيرات دلوقتي';

  @override
  String get todayDone => 'خدته';

  @override
  String get todayLater => 'بعدين';

  @override
  String get todayPeopleMet => 'قابلت النهارده';

  @override
  String get todayNoPeople => 'الناس اللي تقابلهم هيظهروا هنا';

  @override
  String get todayAskLater => 'اسأل (المرحلة ٢)';

  @override
  String get patientRemindersTitle => 'تذكيرات النهارده';

  @override
  String get patientRemindersEmpty => 'تذكيراتك هتظهر هنا';

  @override
  String get patientReminderPending => 'لسه';

  @override
  String get patientReminderSnoozed => 'بعدين';

  @override
  String get patientReminderMissed => 'وقتها فات';

  @override
  String patientAlertTitle(String title) {
    return 'ميعاد $title';
  }

  @override
  String get patientAlertUnavailable => 'تذكيراتك موجودة في التذكيرات';

  @override
  String get patientAlertSaveFailed => 'لسه ما اتحفظتش. جرّب تاني.';

  @override
  String get patientAlertBack => 'ارجع للتذكيرات';

  @override
  String get patientDayToday => 'النهارده';

  @override
  String get patientDayYesterday => 'امبارح';

  @override
  String get patientDayOffline =>
      'يومك المحفوظ موجود هنا. التحديثات هتوصل لما الاتصال يرجع.';

  @override
  String get patientDayEmpty => 'لحظات من يومك هتظهر هنا';

  @override
  String get patientDayDetailPending => 'تفاصيل الذكريات هتكون متاحة قريب.';

  @override
  String patientDayMet(String name, String time) {
    return 'قابلت $name الساعة $time';
  }

  @override
  String patientDayEncounter(String time) {
    return 'قابلت حد الساعة $time';
  }

  @override
  String patientDayTalk(String time) {
    return 'محادثة الساعة $time';
  }

  @override
  String patientDayReminder(String time) {
    return 'تذكير الساعة $time';
  }

  @override
  String patientDayRecording(String time) {
    return 'تسجيل الساعة $time';
  }

  @override
  String patientDayMoment(String time) {
    return 'لحظة الساعة $time';
  }

  @override
  String patientDayDocument(String time) {
    return 'مستند الساعة $time';
  }

  @override
  String patientDayQuestion(String time) {
    return 'سألت سؤال الساعة $time';
  }

  @override
  String patientDayGame(String time) {
    return 'لعبة الساعة $time';
  }

  @override
  String patientDayPaused(String time) {
    return 'الذاكرة اتوقفت الساعة $time';
  }

  @override
  String patientDayResumed(String time) {
    return 'الذاكرة رجعت تشتغل الساعة $time';
  }

  @override
  String patientDayEvent(String time) {
    return 'لحظة من يومك الساعة $time';
  }
}

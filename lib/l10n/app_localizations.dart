import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('ar'), Locale('fr')];
  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(Locale('en'));
  }

  String _pick(String en, String ar, String fr) =>
      switch (locale.languageCode) {
        'ar' => ar,
        'fr' => fr,
        _ => en,
      };

  String get chooseTranslationLanguage => _pick(
    'What language should translations use?',
    'ما اللغة التي تريد الترجمة إليها؟',
    'Dans quelle langue traduire ?',
  );
  String get translationLanguageDescription => _pick(
    'Stackit detects the highlighted language automatically. You can override the route for any capture.',
    'يكتشف Stackit لغة النص المحدد تلقائيًا، ويمكنك تغيير مسار الترجمة لأي كلمة.',
    'Stackit détecte automatiquement la langue sélectionnée. Vous pouvez modifier le sens pour chaque capture.',
  );
  String get chooseTranslationRoute => _pick(
    'Choose a translation direction',
    'اختر اتجاه الترجمة',
    'Choisir le sens de traduction',
  );
  String get translationRouteDescription => _pick(
    'Spin both wheels to choose the source and translation languages.',
    'حرّك العجلتين لاختيار لغة المصدر ولغة الترجمة.',
    'Faites tourner les deux roues pour choisir les langues source et cible.',
  );
  String get fromLanguage => _pick('From', 'من', 'Depuis');
  String get toLanguage => _pick('To', 'إلى', 'Vers');
  String get useTranslationRoute =>
      _pick('Use this direction', 'استخدام هذا الاتجاه', 'Utiliser ce sens');
  String get chooseDifferentLanguages => _pick(
    'Choose two different languages.',
    'اختر لغتين مختلفتين.',
    'Choisissez deux langues différentes.',
  );
  String unavailableLanguageRoute(String source, String target) => _pick(
    '$source ↔ $target translation is not available yet. Choose English as either the source or target.',
    'الترجمة بين $source و$target غير متاحة بعد. اختر الإنجليزية كلغة المصدر أو الهدف.',
    "La traduction $source ↔ $target n’est pas encore disponible. Choisissez l’anglais comme langue source ou cible.",
  );
  String get findAllMeanings => _pick(
    'Find all meanings',
    'العثور على جميع المعاني',
    'Trouver tous les sens',
  );
  String get findAllMeaningsDescription => _pick(
    'Expand this entry into distinct meanings, translations, and examples using AI.',
    'وسّع هذه الكلمة إلى معانٍ وترجمات وأمثلة منفصلة باستخدام الذكاء الاصطناعي.',
    "Développez l’entrée en sens, traductions et exemples distincts grâce à l’IA.",
  );
  String get findingAllMeanings => _pick(
    'Finding meanings…',
    'جارٍ البحث عن المعاني…',
    'Recherche des sens…',
  );
  String get meaningDiscoveryFailed => _pick(
    'All meanings could not be loaded. Please try again.',
    'تعذّر تحميل جميع المعاني. حاول مرة أخرى.',
    'Impossible de charger tous les sens. Réessayez.',
  );
  String get retry => _pick('Retry', 'إعادة المحاولة', 'Réessayer');
  String translateInto(String language) => _pick(
    'Translate into $language',
    'الترجمة إلى $language',
    'Traduire en $language',
  );
  String routesFrom(String sources) => _pick(
    'Offline from: $sources',
    'متاح دون اتصال من: $sources',
    'Hors ligne depuis : $sources',
  );
  String get interfaceLanguage =>
      _pick('Interface language', 'لغة واجهة التطبيق', "Langue de l'interface");
  String get systemDefault => _pick(
    'Follow device language',
    'اتّباع لغة الجهاز',
    "Suivre la langue de l'appareil",
  );
  String get accountAndSettings =>
      _pick('Account and settings', 'الحساب والإعدادات', 'Compte et réglages');
  String get learningProfile =>
      _pick('Learning profile', 'ملف التعلّم', "Profil d'apprentissage");
  String get completeYourProfile => _pick(
    'Set your languages, goals, and preferences',
    'حدّد لغاتك وأهدافك وتفضيلاتك',
    'Définissez vos langues, objectifs et préférences',
  );
  String get setUpLearningProfile => _pick(
    'Set up your learning profile',
    'إعداد ملف التعلّم',
    "Configurer votre profil d’apprentissage",
  );
  String get onboardingProfileIntroduction => _pick(
    'Choose your languages and daily goal. You can close this screen and keep capturing words at any time.',
    'اختر لغاتك وهدفك اليومي. يمكنك إغلاق هذه الشاشة ومتابعة حفظ الكلمات في أي وقت.',
    'Choisissez vos langues et votre objectif quotidien. Vous pouvez fermer cet écran et continuer à enregistrer des mots à tout moment.',
  );
  String get completeExistingProfileTitle => _pick(
    'Complete your learning profile?',
    'هل تريد إكمال ملف التعلّم؟',
    'Compléter votre profil d’apprentissage ?',
  );
  String get existingProfileMigrationDescription => _pick(
    'Your existing words and review history stay unchanged. Adding your languages and goals helps Stackit personalize future learning.',
    'ستبقى كلماتك الحالية وسجل المراجعة دون تغيير. تساعد إضافة لغاتك وأهدافك Stackit على تخصيص التعلّم لاحقًا.',
    'Vos mots et votre historique de révision restent inchangés. Vos langues et objectifs aideront Stackit à personnaliser la suite.',
  );
  String get setUpNow => _pick('Set up now', 'الإعداد الآن', 'Configurer');
  String get later => _pick('Later', 'لاحقًا', 'Plus tard');
  String get profileSyncLocal => _pick(
    'Your profile is available locally. Cloud sync will retry.',
    'ملفك متاح على الجهاز، وستُعاد محاولة المزامنة السحابية.',
    'Votre profil reste disponible localement. La synchronisation reprendra.',
  );
  String get identity => _pick('Identity', 'الهوية', 'Identité');
  String get displayName =>
      _pick('Display name', 'الاسم الظاهر', "Nom d'affichage");
  String get verified => _pick('Verified', 'موثّق', 'Vérifié');
  String get notVerified => _pick('Not verified', 'غير موثّق', 'Non vérifié');
  String get freePlan => _pick('Free plan', 'الخطة المجانية', 'Offre gratuite');
  String memberSince(String date) =>
      _pick('Member since $date', 'عضو منذ $date', 'Membre depuis $date');
  String profileUpdated(String date) => _pick(
    'Profile updated $date',
    'تم تحديث الملف في $date',
    'Profil mis à jour le $date',
  );
  String get changeProfilePhoto => _pick(
    'Change profile photo',
    'تغيير صورة الملف الشخصي',
    'Modifier la photo de profil',
  );
  String get chooseProfilePhoto => _pick(
    'Choose a profile photo',
    'اختيار صورة للملف الشخصي',
    'Choisir une photo de profil',
  );
  String get removeProfilePhoto => _pick(
    'Remove profile photo',
    'إزالة صورة الملف الشخصي',
    'Supprimer la photo de profil',
  );
  String get profilePhotoUpdated => _pick(
    'Profile photo updated.',
    'تم تحديث صورة الملف الشخصي.',
    'Photo de profil mise à jour.',
  );
  String get profilePhotoRemoved => _pick(
    'Profile photo removed.',
    'تمت إزالة صورة الملف الشخصي.',
    'Photo de profil supprimée.',
  );
  String get progress => _pick('Progress', 'التقدّم', 'Progression');
  String get collected => _pick('Collected', 'المحفوظة', 'Collectés');
  String get reviewed => _pick('Reviewed', 'تمت مراجعتها', 'Révisés');
  String get mastered => _pick('Mastered', 'متقَنة', 'Maîtrisés');
  String get dueNow => _pick('Due now', 'مستحقة الآن', 'À réviser');
  String get languages => _pick('Languages', 'اللغات', 'Langues');
  String get nativeLanguage =>
      _pick('Native language', 'اللغة الأم', 'Langue maternelle');
  String get notSet => _pick('Not set', 'غير محددة', 'Non définie');
  String get learningLanguages => _pick(
    'Languages you are learning',
    'اللغات التي تتعلّمها',
    'Langues que vous apprenez',
  );
  String get proficiency => _pick('Proficiency', 'مستوى الإتقان', 'Niveau');
  String proficiencyLabel(String value) => switch (value) {
    'beginner' => _pick('Beginner', 'مبتدئ', 'Débutant'),
    'elementary' => _pick('Elementary', 'أساسي', 'Élémentaire'),
    'intermediate' => _pick('Intermediate', 'متوسط', 'Intermédiaire'),
    'upper-intermediate' => _pick(
      'Upper intermediate',
      'فوق المتوسط',
      'Intermédiaire avancé',
    ),
    'advanced' => _pick('Advanced', 'متقدم', 'Avancé'),
    'proficient' => _pick('Proficient', 'متقن', 'Confirmé'),
    _ => value,
  };
  String get goalsAndPersonalization => _pick(
    'Goals and personalization',
    'الأهداف والتخصيص',
    'Objectifs et personnalisation',
  );
  String dailyGoal(int count) => _pick(
    '$count reviews per day',
    '$count مراجعات يوميًا',
    '$count révisions par jour',
  );
  String get reviewIntensity =>
      _pick('Review intensity', 'كثافة المراجعة', 'Intensité des révisions');
  String intensityLabel(String value) => switch (value) {
    'gentle' => _pick('Gentle', 'خفيفة', 'Douce'),
    'intensive' => _pick('Intensive', 'مكثفة', 'Intensive'),
    _ => _pick('Balanced', 'متوازنة', 'Équilibrée'),
  };
  String get interests => _pick('Interests', 'الاهتمامات', 'Centres d’intérêt');
  String get interestsHint => _pick(
    'Travel, technology, literature',
    'السفر، التقنية، الأدب',
    'Voyage, technologie, littérature',
  );
  String get learningPurposes =>
      _pick('Learning purposes', 'أهداف التعلّم', "Objectifs d'apprentissage");
  String get purposesHint => _pick(
    'Work, study, conversation',
    'العمل، الدراسة، المحادثة',
    'Travail, études, conversation',
  );
  String get privacyAndAssistance => _pick(
    'Privacy and assistance',
    'الخصوصية والمساعدة',
    'Confidentialité et assistance',
  );
  String get aiAssistance =>
      _pick('AI assistance', 'المساعدة بالذكاء الاصطناعي', 'Assistance par IA');
  String get aiAssistanceDescription => _pick(
    'Allow contextual explanations only when you explicitly request one.',
    'السماح بالشرح السياقي فقط عندما تطلبه صراحةً.',
    'Autoriser les explications contextuelles uniquement à votre demande.',
  );
  String get productAnalytics => _pick(
    'Private product analytics',
    'تحليلات خاصة للمنتج',
    'Analyse privée du produit',
  );
  String get productAnalyticsDescription => _pick(
    'Help improve Stackit without sending captured words.',
    'ساعد في تحسين Stackit من دون إرسال الكلمات التي تحفظها.',
    'Aidez à améliorer Stackit sans envoyer les mots capturés.',
  );
  String get saveProfile =>
      _pick('Save profile', 'حفظ الملف', 'Enregistrer le profil');
  String get profileSaved =>
      _pick('Profile saved', 'تم حفظ الملف', 'Profil enregistré');
  String get inbox => _pick('Inbox', 'الوارد', 'Boîte');
  String get review => _pick('Review', 'المراجعة', 'Révision');
  String get library => _pick('Library', 'المكتبة', 'Bibliothèque');
  String get wordInbox =>
      _pick('Your word inbox', 'صندوق كلماتك', 'Votre boîte de mots');
  String savedCount(int count) =>
      _pick('$count saved', '$count محفوظة', '$count enregistrés');
  String get searchHint => _pick(
    'Search in any supported language',
    'ابحث بأي لغة مدعومة',
    'Rechercher dans une langue prise en charge',
  );
  String librarySummary(int count) => _pick(
    'All $count saved words — new and reviewed.',
    'كل الكلمات المحفوظة ($count) — الجديدة والمُراجعة.',
    '$count mots enregistrés — nouveaux et révisés.',
  );
  String get emptyLibrary => _pick(
    'Your library is empty.',
    'مكتبتك فارغة.',
    'Votre bibliothèque est vide.',
  );
  String get noMatches =>
      _pick('No matches found.', 'لم يتم العثور على نتائج.', 'Aucun résultat.');
  String detectedRoute(String route) => _pick(
    'Detected text — using $route for this capture.',
    'تم اكتشاف اللغة — سيُستخدم المسار $route لهذه الكلمة.',
    'Langue détectée — sens $route pour cette capture.',
  );
  String get captureRoute =>
      _pick('Translation route', 'مسار الترجمة', 'Sens de traduction');
  String targetEquivalents(String language) => _pick(
    '$language equivalents',
    'المعاني باللغة $language',
    'Équivalents en $language',
  );
  String get pronounce => _pick('Pronounce', 'النطق', 'Prononcer');
  String get saveForReview =>
      _pick('Save for review', 'حفظ للمراجعة', 'Enregistrer pour révision');
  String get alreadySaved =>
      _pick('Already saved', 'محفوظة مسبقًا', 'Déjà enregistré');
  String get continueReading =>
      _pick('Continue reading', 'متابعة القراءة', 'Continuer la lecture');
  String get addWord => _pick(
    'Add a word or phrase',
    'إضافة كلمة أو عبارة',
    'Ajouter un mot ou une expression',
  );
  String get addWordDirectly => _pick(
    'Add a word directly',
    'إضافة كلمة مباشرةً',
    'Ajouter un mot directement',
  );
  String get wordOrPhrase =>
      _pick('Word or phrase', 'كلمة أو عبارة', 'Mot ou expression');
  String get wordOrPhraseHint => _pick(
    'Type or paste what you want to learn',
    'اكتب أو الصق ما تريد تعلّمه',
    'Saisissez ou collez ce que vous voulez apprendre',
  );
  String get add => _pick('Add', 'إضافة', 'Ajouter');
  String get cancel => _pick('Cancel', 'إلغاء', 'Annuler');
  String get wordSaveFailed => _pick(
    'This word could not be saved. Please try again.',
    'تعذّر حفظ هذه الكلمة. حاول مرة أخرى.',
    "Ce mot n'a pas pu être enregistré. Réessayez.",
  );
  String savedForReview(String word) => _pick(
    '“$word” saved for review',
    'تم حفظ «$word» للمراجعة',
    '« $word » enregistré pour révision',
  );
  String get missingOfflineMeaning => _pick(
    'Sorry, this meaning is not in the offline dictionary yet.',
    'عذرًا، هذا المعنى غير موجود في القاموس دون اتصال حتى الآن.',
    "Désolé, ce sens n'est pas encore dans le dictionnaire hors ligne.",
  );
  String get maySaveMissing => _pick(
    'You can still save it and enrich it when you are online.',
    'يمكنك حفظه الآن وإثراؤه عند الاتصال بالإنترنت.',
    "Vous pouvez l'enregistrer et l'enrichir une fois en ligne.",
  );
  String unavailableRoute(String route) => _pick(
    '$route is not available offline. Choose another route for this capture.',
    'المسار $route غير متاح دون اتصال. اختر مسارًا آخر لهذه الكلمة.',
    "$route n'est pas disponible hors ligne. Choisissez un autre sens.",
  );
  String get settings => _pick('Settings', 'الإعدادات', 'Réglages');
  String get translationPreference => _pick(
    'Preferred translation language',
    'لغة الترجمة المفضلة',
    'Langue de traduction préférée',
  );
  String get close => _pick('Close', 'إغلاق', 'Fermer');
  String get createYourAccount =>
      _pick('Create your account', 'أنشئ حسابك', 'Créez votre compte');
  String get welcomeBack =>
      _pick('Welcome back', 'مرحبًا بعودتك', 'Bon retour');
  String get createAccountSubtitle => _pick(
    'Keep your vocabulary available across devices.',
    'احتفظ بكلماتك متاحة على جميع أجهزتك.',
    'Retrouvez votre vocabulaire sur tous vos appareils.',
  );
  String get signInSubtitle => _pick(
    'Sign in to open your vocabulary collection.',
    'سجّل الدخول لفتح مجموعة كلماتك.',
    'Connectez-vous pour ouvrir votre vocabulaire.',
  );
  String get email => _pick('Email', 'البريد الإلكتروني', 'E-mail');
  String get password => _pick('Password', 'كلمة المرور', 'Mot de passe');
  String get createAccount =>
      _pick('Create account', 'إنشاء حساب', 'Créer un compte');
  String get signIn => _pick('Sign in', 'تسجيل الدخول', 'Se connecter');
  String get forgotPassword =>
      _pick('Forgot password?', 'نسيت كلمة المرور؟', 'Mot de passe oublié ?');
  String get or => _pick('or', 'أو', 'ou');
  String get continueWithGoogle => _pick(
    'Continue with Google',
    'المتابعة باستخدام Google',
    'Continuer avec Google',
  );
  String get existingAccount => _pick(
    'Already have an account? Sign in',
    'لديك حساب؟ سجّل الدخول',
    'Déjà un compte ? Connectez-vous',
  );
  String get newAccount => _pick(
    'New to Stackit? Create an account',
    'جديد في Stackit؟ أنشئ حسابًا',
    'Nouveau sur Stackit ? Créez un compte',
  );
  String get invalidEmail => _pick(
    'Enter a valid email address.',
    'أدخل بريدًا إلكترونيًا صالحًا.',
    'Saisissez une adresse e-mail valide.',
  );
  String get shortPassword => _pick(
    'Use at least 6 characters.',
    'استخدم 6 أحرف على الأقل.',
    'Utilisez au moins 6 caractères.',
  );
  String get resetSent => _pick(
    'Password reset email sent.',
    'تم إرسال رسالة إعادة تعيين كلمة المرور.',
    'E-mail de réinitialisation envoyé.',
  );
  String get allClear =>
      _pick('ALL CLEAR', 'لا توجد مراجعات', 'TOUT EST À JOUR');
  String get nothingDue => _pick(
    'Nothing due right now',
    'لا توجد كلمات للمراجعة الآن',
    'Aucune révision pour le moment',
  );
  String get collectWords => _pick(
    'Collect a few words, then return for a short review session.',
    'اجمع بعض الكلمات ثم عُد لجلسة مراجعة قصيرة.',
    'Ajoutez quelques mots, puis revenez pour une courte révision.',
  );
  String get sessionComplete =>
      _pick('SESSION COMPLETE', 'اكتملت الجلسة', 'SESSION TERMINÉE');
  String wordsRevisited(int count) => _pick(
    '$count words revisited',
    'تمت مراجعة $count كلمات',
    '$count mots révisés',
  );
  String get enoughToday => _pick(
    'That is enough for today. We will bring them back when your memory needs them.',
    'هذا يكفي اليوم. سنعيد الكلمات عندما تحتاج ذاكرتك إلى مراجعتها.',
    "C'est suffisant pour aujourd'hui. Les mots reviendront au bon moment.",
  );
  String get revealMeaning =>
      _pick('Reveal meaning', 'إظهار المعنى', 'Afficher le sens');
  String get recallMeaning =>
      _pick('RECALL THE MEANING', 'تذكّر المعنى', 'RAPPELEZ-VOUS LE SENS');
  String get completeThought =>
      _pick('COMPLETE THE THOUGHT', 'أكمل العبارة', 'COMPLÉTEZ LA PHRASE');
  String explainIn(String language) => _pick(
    'Can you explain it in $language?',
    'هل يمكنك شرحه باللغة $language؟',
    "Pouvez-vous l'expliquer en $language ?",
  );
  String get wordInBlank => _pick(
    'Which saved word belongs in the blank?',
    'ما الكلمة المحفوظة التي تناسب الفراغ؟',
    'Quel mot enregistré complète la phrase ?',
  );
  String get recallFirst => _pick(
    'Try to recall before revealing',
    'حاول التذكّر قبل إظهار الإجابة',
    "Essayez de vous souvenir avant d'afficher",
  );
  String get forgot => _pick('Forgot', 'نسيت', 'Oublié');
  String get almost => _pick('Almost', 'تقريبًا', 'Presque');
  String get remembered => _pick('Remembered', 'تذكّرت', 'Retenu');
  String get newWordsStay => _pick(
    'New words stay here until their first review.',
    'تبقى الكلمات الجديدة هنا حتى أول مراجعة.',
    "Les nouveaux mots restent ici jusqu'à leur première révision.",
  );
  String get syncing => _pick(
    'Syncing securely…',
    'جارٍ المزامنة بأمان…',
    'Synchronisation sécurisée…',
  );
  String newCount(int count) =>
      _pick('$count new', '$count جديدة', '$count nouveaux');
  String startReviewing(int count) => _pick(
    'Start reviewing $count new ${count == 1 ? 'word' : 'words'}',
    'ابدأ مراجعة $count ${count == 1 ? 'كلمة جديدة' : 'كلمات جديدة'}',
    'Réviser $count ${count == 1 ? 'nouveau mot' : 'nouveaux mots'}',
  );
  String get meetAWord => _pick(
    'Meet a word worth keeping?',
    'وجدت كلمة تستحق الحفظ؟',
    'Un mot mérite d’être retenu ?',
  );
  String get inboxClear =>
      _pick('Inbox clear', 'صندوق الوارد فارغ', 'Boîte vide');
  String get captureInstructions => _pick(
    'Highlight text in another app, then choose “Stackit”. If it is not listed, tap Share and choose Stackit instead.',
    'حدّد نصًا في تطبيق آخر ثم اختر «Stackit». إذا لم يظهر، اضغط مشاركة واختر Stackit.',
    'Sélectionnez du texte dans une autre application, puis choisissez « Stackit ». Sinon, utilisez Partager.',
  );
  String clearInboxSummary(int count) => _pick(
    'No new words are waiting. Your $count saved ${count == 1 ? 'word is' : 'words are'} still searchable in Library.',
    'لا توجد كلمات جديدة. ما زال بإمكانك البحث في كلماتك المحفوظة ($count) داخل المكتبة.',
    'Aucun nouveau mot. Vos $count mots enregistrés restent disponibles dans la bibliothèque.',
  );
  String moreMeanings(int count) => _pick(
    '+$count more ${count == 1 ? 'meaning' : 'meanings'} — tap to expand',
    '+$count ${count == 1 ? 'معنى إضافي' : 'معانٍ إضافية'} — اضغط للتوسيع',
    '+$count ${count == 1 ? 'sens' : 'sens'} — toucher pour développer',
  );
  String meaningLabel(int index, int total) => _pick(
    total == 1 ? 'Meaning' : 'Meaning $index of $total',
    total == 1 ? 'المعنى' : 'المعنى $index من $total',
    total == 1 ? 'Sens' : 'Sens $index sur $total',
  );
  String equivalentsLabel(int count) => _pick(
    count == 1 ? 'Equivalent' : 'Equivalent translations',
    count == 1 ? 'المقابل' : 'ترجمات مكافئة',
    count == 1 ? 'Équivalent' : 'Traductions équivalentes',
  );
  String get examples => _pick('Examples', 'أمثلة', 'Exemples');
  String get tapForDetails => _pick(
    'Tap for word details',
    'اضغط لعرض تفاصيل الكلمة',
    'Touchez pour afficher les détails',
  );
  String get moreVerified => _pick(
    'More verified equivalents',
    'معانٍ إضافية موثوقة',
    'Autres équivalents vérifiés',
  );
  String get fullDetails =>
      _pick('Full details', 'كل التفاصيل', 'Tous les détails');
  String get exampleTranslation =>
      _pick('Example translation', 'ترجمة المثال', "Traduction de l'exemple");
  String get explainInContext => _pick(
    'Explain in context',
    'شرحها ضمن السياق',
    'Expliquer dans le contexte',
  );
  String get sentenceOptional => _pick(
    'Sentence or context (optional)',
    'الجملة أو السياق (اختياري)',
    'Phrase ou contexte (facultatif)',
  );
  String get sentenceHint => _pick(
    'Paste the sentence where you found this word.',
    'الصق الجملة التي وجدت فيها هذه الكلمة.',
    'Collez la phrase dans laquelle vous avez trouvé ce mot.',
  );
  String get explain => _pick('Explain', 'اشرح', 'Expliquer');
  String get dailyReminder => _pick(
    'Daily review reminder',
    'تذكير يومي بالمراجعة',
    'Rappel de révision quotidien',
  );
  String get reminderTime => _pick(
    'At 7:00 PM in your device time zone',
    'الساعة 7:00 مساءً حسب توقيت جهازك',
    'À 19 h selon le fuseau de votre appareil',
  );
  String get exportVocabulary =>
      _pick('Export vocabulary', 'تصدير الكلمات', 'Exporter le vocabulaire');
  String jsonEntries(int count) => _pick(
    '$count entries as JSON',
    '$count عنصر بصيغة JSON',
    '$count entrées en JSON',
  );
  String get privacyPolicy =>
      _pick('Privacy policy', 'سياسة الخصوصية', 'Politique de confidentialité');
  String get signOut => _pick('Sign out', 'تسجيل الخروج', 'Se déconnecter');
  String get deleteAccount => _pick(
    'Delete account and cloud data',
    'حذف الحساب والبيانات السحابية',
    'Supprimer le compte et les données cloud',
  );
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (item) => item.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension LocalizedContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

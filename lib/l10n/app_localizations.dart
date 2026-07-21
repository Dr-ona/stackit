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
  String get lookupFailed => _pick(
    'Dictionary lookup failed. Please try again.',
    'تعذّر البحث في القاموس. حاول مرة أخرى.',
    'La recherche dans le dictionnaire a échoué. Réessayez.',
  );
  String get aiLookupInProgress => _pick(
    'AI lookup in progress…',
    'جارٍ البحث بالذكاء الاصطناعي…',
    'Recherche IA en cours…',
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
  String streakDays(int count) => _pick(
    '$count ${count == 1 ? 'day' : 'days'} streak',
    '$count ${count == 1 ? 'يوم' : 'أيام'} متتالية',
    '$count ${count == 1 ? 'jour' : 'jours'} consécutif${count == 1 ? '' : 's'}',
  );
  String get noStreak =>
      _pick('No streak yet', 'لم تبدأ سلسلة بعد', 'Pas encore de série');
  String retentionPercent(int percent) => _pick(
    '$percent% retention',
    '$percent% معدل الاحتفاظ',
    '$percent% de rétention',
  );
  String get retention => _pick('Retention', 'معدل الاحتفاظ', 'Rétention');
  String partOfSpeechLabel(String value) {
    final capitalized = value.isEmpty
        ? value
        : '${value[0].toUpperCase()}${value.substring(1)}';
    return _pick(capitalized, capitalized, capitalized);
  }

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
  String get alreadyInLibrary => _pick(
    'This word is already in your library.',
    'هذه الكلمة موجودة بالفعل في مكتبتك.',
    'Ce mot est déjà dans votre bibliothèque.',
  );
  String get viewExisting =>
      _pick('View existing', 'عرض المحفوظة', 'Voir l\'existant');
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
  String get pasteFromClipboard => _pick(
    'Paste from clipboard',
    'لصق من الحافظة',
    'Coller depuis le presse-papiers',
  );
  String get clipboardEmpty => _pick(
    'Clipboard is empty',
    'الحافظة فارغة',
    'Le presse-papiers est vide',
  );
  String get accent => _pick('Accent', ' اللهجة', 'Accent');
  String get defaultAccent => _pick('Default', 'الافتراضي', 'Par defaut');
  String get addToCollection =>
      _pick('Add to Collection', 'إضافة إلى مجموعة', 'Ajouter a la collection');
  String get noCollectionsYet => _pick(
    'No collections yet. Create one below.',
    'لا توجد مجموعات بعد. أنشئ واحدة أدناه.',
    'Pas encore de collections. Creez-en une ci-dessous.',
  );
  String get newCollectionHint => _pick(
    'New collection name...',
    'اسم المجموعة الجديدة...',
    'Nom de la nouvelle collection...',
  );
  String get done => _pick('Done', 'تم', 'Termine');
  String get howToCapture => _pick(
    'How to capture words',
    'كيف تلتقط الكلمات',
    'Comment capturer des mots',
  );
  String get captureStep1 => _pick(
    'Highlight any word in any app',
    'حدد أي كلمة في أي تطبيق',
    'Selectionnez n\'importe quel mot dans une application',
  );
  String get captureStep2 => _pick(
    'Tap "Understand with Stackit" in the menu',
    'اضغط "افهم مع Stackit" في القائمة',
    'Appuyez sur "Comprendre avec Stackit" dans le menu',
  );
  String get captureStep3 => _pick(
    'Save the meaning to your vocabulary',
    'احفظ المعنى في قاموسك',
    'Enregistrez le sens dans votre vocabulaire',
  );
  String get captureMissingHint => _pick(
    'Don\'t see "Understand with Stackit"? Open your phone\'s text selection settings and enable it.',
    'لا ترى "افهم مع Stackit"؟ افتح إعدادات تحديد النص في هاتفك وقم بتفعيله.',
    'Vous ne voyez pas "Comprendre avec Stackit" ? Ouvrez les parametres de selection de texte de votre telephone et activez-le.',
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
  String get selectAll =>
      _pick('Select all', 'تحديد الكل', 'Tout sélectionner');
  String get deselectAll =>
      _pick('Deselect all', 'إلغاء التحيد', 'Tout désélectionner');
  String selectedCount(int count) => _pick(
    '$count selected',
    '$count محدد',
    '$count sélectionné${count == 1 ? '' : 's'}',
  );
  String get deleteSelected =>
      _pick('Delete selected', 'حذف المحدد', 'Supprimer la sélection');
  String get confirmDeleteSelected => _pick(
    'Delete selected entries?',
    'حذف المدخلات المحددة؟',
    'Supprimer les entrées sélectionnées ?',
  );
  String get deleteCollectionOnly => _pick(
    'Remove collection from entries?',
    'إزالة المجموعة من المدخلات؟',
    'Retirer la collection des entrées ?',
  );
  String get deleteCollectionOnlyHint => _pick(
    'Entries will stay in your vocabulary. Only the collection tag is removed.',
    'ستبقى المدخلات في معجمك. يتم فقط إزالة وسم المجموعة.',
    'Les entrées restent dans votre vocabulaire. Seul le tag de collection est supprimé.',
  );
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
  String lastSyncedAt(DateTime date) => _pick(
    'Last synced: ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
    'آخر مزامنة: ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
    'Dernière sync : ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
  );
  String get notSyncedYet =>
      _pick('Not synced yet', 'لم تُزامَن بعد', 'Pas encore synchronisé');
  String get syncNow => _pick('Sync now', 'مزامنة الآن', 'Synchroniser');
  String syncedCount(int count) => _pick(
    'Synced $count ${count == 1 ? 'entry' : 'entries'}',
    'تمت مزامنة $count ${count == 1 ? 'مدخل' : 'مدخلات'}',
    '$count ${count == 1 ? 'entrée synchronisée' : 'entrées synchronisées'}',
  );
  String entryDeleted(String text) =>
      _pick('"$text" deleted', 'تم حذف "$text"', '"$text" supprimé');
  String get undo => _pick('Undo', 'تراجع', 'Annuler');
  String get signOut => _pick('Sign out', 'تسجيل الخروج', 'Se déconnecter');
  String get deleteAccount => _pick(
    'Delete account and cloud data',
    'حذف الحساب والبيانات السحابية',
    'Supprimer le compte et les données cloud',
  );
  String get deleteAccountTitle => _pick(
    'Delete your Stackit account?',
    'حذف حساب Stackit؟',
    'Supprimer votre compte Stackit ?',
  );
  String get deleteAccountDescription => _pick(
    'This permanently deletes your cloud vocabulary and Firebase account. Export first if you want a copy.',
    'يحذف ذلك بشكل دائم كلماتك السحابية وحساب Firebase. صدّر نسخة أولاً إذا أردت الاحتفاظ بنسخة.',
    'Cela supprime définitivement votre vocabulaire cloud et votre compte Firebase. Exportez d\'abord si vous souhaitez une copie.',
  );
  String get currentPassword =>
      _pick('Current password', 'كلمة المرور الحالية', 'Mot de passe actuel');
  String get deletePermanently =>
      _pick('Delete permanently', 'حذف نهائي', 'Supprimer définitivement');
  String get dailyReviewHeader =>
      _pick('DAILY REVIEW', 'المراجعة اليومية', 'RÉVISION QUOTIDIENNE');
  String reviewProgress(int position, int total) => _pick(
    '$position of $total',
    '$position من $total',
    '$position sur $total',
  );
  String reviewRemaining(int count) => _pick(
    '$count left',
    '$count متبقية',
    '$count restant${count == 1 ? '' : 's'}',
  );
  String get notificationPermissionNotGranted => _pick(
    'Notification permission was not granted.',
    'لم تُمنح صلاحية الإشعارات.',
    'La permission de notification n\'a pas été accordée.',
  );
  String get stackitPrivacy =>
      _pick('Stackit privacy', 'خصوصية Stackit', 'Confidentialité Stackit');
  String get privacyDescription => _pick(
    'Stackit stores vocabulary on your device and, when signed in, in your private Firebase account. Gemini receives a selected term and only the context you choose to submit. We do not sell personal data. You can export your vocabulary or delete your account and cloud data from this screen. Contact: khalidona.bk@gmail.com',
    'يخزن Stackit المفردات على جهازك وعند تسجيل الدخول في حسابك الخاص بـ Firebase. يتلقى Gemini المصطلح المحدد والسياق فقط الذي تختار إرساله. لا نبيع البيانات الشخصية. يمكنك تصدير كلماتك أو حذف حسابك والبيانات السحابية من هذا الشاشة. التواصل: khalidona.bk@gmail.com',
    'Stackit stocke le vocabulaire sur votre appareil et, lorsque vous êtes connecté, dans votre compte Firebase privé. Gemini reçoit un terme sélectionné et uniquement le contexte que vous choisissez de soumettre. Nous ne vendons pas de données personnelles. Vous pouvez exporter votre vocabulaire ou supprimer votre compte et vos données cloud depuis cet écran. Contact : khalidona.bk@gmail.com',
  );
  String get accountDeletionFailed => _pick(
    'Account deletion failed. Please try again.',
    'فشل حذف الحساب. حاول مرة أخرى.',
    'La suppression du compte a échoué. Réessayez.',
  );
  String get signInRequired => _pick(
    'You are not signed in.',
    'أنت غير مسجل الدخول.',
    'Vous n\'êtes pas connecté.',
  );
  String get termsOfService =>
      _pick('Terms of Service', 'شروط الخدمة', 'Conditions d\'utilisation');

  // Entry detail sheet
  String get verifiedMeaning =>
      _pick('1 verified meaning', 'معنى واحد موثّق', '1 sens vérifié');
  String verifiedMeanings(int count) => _pick(
    '$count verified meanings',
    '$count معانٍ موثّقة',
    '$count sens vérifiés',
  );
  String get explainWithGemini => _pick(
    'Explain this meaning with Gemini',
    'اشرح هذا المعنى بالذكاء الاصطناعي',
    'Expliquer ce sens avec Gemini',
  );
  String get capturedFrom =>
      _pick('Captured from', 'مأخوذ من', 'Capturé depuis');
  String get latestContextualExplanation => _pick(
    'Latest contextual explanation',
    'آخر شرح سياقي',
    'Dernière explication contextuelle',
  );
  String get newExample => _pick('New example', 'مثال جديد', 'Nouvel exemple');
  String get relatedPhrases =>
      _pick('Related phrases', 'عبارات ذات صلة', 'Expressions associées');

  // Sign-in page errors
  String get enterEmailFirst => _pick(
    'Enter your email first.',
    'أدخل بريدك الإلكتروني أولاً.',
    'Entrez d\'abord votre email.',
  );
  String get googleSignInFailed => _pick(
    'Google Sign-In failed. Please try again.',
    'فشل تسجيل الدخول بـ Google. حاول مرة أخرى.',
    'La connexion Google a échoué. Réessayez.',
  );
  String get somethingWentWrong => _pick(
    'Something went wrong. Please try again.',
    'حدث خطأ ما. حاول مرة أخرى.',
    'Une erreur s\'est produite. Réessayez.',
  );
  String get invalidCredential => _pick(
    'The email or password is incorrect.',
    'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
    'L\'email ou le mot de passe est incorrect.',
  );
  String get emailAlreadyInUse => _pick(
    'An account already uses this email.',
    'يوجد حساب بهذا البريد الإلكتروني بالفعل.',
    'Un compte utilise déjà cet email.',
  );
  String get weakPassword => _pick(
    'Choose a stronger password.',
    'اختر كلمة مرور أقوى.',
    'Choisissez un mot de passe plus fort.',
  );
  String get networkRequestFailed => _pick(
    'Check your connection and try again.',
    'تحقق من اتصالك وحاول مرة أخرى.',
    'Vérifiez votre connexion et réessayez.',
  );
  String get tooManyRequests => _pick(
    'Too many attempts. Please wait and try again.',
    'محاولات كثيرة جداً. انتظر وحاول مرة أخرى.',
    'Trop de tentatives. Attendez et réessayez.',
  );
  String get authFailed => _pick(
    'Authentication failed. Please try again.',
    'فشل المصادقة. حاول مرة أخرى.',
    'L\'authentification a échoué. Réessayez.',
  );

  // Controller error messages (accessible without BuildContext)
  static String offlineMessage(Locale locale) => _pickStatic(
    locale,
    'Offline. Saved locally; sync will retry.',
    'غير متصل. حُفظ محليًا؛ ستتم المحاولة لاحقًا.',
    'Hors ligne. Enregistré localement ; la synchronisation réessayera.',
  );
  static String permissionDeniedCloudMessage(Locale locale) => _pickStatic(
    locale,
    'Cloud access was denied. Saved locally; check sign-in or App Check, then retry.',
    'تم رفض الوصول السحابي. حُفظ محليًا. تحقق من تسجيل الدخول أو App Check ثم أعد المحاولة.',
    'Accès cloud refusé. Enregistré localement ; vérifiez la connexion ou App Check, puis réessayez.',
  );
  static String cloudSyncPausedMessage(Locale locale) => _pickStatic(
    locale,
    'Cloud sync paused. Your local words are safe.',
    'تم إيقاف المزامنة السحابية مؤقتًا. كلماتك المحلية آمنة.',
    'Synchronisation cloud en pause. Vos mots locaux sont en sécurité.',
  );
  static String profileOfflineMessage(Locale locale) => _pickStatic(
    locale,
    'Profile is available locally and will sync when online.',
    'الملف الشخصي متاح محليًا وسيتم مزامنته عند الاتصال.',
    'Le profil est disponible localement et se synchronisera en ligne.',
  );
  static String profilePermissionDeniedMessage(Locale locale) => _pickStatic(
    locale,
    'Profile cloud access needs attention. Local settings are safe.',
    'يحتاج الوصول السحابي للملف الشخصي إلى مراجعة. الإعدادات المحلية آمنة.',
    'L\'accès cloud au profil nécessite une attention. Les paramètres locaux sont en sécurité.',
  );
  static String profileSyncPausedMessage(Locale locale) => _pickStatic(
    locale,
    'Profile sync paused. Local settings are safe.',
    'تم إيقاف مزامنة الملف الشخصي. الإعدادات المحلية آمنة.',
    'Synchronisation du profil en pause. Les paramètres locaux sont en sécurité.',
  );
  static String translationPending(Locale locale) => _pickStatic(
    locale,
    'Translation pending',
    'بانتظار المعنى',
    'Traduction en attente',
  );
  static String meaningNotAvailable(Locale locale) => _pickStatic(
    locale,
    'Meaning not available offline yet.',
    'المعنى غير متاح بدون اتصال.',
    'Sens non disponible hors ligne.',
  );
  static String sameLanguageStudy(Locale locale) => _pickStatic(
    locale,
    'Saved for same-language study. Use Find all meanings for definitions and examples.',
    'حُفظ لدراسة نفس اللغة. استخدم "إيجاد جميع المعاني" للتعريفات والأمثلة.',
    'Enregistré pour l\'étude dans la même langue. Utilisez Trouver tous les sens pour les définitions et exemples.',
  );
  static String signInFirst(Locale locale) => _pickStatic(
    locale,
    'Sign in before adding a profile photo.',
    'سجّل الدخول قبل إضافة صورة الملف الشخصي.',
    'Connectez-vous avant d\'ajouter une photo de profil.',
  );
  static String noOfflineRoutes(Locale locale, String languageName) =>
      _pickStatic(
        locale,
        'No offline routes translate into $languageName.',
        'لا توجد ترجمات متاحة بدون اتصال إلى $languageName.',
        'Aucune route hors ligne ne traduit en $languageName.',
      );
  static String meaningDiscoveryNotConfigured(Locale locale) => _pickStatic(
    locale,
    'Meaning discovery is not configured.',
    'اكتشاف المعاني غير مهيأ.',
    'La découverte des sens n\'est pas configurée.',
  );
  static String contextExplanationUnavailable(Locale locale) => _pickStatic(
    locale,
    'Context explanations are not available on this device.',
    'الشروحات السياقية غير متاحة على هذا الجهاز.',
    'Les explications contextuelles ne sont pas disponibles sur cet appareil.',
  );

  static String _pickStatic(Locale locale, String en, String ar, String fr) =>
      switch (locale.languageCode) {
        'ar' => ar,
        'fr' => fr,
        _ => en,
      };

  // Empty library
  String get emptyLibraryTitle => _pick(
    'Your library is empty',
    'مكتبتك فارغة',
    'Votre bibliothèque est vide',
  );
  String get emptyLibraryHint => _pick(
    'Words you save will appear here. Use the Inbox tab to capture new words.',
    'ستظهر الكلمات التي تحفظها هنا. استخدم علامة الصنداد لالتقاط كلمات جديدة.',
    'Les mots que vous enregistrez apparaîtront ici. Utilisez l\'onglet Boîte pour capturer de nouveaux mots.',
  );
  String dailyGoalProgress(int reviewed, int goal) => _pick(
    '$reviewed of $goal daily goal',
    '$reviewed من $goal هدف يومي',
    '$reviewed sur $goal objectif quotidien',
  );
  String get goalReached => _pick(
    'Daily goal reached!',
    'تم تحقيق الهدف اليومي!',
    'Objectif quotidien atteint !',
  );
  String get exerciseSession =>
      _pick('EXERCISE SESSION', 'جلسة تمارين', 'SESSION D\'EXERCICES');
  String exerciseProgress(int position, int total) => _pick(
    'Exercise $position of $total',
    'تمرين $position من $total',
    'Exercice $position sur $total',
  );
  String get fillInBlank =>
      _pick('FILL IN THE BLANK', 'أكمل الفراغ', 'COMPLÉTEZ LA PHRASE');
  String get chooseCorrectTranslation => _pick(
    'CHOOSE THE CORRECT TRANSLATION',
    'اختر الترجمة الصحيحة',
    'CHOISISSEZ LA TRADUCTION CORRECTE',
  );
  String get translateToSource => _pick(
    'TRANSLATE TO SOURCE LANGUAGE',
    'ترجم إلى اللغة المصدر',
    'TRADUIRE VERS LA LANGUE SOURCE',
  );
  String get whatWordMatches => _pick(
    'WHAT WORD MATCHES THIS DEFINITION?',
    'أي كلمة تطابق هذا التعريف?',
    'QUEL MOT CORRESPOND À CETTE DÉFINITION ?',
  );
  String get typeYourAnswer =>
      _pick('Type your answer...', 'اكتب إجابتك...', 'Tapez votre réponse...');
  String get check => _pick('Check', 'تحقق', 'Vérifier');
  String get next => _pick('Next', 'التالي', 'Suivant');
  String get correctAnswer => _pick('Correct!', 'صحيح!', 'Correct !');
  String get incorrectAnswer =>
      _pick('Not quite right', 'ليس صحيحاً', 'Pas tout à fait');
  String translationIs(String translation) => _pick(
    'Translation: $translation',
    'الترجمة: $translation',
    'Traduction : $translation',
  );
  String get noExercisesAvailable => _pick(
    'No exercises available',
    'لا توجد تمارين متاحة',
    'Aucun exercice disponible',
  );
  String get collectWordsFirst => _pick(
    'Collect some words first, then come back for exercises.',
    'اجمع بعض الكلمات أولاً ثم عُد للتمارين.',
    'Collectez d\'abord des mots, puis revenez pour les exercices.',
  );
  String get exerciseSessionComplete =>
      _pick('Session Complete!', 'اكتملت الجلسة!', 'Session terminée !');
  String exerciseScore(int correct, int total) => _pick(
    '$correct out of $total correct',
    '$correct من $total صحيح',
    '$correct sur $total correct',
  );
  String get syncContextInfo => _pick(
    'Sync source app and context to cloud',
    'مزامنة تطبيق المصدر والسياق إلى السحاب',
    'Synchroniser l\'application source et le contexte dans le cloud',
  );
  String get syncContextDescription => _pick(
    'Allow syncing which app this word was captured from, its URL, and surrounding sentence. These are kept private and never shared.',
    'السماح بمزامنة التطبيق الذي تم التقاط الكلمة منه ورابطه والجملة المحيطة. هذه تبقى خاصة ولا تُشارك أبداً.',
    'Autoriser la synchronisation de l\'application d\'origine, l\'URL et la phrase contextuelle. Ces données restent privées et ne sont jamais partagées.',
  );
  String get contextSyncedLocally => _pick(
    'Saved locally only',
    'محفوظ محلياً فقط',
    'Enregistré localement uniquement',
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

enum VocabularyLanguage {
  english(
    code: 'en',
    label: 'English',
    nativeLabel: 'English',
    localeTag: 'en-US',
    isRtl: false,
    writingSystem: WritingSystem.latin,
  ),
  arabic(
    code: 'ar',
    label: 'Arabic',
    nativeLabel: 'العربية',
    localeTag: 'ar-SA',
    isRtl: true,
    writingSystem: WritingSystem.arabic,
  ),
  french(
    code: 'fr',
    label: 'French',
    nativeLabel: 'Français',
    localeTag: 'fr-FR',
    isRtl: false,
    writingSystem: WritingSystem.latin,
  ),
  hindi(
    code: 'hi',
    label: 'Hindi',
    nativeLabel: 'हिन्दी',
    localeTag: 'hi-IN',
    isRtl: false,
    writingSystem: WritingSystem.devanagari,
  ),
  urdu(
    code: 'ur',
    label: 'Urdu',
    nativeLabel: 'اردو',
    localeTag: 'ur-PK',
    isRtl: true,
    writingSystem: WritingSystem.persian,
  ),
  farsi(
    code: 'fa',
    label: 'Farsi',
    nativeLabel: 'فارسی',
    localeTag: 'fa-IR',
    isRtl: true,
    writingSystem: WritingSystem.persian,
  );

  const VocabularyLanguage({
    required this.code,
    required this.label,
    required this.nativeLabel,
    required this.localeTag,
    required this.isRtl,
    required this.writingSystem,
  });

  final String code;
  final String label;
  final String nativeLabel;
  final String localeTag;
  final bool isRtl;
  final WritingSystem writingSystem;

  static VocabularyLanguage? tryFromCode(String? code) {
    for (final language in values) {
      if (language.code == code) return language;
    }
    return null;
  }

  static VocabularyLanguage fromCode(String? code) {
    return tryFromCode(code) ?? VocabularyLanguage.english;
  }
}

enum WritingSystem { latin, arabic, devanagari, persian }

class LanguagePair {
  const LanguagePair({required this.source, required this.target});

  final VocabularyLanguage source;
  final VocabularyLanguage target;

  String get id => '${source.code}_${target.code}';
  String get label => '${source.label} → ${target.label}';

  LanguagePair get reversed => LanguagePair(source: target, target: source);

  static const englishToArabic = LanguagePair(
    source: VocabularyLanguage.english,
    target: VocabularyLanguage.arabic,
  );
  static const englishToEnglish = LanguagePair(
    source: VocabularyLanguage.english,
    target: VocabularyLanguage.english,
  );
  static const arabicToArabic = LanguagePair(
    source: VocabularyLanguage.arabic,
    target: VocabularyLanguage.arabic,
  );
  static const frenchToFrench = LanguagePair(
    source: VocabularyLanguage.french,
    target: VocabularyLanguage.french,
  );
  static const arabicToEnglish = LanguagePair(
    source: VocabularyLanguage.arabic,
    target: VocabularyLanguage.english,
  );
  static const englishToFrench = LanguagePair(
    source: VocabularyLanguage.english,
    target: VocabularyLanguage.french,
  );
  static const frenchToEnglish = LanguagePair(
    source: VocabularyLanguage.french,
    target: VocabularyLanguage.english,
  );
  static const arabicToFrench = LanguagePair(
    source: VocabularyLanguage.arabic,
    target: VocabularyLanguage.french,
  );
  static const frenchToArabic = LanguagePair(
    source: VocabularyLanguage.french,
    target: VocabularyLanguage.arabic,
  );
  static const englishToHindi = LanguagePair(
    source: VocabularyLanguage.english,
    target: VocabularyLanguage.hindi,
  );
  static const hindiToEnglish = LanguagePair(
    source: VocabularyLanguage.hindi,
    target: VocabularyLanguage.english,
  );
  static const hindiToHindi = LanguagePair(
    source: VocabularyLanguage.hindi,
    target: VocabularyLanguage.hindi,
  );
  static const englishToUrdu = LanguagePair(
    source: VocabularyLanguage.english,
    target: VocabularyLanguage.urdu,
  );
  static const urduToEnglish = LanguagePair(
    source: VocabularyLanguage.urdu,
    target: VocabularyLanguage.english,
  );
  static const urduToUrdu = LanguagePair(
    source: VocabularyLanguage.urdu,
    target: VocabularyLanguage.urdu,
  );
  static const englishToFarsi = LanguagePair(
    source: VocabularyLanguage.english,
    target: VocabularyLanguage.farsi,
  );
  static const farsiToEnglish = LanguagePair(
    source: VocabularyLanguage.farsi,
    target: VocabularyLanguage.english,
  );
  static const farsiToFarsi = LanguagePair(
    source: VocabularyLanguage.farsi,
    target: VocabularyLanguage.farsi,
  );
  static const arabicToHindi = LanguagePair(
    source: VocabularyLanguage.arabic,
    target: VocabularyLanguage.hindi,
  );
  static const hindiToArabic = LanguagePair(
    source: VocabularyLanguage.hindi,
    target: VocabularyLanguage.arabic,
  );
  static const frenchToHindi = LanguagePair(
    source: VocabularyLanguage.french,
    target: VocabularyLanguage.hindi,
  );
  static const hindiToFrench = LanguagePair(
    source: VocabularyLanguage.hindi,
    target: VocabularyLanguage.french,
  );
  static const arabicToUrdu = LanguagePair(
    source: VocabularyLanguage.arabic,
    target: VocabularyLanguage.urdu,
  );
  static const urduToArabic = LanguagePair(
    source: VocabularyLanguage.urdu,
    target: VocabularyLanguage.arabic,
  );
  static const frenchToUrdu = LanguagePair(
    source: VocabularyLanguage.french,
    target: VocabularyLanguage.urdu,
  );
  static const urduToFrench = LanguagePair(
    source: VocabularyLanguage.urdu,
    target: VocabularyLanguage.french,
  );
  static const arabicToFarsi = LanguagePair(
    source: VocabularyLanguage.arabic,
    target: VocabularyLanguage.farsi,
  );
  static const farsiToArabic = LanguagePair(
    source: VocabularyLanguage.farsi,
    target: VocabularyLanguage.arabic,
  );
  static const frenchToFarsi = LanguagePair(
    source: VocabularyLanguage.french,
    target: VocabularyLanguage.farsi,
  );
  static const farsiToFrench = LanguagePair(
    source: VocabularyLanguage.farsi,
    target: VocabularyLanguage.french,
  );
  static const hindiToUrdu = LanguagePair(
    source: VocabularyLanguage.hindi,
    target: VocabularyLanguage.urdu,
  );
  static const urduToHindi = LanguagePair(
    source: VocabularyLanguage.urdu,
    target: VocabularyLanguage.hindi,
  );
  static const hindiToFarsi = LanguagePair(
    source: VocabularyLanguage.hindi,
    target: VocabularyLanguage.farsi,
  );
  static const farsiToHindi = LanguagePair(
    source: VocabularyLanguage.farsi,
    target: VocabularyLanguage.hindi,
  );
  static const urduToFarsi = LanguagePair(
    source: VocabularyLanguage.urdu,
    target: VocabularyLanguage.farsi,
  );
  static const farsiToUrdu = LanguagePair(
    source: VocabularyLanguage.farsi,
    target: VocabularyLanguage.urdu,
  );

  // Product routes and offline dictionary coverage are intentionally separate:
  // every language combination is selectable, while thin routes can be saved
  // locally and enriched directly when the user requests it.
  static const supported = [
    englishToEnglish,
    englishToArabic,
    englishToFrench,
    englishToHindi,
    englishToUrdu,
    englishToFarsi,
    arabicToEnglish,
    arabicToArabic,
    arabicToFrench,
    arabicToHindi,
    arabicToUrdu,
    arabicToFarsi,
    frenchToEnglish,
    frenchToArabic,
    frenchToFrench,
    frenchToHindi,
    frenchToUrdu,
    frenchToFarsi,
    hindiToEnglish,
    hindiToArabic,
    hindiToFrench,
    hindiToHindi,
    hindiToUrdu,
    hindiToFarsi,
    urduToEnglish,
    urduToArabic,
    urduToFrench,
    urduToHindi,
    urduToUrdu,
    urduToFarsi,
    farsiToEnglish,
    farsiToArabic,
    farsiToFrench,
    farsiToHindi,
    farsiToUrdu,
    farsiToFarsi,
  ];

  static List<VocabularyLanguage> get availableTargets =>
      {for (final pair in supported) pair.target}.toList(growable: false);

  static List<LanguagePair> routesTo(VocabularyLanguage target) =>
      supported.where((pair) => pair.target == target).toList(growable: false);

  static List<LanguagePair> routesFrom(VocabularyLanguage source) =>
      supported.where((pair) => pair.source == source).toList(growable: false);

  static LanguagePair? route(
    VocabularyLanguage source,
    VocabularyLanguage target,
  ) {
    for (final pair in supported) {
      if (pair.source == source && pair.target == target) return pair;
    }
    return null;
  }

  static LanguagePair? tryParse(String? id) {
    if (id == null) return null;
    for (final pair in supported) {
      if (pair.id == id) return pair;
    }
    return null;
  }

  static VocabularyLanguage? detectSourceLanguage(String text) {
    final devanagariCount = RegExp(r'[\u0900-\u097F]').allMatches(text).length;
    if (devanagariCount > 0) return VocabularyLanguage.hindi;
    final extendedArabicCount = RegExp(
      r'[\u067E\u0686\u0698\u06AF\u06C3]',
    ).allMatches(text).length;
    if (extendedArabicCount > 0) return VocabularyLanguage.urdu;
    final arabicCount = RegExp(
      r'[\u0621-\u063A\u0641-\u064A]',
    ).allMatches(text).length;
    final latinCount = RegExp(
      r'[A-Za-zÀ-ÖØ-öø-ÿŒœÆæÇç]',
      unicode: true,
    ).allMatches(text).length;
    if (arabicCount == 0 && latinCount == 0) return null;
    if (latinCount == 0) return VocabularyLanguage.arabic;
    if (arabicCount == 0) {
      return RegExp(r'[À-ÖØ-öø-ÿŒœÆæÇç]', unicode: true).hasMatch(text)
          ? VocabularyLanguage.french
          : VocabularyLanguage.english;
    }
    if (arabicCount >= latinCount * 2) return VocabularyLanguage.arabic;
    return null;
  }

  static VocabularyLanguage? detectSourceForTarget(
    String text,
    VocabularyLanguage target,
  ) {
    final candidates = routesTo(target).map((pair) => pair.source).toSet();
    final devanagariCount = RegExp(r'[\u0900-\u097F]').allMatches(text).length;
    if (devanagariCount > 0 && candidates.contains(VocabularyLanguage.hindi)) {
      return VocabularyLanguage.hindi;
    }
    final extendedArabicCount = RegExp(
      r'[\u067E\u0686\u0698\u06AF\u06C3]',
    ).allMatches(text).length;
    if (extendedArabicCount > 0) {
      if (candidates.contains(VocabularyLanguage.urdu)) {
        return VocabularyLanguage.urdu;
      }
      if (candidates.contains(VocabularyLanguage.farsi)) {
        return VocabularyLanguage.farsi;
      }
    }
    final arabicCount = RegExp(
      r'[\u0621-\u063A\u0641-\u064A]',
    ).allMatches(text).length;
    if (arabicCount > 0 && candidates.contains(VocabularyLanguage.arabic)) {
      return VocabularyLanguage.arabic;
    }
    final latinCount = RegExp(
      r'[A-Za-zÀ-ÖØ-öø-ÿŒœÆæÇç]',
      unicode: true,
    ).allMatches(text).length;
    if (latinCount == 0) return null;
    final hasFrenchMarks = RegExp(
      r'[À-ÖØ-öø-ÿŒœÆæÇç]',
      unicode: true,
    ).hasMatch(text);
    if (hasFrenchMarks && candidates.contains(VocabularyLanguage.french)) {
      return VocabularyLanguage.french;
    }
    final latinCandidates = candidates
        .where((language) => language.writingSystem == WritingSystem.latin)
        .toList(growable: false);
    if (latinCandidates.length == 1) return latinCandidates.single;
    return null;
  }

  static LanguagePair? resolveForTarget(
    String text,
    VocabularyLanguage target, {
    VocabularyLanguage? fallbackSource,
  }) {
    final detected = detectSourceForTarget(text, target);
    if (detected != null) return route(detected, target);
    if (fallbackSource != null) {
      final fallback = route(fallbackSource, target);
      if (fallback != null) return fallback;
    }
    final routes = routesTo(target);
    return routes.isEmpty ? null : routes.first;
  }

  // Compatibility helper for entries and preferences created before the
  // preferred-target migration.
  static LanguagePair resolveForText(String text, LanguagePair fallback) {
    return resolveForTarget(
          text,
          fallback.target,
          fallbackSource: fallback.source,
        ) ??
        fallback;
  }

  @override
  bool operator ==(Object other) => other is LanguagePair && other.id == id;

  @override
  int get hashCode => Object.hash(source, target);
}

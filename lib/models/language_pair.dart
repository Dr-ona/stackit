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

enum WritingSystem { latin, arabic }

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

  // Product routes and offline dictionary coverage are intentionally separate:
  // every language combination is selectable, while thin routes can be saved
  // locally and enriched directly when the user requests it.
  static const supported = [
    englishToEnglish,
    englishToArabic,
    englishToFrench,
    arabicToEnglish,
    arabicToArabic,
    arabicToFrench,
    frenchToEnglish,
    frenchToArabic,
    frenchToFrench,
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
    final arabicCount = RegExp(
      r'[\u0621-\u063A\u0641-\u064A]',
    ).allMatches(text).length;
    if (arabicCount > 0) return VocabularyLanguage.arabic;
    final latinCount = RegExp(
      r'[A-Za-zÀ-ÖØ-öø-ÿŒœÆæÇç]',
      unicode: true,
    ).allMatches(text).length;
    if (latinCount == 0) return null;
    final hasFrenchMarks = RegExp(
      r'[À-ÖØ-öø-ÿŒœÆæÇç]',
      unicode: true,
    ).hasMatch(text);
    if (hasFrenchMarks) return VocabularyLanguage.french;
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

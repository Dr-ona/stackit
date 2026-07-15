enum VocabularyLanguage {
  english(code: 'en', label: 'English', localeTag: 'en-US', isRtl: false),
  arabic(code: 'ar', label: 'Arabic', localeTag: 'ar-SA', isRtl: true);

  const VocabularyLanguage({
    required this.code,
    required this.label,
    required this.localeTag,
    required this.isRtl,
  });

  final String code;
  final String label;
  final String localeTag;
  final bool isRtl;

  static VocabularyLanguage fromCode(String? code) {
    return values.firstWhere(
      (language) => language.code == code,
      orElse: () => VocabularyLanguage.english,
    );
  }
}

class LanguagePair {
  const LanguagePair({required this.source, required this.target})
    : assert(source != target, 'Source and target languages must differ.');

  final VocabularyLanguage source;
  final VocabularyLanguage target;

  String get id => '${source.code}_${target.code}';
  String get label => '${source.label} → ${target.label}';

  LanguagePair get reversed => LanguagePair(source: target, target: source);

  static const englishToArabic = LanguagePair(
    source: VocabularyLanguage.english,
    target: VocabularyLanguage.arabic,
  );
  static const arabicToEnglish = LanguagePair(
    source: VocabularyLanguage.arabic,
    target: VocabularyLanguage.english,
  );
  static const supported = [englishToArabic, arabicToEnglish];

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
    final englishCount = RegExp(r'[A-Za-z]').allMatches(text).length;
    if (arabicCount == 0 && englishCount == 0) return null;
    if (arabicCount == 0) return VocabularyLanguage.english;
    if (englishCount == 0) return VocabularyLanguage.arabic;
    if (arabicCount >= englishCount * 2) return VocabularyLanguage.arabic;
    if (englishCount >= arabicCount * 2) return VocabularyLanguage.english;
    return null;
  }

  static LanguagePair resolveForText(String text, LanguagePair fallback) {
    final detected = detectSourceLanguage(text);
    if (detected == null || detected == fallback.source) {
      return fallback;
    }
    for (final pair in supported) {
      if (pair.source == detected && pair.target == fallback.source) {
        return pair;
      }
    }
    for (final pair in supported) {
      if (pair.source == detected) return pair;
    }
    return fallback;
  }

  @override
  bool operator ==(Object other) => other is LanguagePair && other.id == id;

  @override
  int get hashCode => Object.hash(source, target);
}

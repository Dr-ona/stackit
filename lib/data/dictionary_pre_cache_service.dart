import 'dart:async';

import '../models/language_pair.dart';
import 'gemini_dictionary_service.dart';
import 'local_dictionary_cache.dart';

class DictionaryPreCacheService {
  DictionaryPreCacheService({
    required this._cache,
    required this._gemini,
    int requestsPerMinute = 10,
  }) : _rpm = requestsPerMinute;

  final LocalDictionaryCache _cache;
  final GeminiDictionaryService _gemini;
  final int _rpm;

  bool _running = false;
  double _progress = 0.0;

  bool get isRunning => _running;
  double get progress => _progress;

  /// Pre-cache the most common words for the given language pair.
  ///
  /// Each word that already exists in the cache is skipped. Words are
  /// fetched one at a time with a delay to stay within Gemini free-tier
  /// rate limits.
  Future<void> preCache(LanguagePair pair, {List<String>? words}) async {
    if (_running) return;
    _running = true;
    _progress = 0.0;

    try {
      final targets = words ?? _commonWords(pair.source);
      final total = targets.length;
      if (total == 0) return;

      final delay = Duration(milliseconds: (60 * 1000 / _rpm).ceil());

      for (var i = 0; i < total; i++) {
        final word = targets[i];
        if (await _cache.lookup(word, pair) != null) {
          _progress = (i + 1) / total;
          continue;
        }

        final result = await _gemini.lookup(word, pair);
        if (result != null) {
          await _cache.store(result, pair);
        }

        _progress = (i + 1) / total;
        if (i < total - 1) {
          await Future<void>.delayed(delay);
        }
      }
    } finally {
      _running = false;
    }
  }

  /// Quick check — only pre-cache words that aren't already cached.
  int estimatedRemaining(LanguagePair pair, List<String> words) {
    // We can't check disk synchronously, so just return the total.
    // The actual lookup inside preCache skips cached entries anyway.
    return words.length;
  }

  /// Common single-word entries for a language. Used as a default list
  /// when the caller doesn't supply one.
  static List<String> _commonWords(VocabularyLanguage lang) {
    switch (lang) {
      case VocabularyLanguage.english:
        return _englishWords;
      case VocabularyLanguage.arabic:
        return _arabicWords;
      case VocabularyLanguage.french:
        return _frenchWords;
      case VocabularyLanguage.hindi:
        return _hindiWords;
      case VocabularyLanguage.urdu:
        return _urduWords;
      case VocabularyLanguage.farsi:
        return _farsiWords;
    }
  }

  static const _englishWords = [
    'hello',
    'goodbye',
    'thank',
    'please',
    'sorry',
    'help',
    'water',
    'food',
    'time',
    'day',
    'good',
    'bad',
    'big',
    'small',
    'new',
    'love',
    'hate',
    'want',
    'need',
    'know',
    'see',
    'hear',
    'eat',
    'drink',
    'go',
    'come',
    'work',
    'money',
    'friend',
    'family',
    'house',
    'car',
    'book',
    'school',
    'teacher',
    'child',
    'mother',
    'father',
    'brother',
    'sister',
    'one',
    'two',
    'three',
    'yes',
    'no',
  ];

  static const _arabicWords = [
    'مرحبا',
    'شكرا',
    'عفوا',
    'مساء',
    'نعم',
    'لا',
    'ماء',
    'خبز',
    'وقت',
    'يوم',
    'ليلة',
    'سماء',
    'أرض',
    'نار',
    'كتاب',
    'بيت',
    'طريق',
    'مدينة',
    'بلد',
    'أب',
    'أم',
    'أخ',
    'أخت',
    'ابن',
    'صديق',
    'عمل',
    'مال',
    'حب',
    'حياة',
    'موت',
    'جديد',
    'قديم',
    'كبير',
    'صغير',
    'جيد',
    'سيء',
    'حقيقي',
    'ممكن',
    'لازم',
  ];

  static const _frenchWords = [
    'bonjour',
    'merci',
    's\'il vous plaît',
    'excusez-moi',
    'au revoir',
    'oui',
    'non',
    'eau',
    'pain',
    'temps',
    'jour',
    'nuit',
    'ciel',
    'terre',
    'feu',
    'livre',
    'maison',
    'rue',
    'ville',
    'pays',
    'père',
    'mère',
    'frère',
    'sœur',
    'ami',
    'travail',
    'argent',
    'amour',
    'vie',
    'mort',
    'nouveau',
    'vieux',
    'grand',
    'petit',
    'bon',
    'mauvais',
    'possible',
    'vraiment',
    'beaucoup',
    'toujours',
  ];

  static const _hindiWords = [
    'नमस्ते',
    'शुक्रिया',
    'कृपया',
    'माफ़ कीजिये',
    'अलविदा',
    'हाँ',
    'नहीं',
    'पानी',
    'रोटी',
    'समय',
    'दिन',
    'रात',
    'आसमान',
    'ज़मीन',
    'आग',
    'किताब',
    'घर',
    'सड़क',
    'शहर',
    'देश',
    'पिता',
    'माता',
    'भाई',
    'बहन',
    'बेटा',
    'दोस्त',
    'काम',
    'पैसा',
    'प्यार',
    'ज़िन्दगी',
    'मौत',
    'नया',
    'पुराना',
    'बड़ा',
    'छोटा',
    'अच्छा',
    'बुरा',
    'सच्चा',
    'मुमकिन',
    'ज़रूरी',
  ];

  static const _urduWords = [
    'السلام علیکم',
    'شکریہ',
    'معاف کیجیے',
    'خدا حافظ',
    'جی ہاں',
    'نہیں',
    'پانی',
    'روٹی',
    'وقت',
    'دن',
    'رات',
    'آسمان',
    'زمین',
    'آگ',
    'کتاب',
    'گھر',
    'سڑک',
    'شہر',
    'ملک',
    'باپ',
    'ماں',
    'بھائی',
    'بہن',
    'بیٹا',
    'دوست',
    'کام',
    'مال',
    'محبت',
    'زندگی',
    'موت',
    'نیا',
    'پرانا',
    'بڑا',
    'چھوٹا',
    'اچھا',
    'برا',
    'سچا',
    'ممکن',
    'ضروری',
  ];

  static const _farsiWords = [
    'سلام',
    'متشکرم',
    'لطفاً',
    'ببخشید',
    'خداحافظ',
    'بله',
    'نه',
    'آب',
    'نان',
    'زمان',
    'روز',
    'شب',
    'آسمان',
    'زمین',
    'آتش',
    'کتاب',
    'خانه',
    'خیابان',
    'شهر',
    'کشور',
    'پدر',
    'مادر',
    'برادر',
    'خواهر',
    'پسر',
    'دوست',
    'کار',
    'پول',
    'عشق',
    'زندگی',
    'مرگ',
    'جدید',
    'قدیمی',
    'بزرگ',
    'کوچک',
    'خوب',
    'بد',
    'واقعی',
    'ممکن',
    'لازم',
  ];
}

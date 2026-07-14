import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/data/offline_dictionary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineDictionary', () {
    test('loads the complete compact FreeDict index', () async {
      final dictionary = OfflineDictionary();

      await dictionary.load();

      expect(dictionary.freeDictEntryCount, 87412);
    });

    test('finds an exact English to Arabic entry', () async {
      final result = await OfflineDictionary().lookup('elusive');
      expect(result, isNotNull);
      expect(result!.arabic, contains('صعب المنال'));
    });

    test('normalizes punctuation and casing', () async {
      final result = await OfflineDictionary().lookup('  Nuance! ');
      expect(result?.term, 'nuance');
    });

    test('supports phrases selected by the user', () async {
      final result = await OfflineDictionary().lookup('figure out');
      expect(result?.partOfSpeech, 'phrasal verb');
    });

    test('falls back to an entry outside the curated seed', () async {
      final result = await OfflineDictionary().lookup('Befriend');

      expect(result?.term, 'befriend');
      expect(result?.arabic, contains('صادق'));
      expect(result?.definition, 'Offline English–Arabic translation.');
    });

    test('returns null for unknown text', () async {
      final result = await OfflineDictionary().lookup(
        'not-in-the-seed-lexicon',
      );
      expect(result, isNull);
    });
  });
}

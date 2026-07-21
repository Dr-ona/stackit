import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String rules;

  setUpAll(() {
    rules = File('firestore.rules').readAsStringSync();
  });

  test('vocabulary rules allow every supported language combination', () {
    expect(rules, contains("return value in ['en', 'ar', 'fr'];"));
    expect(
      rules,
      contains('isSupportedVocabularyLanguage(data.sourceLanguage)'),
    );
    expect(
      rules,
      contains('isSupportedVocabularyLanguage(data.targetLanguage)'),
    );
    expect(
      rules,
      isNot(contains('data.sourceLanguage != data.targetLanguage')),
    );
  });

  test('owner, strict schema, and immutable timestamps remain enforced', () {
    expect(rules, contains('allow create: if isOwner(userId)'));
    expect(rules, contains('hasOnlyVocabularyFields(data)'));
    expect(rules, contains('hasOnlyProfileFields(data)'));
    expect(
      rules,
      contains('request.resource.data.createdAt == resource.data.createdAt'),
    );
    expect(rules, contains('allow read, write: if false'));
  });
}

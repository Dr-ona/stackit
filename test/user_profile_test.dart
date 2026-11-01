import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/models/user_profile.dart';

void main() {
  test('sparse legacy data migrates to safe versioned defaults', () {
    final profile = UserProfile.fromJson({
      'displayName': '  Ona  ',
      'preferredTargetLanguage': 'fr',
      'dailyReviewGoal': 999,
      'createdAt': '2026-01-02T03:04:05Z',
    });

    expect(profile.schemaVersion, UserProfile.currentSchemaVersion);
    expect(profile.displayName, 'Ona');
    expect(profile.preferredTargetLanguageCode, 'fr');
    expect(profile.dailyReviewGoal, 100);
    expect(profile.reviewIntensity, ReviewIntensity.balanced);
    expect(profile.learningLanguages, isEmpty);
    expect(profile.analyticsConsent, isFalse);
    expect(profile.onboardingCompleted, isFalse);
    expect(profile.avatarStoragePath, isNull);
  });

  test('normalization removes duplicates and bounds scalable list data', () {
    final now = DateTime.utc(2026, 1, 1);
    final profile = UserProfile(
      displayName: '  Learner  ',
      nativeLanguageCode: 'ar',
      interfaceLanguageCode: null,
      learningLanguages: const [
        LearningLanguagePreference(languageCode: 'en'),
        LearningLanguagePreference(
          languageCode: 'EN',
          proficiency: LanguageProficiency.advanced,
        ),
        LearningLanguagePreference(languageCode: ''),
      ],
      preferredTargetLanguageCode: 'ar',
      dailyReviewGoal: -2,
      reviewIntensity: ReviewIntensity.intensive,
      interests: List.generate(20, (index) => ' interest $index '),
      learningPurposes: const [' work ', '', 'conversation'],
      aiEnabled: true,
      notificationsEnabled: false,
      analyticsConsent: false,
      onboardingCompleted: true,
      createdAt: now,
      updatedAt: now.subtract(const Duration(days: 1)),
    ).normalized();

    expect(profile.displayName, 'Learner');
    expect(profile.learningLanguages, hasLength(1));
    expect(profile.learningLanguages.single.languageCode, 'en');
    expect(profile.dailyReviewGoal, 1);
    expect(profile.interests, hasLength(12));
    expect(profile.learningPurposes, ['work', 'conversation']);
    expect(profile.updatedAt, now);
  });

  test(
    'profile JSON round-trip keeps language proficiency and preferences',
    () {
      final now = DateTime.utc(2026, 2, 3, 4, 5);
      final original = UserProfile(
        displayName: 'Mina',
        avatarStoragePath: 'users/user-a/profile/avatar',
        nativeLanguageCode: 'ar',
        interfaceLanguageCode: 'fr',
        learningLanguages: const [
          LearningLanguagePreference(
            languageCode: 'en',
            proficiency: LanguageProficiency.upperIntermediate,
            pronunciationLocale: 'en-GB',
          ),
        ],
        preferredTargetLanguageCode: 'ar',
        dailyReviewGoal: 15,
        reviewIntensity: ReviewIntensity.gentle,
        interests: const ['technology'],
        learningPurposes: const ['work'],
        aiEnabled: true,
        notificationsEnabled: true,
        analyticsConsent: true,
        onboardingCompleted: true,
        createdAt: now,
        updatedAt: now,
      );

      final restored = UserProfile.fromJson(original.toJson());

      expect(
        restored.learningLanguages.single.proficiency,
        LanguageProficiency.upperIntermediate,
      );
      expect(restored.learningLanguages.single.pronunciationLocale, 'en-GB');
      expect(restored.reviewIntensity, ReviewIntensity.gentle);
      expect(restored.analyticsConsent, isTrue);
      expect(restored.avatarStoragePath, 'users/user-a/profile/avatar');
    },
  );
}

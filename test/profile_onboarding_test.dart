import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/features/profile/profile_onboarding.dart';
import 'package:stackit/models/user_profile.dart';

void main() {
  final incomplete = UserProfile.defaults(
    now: DateTime.utc(2026),
    preferredTargetLanguageCode: 'ar',
  );

  test('waits for vocabulary and profile sync before onboarding', () {
    expect(
      profileOnboardingKind(
        profile: incomplete,
        controllerReady: true,
        vocabularySyncing: true,
        profileSyncing: false,
        hasVocabulary: false,
      ),
      ProfileOnboardingKind.none,
    );
    expect(
      profileOnboardingKind(
        profile: incomplete,
        controllerReady: true,
        vocabularySyncing: false,
        profileSyncing: true,
        hasVocabulary: false,
      ),
      ProfileOnboardingKind.none,
    );
  });

  test('new users receive first-run onboarding', () {
    expect(
      profileOnboardingKind(
        profile: incomplete,
        controllerReady: true,
        vocabularySyncing: false,
        profileSyncing: false,
        hasVocabulary: false,
      ),
      ProfileOnboardingKind.firstRun,
    );
  });

  test('existing vocabulary users receive a migration prompt', () {
    expect(
      profileOnboardingKind(
        profile: incomplete,
        controllerReady: true,
        vocabularySyncing: false,
        profileSyncing: false,
        hasVocabulary: true,
      ),
      ProfileOnboardingKind.migration,
    );
  });

  test('completed profiles are never prompted', () {
    expect(
      profileOnboardingKind(
        profile: incomplete.copyWith(onboardingCompleted: true),
        controllerReady: true,
        vocabularySyncing: false,
        profileSyncing: false,
        hasVocabulary: true,
      ),
      ProfileOnboardingKind.none,
    );
  });
}

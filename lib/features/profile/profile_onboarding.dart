import '../../models/user_profile.dart';

enum ProfileOnboardingKind { none, firstRun, migration }

ProfileOnboardingKind profileOnboardingKind({
  required UserProfile? profile,
  required bool controllerReady,
  required bool vocabularySyncing,
  required bool profileSyncing,
  required bool hasVocabulary,
}) {
  if (!controllerReady ||
      vocabularySyncing ||
      profileSyncing ||
      profile == null ||
      profile.onboardingCompleted) {
    return ProfileOnboardingKind.none;
  }
  return hasVocabulary
      ? ProfileOnboardingKind.migration
      : ProfileOnboardingKind.firstRun;
}

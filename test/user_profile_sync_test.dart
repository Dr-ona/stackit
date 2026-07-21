import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/data/offline_dictionary.dart';
import 'package:stackit/data/platform_bridge.dart';
import 'package:stackit/data/profile_avatar_store.dart';
import 'package:stackit/data/user_profile_cloud_store.dart';
import 'package:stackit/data/vocabulary_cloud_store.dart';
import 'package:stackit/features/vocabulary/vocabulary_controller.dart';
import 'package:stackit/models/capture_payload.dart';
import 'package:stackit/models/language_pair.dart';
import 'package:stackit/models/user_profile.dart';
import 'package:stackit/models/vocabulary_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('first sync creates and stores a safe private profile', () async {
    final bridge = _ProfileBridge();
    final profiles = _ProfileStore();
    final controller = _controller(bridge, profiles);

    await controller.initialize();
    await controller.syncForUser('user-a', displayName: 'Ona');

    expect(controller.userProfile?.displayName, 'Ona');
    expect(controller.userProfile?.onboardingCompleted, isFalse);
    expect(bridge.profileUserId, 'user-a');
    expect(profiles.saved?.displayName, 'Ona');
  });

  test('newer remote profile wins and is cached locally', () async {
    final older = _profile(DateTime.utc(2026, 1, 1), name: 'Local');
    final newer = _profile(DateTime.utc(2026, 1, 2), name: 'Cloud');
    final bridge = _ProfileBridge()
      ..profile = older
      ..profileUserId = 'user-a';
    final profiles = _ProfileStore()..remote = newer;
    final controller = _controller(bridge, profiles);

    await controller.initialize();
    await controller.syncForUser('user-a');

    expect(controller.userProfile?.displayName, 'Cloud');
    expect(bridge.profile?.displayName, 'Cloud');
  });

  test('newer local profile preserves remote creation time', () async {
    final local = _profile(
      DateTime.utc(2026, 1, 3),
      name: 'Local',
      createdAt: DateTime.utc(2026, 1, 1),
    );
    final remote = _profile(
      DateTime.utc(2026, 1, 2),
      name: 'Cloud',
      createdAt: DateTime.utc(2026, 1, 2),
    );
    final bridge = _ProfileBridge()
      ..profile = local
      ..profileUserId = 'user-a';
    final profiles = _ProfileStore()..remote = remote;
    final controller = _controller(bridge, profiles);

    await controller.initialize();
    await controller.syncForUser('user-a');

    expect(profiles.saved?.displayName, 'Local');
    expect(profiles.saved?.createdAt, remote.createdAt);
    expect(bridge.profile?.createdAt, remote.createdAt);
  });

  test('profile update remains local and queues a cloud write', () async {
    final bridge = _ProfileBridge();
    final profiles = _ProfileStore();
    final controller = _controller(bridge, profiles);
    await controller.initialize();
    await controller.syncForUser('user-a');

    final changed = controller.userProfile!.copyWith(
      nativeLanguageCode: 'ar',
      learningLanguages: const [
        LearningLanguagePreference(
          languageCode: 'fr',
          proficiency: LanguageProficiency.intermediate,
        ),
      ],
      onboardingCompleted: true,
    );
    await controller.updateUserProfile(changed);
    await Future<void>.delayed(Duration.zero);

    expect(bridge.profile?.nativeLanguageCode, 'ar');
    expect(bridge.profile?.onboardingCompleted, isTrue);
    expect(profiles.saved?.learningLanguages.single.languageCode, 'fr');
  });

  test(
    'avatar upload and removal update local and cloud profile state',
    () async {
      final bridge = _ProfileBridge();
      final profiles = _ProfileStore();
      final avatars = _AvatarStore();
      final controller = _controller(bridge, profiles, avatars: avatars);
      await controller.initialize();
      await controller.syncForUser('user-a');

      final jpeg = Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]);
      await controller.uploadProfileAvatar(jpeg);
      await Future<void>.delayed(Duration.zero);

      expect(avatars.uploadedUserId, 'user-a');
      expect(avatars.uploadedBytes, jpeg);
      expect(
        controller.userProfile?.avatarStoragePath,
        'users/user-a/profile/avatar',
      );
      expect(profiles.saved?.avatarStoragePath, 'users/user-a/profile/avatar');

      await controller.removeProfileAvatar();
      await Future<void>.delayed(Duration.zero);

      expect(avatars.deletedUserId, 'user-a');
      expect(controller.userProfile?.avatarStoragePath, isNull);
      expect(profiles.saved?.avatarStoragePath, isNull);
    },
  );

  test('cloud failure keeps the local profile usable', () async {
    final local = _profile(DateTime.utc(2026, 1, 1), name: 'Offline learner');
    final bridge = _ProfileBridge()
      ..profile = local
      ..profileUserId = 'user-a';
    final profiles = _ProfileStore()..loadError = StateError('offline');
    final controller = _controller(bridge, profiles);

    await controller.initialize();
    await controller.syncForUser('user-a');

    expect(controller.userProfile?.displayName, 'Offline learner');
    expect(controller.profileSyncError, isNotNull);
    expect(bridge.profile?.displayName, 'Offline learner');
  });

  test(
    'account deletion removes vocabulary, profile, and local cache',
    () async {
      final bridge = _ProfileBridge();
      final profiles = _ProfileStore();
      final vocabulary = _VocabularyStore();
      final avatars = _AvatarStore();
      final controller = VocabularyController(
        OfflineDictionary(),
        bridge,
        vocabulary,
        null,
        null,
        profiles,
        null,
        avatars,
      );
      await controller.initialize();
      await controller.syncForUser('user-a');

      await controller.deleteAccountData('user-a');

      expect(profiles.deletedUserId, 'user-a');
      expect(vocabulary.deletedUserId, 'user-a');
      expect(avatars.deletedUserId, 'user-a');
      expect(bridge.profile, isNull);
      expect(controller.userProfile, isNull);
    },
  );
}

VocabularyController _controller(
  _ProfileBridge bridge,
  _ProfileStore profiles, {
  ProfileAvatarStore? avatars,
}) {
  return VocabularyController(
    OfflineDictionary(),
    bridge,
    _VocabularyStore(),
    null,
    null,
    profiles,
    null,
    avatars,
  );
}

UserProfile _profile(DateTime updatedAt, {String? name, DateTime? createdAt}) {
  return UserProfile(
    displayName: name,
    nativeLanguageCode: null,
    interfaceLanguageCode: null,
    learningLanguages: const [],
    preferredTargetLanguageCode: 'ar',
    dailyReviewGoal: 10,
    reviewIntensity: ReviewIntensity.balanced,
    interests: const [],
    learningPurposes: const [],
    aiEnabled: false,
    notificationsEnabled: false,
    analyticsConsent: false,
    onboardingCompleted: false,
    createdAt: createdAt ?? DateTime.utc(2026),
    updatedAt: updatedAt,
  );
}

class _ProfileBridge extends PlatformBridge {
  UserProfile? profile;
  String? profileUserId;
  List<VocabularyEntry> entries = const [];

  @override
  Future<CapturePayload?> takeInitialSelection() async => null;

  @override
  Future<List<VocabularyEntry>> loadEntries() async => entries;

  @override
  Future<void> saveEntries(List<VocabularyEntry> entries) async {
    this.entries = List.unmodifiable(entries);
  }

  @override
  Future<UserProfile?> loadUserProfile({String? userId}) async {
    if (userId != null && profileUserId != userId) return null;
    return profile;
  }

  @override
  Future<void> saveUserProfile(UserProfile profile, {String? userId}) async {
    this.profile = profile;
    profileUserId = userId;
  }

  @override
  Future<void> clearUserProfile() async {
    profile = null;
    profileUserId = null;
  }

  @override
  Future<void> speak(
    String text,
    VocabularyLanguage language, {
    String? localeTag,
  }) async {}
}

class _ProfileStore implements UserProfileCloudStore {
  UserProfile? remote;
  UserProfile? saved;
  Object? loadError;
  String? deletedUserId;

  @override
  Future<UserProfile?> loadProfile(String userId) async {
    final error = loadError;
    if (error != null) throw error;
    return remote;
  }

  @override
  Future<void> saveProfile(String userId, UserProfile profile) async {
    saved = profile;
    remote = profile;
  }

  @override
  Future<void> deleteProfile(String userId) async {
    deletedUserId = userId;
    remote = null;
    saved = null;
  }
}

class _VocabularyStore implements VocabularyCloudStore {
  String? deletedUserId;

  @override
  Future<List<VocabularyEntry>> loadEntries(String userId) async => const [];

  @override
  Future<void> upsertEntry(String userId, VocabularyEntry entry) async {}

  @override
  Future<void> upsertEntries(
    String userId,
    Iterable<VocabularyEntry> entries,
  ) async {}

  @override
  Future<void> deleteEntry(String userId, String entryId) async {}

  @override
  Future<void> deleteAllEntries(String userId) async {
    deletedUserId = userId;
  }
}

class _AvatarStore implements ProfileAvatarStore {
  String? deletedUserId;
  String? uploadedUserId;
  Uint8List? uploadedBytes;

  @override
  String pathForUser(String userId) => 'users/$userId/profile/avatar';

  @override
  Future<void> deleteAvatar(String userId) async {
    deletedUserId = userId;
  }

  @override
  Future<Uint8List?> loadAvatar(String userId) async => null;

  @override
  Future<String> uploadAvatar(String userId, Uint8List bytes) async {
    uploadedUserId = userId;
    uploadedBytes = bytes;
    return pathForUser(userId);
  }
}

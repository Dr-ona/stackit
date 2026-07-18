const _unsetProfileValue = Object();

enum LanguageProficiency {
  beginner,
  elementary,
  intermediate,
  upperIntermediate,
  advanced,
  proficient;

  String get storageValue => switch (this) {
    LanguageProficiency.beginner => 'beginner',
    LanguageProficiency.elementary => 'elementary',
    LanguageProficiency.intermediate => 'intermediate',
    LanguageProficiency.upperIntermediate => 'upper-intermediate',
    LanguageProficiency.advanced => 'advanced',
    LanguageProficiency.proficient => 'proficient',
  };

  static LanguageProficiency fromStorage(Object? value) {
    return LanguageProficiency.values.firstWhere(
      (item) => item.storageValue == value,
      orElse: () => LanguageProficiency.beginner,
    );
  }
}

enum ReviewIntensity {
  gentle,
  balanced,
  intensive;

  String get storageValue => name;

  static ReviewIntensity fromStorage(Object? value) {
    return ReviewIntensity.values.firstWhere(
      (item) => item.storageValue == value,
      orElse: () => ReviewIntensity.balanced,
    );
  }
}

class LearningLanguagePreference {
  const LearningLanguagePreference({
    required this.languageCode,
    this.proficiency = LanguageProficiency.beginner,
    this.pronunciationLocale,
  });

  final String languageCode;
  final LanguageProficiency proficiency;
  final String? pronunciationLocale;

  factory LearningLanguagePreference.fromJson(Map<String, Object?> json) {
    return LearningLanguagePreference(
      languageCode: (json['languageCode'] as String? ?? '').trim(),
      proficiency: LanguageProficiency.fromStorage(json['proficiency']),
      pronunciationLocale: _trimmedOrNull(json['pronunciationLocale']),
    );
  }

  LearningLanguagePreference copyWith({
    LanguageProficiency? proficiency,
    Object? pronunciationLocale = _unsetProfileValue,
  }) {
    return LearningLanguagePreference(
      languageCode: languageCode,
      proficiency: proficiency ?? this.proficiency,
      pronunciationLocale: identical(pronunciationLocale, _unsetProfileValue)
          ? this.pronunciationLocale
          : _trimmedOrNull(pronunciationLocale),
    );
  }

  Map<String, Object?> toJson() => {
    'languageCode': languageCode,
    'proficiency': proficiency.storageValue,
    'pronunciationLocale': pronunciationLocale,
  };
}

class UserProfile {
  const UserProfile({
    this.schemaVersion = currentSchemaVersion,
    required this.displayName,
    this.avatarStoragePath,
    required this.nativeLanguageCode,
    required this.interfaceLanguageCode,
    required this.learningLanguages,
    required this.preferredTargetLanguageCode,
    required this.dailyReviewGoal,
    required this.reviewIntensity,
    required this.interests,
    required this.learningPurposes,
    required this.aiEnabled,
    required this.notificationsEnabled,
    required this.analyticsConsent,
    required this.onboardingCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  static const currentSchemaVersion = 2;

  final int schemaVersion;
  final String? displayName;
  final String? avatarStoragePath;
  final String? nativeLanguageCode;
  final String? interfaceLanguageCode;
  final List<LearningLanguagePreference> learningLanguages;
  final String preferredTargetLanguageCode;
  final int dailyReviewGoal;
  final ReviewIntensity reviewIntensity;
  final List<String> interests;
  final List<String> learningPurposes;
  final bool aiEnabled;
  final bool notificationsEnabled;
  final bool analyticsConsent;
  final bool onboardingCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory UserProfile.defaults({
    required DateTime now,
    String? displayName,
    String? nativeLanguageCode,
    String? interfaceLanguageCode,
    required String preferredTargetLanguageCode,
    bool notificationsEnabled = false,
  }) {
    return UserProfile(
      displayName: _trimmedOrNull(displayName),
      avatarStoragePath: null,
      nativeLanguageCode: _trimmedOrNull(nativeLanguageCode),
      interfaceLanguageCode: _trimmedOrNull(interfaceLanguageCode),
      learningLanguages: const [],
      preferredTargetLanguageCode: preferredTargetLanguageCode,
      dailyReviewGoal: 10,
      reviewIntensity: ReviewIntensity.balanced,
      interests: const [],
      learningPurposes: const [],
      aiEnabled: false,
      notificationsEnabled: notificationsEnabled,
      analyticsConsent: false,
      onboardingCompleted: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory UserProfile.fromJson(Map<String, Object?> json) {
    final now = DateTime.now();
    final preferredTarget =
        _trimmedOrNull(json['preferredTargetLanguage']) ?? 'ar';
    return UserProfile(
      schemaVersion: currentSchemaVersion,
      displayName: _trimmedOrNull(json['displayName']),
      avatarStoragePath: _trimmedOrNull(json['avatarStoragePath']),
      nativeLanguageCode: _trimmedOrNull(json['nativeLanguage']),
      interfaceLanguageCode: _trimmedOrNull(json['interfaceLanguage']),
      learningLanguages: _learningLanguages(json['learningLanguages']),
      preferredTargetLanguageCode: preferredTarget,
      dailyReviewGoal: _boundedInt(json['dailyReviewGoal'], 1, 100, 10),
      reviewIntensity: ReviewIntensity.fromStorage(json['reviewIntensity']),
      interests: _boundedStrings(json['interests'], 12, 60),
      learningPurposes: _boundedStrings(json['learningPurposes'], 8, 80),
      aiEnabled: json['aiEnabled'] as bool? ?? false,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? false,
      analyticsConsent: json['analyticsConsent'] as bool? ?? false,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      createdAt: _date(json['createdAt']) ?? now,
      updatedAt: _date(json['updatedAt']) ?? _date(json['createdAt']) ?? now,
    ).normalized();
  }

  UserProfile normalized() {
    final uniqueLanguages = <String, LearningLanguagePreference>{};
    for (final language in learningLanguages.take(8)) {
      final code = language.languageCode.trim();
      if (code.isEmpty || code.length > 20) continue;
      uniqueLanguages.putIfAbsent(
        code.toLowerCase(),
        () => LearningLanguagePreference(
          languageCode: code,
          proficiency: language.proficiency,
          pronunciationLocale: _trimmedOrNull(language.pronunciationLocale),
        ),
      );
    }
    return UserProfile(
      displayName: _boundedOptionalString(displayName, 80),
      avatarStoragePath: _boundedOptionalString(avatarStoragePath, 200),
      nativeLanguageCode: _boundedOptionalString(nativeLanguageCode, 20),
      interfaceLanguageCode: _boundedOptionalString(interfaceLanguageCode, 20),
      learningLanguages: List.unmodifiable(uniqueLanguages.values),
      preferredTargetLanguageCode:
          _boundedOptionalString(preferredTargetLanguageCode, 20) ?? 'ar',
      dailyReviewGoal: dailyReviewGoal.clamp(1, 100),
      reviewIntensity: reviewIntensity,
      interests: List.unmodifiable(
        interests
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .take(12)
            .map(
              (value) => value.length <= 60 ? value : value.substring(0, 60),
            ),
      ),
      learningPurposes: List.unmodifiable(
        learningPurposes
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .take(8)
            .map(
              (value) => value.length <= 80 ? value : value.substring(0, 80),
            ),
      ),
      aiEnabled: aiEnabled,
      notificationsEnabled: notificationsEnabled,
      analyticsConsent: analyticsConsent,
      onboardingCompleted: onboardingCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt.isBefore(createdAt) ? createdAt : updatedAt,
    );
  }

  UserProfile copyWith({
    Object? displayName = _unsetProfileValue,
    Object? avatarStoragePath = _unsetProfileValue,
    Object? nativeLanguageCode = _unsetProfileValue,
    Object? interfaceLanguageCode = _unsetProfileValue,
    List<LearningLanguagePreference>? learningLanguages,
    String? preferredTargetLanguageCode,
    int? dailyReviewGoal,
    ReviewIntensity? reviewIntensity,
    List<String>? interests,
    List<String>? learningPurposes,
    bool? aiEnabled,
    bool? notificationsEnabled,
    bool? analyticsConsent,
    bool? onboardingCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      displayName: identical(displayName, _unsetProfileValue)
          ? this.displayName
          : _trimmedOrNull(displayName),
      avatarStoragePath: identical(avatarStoragePath, _unsetProfileValue)
          ? this.avatarStoragePath
          : _trimmedOrNull(avatarStoragePath),
      nativeLanguageCode: identical(nativeLanguageCode, _unsetProfileValue)
          ? this.nativeLanguageCode
          : _trimmedOrNull(nativeLanguageCode),
      interfaceLanguageCode:
          identical(interfaceLanguageCode, _unsetProfileValue)
          ? this.interfaceLanguageCode
          : _trimmedOrNull(interfaceLanguageCode),
      learningLanguages: learningLanguages ?? this.learningLanguages,
      preferredTargetLanguageCode:
          preferredTargetLanguageCode ?? this.preferredTargetLanguageCode,
      dailyReviewGoal: dailyReviewGoal ?? this.dailyReviewGoal,
      reviewIntensity: reviewIntensity ?? this.reviewIntensity,
      interests: interests ?? this.interests,
      learningPurposes: learningPurposes ?? this.learningPurposes,
      aiEnabled: aiEnabled ?? this.aiEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      analyticsConsent: analyticsConsent ?? this.analyticsConsent,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    ).normalized();
  }

  Map<String, Object?> toJson() => {
    'schemaVersion': currentSchemaVersion,
    'displayName': displayName,
    'avatarStoragePath': avatarStoragePath,
    'nativeLanguage': nativeLanguageCode,
    'interfaceLanguage': interfaceLanguageCode,
    'learningLanguages': learningLanguages
        .map((language) => language.toJson())
        .toList(growable: false),
    'preferredTargetLanguage': preferredTargetLanguageCode,
    'dailyReviewGoal': dailyReviewGoal,
    'reviewIntensity': reviewIntensity.storageValue,
    'interests': interests,
    'learningPurposes': learningPurposes,
    'aiEnabled': aiEnabled,
    'notificationsEnabled': notificationsEnabled,
    'analyticsConsent': analyticsConsent,
    'onboardingCompleted': onboardingCompleted,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };
}

List<LearningLanguagePreference> _learningLanguages(Object? value) {
  if (value is! List<Object?>) return const [];
  return value
      .whereType<Map<Object?, Object?>>()
      .map(
        (item) =>
            LearningLanguagePreference.fromJson(item.cast<String, Object?>()),
      )
      .toList(growable: false);
}

List<String> _boundedStrings(Object? value, int maxItems, int maxLength) {
  if (value is! List<Object?>) return const [];
  return value
      .whereType<String>()
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .take(maxItems)
      .map(
        (item) =>
            item.length <= maxLength ? item : item.substring(0, maxLength),
      )
      .toList(growable: false);
}

int _boundedInt(Object? value, int min, int max, int fallback) {
  return value is int ? value.clamp(min, max) : fallback;
}

String? _boundedOptionalString(String? value, int maxLength) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed.length <= maxLength
      ? trimmed
      : trimmed.substring(0, maxLength);
}

String? _trimmedOrNull(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

DateTime? _date(Object? value) {
  return value is String ? DateTime.tryParse(value)?.toLocal() : null;
}

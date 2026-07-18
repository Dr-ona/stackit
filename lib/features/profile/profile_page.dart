import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/auth_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/language_pair.dart';
import '../../models/user_profile.dart';
import '../vocabulary/vocabulary_controller.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.controller,
    required this.authService,
    this.isOnboarding = false,
  });

  final VocabularyController controller;
  final AuthService authService;
  final bool isOnboarding;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _none = '';
  static const _system = 'system';

  late final TextEditingController _displayName;
  late final TextEditingController _interests;
  late final TextEditingController _purposes;
  late final DateTime _createdAt;
  late DateTime _profileUpdatedAt;
  String? _avatarStoragePath;
  Uint8List? _avatarBytes;
  late String _nativeLanguageCode;
  late String _interfaceLanguageCode;
  late String _preferredTargetLanguageCode;
  late int _dailyReviewGoal;
  late ReviewIntensity _reviewIntensity;
  late bool _aiEnabled;
  late bool _notificationsEnabled;
  late bool _analyticsConsent;
  final Map<String, LearningLanguagePreference> _learningLanguages = {};
  bool _busy = false;
  bool _avatarBusy = false;

  @override
  void initState() {
    super.initState();
    final current = widget.controller.userProfile;
    final fallback = UserProfile.defaults(
      now: DateTime.now(),
      displayName: widget.authService.currentUser?.displayName,
      interfaceLanguageCode: widget.controller.interfaceLanguage?.code,
      preferredTargetLanguageCode:
          widget.controller.preferredTargetLanguage.code,
      notificationsEnabled: widget.controller.reviewRemindersEnabled,
    );
    final profile = current ?? fallback;
    _createdAt = profile.createdAt;
    _profileUpdatedAt = profile.updatedAt;
    _avatarStoragePath = profile.avatarStoragePath;
    _displayName = TextEditingController(text: profile.displayName);
    _interests = TextEditingController(text: profile.interests.join(', '));
    _purposes = TextEditingController(
      text: profile.learningPurposes.join(', '),
    );
    _nativeLanguageCode = _supportedOrEmpty(profile.nativeLanguageCode);
    _interfaceLanguageCode = profile.interfaceLanguageCode == null
        ? _system
        : _supportedOrSystem(profile.interfaceLanguageCode!);
    _preferredTargetLanguageCode =
        LanguagePair.availableTargets.any(
          (language) => language.code == profile.preferredTargetLanguageCode,
        )
        ? profile.preferredTargetLanguageCode
        : widget.controller.preferredTargetLanguage.code;
    _dailyReviewGoal = profile.dailyReviewGoal;
    _reviewIntensity = profile.reviewIntensity;
    _aiEnabled = profile.aiEnabled;
    _notificationsEnabled = widget.controller.reviewRemindersEnabled;
    _analyticsConsent = profile.analyticsConsent;
    for (final language in profile.learningLanguages) {
      if (VocabularyLanguage.tryFromCode(language.languageCode) != null) {
        _learningLanguages[language.languageCode] = language;
      }
    }
    if (_avatarStoragePath != null) _loadAvatar();
  }

  @override
  void dispose() {
    _displayName.dispose();
    _interests.dispose();
    _purposes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = widget.authService.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isOnboarding
              ? l10n.setUpLearningProfile
              : l10n.learningProfile,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
        children: [
          if (widget.isOnboarding) ...[
            _NoticeCard(text: l10n.onboardingProfileIntroduction),
            const SizedBox(height: 12),
          ],
          if (widget.controller.profileSyncError != null)
            _NoticeCard(text: l10n.profileSyncLocal),
          _identityCard(context),
          const SizedBox(height: 24),
          _sectionTitle(context, l10n.progress),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _metric(
                    context,
                    width,
                    widget.controller.entries.length,
                    l10n.collected,
                  ),
                  _metric(
                    context,
                    width,
                    widget.controller.reviewedCount,
                    l10n.reviewed,
                  ),
                  _metric(
                    context,
                    width,
                    widget.controller.masteredCount,
                    l10n.mastered,
                  ),
                  _metric(
                    context,
                    width,
                    widget.controller.dueCount,
                    l10n.dueNow,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          _sectionTitle(context, l10n.identity),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: TextField(
                controller: _displayName,
                maxLength: 80,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.displayName,
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _sectionTitle(context, l10n.languages),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _nativeLanguageCode,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l10n.nativeLanguage),
                    items: [
                      DropdownMenuItem(value: _none, child: Text(l10n.notSet)),
                      for (final language in VocabularyLanguage.values)
                        DropdownMenuItem(
                          value: language.code,
                          child: Text(language.nativeLabel),
                        ),
                    ],
                    onChanged: _busy
                        ? null
                        : (value) =>
                              setState(() => _nativeLanguageCode = value ?? _none),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _interfaceLanguageCode,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l10n.interfaceLanguage),
                    items: [
                      DropdownMenuItem(value: _system, child: Text(l10n.systemDefault)),
                      for (final language in VocabularyLanguage.values)
                        DropdownMenuItem(
                          value: language.code,
                          child: Text(language.nativeLabel),
                        ),
                    ],
                    onChanged: _busy
                        ? null
                        : (value) =>
                              setState(() => _interfaceLanguageCode = value ?? _system),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _preferredTargetLanguageCode,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l10n.translationPreference),
                    items: [
                      for (final language in LanguagePair.availableTargets)
                        DropdownMenuItem(
                          value: language.code,
                          child: Text(language.nativeLabel),
                        ),
                    ],
                    onChanged: _busy
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _preferredTargetLanguageCode = value);
                            }
                          },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.learningLanguages,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          for (final language in VocabularyLanguage.values)
            _learningLanguageTile(context, language),
          const SizedBox(height: 24),
          _sectionTitle(context, l10n.goalsAndPersonalization),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.dailyGoal(_dailyReviewGoal),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Slider(
                    value: _dailyReviewGoal.toDouble(),
                    min: 5,
                    max: 50,
                    divisions: 9,
                    label: _dailyReviewGoal.toString(),
                    onChanged: _busy
                        ? null
                        : (value) =>
                              setState(() => _dailyReviewGoal = value.round()),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  DropdownButtonFormField<ReviewIntensity>(
                    initialValue: _reviewIntensity,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l10n.reviewIntensity),
                    items: [
                      for (final intensity in ReviewIntensity.values)
                        DropdownMenuItem(
                          value: intensity,
                          child: Text(l10n.intensityLabel(intensity.storageValue)),
                        ),
                    ],
                    onChanged: _busy
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _reviewIntensity = value);
                            }
                          },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _interests,
                    maxLength: 720,
                    decoration: InputDecoration(
                      labelText: l10n.interests,
                      hintText: l10n.interestsHint,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _purposes,
                    maxLength: 640,
                    decoration: InputDecoration(
                      labelText: l10n.learningPurposes,
                      hintText: l10n.purposesHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle(context, l10n.privacyAndAssistance),
          const SizedBox(height: 6),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.auto_awesome_outlined),
                  title: Text(l10n.aiAssistance),
                  subtitle: Text(l10n.aiAssistanceDescription),
                  value: _aiEnabled,
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _aiEnabled = value),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: Text(l10n.dailyReminder),
                  subtitle: Text(l10n.reminderTime),
                  value: _notificationsEnabled,
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _notificationsEnabled = value),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.analytics_outlined),
                  title: Text(l10n.productAnalytics),
                  subtitle: Text(l10n.productAnalyticsDescription),
                  value: _analyticsConsent,
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _analyticsConsent = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _busy ? null : _save,
            icon: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(l10n.saveProfile),
          ),
          if (user == null) const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _identityCard(BuildContext context) {
    final l10n = context.l10n;
    final user = widget.authService.currentUser;
    final email = user?.email ?? '';
    final name = _displayName.text.trim();
    final initialSource = name.isNotEmpty ? name : email;
    final initial = initialSource.isEmpty
        ? 'S'
        : initialSource.characters.first;
    final created = user?.metadata.creationTime;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              button: true,
              label: l10n.changeProfilePhoto,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _busy || _avatarBusy ? null : _showAvatarActions,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: _avatarBytes == null
                          ? null
                          : MemoryImage(_avatarBytes!),
                      child: _avatarBusy
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : _avatarBytes == null
                          ? Text(
                              initial.toUpperCase(),
                              style: Theme.of(context).textTheme.headlineSmall,
                            )
                          : null,
                    ),
                    PositionedDirectional(
                      end: -3,
                      bottom: -3,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.camera_alt_outlined, size: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? l10n.learningProfile : name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(email, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Chip(
                        avatar: Icon(
                          user?.emailVerified == true
                              ? Icons.verified_outlined
                              : Icons.info_outline,
                          size: 17,
                        ),
                        label: Text(
                          user?.emailVerified == true
                              ? l10n.verified
                              : l10n.notVerified,
                        ),
                      ),
                      Chip(label: Text(l10n.freePlan)),
                    ],
                  ),
                  if (created != null)
                    Text(
                      l10n.memberSince(_dateLabel(created)),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  Text(
                    l10n.profileUpdated(_dateLabel(_profileUpdatedAt)),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadAvatar() async {
    setState(() => _avatarBusy = true);
    try {
      final bytes = await widget.controller.loadProfileAvatar();
      if (mounted) setState(() => _avatarBytes = bytes);
    } catch (_) {
      // The identity fallback remains available when the image is offline.
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  Future<void> _showAvatarActions() async {
    final action = await showModalBottomSheet<_AvatarAction>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(context.l10n.chooseProfilePhoto),
              onTap: () => Navigator.pop(context, _AvatarAction.choose),
            ),
            if (_avatarStoragePath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(context.l10n.removeProfilePhoto),
                onTap: () => Navigator.pop(context, _AvatarAction.remove),
              ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == _AvatarAction.remove) {
      await _removeAvatar();
    } else {
      await _chooseAvatar();
    }
  }

  Future<void> _chooseAvatar() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    if (image == null || !mounted) return;
    setState(() => _avatarBusy = true);
    try {
      final bytes = await image.readAsBytes();
      await widget.controller.uploadProfileAvatar(bytes);
      if (!mounted) return;
      setState(() {
        _avatarBytes = bytes;
        _avatarStoragePath = widget.controller.userProfile?.avatarStoragePath;
        _profileUpdatedAt =
            widget.controller.userProfile?.updatedAt ?? DateTime.now();
      });
      _showMessage(context.l10n.profilePhotoUpdated);
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  Future<void> _removeAvatar() async {
    setState(() => _avatarBusy = true);
    try {
      await widget.controller.removeProfileAvatar();
      if (!mounted) return;
      setState(() {
        _avatarBytes = null;
        _avatarStoragePath = null;
        _profileUpdatedAt =
            widget.controller.userProfile?.updatedAt ?? DateTime.now();
      });
      _showMessage(context.l10n.profilePhotoRemoved);
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _learningLanguageTile(
    BuildContext context,
    VocabularyLanguage language,
  ) {
    final preference = _learningLanguages[language.code];
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          CheckboxListTile(
            value: preference != null,
            title: Text(language.nativeLabel),
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: _busy
                ? null
                : (selected) {
                    setState(() {
                      if (selected == true) {
                        _learningLanguages[language.code] =
                            LearningLanguagePreference(
                              languageCode: language.code,
                              pronunciationLocale: language.localeTag,
                            );
                      } else {
                        _learningLanguages.remove(language.code);
                      }
                    });
                  },
          ),
          if (preference != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: DropdownButtonFormField<LanguageProficiency>(
                key: ValueKey(
                  '${language.code}-${preference.proficiency.name}',
                ),
                initialValue: preference.proficiency,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: context.l10n.proficiency,
                ),
                items: [
                  for (final level in LanguageProficiency.values)
                    DropdownMenuItem(
                      value: level,
                      child: Text(
                        context.l10n.proficiencyLabel(level.storageValue),
                      ),
                    ),
                ],
                onChanged: _busy
                    ? null
                    : (level) {
                        if (level != null) {
                          setState(() {
                            _learningLanguages[language.code] = preference
                                .copyWith(proficiency: level);
                          });
                        }
                      },
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
    );
  }

  Widget _metric(BuildContext context, double width, int value, String label) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      var remindersEnabled = _notificationsEnabled;
      if (remindersEnabled != widget.controller.reviewRemindersEnabled) {
        remindersEnabled = await widget.controller.setReviewReminders(
          remindersEnabled,
        );
      }
      final now = DateTime.now();
      final profile = UserProfile(
        displayName: _displayName.text,
        avatarStoragePath: _avatarStoragePath,
        nativeLanguageCode: _nativeLanguageCode == _none
            ? null
            : _nativeLanguageCode,
        interfaceLanguageCode: _interfaceLanguageCode == _system
            ? null
            : _interfaceLanguageCode,
        learningLanguages: _learningLanguages.values.toList(growable: false),
        preferredTargetLanguageCode: _preferredTargetLanguageCode,
        dailyReviewGoal: _dailyReviewGoal,
        reviewIntensity: _reviewIntensity,
        interests: _splitList(_interests.text),
        learningPurposes: _splitList(_purposes.text),
        aiEnabled: _aiEnabled,
        notificationsEnabled: remindersEnabled,
        analyticsConsent: _analyticsConsent,
        onboardingCompleted: true,
        createdAt: _createdAt,
        updatedAt: now,
      ).normalized();
      await widget.authService.updateDisplayName(profile.displayName);
      await widget.controller.updateUserProfile(profile);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.profileSaved)));
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<String> _splitList(String value) {
    return value
        .split(RegExp(r'[,،\n]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  String _supportedOrEmpty(String? code) {
    return VocabularyLanguage.tryFromCode(code) == null ? _none : code!;
  }

  String _supportedOrSystem(String code) {
    return VocabularyLanguage.tryFromCode(code) == null ? _system : code;
  }

  String _dateLabel(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}

enum _AvatarAction { choose, remove }

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.cloud_off_outlined),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}

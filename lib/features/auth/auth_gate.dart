import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/auth_service.dart';
import '../../l10n/app_localizations.dart';
import '../profile/profile_onboarding.dart';
import '../profile/profile_page.dart';
import '../vocabulary/vocabulary_controller.dart';
import '../vocabulary/vocabulary_home.dart';
import 'sign_in_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.authService,
    required this.controller,
  });

  final AuthService authService;
  final VocabularyController controller;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _lastUserId;
  bool _hasSeenAuthState = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: widget.authService.authStateChanges,
      initialData: widget.authService.currentUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        _handleAuthState(user);
        if (snapshot.data == null) {
          return SignInPage(authService: widget.authService);
        }
        return _SignedInExperience(
          key: ValueKey(user!.uid),
          controller: widget.controller,
          authService: widget.authService,
        );
      },
    );
  }

  void _handleAuthState(User? user) {
    final userId = user?.uid;
    if (_hasSeenAuthState && _lastUserId == userId) return;
    final previousUserId = _lastUserId;
    _lastUserId = userId;
    final wasInitialized = _hasSeenAuthState;
    _hasSeenAuthState = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (userId != null) {
        widget.controller.syncForUser(userId, displayName: user?.displayName);
      } else if (wasInitialized && previousUserId != null) {
        widget.controller.clearAfterSignOut();
      }
    });
  }
}

class _SignedInExperience extends StatefulWidget {
  const _SignedInExperience({
    super.key,
    required this.controller,
    required this.authService,
  });

  final VocabularyController controller;
  final AuthService authService;

  @override
  State<_SignedInExperience> createState() => _SignedInExperienceState();
}

class _SignedInExperienceState extends State<_SignedInExperience> {
  bool _offeredOnboarding = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _checkOnboarding();
  }

  @override
  void didUpdateWidget(covariant _SignedInExperience oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
      _checkOnboarding();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    _checkOnboarding();
  }

  void _checkOnboarding() {
    if (_offeredOnboarding || !mounted) return;
    final kind = profileOnboardingKind(
      profile: widget.controller.userProfile,
      controllerReady: widget.controller.isReady,
      vocabularySyncing: widget.controller.isSyncing,
      profileSyncing: widget.controller.isProfileSyncing,
      hasVocabulary: widget.controller.entries.isNotEmpty,
    );
    if (kind == ProfileOnboardingKind.none) return;
    _offeredOnboarding = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _offerOnboarding(kind);
    });
  }

  @override
  Widget build(BuildContext context) {
    return VocabularyHome(
      controller: widget.controller,
      authService: widget.authService,
    );
  }

  Future<void> _offerOnboarding(ProfileOnboardingKind kind) async {
    if (kind == ProfileOnboardingKind.migration) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(dialogContext.l10n.completeExistingProfileTitle),
          content: Text(dialogContext.l10n.existingProfileMigrationDescription),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(dialogContext.l10n.later),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(dialogContext.l10n.setUpNow),
            ),
          ],
        ),
      );
      if (accepted != true || !mounted) return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ProfilePage(
          controller: widget.controller,
          authService: widget.authService,
          isOnboarding: true,
        ),
      ),
    );
  }
}

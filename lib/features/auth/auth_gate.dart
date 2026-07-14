import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/auth_service.dart';
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
        final userId = snapshot.data?.uid;
        _handleAuthState(userId);
        if (snapshot.data == null) {
          return SignInPage(authService: widget.authService);
        }
        return VocabularyHome(
          controller: widget.controller,
          authService: widget.authService,
        );
      },
    );
  }

  void _handleAuthState(String? userId) {
    if (_hasSeenAuthState && _lastUserId == userId) return;
    final previousUserId = _lastUserId;
    _lastUserId = userId;
    final wasInitialized = _hasSeenAuthState;
    _hasSeenAuthState = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (userId != null) {
        widget.controller.syncForUser(userId);
      } else if (wasInitialized && previousUserId != null) {
        widget.controller.clearAfterSignOut();
      }
    });
  }
}

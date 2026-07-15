import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  User? get currentUser => _firebaseAuth.currentUser;

  Future<void> initialize() async {
    if (!kIsWeb) await GoogleSignIn.instance.initialize();
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.sendEmailVerification();
    return credential;
  }

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      return _firebaseAuth.signInWithPopup(GoogleAuthProvider());
    }

    final account = await GoogleSignIn.instance.authenticate();
    final authentication = account.authentication;
    final idToken = authentication.idToken;
    if (idToken == null) {
      throw const AuthFlowException(
        'Google did not return an identity token. Please try again.',
      );
    }
    return _firebaseAuth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  Future<void> sendPasswordReset(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    if (!kIsWeb) await GoogleSignIn.instance.signOut();
    await _firebaseAuth.signOut();
  }

  bool get requiresPasswordForReauthentication =>
      currentUser?.providerData.any(
        (provider) => provider.providerId == EmailAuthProvider.PROVIDER_ID,
      ) ??
      false;

  Future<void> reauthenticate({String? password}) async {
    final user = currentUser;
    if (user == null) throw const AuthFlowException('You are not signed in.');
    if (requiresPasswordForReauthentication) {
      final email = user.email;
      if (email == null || password == null || password.isEmpty) {
        throw const AuthFlowException(
          'Enter your current password to continue.',
        );
      }
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
      return;
    }
    if (!kIsWeb &&
        user.providerData.any(
          (provider) => provider.providerId == GoogleAuthProvider.PROVIDER_ID,
        )) {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthFlowException(
          'Google did not return an identity token.',
        );
      }
      await user.reauthenticateWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      return;
    }
    await user.reload();
  }

  Future<void> deleteCurrentUser() async {
    final user = currentUser;
    if (user == null) throw const AuthFlowException('You are not signed in.');
    await user.delete();
    if (!kIsWeb) await GoogleSignIn.instance.signOut();
  }
}

class AuthFlowException implements Exception {
  const AuthFlowException(this.message);

  final String message;

  @override
  String toString() => message;
}

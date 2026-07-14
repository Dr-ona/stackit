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
}

class AuthFlowException implements Exception {
  const AuthFlowException(this.message);

  final String message;

  @override
  String toString() => message;
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../data/auth_service.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key, required this.authService});

  final AuthService authService;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _createAccount = false;
  bool _busy = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _BrandMark(),
                  const SizedBox(height: 34),
                  Text(
                    _createAccount ? 'Create your account' : 'Welcome back',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _createAccount
                        ? 'Keep your vocabulary available across devices.'
                        : 'Sign in to open your vocabulary collection.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF657069),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.mail_outline_rounded),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty || !email.contains('@')) {
                              return 'Enter a valid email address.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password,
                          obscureText: _hidePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: _createAccount
                              ? const [AutofillHints.newPassword]
                              : const [AutofillHints.password],
                          onFieldSubmitted: (_) => _submitEmail(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _hidePassword = !_hidePassword,
                              ),
                              icon: Icon(
                                _hidePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if ((value?.length ?? 0) < 6) {
                              return 'Use at least 6 characters.';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFB3261E)),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _busy ? null : _submitEmail,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                    ),
                    child: _busy
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_createAccount ? 'Create account' : 'Sign in'),
                  ),
                  if (!_createAccount)
                    TextButton(
                      onPressed: _busy ? null : _resetPassword,
                      child: const Text('Forgot password?'),
                    ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Text('or'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _submitGoogle,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                    ),
                    icon: const Icon(Icons.account_circle_outlined),
                    label: const Text('Continue with Google'),
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _createAccount = !_createAccount;
                            _error = null;
                          }),
                    child: Text(
                      _createAccount
                          ? 'Already have an account? Sign in'
                          : 'New to Stackit? Create an account',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await _run(() async {
      if (_createAccount) {
        await widget.authService.createAccount(
          email: _email.text,
          password: _password.text,
        );
      } else {
        await widget.authService.signInWithEmail(
          email: _email.text,
          password: _password.text,
        );
      }
    });
  }

  Future<void> _submitGoogle() => _run(() async {
    await widget.authService.signInWithGoogle();
  });

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter your email first.');
      return;
    }
    await _run(() => widget.authService.sendPasswordReset(email));
    if (mounted && _error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _messageFor(error));
    } on GoogleSignInException catch (error) {
      if (mounted && error.code != GoogleSignInExceptionCode.canceled) {
        setState(() => _error = 'Google Sign-In failed. Please try again.');
      }
    } on AuthFlowException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _messageFor(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-credential' => 'The email or password is incorrect.',
      'email-already-in-use' => 'An account already uses this email.',
      'invalid-email' => 'Enter a valid email address.',
      'weak-password' => 'Choose a stronger password.',
      'network-request-failed' => 'Check your connection and try again.',
      'too-many-requests' => 'Too many attempts. Please wait and try again.',
      _ => error.message ?? 'Authentication failed. Please try again.',
    };
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF356859),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.layers_rounded, color: Colors.white),
        ),
        const SizedBox(width: 13),
        Text(
          'STACKIT',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xFF356859),
            fontWeight: FontWeight.w900,
            letterSpacing: 2.4,
          ),
        ),
      ],
    );
  }
}

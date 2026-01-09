import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'sign_up_page.dart';
import '../data/local_db.dart';

/// Email/password sign-in flow; on success seeds a local profile if missing.
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _resetting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFB388FF),
                    Color(0xFF7E57C2),
                    Color(0xFF5E35B1),
                    Color(0xFF311B92),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () => Navigator.of(context).maybePop(),
                              ),
                              const Spacer(),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: SizedBox(
                                  height: 110,
                                  width: 260,
                                  child: Image.asset(
                                    'lib/screens/assets/logo.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const Spacer(flex: 2),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Sign in',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 24),
                          _buildField(
                            label: 'Email',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            icon: Icons.email_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            label: 'Password',
                            controller: _passwordController,
                            obscure: _obscure,
                            icon: Icons.lock_outline,
                            suffix: IconButton(
                              icon: Icon(
                                _obscure ? Icons.visibility_off : Icons.visibility,
                                color: Colors.white70,
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _resetting ? null : _sendPasswordReset,
                              child: _resetting
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Forgot password?',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A148C),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _loading ? null : _signIn,
                              child: _loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text(
                                      'Sign in',
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account? ",
                                style: TextStyle(color: Colors.white70),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const SignUpPage()),
                                  );
                                },
                                child: const Text(
                                  'Register',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    bool obscure = false,
    TextInputType? keyboardType,
    IconData? icon,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, color: Colors.white70) : null,
            suffixIcon: suffix,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter email and password.');
      return;
    }

    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _ensureLocalProfile(cred.user);
      if (mounted) Navigator.of(context).maybePop();
    } on FirebaseAuthException catch (e) {
      _showMessage(_messageForCode(e.code));
    } catch (_) {
      _showMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Enter your email to receive a reset link.');
      return;
    }

    setState(() => _resetting = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showMessage('If an account exists, a reset link was sent.');
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          _showMessage('That email looks invalid.');
          break;
        case 'user-not-found':
          _showMessage('If an account exists, a reset link was sent.');
          break;
        case 'too-many-requests':
          _showMessage('Too many attempts. Try again later.');
          break;
        case 'network-request-failed':
          _showMessage('No network connection. Check your internet and try again.');
          break;
        default:
          _showMessage('Unable to send reset email right now.');
      }
    } catch (_) {
      _showMessage('Unable to send reset email right now.');
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  String _messageForCode(String code) {
    switch (code) {
      case 'invalid-email':
        return 'That email looks invalid.';
      case 'user-disabled':
        return 'This account is disabled.';
      case 'user-not-found':
      case 'wrong-password':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is disabled for this project.';
      case 'invalid-credential':
        return 'The email or password is incorrect.';
      case 'network-request-failed':
        return 'No network connection. Check your internet and try again.';
      default:
        return 'Unable to sign in right now.';
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _ensureLocalProfile(User? user) async {
    if (user == null) return;
    // If we sign in for the first time on this device, create a local profile row.
    final existing = await LocalDb.instance.getProfile(user.uid);
    if (existing != null) return;
    final profile = LocalProfile(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
      bio: null,
      photoUrl: user.photoURL,
      location: null,
      phone: null,
      website: null,
      updatedAt: DateTime.now(),
    );
    await LocalDb.instance.upsertProfile(profile);
  }
}

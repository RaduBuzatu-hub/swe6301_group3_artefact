/// Sign-in screen with email/password auth, reset flow, and local profile bootstrap.
/// - Validates inputs before calling Firebase.
/// - Supports password reset via email.
/// - Seeds a local profile row on first device sign-in.
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'sign_up_page.dart';
import '../data/local_db.dart';
import '../utils/auth_helpers.dart';

/// Email/password sign-in flow; on success seeds a local profile if missing.
/// Accepts an optional [auth] instance for tests.
class SignInPage extends StatefulWidget {
  final FirebaseAuth? auth;
  const SignInPage({super.key, this.auth});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  // Text controllers for the form fields; disposed in dispose().
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // Toggles password visibility.
  bool _obscure = true;
  // Track UI state for sign-in and password reset actions.
  AuthProcessState _signInState = const AuthProcessState.idle();
  AuthProcessState _resetState = const AuthProcessState.idle();

  // Allow dependency injection for testing; default to FirebaseAuth.instance.
  FirebaseAuth get _auth => widget.auth ?? FirebaseAuth.instance;

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
          // Gradient background behind the form.
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
                          // Top bar with back button and logo.
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
                          // Page title.
                          Text(
                            'Sign in',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 24),
                          // Email input field.
                          _buildField(
                            label: 'Email',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            icon: Icons.email_outlined,
                          ),
                          const SizedBox(height: 16),
                          // Password input with visibility toggle.
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
                              // Disable while a reset is in-flight.
                              onPressed: _resetState.isLoading ? null : _sendPasswordReset,
                              child: _resetState.isLoading
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
                          // Sign-in action button.
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
                              onPressed: _signInState.isLoading ? null : _signIn,
                              child: _signInState.isLoading
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
                          // Register link for users without an account.
                          Center(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                const Text(
                                  "Don't have an account?",
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
    // Shared form field styling with label and optional icons.
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
    // Read current form values.
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Validate inputs before attempting authentication.
    final validationMessage = AuthInputValidator.validateEmailAndPassword(
      email: email,
      password: password,
    );
    if (validationMessage != null) {
      if (mounted) {
        setState(() {
          _signInState = AuthProcessReducer.reduce(
            _signInState,
            AuthProcessEvent.failure(validationMessage),
          );
        });
      }
      _showMessage(validationMessage);
      return;
    }

    if (mounted) {
      // Update state to show loading feedback.
      setState(() {
        _signInState = AuthProcessReducer.reduce(
          _signInState,
          const AuthProcessEvent.start(),
        );
      });
    }
    try {
      // Attempt sign-in and seed a local profile for first-time device use.
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _ensureLocalProfile(cred.user);
      if (mounted) {
        // On success, update state and exit the screen.
        setState(() {
          _signInState = AuthProcessReducer.reduce(
            _signInState,
            const AuthProcessEvent.success(),
          );
        });
        Navigator.of(context).maybePop();
      }
    } on FirebaseAuthException catch (e) {
      final message = AuthErrorMapper.signInMessage(e.code);
      if (mounted) {
        // Show a friendly error message and update UI state.
        setState(() {
          _signInState = AuthProcessReducer.reduce(
            _signInState,
            AuthProcessEvent.failure(message),
          );
        });
      }
      _showMessage(message);
    } catch (_) {
      const message = 'Something went wrong. Please try again.';
      if (mounted) {
        // Handle unexpected errors.
        setState(() {
          _signInState = AuthProcessReducer.reduce(
            _signInState,
            const AuthProcessEvent.failure(message),
          );
        });
      }
      _showMessage(message);
    }
  }

  Future<void> _sendPasswordReset() async {
    // Read the email field for reset requests.
    final email = _emailController.text.trim();
    // Validate email before requesting a reset and update UI state for feedback.
    final validationMessage = AuthInputValidator.validateResetEmail(email);
    if (validationMessage != null) {
      if (mounted) {
        setState(() {
          _resetState = AuthProcessReducer.reduce(
            _resetState,
            AuthProcessEvent.failure(validationMessage),
          );
        });
      }
      _showMessage(validationMessage);
      return;
    }

    if (mounted) {
      // Set loading state while sending the reset email.
      setState(() {
        _resetState = AuthProcessReducer.reduce(
          _resetState,
          const AuthProcessEvent.start(),
        );
      });
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (mounted) {
        // Update state after a successful reset request.
        setState(() {
          _resetState = AuthProcessReducer.reduce(
            _resetState,
            const AuthProcessEvent.success(),
          );
        });
      }
      _showMessage('If an account exists, a reset link was sent.');
    } on FirebaseAuthException catch (e) {
      final message = AuthErrorMapper.resetMessage(e.code);
      if (mounted) {
        // Report Firebase-specific errors to the user.
        setState(() {
          _resetState = AuthProcessReducer.reduce(
            _resetState,
            AuthProcessEvent.failure(message),
          );
        });
      }
      _showMessage(message);
    } catch (_) {
      const message = 'Unable to send reset email right now.';
      if (mounted) {
        // Handle unexpected errors during reset.
        setState(() {
          _resetState = AuthProcessReducer.reduce(
            _resetState,
            const AuthProcessEvent.failure(message),
          );
        });
      }
      _showMessage(message);
    }
  }

  void _showMessage(String message) {
    // Surface feedback to the user via a snack bar.
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

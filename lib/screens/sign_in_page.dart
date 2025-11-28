import 'package:flutter/material.dart';
import 'sign_up_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

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
                                onPressed: () => Navigator.of(context).pop(),
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
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Signed in (mock)')),
                                );
                              },
                              child: const Text(
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
}

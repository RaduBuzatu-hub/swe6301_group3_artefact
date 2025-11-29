import 'package:flutter/material.dart';
import 'package:swe6301_group3_artefact/theme/app_styles.dart';

/// Landing panel shown when a feature requires authentication.
/// Exposes `onSignIn` and `onRegister` so host screens can route to auth flows.
class AuthRequiredPage extends StatelessWidget {
  final VoidCallback onSignIn;
  final VoidCallback onRegister;

  // Centralized copy and styling to keep layout and tests consistent.
  static const List<String> _benefits = [
    'Save trips and activities.',
    'See upcoming and past plans.',
    'Sync on this device after sign-in.',
  ];

  const AuthRequiredPage({
    super.key,
    required this.onSignIn,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppGradients.background,
      ),
      child: SafeArea(
        child: Padding(
          padding: AppSpacing.page,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _AuthPageHeader(),
              const SizedBox(height: 24),
              _AuthBenefitCard(
                benefits: _benefits,
                onSignIn: onSignIn,
                onRegister: onRegister,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Top copy for the auth gate screen.
class _AuthPageHeader extends StatelessWidget {
  const _AuthPageHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trips',
          key: const Key('authRequired.title'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          'Sign in to view and save your trips.',
          key: const Key('authRequired.subtitle'),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _AuthBenefitCard extends StatelessWidget {
  final List<String> benefits;
  final VoidCallback onSignIn;
  final VoidCallback onRegister;

  /// Benefit list + action buttons container; keys used heavily by widget tests.
  const _AuthBenefitCard({
    required this.benefits,
    required this.onSignIn,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('authRequired.benefitCard'),
      width: double.infinity,
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create an account or sign in to:',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          // Benefit list kept in one place so widget tests can assert copy/order easily.
          ...benefits.map(
            (benefit) => _BenefitRow(
              key: Key('authRequired.benefit.$benefit'),
              text: benefit,
            ),
          ),
          const SizedBox(height: 18),
          _AuthActions(
            onSignIn: onSignIn,
            onRegister: onRegister,
          ),
        ],
      ),
    );
  }
}

class _AuthActions extends StatelessWidget {
  final VoidCallback onSignIn;
  final VoidCallback onRegister;

  /// Primary CTA row: sign-in and register.
  const _AuthActions({
    required this.onSignIn,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            key: const Key('authRequired.signInButton'),
            style: AppButtons.primaryElevated(),
            onPressed: onSignIn,
            child: const Text(
              'Sign in',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            key: const Key('authRequired.registerButton'),
            style: AppButtons.primaryOutlined(),
            onPressed: onRegister,
            child: const Text(
              'Create account',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String text;
  const _BenefitRow({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.white70),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Unit tests for auth input validation, error mapping, and reducer states.
import 'package:flutter_test/flutter_test.dart';
import 'package:swe6301_group3_artefact/utils/auth_helpers.dart';

void main() {
  // Input validation rules for email/password and reset flow.
  group('AuthInputValidator', () {
    test('blocks empty email or password', () {
      final message = AuthInputValidator.validateEmailAndPassword(
        email: '',
        password: '',
      );

      expect(message, 'Please enter email and password.');
    });

    test('blocks invalid email', () {
      final message = AuthInputValidator.validateEmailAndPassword(
        email: 'not-an-email',
        password: 'password',
      );

      expect(message, 'That email looks invalid.');
    });

    test('blocks short password', () {
      final message = AuthInputValidator.validateEmailAndPassword(
        email: 'user@example.com',
        password: '123',
      );

      expect(message, 'Password should be stronger (min 6 characters).');
    });

    test('accepts valid credentials', () {
      final message = AuthInputValidator.validateEmailAndPassword(
        email: 'user@example.com',
        password: 'password',
      );

      expect(message, isNull);
    });

    test('validates reset email', () {
      final emptyMessage = AuthInputValidator.validateResetEmail('');
      final invalidMessage = AuthInputValidator.validateResetEmail('invalid');
      final validMessage = AuthInputValidator.validateResetEmail('user@example.com');

      expect(emptyMessage, 'Enter your email to receive a reset link.');
      expect(invalidMessage, 'That email looks invalid.');
      expect(validMessage, isNull);
    });
  });

  // Error code mapping to human-friendly messages.
  group('AuthErrorMapper', () {
    test('maps sign-in error codes', () {
      expect(AuthErrorMapper.signInMessage('invalid-email'), 'That email looks invalid.');
      expect(AuthErrorMapper.signInMessage('wrong-password'), 'Incorrect email or password.');
      expect(
        AuthErrorMapper.signInMessage('network-request-failed'),
        'No network connection. Check your internet and try again.',
      );
      expect(AuthErrorMapper.signInMessage('unknown'), 'Unable to sign in right now.');
    });

    test('maps sign-up error codes', () {
      expect(
        AuthErrorMapper.signUpMessage('email-already-in-use'),
        'An account already exists for that email.',
      );
      expect(
        AuthErrorMapper.signUpMessage('weak-password'),
        'Password should be stronger (min 6 characters).',
      );
      expect(AuthErrorMapper.signUpMessage('unknown'), 'Unable to create account right now.');
    });

    test('maps reset error codes', () {
      expect(AuthErrorMapper.resetMessage('invalid-email'), 'That email looks invalid.');
      expect(
        AuthErrorMapper.resetMessage('too-many-requests'),
        'Too many attempts. Try again later.',
      );
      expect(
        AuthErrorMapper.resetMessage('user-not-found'),
        'If an account exists, a reset link was sent.',
      );
      expect(AuthErrorMapper.resetMessage('unknown'), 'Unable to send reset email right now.');
    });
  });

  // Reducer transitions for loading/success/error/reset states.
  group('AuthProcessReducer', () {
    test('transitions through loading, success, error, and reset', () {
      // Exercise state transitions to ensure flags and messages are consistent.
      const idle = AuthProcessState.idle();

      final loading = AuthProcessReducer.reduce(
        idle,
        const AuthProcessEvent.start(),
      );
      expect(loading.status, AuthProcessStatus.loading);
      expect(loading.isLoading, isTrue);

      final success = AuthProcessReducer.reduce(
        loading,
        const AuthProcessEvent.success(),
      );
      expect(success.status, AuthProcessStatus.success);
      expect(success.isLoading, isFalse);

      final failure = AuthProcessReducer.reduce(
        success,
        const AuthProcessEvent.failure('Something failed'),
      );
      expect(failure.status, AuthProcessStatus.error);
      expect(failure.message, 'Something failed');

      final reset = AuthProcessReducer.reduce(
        failure,
        const AuthProcessEvent.reset(),
      );
      expect(reset.status, AuthProcessStatus.idle);
    });
  });
}

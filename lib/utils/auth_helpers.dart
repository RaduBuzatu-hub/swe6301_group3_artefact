/// Helpers for auth form validation, error mapping, and UI state transitions.

/// Validates auth form inputs and returns user-friendly messages.
class AuthInputValidator {
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? validateEmailAndPassword({
    required String email,
    required String password,
  }) {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.isEmpty) {
      return 'Please enter email and password.';
    }
    if (!_emailRegex.hasMatch(trimmedEmail)) {
      return 'That email looks invalid.';
    }
    if (password.length < 6) {
      return 'Password should be stronger (min 6 characters).';
    }
    return null;
  }

  static String? validateResetEmail(String email) {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      return 'Enter your email to receive a reset link.';
    }
    if (!_emailRegex.hasMatch(trimmedEmail)) {
      return 'That email looks invalid.';
    }
    return null;
  }
}

/// Maps Firebase auth error codes to strings shown in the UI.
class AuthErrorMapper {
  static String signInMessage(String code) {
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

  static String signUpMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'That email looks invalid.';
      case 'weak-password':
        return 'Password should be stronger (min 6 characters).';
      default:
        return 'Unable to create account right now.';
    }
  }

  static String resetMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'That email looks invalid.';
      case 'user-not-found':
        return 'If an account exists, a reset link was sent.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'No network connection. Check your internet and try again.';
      default:
        return 'Unable to send reset email right now.';
    }
  }
}

/// Status values for auth-related UI operations.
enum AuthProcessStatus { idle, loading, success, error }

/// Immutable container for a single auth operation state.
class AuthProcessState {
  final AuthProcessStatus status;
  final String? message;

  const AuthProcessState({required this.status, this.message});

  const AuthProcessState.idle()
      : status = AuthProcessStatus.idle,
        message = null;

  bool get isLoading => status == AuthProcessStatus.loading;
}

/// Events used to drive auth state transitions.
enum AuthProcessEventType { start, success, failure, reset }

/// Event payload for updating auth process state.
class AuthProcessEvent {
  final AuthProcessEventType type;
  final String? message;

  const AuthProcessEvent._(this.type, this.message);

  const AuthProcessEvent.start() : this._(AuthProcessEventType.start, null);
  const AuthProcessEvent.success() : this._(AuthProcessEventType.success, null);
  const AuthProcessEvent.failure(String message)
      : this._(AuthProcessEventType.failure, message);
  const AuthProcessEvent.reset() : this._(AuthProcessEventType.reset, null);
}

/// Pure reducer that applies an [AuthProcessEvent] to an [AuthProcessState].
class AuthProcessReducer {
  static AuthProcessState reduce(AuthProcessState state, AuthProcessEvent event) {
    switch (event.type) {
      case AuthProcessEventType.start:
        return const AuthProcessState(status: AuthProcessStatus.loading);
      case AuthProcessEventType.success:
        return const AuthProcessState(status: AuthProcessStatus.success);
      case AuthProcessEventType.failure:
        return AuthProcessState(status: AuthProcessStatus.error, message: event.message);
      case AuthProcessEventType.reset:
        return const AuthProcessState(status: AuthProcessStatus.idle);
    }
  }
}

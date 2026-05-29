import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────
// StateProvider — replaces setState for isLoading
// Used by: LoginScreen, SignupScreen
// ─────────────────────────────────────────────
final isLoadingProvider = StateProvider<bool>((ref) => false);

// ─────────────────────────────────────────────
// AuthState — holds logged-in user data in memory
// Replaces: reading SharedPreferences on every screen
// ─────────────────────────────────────────────
class AuthState {
  final String? token;
  final String? userName;
  final String? userEmail;
  final String? profilePicture;
  final bool isLoggedIn;

  const AuthState({
    this.token,
    this.userName,
    this.userEmail,
    this.profilePicture,
    this.isLoggedIn = false,
  });

  // copyWith: update one field, keep the rest unchanged
  AuthState copyWith({
    String? token,
    String? userName,
    String? userEmail,
    String? profilePicture,
    bool? isLoggedIn,
  }) {
    return AuthState(
      token:          token          ?? this.token,
      userName:       userName       ?? this.userName,
      userEmail:      userEmail      ?? this.userEmail,
      profilePicture: profilePicture ?? this.profilePicture,
      isLoggedIn:     isLoggedIn     ?? this.isLoggedIn,
    );
  }
}

// ─────────────────────────────────────────────
// AuthNotifier — all logic that changes AuthState
// ─────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()); // starts as logged out

  void login({
    required String token,
    required String userName,
    required String userEmail,
    String? profilePicture,
  }) {
    state = state.copyWith(
      token:          token,
      userName:       userName,
      userEmail:      userEmail,
      profilePicture: profilePicture,
      isLoggedIn:     true,
    );
  }

  void logout() {
    state = const AuthState(); // reset everything to empty
  }

  void updateProfilePicture(String path) {
    state = state.copyWith(profilePicture: path);
  }

  void updateName(String name) {
    state = state.copyWith(userName: name);
  }

  void clearProfilePicture() {
    state = state.copyWith(profilePicture: '');
  }

  // Called on app start to restore session from SharedPreferences
  void restoreSession({
    required String token,
    required String userName,
    required String userEmail,
    String? profilePicture,
  }) {
    state = AuthState(
      token:          token,
      userName:       userName,
      userEmail:      userEmail,
      profilePicture: profilePicture,
      isLoggedIn:     true,
    );
  }
}

// ─────────────────────────────────────────────
// The provider — exposes AuthNotifier to the app
// ─────────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
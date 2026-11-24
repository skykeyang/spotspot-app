import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseProvider).auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(supabaseProvider).auth.currentUser;
});

final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

class AuthNotifier extends Notifier<User?> {
  @override
  User? build() {
    return ref.read(supabaseProvider).auth.currentUser;
  }

  Future<void> signInWithGoogle() async {
    await ref.read(supabaseProvider).auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb
          ? null
          : 'io.supabase.flutter://login-callback/',
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.platformDefault,
    );
  }

  Future<void> signOut() async {
    await ref.read(supabaseProvider).auth.signOut();
    state = null;
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, User?>(AuthNotifier.new);
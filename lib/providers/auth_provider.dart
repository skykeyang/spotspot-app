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

// Auth loading state
class AuthLoadingNotifier extends Notifier<bool> {
  @override
  bool build() {
    // Clear loading whenever auth state changes
    ref.listen(authStateProvider, (_, __) {
      state = false;
    });
    return false;
  }
  void start() => state = true;
  void stop() => state = false;
}
final authLoadingProvider = NotifierProvider<AuthLoadingNotifier, bool>(AuthLoadingNotifier.new);

class AuthNotifier extends Notifier<User?> {
  @override
  User? build() {
    // Refresh user when auth state changes
    ref.watch(authStateProvider);
    return ref.read(supabaseProvider).auth.currentUser;
  }

  Future<void> signInWithGoogle() async {
    ref.read(authLoadingProvider.notifier).start();
    try {
      await ref.read(supabaseProvider).auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.flutter://login-callback/',
        authScreenLaunchMode: LaunchMode.platformDefault,
      );
    } catch (e) {
      ref.read(authLoadingProvider.notifier).stop();
      rethrow;
    }
  }

  Future<void> signOut() async {
    await ref.read(supabaseProvider).auth.signOut();
    state = null;
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, User?>(AuthNotifier.new);
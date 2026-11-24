import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String? _error;

  Future<void> _signIn() async {
    setState(() => _error = null);
    try {
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();
      // Loading state will be cleared by auth state change
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authLoadingProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Text(
                'SPOTSPOT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'SG Bingo',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Text(
                'Spot it. Snap it. Win it.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 40),

              // Feature row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _feature(context, '🎯', 'Spot moments'),
                  const SizedBox(width: 24),
                  _feature(context, '📸', 'Snap proof'),
                  const SizedBox(width: 24),
                  _feature(context, '🏆', 'Win bingo'),
                ],
              ),
              const SizedBox(height: 40),

              // Sign in button
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.error),
                  ),
                ),

              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: isLoading ? null : _signIn,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(width: 10),
                            Text('Opening Google sign in...',
                              style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _googleIcon(),
                            const SizedBox(width: 10),
                            const Text('Continue with Google', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                          ],
                        ),
                ),
              ),

              if (isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'Complete the sign in your browser, then you\'ll be redirected back.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feature(BuildContext context, String emoji, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _googleIcon() {
    return Image.network(
      'https://www.google.com/favicon.ico',
      width: 18, height: 18,
      errorBuilder: (_, __, ___) => const Icon(Icons.login, size: 18),
    );
  }
}
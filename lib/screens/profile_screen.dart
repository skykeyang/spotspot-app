import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider);
    final theme = Theme.of(context);
    final email = user?.email ?? 'Unknown';
    final initials = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Avatar
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(initials, style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            ),
          ),
          const SizedBox(height: 16),

          // Email
          Center(child: Text(email, style: theme.textTheme.bodyLarge)),
          const SizedBox(height: 32),

          // Settings section
          Text('Settings', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          _settingsTile(Icons.notifications_outlined, 'Notifications', () {}),
          _settingsTile(Icons.privacy_tip_outlined, 'Privacy', () {}),
          _settingsTile(Icons.help_outline, 'Help', () {}),
          _settingsTile(Icons.info_outline, 'About', () {}),

          const SizedBox(height: 24),

          // Sign out
          Center(
            child: OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authNotifierProvider.notifier).signOut();
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      onTap: onTap,
    );
  }
}
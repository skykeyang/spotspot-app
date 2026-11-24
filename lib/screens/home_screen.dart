import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bingo.dart';
import '../services/pools.dart';
import '../providers/auth_provider.dart';
import 'main_shell.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider);
    final theme = Theme.of(context);
    final featuredPool = activePools.where((p) => p.type == 'featured').firstOrNull ?? activePools.first;
    final secondaryPools = activePools.where((p) => p.type != 'featured').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SpotSpot'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Greeting
          Text(
            'Hey, ${user?.email?.split('@').first ?? 'there'} 👋',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Pick a board and start spotting.',
            style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),

          // How to play
          _howToPlay(context),
          const SizedBox(height: 24),

          // Pick your board
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('PICK YOUR BOARD',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: theme.colorScheme.onSurfaceVariant)),
          ),

          // Featured
          _poolCard(context, featuredPool, true),
          const SizedBox(height: 12),

          // Secondary
          ...secondaryPools.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _poolCard(context, p, false),
          )),

          const SizedBox(height: 24),

          // Quick actions
          Row(
            children: [
              Expanded(child: FilledButton.icon(
                onPressed: () => ref.read(currentTabIndexProvider.notifier).set(1),
                icon: const Icon(Icons.group, size: 18),
                label: const Text('My Groups'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _howToPlay(BuildContext context) {
    final theme = Theme.of(context);
    final steps = [
      ('1', 'Generate a bingo board — 24 challenges to spot'),
      ('2', 'When something matches, snap a photo to check it off'),
      ('3', 'Complete a row, column, or diagonal to Bingo!'),
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HOW TO PLAY', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 16),
          ...steps.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                CircleAvatar(radius: 11, backgroundColor: theme.colorScheme.primary,
                  child: Text(s.$1, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
                const SizedBox(width: 10),
                Expanded(child: Text(s.$2, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant, height: 1.5))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _poolCard(BuildContext context, BingoPool pool, bool featured) {
    final theme = Theme.of(context);
    final color = hexToColor(pool.color);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.12), color.withOpacity(0.04)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(featured ? 0.4 : 0.2), width: featured ? 2 : 1),
      ),
      child: Row(
        children: [
          Text(pool.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pool.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                Text(pool.tagline, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(pool.description, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: color),
        ],
      ),
    );
  }
}
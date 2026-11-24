import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/bingo.dart';
import '../services/pools.dart';
import '../providers/auth_provider.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider);
    final featuredPool = activePools.where((p) => p.type == 'featured').firstOrNull ?? activePools.first;
    final secondaryPools = activePools.where((p) => p.type != 'featured').toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
          children: [
            // Hero
            Center(
              child: Column(
                children: [
                  Text(
                    'SPOTSPOT',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Spot it. Snap it. Win it.',
                    style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text('Complete real-life challenges by snapping photos. Get a row, column, or diagonal to Bingo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7), height: 1.6)),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // How to Play
            _buildHowToPlay(context),
            const SizedBox(height: 32),

            // Pick your board
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text('PICK YOUR BOARD',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),

            // Featured pool
            _buildPoolCard(context, featuredPool, true),
            const SizedBox(height: 16),

            // Secondary pools
            if (secondaryPools.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('MORE BOARDS',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
              ...secondaryPools.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPoolCard(context, p, false),
              )),
            ],

            const SizedBox(height: 24),

            // Actions
            OutlinedButton(
              onPressed: () => context.go('/groups'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('My Groups'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/profile'),
              child: Text(user?.email ?? 'Profile',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowToPlay(BuildContext context) {
    final steps = [
      ('1', 'Generate a bingo board — 24 challenges to spot'),
      ('2', 'When something matches, snap a photo to check it off'),
      ('3', 'Complete a row, column, or diagonal to Bingo!'),
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HOW TO PLAY', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 16),
          ...steps.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                CircleAvatar(radius: 12, backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(s.$1, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                const SizedBox(width: 12),
                Expanded(child: Text(s.$2, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPoolCard(BuildContext context, BingoPool pool, bool featured) {
    final color = hexToColor(pool.color);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.1), color.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: featured ? 2 : 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Text(pool.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pool.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(pool.tagline, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text(pool.description, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
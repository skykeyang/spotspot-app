import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/bingo.dart';
import '../services/pools.dart';
import '../services/group_service.dart';
import '../providers/auth_provider.dart';
import 'main_shell.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _generating = false;

  @override
  Widget build(BuildContext context) {
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

          // Featured — tappable, generates board and goes to groups
          _poolCard(context, featuredPool, true),
          const SizedBox(height: 12),

          // Secondary pools
          ...secondaryPools.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _poolCard(context, p, false),
          )),

          const SizedBox(height: 24),

          // Group actions — prominent
          Text('GROUPS',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),

          // Create group button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _showCreateDialog(context),
              icon: const Icon(Icons.add_circle, size: 20),
              label: const Text('Create New Group'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
          const SizedBox(height: 10),

          // Join group button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showJoinDialog(context),
              icon: const Icon(Icons.group_add, size: 20),
              label: const Text('Join with Invite Code'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
          const SizedBox(height: 12),

          // My groups
          TextButton.icon(
            onPressed: () => ref.read(currentTabIndexProvider.notifier).set(1),
            icon: const Icon(Icons.groups, size: 18),
            label: const Text('View My Groups →'),
          ),
        ],
      ),
    );
  }

  Widget _howToPlay(BuildContext context) {
    final theme = Theme.of(context);
    final steps = [
      ('1', 'Pick a board theme below'),
      ('2', 'Create a group or join one with an invite code'),
      ('3', 'Tap squares to check them off — snap photos as proof!'),
      ('4', 'Complete a row, column, or diagonal to Bingo!'),
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
    return InkWell(
      onTap: _generating ? null : () => _onPoolTap(pool),
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
            _generating
                ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: color))
                : Icon(Icons.arrow_forward, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  void _onPoolTap(BingoPool pool) async {
    setState(() => _generating = true);
    final user = ref.read(authNotifierProvider);
    if (user == null) return;

    // Check if user already has a group with this pool
    try {
      final groups = await ref.read(groupServiceProvider).getUserGroups(user.id);
      // Find or create a solo group for this pool
      // For now, just switch to groups tab so they can create/join
      ref.read(currentTabIndexProvider.notifier).set(1);
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _showCreateDialog(BuildContext context) {
    final pools = activePools;
    showDialog(context: context, builder: (context) => _CreateDialog(
      pools: pools,
      onCreate: (name, poolId) async {
        final user = ref.read(authNotifierProvider);
        if (user == null) return;
        await ref.read(groupServiceProvider).createGroup(
          userId: user.id, name: name, poolId: poolId,
        );
        ref.invalidate(userGroupsProvider(user.id));
        if (context.mounted) Navigator.pop(context);
        ref.read(currentTabIndexProvider.notifier).set(1);
      },
    ));
  }

  void _showJoinDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => _JoinDialog(
      onJoin: (code) async {
        final user = ref.read(authNotifierProvider);
        if (user == null) return;
        await ref.read(groupServiceProvider).joinGroup(user.id, code);
        ref.invalidate(userGroupsProvider(user.id));
        if (context.mounted) Navigator.pop(context);
        ref.read(currentTabIndexProvider.notifier).set(1);
      },
    ));
  }
}

// Providers needed by this screen
final userGroupsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  return ref.read(groupServiceProvider).getUserGroups(userId);
});

class _CreateDialog extends StatefulWidget {
  final List<BingoPool> pools;
  final Future<void> Function(String name, String poolId) onCreate;
  const _CreateDialog({required this.pools, required this.onCreate});
  @override
  State<_CreateDialog> createState() => _CreateDialogState();
}

class _CreateDialogState extends State<_CreateDialog> {
  final _ctrl = TextEditingController();
  String _selectedPoolId = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedPoolId = widget.pools.first.id;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Group'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _ctrl, decoration: const InputDecoration(hintText: 'Group name (e.g. My Pickleball Kaki)'), autofocus: true),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedPoolId,
            decoration: const InputDecoration(hintText: 'Board theme'),
            items: widget.pools.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.emoji} ${p.name}'))).toList(),
            onChanged: (v) => setState(() => _selectedPoolId = v ?? widget.pools.first.id),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: _loading ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _loading ? null : () async {
            if (_ctrl.text.trim().isEmpty) return;
            setState(() => _loading = true);
            try { await widget.onCreate(_ctrl.text.trim(), _selectedPoolId); }
            catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
            if (mounted) setState(() => _loading = false);
          },
          child: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create'),
        ),
      ],
    );
  }
}

class _JoinDialog extends StatefulWidget {
  final Future<void> Function(String code) onJoin;
  const _JoinDialog({required this.onJoin});
  @override
  State<_JoinDialog> createState() => _JoinDialogState();
}

class _JoinDialogState extends State<_JoinDialog> {
  final _ctrl = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Join Group'),
      content: TextField(
        controller: _ctrl,
        decoration: const InputDecoration(hintText: 'Enter 6-character invite code'),
        autofocus: true,
        textCapitalization: TextCapitalization.characters,
      ),
      actions: [
        TextButton(onPressed: _loading ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _loading ? null : () async {
            if (_ctrl.text.trim().isEmpty) return;
            setState(() => _loading = true);
            try { await widget.onJoin(_ctrl.text.trim()); }
            catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
            if (mounted) setState(() => _loading = false);
          },
          child: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Join'),
        ),
      ],
    );
  }
}
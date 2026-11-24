import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/bingo.dart';
import '../services/pools.dart';
import '../services/group_service.dart';
import '../providers/auth_provider.dart';
import 'main_shell.dart';

final userGroupsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  return ref.read(groupServiceProvider).getUserGroups(userId);
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _busyPoolId;

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
      body: RefreshIndicator(
        onRefresh: () async {
          if (user != null) ref.invalidate(userGroupsProvider(user.id));
        },
        child: ListView(
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

          // Featured pool
          _poolCard(context, featuredPool, true),
          const SizedBox(height: 12),

          // Secondary pools
          ...secondaryPools.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _poolCard(context, p, false),
          )),

          const SizedBox(height: 24),

          // Groups section
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('GROUPS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: theme.colorScheme.onSurfaceVariant)),
          ),

          // Create + Join buttons side by side
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _showCreateDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create'),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showJoinDialog(context),
                  icon: const Icon(Icons.group_add, size: 18),
                  label: const Text('Join'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
            ],
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
      ),
    );
  }

  Widget _howToPlay(BuildContext context) {
    final theme = Theme.of(context);
    final steps = [
      ('1', 'Pick a board theme below'),
      ('2', 'Create a group or join with an invite code'),
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
    final isBusy = _busyPoolId == pool.id;

    return InkWell(
      onTap: isBusy ? null : () => _onPoolTap(pool),
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
                  const SizedBox(height: 6),
                  Text('${pool.events.where((e) => e.active).length} challenges',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color)),
                ],
              ),
            ),
            if (isBusy)
              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            else
              Icon(Icons.play_circle_fill, color: color, size: 28),
          ],
        ),
      ),
    );
  }

  void _onPoolTap(BingoPool pool) async {
    final user = ref.read(authNotifierProvider);
    if (user == null) return;

    setState(() => _busyPoolId = pool.id);

    try {
      final service = ref.read(groupServiceProvider);
      final groups = await service.getUserGroups(user.id);

      // Look for existing group with this pool
      String? groupId;
      for (final g in groups) {
        final gPoolId = g['pool_id'] as String?;
        if (gPoolId == pool.id) {
          groupId = g['group_id'] as String?;
          break;
        }
      }

      if (groupId == null) {
        // Create a new group with this pool
        final group = await service.createGroup(
          userId: user.id,
          name: '${pool.name} Board',
          poolId: pool.id,
        );
        groupId = group.id;
      }

      // Ensure board exists
      final board = await service.getBoard(user.id, groupId);
      if (board == null) {
        await service.createBoard(user.id, groupId, pool.id);
      }

      if (user != null) ref.invalidate(userGroupsProvider(user.id));

      // Navigate to the group detail
      if (mounted) {
        context.push('/groups/$groupId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _busyPoolId = null);
    }
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => _CreateDialog(
      pools: activePools,
      defaultPool: activePools.first,
      onCreate: (name, poolId) async {
        final user = ref.read(authNotifierProvider);
        if (user == null) return;
        final group = await ref.read(groupServiceProvider).createGroup(
          userId: user.id, name: name, poolId: poolId,
        );
        // Create board too
        await ref.read(groupServiceProvider).createBoard(user.id, group.id, poolId);
        ref.invalidate(userGroupsProvider(user.id));
        if (context.mounted) Navigator.pop(context);
        // Navigate to the new group
        context.push('/groups/${group.id}');
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

class _CreateDialog extends StatefulWidget {
  final List<BingoPool> pools;
  final BingoPool defaultPool;
  final Future<void> Function(String name, String poolId) onCreate;
  const _CreateDialog({required this.pools, required this.defaultPool, required this.onCreate});

  @override
  State<_CreateDialog> createState() => _CreateDialogState();
}

class _CreateDialogState extends State<_CreateDialog> {
  final _ctrl = TextEditingController();
  late String _selectedPoolId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedPoolId = widget.defaultPool.id;
  }

  BingoPool get _selectedPool => widget.pools.firstWhere((p) => p.id == _selectedPoolId);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final poolColor = hexToColor(_selectedPool.color);

    return AlertDialog(
      title: const Text('Create New Group'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group name
          TextField(
            controller: _ctrl,
            decoration: const InputDecoration(
              hintText: 'Group name (e.g. My Pickleball Kaki)',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 20),

          // Board theme label
          Text('BOARD THEME',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),

          // Pool selection — visual cards
          Row(
            children: widget.pools.map((p) {
              final selected = p.id == _selectedPoolId;
              final c = hexToColor(p.color);
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPoolId = p.id),
                  child: Container(
                    margin: EdgeInsets.only(right: p.id != widget.pools.last.id ? 8 : 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selected ? c.withOpacity(0.1) : theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? c : theme.dividerColor,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(p.emoji, style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 4),
                        Text(p.name, style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          color: selected ? c : theme.colorScheme.onSurfaceVariant,
                        )),
                        const SizedBox(height: 2),
                        Text('${p.events.where((e) => e.active).length} challenges',
                          style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6))),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // Selected pool preview
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: poolColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: poolColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Text(_selectedPool.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(child: Text(_selectedPool.description,
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant))),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: _loading ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _loading ? null : () async {
            if (_ctrl.text.trim().isEmpty) return;
            setState(() => _loading = true);
            try {
              await widget.onCreate(_ctrl.text.trim(), _selectedPoolId);
            } catch (e) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
            }
            if (mounted) setState(() => _loading = false);
          },
          child: _loading
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Create & Play'),
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
        decoration: const InputDecoration(
          hintText: 'Enter 6-character invite code',
          border: OutlineInputBorder(),
        ),
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
          child: _loading
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Join'),
        ),
      ],
    );
  }
}
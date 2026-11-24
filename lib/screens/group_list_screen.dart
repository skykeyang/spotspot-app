import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/group_service.dart';
import '../providers/auth_provider.dart';

final userGroupsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final service = ref.read(groupServiceProvider);
  return service.getUserGroups(userId);
});

class GroupListScreen extends ConsumerStatefulWidget {
  const GroupListScreen({super.key});

  @override
  ConsumerState<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends ConsumerState<GroupListScreen> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    final user = ref.read(authNotifierProvider);
    if (user != null) {
      ref.invalidate(userGroupsProvider(user.id));
      setState(() => _userId = user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final groupsAsync = ref.watch(userGroupsProvider(_userId!));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Groups'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (groups) {
          if (groups.isEmpty) {
            return _buildEmpty(context);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (context, i) => _buildGroupCard(context, groups[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Group'),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.groups, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No groups yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Create a group or join with an invite code',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showCreateDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Group'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _showJoinDialog(context),
              icon: const Icon(Icons.group_add),
              label: const Text('Join with Code'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, Map<String, dynamic> group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(group['group_name']?.substring(0, 1).toUpperCase() ?? '?'),
        ),
        title: Text(group['group_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${group['member_count'] ?? 0} members • ${group['completion_count'] ?? 0}/${group['total_squares'] ?? 24} completed'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go('/groups/${group['group_id']}'),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => _CreateGroupDialog(
      onCreate: (name) async {
        final user = ref.read(authNotifierProvider);
        if (user == null) return;
        await ref.read(groupServiceProvider).createGroup(
          userId: user.id,
          name: name,
          poolId: 'sg-life-2026-w16',
        );
        _refresh();
        if (context.mounted) Navigator.pop(context);
      },
    ));
  }

  void _showJoinDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => _JoinGroupDialog(
      onJoin: (code) async {
        final user = ref.read(authNotifierProvider);
        if (user == null) return;
        try {
          await ref.read(groupServiceProvider).joinGroup(user.id, code);
          _refresh();
          if (context.mounted) Navigator.pop(context);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
          }
        }
      },
    ));
  }
}

class _CreateGroupDialog extends StatefulWidget {
  final Future<void> Function(String name) onCreate;
  const _CreateGroupDialog({required this.onCreate});

  @override
  State<_CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<_CreateGroupDialog> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Group'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(hintText: 'Group name'),
        autofocus: true,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _loading ? null : () async {
            setState(() => _loading = true);
            await widget.onCreate(_controller.text.trim());
            if (mounted) setState(() => _loading = false);
          },
          child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create'),
        ),
      ],
    );
  }
}

class _JoinGroupDialog extends StatefulWidget {
  final Future<void> Function(String code) onJoin;
  const _JoinGroupDialog({required this.onJoin});

  @override
  State<_JoinGroupDialog> createState() => _JoinGroupDialogState();
}

class _JoinGroupDialogState extends State<_JoinGroupDialog> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Join Group'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(hintText: 'Invite code'),
        autofocus: true,
        textCapitalization: TextCapitalization.characters,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _loading ? null : () async {
            setState(() => _loading = true);
            await widget.onJoin(_controller.text.trim());
            if (mounted) setState(() => _loading = false);
          },
          child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Join'),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/group_service.dart';
import '../providers/auth_provider.dart';

final userGroupsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final service = ref.read(groupServiceProvider);
  return service.getUserGroups(userId);
});

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  void _refresh() {
    final user = ref.read(authNotifierProvider);
    if (user != null) ref.invalidate(userGroupsProvider(user.id));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider);
    final theme = Theme.of(context);

    if (user == null) {
      return Scaffold(appBar: AppBar(title: const Text('Groups')), body: const Center(child: Text('Not signed in')));
    }

    final groupsAsync = ref.watch(userGroupsProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('Error: $e', textAlign: TextAlign.center))),
        data: (groups) {
          if (groups.isEmpty) return _buildEmpty();
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              itemBuilder: (context, i) => _groupCard(context, groups[i]),
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'join',
            onPressed: () => _showJoinDialog(context),
            child: const Icon(Icons.group_add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'create',
            onPressed: () => _showCreateDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('New Group'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text('No groups yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Create a group or join with an invite code',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: () => _showCreateDialog(context), icon: const Icon(Icons.add), label: const Text('Create Group')),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: () => _showJoinDialog(context), icon: const Icon(Icons.group_add), label: const Text('Join with Code')),
          ],
        ),
      ),
    );
  }

  Widget _groupCard(BuildContext context, Map<String, dynamic> group) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text((group['group_name'] ?? '?')[0].toString().toUpperCase()),
        ),
        title: Text(group['group_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${group['member_count'] ?? 0} members • ${group['completion_count'] ?? 0}/${group['total_squares'] ?? 24} completed',
          style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showGroupDetail(context, group),
      ),
    );
  }

  void _showGroupDetail(BuildContext context, Map<String, dynamic> group) {
    // For now show a simple detail; we'll wire up the full screen later
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening ${group['group_name']}...')),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => _CreateDialog(
      onCreate: (name) async {
        final user = ref.read(authNotifierProvider);
        if (user == null) return;
        await ref.read(groupServiceProvider).createGroup(
          userId: user.id, name: name, poolId: 'sg-life-2026-w16',
        );
        _refresh();
        if (context.mounted) Navigator.pop(context);
      },
    ));
  }

  void _showJoinDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => _JoinDialog(
      onJoin: (code) async {
        final user = ref.read(authNotifierProvider);
        if (user == null) return;
        await ref.read(groupServiceProvider).joinGroup(user.id, code);
        _refresh();
        if (context.mounted) Navigator.pop(context);
      },
    ));
  }
}

class _CreateDialog extends StatefulWidget {
  final Future<void> Function(String name) onCreate;
  const _CreateDialog({required this.onCreate});
  @override
  State<_CreateDialog> createState() => _CreateDialogState();
}
class _CreateDialogState extends State<_CreateDialog> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Group'),
      content: TextField(controller: _ctrl, decoration: const InputDecoration(hintText: 'Group name'), autofocus: true),
      actions: [
        TextButton(onPressed: _loading ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _loading ? null : () async {
            setState(() => _loading = true);
            try { await widget.onCreate(_ctrl.text.trim()); }
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
      content: TextField(controller: _ctrl, decoration: const InputDecoration(hintText: 'Invite code'), autofocus: true, textCapitalization: TextCapitalization.characters),
      actions: [
        TextButton(onPressed: _loading ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _loading ? null : () async {
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
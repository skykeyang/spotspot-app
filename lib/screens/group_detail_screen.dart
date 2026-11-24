import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/group.dart';
import '../services/group_service.dart';
import '../services/pools.dart';
import '../providers/auth_provider.dart';

final groupDetailProvider = FutureProvider.family<Map<String, dynamic>?, ({String groupId, String userId})>((ref, params) async {
  final service = ref.read(groupServiceProvider);
  return service.getGroupDetail(params.groupId, params.userId);
});

class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  int _selectedTab = 0; // 0 = Board, 1 = Feed

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider);
    if (user == null) return const Scaffold(body: Center(child: Text('Not signed in')));

    final detailAsync = ref.watch(groupDetailProvider((groupId: widget.groupId, userId: user.id)));

    return detailAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('Error: $e'))),
      data: (detail) {
        if (detail == null) return const Scaffold(body: Center(child: Text('Group not found')));

        final group = Group.fromJson(detail['group'] as Map<String, dynamic>);
        final board = detail['board'] != null
            ? GroupBoard.fromJson(detail['board'] as Map<String, dynamic>)
            : null;
        final feed = (detail['feed'] as List?)?.map((e) => GroupFeedPost.fromJson(e as Map<String, dynamic>)).toList() ?? [];

        return Scaffold(
          appBar: AppBar(
            title: Text(group.name),
            actions: [
              IconButton(icon: const Icon(Icons.share), onPressed: () {}),
            ],
          ),
          body: Column(
            children: [
              // Tab bar
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Board')),
                  ButtonSegment(value: 1, label: Text('Feed')),
                ],
                selected: {_selectedTab},
                onSelectionChanged: (s) => setState(() => _selectedTab = s.first),
              ),
              Expanded(
                child: _selectedTab == 0
                    ? _buildBoard(context, board, user.id, group)
                    : _buildFeed(context, feed, user.id, group),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBoard(BuildContext context, GroupBoard? board, String userId, Group group) {
    if (board == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No board yet'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                await ref.read(groupServiceProvider).createBoard(userId, group.id, group.poolId);
                ref.invalidate(groupDetailProvider((groupId: group.id, userId: userId)));
              },
              child: const Text('Generate Board'),
            ),
          ],
        ),
      );
    }

    final pool = getPoolById(group.poolId);
    final poolColor = pool != null ? hexToColor(pool.color) : Theme.of(context).colorScheme.primary;

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 1,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: 25,
      itemBuilder: (context, index) {
        if (index == 12) {
          // Free space
        return Container(
          decoration: BoxDecoration(
            color: poolColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: poolColor.withOpacity(0.5)),
          ),
          child: const Center(child: Text('FREE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        );
        }

        final isChecked = board.checked.length > index && board.checked[index];
        final event = board.squares.length > index ? board.squares[index] : null;

        return GestureDetector(
          onTap: () => _toggleSquare(index, board, userId, group.id),
          child: Container(
            decoration: BoxDecoration(
              color: isChecked ? poolColor.withOpacity(0.15) : Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isChecked ? poolColor : Theme.of(context).dividerColor,
                width: isChecked ? 1.5 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isChecked)
                    Icon(Icons.check_circle, color: poolColor, size: 20)
                  else
                    Icon(Icons.circle_outlined, color: Theme.of(context).dividerColor, size: 20),
                  const SizedBox(height: 2),
                  Text(
                    event?.text ?? '',
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 7,
                      color: isChecked ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeed(BuildContext context, List<GroupFeedPost> feed, String userId, Group group) {
    if (feed.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('No posts yet', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Check off a square to share it here', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: feed.length,
      itemBuilder: (context, i) {
        final post = feed[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text((post.displayName ?? 'U')[0].toUpperCase()),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.displayName ?? 'User', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(post.eventName, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ),
              // Photo
              ClipRounded(
                child: Image.network(post.photo, fit: BoxFit.cover, width: double.infinity, height: 240,
                  errorBuilder: (_, __, ___2) => Container(height: 240, color: Colors.grey.shade300, child: const Center(child: Icon(Icons.broken_image))),
                ),
              ),
              // Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(post.userLiked ? Icons.favorite : Icons.favorite_border, size: 20),
                      onPressed: () => _toggleLike(post, userId),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(width: 8),
                    Text('${post.likeCount}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggleSquare(int index, GroupBoard board, String userId, String groupId) async {
    final newChecked = List<bool>.from(board.checked);
    newChecked[index] = !newChecked[index];
    await ref.read(groupServiceProvider).saveBoard(userId, groupId, newChecked, board.photos);
    ref.invalidate(groupDetailProvider((groupId: groupId, userId: userId)));
  }

  void _toggleLike(GroupFeedPost post, String userId) async {
    final service = ref.read(groupServiceProvider);
    if (post.userLiked) {
      await service.unlikePost(userId, post.id);
    } else {
      await service.likePost(userId, post.id);
    }
    final user = ref.read(authNotifierProvider);
    if (user != null) {
      ref.invalidate(groupDetailProvider((groupId: post.groupId, userId: user.id)));
    }
  }
}

class ClipRounded extends StatelessWidget {
  final Widget child;
  const ClipRounded({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(borderRadius: BorderRadius.circular(12), child: child);
  }
}
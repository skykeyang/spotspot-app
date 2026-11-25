import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../models/group.dart';
import '../services/group_service.dart';
import '../services/pools.dart';
import '../providers/auth_provider.dart';

final groupDetailProvider = FutureProvider.family<Map<String, dynamic>?, ({String groupId, String userId})>((ref, params) async {
  return ref.read(groupServiceProvider).getGroupDetail(params.groupId, params.userId);
});

const int _slots = 25;
const int _freeIndex = 12;

class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  int _tab = 0; // 0 = Board, 1 = Feed
  int? _pendingSquare;
  bool _uploading = false;
  String? _uploadStatus;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider);
    if (user == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Not signed in')));

    final detailAsync = ref.watch(groupDetailProvider((groupId: widget.groupId, userId: user.id)));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
        title: detailAsync.maybeWhen(
          data: (d) => d != null && d['group'] != null
              ? Text((d['group'] as Map)['name'] as String)
              : const Text('Loading...'),
          orElse: () => const Text('Loading...'),
        ),
        bottom: _tab == 0 ? null : null,
        actions: [
          IconButton(
            icon: Icon(_tab == 0 ? Icons.photo_library : Icons.grid_view),
            onPressed: () => setState(() => _tab = _tab == 0 ? 1 : 0),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('Error: $e'))),
        data: (detail) {
          if (detail == null) return const Center(child: Text('Group not found'));
          final group = Group.fromJson(detail['group'] as Map<String, dynamic>);
          final board = detail['board'] != null ? GroupBoard.fromJson(detail['board'] as Map<String, dynamic>) : null;
          final feed = (detail['feed'] as List?)?.map((e) => GroupFeedPost.fromJson(e as Map<String, dynamic>)).toList() ?? [];

          return _tab == 0
              ? _boardTab(context, board, user.id, group)
              : _feedTab(context, feed, user.id, group);
        },
      ),
    );
  }

  // === BOARD TAB ===
  Widget _boardTab(BuildContext context, GroupBoard? board, String userId, Group group) {
    final theme = Theme.of(context);
    final pool = getPoolById(group.poolId);
    final poolColor = pool != null ? hexToColor(pool.color) : theme.colorScheme.primary;

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

    // Compute checked set — board.checked is a list of 25 bools
    final checkedSet = <int>{};
    for (int i = 0; i < board.checked.length; i++) {
      if (board.checked[i]) checkedSet.add(i);
    }

    // Detect bingo lines
    final bingoLines = _detectBingoLines(checkedSet);

    // Count checked (excluding free space)
    final checkedCount = checkedSet.contains(_freeIndex) ? checkedSet.length - 1 : checkedSet.length;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // Pool name
            Text(pool?.name ?? 'Board', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),

            // Stats bar
            Row(
              children: [
                Text(
                  '$checkedCount/${_slots - 1} spotted',
                  style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
                ),
                const Spacer(),
                if (bingoLines.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: poolColor, borderRadius: BorderRadius.circular(20)),
                    child: const Text('BINGO!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // 5x5 Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                childAspectRatio: 1,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemCount: _slots,
              itemBuilder: (context, index) {
                // Free space
                if (index == _freeIndex) {
                  return Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor, width: 1.5),
                    ),
                    child: Center(
                      child: Text('FREE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant)),
                    ),
                  );
                }

                // Map grid index to square index (skip free space)
                final cardIdx = index < _freeIndex ? index : index - 1;
                final event = cardIdx < board.squares.length ? board.squares[cardIdx] : null;
                final isChecked = checkedSet.contains(index);
                final photoUrl = cardIdx < board.photos.length ? board.photos[cardIdx] : null;
                final isInBingo = bingoLines.contains(index);
                final diff = event?.difficulty ?? 1;

                return GestureDetector(
                  onTap: () => _handleTap(index, cardIdx, event, isChecked, photoUrl, userId, group.id),
                  child: Container(
                    decoration: BoxDecoration(
                      color: photoUrl != null && photoUrl.isNotEmpty
                          ? Colors.black
                          : isChecked
                              ? poolColor.withOpacity(0.1)
                              : theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isInBingo
                            ? poolColor
                            : isChecked
                                ? poolColor.withOpacity(0.5)
                                : theme.dividerColor,
                        width: isInBingo ? 2.5 : isChecked ? 1.5 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Photo thumbnail
                          if (photoUrl != null && photoUrl.isNotEmpty)
                            CachedNetworkImage(
                              imageUrl: photoUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(color: poolColor.withOpacity(0.2)),
                              errorWidget: (_, __, ___) => Container(color: poolColor.withOpacity(0.2)),
                            )
                          else if (event != null)
                            Padding(
                              padding: const EdgeInsets.all(4),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Category dot
                                  Align(
                                    alignment: Alignment.topCenter,
                                    child: Container(
                                      width: 6, height: 6,
                                      decoration: BoxDecoration(shape: BoxShape.circle, color: poolColor.withOpacity(0.5)),
                                    ),
                                  ),
                                  // Event text
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        event.text,
                                        textAlign: TextAlign.center,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 7,
                                          height: 1.1,
                                          color: isChecked ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Difficulty dot or checkmark
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Icon(
                                      isChecked ? Icons.check_circle : _diffIcon(diff),
                                      size: 10,
                                      color: isChecked ? poolColor : _diffColor(diff, poolColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // SPOTTED stamp overlay on photo
                          if (photoUrl != null && photoUrl.isNotEmpty)
                            Positioned(
                              bottom: 2, left: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('SPOTTED', style: TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.bold)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Refreshes remaining
            if (board.refreshesRemaining > 0)
              Center(
                child: Text(
                  '${board.refreshesRemaining} refreshes remaining',
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                ),
              ),

            const SizedBox(height: 8),
            Center(
              child: Text(
                'Tap a square to upload proof.',
                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6)),
              ),
            ),
          ],
        ),

        // Upload overlay
        if (_uploading)
          Container(
            color: Colors.black.withOpacity(0.4),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(_uploadStatus ?? 'Uploading...', style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Handle tap — same as web: upload photo to check off
  Future<void> _handleTap(int gridIndex, int cardIdx, dynamic event, bool isChecked, String? photoUrl, String userId, String groupId) async {
    if (event == null) return;

    if (isChecked) {
      // Already checked — show option to uncheck or view
      _showCheckedOptions(gridIndex, cardIdx, event, photoUrl, userId, groupId);
      return;
    }

    // Upload photo
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;

    setState(() {
      _uploading = true;
      _uploadStatus = 'Uploading...';
    });

    try {
      final service = ref.read(groupServiceProvider);
      final photoUrl = await service.uploadPhoto(userId, groupId, photo.path);

      setState(() => _uploadStatus = 'Posting to feed...');
      await service.postToFeed(
        userId: userId,
        groupId: groupId,
        eventName: event.text,
        eventCategory: event.category,
        eventDifficulty: event.difficulty,
        photo: photoUrl,
      );

      // Mark checked + save photo
      final board = ref.read(groupDetailProvider((groupId: groupId, userId: userId))).value?['board'];
      if (board != null) {
        final gb = GroupBoard.fromJson(board as Map<String, dynamic>);
        final newChecked = List<bool>.from(gb.checked);
        if (gridIndex < newChecked.length) newChecked[gridIndex] = true;
        final newPhotos = Map<int, String>.from(gb.photos);
        newPhotos[cardIdx] = photoUrl;
        await service.saveBoard(userId, groupId, newChecked, newPhotos);
      }

      ref.invalidate(groupDetailProvider((groupId: groupId, userId: userId)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
          _uploadStatus = null;
        });
      }
    }
  }

  void _showCheckedOptions(int gridIndex, int cardIdx, dynamic event, String? photoUrl, String userId, String groupId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.visibility),
            title: const Text('View photo'),
            onTap: () {
              Navigator.pop(context);
              if (photoUrl != null) {
                // Show full photo
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: Text(event.text ?? 'Photo')),
                    body: Center(child: CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.contain)),
                  ),
                ));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Retake photo'),
            onTap: () {
              Navigator.pop(context);
              _retakePhoto(gridIndex, cardIdx, event, userId, groupId);
            },
          ),
          ListTile(
            leading: const Icon(Icons.close, color: Colors.red),
            title: const Text('Uncheck'),
            onTap: () async {
              Navigator.pop(context);
              await _uncheck(gridIndex, cardIdx, event, userId, groupId);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _retakePhoto(int gridIndex, int cardIdx, dynamic event, String userId, String groupId) async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;

    setState(() => _uploading = true);
    try {
      final service = ref.read(groupServiceProvider);
      final newPhotoUrl = await service.uploadPhoto(userId, groupId, photo.path);
      final board = ref.read(groupDetailProvider((groupId: groupId, userId: userId))).value?['board'];
      if (board != null) {
        final gb = GroupBoard.fromJson(board as Map<String, dynamic>);
        final newPhotos = Map<int, String>.from(gb.photos);
        newPhotos[cardIdx] = newPhotoUrl;
        await service.saveBoard(userId, groupId, gb.checked, newPhotos);
      }
      ref.invalidate(groupDetailProvider((groupId: groupId, userId: userId)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _uncheck(int gridIndex, int cardIdx, dynamic event, String userId, String groupId) async {
    try {
      final service = ref.read(groupServiceProvider);
      await service.deleteFeedPost(groupId, event.text, userId);
      final board = ref.read(groupDetailProvider((groupId: groupId, userId: userId))).value?['board'];
      if (board != null) {
        final gb = GroupBoard.fromJson(board as Map<String, dynamic>);
        final newChecked = List<bool>.from(gb.checked);
        if (gridIndex < newChecked.length) newChecked[gridIndex] = false;
        final newPhotos = Map<int, String>.from(gb.photos);
        newPhotos.remove(cardIdx);
        await service.saveBoard(userId, groupId, newChecked, newPhotos);
      }
      ref.invalidate(groupDetailProvider((groupId: groupId, userId: userId)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  // === FEED TAB ===
  Widget _feedTab(BuildContext context, List<GroupFeedPost> feed, String userId, Group group) {
    final theme = Theme.of(context);
    if (feed.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text('No posts yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Check off a square to share it here',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
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
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text((post.displayName ?? 'U')[0].toUpperCase()),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.displayName ?? 'User', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(post.eventName, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: post.photo,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 240,
                  errorWidget: (_, __, ___) => Container(height: 240, color: Colors.grey.shade300, child: const Center(child: Icon(Icons.broken_image))),
                ),
              ),
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

  // === Helpers ===
  Set<int> _detectBingoLines(Set<int> checked) {
    final lines = <int>{};
    // Rows
    for (int r = 0; r < 5; r++) {
      if (List.generate(r * 5, (i) => r * 5 + i).every((i) => checked.contains(i))) {
        lines.addAll(List.generate(5, (i) => r * 5 + i));
      }
    }
    // Columns
    for (int c = 0; c < 5; c++) {
      if (List.generate(5, (r) => r * 5 + c).every((i) => checked.contains(i))) {
        lines.addAll(List.generate(5, (r) => r * 5 + c));
      }
    }
    // Diagonal TL-BR
    if (List.generate(5, (i) => i * 6).every((i) => checked.contains(i))) {
      lines.addAll(List.generate(5, (i) => i * 6));
    }
    // Diagonal TR-BL
    if (List.generate(5, (i) => i * 4 + 4).every((i) => checked.contains(i))) {
      lines.addAll(List.generate(5, (i) => i * 4 + 4));
    }
    return lines;
  }

  IconData _diffIcon(int diff) {
    return Icons.circle;
  }

  Color _diffColor(int diff, Color base) {
    switch (diff) {
      case 1: return Colors.green.shade300;
      case 2: return Colors.amber.shade400;
      case 3: return Colors.orange.shade400;
      default: return Colors.red.shade400;
    }
  }
}
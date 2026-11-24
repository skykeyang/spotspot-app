// Group types — mirrors the web app's groups.ts
import 'bingo.dart';

class Group {
  final String id;
  final String name;
  final String? coverImg;
  final String poolId;
  final String createdBy;
  final String createdAt;
  final String mediaMode;

  const Group({
    required this.id,
    required this.name,
    this.coverImg,
    required this.poolId,
    required this.createdBy,
    required this.createdAt,
    required this.mediaMode,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      coverImg: json['cover_img'] as String?,
      poolId: json['pool_id'] as String,
      createdBy: json['created_by'] as String,
      createdAt: json['created_at'] as String,
      mediaMode: json['media_mode'] as String? ?? 'both',
    );
  }
}

class GroupMember {
  final String userId;
  final String groupId;
  final String role;
  final bool canInvite;
  final String joinedAt;
  final String? displayName;
  final String? avatarUrl;

  const GroupMember({
    required this.userId,
    required this.groupId,
    required this.role,
    required this.canInvite,
    required this.joinedAt,
    this.displayName,
    this.avatarUrl,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'] as Map<String, dynamic>?;
    return GroupMember(
      userId: json['user_id'] as String,
      groupId: json['group_id'] as String,
      role: json['role'] as String? ?? 'member',
      canInvite: json['can_invite'] as bool? ?? false,
      joinedAt: json['joined_at'] as String,
      displayName: profiles?['display_name'] as String?,
      avatarUrl: profiles?['avatar_url'] as String?,
    );
  }
}

class GroupBoard {
  final String id;
  final String userId;
  final String groupId;
  final List<BingoEvent> squares;
  final List<bool> checked;
  final Map<int, String> photos;
  final int completionCount;
  final int refreshesRemaining;

  const GroupBoard({
    required this.id,
    required this.userId,
    required this.groupId,
    required this.squares,
    required this.checked,
    required this.photos,
    required this.completionCount,
    required this.refreshesRemaining,
  });

  factory GroupBoard.fromJson(Map<String, dynamic> json) {
    final squaresRaw = json['squares'] as List? ?? [];
    final checkedRaw = json['checked'] as List? ?? [];
    final photosRaw = json['photos'] as Map<String, dynamic>? ?? {};

    return GroupBoard(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      groupId: json['group_id'] as String,
      squares: squaresRaw.map((e) => BingoEvent.fromJson(e as Map<String, dynamic>)).toList(),
      checked: checkedRaw.map((e) => e as bool).toList(),
      photos: photosRaw.map((k, v) => MapEntry(int.parse(k), v as String)),
      completionCount: json['completion_count'] as int? ?? 0,
      refreshesRemaining: json['refreshes_remaining'] as int? ?? 3,
    );
  }
}

class GroupFeedPost {
  final String id;
  final String userId;
  final String groupId;
  final String eventName;
  final String? eventCategory;
  final int? eventDifficulty;
  final String photo;
  final String createdAt;
  final String? displayName;
  final String? avatarUrl;
  final int likeCount;
  final bool userLiked;

  const GroupFeedPost({
    required this.id,
    required this.userId,
    required this.groupId,
    required this.eventName,
    this.eventCategory,
    this.eventDifficulty,
    required this.photo,
    required this.createdAt,
    this.displayName,
    this.avatarUrl,
    this.likeCount = 0,
    this.userLiked = false,
  });

  factory GroupFeedPost.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'] as Map<String, dynamic>?;
    return GroupFeedPost(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      groupId: json['group_id'] as String,
      eventName: json['event_name'] as String,
      eventCategory: json['event_category'] as String?,
      eventDifficulty: json['event_difficulty'] as int?,
      photo: json['photo'] as String,
      createdAt: json['created_at'] as String,
      displayName: profiles?['display_name'] as String?,
      avatarUrl: profiles?['avatar_url'] as String?,
      likeCount: json['like_count'] as int? ?? 0,
      userLiked: json['user_liked'] as bool? ?? false,
    );
  }
}
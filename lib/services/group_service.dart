import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/group.dart';
import 'pools.dart';

final groupServiceProvider = Provider<GroupService>((ref) {
  return GroupService(ref.read(supabaseProvider));
});

class GroupService {
  final SupabaseClient _client;

  GroupService(this._client);

  // === Groups ===
  Future<List<Map<String, dynamic>>> getUserGroups(String userId) async {
    final data = await _client.rpc('get_user_groups', params: {'p_user_id': userId});
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> getGroupDetail(String groupId, String userId) async {
    final data = await _client.rpc('get_group_detail', params: {
      'p_group_id': groupId,
      'p_user_id': userId,
    });
    return data as Map<String, dynamic>?;
  }

  Future<Group> createGroup({
    required String userId,
    required String name,
    required String poolId,
    String mediaMode = 'both',
    String? coverImg,
  }) async {
    final group = await _client.from('groups').insert({
      'name': name,
      'pool_id': poolId,
      'created_by': userId,
      'cover_img': coverImg,
      'media_mode': mediaMode,
    }).select().single();

    await _client.from('group_members').insert({
      'user_id': userId,
      'group_id': group['id'],
      'role': 'owner',
      'can_invite': true,
    });

    // Generate invite code
    final code = _generateInviteCode();
    await _client.from('group_invites').insert({
      'group_id': group['id'],
      'code': code,
      'created_by': userId,
    });

    return Group.fromJson(group);
  }

  Future<void> joinGroup(String userId, String inviteCode) async {
    final code = inviteCode.toUpperCase();
    final invite = await _client
        .from('group_invites')
        .select('*, groups(*)')
        .eq('code', code)
        .gt('expires_at', DateTime.now().toUtc().toIso8601String())
        .maybeSingle();

    if (invite == null) throw Exception('Invalid or expired invite code');
    if (invite['max_uses'] != null && invite['uses'] >= invite['max_uses']) {
      throw Exception('Invite code has reached maximum uses');
    }

    final groupId = invite['group_id'] as String;
    final poolId = (invite['groups'] as Map<String, dynamic>)['pool_id'] as String;

    // Check if already member
    final existing = await _client
        .from('group_members')
        .select('user_id')
        .eq('group_id', groupId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) throw Exception('Already a member of this group');

    await _client.from('group_members').insert({
      'user_id': userId,
      'group_id': groupId,
    });

    await _client.from('group_invites').update({'uses': invite['uses'] + 1}).eq('id', invite['id']);
  }

  Future<void> leaveGroup(String userId, String groupId) async {
    await _client.from('group_members').delete()
        .eq('user_id', userId).eq('group_id', groupId);
    await _client.from('group_boards').delete()
        .eq('user_id', userId).eq('group_id', groupId);
  }

  // === Boards ===
  Future<GroupBoard?> getBoard(String userId, String groupId) async {
    final data = await _client.from('group_boards')
        .select('*')
        .eq('user_id', userId)
        .eq('group_id', groupId)
        .maybeSingle();
    if (data == null) return null;
    return GroupBoard.fromJson(data);
  }

  Future<void> createBoard(String userId, String groupId, String poolId) async {
    final events = generateBoardEvents(poolId);
    final checked = List<bool>.filled(25, false);
    checked[12] = true; // Free space

    await _client.from('group_boards').insert({
      'user_id': userId,
      'group_id': groupId,
      'squares': events.map((e) => e.toJson()).toList(),
      'checked': checked,
      'photos': {},
      'completion_count': 0,
      'refreshes_remaining': 3,
    });
  }

  Future<void> saveBoard(String userId, String groupId, List<bool> checked, Map<int, String> photos) async {
    final completionCount = checked.where((c) => c).length - (checked.length > 12 && checked[12] ? 1 : 0);
    await _client.from('group_boards').update({
      'checked': checked,
      'photos': photos.map((k, v) => MapEntry(k.toString(), v)),
      'completion_count': completionCount,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('user_id', userId).eq('group_id', groupId);
  }

  // === Feed ===
  Future<List<GroupFeedPost>> getFeed(String groupId, {int page = 0, int pageSize = 20}) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;

    final data = await _client.from('group_feed')
        .select('*, profiles(display_name, avatar_url)')
        .eq('group_id', groupId)
        .order('created_at', ascending: false)
        .range(from, to);

    return (data as List).map((e) => GroupFeedPost.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> postToFeed({
    required String userId,
    required String groupId,
    required String eventName,
    String? eventCategory,
    int? eventDifficulty,
    required String photo,
  }) async {
    await _client.from('group_feed').insert({
      'user_id': userId,
      'group_id': groupId,
      'event_name': eventName,
      'event_category': eventCategory,
      'event_difficulty': eventDifficulty,
      'photo': photo,
    });
  }

  Future<void> deleteFeedPost(String groupId, String eventName, String userId) async {
    final posts = await _client.from('group_feed')
        .select('id')
        .eq('group_id', groupId)
        .eq('user_id', userId)
        .eq('event_name', eventName)
        .order('created_at', ascending: false)
        .limit(1);

    if (posts.isNotEmpty) {
      final postId = posts[0]['id'];
      await _client.from('group_feed').delete().eq('id', postId);
      await _client.from('group_feed_likes').delete().eq('post_id', postId);
      await _client.from('group_feed_comments').delete().eq('post_id', postId);
    }
  }

  Future<void> likePost(String userId, String postId) async {
    await _client.from('group_feed_likes').insert({
      'post_id': postId,
      'user_id': userId,
    }).maybeSingle();
  }

  Future<void> unlikePost(String userId, String postId) async {
    await _client.from('group_feed_likes').delete()
        .eq('post_id', postId).eq('user_id', userId);
  }

  // === Profile ===
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final data = await _client.from('profiles')
        .select('*').eq('id', userId).maybeSingle();
    return data;
  }

  Future<void> updateProfile(String userId, {String? displayName, String? avatarUrl}) async {
    final updates = <String, dynamic>{};
    if (displayName != null) updates['display_name'] = displayName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (updates.isNotEmpty) {
      await _client.from('profiles').update(updates).eq('id', userId);
    }
  }

  // === Storage ===
  Future<String> uploadPhoto(String userId, String groupId, String filePath) async {
    final path = '$userId/$groupId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage.from('feed-photos').upload(path, filePath);
    return _client.storage.from('feed-photos').getPublicUrl(path);
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
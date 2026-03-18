// features/company_portal/chat/data/repositories/company_chat_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class CompanyChatRepository {
  final SupabaseClient _supabase;

  CompanyChatRepository(this._supabase);

  /// 企業のチャットルーム一覧を取得
  Future<List<Map<String, dynamic>>> getCompanyChatRooms(String companyId) async {
    try {
      final response = await _supabase
          .from('chat_rooms')
          .select('*, chat_room_members(*)')
          .eq('company_id', companyId)
          .order('created_at', ascending: false); // ✅ updated_at → created_at

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  /// チャットルームの詳細を取得
  Future<Map<String, dynamic>?> getChatRoom(String roomId) async {
    try {
      final response = await _supabase
          .from('chat_rooms')
          .select('*, chat_room_members(*, profiles(*))')
          .eq('id', roomId)
          .single();

      return response as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// チャットルームのメッセージ一覧を取得
  Future<List<Map<String, dynamic>>> getMessages(String roomId) async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select('*, profiles(*)')
          .eq('room_id', roomId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  /// メッセージを送信
  Future<void> sendMessage({
    required String roomId,
    required String userId,
    required String content,
  }) async {
    try {
      await _supabase.from('chat_messages').insert({
        'room_id': roomId,
        'profile_id': userId,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      });

      // チャットルームの最終更新日時を更新
      await _supabase.from('chat_rooms').update({
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', roomId);
    } catch (e) {
      rethrow;
    }
  }

  /// チャットルームを作成
  Future<String> createChatRoom({
    required String companyId,
    required String name,
    required String description, // ✅ 説明を追加
    required String type, // 'direct' or 'group'
    String? currentUserId, // 作成者のID
    List<String>? memberIds,
  }) async {
    try {
      // チャットルームを作成
      final roomData = {
        'company_id': companyId,
        'name': name,
        'description': description, // ✅ 説明を追加
        'room_type': type,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final roomResponse = await _supabase
          .from('chat_rooms')
          .insert(roomData)
          .select()
          .single();

      final roomId = roomResponse['id'] as String;

      // メンバーを追加
      final allMemberIds = <String>[];
      
      // 作成者を必ず追加
      if (currentUserId != null) {
        allMemberIds.add(currentUserId);
      }
      
      // 指定されたメンバーを追加
      if (memberIds != null && memberIds.isNotEmpty) {
        allMemberIds.addAll(memberIds);
      }

      // 重複を削除
      final uniqueMemberIds = allMemberIds.toSet().toList();

      if (uniqueMemberIds.isNotEmpty) {
        final members = uniqueMemberIds.map((memberId) => {
          'room_id': roomId,
          'profile_id': memberId,
        }).toList();

        await _supabase.from('chat_room_members').insert(members);
      }

      return roomId;
    } catch (e) {
      rethrow;
    }
  }

  /// チャットルームを削除
  /// 関連データを順次削除する（部分的な失敗時もルーム削除を試行）
  Future<void> deleteChatRoom(String roomId) async {
    try {
      // メッセージを削除（失敗しても続行）
      try {
        await _supabase.from('chat_messages').delete().eq('room_id', roomId);
      } catch (_) {
        // 子レコード削除失敗は続行
      }

      // メンバーを削除（失敗しても続行）
      try {
        await _supabase.from('chat_room_members').delete().eq('room_id', roomId);
      } catch (_) {
        // 子レコード削除失敗は続行
      }

      // チャットルームを削除（これが主要操作）
      await _supabase.from('chat_rooms').delete().eq('id', roomId);
    } catch (e) {
      rethrow;
    }
  }

  /// チャットルームにメンバーを追加
  Future<void> addMember({
    required String roomId,
    required String profileId,
  }) async {
    try {
      await _supabase.from('chat_room_members').insert({
        'room_id': roomId,
        'profile_id': profileId,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// チャットルームからメンバーを削除
  Future<void> removeMember({
    required String roomId,
    required String profileId,
  }) async {
    try {
      await _supabase
          .from('chat_room_members')
          .delete()
          .eq('room_id', roomId)
          .eq('profile_id', profileId);
    } catch (e) {
      rethrow;
    }
  }
}
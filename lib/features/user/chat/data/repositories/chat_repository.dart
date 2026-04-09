// features/user/chat/data/repositories/chat_repository.dart
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRepository {
  final SupabaseClient _supabase;

  // 禁止ワードリスト（本番ではDBから取得すべき）
  static const _bannedWords = [
    '死ね', '殺す', 'バカ', 'アホ', 'クソ',
  ];

  ChatRepository(this._supabase);

  /// 禁止ワードチェック
  bool containsBannedWord(String content) {
    final lowerContent = content.toLowerCase();
    return _bannedWords.any((word) => lowerContent.contains(word));
  }

  /// ユーザーが参加しているチャットルーム一覧を取得
  Future<List<Map<String, dynamic>>> getChatRooms(String userId) async {
    try {
      final response = await _supabase
          .from('chat_room_members')
          .select('room_id, chat_rooms(*, companies(*))')
          .eq('profile_id', userId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  /// すべてのグループチャットを取得（全公開）
  Future<List<Map<String, dynamic>>> getAllGroupChats() async {
    try {
      final response = await _supabase
          .from('chat_rooms')
          .select('*, companies(*), chat_room_members(count)')
          .eq('room_type', 'group')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
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

  /// メッセージのリアルタイムストリームを取得
  Stream<List<Map<String, dynamic>>> messagesStream(String roomId) {
    return _supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: true);
  }

  /// 既読ステータスを更新
  Future<void> markAsRead({
    required String roomId,
    required String userId,
  }) async {
    try {
      await _supabase.from('chat_room_members').update({
        'last_read_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('room_id', roomId).eq('profile_id', userId);
    } catch (_) {
      // 既読更新失敗は致命的ではない
    }
  }

  /// メッセージを送信
  Future<void> sendMessage({
    required String roomId,
    required String userId,
    required String content,
  }) async {
    // 入力バリデーション
    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) {
      throw Exception('メッセージを入力してください');
    }
    if (trimmedContent.length > 2000) {
      throw Exception('メッセージは2000文字以内にしてください');
    }
    if (containsBannedWord(trimmedContent)) {
      throw Exception('不適切な表現が含まれています');
    }

    try {
      await _supabase.from('chat_messages').insert({
        'room_id': roomId,
        'profile_id': userId,
        'content': trimmedContent,
      });

      // チャットルームの最終更新日時を更新
      await _supabase.from('chat_rooms').update({
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', roomId);
    } catch (e) {
      rethrow;
    }
  }

  /// ユーザーがグループチャットを作成
  Future<String> createUserGroupChat({
    required String userId,
    required String name,
    required String description,
    String? iconUrl,
  }) async {
    try {
      final roomData = {
        'name': name,
        'description': description,
        'room_type': 'group',
        'company_id': null,
        'created_by': userId,
        'icon_url': iconUrl,
      };

      final roomResponse = await _supabase
          .from('chat_rooms')
          .insert(roomData)
          .select()
          .single();

      final roomId = roomResponse['id'] as String;

      // 作成者を自動的にメンバーとして追加
      await _supabase.from('chat_room_members').insert({
        'room_id': roomId,
        'profile_id': userId,
      });

      return roomId;
    } catch (e) {
      rethrow;
    }
  }

  /// チャットアイコンをSupabase Storageにアップロード
  Future<String> uploadChatIcon({
    required String userId,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sanitizedName = fileName.replaceAll(RegExp(r'[^\w.]'), '_');
      final path = '$userId/${timestamp}_$sanitizedName';

      await _supabase.storage.from('chat-icons').uploadBinary(
        path,
        imageBytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: false,
        ),
      );

      final signedUrl = await _supabase.storage.from('chat-icons').createSignedUrl(path, 60 * 60 * 24 * 365);
      return signedUrl;
    } catch (e) {
      rethrow;
    }
  }
}
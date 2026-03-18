// company_portal/intern/data/repositories/company_intern_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:numbers/features/user/intern/domain/models/internship.dart';
import 'package:numbers/features/user/intern/domain/models/internship_application.dart';

class CompanyInternRepository {
  final SupabaseClient _supabase;

  CompanyInternRepository(this._supabase);

  // ========== インターンCRUD ==========

  /// 企業のインターン一覧を取得
  Future<List<Internship>> getCompanyInternships() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('ログインが必要です');
    }

    try {
      // profilesからcompany_idを取得
      final profile = await _supabase
          .from('profiles')
          .select('company_id')
          .eq('id', userId)
          .maybeSingle();

      if (profile == null || profile['company_id'] == null) {
        throw Exception('企業アカウントではありません');
      }

      final companyId = profile['company_id'] as String;

      final response = await _supabase
          .from('internships')
          .select('*, companies(*)')
          .eq('company_id', companyId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Internship.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// インターンを投稿
  Future<Internship> createInternship({
    required String title,
    required String description,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? tags,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('ログインが必要です');
    }

    try {
      // profilesからcompany_idを取得
      final profile = await _supabase
          .from('profiles')
          .select('company_id')
          .eq('id', userId)
          .maybeSingle();

      if (profile == null || profile['company_id'] == null) {
        throw Exception('企業アカウントではありません');
      }

      final companyId = profile['company_id'] as String;

      final response = await _supabase
          .from('internships')
          .insert({
            'company_id': companyId,
            'title': title,
            'description': description,
            'start_date': startDate?.toIso8601String().split('T')[0],
            'end_date': endDate?.toIso8601String().split('T')[0],
            'tags': tags ?? [],
            'is_public': true,
          })
          .select('*, companies(*)')
          .single();

      return Internship.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// インターンを更新
  Future<Internship> updateInternship({
    required String internshipId,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? tags,
    bool? isPublic,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (startDate != null) {
        updateData['start_date'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        updateData['end_date'] = endDate.toIso8601String().split('T')[0];
      }
      if (tags != null) updateData['tags'] = tags;
      if (isPublic != null) updateData['is_public'] = isPublic;

      final response = await _supabase
          .from('internships')
          .update(updateData)
          .eq('id', internshipId)
          .select('*, companies(*)')
          .single();

      return Internship.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// インターンを削除
  Future<void> deleteInternship(String internshipId) async {
    try {
      await _supabase.from('internships').delete().eq('id', internshipId);
    } catch (e) {
      rethrow;
    }
  }

  /// インターン詳細を取得
  Future<Internship?> getInternship(String internshipId) async {
    try {
      final response = await _supabase
          .from('internships')
          .select('*, companies(*)')
          .eq('id', internshipId)
          .maybeSingle();

      if (response == null) return null;
      return Internship.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // ========== 申し込み管理 ==========

  /// インターンへの申し込み一覧を取得
  Future<List<InternshipApplication>> getApplicationsForInternship(
    String internshipId,
  ) async {
    try {
      // まず申し込み一覧を取得
      final applications = await _supabase
          .from('internship_applications')
          .select('*')
          .eq('internship_id', internshipId)
          .order('applied_at', ascending: false);

      // ユーザーIDを収集してプロフィールを取得
      final userIds = (applications as List)
          .map((app) => app['user_id'] as String)
          .toSet()
          .toList();

      Map<String, Map<String, dynamic>> profilesMap = {};
      if (userIds.isNotEmpty) {
        final profiles = await _supabase
            .from('profiles')
            .select('*')
            .inFilter('id', userIds);

        for (final profile in profiles as List) {
          profilesMap[profile['id'] as String] = profile;
        }
      }

      // 申し込みにプロフィールを結合
      final result = (applications as List).map((app) {
        final userId = app['user_id'] as String;
        return <String, dynamic>{
          ...Map<String, dynamic>.from(app as Map),
          'profiles': profilesMap[userId],
        };
      }).toList();

      return result
          .map((json) => InternshipApplication.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// 全インターンの申し込み一覧を取得
  Future<List<InternshipApplication>> getAllApplications() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('ログインが必要です');
    }

    try {
      // profilesからcompany_idを取得
      final profile = await _supabase
          .from('profiles')
          .select('company_id')
          .eq('id', userId)
          .maybeSingle();

      if (profile == null || profile['company_id'] == null) {
        throw Exception('企業アカウントではありません');
      }

      final companyId = profile['company_id'] as String;

      // 自社インターンを取得
      final internships = await _supabase
          .from('internships')
          .select('*, companies(*)')
          .eq('company_id', companyId);

      final internshipsMap = <String, Map<String, dynamic>>{};
      final internshipIds = <String>[];
      for (final intern in internships as List) {
        final id = intern['id'] as String;
        internshipIds.add(id);
        internshipsMap[id] = intern;
      }

      if (internshipIds.isEmpty) {
        return [];
      }

      // 申し込みを取得
      final applications = await _supabase
          .from('internship_applications')
          .select('*')
          .inFilter('internship_id', internshipIds)
          .order('applied_at', ascending: false);

      // ユーザーIDを収集してプロフィールを取得
      final userIds = (applications as List)
          .map((app) => app['user_id'] as String)
          .toSet()
          .toList();

      Map<String, Map<String, dynamic>> profilesMap = {};
      if (userIds.isNotEmpty) {
        final profiles = await _supabase
            .from('profiles')
            .select('*')
            .inFilter('id', userIds);

        for (final p in profiles as List) {
          profilesMap[p['id'] as String] = p;
        }
      }

      // 申し込みにインターンとプロフィールを結合
      final result = (applications as List).map((app) {
        final appUserId = app['user_id'] as String;
        final internshipId = app['internship_id'] as String;
        return <String, dynamic>{
          ...Map<String, dynamic>.from(app as Map),
          'internships': internshipsMap[internshipId],
          'profiles': profilesMap[appUserId],
        };
      }).toList();

      return result
          .map((json) => InternshipApplication.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// 申し込みを承認してチャットを解放
  Future<InternshipApplication> approveApplication(String applicationId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('ログインが必要です');
    }

    try {
      // 申し込みを承認
      final appResponse = await _supabase
          .from('internship_applications')
          .update({
            'status': 'approved',
            'reviewed_at': DateTime.now().toIso8601String(),
            'reviewed_by': userId,
          })
          .eq('id', applicationId)
          .select('*')
          .single();

      // インターンシップ情報を取得（companies情報含む）
      final internshipData = await _supabase
          .from('internships')
          .select('*, companies(*)')
          .eq('id', appResponse['internship_id'])
          .single();

      // プロフィール情報を取得
      final profileData = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', appResponse['user_id'])
          .maybeSingle();

      // 結合（internshipsキーとprofilesキーで設定）
      final combined = Map<String, dynamic>.from(appResponse as Map);
      combined['internships'] = internshipData;
      combined['profiles'] = profileData;

      final application = InternshipApplication.fromJson(combined);

      // チャットルームを作成してユーザーを追加
      await _createChatRoomForApprovedApplication(application, userId);

      return application;
    } catch (e) {
      rethrow;
    }
  }

  /// 承認済み申し込みのためのチャットルームを作成
  Future<void> _createChatRoomForApprovedApplication(
    InternshipApplication application,
    String companyUserId,
  ) async {
    try {
      final internship = application.internship;

      if (internship == null) {
        return;
      }

      final company = internship.company;

      if (company == null) {
        return;
      }

      // 既存のチャットルームを確認
      final existingRooms = await _supabase
          .from('chat_rooms')
          .select('id, name')
          .eq('company_id', company.id)
          .eq('room_type', 'direct');

      // 重複チェック
      for (final room in existingRooms as List) {
        final roomId = room['id'] as String;
        final roomName = room['name'] as String;

        if (!roomName.contains(internship.title)) {
          continue;
        }

        final members = await _supabase
            .from('chat_room_members')
            .select('profile_id')
            .eq('room_id', roomId);

        final memberIds = (members as List)
            .map((m) => m['profile_id'] as String)
            .toSet();

        if (memberIds.contains(application.userId)) {
          return;
        }
      }

      // 新規チャットルームを作成
      final userName = application.userProfile?.nickname ?? 'インターン参加者';
      final roomName = '${internship.title} - $userName';

      final roomData = {
        'company_id': company.id,
        'name': roomName,
        'description': '${internship.title}のインターン参加者用チャットルームです',
        'room_type': 'direct',
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
      final members = [
        {'room_id': roomId, 'profile_id': companyUserId},
        {'room_id': roomId, 'profile_id': application.userId},
      ];

      await _supabase.from('chat_room_members').insert(members);

      // システムメッセージを送信
      await _supabase.from('chat_messages').insert({
        'room_id': roomId,
        'profile_id': companyUserId,
        'content': 'インターン「${internship.title}」への参加が承認されました。このチャットでやり取りを行ってください。',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // エラーを再スローしない（承認自体は成功させる）
    }
  }

  /// 申し込みを却下
  Future<InternshipApplication> rejectApplication(
    String applicationId, {
    String? reason,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('ログインが必要です');
    }

    try {
      final appResponse = await _supabase
          .from('internship_applications')
          .update({
            'status': 'rejected',
            'reviewed_at': DateTime.now().toIso8601String(),
            'reviewed_by': userId,
            'rejection_reason': reason,
          })
          .eq('id', applicationId)
          .select('*')
          .single();

      // インターンシップ情報を取得
      final internship = await _supabase
          .from('internships')
          .select('*, companies(*)')
          .eq('id', appResponse['internship_id'])
          .single();

      // プロフィール情報を取得
      final profile = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', appResponse['user_id'])
          .maybeSingle();

      // 結合
      final combined = {
        ...appResponse,
        'internships': internship,
        'profiles': profile,
      };

      return InternshipApplication.fromJson(combined);
    } catch (e) {
      rethrow;
    }
  }

  /// 申し込み数を取得（ステータス別）
  Future<Map<String, int>> getApplicationCounts(String internshipId) async {
    try {
      final response = await _supabase
          .from('internship_applications')
          .select('status')
          .eq('internship_id', internshipId);

      final counts = <String, int>{
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'cancelled': 0,
        'total': 0,
      };

      for (final app in response as List) {
        final status = app['status'] as String;
        counts[status] = (counts[status] ?? 0) + 1;
        counts['total'] = (counts['total'] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      rethrow;
    }
  }
}

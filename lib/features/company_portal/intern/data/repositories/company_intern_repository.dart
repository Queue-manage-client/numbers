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
  }

  /// インターンを削除
  Future<void> deleteInternship(String internshipId) async {
    await _supabase.from('internships').delete().eq('id', internshipId);
  }

  /// インターン詳細を取得
  Future<Internship?> getInternship(String internshipId) async {
    final response = await _supabase
        .from('internships')
        .select('*, companies(*)')
        .eq('id', internshipId)
        .maybeSingle();

    if (response == null) return null;
    return Internship.fromJson(response);
  }

  // ========== 申し込み管理 ==========

  /// インターンへの申し込み一覧を取得
  Future<List<InternshipApplication>> getApplicationsForInternship(
    String internshipId,
  ) async {
    try {
      print('=== 申し込み一覧取得開始 ===');
      print('internshipId: $internshipId');

      // まず申し込み一覧を取得
      final applications = await _supabase
          .from('internship_applications')
          .select('*')
          .eq('internship_id', internshipId)
          .order('applied_at', ascending: false);

      print('=== 申し込みレスポンス ===');
      print(applications);

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

      print('=== プロフィール取得完了 ===');
      print('プロフィール数: ${profilesMap.length}');

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
    } catch (e, st) {
      print('=== 申し込み一覧取得エラー ===');
      print('エラー: $e');
      print('スタックトレース: $st');
      rethrow;
    }
  }

  /// 全インターンの申し込み一覧を取得
  Future<List<InternshipApplication>> getAllApplications() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('ログインが必要です');
    }

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
  }

  /// 申し込みを承認してチャットを解放
  Future<InternshipApplication> approveApplication(String applicationId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('ログインが必要です');
    }

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

    final application = InternshipApplication.fromJson(combined);

    // チャットルームを作成してユーザーを追加
    await _createChatRoomForApprovedApplication(application, userId);

    return application;
  }

  /// 承認済み申し込みのためのチャットルームを作成
  Future<void> _createChatRoomForApprovedApplication(
    InternshipApplication application,
    String companyUserId,
  ) async {
    try {
      final internship = application.internship;
      final company = internship?.company;

      if (internship == null || company == null) {
        return; // インターンまたは企業情報がない場合はスキップ
      }

      // 既存のチャットルームを確認（同じインターン・ユーザーの組み合わせ）
      // インターン名を含むルーム名で検索
      final roomName = '${internship.title} - インターン参加者';

      // チャットルームを作成
      final roomData = {
        'company_id': company.id,
        'name': roomName,
        'description': '${internship.title}のインターン参加者用チャットルームです',
        'room_type': 'intern',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final roomResponse = await _supabase
          .from('chat_rooms')
          .insert(roomData)
          .select()
          .single();

      final roomId = roomResponse['id'] as String;

      // メンバーを追加（企業ユーザーとインターン参加者）
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
    } catch (e) {
      // チャットルーム作成に失敗しても承認自体は成功させる
      print('チャットルーム作成エラー（承認は成功）: $e');
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
  }

  /// 申し込み数を取得（ステータス別）
  Future<Map<String, int>> getApplicationCounts(String internshipId) async {
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
  }
}

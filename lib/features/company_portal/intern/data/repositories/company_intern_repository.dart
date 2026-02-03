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

    print('=== 承認処理開始 ===');
    print('applicationId: $applicationId');
    print('companyUserId: $userId');

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

    print('=== DB更新完了 ===');
    print('appResponse: $appResponse');

    // インターンシップ情報を取得（companies情報含む）
    final internshipData = await _supabase
        .from('internships')
        .select('*, companies(*)')
        .eq('id', appResponse['internship_id'])
        .single();

    print('=== インターンシップ取得完了 ===');
    print('internshipData: $internshipData');
    print('internshipData[companies]: ${internshipData['companies']}');

    // プロフィール情報を取得
    final profileData = await _supabase
        .from('profiles')
        .select('*')
        .eq('id', appResponse['user_id'])
        .maybeSingle();

    print('=== プロフィール取得完了 ===');
    print('profileData: $profileData');

    // 結合（internshipsキーとprofilesキーで設定）
    final combined = Map<String, dynamic>.from(appResponse as Map);
    combined['internships'] = internshipData;
    combined['profiles'] = profileData;

    print('=== combined作成完了 ===');
    print('combined keys: ${combined.keys.toList()}');

    final application = InternshipApplication.fromJson(combined);

    print('=== InternshipApplication作成完了 ===');
    print('application.internship: ${application.internship}');
    print('application.internship?.title: ${application.internship?.title}');
    print('application.internship?.company: ${application.internship?.company}');
    print('application.internship?.company?.name: ${application.internship?.company?.name}');

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
      print('');
      print('========================================');
      print('=== チャットルーム作成開始 ===');
      print('========================================');
      print('application.id: ${application.id}');
      print('application.userId: ${application.userId}');
      print('companyUserId: $companyUserId');

      final internship = application.internship;
      print('internship: $internship');

      if (internship == null) {
        print('');
        print('❌❌❌ エラー: internship が null です ❌❌❌');
        print('application.internshipId: ${application.internshipId}');
        print('これは InternshipApplication.fromJson で internships キーが見つからなかったことを意味します');
        return;
      }

      final company = internship.company;
      print('company: $company');

      if (company == null) {
        print('');
        print('❌❌❌ エラー: company が null です ❌❌❌');
        print('internship.companyId: ${internship.companyId}');
        print('これは Internship.fromJson で companies キーが見つからなかったことを意味します');
        return;
      }

      print('');
      print('✅ データ検証OK');
      print('インターン名: ${internship.title}');
      print('企業名: ${company.name}');
      print('企業ID: ${company.id}');

      // 既存のチャットルームを確認
      print('');
      print('=== 既存ルームチェック開始 ===');
      final existingRooms = await _supabase
          .from('chat_rooms')
          .select('id, name')
          .eq('company_id', company.id)
          .eq('room_type', 'intern');

      print('既存のインターンルーム数: ${(existingRooms as List).length}');

      // 重複チェック
      for (final room in existingRooms) {
        final roomId = room['id'] as String;
        final roomName = room['name'] as String;
        print('チェック中: $roomName ($roomId)');

        if (!roomName.contains(internship.title)) {
          print('  → インターン名が含まれていないのでスキップ');
          continue;
        }

        final members = await _supabase
            .from('chat_room_members')
            .select('profile_id')
            .eq('room_id', roomId);

        final memberIds = (members as List)
            .map((m) => m['profile_id'] as String)
            .toSet();

        print('  → メンバー数: ${memberIds.length}');

        if (memberIds.contains(application.userId)) {
          print('');
          print('⚠️ 既存のチャットルームが見つかりました');
          print('roomId: $roomId');
          print('roomName: $roomName');
          print('=== チャットルーム作成スキップ（重複防止） ===');
          return;
        }
      }

      // 新規チャットルームを作成
      final userName = application.userProfile?.nickname ?? 'インターン参加者';
      final roomName = '${internship.title} - $userName';

      print('');
      print('=== 新規チャットルーム作成 ===');
      print('ルーム名: $roomName');

      final roomData = {
        'company_id': company.id,
        'name': roomName,
        'description': '${internship.title}のインターン参加者用チャットルームです',
        'room_type': 'intern',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('roomData: $roomData');

      final roomResponse = await _supabase
          .from('chat_rooms')
          .insert(roomData)
          .select()
          .single();

      final roomId = roomResponse['id'] as String;
      print('✅ チャットルーム作成成功: $roomId');

      // メンバーを追加
      print('');
      print('=== メンバー追加 ===');
      final members = [
        {'room_id': roomId, 'profile_id': companyUserId},
        {'room_id': roomId, 'profile_id': application.userId},
      ];
      print('追加するメンバー: $members');

      await _supabase.from('chat_room_members').insert(members);
      print('✅ メンバー追加成功');

      // システムメッセージを送信
      print('');
      print('=== システムメッセージ送信 ===');
      await _supabase.from('chat_messages').insert({
        'room_id': roomId,
        'profile_id': companyUserId,
        'content': 'インターン「${internship.title}」への参加が承認されました。このチャットでやり取りを行ってください。',
        'created_at': DateTime.now().toIso8601String(),
      });
      print('✅ システムメッセージ送信成功');

      print('');
      print('========================================');
      print('=== チャットルーム作成完了 ===');
      print('========================================');
      print('');
    } catch (e, st) {
      print('');
      print('❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌');
      print('チャットルーム作成でエラーが発生しました');
      print('エラー: $e');
      print('スタックトレース: $st');
      print('❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌');
      print('');
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

// company_portal/job/data/repositories/company_job_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:numbers/features/user/job/domain/models/job.dart';
import 'package:numbers/features/user/job/domain/models/job_application.dart';

class CompanyJobRepository {
  final SupabaseClient _supabase;

  CompanyJobRepository(this._supabase);

  // ========== 求人CRUD ==========

  /// 企業の求人一覧を取得
  Future<List<Job>> getCompanyJobs() async {
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
        .from('jobs')
        .select('*, companies(*)')
        .eq('company_id', companyId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Job.fromJson(json))
        .toList();
  }

  /// 求人を投稿
  Future<Job> createJob({
    required String title,
    required String description,
    String? salary,
    String? location,
    String? jobType,
    String? jobCategory,
    String? workingHours,
    int? salaryMin,
    int? salaryMax,
    String status = 'open',
    double? latitude,
    double? longitude,
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

    final insertData = <String, dynamic>{
      'company_id': companyId,
      'title': title,
      'description': description,
      'status': status,
    };

    if (salary != null) insertData['salary'] = salary;
    if (location != null) insertData['location_text'] = location;
    if (jobType != null) insertData['job_type'] = jobType;
    if (jobCategory != null) insertData['job_category'] = jobCategory;
    if (workingHours != null) insertData['working_hours'] = workingHours;
    if (salaryMin != null) insertData['salary_min'] = salaryMin;
    if (salaryMax != null) insertData['salary_max'] = salaryMax;
    if (latitude != null) insertData['latitude'] = latitude;
    if (longitude != null) insertData['longitude'] = longitude;

    final response = await _supabase
        .from('jobs')
        .insert(insertData)
        .select('*, companies(*)')
        .single();

    return Job.fromJson(response);
  }

  /// 求人を更新
  Future<Job> updateJob({
    required String jobId,
    String? title,
    String? description,
    String? salary,
    String? location,
    String? jobType,
    String? jobCategory,
    String? workingHours,
    int? salaryMin,
    int? salaryMax,
    String? status,
    double? latitude,
    double? longitude,
  }) async {
    final updateData = <String, dynamic>{};

    if (title != null) updateData['title'] = title;
    if (description != null) updateData['description'] = description;
    if (salary != null) updateData['salary'] = salary;
    if (location != null) updateData['location_text'] = location;
    if (jobType != null) updateData['job_type'] = jobType;
    if (jobCategory != null) updateData['job_category'] = jobCategory;
    if (workingHours != null) updateData['working_hours'] = workingHours;
    if (salaryMin != null) updateData['salary_min'] = salaryMin;
    if (salaryMax != null) updateData['salary_max'] = salaryMax;
    if (status != null) updateData['status'] = status;
    if (latitude != null) updateData['latitude'] = latitude;
    if (longitude != null) updateData['longitude'] = longitude;

    final response = await _supabase
        .from('jobs')
        .update(updateData)
        .eq('id', jobId)
        .select('*, companies(*)')
        .single();

    return Job.fromJson(response);
  }

  /// 求人を削除
  Future<void> deleteJob(String jobId) async {
    await _supabase.from('jobs').delete().eq('id', jobId);
  }

  /// 求人詳細を取得
  Future<Job?> getJob(String jobId) async {
    final response = await _supabase
        .from('jobs')
        .select('*, companies(*)')
        .eq('id', jobId)
        .maybeSingle();

    if (response == null) return null;
    return Job.fromJson(response);
  }

  // ========== 申し込み管理 ==========

  /// 求人への申し込み一覧を取得
  Future<List<JobApplication>> getApplicationsForJob(
    String jobId,
  ) async {
    try {
      print('=== 求人申し込み一覧取得開始 ===');
      print('jobId: $jobId');

      // まず申し込み一覧を取得
      final applications = await _supabase
          .from('job_applications')
          .select('*')
          .eq('job_id', jobId)
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
          .map((json) => JobApplication.fromJson(json))
          .toList();
    } catch (e, st) {
      print('=== 求人申し込み一覧取得エラー ===');
      print('エラー: $e');
      print('スタックトレース: $st');
      rethrow;
    }
  }

  /// 全求人の申し込み一覧を取得
  Future<List<JobApplication>> getAllApplications() async {
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

    // 自社求人を取得
    final jobs = await _supabase
        .from('jobs')
        .select('*, companies(*)')
        .eq('company_id', companyId);

    final jobsMap = <String, Map<String, dynamic>>{};
    final jobIds = <String>[];
    for (final job in jobs as List) {
      final id = job['id'] as String;
      jobIds.add(id);
      jobsMap[id] = job;
    }

    if (jobIds.isEmpty) {
      return [];
    }

    // 申し込みを取得
    final applications = await _supabase
        .from('job_applications')
        .select('*')
        .inFilter('job_id', jobIds)
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

    // 申し込みに求人とプロフィールを結合
    final result = (applications as List).map((app) {
      final appUserId = app['user_id'] as String;
      final jobId = app['job_id'] as String;
      return <String, dynamic>{
        ...Map<String, dynamic>.from(app as Map),
        'jobs': jobsMap[jobId],
        'profiles': profilesMap[appUserId],
      };
    }).toList();

    return result
        .map((json) => JobApplication.fromJson(json))
        .toList();
  }

  /// 申し込みを承認してチャットを解放
  Future<JobApplication> approveApplication(String applicationId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('ログインが必要です');
    }

    print('=== 求人承認処理開始 ===');
    print('applicationId: $applicationId');
    print('companyUserId: $userId');

    // 申し込みを承認
    final appResponse = await _supabase
        .from('job_applications')
        .update({
          'status': 'accepted',
          'reviewed_at': DateTime.now().toIso8601String(),
          'reviewed_by': userId,
        })
        .eq('id', applicationId)
        .select('*')
        .single();

    print('=== DB更新完了 ===');
    print('appResponse: $appResponse');

    // 求人情報を取得（companies情報含む）
    final jobData = await _supabase
        .from('jobs')
        .select('*, companies(*)')
        .eq('id', appResponse['job_id'])
        .single();

    print('=== 求人取得完了 ===');
    print('jobData: $jobData');
    print('jobData[companies]: ${jobData['companies']}');

    // プロフィール情報を取得
    final profileData = await _supabase
        .from('profiles')
        .select('*')
        .eq('id', appResponse['user_id'])
        .maybeSingle();

    print('=== プロフィール取得完了 ===');
    print('profileData: $profileData');

    // 結合（jobsキーとprofilesキーで設定）
    final combined = Map<String, dynamic>.from(appResponse as Map);
    combined['jobs'] = jobData;
    combined['profiles'] = profileData;

    print('=== combined作成完了 ===');
    print('combined keys: ${combined.keys.toList()}');

    final application = JobApplication.fromJson(combined);

    print('=== JobApplication作成完了 ===');
    print('application.job: ${application.job}');
    print('application.job?.title: ${application.job?.title}');
    print('application.job?.company: ${application.job?.company}');
    print('application.job?.company?.name: ${application.job?.company?.name}');

    // チャットルームを作成してユーザーを追加
    await _createChatRoomForApprovedApplication(application, userId);

    return application;
  }

  /// 承認済み申し込みのためのチャットルームを作成
  Future<void> _createChatRoomForApprovedApplication(
    JobApplication application,
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

      final job = application.job;
      print('job: $job');

      if (job == null) {
        print('');
        print('エラー: job が null です');
        print('application.jobId: ${application.jobId}');
        print('これは JobApplication.fromJson で jobs キーが見つからなかったことを意味します');
        return;
      }

      final company = job.company;
      print('company: $company');

      if (company == null) {
        print('');
        print('エラー: company が null です');
        print('job.companyId: ${job.companyId}');
        print('これは Job.fromJson で companies キーが見つからなかったことを意味します');
        return;
      }

      print('');
      print('データ検証OK');
      print('求人名: ${job.title}');
      print('企業名: ${company.name}');
      print('企業ID: ${company.id}');

      // 既存のチャットルームを確認
      print('');
      print('=== 既存ルームチェック開始 ===');
      final existingRooms = await _supabase
          .from('chat_rooms')
          .select('id, name')
          .eq('company_id', company.id)
          .eq('room_type', 'direct');

      print('既存の求人ルーム数: ${(existingRooms as List).length}');

      // 重複チェック
      for (final room in existingRooms) {
        final roomId = room['id'] as String;
        final roomName = room['name'] as String;
        print('チェック中: $roomName ($roomId)');

        if (!roomName.contains(job.title)) {
          print('  → 求人名が含まれていないのでスキップ');
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
          print('既存のチャットルームが見つかりました');
          print('roomId: $roomId');
          print('roomName: $roomName');
          print('=== チャットルーム作成スキップ（重複防止） ===');
          return;
        }
      }

      // 新規チャットルームを作成
      final userName = application.userProfile?.nickname ?? '求人応募者';
      final roomName = '${job.title} - $userName';

      print('');
      print('=== 新規チャットルーム作成 ===');
      print('ルーム名: $roomName');

      final roomData = {
        'company_id': company.id,
        'name': roomName,
        'description': '${job.title}の求人応募が承認されました。こちらでやり取りを行ってください。',
        'room_type': 'direct',
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
      print('チャットルーム作成成功: $roomId');

      // メンバーを追加
      print('');
      print('=== メンバー追加 ===');
      final membersList = [
        {'room_id': roomId, 'profile_id': companyUserId},
        {'room_id': roomId, 'profile_id': application.userId},
      ];
      print('追加するメンバー: $membersList');

      await _supabase.from('chat_room_members').insert(membersList);
      print('メンバー追加成功');

      // システムメッセージを送信
      print('');
      print('=== システムメッセージ送信 ===');
      await _supabase.from('chat_messages').insert({
        'room_id': roomId,
        'profile_id': companyUserId,
        'content': '求人「${job.title}」への応募が承認されました。このチャットでやり取りを行ってください。',
        'created_at': DateTime.now().toIso8601String(),
      });
      print('システムメッセージ送信成功');

      print('');
      print('========================================');
      print('=== チャットルーム作成完了 ===');
      print('========================================');
      print('');
    } catch (e, st) {
      print('');
      print('チャットルーム作成でエラーが発生しました');
      print('エラー: $e');
      print('スタックトレース: $st');
      // エラーを再スローしない（承認自体は成功させる）
    }
  }

  /// 申し込みを却下
  Future<JobApplication> rejectApplication(
    String applicationId, {
    String? reason,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('ログインが必要です');
    }

    final appResponse = await _supabase
        .from('job_applications')
        .update({
          'status': 'rejected',
          'reviewed_at': DateTime.now().toIso8601String(),
          'reviewed_by': userId,
          'rejection_reason': reason,
        })
        .eq('id', applicationId)
        .select('*')
        .single();

    // 求人情報を取得
    final jobData = await _supabase
        .from('jobs')
        .select('*, companies(*)')
        .eq('id', appResponse['job_id'])
        .single();

    // プロフィール情報を取得
    final profileData = await _supabase
        .from('profiles')
        .select('*')
        .eq('id', appResponse['user_id'])
        .maybeSingle();

    // 結合
    final combined = {
      ...appResponse,
      'jobs': jobData,
      'profiles': profileData,
    };

    return JobApplication.fromJson(combined);
  }

  /// 申し込み数を取得（ステータス別）
  Future<Map<String, int>> getApplicationCounts(String jobId) async {
    final response = await _supabase
        .from('job_applications')
        .select('status')
        .eq('job_id', jobId);

    final counts = <String, int>{
      'pending': 0,
      'approved': 0,
      'rejected': 0,
      'total': 0,
    };

    for (final app in response as List) {
      final status = app['status'] as String;
      // DB値 → 表示用キーにマッピング
      final key = (status == 'applied') ? 'pending'
          : (status == 'accepted') ? 'approved'
          : status;
      counts[key] = (counts[key] ?? 0) + 1;
      counts['total'] = (counts['total'] ?? 0) + 1;
    }

    return counts;
  }
}

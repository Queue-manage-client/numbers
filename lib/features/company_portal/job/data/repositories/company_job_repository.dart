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
          .from('jobs')
          .select('*, companies(*)')
          .eq('company_id', companyId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Job.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
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
    } catch (e) {
      rethrow;
    }
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
    try {
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
    } catch (e) {
      rethrow;
    }
  }

  /// 求人を削除
  Future<void> deleteJob(String jobId) async {
    try {
      await _supabase.from('jobs').delete().eq('id', jobId);
    } catch (e) {
      rethrow;
    }
  }

  /// 求人詳細を取得
  Future<Job?> getJob(String jobId) async {
    try {
      final response = await _supabase
          .from('jobs')
          .select('*, companies(*)')
          .eq('id', jobId)
          .maybeSingle();

      if (response == null) return null;
      return Job.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // ========== 申し込み管理 ==========

  /// 求人への申し込み一覧を取得
  Future<List<JobApplication>> getApplicationsForJob(
    String jobId,
  ) async {
    try {
      // まず申し込み一覧を取得
      final applications = await _supabase
          .from('job_applications')
          .select('*')
          .eq('job_id', jobId)
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
          .map((json) => JobApplication.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// 全求人の申し込み一覧を取得
  Future<List<JobApplication>> getAllApplications() async {
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
    } catch (e) {
      rethrow;
    }
  }

  /// 申し込みを承認してチャットを解放
  Future<JobApplication> approveApplication(String applicationId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('ログインが必要です');
    }

    try {
      // 申し込みを承認
      final appResponse = await _supabase
          .from('job_applications')
          .update({
            'status': 'approved',
            'reviewed_at': DateTime.now().toIso8601String(),
            'reviewed_by': userId,
          })
          .eq('id', applicationId)
          .select('*')
          .single();

      // 求人情報を取得（companies情報含む）
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

      // 結合（jobsキーとprofilesキーで設定）
      final combined = Map<String, dynamic>.from(appResponse as Map);
      combined['jobs'] = jobData;
      combined['profiles'] = profileData;

      final application = JobApplication.fromJson(combined);

      // チャットルームを作成してユーザーを追加
      await _createChatRoomForApprovedApplication(application, userId);

      return application;
    } catch (e) {
      rethrow;
    }
  }

  /// 承認済み申し込みのためのチャットルームを作成
  Future<void> _createChatRoomForApprovedApplication(
    JobApplication application,
    String companyUserId,
  ) async {
    try {
      final job = application.job;

      if (job == null) {
        return;
      }

      final company = job.company;

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

        if (!roomName.contains(job.title)) {
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
      final userName = application.userProfile?.nickname ?? '求人応募者';
      final roomName = '${job.title} - $userName';

      final roomData = {
        'company_id': company.id,
        'name': roomName,
        'description': '${job.title}の求人応募が承認されました。こちらでやり取りを行ってください。',
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
      final membersList = [
        {'room_id': roomId, 'profile_id': companyUserId},
        {'room_id': roomId, 'profile_id': application.userId},
      ];

      await _supabase.from('chat_room_members').insert(membersList);

      // システムメッセージを送信
      await _supabase.from('chat_messages').insert({
        'room_id': roomId,
        'profile_id': companyUserId,
        'content': '求人「${job.title}」への応募が承認されました。このチャットでやり取りを行ってください。',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
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

    try {
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
    } catch (e) {
      rethrow;
    }
  }

  /// 申し込み数を取得（ステータス別）
  Future<Map<String, int>> getApplicationCounts(String jobId) async {
    try {
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
        // DB値がそのままキーに対応（統一済み）
        counts[status] = (counts[status] ?? 0) + 1;
        counts['total'] = (counts['total'] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      rethrow;
    }
  }
}

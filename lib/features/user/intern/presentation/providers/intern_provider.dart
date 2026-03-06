// intern/presentation/providers/intern_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/features/user/intern/data/repositories/intern_repository.dart';
import 'package:numbers/features/user/intern/domain/models/internship_application.dart';

final internRepositoryProvider = Provider<InternRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return InternRepository(supabase);
});

final internshipsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // デモ用モックデータ
  return _mockInternships;
});

const List<Map<String, dynamic>> _mockInternships = [
  {
    'id': 'mock-intern-1',
    'title': '【夏季】Webアプリ開発インターン（2週間）',
    'start_date': '2026-08-01',
    'end_date': '2026-08-14',
    'tags': ['Flutter', 'Firebase', 'チーム開発'],
    'companies': {
      'name': 'ブライトウェーブ',
      'industry': 'IT',
    },
  },
  {
    'id': 'mock-intern-2',
    'title': 'データ分析・AIエンジニアインターン',
    'start_date': '2026-07-15',
    'end_date': '2026-08-31',
    'tags': ['Python', '機械学習', 'データ分析'],
    'companies': {
      'name': 'ネクストビジョンテクノロジーズ',
      'industry': 'IT',
    },
  },
  {
    'id': 'mock-intern-3',
    'title': '法人営業体験インターン（5日間）',
    'start_date': '2026-09-01',
    'end_date': '2026-09-05',
    'tags': ['営業', 'ビジネス', 'プレゼン'],
    'companies': {
      'name': '東洋キャピタル信託銀行',
      'industry': '金融',
    },
  },
  {
    'id': 'mock-intern-4',
    'title': 'UI/UXデザインインターン',
    'start_date': '2026-08-18',
    'end_date': '2026-09-12',
    'tags': ['Figma', 'デザイン', 'ユーザーリサーチ'],
    'companies': {
      'name': 'クロスフィールド',
      'industry': 'IT',
    },
  },
  {
    'id': 'mock-intern-5',
    'title': '施工管理体験インターン（3日間）',
    'start_date': '2026-08-25',
    'end_date': '2026-08-27',
    'tags': ['施工管理', '現場体験', 'ものづくり'],
    'companies': {
      'name': '三栄建設工業',
      'industry': '建築・土木',
    },
  },
  {
    'id': 'mock-intern-6',
    'title': 'バックエンドエンジニアインターン',
    'start_date': '2026-07-01',
    'end_date': '2026-08-31',
    'tags': ['Go', 'AWS', 'マイクロサービス'],
    'companies': {
      'name': 'スカイラボ',
      'industry': 'IT',
    },
  },
  {
    'id': 'mock-intern-7',
    'title': '商品企画・マーケティングインターン',
    'start_date': '2026-08-04',
    'end_date': '2026-08-08',
    'tags': ['マーケティング', '企画', '分析'],
    'companies': {
      'name': 'グローバルスタイルホールディングス',
      'industry': '小売',
    },
  },
  {
    'id': 'mock-intern-8',
    'title': '製品開発エンジニアインターン',
    'start_date': '2026-08-11',
    'end_date': '2026-08-22',
    'tags': ['機械設計', 'CAD', '製品開発'],
    'companies': {
      'name': '旭光精密工業',
      'industry': '製造',
    },
  },
  {
    'id': 'mock-intern-9',
    'title': 'ホテル運営マネジメントインターン',
    'start_date': '2026-09-01',
    'end_date': '2026-09-14',
    'tags': ['ホスピタリティ', '接客', 'マネジメント'],
    'companies': {
      'name': 'リゾートプランニング',
      'industry': 'サービス',
    },
  },
  {
    'id': 'mock-intern-10',
    'title': '医療IT・ヘルスケアインターン',
    'start_date': '2026-08-18',
    'end_date': '2026-08-29',
    'tags': ['ヘルスケア', 'IT', 'アプリ開発'],
    'companies': {
      'name': 'メディカルブリッジ',
      'industry': '医療・福祉',
    },
  },
  {
    'id': 'mock-intern-11',
    'title': 'EdTechプロダクト開発インターン',
    'start_date': '2026-07-21',
    'end_date': '2026-08-15',
    'tags': ['教育', 'React', 'プロダクト開発'],
    'companies': {
      'name': 'ラーニングパス',
      'industry': '教育',
    },
  },
  {
    'id': 'mock-intern-12',
    'title': 'クラウドインフラエンジニアインターン',
    'start_date': '2026-08-01',
    'end_date': '2026-08-28',
    'tags': ['AWS', 'Kubernetes', 'インフラ'],
    'companies': {
      'name': 'アークシステムズ',
      'industry': 'IT',
    },
  },
];

final internshipProvider = FutureProvider.family<Map<String, dynamic>?, String>(
    (ref, internshipId) async {
  final repository = ref.watch(internRepositoryProvider);
  return await repository.getInternship(internshipId);
});

// ========== 検索・フィルター関連プロバイダー ==========

/// 検索テキスト
final internSearchQueryProvider = StateProvider<String>((ref) => '');

/// 業種フィルター（null = 全て）
final internIndustryFilterProvider = StateProvider<String?>((ref) => null);

/// フィルタリング済みインターン一覧
final filteredInternshipsProvider =
    Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final internshipsAsync = ref.watch(internshipsProvider);
  final query = ref.watch(internSearchQueryProvider).toLowerCase();
  final industry = ref.watch(internIndustryFilterProvider);

  return internshipsAsync.whenData((internships) {
    return internships.where((internship) {
      // テキスト検索
      if (query.isNotEmpty) {
        final title = (internship['title'] as String? ?? '').toLowerCase();
        final company = internship['companies'] as Map<String, dynamic>?;
        final companyName = (company?['name'] as String? ?? '').toLowerCase();
        if (!title.contains(query) && !companyName.contains(query)) {
          return false;
        }
      }

      // 業種フィルター
      if (industry != null) {
        final company = internship['companies'] as Map<String, dynamic>?;
        final companyIndustry = company?['industry'] as String?;
        if (companyIndustry != industry) {
          return false;
        }
      }

      return true;
    }).toList();
  });
});

// ========== 申し込み関連プロバイダー ==========

/// ユーザーの全申し込み一覧
final userApplicationsProvider =
    FutureProvider<List<InternshipApplication>>((ref) async {
  final repository = ref.watch(internRepositoryProvider);
  return await repository.getUserApplications();
});

/// 特定インターンの申し込み状態
final applicationStatusProvider =
    FutureProvider.family<InternshipApplication?, String>(
        (ref, internshipId) async {
  final repository = ref.watch(internRepositoryProvider);
  return await repository.getApplicationStatus(internshipId);
});

/// 申し込み済みかどうか
final hasAppliedProvider =
    FutureProvider.family<bool, String>((ref, internshipId) async {
  final repository = ref.watch(internRepositoryProvider);
  return await repository.hasApplied(internshipId);
});

/// 申し込み処理を行うNotifier
class InternApplicationNotifier extends StateNotifier<AsyncValue<void>> {
  final InternRepository _repository;
  final Ref _ref;

  InternApplicationNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  Future<bool> apply(String internshipId, {String? message}) async {
    state = const AsyncValue.loading();
    try {
      await _repository.applyForInternship(
        internshipId: internshipId,
        message: message,
      );
      state = const AsyncValue.data(null);

      // 関連するプロバイダーを更新
      _ref.invalidate(userApplicationsProvider);
      _ref.invalidate(applicationStatusProvider(internshipId));
      _ref.invalidate(hasAppliedProvider(internshipId));

      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> cancel(String applicationId, String internshipId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.cancelApplication(applicationId);
      state = const AsyncValue.data(null);

      // 関連するプロバイダーを更新
      _ref.invalidate(userApplicationsProvider);
      _ref.invalidate(applicationStatusProvider(internshipId));
      _ref.invalidate(hasAppliedProvider(internshipId));

      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final internApplicationNotifierProvider =
    StateNotifierProvider<InternApplicationNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(internRepositoryProvider);
  return InternApplicationNotifier(repository, ref);
});

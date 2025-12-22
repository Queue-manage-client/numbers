// company/presentation/providers/company_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/features/user/company/data/repositories/company_repository.dart';

final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return CompanyRepository(supabase);
});

final companyProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, companyId) async {
  final repository = ref.watch(companyRepositoryProvider);
  return await repository.getCompany(companyId);
});

final companyVideosProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, companyId) async {
  final repository = ref.watch(companyRepositoryProvider);
  return await repository.getCompanyVideos(companyId);
});

final companyJobsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, companyId) async {
  final repository = ref.watch(companyRepositoryProvider);
  return await repository.getCompanyJobs(companyId);
});

final companyInternshipsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, companyId) async {
  final repository = ref.watch(companyRepositoryProvider);
  return await repository.getCompanyInternships(companyId);
});

// フィード用：全企業の公開動画を取得
final feedVideosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(companyRepositoryProvider);
  return await repository.getAllPublicVideos();
});

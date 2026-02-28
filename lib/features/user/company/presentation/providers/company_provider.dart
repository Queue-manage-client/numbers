// company/presentation/providers/company_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final videos = await repository.getCompanyVideos(companyId);
  final supabase = Supabase.instance.client;

  // Enrich with signed URLs for private storage buckets
  final enriched = videos.map((v) => Map<String, dynamic>.from(v)).toList();
  await Future.wait(enriched.map((video) async {
    final videoPath = video['video_path'] as String?;
    final thumbnailPath = video['thumbnail_path'] as String?;

    if (videoPath != null && videoPath.isNotEmpty) {
      try {
        video['video_url'] = videoPath.startsWith('http')
            ? videoPath
            : await supabase.storage
                .from('company-videos')
                .createSignedUrl(videoPath, 3600);
      } catch (e) {
        video['video_url'] = '';
      }
    }

    if (thumbnailPath != null && thumbnailPath.isNotEmpty) {
      try {
        video['thumbnail_url'] = thumbnailPath.startsWith('http')
            ? thumbnailPath
            : await supabase.storage
                .from('company-thumbnails')
                .createSignedUrl(thumbnailPath, 3600);
      } catch (e) {
        video['thumbnail_url'] = '';
      }
    }
  }));

  return enriched;
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

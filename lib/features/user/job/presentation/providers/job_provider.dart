// job/presentation/providers/job_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/features/user/job/data/repositories/job_repository.dart';

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return JobRepository(supabase);
});

final jobsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(jobRepositoryProvider);
  return await repository.getJobs();
});

final jobProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, jobId) async {
  final repository = ref.watch(jobRepositoryProvider);
  return await repository.getJob(jobId);
});

final applicationsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final repository = ref.watch(jobRepositoryProvider);
  return await repository.getApplications(user.id);
});

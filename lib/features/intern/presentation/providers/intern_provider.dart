import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/features/intern/data/repositories/intern_repository.dart';

final internRepositoryProvider = Provider<InternRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return InternRepository(supabase);
});

final internshipsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(internRepositoryProvider);
  return await repository.getInternships();
});

final internshipProvider = FutureProvider.family<Map<String, dynamic>?, String>(
    (ref, internshipId) async {
  final repository = ref.watch(internRepositoryProvider);
  return await repository.getInternship(internshipId);
});

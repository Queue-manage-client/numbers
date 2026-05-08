import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/admin_plan_application_repository.dart';

final adminPlanApplicationRepositoryProvider =
    Provider<AdminPlanApplicationRepository>((ref) {
  return AdminPlanApplicationRepository(Supabase.instance.client);
});

final adminPlanApplicationFilterProvider = StateProvider<String?>((ref) => 'pending');

final adminPlanApplicationsProvider =
    FutureProvider<List<AdminPlanApplicationRow>>((ref) async {
  final repo = ref.watch(adminPlanApplicationRepositoryProvider);
  final filter = ref.watch(adminPlanApplicationFilterProvider);
  return repo.fetchApplications(statusFilter: filter);
});

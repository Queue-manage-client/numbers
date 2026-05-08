import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/subscription_repository.dart';
import '../../domain/entities/plan_application.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/entities/subscription_status.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(ref.watch(supabaseClientProvider));
});

/// 自社サブスク状態
final currentCompanySubscriptionProvider =
    FutureProvider<CompanySubscription?>((ref) async {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.fetchCurrentCompanySubscription();
});

/// 加入可能なプラン一覧 (eligible_plan_codes に応じてフィルタ)
final availablePlansProvider =
    FutureProvider<List<SubscriptionPlan>>((ref) async {
  final repo = ref.watch(subscriptionRepositoryProvider);
  final sub = await ref.watch(currentCompanySubscriptionProvider.future);
  final eligible = sub?.eligiblePlanCodes ?? const <String>[];
  return repo.fetchPlans(includeApprovalCodes: eligible);
});

/// 自社の申請履歴
final ownPlanApplicationsProvider =
    FutureProvider<List<PlanApplication>>((ref) async {
  final sub = await ref.watch(currentCompanySubscriptionProvider.future);
  if (sub == null) return const [];
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.fetchOwnApplications(sub.companyId);
});

/// 投稿可否ヘルパー
final canPostProvider = Provider<bool>((ref) {
  final sub = ref.watch(currentCompanySubscriptionProvider).valueOrNull;
  return sub?.canPost ?? false;
});

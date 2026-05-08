import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/plan_application.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/entities/subscription_status.dart';
import '../../domain/enums/billing_cycle.dart';

class SubscriptionRepository {
  SubscriptionRepository(this._client);

  final SupabaseClient _client;

  Future<CompanySubscription?> fetchCurrentCompanySubscription() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    // profiles.company_id 経由で対象企業を取得
    final profile = await _client
        .from('profiles')
        .select('company_id')
        .eq('id', user.id)
        .maybeSingle();
    final companyId = profile?['company_id'] as String?;
    if (companyId == null) return null;

    final row = await _client
        .from('companies')
        .select(
          'id, approval_status, subscription_status, current_plan_code, '
          'current_billing_cycle, current_period_end, cancel_at_period_end, '
          'eligible_plan_codes, stripe_customer_id',
        )
        .eq('id', companyId)
        .maybeSingle();

    if (row == null) return null;
    return CompanySubscription.fromMap(row);
  }

  Future<List<SubscriptionPlan>> fetchPlans({
    List<String> includeApprovalCodes = const [],
  }) async {
    final rows = await _client
        .from('subscription_plans')
        .select(
          'code, name, monthly_amount, yearly_amount, '
          'requires_approval, is_public, display_order',
        )
        .order('display_order', ascending: true);

    final plans =
        rows.map((row) => SubscriptionPlan.fromMap(row)).toList();
    return plans
        .where(
          (p) => p.isPublic || includeApprovalCodes.contains(p.code),
        )
        .toList();
  }

  Future<String> createCheckoutSessionUrl({
    required String planCode,
    required BillingCycle billingCycle,
  }) async {
    final response = await _client.functions.invoke(
      'create-checkout-session',
      body: {
        'plan_code': planCode,
        'billing_cycle': billingCycle.apiValue,
      },
    );
    if (response.status != 200) {
      throw Exception(
        'Failed to create checkout session: ${response.data}',
      );
    }
    final data = response.data as Map<String, dynamic>;
    return data['url'] as String;
  }

  Future<String> createPortalSessionUrl() async {
    final response = await _client.functions.invoke(
      'create-portal-session',
    );
    if (response.status != 200) {
      throw Exception(
        'Failed to create portal session: ${response.data}',
      );
    }
    final data = response.data as Map<String, dynamic>;
    return data['url'] as String;
  }

  Future<List<PlanApplication>> fetchOwnApplications(
    String companyId,
  ) async {
    final rows = await _client
        .from('plan_applications')
        .select(
          'id, company_id, requested_plan_code, status, evidence_url, '
          'applicant_note, rejection_reason, reviewed_at, created_at',
        )
        .eq('company_id', companyId)
        .order('created_at', ascending: false);

    return rows.map((row) => PlanApplication.fromMap(row)).toList();
  }

  Future<void> submitPlanApplication({
    required String companyId,
    required String planCode,
    required String? evidenceUrl,
    required String? applicantNote,
  }) async {
    await _client.from('plan_applications').insert({
      'company_id': companyId,
      'requested_plan_code': planCode,
      'evidence_url': evidenceUrl,
      'applicant_note': applicantNote,
    });
  }
}

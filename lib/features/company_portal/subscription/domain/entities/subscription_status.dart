class CompanySubscription {
  const CompanySubscription({
    required this.companyId,
    required this.approvalStatus,
    required this.subscriptionStatus,
    required this.currentPlanCode,
    required this.currentBillingCycle,
    required this.currentPeriodEnd,
    required this.cancelAtPeriodEnd,
    required this.eligiblePlanCodes,
    required this.hasStripeCustomer,
  });

  final String companyId;
  final String? approvalStatus;
  final String? subscriptionStatus;
  final String? currentPlanCode;
  final String? currentBillingCycle;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;
  final List<String> eligiblePlanCodes;
  final bool hasStripeCustomer;

  bool get isApproved => approvalStatus == 'approved';

  bool get isActive =>
      subscriptionStatus == 'active' || subscriptionStatus == 'trialing';

  bool get isPastDue => subscriptionStatus == 'past_due';

  bool get canPost => isApproved && isActive;

  factory CompanySubscription.fromMap(Map<String, dynamic> map) {
    final eligible = map['eligible_plan_codes'];
    return CompanySubscription(
      companyId: map['id'] as String,
      approvalStatus: map['approval_status'] as String?,
      subscriptionStatus: map['subscription_status'] as String?,
      currentPlanCode: map['current_plan_code'] as String?,
      currentBillingCycle: map['current_billing_cycle'] as String?,
      currentPeriodEnd: _parseDate(map['current_period_end']),
      cancelAtPeriodEnd: map['cancel_at_period_end'] as bool? ?? false,
      eligiblePlanCodes: eligible is List
          ? List<String>.from(eligible)
          : const <String>[],
      hasStripeCustomer: map['stripe_customer_id'] != null,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

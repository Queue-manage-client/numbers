class SubscriptionPlan {
  const SubscriptionPlan({
    required this.code,
    required this.name,
    required this.monthlyAmount,
    required this.yearlyAmount,
    required this.requiresApproval,
    required this.isPublic,
    required this.displayOrder,
  });

  final String code;
  final String name;
  final int monthlyAmount;
  final int? yearlyAmount;
  final bool requiresApproval;
  final bool isPublic;
  final int displayOrder;

  factory SubscriptionPlan.fromMap(Map<String, dynamic> map) {
    return SubscriptionPlan(
      code: map['code'] as String,
      name: map['name'] as String,
      monthlyAmount: map['monthly_amount'] as int,
      yearlyAmount: map['yearly_amount'] as int?,
      requiresApproval: map['requires_approval'] as bool? ?? false,
      isPublic: map['is_public'] as bool? ?? true,
      displayOrder: map['display_order'] as int? ?? 0,
    );
  }
}

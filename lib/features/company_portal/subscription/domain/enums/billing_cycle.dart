enum BillingCycle {
  monthly,
  yearly;

  String get apiValue => switch (this) {
        BillingCycle.monthly => 'monthly',
        BillingCycle.yearly => 'yearly',
      };

  String get label => switch (this) {
        BillingCycle.monthly => '月額',
        BillingCycle.yearly => '年額',
      };
}

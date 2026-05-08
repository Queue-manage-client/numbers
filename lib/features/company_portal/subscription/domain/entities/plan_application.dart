enum PlanApplicationStatus {
  pending,
  approved,
  rejected;

  static PlanApplicationStatus fromString(String value) => switch (value) {
        'approved' => PlanApplicationStatus.approved,
        'rejected' => PlanApplicationStatus.rejected,
        _ => PlanApplicationStatus.pending,
      };

  String get label => switch (this) {
        PlanApplicationStatus.pending => '審査中',
        PlanApplicationStatus.approved => '承認済み',
        PlanApplicationStatus.rejected => '否認',
      };
}

class PlanApplication {
  const PlanApplication({
    required this.id,
    required this.companyId,
    required this.requestedPlanCode,
    required this.status,
    required this.evidenceUrl,
    required this.applicantNote,
    required this.rejectionReason,
    required this.reviewedAt,
    required this.createdAt,
  });

  final String id;
  final String companyId;
  final String requestedPlanCode;
  final PlanApplicationStatus status;
  final String? evidenceUrl;
  final String? applicantNote;
  final String? rejectionReason;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  factory PlanApplication.fromMap(Map<String, dynamic> map) {
    return PlanApplication(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      requestedPlanCode: map['requested_plan_code'] as String,
      status: PlanApplicationStatus.fromString(map['status'] as String),
      evidenceUrl: map['evidence_url'] as String?,
      applicantNote: map['applicant_note'] as String?,
      rejectionReason: map['rejection_reason'] as String?,
      reviewedAt: _parseDate(map['reviewed_at']),
      createdAt: _parseDate(map['created_at']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

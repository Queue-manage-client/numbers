import 'package:supabase_flutter/supabase_flutter.dart';

class AdminPlanApplicationRow {
  const AdminPlanApplicationRow({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.requestedPlanCode,
    required this.status,
    required this.evidenceUrl,
    required this.applicantNote,
    required this.rejectionReason,
    required this.createdAt,
    required this.reviewedAt,
  });

  final String id;
  final String companyId;
  final String? companyName;
  final String requestedPlanCode;
  final String status;
  final String? evidenceUrl;
  final String? applicantNote;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  factory AdminPlanApplicationRow.fromMap(Map<String, dynamic> map) {
    final company = map['companies'] as Map<String, dynamic>?;
    return AdminPlanApplicationRow(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      companyName: company?['name'] as String?,
      requestedPlanCode: map['requested_plan_code'] as String,
      status: map['status'] as String,
      evidenceUrl: map['evidence_url'] as String?,
      applicantNote: map['applicant_note'] as String?,
      rejectionReason: map['rejection_reason'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      reviewedAt: map['reviewed_at'] != null
          ? DateTime.parse(map['reviewed_at'] as String)
          : null,
    );
  }
}

class AdminPlanApplicationRepository {
  AdminPlanApplicationRepository(this._client);

  final SupabaseClient _client;

  Future<List<AdminPlanApplicationRow>> fetchApplications({
    String? statusFilter,
  }) async {
    var query = _client.from('plan_applications').select(
          'id, company_id, requested_plan_code, status, evidence_url, '
          'applicant_note, rejection_reason, created_at, reviewed_at, '
          'companies(name)',
        );
    if (statusFilter != null) {
      query = query.eq('status', statusFilter);
    }
    final rows = await query.order('created_at', ascending: false);
    return rows.map((r) => AdminPlanApplicationRow.fromMap(r)).toList();
  }

  Future<void> approve(String applicationId) async {
    await _client.rpc('approve_plan_application', params: {
      'application_id': applicationId,
    });
  }

  Future<void> reject(String applicationId, String reason) async {
    await _client.rpc('reject_plan_application', params: {
      'application_id': applicationId,
      'reason': reason,
    });
  }
}

// core/domain/models/company.dart
// 共通のCompanyモデル（Job/Intern/Feed等で共有）

enum CompanyApprovalStatus {
  pending,
  approved,
  rejected;

  static CompanyApprovalStatus fromString(String? status) {
    switch (status) {
      case 'approved':
        return CompanyApprovalStatus.approved;
      case 'rejected':
        return CompanyApprovalStatus.rejected;
      case 'pending':
      default:
        return CompanyApprovalStatus.pending;
    }
  }

  String toJson() => name;

  String get displayName {
    switch (this) {
      case CompanyApprovalStatus.pending:
        return '審査待ち';
      case CompanyApprovalStatus.approved:
        return '審査通過';
      case CompanyApprovalStatus.rejected:
        return '審査否認';
    }
  }
}

class Company {
  final String id;
  final String name;
  final String? description;
  final String? address;
  final String? industry;
  final String? website;
  final String? logoUrl;
  final String? catchphrase;
  final String? representativeName;
  final String? phone;
  final bool isSuspended;
  final CompanyApprovalStatus approvalStatus;
  final String? approvalNote;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  Company({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.industry,
    this.website,
    this.logoUrl,
    this.catchphrase,
    this.representativeName,
    this.phone,
    this.isSuspended = false,
    this.approvalStatus = CompanyApprovalStatus.pending,
    this.approvalNote,
    this.reviewedAt,
    this.reviewedBy,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description'] as String?,
      address: json['address'] as String?,
      industry: json['industry'] as String?,
      website: json['website'] as String?,
      logoUrl: json['logo_url'] as String?,
      catchphrase: json['catchphrase'] as String?,
      representativeName: json['representative_name'] as String?,
      phone: json['phone'] as String?,
      isSuspended: json['is_suspended'] as bool? ?? false,
      approvalStatus: CompanyApprovalStatus.fromString(json['approval_status'] as String?),
      approvalNote: json['approval_note'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'].toString())
          : null,
      reviewedBy: json['reviewed_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'industry': industry,
      'website': website,
      'logo_url': logoUrl,
      'catchphrase': catchphrase,
      'representative_name': representativeName,
      'phone': phone,
      'is_suspended': isSuspended,
    };
  }

  bool get isApproved => approvalStatus == CompanyApprovalStatus.approved;
  bool get isPending => approvalStatus == CompanyApprovalStatus.pending;
  bool get isRejected => approvalStatus == CompanyApprovalStatus.rejected;
}

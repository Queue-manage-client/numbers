// job/domain/models/job_application.dart

import 'package:numbers/features/user/intern/domain/models/internship_application.dart';
import 'package:numbers/features/user/job/domain/models/job.dart';

class JobApplication {
  final String id;
  final String jobId;
  final String userId;
  final ApplicationStatus status;
  final DateTime appliedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? message;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // 関連データ
  final Job? job;
  final UserProfile? userProfile;

  JobApplication({
    required this.id,
    required this.jobId,
    required this.userId,
    required this.status,
    required this.appliedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.message,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
    this.job,
    this.userProfile,
  });

  factory JobApplication.fromJson(Map<String, dynamic> json) {
    final appliedAtRaw = json['applied_at'];
    final createdAtRaw = json['created_at'];
    final dateSource = appliedAtRaw ?? createdAtRaw;

    return JobApplication(
      id: json['id'] as String? ?? '',
      jobId: json['job_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      status:
          ApplicationStatus.fromString(json['status'] as String? ?? 'pending'),
      appliedAt: dateSource != null
          ? (DateTime.tryParse(dateSource.toString()) ?? DateTime.now())
          : DateTime.now(),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'].toString())
          : null,
      reviewedBy: json['reviewed_by'] as String?,
      message: json['message'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: createdAtRaw != null
          ? DateTime.tryParse(createdAtRaw.toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      job: json['jobs'] != null && json['jobs'] is Map
          ? Job.fromJson(Map<String, dynamic>.from(json['jobs'] as Map))
          : null,
      userProfile: json['profiles'] != null && json['profiles'] is Map
          ? UserProfile.fromJson(Map<String, dynamic>.from(json['profiles'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_id': jobId,
      'user_id': userId,
      'status': status.toJson(),
      'message': message,
      'rejection_reason': rejectionReason,
    };
  }

  JobApplication copyWith({
    String? id,
    String? jobId,
    String? userId,
    ApplicationStatus? status,
    DateTime? appliedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? message,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    Job? job,
    UserProfile? userProfile,
  }) {
    return JobApplication(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      appliedAt: appliedAt ?? this.appliedAt,
      reviewedAt: reviewedAt,
      reviewedBy: reviewedBy,
      message: message,
      rejectionReason: rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      job: job ?? this.job,
      userProfile: userProfile ?? this.userProfile,
    );
  }
}

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
    return JobApplication(
      id: json['id'] as String? ?? '',
      jobId: json['job_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      status:
          ApplicationStatus.fromString(json['status'] as String? ?? 'pending'),
      appliedAt: json['applied_at'] != null
          ? DateTime.parse(json['applied_at'] as String)
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now()),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      reviewedBy: json['reviewed_by'] as String?,
      message: json['message'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      job: json['jobs'] != null
          ? Job.fromJson(json['jobs'] as Map<String, dynamic>)
          : null,
      userProfile: json['profiles'] != null
          ? UserProfile.fromJson(json['profiles'] as Map<String, dynamic>)
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

// intern/domain/models/internship_application.dart

import 'package:numbers/features/user/intern/domain/models/internship.dart';

enum ApplicationStatus {
  pending,
  approved,
  rejected,
  cancelled;

  static ApplicationStatus fromString(String status) {
    switch (status) {
      case 'pending':
      case 'applied': // レガシー互換
        return ApplicationStatus.pending;
      case 'approved':
      case 'accepted': // レガシー互換
        return ApplicationStatus.approved;
      case 'rejected':
        return ApplicationStatus.rejected;
      case 'cancelled':
        return ApplicationStatus.cancelled;
      default:
        return ApplicationStatus.pending;
    }
  }

  String toJson() => name;

  String get displayName {
    switch (this) {
      case ApplicationStatus.pending:
        return '審査中';
      case ApplicationStatus.approved:
        return '承認済み';
      case ApplicationStatus.rejected:
        return '却下';
      case ApplicationStatus.cancelled:
        return 'キャンセル';
    }
  }
}

class InternshipApplication {
  final String id;
  final String internshipId;
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
  final Internship? internship;
  final UserProfile? userProfile;

  InternshipApplication({
    required this.id,
    required this.internshipId,
    required this.userId,
    required this.status,
    required this.appliedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.message,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
    this.internship,
    this.userProfile,
  });

  factory InternshipApplication.fromJson(Map<String, dynamic> json) {
    final appliedAtRaw = json['applied_at'];
    final createdAtRaw = json['created_at'];
    final dateSource = appliedAtRaw ?? createdAtRaw;

    return InternshipApplication(
      id: json['id'] as String? ?? '',
      internshipId: json['internship_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      status: ApplicationStatus.fromString(json['status'] as String? ?? 'pending'),
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
      internship: json['internships'] != null && json['internships'] is Map
          ? Internship.fromJson(Map<String, dynamic>.from(json['internships'] as Map))
          : null,
      userProfile: json['profiles'] != null && json['profiles'] is Map
          ? UserProfile.fromJson(Map<String, dynamic>.from(json['profiles'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'internship_id': internshipId,
      'user_id': userId,
      'status': status.toJson(),
      'message': message,
      'rejection_reason': rejectionReason,
    };
  }

  InternshipApplication copyWith({
    String? id,
    String? internshipId,
    String? userId,
    ApplicationStatus? status,
    DateTime? appliedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? message,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    Internship? internship,
    UserProfile? userProfile,
  }) {
    return InternshipApplication(
      id: id ?? this.id,
      internshipId: internshipId ?? this.internshipId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      appliedAt: appliedAt ?? this.appliedAt,
      reviewedAt: reviewedAt,
      reviewedBy: reviewedBy,
      message: message,
      rejectionReason: rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      internship: internship ?? this.internship,
      userProfile: userProfile ?? this.userProfile,
    );
  }
}

class UserProfile {
  final String id;
  final String? nickname;
  final String? gender;
  final DateTime? birthDate;
  final String? location;
  final String? university;
  final List<String> skills;
  final String? resumeUrl;
  final String? resumeFileName;

  UserProfile({
    required this.id,
    this.nickname,
    this.gender,
    this.birthDate,
    this.location,
    this.university,
    this.skills = const [],
    this.resumeUrl,
    this.resumeFileName,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      nickname: json['nickname'] as String?,
      gender: json['gender'] as String?,
      birthDate: json['birth_date'] != null
          ? DateTime.tryParse(json['birth_date'].toString())
          : null,
      location: json['location'] as String?,
      university: json['university'] as String?,
      skills: json['skills'] != null && json['skills'] is List
          ? (json['skills'] as List).whereType<String>().toList()
          : [],
      resumeUrl: json['resume_url'] as String?,
      resumeFileName: json['resume_file_name'] as String?,
    );
  }
}

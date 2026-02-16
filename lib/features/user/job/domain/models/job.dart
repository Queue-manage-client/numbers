// job/domain/models/job.dart

import 'package:numbers/features/user/intern/domain/models/internship.dart';

class JobCategory {
  static const String office = '事務・管理';
  static const String sales = '営業';
  static const String engineer = 'エンジニア';
  static const String marketing = 'マーケティング';
  static const String design = 'デザイン';
  static const String service = 'サービス・接客';
  static const String other = 'その他';

  static List<String> get all =>
      [office, sales, engineer, marketing, design, service, other];
}

class Job {
  final String id;
  final String companyId;
  final String title;
  final String description;
  final String? salary;
  final String? location;
  final String status; // 'open' / 'closed'
  final String? jobType; // 'part_time','full_time','new_grad','mid_career'
  final String? jobCategory; // '事務・管理', '営業', etc.
  final String? workingHours; // '9:00~18:00' etc.
  final int? salaryMin; // in 万円
  final int? salaryMax; // in 万円
  final double? latitude;
  final double? longitude;
  final String? thumbnailUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // 関連データ
  final Company? company;

  Job({
    required this.id,
    required this.companyId,
    required this.title,
    required this.description,
    this.salary,
    this.location,
    this.status = 'open',
    this.jobType,
    this.jobCategory,
    this.workingHours,
    this.salaryMin,
    this.salaryMax,
    this.latitude,
    this.longitude,
    this.thumbnailUrl,
    this.createdAt,
    this.updatedAt,
    this.company,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      salary: json['salary'] as String?,
      location: json['location_text'] as String?,
      status: json['status'] as String? ?? 'open',
      jobType: json['job_type'] as String?,
      jobCategory: json['job_category'] as String?,
      workingHours: json['working_hours'] as String?,
      salaryMin: json['salary_min'] as int?,
      salaryMax: json['salary_max'] as int?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      thumbnailUrl: json['thumbnail_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      company: json['companies'] != null
          ? Company.fromJson(json['companies'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'title': title,
      'description': description,
      'salary': salary,
      'location_text': location,
      'status': status,
      'job_type': jobType,
      'job_category': jobCategory,
      'working_hours': workingHours,
      'salary_min': salaryMin,
      'salary_max': salaryMax,
      'latitude': latitude,
      'longitude': longitude,
      'thumbnail_url': thumbnailUrl,
    };
  }

  String get salaryRangeDisplay {
    if (salaryMin != null && salaryMax != null) {
      return '月給${salaryMin}万円〜${salaryMax}万円';
    } else if (salaryMin != null) {
      return '月給${salaryMin}万円〜';
    } else if (salaryMax != null) {
      return '〜月給${salaryMax}万円';
    }
    return salary ?? '';
  }

  Job copyWith({
    String? id,
    String? companyId,
    String? title,
    String? description,
    String? salary,
    String? location,
    String? status,
    String? jobType,
    String? jobCategory,
    String? workingHours,
    int? salaryMin,
    int? salaryMax,
    double? latitude,
    double? longitude,
    String? thumbnailUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    Company? company,
  }) {
    return Job(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      title: title ?? this.title,
      description: description ?? this.description,
      salary: salary ?? this.salary,
      location: location ?? this.location,
      status: status ?? this.status,
      jobType: jobType ?? this.jobType,
      jobCategory: jobCategory ?? this.jobCategory,
      workingHours: workingHours ?? this.workingHours,
      salaryMin: salaryMin ?? this.salaryMin,
      salaryMax: salaryMax ?? this.salaryMax,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      company: company ?? this.company,
    );
  }
}

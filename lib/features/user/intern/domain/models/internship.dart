// intern/domain/models/internship.dart

// 共通Companyモデルをre-export（既存のimportとの互換性維持）
export 'package:numbers/core/domain/models/company.dart';

import 'package:numbers/core/domain/models/company.dart';

class Internship {
  final String id;
  final String companyId;
  final String title;
  final String description;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> tags;
  final bool isPublic;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // 関連データ
  final Company? company;

  Internship({
    required this.id,
    required this.companyId,
    required this.title,
    required this.description,
    this.startDate,
    this.endDate,
    required this.tags,
    required this.isPublic,
    this.createdAt,
    this.updatedAt,
    this.company,
  });

  factory Internship.fromJson(Map<String, dynamic> json) {
    return Internship(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : [],
      isPublic: json['is_public'] as bool? ?? true,
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
      'start_date': startDate?.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'tags': tags,
      'is_public': isPublic,
    };
  }

  Internship copyWith({
    String? id,
    String? companyId,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? tags,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
    Company? company,
  }) {
    return Internship(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      tags: tags ?? this.tags,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      company: company ?? this.company,
    );
  }
}

// Company クラスは core/domain/models/company.dart から re-export 済み

// intern/domain/models/internship.dart

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
      id: json['id'] as String,
      companyId: json['company_id'] as String,
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

class Company {
  final String id;
  final String name;
  final String? description;
  final String? address;
  final String? industry;
  final String? website;
  final bool isSuspended;

  Company({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.industry,
    this.website,
    this.isSuspended = false,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      address: json['address'] as String?,
      industry: json['industry'] as String?,
      website: json['website'] as String?,
      isSuspended: json['is_suspended'] as bool? ?? false,
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
      'is_suspended': isSuspended,
    };
  }
}

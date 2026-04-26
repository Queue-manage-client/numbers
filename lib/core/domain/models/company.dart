// core/domain/models/company.dart
// 共通のCompanyモデル（Job/Intern/Feed等で共有）

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
}

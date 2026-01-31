// job/data/models/job_location.dart

/// Represents a job or internship location for map display
class JobLocation {
  final String id;
  final String title;
  final String companyId;
  final String companyName;
  final String? companyLogoUrl;
  final String? catchphrase;
  final String? thumbnailUrl;
  final String jobType; // 'part_time', 'intern', 'full_time', 'new_grad', 'mid_career'
  final double latitude;
  final double longitude;
  final String? salary;
  final String? location;
  final String? industry;
  final String? description;

  const JobLocation({
    required this.id,
    required this.title,
    required this.companyId,
    required this.companyName,
    this.companyLogoUrl,
    this.catchphrase,
    this.thumbnailUrl,
    required this.jobType,
    required this.latitude,
    required this.longitude,
    this.salary,
    this.location,
    this.industry,
    this.description,
  });

  factory JobLocation.fromJobJson(Map<String, dynamic> json) {
    final company = json['companies'] as Map<String, dynamic>?;
    return JobLocation(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      companyId: json['company_id'] as String,
      companyName: company?['name'] as String? ?? '',
      companyLogoUrl: company?['logo_url'] as String?,
      catchphrase: company?['catchphrase'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      jobType: json['job_type'] as String? ?? 'part_time',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      salary: json['salary'] as String?,
      location: json['location'] as String?,
      industry: company?['industry'] as String?,
      description: json['description'] as String?,
    );
  }

  factory JobLocation.fromInternJson(Map<String, dynamic> json) {
    final company = json['companies'] as Map<String, dynamic>?;
    return JobLocation(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      companyId: json['company_id'] as String,
      companyName: company?['name'] as String? ?? '',
      companyLogoUrl: company?['logo_url'] as String?,
      catchphrase: company?['catchphrase'] as String?,
      thumbnailUrl: null,
      jobType: 'intern',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      salary: null,
      location: json['location'] as String?,
      industry: company?['industry'] as String?,
      description: json['description'] as String?,
    );
  }

  bool get hasValidCoordinates => latitude != 0 && longitude != 0;
}

/// Represents a user's saved location (home, school, etc.)
class UserSavedLocation {
  final String id;
  final String userId;
  final String name;
  final String? address;
  final double latitude;
  final double longitude;
  final bool isDefault;
  final DateTime createdAt;

  const UserSavedLocation({
    required this.id,
    required this.userId,
    required this.name,
    this.address,
    required this.latitude,
    required this.longitude,
    this.isDefault = false,
    required this.createdAt,
  });

  factory UserSavedLocation.fromJson(Map<String, dynamic> json) {
    return UserSavedLocation(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Represents a base location for map center (current location, home, school)
class BaseLocation {
  final String name;
  final double latitude;
  final double longitude;
  final String? address;

  const BaseLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
  });

  factory BaseLocation.fromUserSaved(UserSavedLocation saved) {
    return BaseLocation(
      name: saved.name,
      latitude: saved.latitude,
      longitude: saved.longitude,
      address: saved.address,
    );
  }
}

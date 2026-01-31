// job/data/models/map_filter.dart

/// Filter conditions for map-based job search
class MapFilter {
  /// Job types to include: 'part_time', 'intern', 'full_time', 'new_grad', 'mid_career'
  final List<String> jobTypes;

  /// Industries to filter by: 'IT', 'finance', 'manufacturing', 'service', etc.
  final List<String> industries;

  /// Search radius in kilometers
  final double radiusKm;

  /// Minimum salary (optional)
  final int? minSalary;

  /// Maximum salary (optional)
  final int? maxSalary;

  const MapFilter({
    this.jobTypes = const ['part_time', 'intern'],
    this.industries = const [],
    this.radiusKm = 5.0,
    this.minSalary,
    this.maxSalary,
  });

  MapFilter copyWith({
    List<String>? jobTypes,
    List<String>? industries,
    double? radiusKm,
    int? minSalary,
    int? maxSalary,
  }) {
    return MapFilter(
      jobTypes: jobTypes ?? this.jobTypes,
      industries: industries ?? this.industries,
      radiusKm: radiusKm ?? this.radiusKm,
      minSalary: minSalary ?? this.minSalary,
      maxSalary: maxSalary ?? this.maxSalary,
    );
  }

  /// Clear salary filter
  MapFilter clearSalaryFilter() {
    return MapFilter(
      jobTypes: jobTypes,
      industries: industries,
      radiusKm: radiusKm,
      minSalary: null,
      maxSalary: null,
    );
  }

  /// Reset all filters to default
  static const MapFilter defaultFilter = MapFilter();

  /// Check if any filters are active (non-default)
  bool get hasActiveFilters {
    return jobTypes.length != 2 ||
        !jobTypes.contains('part_time') ||
        !jobTypes.contains('intern') ||
        industries.isNotEmpty ||
        minSalary != null ||
        maxSalary != null;
  }
}

/// Available job type options
class JobTypeOption {
  final String value;
  final String label;

  const JobTypeOption({required this.value, required this.label});

  static const List<JobTypeOption> all = [
    JobTypeOption(value: 'part_time', label: 'バイト'),
    JobTypeOption(value: 'intern', label: 'インターン'),
    JobTypeOption(value: 'full_time', label: '正社員'),
    JobTypeOption(value: 'new_grad', label: '新卒'),
    JobTypeOption(value: 'mid_career', label: '中途'),
  ];

  static String getLabel(String value) {
    return all.firstWhere(
      (o) => o.value == value,
      orElse: () => JobTypeOption(value: value, label: value),
    ).label;
  }
}

/// Available industry options
class IndustryOption {
  final String value;
  final String label;

  const IndustryOption({required this.value, required this.label});

  static const List<IndustryOption> all = [
    IndustryOption(value: 'IT', label: 'IT'),
    IndustryOption(value: 'finance', label: '金融'),
    IndustryOption(value: 'manufacturing', label: '製造'),
    IndustryOption(value: 'service', label: 'サービス'),
    IndustryOption(value: 'retail', label: '小売'),
    IndustryOption(value: 'healthcare', label: '医療'),
    IndustryOption(value: 'education', label: '教育'),
    IndustryOption(value: 'other', label: 'その他'),
  ];
}

/// Available radius options in kilometers
class RadiusOption {
  final double value;
  final String label;

  const RadiusOption({required this.value, required this.label});

  static const List<RadiusOption> all = [
    RadiusOption(value: 1.0, label: '1km'),
    RadiusOption(value: 3.0, label: '3km'),
    RadiusOption(value: 5.0, label: '5km'),
    RadiusOption(value: 10.0, label: '10km'),
    RadiusOption(value: 20.0, label: '20km'),
  ];
}

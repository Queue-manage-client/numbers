// job/data/repositories/job_map_repository.dart
import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:numbers/features/user/job/data/models/job_location.dart';

/// Repository for fetching job and internship data for map display
class JobMapRepository {
  final SupabaseClient _supabase;

  JobMapRepository(this._supabase);

  /// Get all jobs with valid coordinates
  Future<List<JobLocation>> getJobsWithCoordinates() async {
    final response = await _supabase
        .from('jobs')
        .select('*, companies(*)')
        .eq('status', 'open')
        .not('latitude', 'is', null)
        .not('longitude', 'is', null)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response)
        .map((json) => JobLocation.fromJobJson(json))
        .where((job) => job.hasValidCoordinates)
        .toList();
  }

  /// Get all internships with valid coordinates
  Future<List<JobLocation>> getInternshipsWithCoordinates() async {
    final response = await _supabase
        .from('internships')
        .select('*, companies(*)')
        .eq('is_public', true)
        .not('latitude', 'is', null)
        .not('longitude', 'is', null)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response)
        .map((json) => JobLocation.fromInternJson(json))
        .where((job) => job.hasValidCoordinates)
        .toList();
  }

  /// Get jobs within a radius from a center point (client-side filtering)
  /// Note: For production, consider using PostGIS for server-side distance calculation
  Future<List<JobLocation>> getJobsWithinRadius({
    required double centerLat,
    required double centerLng,
    required double radiusKm,
    List<String>? jobTypes,
    List<String>? industries,
  }) async {
    // Get all jobs with coordinates
    final jobs = await getJobsWithCoordinates();

    // Filter by distance
    var filtered = jobs.where((job) {
      final distance = _calculateDistance(
        centerLat,
        centerLng,
        job.latitude,
        job.longitude,
      );
      return distance <= radiusKm;
    }).toList();

    // Filter by job types
    if (jobTypes != null && jobTypes.isNotEmpty) {
      filtered = filtered.where((job) => jobTypes.contains(job.jobType)).toList();
    }

    // Filter by industries
    if (industries != null && industries.isNotEmpty) {
      filtered = filtered.where((job) {
        return job.industry != null && industries.contains(job.industry);
      }).toList();
    }

    return filtered;
  }

  /// Get internships within a radius from a center point
  Future<List<JobLocation>> getInternshipsWithinRadius({
    required double centerLat,
    required double centerLng,
    required double radiusKm,
    List<String>? industries,
  }) async {
    final internships = await getInternshipsWithCoordinates();

    var filtered = internships.where((intern) {
      final distance = _calculateDistance(
        centerLat,
        centerLng,
        intern.latitude,
        intern.longitude,
      );
      return distance <= radiusKm;
    }).toList();

    if (industries != null && industries.isNotEmpty) {
      filtered = filtered.where((intern) {
        return intern.industry != null && industries.contains(intern.industry);
      }).toList();
    }

    return filtered;
  }

  /// Get all jobs and internships within radius (combined)
  Future<List<JobLocation>> getAllListingsWithinRadius({
    required double centerLat,
    required double centerLng,
    required double radiusKm,
    List<String>? jobTypes,
    List<String>? industries,
  }) async {
    final results = <JobLocation>[];

    // Get jobs (if job types include non-intern types or is empty)
    final includeJobs = jobTypes == null ||
        jobTypes.isEmpty ||
        jobTypes.any((t) => t != 'intern');

    if (includeJobs) {
      final jobs = await getJobsWithinRadius(
        centerLat: centerLat,
        centerLng: centerLng,
        radiusKm: radiusKm,
        jobTypes: jobTypes?.where((t) => t != 'intern').toList(),
        industries: industries,
      );
      results.addAll(jobs);
    }

    // Get internships (if job types include 'intern' or is empty)
    final includeInterns = jobTypes == null ||
        jobTypes.isEmpty ||
        jobTypes.contains('intern');

    if (includeInterns) {
      final internships = await getInternshipsWithinRadius(
        centerLat: centerLat,
        centerLng: centerLng,
        radiusKm: radiusKm,
        industries: industries,
      );
      results.addAll(internships);
    }

    return results;
  }

  /// Get user's saved locations
  Future<List<UserSavedLocation>> getUserSavedLocations(String userId) async {
    final response = await _supabase
        .from('user_saved_locations')
        .select()
        .eq('user_id', userId)
        .order('is_default', ascending: false)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response)
        .map((json) => UserSavedLocation.fromJson(json))
        .toList();
  }

  /// Save or update a user's location
  Future<void> upsertUserLocation({
    required String userId,
    required String name,
    required double latitude,
    required double longitude,
    String? address,
    bool isDefault = false,
  }) async {
    // If setting as default, unset other defaults first
    if (isDefault) {
      await _supabase
          .from('user_saved_locations')
          .update({'is_default': false})
          .eq('user_id', userId);
    }

    await _supabase.from('user_saved_locations').upsert(
      {
        'user_id': userId,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'is_default': isDefault,
      },
      onConflict: 'user_id, name',
    );
  }

  /// Delete a user's saved location
  Future<void> deleteUserLocation(String locationId) async {
    await _supabase.from('user_saved_locations').delete().eq('id', locationId);
  }

  /// Calculate distance between two coordinates in kilometers (Haversine formula)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371;

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  double _toRadians(double degree) => degree * math.pi / 180;
}

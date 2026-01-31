// job/presentation/providers/job_map_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/features/user/job/data/models/job_location.dart';
import 'package:numbers/features/user/job/data/models/map_filter.dart';
import 'package:numbers/features/user/job/data/repositories/job_map_repository.dart';
import 'package:numbers/core/services/location_service.dart';
import 'package:numbers/core/services/geocoding_service.dart';

// Services
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final geocodingServiceProvider = Provider<GeocodingService>((ref) {
  return GeocodingService();
});

// Repository
final jobMapRepositoryProvider = Provider<JobMapRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return JobMapRepository(supabase);
});

// Current device position
final currentPositionProvider = FutureProvider<Position?>((ref) async {
  final service = ref.watch(locationServiceProvider);
  return await service.getCurrentPosition();
});

// Selected base location (current location, home, school, etc.)
final selectedBaseLocationProvider = StateProvider<BaseLocation?>((ref) => null);

// Filter state
final mapFilterProvider = StateNotifierProvider<MapFilterNotifier, MapFilter>((ref) {
  return MapFilterNotifier();
});

class MapFilterNotifier extends StateNotifier<MapFilter> {
  MapFilterNotifier() : super(const MapFilter());

  void updateRadius(double radiusKm) {
    state = state.copyWith(radiusKm: radiusKm);
  }

  void toggleJobType(String type) {
    final current = List<String>.from(state.jobTypes);
    if (current.contains(type)) {
      current.remove(type);
    } else {
      current.add(type);
    }
    state = state.copyWith(jobTypes: current);
  }

  void setJobTypes(List<String> types) {
    state = state.copyWith(jobTypes: types);
  }

  void toggleIndustry(String industry) {
    final current = List<String>.from(state.industries);
    if (current.contains(industry)) {
      current.remove(industry);
    } else {
      current.add(industry);
    }
    state = state.copyWith(industries: current);
  }

  void setIndustries(List<String> industries) {
    state = state.copyWith(industries: industries);
  }

  void setSalaryRange(int? min, int? max) {
    state = state.copyWith(minSalary: min, maxSalary: max);
  }

  void clearSalaryRange() {
    state = state.clearSalaryFilter();
  }

  void reset() {
    state = const MapFilter();
  }
}

// Jobs and internships for map display
final mapJobsProvider = FutureProvider<List<JobLocation>>((ref) async {
  final baseLocation = ref.watch(selectedBaseLocationProvider);
  final filter = ref.watch(mapFilterProvider);
  final repository = ref.watch(jobMapRepositoryProvider);

  if (baseLocation == null) {
    return [];
  }

  return await repository.getAllListingsWithinRadius(
    centerLat: baseLocation.latitude,
    centerLng: baseLocation.longitude,
    radiusKm: filter.radiusKm,
    jobTypes: filter.jobTypes.isNotEmpty ? filter.jobTypes : null,
    industries: filter.industries.isNotEmpty ? filter.industries : null,
  );
});

// User's saved locations
final userSavedLocationsProvider = FutureProvider<List<UserSavedLocation>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final repository = ref.watch(jobMapRepositoryProvider);
  return await repository.getUserSavedLocations(user.id);
});

// Selected job for popup display
final selectedMapJobProvider = StateProvider<JobLocation?>((ref) => null);

// Map loading state
final mapLoadingProvider = StateProvider<bool>((ref) => true);

// Initialize base location from current position or saved locations
final initializeBaseLocationProvider = FutureProvider<void>((ref) async {
  final currentBase = ref.read(selectedBaseLocationProvider);
  if (currentBase != null) return;

  // Try to get saved locations first
  final savedLocations = await ref.watch(userSavedLocationsProvider.future);
  final defaultSaved = savedLocations.where((l) => l.isDefault).firstOrNull;

  if (defaultSaved != null) {
    ref.read(selectedBaseLocationProvider.notifier).state =
        BaseLocation.fromUserSaved(defaultSaved);
    return;
  }

  // Fall back to current position
  final position = await ref.watch(currentPositionProvider.future);
  if (position != null) {
    ref.read(selectedBaseLocationProvider.notifier).state = BaseLocation(
      name: '現在地',
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
});

// core/services/location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for handling device location
class LocationService {
  /// Request location permission from the user
  Future<bool> requestPermission() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  /// Check if location permission is granted
  Future<bool> hasPermission() async {
    final status = await Permission.locationWhenInUse.status;
    return status.isGranted;
  }

  /// Check if location services are enabled on the device
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get the current device position
  /// Returns null if permission is denied or location services are disabled
  Future<Position?> getCurrentPosition() async {
    // Check if location services are enabled
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    // Check/request permission
    final hasPermissionGranted = await hasPermission();
    if (!hasPermissionGranted) {
      final granted = await requestPermission();
      if (!granted) {
        return null;
      }
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get the last known position (faster, but may be outdated)
  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      return null;
    }
  }

  /// Get a stream of position updates
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100, // Update every 100 meters
      ),
    );
  }

  /// Calculate distance between two points in meters
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Calculate distance in kilometers
  double calculateDistanceKm(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return calculateDistance(
          startLatitude,
          startLongitude,
          endLatitude,
          endLongitude,
        ) /
        1000;
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings (for permission settings)
  Future<bool> openAppSettings() async {
    return await openAppSettings();
  }
}

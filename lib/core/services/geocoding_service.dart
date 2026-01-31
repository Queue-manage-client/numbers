// core/services/geocoding_service.dart
import 'package:geocoding/geocoding.dart';

/// Service for converting addresses to coordinates and vice versa
class GeocodingService {
  /// Convert an address string to coordinates
  /// Returns null if the address cannot be geocoded
  Future<GeocodingResult?> getCoordinatesFromAddress(String address) async {
    if (address.trim().isEmpty) {
      return null;
    }

    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        return GeocodingResult(
          latitude: location.latitude,
          longitude: location.longitude,
          address: address,
        );
      }
    } catch (e) {
      // Geocoding failed
    }
    return null;
  }

  /// Convert coordinates to an address
  /// Returns null if reverse geocoding fails
  Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return _formatAddress(place);
      }
    } catch (e) {
      // Reverse geocoding failed
    }
    return null;
  }

  /// Format a Placemark into a readable address string
  String _formatAddress(Placemark place) {
    final parts = <String>[];

    if (place.postalCode != null && place.postalCode!.isNotEmpty) {
      parts.add('\u3012${place.postalCode}');
    }

    if (place.administrativeArea != null &&
        place.administrativeArea!.isNotEmpty) {
      parts.add(place.administrativeArea!);
    }

    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    }

    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      parts.add(place.subLocality!);
    }

    if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
      parts.add(place.thoroughfare!);
    }

    if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
      parts.add(place.subThoroughfare!);
    }

    return parts.join(' ');
  }

  /// Get detailed location information from coordinates
  Future<DetailedLocation?> getDetailedLocation(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return DetailedLocation(
          latitude: latitude,
          longitude: longitude,
          formattedAddress: _formatAddress(place),
          country: place.country,
          administrativeArea: place.administrativeArea,
          locality: place.locality,
          subLocality: place.subLocality,
          postalCode: place.postalCode,
        );
      }
    } catch (e) {
      // Reverse geocoding failed
    }
    return null;
  }
}

/// Result of geocoding an address
class GeocodingResult {
  final double latitude;
  final double longitude;
  final String address;

  const GeocodingResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

/// Detailed location information from reverse geocoding
class DetailedLocation {
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String? country;
  final String? administrativeArea;
  final String? locality;
  final String? subLocality;
  final String? postalCode;

  const DetailedLocation({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    this.country,
    this.administrativeArea,
    this.locality,
    this.subLocality,
    this.postalCode,
  });
}

// job/presentation/widgets/job_map_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:numbers/features/user/job/data/models/job_location.dart';
import 'package:numbers/features/user/job/presentation/providers/job_map_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';

class JobMapView extends ConsumerStatefulWidget {
  final LatLng initialPosition;
  final double radiusKm;
  final Function(GoogleMapController)? onMapCreated;
  final Function(JobLocation) onMarkerTapped;

  const JobMapView({
    super.key,
    required this.initialPosition,
    required this.radiusKm,
    this.onMapCreated,
    required this.onMarkerTapped,
  });

  @override
  ConsumerState<JobMapView> createState() => _JobMapViewState();
}

class _JobMapViewState extends ConsumerState<JobMapView> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  @override
  void didUpdateWidget(covariant JobMapView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update camera if initial position changed
    if (oldWidget.initialPosition != widget.initialPosition) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          widget.initialPosition,
          _calculateZoomLevel(widget.radiusKm),
        ),
      );
    }

    // Update zoom if radius changed
    if (oldWidget.radiusKm != widget.radiusKm) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          widget.initialPosition,
          _calculateZoomLevel(widget.radiusKm),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(mapJobsProvider);

    // Build markers from jobs
    jobsAsync.whenData((jobs) {
      _markers = jobs.map((job) {
        return Marker(
          markerId: MarkerId(job.id),
          position: LatLng(job.latitude, job.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _getMarkerHue(job.jobType),
          ),
          onTap: () => widget.onMarkerTapped(job),
        );
      }).toSet();
    });

    // Build radius circle
    _circles = {
      Circle(
        circleId: const CircleId('radius'),
        center: widget.initialPosition,
        radius: widget.radiusKm * 1000,
        fillColor: ColorPalette.primaryColor.withOpacity(0.1),
        strokeColor: ColorPalette.primaryColor,
        strokeWidth: 2,
      ),
    };

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.initialPosition,
            zoom: _calculateZoomLevel(widget.radiusKm),
          ),
          markers: _markers,
          circles: _circles,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          onMapCreated: (controller) {
            _mapController = controller;
            widget.onMapCreated?.call(controller);
            _setMapStyle(controller);
          },
          onTap: (_) {
            // Deselect marker when tapping on map
            ref.read(selectedMapJobProvider.notifier).state = null;
          },
        ),

        // Loading overlay
        if (jobsAsync.isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(SpacePalette.base),
                  decoration: BoxDecoration(
                    color: ColorPalette.neutral800,
                    borderRadius: BorderRadius.circular(RadiusPalette.base),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: ColorPalette.primaryColor,
                      ),
                      const SizedBox(height: SpacePalette.sm),
                      Text(
                        '求人を読み込み中...',
                        style: TextStylePalette.smText,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Job count badge
        Positioned(
          top: SpacePalette.sm,
          right: SpacePalette.sm,
          child: jobsAsync.when(
            data: (jobs) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacePalette.base,
                vertical: SpacePalette.sm,
              ),
              decoration: BoxDecoration(
                color: ColorPalette.neutral800.withOpacity(0.9),
                borderRadius: BorderRadius.circular(RadiusPalette.base),
                border: Border.all(color: ColorPalette.neutral600),
              ),
              child: Text(
                '${jobs.length}件',
                style: TextStylePalette.smTitle.copyWith(
                  color: ColorPalette.primaryColor,
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),

        // My location button
        Positioned(
          bottom: SpacePalette.base,
          right: SpacePalette.base,
          child: FloatingActionButton.small(
            heroTag: 'myLocation',
            backgroundColor: ColorPalette.neutral800,
            onPressed: _goToCurrentLocation,
            child: Icon(
              Icons.my_location,
              color: ColorPalette.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  double _calculateZoomLevel(double radiusKm) {
    if (radiusKm <= 1) return 15;
    if (radiusKm <= 3) return 14;
    if (radiusKm <= 5) return 13;
    if (radiusKm <= 10) return 12;
    if (radiusKm <= 20) return 11;
    return 10;
  }

  double _getMarkerHue(String jobType) {
    switch (jobType) {
      case 'part_time':
        return BitmapDescriptor.hueBlue;
      case 'intern':
        return BitmapDescriptor.hueOrange;
      case 'full_time':
        return BitmapDescriptor.hueGreen;
      case 'new_grad':
        return BitmapDescriptor.hueViolet;
      case 'mid_career':
        return BitmapDescriptor.hueCyan;
      default:
        return BitmapDescriptor.hueRed;
    }
  }

  Future<void> _setMapStyle(GoogleMapController controller) async {
    // Dark mode style for the map
    const darkStyle = '''
    [
      {
        "elementType": "geometry",
        "stylers": [{"color": "#242f3e"}]
      },
      {
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#746855"}]
      },
      {
        "elementType": "labels.text.stroke",
        "stylers": [{"color": "#242f3e"}]
      },
      {
        "featureType": "administrative.locality",
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#d59563"}]
      },
      {
        "featureType": "poi",
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#d59563"}]
      },
      {
        "featureType": "poi.park",
        "elementType": "geometry",
        "stylers": [{"color": "#263c3f"}]
      },
      {
        "featureType": "poi.park",
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#6b9a76"}]
      },
      {
        "featureType": "road",
        "elementType": "geometry",
        "stylers": [{"color": "#38414e"}]
      },
      {
        "featureType": "road",
        "elementType": "geometry.stroke",
        "stylers": [{"color": "#212a37"}]
      },
      {
        "featureType": "road",
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#9ca5b3"}]
      },
      {
        "featureType": "road.highway",
        "elementType": "geometry",
        "stylers": [{"color": "#746855"}]
      },
      {
        "featureType": "road.highway",
        "elementType": "geometry.stroke",
        "stylers": [{"color": "#1f2835"}]
      },
      {
        "featureType": "road.highway",
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#f3d19c"}]
      },
      {
        "featureType": "transit",
        "elementType": "geometry",
        "stylers": [{"color": "#2f3948"}]
      },
      {
        "featureType": "transit.station",
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#d59563"}]
      },
      {
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [{"color": "#17263c"}]
      },
      {
        "featureType": "water",
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#515c6d"}]
      },
      {
        "featureType": "water",
        "elementType": "labels.text.stroke",
        "stylers": [{"color": "#17263c"}]
      }
    ]
    ''';

    await controller.setMapStyle(darkStyle);
  }

  Future<void> _goToCurrentLocation() async {
    final position = await ref.read(currentPositionProvider.future);
    if (position != null && _mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude),
        ),
      );
    }
  }
}

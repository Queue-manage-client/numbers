// job/presentation/pages/job_map_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:numbers/features/user/job/data/models/job_location.dart';
import 'package:numbers/features/user/job/presentation/providers/job_map_provider.dart';
import 'package:numbers/features/user/job/presentation/widgets/job_map_view.dart';
import 'package:numbers/features/user/job/presentation/widgets/job_marker_popup.dart';
import 'package:numbers/features/user/job/presentation/widgets/map_filter_sheet.dart';
import 'package:numbers/features/user/job/presentation/widgets/location_selector.dart';
import 'package:numbers/features/user/job/presentation/widgets/radius_slider.dart';
import 'package:numbers/core/theme/app_theme.dart';

class JobMapPage extends ConsumerStatefulWidget {
  const JobMapPage({super.key});

  @override
  ConsumerState<JobMapPage> createState() => _JobMapPageState();
}

class _JobMapPageState extends ConsumerState<JobMapPage> {
  GoogleMapController? _mapController;
  bool _showRadiusSlider = false;

  @override
  void initState() {
    super.initState();
    // Initialize base location
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
    });
  }

  Future<void> _initializeLocation() async {
    final currentBase = ref.read(selectedBaseLocationProvider);
    if (currentBase != null) return;

    // Try to get current position first
    final position = await ref.read(currentPositionProvider.future);
    if (position != null && mounted) {
      ref.read(selectedBaseLocationProvider.notifier).state = BaseLocation(
        name: '現在地',
        latitude: position.latitude,
        longitude: position.longitude,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseLocation = ref.watch(selectedBaseLocationProvider);
    final selectedJob = ref.watch(selectedMapJobProvider);
    final filter = ref.watch(mapFilterProvider);

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        title: const Text('募集を探す'),
        centerTitle: true,
        actions: [
          // Filter button
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.tune),
                if (filter.hasActiveFilters)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: ColorPalette.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => _showFilterSheet(context),
          ),
          const SizedBox(width: SpacePalette.sm),
        ],
      ),
      body: baseLocation == null
          ? _buildLoadingState()
          : Stack(
              children: [
                // Google Map
                JobMapView(
                  initialPosition: LatLng(
                    baseLocation.latitude,
                    baseLocation.longitude,
                  ),
                  radiusKm: filter.radiusKm,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onMarkerTapped: (job) {
                    ref.read(selectedMapJobProvider.notifier).state = job;
                  },
                ),

                // Location selector (top)
                Positioned(
                  top: SpacePalette.base,
                  left: SpacePalette.base,
                  right: SpacePalette.base,
                  child: LocationSelector(
                    onLocationSelected: (location) {
                      ref.read(selectedBaseLocationProvider.notifier).state =
                          location;
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLng(
                          LatLng(location.latitude, location.longitude),
                        ),
                      );
                    },
                  ),
                ),

                // Radius slider toggle button
                Positioned(
                  bottom: selectedJob != null ? 280 : 100,
                  left: SpacePalette.base,
                  child: FloatingActionButton.small(
                    heroTag: 'radiusToggle',
                    backgroundColor: ColorPalette.neutral800,
                    onPressed: () {
                      setState(() {
                        _showRadiusSlider = !_showRadiusSlider;
                      });
                    },
                    child: Icon(
                      _showRadiusSlider ? Icons.close : Icons.radar,
                      color: ColorPalette.primaryColor,
                    ),
                  ),
                ),

                // Radius slider
                if (_showRadiusSlider)
                  Positioned(
                    bottom: selectedJob != null ? 320 : 140,
                    left: 0,
                    right: 0,
                    child: RadiusSlider(
                      value: filter.radiusKm,
                      onChanged: (value) {
                        ref.read(mapFilterProvider.notifier).updateRadius(value);
                      },
                    ),
                  ),

                // Job popup (bottom)
                if (selectedJob != null)
                  Positioned(
                    bottom: 100,
                    left: SpacePalette.base,
                    right: SpacePalette.base,
                    child: JobMarkerPopup(
                      job: selectedJob,
                      onClose: () {
                        ref.read(selectedMapJobProvider.notifier).state = null;
                      },
                      onDetailTap: () {
                        if (selectedJob.jobType == 'intern') {
                          context.push('/interns/${selectedJob.id}');
                        } else {
                          context.push('/jobs/${selectedJob.id}');
                        }
                      },
                      onApplyTap: selectedJob.jobType == 'intern'
                          ? null
                          : () {
                              context.push('/jobs/${selectedJob.id}/apply/confirm');
                            },
                    ),
                  ),

                // Legend
                Positioned(
                  bottom: selectedJob != null ? 340 : 160,
                  right: SpacePalette.base,
                  child: _buildLegend(),
                ),
              ],
            ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: ColorPalette.primaryColor,
          ),
          const SizedBox(height: SpacePalette.lg),
          Text(
            '位置情報を取得中...',
            style: TextStylePalette.subText,
          ),
          const SizedBox(height: SpacePalette.sm),
          TextButton(
            onPressed: () async {
              final service = ref.read(locationServiceProvider);
              final hasPermission = await service.hasPermission();
              if (!hasPermission) {
                await service.requestPermission();
              }
              ref.invalidate(currentPositionProvider);
              _initializeLocation();
            },
            child: Text(
              '再試行',
              style: TextStylePalette.guide,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(SpacePalette.sm),
      decoration: BoxDecoration(
        color: ColorPalette.neutral800.withOpacity(0.9),
        borderRadius: BorderRadius.circular(RadiusPalette.base),
        border: Border.all(color: ColorPalette.neutral600),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildImageLegendItem('assets/images/map2.png', 'バイト'),
          const SizedBox(height: SpacePalette.xs),
          _buildImageLegendItem('assets/images/map100.png', 'インターン'),
          const SizedBox(height: SpacePalette.xs),
          _buildImageLegendItem('assets/images/map6.png', '正社員'),
          const SizedBox(height: SpacePalette.xs),
          _buildLegendItem(Colors.purple, '新卒'),
          const SizedBox(height: SpacePalette.xs),
          _buildLegendItem(Colors.cyan, '中途'),
        ],
      ),
    );
  }

  Widget _buildImageLegendItem(String imagePath, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          imagePath,
          width: 16,
          height: 16,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: SpacePalette.sm),
        Text(
          label,
          style: TextStylePalette.smSubText,
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: SpacePalette.sm),
        Text(
          label,
          style: TextStylePalette.smSubText,
        ),
      ],
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MapFilterSheet(),
    );
  }
}

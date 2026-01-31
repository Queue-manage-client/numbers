// job/presentation/widgets/location_selector.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/features/user/job/data/models/job_location.dart';
import 'package:numbers/features/user/job/presentation/providers/job_map_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';

class LocationSelector extends ConsumerWidget {
  final Function(BaseLocation) onLocationSelected;

  const LocationSelector({
    super.key,
    required this.onLocationSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedBase = ref.watch(selectedBaseLocationProvider);
    final savedLocationsAsync = ref.watch(userSavedLocationsProvider);
    final currentPositionAsync = ref.watch(currentPositionProvider);

    return Container(
      padding: const EdgeInsets.all(SpacePalette.sm),
      decoration: BoxDecoration(
        color: ColorPalette.neutral800.withOpacity(0.95),
        borderRadius: BorderRadius.circular(RadiusPalette.lg),
        border: Border.all(color: ColorPalette.neutral600),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Current location chip
            currentPositionAsync.when(
              data: (position) {
                if (position == null) {
                  return _buildDisabledChip('現在地', Icons.my_location);
                }
                final isCurrent = selectedBase?.name == '現在地';
                return _LocationChip(
                  label: '現在地',
                  icon: Icons.my_location,
                  isSelected: isCurrent,
                  onTap: () {
                    final location = BaseLocation(
                      name: '現在地',
                      latitude: position.latitude,
                      longitude: position.longitude,
                    );
                    ref.read(selectedBaseLocationProvider.notifier).state =
                        location;
                    onLocationSelected(location);
                  },
                );
              },
              loading: () => _buildLoadingChip('現在地', Icons.my_location),
              error: (_, __) => _buildDisabledChip('現在地', Icons.my_location),
            ),

            const SizedBox(width: SpacePalette.sm),

            // Saved locations
            savedLocationsAsync.when(
              data: (savedLocations) {
                return Row(
                  children: savedLocations.map((saved) {
                    final isSelected = selectedBase?.name == saved.name;
                    return Padding(
                      padding: const EdgeInsets.only(right: SpacePalette.sm),
                      child: _LocationChip(
                        label: saved.name,
                        icon: _getIconForLocation(saved.name),
                        isSelected: isSelected,
                        onTap: () {
                          final location = BaseLocation.fromUserSaved(saved);
                          ref.read(selectedBaseLocationProvider.notifier).state =
                              location;
                          onLocationSelected(location);
                        },
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Add location button
            _AddLocationChip(
              onTap: () => _showAddLocationDialog(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacePalette.base,
        vertical: SpacePalette.sm,
      ),
      decoration: BoxDecoration(
        color: ColorPalette.neutral600,
        borderRadius: BorderRadius.circular(RadiusPalette.base),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ColorPalette.neutral400,
            ),
          ),
          const SizedBox(width: SpacePalette.sm),
          Text(
            label,
            style: TextStylePalette.smSubText,
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacePalette.base,
        vertical: SpacePalette.sm,
      ),
      decoration: BoxDecoration(
        color: ColorPalette.neutral600.withOpacity(0.5),
        borderRadius: BorderRadius.circular(RadiusPalette.base),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: ColorPalette.neutral500),
          const SizedBox(width: SpacePalette.sm),
          Text(
            label,
            style: TextStylePalette.smSubText.copyWith(
              color: ColorPalette.neutral500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForLocation(String name) {
    switch (name.toLowerCase()) {
      case '自宅':
      case 'home':
        return Icons.home;
      case '学校':
      case 'school':
        return Icons.school;
      case '会社':
      case 'office':
        return Icons.business;
      default:
        return Icons.place;
    }
  }

  void _showAddLocationDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddLocationSheet(),
    );
  }
}

class _LocationChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _LocationChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacePalette.base,
          vertical: SpacePalette.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? ColorPalette.primaryColor : ColorPalette.neutral800,
          borderRadius: BorderRadius.circular(RadiusPalette.base),
          border: Border.all(
            color: isSelected ? ColorPalette.primaryColor : ColorPalette.neutral600,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? ColorPalette.neutral900 : ColorPalette.neutral0,
            ),
            const SizedBox(width: SpacePalette.sm),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'NotoSansJP',
                fontSize: FontSizePalette.size14,
                fontVariations: const [FontVariation('wght', 700)],
                color: isSelected ? ColorPalette.neutral900 : ColorPalette.neutral0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddLocationChip extends StatelessWidget {
  final VoidCallback onTap;

  const _AddLocationChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacePalette.base,
          vertical: SpacePalette.sm,
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(RadiusPalette.base),
          border: Border.all(
            color: ColorPalette.neutral600,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add,
              size: 16,
              color: ColorPalette.neutral400,
            ),
            const SizedBox(width: SpacePalette.sm),
            Text(
              '追加',
              style: TextStylePalette.smSubText,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddLocationSheet extends ConsumerStatefulWidget {
  const _AddLocationSheet();

  @override
  ConsumerState<_AddLocationSheet> createState() => _AddLocationSheetState();
}

class _AddLocationSheetState extends ConsumerState<_AddLocationSheet> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;
  String? _selectedType;

  final List<Map<String, dynamic>> _locationTypes = [
    {'name': '自宅', 'icon': Icons.home},
    {'name': '学校', 'icon': Icons.school},
    {'name': '会社', 'icon': Icons.business},
    {'name': 'その他', 'icon': Icons.place},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: ColorPalette.neutral800,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(RadiusPalette.lg),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SpacePalette.base),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: SpacePalette.base),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ColorPalette.neutral600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text('地点を追加', style: TextStylePalette.smHeader),
            const SizedBox(height: SpacePalette.lg),

            // Location type selection
            Text('種類', style: TextStylePalette.smTitle),
            const SizedBox(height: SpacePalette.sm),
            Wrap(
              spacing: SpacePalette.sm,
              runSpacing: SpacePalette.sm,
              children: _locationTypes.map((type) {
                final isSelected = _selectedType == type['name'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedType = type['name'];
                      if (type['name'] != 'その他') {
                        _nameController.text = type['name'];
                      } else {
                        _nameController.clear();
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacePalette.base,
                      vertical: SpacePalette.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ColorPalette.primaryColor
                          : ColorPalette.neutral800,
                      borderRadius: BorderRadius.circular(RadiusPalette.base),
                      border: Border.all(
                        color: isSelected
                            ? ColorPalette.primaryColor
                            : ColorPalette.neutral600,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          type['icon'],
                          size: 16,
                          color: isSelected
                              ? ColorPalette.neutral900
                              : ColorPalette.neutral0,
                        ),
                        const SizedBox(width: SpacePalette.sm),
                        Text(
                          type['name'],
                          style: TextStyle(
                            fontFamily: 'NotoSansJP',
                            fontSize: FontSizePalette.size14,
                            fontVariations: const [FontVariation('wght', 700)],
                            color: isSelected
                                ? ColorPalette.neutral900
                                : ColorPalette.neutral0,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: SpacePalette.lg),

            // Custom name (for "other" type)
            if (_selectedType == 'その他') ...[
              Text('名前', style: TextStylePalette.smTitle),
              const SizedBox(height: SpacePalette.sm),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: '例: バイト先',
                ),
              ),
              const SizedBox(height: SpacePalette.lg),
            ],

            // Address input
            Text('住所', style: TextStylePalette.smTitle),
            const SizedBox(height: SpacePalette.sm),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                hintText: '例: 東京都渋谷区渋谷1-1-1',
              ),
            ),

            const SizedBox(height: SpacePalette.lg),

            // Save button
            GradientButton(
              text: '保存',
              isLoading: _isLoading,
              onPressed: _selectedType != null &&
                      _addressController.text.isNotEmpty &&
                      (_selectedType != 'その他' || _nameController.text.isNotEmpty)
                  ? _saveLocation
                  : null,
            ),

            const SizedBox(height: SpacePalette.base),
          ],
        ),
      ),
    );
  }

  Future<void> _saveLocation() async {
    setState(() => _isLoading = true);

    try {
      final geocodingService = ref.read(geocodingServiceProvider);
      final result =
          await geocodingService.getCoordinatesFromAddress(_addressController.text);

      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('住所が見つかりませんでした'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final user = ref.read(currentUserProvider);
      if (user == null) {
        if (mounted) {
          Navigator.pop(context);
        }
        return;
      }

      final repository = ref.read(jobMapRepositoryProvider);
      await repository.upsertUserLocation(
        userId: user.id,
        name: _nameController.text.isNotEmpty
            ? _nameController.text
            : _selectedType!,
        latitude: result.latitude,
        longitude: result.longitude,
        address: _addressController.text,
      );

      // Refresh saved locations
      ref.invalidate(userSavedLocationsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('地点を保存しました'),
            backgroundColor: ColorPalette.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

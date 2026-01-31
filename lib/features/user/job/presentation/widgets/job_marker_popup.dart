// job/presentation/widgets/job_marker_popup.dart
import 'package:flutter/material.dart';
import 'package:numbers/features/user/job/data/models/job_location.dart';
import 'package:numbers/features/user/job/data/models/map_filter.dart';
import 'package:numbers/core/theme/app_theme.dart';

class JobMarkerPopup extends StatelessWidget {
  final JobLocation job;
  final VoidCallback onClose;
  final VoidCallback onDetailTap;

  const JobMarkerPopup({
    super.key,
    required this.job,
    required this.onClose,
    required this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorPalette.neutral800,
        borderRadius: BorderRadius.circular(RadiusPalette.lg),
        border: Border.all(color: ColorPalette.neutral600),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with badge and close button
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SpacePalette.sm,
              SpacePalette.sm,
              SpacePalette.xs,
              0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Job type badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacePalette.sm,
                    vertical: SpacePalette.xs,
                  ),
                  decoration: BoxDecoration(
                    color: _getJobTypeColor(job.jobType),
                    borderRadius: BorderRadius.circular(RadiusPalette.mini),
                  ),
                  child: Text(
                    JobTypeOption.getLabel(job.jobType),
                    style: TextStylePalette.miniTitle,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 20,
                    color: ColorPalette.neutral400,
                  ),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SpacePalette.base,
              SpacePalette.sm,
              SpacePalette.base,
              SpacePalette.base,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail or logo
                ClipRRect(
                  borderRadius: BorderRadius.circular(RadiusPalette.base),
                  child: Container(
                    width: 80,
                    height: 60,
                    color: ColorPalette.neutral600,
                    child: job.thumbnailUrl != null
                        ? Image.network(
                            job.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(),
                          )
                        : job.companyLogoUrl != null
                            ? Image.network(
                                job.companyLogoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildPlaceholder(),
                              )
                            : _buildPlaceholder(),
                  ),
                ),
                const SizedBox(width: SpacePalette.base),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.companyName,
                        style: TextStylePalette.smSubText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: SpacePalette.xs),
                      Text(
                        job.title,
                        style: TextStylePalette.smListTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (job.salary != null && job.salary!.isNotEmpty) ...[
                        const SizedBox(height: SpacePalette.xs),
                        Text(
                          job.salary!,
                          style: TextStylePalette.smSubText.copyWith(
                            color: ColorPalette.primaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Detail button
          GestureDetector(
            onTap: onDetailTap,
            child: Container(
              padding: const EdgeInsets.all(SpacePalette.base),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: ColorPalette.neutral600),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '詳細を見る',
                    style: TextStylePalette.guide,
                  ),
                  const SizedBox(width: SpacePalette.xs),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: ColorPalette.primaryColor,
                    size: 12,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.business,
        size: 30,
        color: ColorPalette.neutral400,
      ),
    );
  }

  Color _getJobTypeColor(String type) {
    switch (type) {
      case 'part_time':
        return Colors.blue;
      case 'intern':
        return Colors.orange;
      case 'full_time':
        return ColorPalette.primaryColor;
      case 'new_grad':
        return Colors.purple;
      case 'mid_career':
        return Colors.teal;
      default:
        return ColorPalette.neutral600;
    }
  }
}

// job/presentation/widgets/job_marker_popup.dart
import 'package:flutter/material.dart';
import 'package:numbers/features/user/job/data/models/job_location.dart';
import 'package:numbers/features/user/job/data/models/map_filter.dart';
import 'package:numbers/core/theme/app_theme.dart';

class JobMarkerPopup extends StatelessWidget {
  final JobLocation job;
  final VoidCallback onClose;
  final VoidCallback onDetailTap;
  final VoidCallback? onApplyTap;

  const JobMarkerPopup({
    super.key,
    required this.job,
    required this.onClose,
    required this.onDetailTap,
    this.onApplyTap,
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

          // Content area (text-focused, no thumbnail)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SpacePalette.base,
              SpacePalette.sm,
              SpacePalette.base,
              SpacePalette.base,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  job.title,
                  style: TextStylePalette.smListTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: SpacePalette.xs),

                // Company name
                Text(
                  job.companyName,
                  style: TextStylePalette.smSubText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // Job category badge
                if (job.jobCategory != null && job.jobCategory!.isNotEmpty) ...[
                  const SizedBox(height: SpacePalette.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacePalette.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: ColorPalette.neutral600,
                      borderRadius: BorderRadius.circular(RadiusPalette.mini),
                      border: Border.all(color: ColorPalette.neutral600),
                    ),
                    child: Text(
                      job.jobCategory!,
                      style: TextStylePalette.smSubText,
                    ),
                  ),
                ],

                // Salary range display
                if (job.salaryRangeDisplay.isNotEmpty) ...[
                  const SizedBox(height: SpacePalette.sm),
                  Text(
                    job.salaryRangeDisplay,
                    style: TextStylePalette.smSubText.copyWith(
                      color: ColorPalette.primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Working hours
                if (job.workingHours != null &&
                    job.workingHours!.isNotEmpty) ...[
                  const SizedBox(height: SpacePalette.xs),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: ColorPalette.neutral400,
                      ),
                      const SizedBox(width: SpacePalette.xs),
                      Expanded(
                        child: Text(
                          job.workingHours!,
                          style: TextStylePalette.smSubText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                // Location
                if (job.location != null && job.location!.isNotEmpty) ...[
                  const SizedBox(height: SpacePalette.xs),
                  Row(
                    children: [
                      Icon(
                        Icons.place,
                        size: 14,
                        color: ColorPalette.neutral400,
                      ),
                      const SizedBox(width: SpacePalette.xs),
                      Expanded(
                        child: Text(
                          job.location!,
                          style: TextStylePalette.smSubText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Bottom buttons
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: ColorPalette.neutral600),
              ),
            ),
            child: Row(
              children: [
                // "詳細を見る" outline button
                Expanded(
                  child: GestureDetector(
                    onTap: onDetailTap,
                    child: Container(
                      padding: const EdgeInsets.all(SpacePalette.base),
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
                ),

                // "応募する" filled button (only if onApplyTap is provided)
                if (onApplyTap != null) ...[
                  Container(
                    width: 1,
                    height: 40,
                    color: ColorPalette.neutral600,
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: onApplyTap,
                      child: Container(
                        padding: const EdgeInsets.all(SpacePalette.base),
                        decoration: BoxDecoration(
                          color: ColorPalette.primaryColor,
                          borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(RadiusPalette.lg),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '応募する',
                              style: TextStylePalette.guide.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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

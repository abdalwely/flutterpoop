import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';

class StoryProgressBar extends StatelessWidget {
  final int segmentCount;
  final int currentSegment;
  final AnimationController progressController;

  const StoryProgressBar({
    super.key,
    required this.segmentCount,
    required this.currentSegment,
    required this.progressController,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(segmentCount, (index) {
        return Expanded(
          child: Container(
            height: 3.h,
            margin: EdgeInsets.symmetric(horizontal: 2.w),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(1.5.r),
            ),
            child: _buildProgressSegment(index),
          ),
        );
      }),
    );
  }

  Widget _buildProgressSegment(int index) {
    if (index < currentSegment) {
      // Completed segment
      return Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(1.5.r),
        ),
      );
    } else if (index == currentSegment) {
      // Current segment with animation
      return AnimatedBuilder(
        animation: progressController,
        builder: (context, child) {
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progressController.value,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(1.5.r),
              ),
            ),
          );
        },
      );
    } else {
      // Future segment
      return const SizedBox.shrink();
    }
  }
}

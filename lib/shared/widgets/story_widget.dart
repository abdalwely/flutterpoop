import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_colors.dart';
import '../../features/stories/presentation/pages/create_story_screen.dart';

class StoryWidget extends StatelessWidget {
  final String profileImageUrl;
  final String username;
  final bool isViewed;
  final bool isMyStory;
  final VoidCallback? onTap;
  final VoidCallback? onAddStory;
  final double size;

  const StoryWidget({
    super.key,
    required this.profileImageUrl,
    required this.username,
    this.isViewed = false,
    this.isMyStory = false,
    this.onTap,
    this.onAddStory,
    this.size = 70,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isMyStory ? (onAddStory ?? () => _showCreateStoryOptions(context)) : onTap,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Story Circle
            Container(
              width: size.w,
              height: size.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isViewed || isMyStory
                    ? null
                    : AppColors.storyGradient,
                border: isViewed
                    ? Border.all(
                        color: AppColors.storyViewed,
                        width: 2,
                      )
                    : null,
              ),
              child: Container(
                margin: EdgeInsets.all(isViewed || isMyStory ? 0 : 3.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white,
                ),
                child: Container(
                  margin: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(profileImageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: isMyStory
                      ? Align(
                          alignment: Alignment.bottomRight,
                          child: GestureDetector(
                            onTap: onAddStory ?? () => _showCreateStoryOptions(context),
                            child: Container(
                              width: 20.w,
                              height: 20.h,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.white,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.add,
                                color: AppColors.white,
                                size: 12.sp,
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),
            
            SizedBox(height: 4.h),
            
            // Username
            SizedBox(
              width: size.w,
              child: Text(
                isMyStory ? 'قصتك' : username,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textPrimary,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateStoryOptions(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateStoryScreen(),
      ),
    );
  }
}

// Large Story Widget for Story View
class LargeStoryWidget extends StatelessWidget {
  final String profileImageUrl;
  final String username;
  final String timeAgo;
  final bool isViewed;
  final VoidCallback? onProfileTap;
  final VoidCallback? onMoreTap;

  const LargeStoryWidget({
    super.key,
    required this.profileImageUrl,
    required this.username,
    required this.timeAgo,
    this.isViewed = false,
    this.onProfileTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          // Profile Image
          GestureDetector(
            onTap: onProfileTap,
            child: Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isViewed ? null : AppColors.storyGradient,
                border: isViewed
                    ? Border.all(
                        color: AppColors.storyViewed,
                        width: 2,
                      )
                    : null,
              ),
              child: Container(
                margin: EdgeInsets.all(isViewed ? 0 : 2.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white,
                ),
                child: Container(
                  margin: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(profileImageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          SizedBox(width: 12.w),
          
          // User Info
          Expanded(
            child: GestureDetector(
              onTap: onProfileTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.white.withOpacity(0.7),
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // More Button
          IconButton(
            onPressed: onMoreTap,
            icon: Icon(
              Icons.more_horiz,
              color: AppColors.white,
              size: 20.sp,
            ),
          ),
        ],
      ),
    );
  }
}

// Story Progress Indicator
class StoryProgressIndicator extends StatelessWidget {
  final int storyCount;
  final int currentIndex;
  final double progress;

  const StoryProgressIndicator({
    super.key,
    required this.storyCount,
    required this.currentIndex,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: List.generate(storyCount, (index) {
          return Expanded(
            child: Container(
              height: 2.h,
              margin: EdgeInsets.symmetric(horizontal: 1.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1.r),
                color: AppColors.white.withOpacity(0.3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: index == currentIndex
                    ? progress
                    : index < currentIndex
                        ? 1.0
                        : 0.0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1.r),
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

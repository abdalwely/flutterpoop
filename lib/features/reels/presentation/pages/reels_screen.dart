import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: 10,
        itemBuilder: (context, index) {
          return _buildReelItem(index);
        },
      ),
    );
  }

  Widget _buildReelItem(int index) {
    return Stack(
      children: [
        // Video Placeholder
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(
                'https://picsum.photos/400/800?random=${index + 200}',
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
        
        // Gradient Overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                AppColors.black.withOpacity(0.3),
              ],
            ),
          ),
        ),
        
        // Top Bar
        Positioned(
          top: MediaQuery.of(context).padding.top + 16.h,
          left: 16.w,
          right: 16.w,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppConstants.reels,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                  fontFamily: 'Cairo',
                ),
              ),
              Icon(
                Icons.camera_alt_outlined,
                color: AppColors.white,
                size: 24.sp,
              ),
            ],
          ),
        ),
        
        // Side Actions
        Positioned(
          right: 16.w,
          bottom: 100.h,
          child: Column(
            children: [
              // Like
              _buildActionButton(
                Icons.favorite_border,
                '${(index + 1) * 120}',
                () {},
              ),
              
              SizedBox(height: 24.h),
              
              // Comment
              _buildActionButton(
                Icons.mode_comment_outlined,
                '${(index + 1) * 15}',
                () {},
              ),
              
              SizedBox(height: 24.h),
              
              // Share
              _buildActionButton(
                Icons.send_outlined,
                '',
                () {},
              ),
              
              SizedBox(height: 24.h),
              
              // Save
              _buildActionButton(
                Icons.bookmark_border,
                '',
                () {},
              ),
            ],
          ),
        ),
        
        // Bottom Info
        Positioned(
          left: 16.w,
          right: 80.w,
          bottom: 50.h,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Username
              Row(
                children: [
                  CircleAvatar(
                    radius: 16.r,
                    backgroundImage: NetworkImage(
                      'https://picsum.photos/200?random=${index + 300}',
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'user_$index',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.white),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      'متابعة',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.white,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 8.h),
              
              // Caption
              Text(
                'هذا ريل تجريبي رقم ${index + 1} مع وصف قصير',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.white,
                  fontFamily: 'Cairo',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String count, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Icon(
            icon,
            color: AppColors.white,
            size: 28.sp,
          ),
        ),
        if (count.isNotEmpty) ...[
          SizedBox(height: 4.h),
          Text(
            count,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.white,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ],
    );
  }
}

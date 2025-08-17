import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/temp_auth_provider.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/custom_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: CustomAppBar(
        title: user?.username ?? AppConstants.profile,
        titleStyle: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          fontFamily: 'Cairo',
        ),
        showBackButton: false,
        actions: [
          IconButton(
            onPressed: () {
              // Navigate to settings
            },
            icon: Icon(
              Icons.menu,
              size: 24.sp,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                children: [
                  // Profile Image
                  CircleAvatar(
                    radius: 50.r,
                    backgroundColor: AppColors.inputBackground,
                    backgroundImage: user?.hasProfileImage == true
                        ? NetworkImage(user!.profileImageUrl)
                        : null,
                    child: user?.hasProfileImage != true
                        ? Icon(
                            Icons.person,
                            size: 50.sp,
                            color: AppColors.textSecondary,
                          )
                        : null,
                  ),
                  
                  SizedBox(height: 16.h),
                  
                  // Full Name
                  Text(
                    user?.fullName ?? 'الاسم الكامل',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  
                  SizedBox(height: 4.h),
                  
                  // Username
                  Text(
                    '@${user?.username ?? 'username'}',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: AppColors.textSecondary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  
                  if (user?.hasBio == true) ...[
                    SizedBox(height: 12.h),
                    Text(
                      user!.bio,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textPrimary,
                        fontFamily: 'Cairo',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  
                  SizedBox(height: 24.h),
                  
                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(
                        user?.postsText ?? '0',
                        AppConstants.posts,
                      ),
                      _buildStatItem(
                        user?.followerText ?? '0',
                        AppConstants.followers,
                      ),
                      _buildStatItem(
                        user?.followingText ?? '0',
                        AppConstants.following,
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 24.h),
                  
                  // Edit Profile Button
                  CustomButton(
                    text: AppConstants.editProfile,
                    isOutlined: true,
                    onPressed: () {
                      // Navigate to edit profile
                    },
                  ),
                ],
              ),
            ),
            
            // Tab Bar
            DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    indicatorColor: AppColors.primary,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    tabs: [
                      Tab(
                        icon: Icon(Icons.grid_on, size: 20.sp),
                      ),
                      Tab(
                        icon: Icon(Icons.video_library_outlined, size: 20.sp),
                      ),
                    ],
                  ),
                  
                  // Posts Grid
                  SizedBox(
                    height: 400.h,
                    child: TabBarView(
                      children: [
                        // Posts Tab
                        _buildPostsGrid(),
                        
                        // Reels Tab
                        _buildReelsGrid(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // Logout Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: CustomButton(
                text: AppConstants.logout,
                backgroundColor: AppColors.error,
                onPressed: () => _showLogoutDialog(context, ref),
              ),
            ),
            
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontFamily: 'Cairo',
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _buildPostsGrid() {
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2.w,
        mainAxisSpacing: 2.w,
        childAspectRatio: 1,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.shimmerBase,
            image: DecorationImage(
              image: NetworkImage(
                'https://picsum.photos/300?random=${index + 400}',
              ),
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  Widget _buildReelsGrid() {
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2.w,
        mainAxisSpacing: 2.w,
        childAspectRatio: 0.75,
      ),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.shimmerBase,
            image: DecorationImage(
              image: NetworkImage(
                'https://picsum.photos/300/400?random=${index + 500}',
              ),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                bottom: 8.h,
                left: 8.w,
                child: Icon(
                  Icons.play_arrow,
                  color: AppColors.white,
                  size: 20.sp,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من أنك تريد تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(authProvider.notifier).signOut();
            },
            child: Text(
              'تسجيل الخروج',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

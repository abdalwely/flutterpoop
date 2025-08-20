import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/custom_button.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: AppConstants.addPost,
        titleStyle: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          fontFamily: 'Cairo',
        ),
        showBackButton: false,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Camera Icon
              Container(
                width: 100.w,
                height: 100.h,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt_outlined,
                  size: 50.sp,
                  color: AppColors.primary,
                ),
              ),
              
              SizedBox(height: 32.h),
              
              // Title
              Text(
                'شارك لحظاتك',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontFamily: 'Cairo',
                ),
              ),
              
              SizedBox(height: 16.h),
              
              // Description
              Text(
                'اختر صورة أو فيديو من معرض الصور أو التقط جديد',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.textSecondary,
                  fontFamily: 'Cairo',
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 48.h),
              
              // Buttons
              CustomButton(
                text: 'اختيار من المعرض',
                icon: Icons.photo_library_outlined,
                onPressed: () {
                  // Implement gallery picker
                },
              ),
              
              SizedBox(height: 16.h),
              
              CustomButton(
                text: 'التقاط صورة',
                icon: Icons.camera_alt_outlined,
                isOutlined: true,
                onPressed: () {
                  // Implement camera
                },
              ),
              
              SizedBox(height: 16.h),
              
              CustomButton(
                text: 'تسجيل فيديو',
                icon: Icons.videocam_outlined,
                isOutlined: true,
                onPressed: () {
                  // Implement video recording
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/custom_button.dart';
import 'create_post_screen.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickFromGallery() async {
    try {
      setState(() => _isLoading = true);

      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        final List<File> files = images.map((image) => File(image.path)).toList();
        _navigateToCreatePost(files);
      }
    } catch (e) {
      _showErrorSnackBar('فشل في اختيار الصور');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _takePhoto() async {
    try {
      setState(() => _isLoading = true);

      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        _navigateToCreatePost([File(photo.path)]);
      }
    } catch (e) {
      _showErrorSnackBar('فشل في التقاط الصورة');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _recordVideo() async {
    try {
      setState(() => _isLoading = true);

      final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
      if (video != null) {
        _navigateToCreatePost([File(video.path)]);
      }
    } catch (e) {
      _showErrorSnackBar('فشل في تسجيل الفيديو');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToCreatePost(List<File> files) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(initialMedia: files),
      ),
    ).then((result) {
      if (result == true) {
        // Post was created successfully, navigate back to home
        Navigator.pop(context);
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }

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
                onPressed: _pickFromGallery,
              ),

              SizedBox(height: 16.h),

              CustomButton(
                text: 'التقاط صورة',
                icon: Icons.camera_alt_outlined,
                isOutlined: true,
                onPressed: _takePhoto,
              ),

              SizedBox(height: 16.h),

              CustomButton(
                text: 'تسجيل فيديو',
                icon: Icons.videocam_outlined,
                isOutlined: true,
                onPressed: _recordVideo,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

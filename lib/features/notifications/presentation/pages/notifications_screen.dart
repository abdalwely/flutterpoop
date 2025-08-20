import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/custom_icons.dart';
import '../../../../shared/widgets/custom_app_bar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: AppConstants.notifications,
        titleStyle: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          fontFamily: 'Cairo',
        ),
      ),
      body: ListView.builder(
        itemCount: 15,
        itemBuilder: (context, index) {
          return _buildNotificationItem(index);
        },
      ),
    );
  }

  Widget _buildNotificationItem(int index) {
    final notificationType = index % 4;
    IconData icon;
    String message;
    Color iconColor;

    switch (notificationType) {
      case 0:
        icon = Icons.favorite;
        message = 'أعجب بمنشورك';
        iconColor = AppColors.like;
        break;
      case 1:
        icon = Icons.mode_comment;
        message = 'علق على منشورك';
        iconColor = AppColors.primary;
        break;
      case 2:
        icon = Icons.person_add;
        message = 'بدأ في متابعتك';
        iconColor = AppColors.primary;
        break;
      default:
        icon = CustomIcons.mention;
        message = 'ذكرك في تعليق';
        iconColor = AppColors.secondary;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: index % 5 == 0 ? AppColors.primary.withOpacity(0.05) : null,
      ),
      child: Row(
        children: [
          // Profile Image
          CircleAvatar(
            radius: 24.r,
            backgroundImage: NetworkImage(
              'https://picsum.photos/200?random=${index + 700}',
            ),
          ),
          
          SizedBox(width: 12.w),
          
          // Notification Icon
          Container(
            width: 32.w,
            height: 32.h,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16.sp,
              color: iconColor,
            ),
          ),
          
          SizedBox(width: 12.w),
          
          // Message
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'user_$index ',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  TextSpan(
                    text: message,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textPrimary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Time
          Text(
            '${index + 1}د',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textSecondary,
              fontFamily: 'Cairo',
            ),
          ),
          
          SizedBox(width: 8.w),
          
          // Post Thumbnail (for relevant notifications)
          if (notificationType == 0 || notificationType == 1)
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                image: DecorationImage(
                  image: NetworkImage(
                    'https://picsum.photos/200?random=${index + 800}',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

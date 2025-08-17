import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/custom_app_bar.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: AppConstants.messages,
        titleStyle: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          fontFamily: 'Cairo',
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Start new chat
            },
            icon: Icon(
              Icons.edit_outlined,
              size: 24.sp,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return _buildChatItem(index);
        },
      ),
    );
  }

  Widget _buildChatItem(int index) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28.r,
            backgroundImage: NetworkImage(
              'https://picsum.photos/200?random=${index + 600}',
            ),
          ),
          if (index % 3 == 0)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 16.w,
                height: 16.h,
                decoration: BoxDecoration(
                  color: AppColors.online,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.white,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        'user_$index',
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontFamily: 'Cairo',
        ),
      ),
      subtitle: Text(
        'هذه رسالة تجريبية رقم ${index + 1}',
        style: TextStyle(
          fontSize: 14.sp,
          color: AppColors.textSecondary,
          fontFamily: 'Cairo',
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${index + 1}د',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textSecondary,
              fontFamily: 'Cairo',
            ),
          ),
          if (index % 4 == 0) ...[
            SizedBox(height: 4.h),
            Container(
              width: 8.w,
              height: 8.h,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
      onTap: () {
        // Navigate to chat screen
      },
    );
  }
}

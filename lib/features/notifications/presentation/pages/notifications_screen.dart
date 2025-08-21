import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/providers/auth_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (!authState.isAuthenticated) {
      return Scaffold(
        appBar: CustomAppBar(
          title: AppConstants.notifications,
          showBackButton: false,
        ),
        body: const Center(
          child: Text(
            'يجب تسجيل الدخول أولاً',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: AppConstants.notifications,
        titleStyle: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          fontFamily: 'Cairo',
        ),
        showBackButton: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Cairo',
            fontSize: 14.sp,
          ),
          tabs: const [
            Tab(text: 'الكل'),
            Tab(text: 'المتابعة'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllNotifications(),
          _buildFollowingNotifications(),
        ],
      ),
    );
  }

  Widget _buildAllNotifications() {
    // Mock notifications data
    final notifications = [
      {
        'type': 'like',
        'user': 'محمد أحمد',
        'avatar': 'https://picsum.photos/200?random=1',
        'time': 'منذ ساعة',
        'post': 'https://picsum.photos/400?random=10',
        'message': 'أعجب بمنشورك',
      },
      {
        'type': 'follow',
        'user': 'سارة محمد',
        'avatar': 'https://picsum.photos/200?random=2',
        'time': 'منذ ساعتين',
        'message': 'بدأت بمتابعتك',
      },
      {
        'type': 'comment',
        'user': 'أحمد علي',
        'avatar': 'https://picsum.photos/200?random=3',
        'time': 'منذ 3 ساعات',
        'post': 'https://picsum.photos/400?random=11',
        'message': 'عل�� على منشورك: "رائع جداً!"',
      },
      {
        'type': 'story',
        'user': 'فاطمة سالم',
        'avatar': 'https://picsum.photos/200?random=4',
        'time': 'منذ 5 ساعات',
        'message': 'شاهدت قصتك',
      },
      {
        'type': 'like',
        'user': 'خالد محمود',
        'avatar': 'https://picsum.photos/200?random=5',
        'time': 'أمس',
        'post': 'https://picsum.photos/400?random=12',
        'message': 'أعجب بمنشورك',
      },
    ];

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationItem(notification);
      },
    );
  }

  Widget _buildFollowingNotifications() {
    // Mock following notifications
    final followingNotifications = [
      {
        'type': 'like',
        'user': 'محمد أحمد',
        'avatar': 'https://picsum.photos/200?random=1',
        'time': 'منذ ساعة',
        'post': 'https://picsum.photos/400?random=10',
        'message': 'أعجب بمنشورك',
      },
      {
        'type': 'comment',
        'user': 'أحمد علي',
        'avatar': 'https://picsum.photos/200?random=3',
        'time': 'منذ 3 ساعات',
        'post': 'https://picsum.photos/400?random=11',
        'message': 'علق على منشورك: "رائع جداً!"',
      },
    ];

    if (followingNotifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64.sp,
              color: AppColors.textSecondary,
            ),
            
            SizedBox(height: 16.h),
            
            Text(
              'لا توجد إشعارات من المتابعين',
              style: TextStyle(
                fontSize: 18.sp,
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      itemCount: followingNotifications.length,
      itemBuilder: (context, index) {
        final notification = followingNotifications[index];
        return _buildNotificationItem(notification);
      },
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final type = notification['type'] as String;
    final hasPost = notification['post'] != null;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      leading: Container(
        width: 50.w,
        height: 50.h,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: CachedNetworkImageProvider(notification['avatar']),
            fit: BoxFit.cover,
          ),
        ),
      ),
      
      title: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: notification['user'],
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Cairo',
              ),
            ),
            TextSpan(
              text: ' ${notification['message']}',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textPrimary,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
      
      subtitle: Padding(
        padding: EdgeInsets.only(top: 4.h),
        child: Text(
          notification['time'],
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.textSecondary,
            fontFamily: 'Cairo',
          ),
        ),
      ),
      
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasPost)
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(notification['post']),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else if (type == 'follow')
            SizedBox(
              width: 80.w,
              height: 32.h,
              child: ElevatedButton(
                onPressed: () => _followBack(notification['user']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  'متابعة',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ),
        ],
      ),
      
      onTap: () => _handleNotificationTap(notification),
    );
  }

  void _followBack(String username) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تمت متابعة $username'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    final type = notification['type'] as String;
    
    switch (type) {
      case 'like':
      case 'comment':
        // Navigate to post
        print('Navigate to post');
        break;
      case 'follow':
        // Navigate to profile
        print('Navigate to profile');
        break;
      case 'story':
        // Navigate to story
        print('Navigate to story');
        break;
    }
  }
}

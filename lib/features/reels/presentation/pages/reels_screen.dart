import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/reels_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/follow_provider.dart';
import '../../../../shared/models/reel_model.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../post/presentation/pages/comments_screen.dart';
import '../../../profile/presentation/pages/profile_screen.dart';
import 'create_reel_screen.dart';

class ReelsScreen extends ConsumerStatefulWidget {
  const ReelsScreen({super.key});

  @override
  ConsumerState<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends ConsumerState<ReelsScreen> {
  late PageController _pageController;
  Map<String, VideoPlayerController> _videoControllers = {};
  String? _currentPlayingVideo;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Load reels when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reelsProvider.notifier).loadReels();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _disposeVideoControllers();
    super.dispose();
  }

  void _disposeVideoControllers() {
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
  }

  Future<VideoPlayerController> _getVideoController(String videoUrl) async {
    if (_videoControllers.containsKey(videoUrl)) {
      return _videoControllers[videoUrl]!;
    }

    final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    await controller.initialize();
    controller.setLooping(true);
    
    _videoControllers[videoUrl] = controller;
    return controller;
  }

  void _playVideo(String videoUrl) {
    if (_currentPlayingVideo != null && _currentPlayingVideo != videoUrl) {
      _videoControllers[_currentPlayingVideo!]?.pause();
    }
    
    _currentPlayingVideo = videoUrl;
    _videoControllers[videoUrl]?.play();
  }

  void _pauseVideo(String videoUrl) {
    _videoControllers[videoUrl]?.pause();
  }

  @override
  Widget build(BuildContext context) {
    final reelsState = ref.watch(reelsProvider);
    final authState = ref.watch(authProvider);

    if (reelsState.isLoading && reelsState.reels.isEmpty) {
      return const LoadingOverlay.message(message: 'جاري تحميل الريلز...');
    }

    if (reelsState.error != null && reelsState.reels.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: AppColors.white,
                size: 48.sp,
              ),
              SizedBox(height: 16.h),
              Text(
                reelsState.error!,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16.sp,
                  fontFamily: 'Cairo',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: () => ref.read(reelsProvider.notifier).refreshReels(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: Text(
                  'إعادة المحاولة',
                  style: TextStyle(
                    color: AppColors.white,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (reelsState.reels.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.video_library_outlined,
                color: AppColors.white,
                size: 64.sp,
              ),
              SizedBox(height: 16.h),
              Text(
                'لا توجد ريلز متاحة',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'كن أول من ينشر ريل!',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 14.sp,
                  fontFamily: 'Cairo',
                ),
              ),
              SizedBox(height: 24.h),
              ElevatedButton.icon(
                onPressed: () => _navigateToCreateReel(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                ),
                icon: Icon(Icons.add, color: AppColors.white),
                label: Text(
                  'إنشاء ريل',
                  style: TextStyle(
                    color: AppColors.white,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          // Reels PageView
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: reelsState.reels.length,
            onPageChanged: (index) {
              ref.read(reelsProvider.notifier).setCurrentIndex(index);
              final reel = reelsState.reels[index];
              _playVideo(reel.videoUrl);
            },
            itemBuilder: (context, index) {
              final reel = reelsState.reels[index];
              return _buildReelItem(reel, authState.user?.uid);
            },
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
                GestureDetector(
                  onTap: _navigateToCreateReel,
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppColors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: AppColors.white,
                      size: 24.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading indicator for pagination
          if (reelsState.isLoading)
            Positioned(
              bottom: 100.h,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReelItem(ReelModel reel, String? currentUserId) {
    return Stack(
      children: [
        // Video Player
        FutureBuilder<VideoPlayerController>(
          future: _getVideoController(reel.videoUrl),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                color: AppColors.black,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                  ),
                ),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(reel.thumbnailUrl),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    color: AppColors.white,
                    size: 64.sp,
                  ),
                ),
              );
            }

            final controller = snapshot.data!;
            return GestureDetector(
              onTap: () {
                if (controller.value.isPlaying) {
                  _pauseVideo(reel.videoUrl);
                } else {
                  _playVideo(reel.videoUrl);
                }
              },
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                ),
              ),
            );
          },
        ),

        // Gradient Overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.transparent,
                AppColors.black.withOpacity(0.6),
              ],
              stops: const [0.0, 0.7, 1.0],
            ),
          ),
        ),

        // Side Actions
        Positioned(
          right: 16.w,
          bottom: 100.h,
          child: Column(
            children: [
              // Profile Picture
              GestureDetector(
                onTap: () => _navigateToProfile(reel.userId),
                child: Container(
                  width: 50.w,
                  height: 50.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      reel.userProfileImage.isNotEmpty 
                          ? reel.userProfileImage
                          : 'https://via.placeholder.com/150',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.grey,
                          child: Icon(
                            Icons.person,
                            color: AppColors.white,
                            size: 24.sp,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              // Like Button
              _buildActionButton(
                icon: reel.isLikedBy(currentUserId ?? '') 
                    ? Icons.favorite 
                    : Icons.favorite_border,
                count: reel.likesText,
                onTap: () => _toggleLike(reel.id),
                isActive: reel.isLikedBy(currentUserId ?? ''),
              ),

              SizedBox(height: 24.h),

              // Comment Button
              _buildActionButton(
                icon: Icons.mode_comment_outlined,
                count: reel.commentsText,
                onTap: () => _openComments(reel),
              ),

              SizedBox(height: 24.h),

              // Share Button
              _buildActionButton(
                icon: Icons.send_outlined,
                count: reel.sharesCount > 0 ? reel.sharesCount.toString() : '',
                onTap: () => _shareReel(reel),
              ),

              SizedBox(height: 24.h),

              // Save Button
              _buildActionButton(
                icon: reel.isSavedBy(currentUserId ?? '') 
                    ? Icons.bookmark 
                    : Icons.bookmark_border,
                count: '',
                onTap: () => _toggleSave(reel.id),
                isActive: reel.isSavedBy(currentUserId ?? ''),
              ),

              SizedBox(height: 24.h),

              // More Options
              _buildActionButton(
                icon: Icons.more_vert,
                count: '',
                onTap: () => _showMoreOptions(reel),
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
              // User Info and Follow Button
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _navigateToProfile(reel.userId),
                    child: CircleAvatar(
                      radius: 16.r,
                      backgroundImage: NetworkImage(
                        reel.userProfileImage.isNotEmpty 
                            ? reel.userProfileImage
                            : 'https://via.placeholder.com/150',
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _navigateToProfile(reel.userId),
                      child: Row(
                        children: [
                          Text(
                            reel.username,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          if (reel.isUserVerified) ...[
                            SizedBox(width: 4.w),
                            Icon(
                              Icons.verified,
                              color: AppColors.primary,
                              size: 16.sp,
                            ),
                          ],
                          SizedBox(width: 8.w),
                          Text(
                            '• ${reel.timeAgo}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.grey,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Follow Button
                  if (reel.userId != currentUserId)
                    Consumer(
                      builder: (context, ref, child) {
                        final followState = ref.watch(followStatusProvider(reel.userId));
                        return followState.when(
                          data: (isFollowing) => GestureDetector(
                            onTap: () => _toggleFollow(reel.userId),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: isFollowing ? AppColors.grey : AppColors.primary,
                                borderRadius: BorderRadius.circular(6.r),
                                border: isFollowing 
                                    ? Border.all(color: AppColors.white.withOpacity(0.3))
                                    : null,
                              ),
                              child: Text(
                                isFollowing ? 'متابَع' : 'متابعة',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                          ),
                          loading: () => Container(
                            width: 60.w,
                            height: 28.h,
                            decoration: BoxDecoration(
                              color: AppColors.grey.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                          ),
                          error: (error, stack) => const SizedBox.shrink(),
                        );
                      },
                    ),
                ],
              ),

              SizedBox(height: 12.h),

              // Caption
              if (reel.caption.isNotEmpty)
                Text(
                  reel.caption,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.white,
                    fontFamily: 'Cairo',
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              // Audio Info
              if (reel.audio != null) ...[
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(
                      Icons.music_note,
                      color: AppColors.white,
                      size: 16.sp,
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        '${reel.audio!.name} - ${reel.audio!.artist}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.white,
                          fontFamily: 'Cairo',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // Views count
              SizedBox(height: 8.h),
              Text(
                reel.viewsText,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.grey,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String count,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 50.w,
            height: 50.h,
            decoration: BoxDecoration(
              color: AppColors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? AppColors.error : AppColors.white,
              size: 28.sp,
            ),
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
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  // Action methods
  void _toggleLike(String reelId) {
    ref.read(reelsProvider.notifier).toggleLike(reelId);
  }

  void _toggleSave(String reelId) {
    ref.read(reelsProvider.notifier).toggleSave(reelId);
  }

  void _toggleFollow(String userId) {
    ref.read(reelsProvider.notifier).toggleFollow(userId);
    // Invalidate follow status to refresh
    ref.invalidate(followStatusProvider(userId));
  }

  void _shareReel(ReelModel reel) async {
    ref.read(reelsProvider.notifier).shareReel(reel.id);
    
    // Share using system share
    final shareText = 'شاهد هذا الريل الرائع من ${reel.username}\n\n${reel.caption}';
    await Share.share(
      shareText,
      subject: 'ريل من ${reel.username}',
    );
  }

  void _openComments(ReelModel reel) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CommentsScreen(
          postId: reel.id,
          postType: 'reel',
        ),
      ),
    );
  }

  void _navigateToProfile(String userId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: userId),
      ),
    );
  }

  void _navigateToCreateReel() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateReelScreen(),
      ),
    ).then((result) {
      if (result == true) {
        // Refresh reels after creating new one
        ref.read(reelsProvider.notifier).refreshReels();
      }
    });
  }

  void _showMoreOptions(ReelModel reel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.accent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.grey,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),
            
            if (reel.userId == ref.read(authProvider).user?.uid) ...[
              _buildOptionItem(
                icon: Icons.edit,
                title: 'تعديل',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to edit reel
                },
              ),
              _buildOptionItem(
                icon: Icons.delete_outline,
                title: 'حذف',
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(reel);
                },
              ),
            ] else ...[
              _buildOptionItem(
                icon: Icons.report_outlined,
                title: 'إبلاغ',
                onTap: () {
                  Navigator.pop(context);
                  _reportReel(reel);
                },
              ),
              _buildOptionItem(
                icon: Icons.block_outlined,
                title: 'حظر المستخدم',
                onTap: () {
                  Navigator.pop(context);
                  _blockUser(reel.userId);
                },
              ),
            ],
            
            _buildOptionItem(
              icon: Icons.link,
              title: 'نسخ الرابط',
              onTap: () {
                Navigator.pop(context);
                _copyLink(reel);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.white),
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.white,
          fontFamily: 'Cairo',
        ),
      ),
      onTap: onTap,
    );
  }

  void _showDeleteConfirmation(ReelModel reel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.accent,
        title: Text(
          'حذف ال��يل',
          style: TextStyle(color: AppColors.white, fontFamily: 'Cairo'),
        ),
        content: Text(
          'هل أنت متأكد من حذف هذا الريل؟',
          style: TextStyle(color: AppColors.white, fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: TextStyle(color: AppColors.grey, fontFamily: 'Cairo'),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteReel(reel.id);
            },
            child: Text(
              'حذف',
              style: TextStyle(color: AppColors.error, fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteReel(String reelId) {
    // Implement delete reel functionality
  }

  void _reportReel(ReelModel reel) {
    // Implement report reel functionality
  }

  void _blockUser(String userId) {
    // Implement block user functionality
  }

  void _copyLink(ReelModel reel) {
    // Implement copy link functionality
  }
}

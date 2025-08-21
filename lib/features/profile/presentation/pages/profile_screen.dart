import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/posts_provider.dart';
import '../../../../shared/providers/reels_provider.dart';
import '../../../../shared/services/firestore_service.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../auth/presentation/pages/login_screen.dart';
import '../../../reels/presentation/pages/reels_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String? userId; // If null, show current user's profile
  
  const ProfileScreen({super.key, this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  UserModel? _profileUser;
  bool _isLoading = true;
  bool _isFollowing = false;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final authState = ref.read(authProvider);
      
      if (widget.userId == null) {
        // Show current user's profile
        _profileUser = authState.user;
      } else {
        // Load specific user's profile
        final firestoreService = FirestoreService();
        _profileUser = await firestoreService.getUser(widget.userId!);
        
        // Check if current user is following this user
        if (authState.user != null && _profileUser != null) {
          _isFollowing = await firestoreService.isFollowing(
            authState.user!.uid, 
            _profileUser!.uid,
          );
        }
      }
      
      // Load user's posts
      if (_profileUser != null) {
        await ref.read(userPostsProvider(_profileUser!.uid).notifier)
            .loadUserPosts(_profileUser!.uid, refresh: true);
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  bool get _isOwnProfile {
    final authState = ref.read(authProvider);
    return widget.userId == null || widget.userId == authState.user?.uid;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    if (_isLoading) {
      return Scaffold(
        appBar: CustomAppBar(
          title: AppConstants.profile,
          showBackButton: widget.userId != null,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    
    if (_profileUser == null) {
      return Scaffold(
        appBar: CustomAppBar(
          title: AppConstants.profile,
          showBackButton: widget.userId != null,
        ),
        body: const Center(
          child: Text('لم يتم العثور على المستخدم'),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: _profileUser?.username ?? AppConstants.profile,
        titleStyle: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          fontFamily: 'Cairo',
        ),
        showBackButton: widget.userId != null,
        actions: _isOwnProfile ? [
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
        ] : null,
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
                    backgroundImage: _profileUser!.hasProfileImage
                        ? NetworkImage(_profileUser!.profileImageUrl)
                        : null,
                    child: !_profileUser!.hasProfileImage
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
                    _profileUser!.fullName.isNotEmpty 
                      ? _profileUser!.fullName 
                      : _profileUser!.username,
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
                    '@${_profileUser!.username}',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: AppColors.textSecondary,
                      fontFamily: 'Cairo',
                    ),
                  ),

                  if (_profileUser!.hasBio) ...[
                    SizedBox(height: 12.h),
                    Text(
                      _profileUser!.bio,
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
                        _profileUser?.postsText ?? '0',
                        AppConstants.posts,
                      ),
                      _buildStatItem(
                        _profileUser?.followerText ?? '0',
                        AppConstants.followers,
                      ),
                      _buildStatItem(
                        _profileUser?.followingText ?? '0',
                        AppConstants.following,
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // Action Button (Edit Profile or Follow)
                  if (_isOwnProfile)
                    CustomButton(
                      text: AppConstants.editProfile,
                      isOutlined: true,
                      onPressed: () {
                        // Navigate to edit profile
                      },
                    )
                  else
                    CustomButton(
                      text: _isFollowing ? AppConstants.unfollow : AppConstants.follow,
                      isOutlined: _isFollowing,
                      onPressed: _toggleFollow,
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

            // Logout Button (only for own profile)
            if (_isOwnProfile)
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
    if (_profileUser == null) return const SizedBox.shrink();
    
    final postsState = ref.watch(userPostsProvider(_profileUser!.uid));
    
    if (postsState.isLoading && postsState.posts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    
    if (postsState.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 64.sp,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16.h),
            Text(
              'لا توجد منشورات',
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
    
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2.w,
        mainAxisSpacing: 2.w,
        childAspectRatio: 1,
      ),
      itemCount: postsState.posts.length,
      itemBuilder: (context, index) {
        final post = postsState.posts[index];
        return GestureDetector(
          onTap: () {
            // Navigate to post detail
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.shimmerBase,
              image: DecorationImage(
                image: NetworkImage(post.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: post.media.length > 1
              ? Positioned(
                  top: 8.h,
                  right: 8.w,
                  child: Icon(
                    Icons.collections,
                    color: AppColors.white,
                    size: 16.sp,
                  ),
                )
              : null,
          ),
        );
      },
    );
  }

  Widget _buildReelsGrid() {
    if (_profileUser == null) return const SizedBox.shrink();

    final userReelsAsync = ref.watch(userReelsProvider(_profileUser!.uid));

    return userReelsAsync.when(
      data: (reels) {
        if (reels.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.video_library_outlined,
                  size: 64.sp,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 16.h),
                Text(
                  'لا توجد ريلز',
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

        return GridView.builder(
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2.w,
            mainAxisSpacing: 2.w,
            childAspectRatio: 0.75,
          ),
          itemCount: reels.length,
          itemBuilder: (context, index) {
            final reel = reels[index];
            return GestureDetector(
              onTap: () {
                // Navigate to reels screen with this specific reel
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ReelsScreen(),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.shimmerBase,
                  image: DecorationImage(
                    image: NetworkImage(reel.thumbnailUrl),
                    fit: BoxFit.cover,
                    onError: (error, stackTrace) {
                      // Handle error loading thumbnail
                    },
                  ),
                ),
                child: Stack(
                  children: [
                    // Play button overlay
                    Positioned(
                      bottom: 8.h,
                      left: 8.w,
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: AppColors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: AppColors.white,
                          size: 16.sp,
                        ),
                      ),
                    ),

                    // Views count
                    Positioned(
                      bottom: 8.h,
                      right: 8.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppColors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          reel.viewsCount > 999
                              ? '${(reel.viewsCount / 1000).toStringAsFixed(1)}ك'
                              : reel.viewsCount.toString(),
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ),

                    // Duration
                    Positioned(
                      top: 8.h,
                      right: 8.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppColors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          reel.durationText,
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48.sp,
              color: AppColors.error,
            ),
            SizedBox(height: 16.h),
            Text(
              'فشل في تحميل الريلز',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.error,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _toggleFollow() async {
    final auth = ref.read(authProvider);
    if (auth.user == null || _profileUser == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final firestoreService = FirestoreService();
      
      if (_isFollowing) {
        await firestoreService.unfollowUser(auth.user!.uid, _profileUser!.uid);
        setState(() => _isFollowing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إلغاء متابعة ${_profileUser!.username}'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        await firestoreService.followUser(auth.user!.uid, _profileUser!.uid);
        setState(() => _isFollowing = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تمت متابعة ${_profileUser!.username}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      
      // Reload user data to update follower count
      await _loadUserData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحديث حالة المتابعة'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(authProvider.notifier).signOut();

              // Navigate to login screen
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                      (route) => false,
                );
              }
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/models/post_model.dart';
import '../../../../shared/providers/follow_provider.dart';
import '../../../../shared/widgets/enhanced_post_widget.dart';
import 'followers_following_screen.dart';

class EnhancedProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  final bool isCurrentUser;

  const EnhancedProfileScreen({
    super.key,
    required this.userId,
    this.isCurrentUser = false,
  });

  @override
  ConsumerState<EnhancedProfileScreen> createState() => _EnhancedProfileScreenState();
}

class _EnhancedProfileScreenState extends ConsumerState<EnhancedProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  
  bool _isHeaderExpanded = true;
  UserModel? _user;
  List<PostModel> _posts = [];
  List<PostModel> _reels = [];
  List<PostModel> _tagged = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    const threshold = 200.0;
    if (_scrollController.offset > threshold && _isHeaderExpanded) {
      setState(() => _isHeaderExpanded = false);
    } else if (_scrollController.offset <= threshold && !_isHeaderExpanded) {
      setState(() => _isHeaderExpanded = true);
    }
  }

  void _loadUserData() {
    // Mock data - في التطبيق الحقيقي ستأتي من Firebase
    _user = UserModel(
      id: widget.userId,
      username: 'ahmed_mohamed',
      displayName: 'أحمد محمد',
      email: 'ahmed@example.com',
      profilePicture: '',
      bio: 'مطور تطبيقات موبايل 📱\nأحب التصوير والسفر 📸✈️\nمن الرياض، السعودية 🇸🇦',
      website: 'https://ahmed.dev',
      isVerified: true,
      isPrivate: false,
      followersCount: 1250,
      followingCount: 890,
      postsCount: 156,
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildSliverAppBar(),
            _buildProfileHeader(),
            _buildTabBar(),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPostsGrid(),
            _buildReelsGrid(),
            _buildTaggedGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: AppColors.white,
      elevation: 0,
      title: AnimatedOpacity(
        opacity: _isHeaderExpanded ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Text(
          _user!.username,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontFamily: 'Cairo',
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _showMenu,
          icon: Icon(
            Icons.menu,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return SliverToBoxAdapter(
      child: Container(
        color: AppColors.white,
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Profile image and stats
            Row(
              children: [
                // Profile image
                Container(
                  width: 90.w,
                  height: 90.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _user!.hasStory 
                        ? LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                          )
                        : null,
                  ),
                  padding: EdgeInsets.all(_user!.hasStory ? 3.w : 0),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: _user!.hasStory 
                          ? Border.all(color: AppColors.white, width: 3)
                          : null,
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: _user!.profilePicture,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.primary,
                          child: Icon(
                            Icons.person,
                            color: AppColors.white,
                            size: 40.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(width: 20.w),
                
                // Stats
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem('${_user!.postsCount}', 'منشور'),
                      _buildStatItem('${_user!.followersCount}', 'متابع', onTap: _showFollowers),
                      _buildStatItem('${_user!.followingCount}', 'يتابع', onTap: _showFollowing),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16.h),
            
            // Name and verification
            Row(
              children: [
                Text(
                  _user!.displayName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontFamily: 'Cairo',
                  ),
                ),
                if (_user!.isVerified) ...[
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.verified,
                    color: AppColors.primary,
                    size: 18.sp,
                  ),
                ],
              ],
            ),
            
            // Bio
            if (_user!.bio.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _user!.bio,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textPrimary,
                    fontFamily: 'Cairo',
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
            
            // Website
            if (_user!.website.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => _openWebsite(_user!.website),
                  child: Text(
                    _user!.website,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.primary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ),
            ],
            
            SizedBox(height: 16.h),
            
            // Action buttons
            _buildActionButtons(),
            
            SizedBox(height: 16.h),
            
            // Highlights
            _buildHighlights(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String count, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
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
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textSecondary,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (widget.isCurrentUser) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _editProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.inputBackground,
                foregroundColor: AppColors.textPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'تعديل الملف الشخصي',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          ElevatedButton(
            onPressed: _shareProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.inputBackground,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Icon(Icons.share),
          ),
        ],
      );
    } else {
      final isFollowing = ref.watch(userFollowStatusProvider(_user!.id));
      
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => ref.read(followProvider.notifier).toggleFollow(_user!.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowing ? AppColors.inputBackground : AppColors.primary,
                foregroundColor: isFollowing ? AppColors.textPrimary : AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                isFollowing ? 'إلغاء المتابعة' : 'متابعة',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          ElevatedButton(
            onPressed: _sendMessage,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.inputBackground,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'رسالة',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
          SizedBox(width: 8.w),
          ElevatedButton(
            onPressed: _showMoreOptions,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.inputBackground,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Icon(Icons.keyboard_arrow_down),
          ),
        ],
      );
    }
  }

  Widget _buildHighlights() {
    return SizedBox(
      height: 80.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Add highlight (only for current user)
          if (widget.isCurrentUser) _buildAddHighlight(),
          
          // Sample highlights
          ...List.generate(5, (index) => _buildHighlightItem('ذكريات ${index + 1}')),
        ],
      ),
    );
  }

  Widget _buildAddHighlight() {
    return Padding(
      padding: EdgeInsets.only(left: 12.w),
      child: Column(
        children: [
          Container(
            width: 60.w,
            height: 60.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: Icon(
              Icons.add,
              color: AppColors.textSecondary,
              size: 24.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'جديد',
            style: TextStyle(
              fontSize: 10.sp,
              color: AppColors.textSecondary,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightItem(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 12.w),
      child: Column(
        children: [
          Container(
            width: 60.w,
            height: 60.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 2),
              color: AppColors.inputBackground,
            ),
            child: Icon(
              Icons.photo,
              color: AppColors.textSecondary,
              size: 24.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppColors.textSecondary,
              fontFamily: 'Cairo',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverTabBarDelegate(
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.grid_on)),
            Tab(icon: Icon(Icons.video_library)),
            Tab(icon: Icon(Icons.person_pin)),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildPostsGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(2.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2.w,
        mainAxisSpacing: 2.h,
      ),
      itemCount: 20, // Mock data
      itemBuilder: (context, index) {
        return Container(
          color: AppColors.inputBackground,
          child: Center(
            child: Icon(
              Icons.photo,
              color: AppColors.textSecondary,
              size: 40.sp,
            ),
          ),
        );
      },
    );
  }

  Widget _buildReelsGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(2.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2.w,
        mainAxisSpacing: 2.h,
        childAspectRatio: 9 / 16,
      ),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Container(
          color: AppColors.black,
          child: Center(
            child: Icon(
              Icons.play_arrow,
              color: AppColors.white,
              size: 40.sp,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaggedGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(2.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2.w,
        mainAxisSpacing: 2.h,
      ),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          color: AppColors.inputBackground,
          child: Center(
            child: Icon(
              Icons.person_pin,
              color: AppColors.textSecondary,
              size: 40.sp,
            ),
          ),
        );
      },
    );
  }

  // Action methods
  void _showFollowers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowersFollowingScreen(
          userId: _user!.id,
          username: _user!.username,
          initialTab: 0,
        ),
      ),
    );
  }

  void _showFollowing() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowersFollowingScreen(
          userId: _user!.id,
          username: _user!.username,
          initialTab: 1,
        ),
      ),
    );
  }

  void _editProfile() {
    // Implementation for editing profile
  }

  void _shareProfile() {
    // Implementation for sharing profile
  }

  void _sendMessage() {
    // Implementation for sending message
  }

  void _showMoreOptions() {
    // Implementation for more options
  }

  void _showMenu() {
    // Implementation for menu
  }

  void _openWebsite(String url) {
    // Implementation for opening website
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/providers/follow_provider.dart';
import '../../../../shared/services/follow_service.dart';
import '../../../../shared/widgets/custom_app_bar.dart';

class FollowersFollowingScreen extends ConsumerStatefulWidget {
  final String userId;
  final String username;
  final int initialTab; // 0 for followers, 1 for following

  const FollowersFollowingScreen({
    super.key,
    required this.userId,
    required this.username,
    this.initialTab = 0,
  });

  @override
  ConsumerState<FollowersFollowingScreen> createState() => _FollowersFollowingScreenState();
}

class _FollowersFollowingScreenState extends ConsumerState<FollowersFollowingScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  List<UserModel> _followers = [];
  List<UserModel> _following = [];
  List<UserModel> _filteredFollowers = [];
  List<UserModel> _filteredFollowing = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterUsers();
    });
  }

  void _filterUsers() {
    _filteredFollowers = _followers.where((user) {
      return user.username.toLowerCase().contains(_searchQuery) ||
             user.displayName.toLowerCase().contains(_searchQuery);
    }).toList();

    _filteredFollowing = _following.where((user) {
      return user.username.toLowerCase().contains(_searchQuery) ||
             user.displayName.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final futures = await Future.wait([
        FollowService.getFollowers(widget.userId),
        FollowService.getFollowing(widget.userId),
      ]);
      
      setState(() {
        _followers = futures[0];
        _following = futures[1];
        _filterUsers();
        _isLoading = false;
      });

      // Load follow status for all users
      final allUserIds = [..._followers, ..._following]
          .map((user) => user.id)
          .toSet()
          .toList();
      
      if (allUserIds.isNotEmpty) {
        ref.read(followProvider.notifier).batchLoadFollowStatus(allUserIds);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: widget.username,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16.w),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'البحث',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontFamily: 'Cairo',
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              ),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontFamily: 'Cairo',
              ),
            ),
          ),

          // Tab Bar
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12.r),
              ),
              labelColor: AppColors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'Cairo',
                fontSize: 14.sp,
              ),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w500,
                fontFamily: 'Cairo',
                fontSize: 14.sp,
              ),
              tabs: [
                Tab(text: 'المتابعون (${_followers.length})'),
                Tab(text: 'يتابع (${_following.length})'),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFollowersList(),
                      _buildFollowingList(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowersList() {
    if (_filteredFollowers.isEmpty) {
      return _buildEmptyState(
        'لا يوجد متابعون',
        _searchQuery.isNotEmpty 
            ? 'لا توجد نتائج للبحث'
            : 'لا يوجد متابعون حتى الآن',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: _filteredFollowers.length,
      itemBuilder: (context, index) {
        final user = _filteredFollowers[index];
        return UserListItem(
          user: user,
          showFollowButton: true,
          showRemoveButton: true, // Can remove followers
          onRemove: () => _removeFollower(user.id),
        );
      },
    );
  }

  Widget _buildFollowingList() {
    if (_filteredFollowing.isEmpty) {
      return _buildEmptyState(
        'لا يتابع أحد',
        _searchQuery.isNotEmpty 
            ? 'لا توجد نتائج للبحث'
            : 'لا يتابع أي شخص حتى الآن',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: _filteredFollowing.length,
      itemBuilder: (context, index) {
        final user = _filteredFollowing[index];
        return UserListItem(
          user: user,
          showFollowButton: true,
          showRemoveButton: false,
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64.sp,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 16.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
              fontFamily: 'Cairo',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _removeFollower(String followerId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'إزالة المتابع',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'هل تريد إزالة هذا المتابع؟',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'إلغاء',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'إزالة',
              style: TextStyle(
                color: AppColors.error,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      await ref.read(followProvider.notifier).removeFollower(followerId);
      _loadData(); // Refresh the list
    }
  }
}

class UserListItem extends ConsumerWidget {
  final UserModel user;
  final bool showFollowButton;
  final bool showRemoveButton;
  final VoidCallback? onRemove;

  const UserListItem({
    super.key,
    required this.user,
    this.showFollowButton = true,
    this.showRemoveButton = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFollowing = ref.watch(userFollowStatusProvider(user.id));
    final followStats = ref.watch(userFollowStatsProvider(user.id));

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Image
          Container(
            width: 50.w,
            height: 50.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.border,
                width: 1,
              ),
            ),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: user.profilePicture,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.shimmerBase,
                  child: Icon(
                    Icons.person,
                    color: AppColors.textSecondary,
                    size: 24.sp,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.inputBackground,
                  child: Icon(
                    Icons.person,
                    color: AppColors.textSecondary,
                    size: 24.sp,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(width: 12.w),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.username,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    if (user.isVerified) ...[
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.verified,
                        color: AppColors.primary,
                        size: 16.sp,
                      ),
                    ],
                  ],
                ),
                if (user.displayName.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    user.displayName,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
                SizedBox(height: 4.h),
                Text(
                  '${followStats['followersCount']} متابع',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showFollowButton)
                FollowButton(
                  userId: user.id,
                  isFollowing: isFollowing,
                ),
              if (showRemoveButton) ...[
                SizedBox(width: 8.w),
                IconButton(
                  onPressed: onRemove,
                  icon: Icon(
                    Icons.person_remove,
                    color: AppColors.error,
                    size: 20.sp,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class FollowButton extends ConsumerWidget {
  final String userId;
  final bool isFollowing;

  const FollowButton({
    super.key,
    required this.userId,
    required this.isFollowing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(followProvider.notifier).toggleFollow(userId),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isFollowing ? AppColors.inputBackground : AppColors.primary,
          borderRadius: BorderRadius.circular(8.r),
          border: isFollowing 
              ? Border.all(color: AppColors.border)
              : null,
        ),
        child: Text(
          isFollowing ? 'إلغاء المتابعة' : 'متابعة',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isFollowing ? AppColors.textPrimary : AppColors.white,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    );
  }
}

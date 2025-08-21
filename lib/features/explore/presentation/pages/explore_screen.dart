import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/posts_provider.dart';
import '../../../../shared/services/follow_service.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/models/post_model.dart';
import '../../../profile/presentation/pages/profile_screen.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  
  Timer? _searchDebounce;
  List<UserModel> _searchResults = [];
  List<PostModel> _trendingPosts = [];
  bool _isSearching = false;
  bool _isLoadingTrending = false;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTrendingPosts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadTrendingPosts() async {
    setState(() => _isLoadingTrending = true);
    
    try {
      final trendingPosts = await ref.read(trendingPostsProvider.future);
      setState(() => _trendingPosts = trendingPosts);
    } catch (e) {
      print('Error loading trending posts: $e');
    } finally {
      setState(() => _isLoadingTrending = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    
    setState(() {
      _currentQuery = query;
      if (query.isEmpty) {
        _searchResults.clear();
        _isSearching = false;
      }
    });
    
    if (query.isNotEmpty) {
      _searchDebounce = Timer(AppConstants.searchDebounceTime, () {
        _performSearch(query);
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    
    setState(() => _isSearching = true);
    
    try {
      final results = await FollowService.searchUsers(query);
      setState(() => _searchResults = results);
    } catch (e) {
      print('Search error: $e');
      setState(() => _searchResults = []);
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    return Scaffold(
      appBar: CustomAppBar(
        title: AppConstants.explore,
        titleStyle: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          fontFamily: 'Cairo',
        ),
        showBackButton: false,
      ),
      body: LoadingOverlay(
        isLoading: _isSearching || _isLoadingTrending,
        child: Column(
          children: [
            // Search Bar
            _buildSearchBar(),
            
            // Search Results or Explore Content
            Expanded(
              child: _currentQuery.isNotEmpty
                  ? _buildSearchResults()
                  : _buildExploreContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(25.r),
          border: Border.all(color: AppColors.border),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: TextStyle(
            fontSize: 16.sp,
            color: AppColors.textPrimary,
            fontFamily: 'Cairo',
          ),
          decoration: InputDecoration(
            hintText: AppConstants.searchHint,
            border: InputBorder.none,
            prefixIcon: Icon(
              Icons.search,
              color: AppColors.textSecondary,
              size: 20.sp,
            ),
            suffixIcon: _currentQuery.isNotEmpty
                ? IconButton(
                    onPressed: _clearSearch,
                    icon: Icon(
                      Icons.clear,
                      color: AppColors.textSecondary,
                      size: 20.sp,
                    ),
                  )
                : null,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 12.h,
            ),
            hintStyle: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16.sp,
              fontFamily: 'Cairo',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64.sp,
              color: AppColors.textSecondary,
            ),
            
            SizedBox(height: 16.h),
            
            Text(
              'لا توجد نتائج للبحث',
              style: TextStyle(
                fontSize: 18.sp,
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
            ),
            
            SizedBox(height: 8.h),
            
            Text(
              'جرب البحث بكلمات مختلفة',
              style: TextStyle(
                fontSize: 14.sp,
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
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildUserSearchItem(user);
      },
    );
  }

  Widget _buildUserSearchItem(UserModel user) {
    final authState = ref.watch(authProvider);
    final isCurrentUser = authState.user?.uid == user.uid;
    
    return ListTile(
      leading: GestureDetector(
        onTap: () => _navigateToProfile(user.uid),
        child: Container(
          width: 50.w,
          height: 50.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: user.hasProfileImage
                ? DecorationImage(
                    image: CachedNetworkImageProvider(user.profileImageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
            color: user.hasProfileImage ? null : AppColors.inputBackground,
          ),
          child: !user.hasProfileImage
              ? Icon(
                  Icons.person,
                  color: AppColors.textSecondary,
                  size: 24.sp,
                )
              : null,
        ),
      ),
      
      title: GestureDetector(
        onTap: () => _navigateToProfile(user.uid),
        child: Row(
          children: [
            Text(
              user.username,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Cairo',
              ),
            ),
            
            if (user.isVerified) ...[
              SizedBox(width: 4.w),
              Icon(
                Icons.verified,
                size: 16.sp,
                color: AppColors.primary,
              ),
            ],
          ],
        ),
      ),
      
      subtitle: GestureDetector(
        onTap: () => _navigateToProfile(user.uid),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.fullName.isNotEmpty)
              Text(
                user.fullName,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                  fontFamily: 'Cairo',
                ),
              ),
            
            Text(
              '${user.followerText} • ${user.postsText}',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
      
      trailing: !isCurrentUser
          ? _buildFollowButton(user)
          : null,
      
      onTap: () => _navigateToProfile(user.uid),
    );
  }

  Widget _buildFollowButton(UserModel user) {
    return Consumer(
      builder: (context, ref, child) {
        // This would ideally use a follow provider to check follow status
        return SizedBox(
          width: 80.w,
          height: 32.h,
          child: ElevatedButton(
            onPressed: () => _toggleFollow(user),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12.w),
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
        );
      },
    );
  }

  Widget _buildExploreContent() {
    return Column(
      children: [
        // Tab Bar
        TabBar(
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
            Tab(text: 'الرائج'),
            Tab(text: 'اقتراحات'),
          ],
        ),
        
        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTrendingTab(),
              _buildSuggestionsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingTab() {
    if (_isLoadingTrending) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_trendingPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              size: 64.sp,
              color: AppColors.textSecondary,
            ),
            
            SizedBox(height: 16.h),
            
            Text(
              'لا توجد منشورات رائجة',
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
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2.w,
        mainAxisSpacing: 2.w,
        childAspectRatio: 1,
      ),
      itemCount: _trendingPosts.length,
      itemBuilder: (context, index) {
        final post = _trendingPosts[index];
        return GestureDetector(
          onTap: () => _navigateToProfile(post.userId),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.shimmerBase,
              image: DecorationImage(
                image: CachedNetworkImageProvider(post.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                // Post type indicator
                if (post.isVideo)
                  Positioned(
                    top: 8.h,
                    right: 8.w,
                    child: Icon(
                      Icons.play_arrow,
                      color: AppColors.white,
                      size: 16.sp,
                    ),
                  ),
                
                if (post.isCarousel)
                  Positioned(
                    top: 8.h,
                    right: 8.w,
                    child: Icon(
                      Icons.collections,
                      color: AppColors.white,
                      size: 16.sp,
                    ),
                  ),
                
                // Engagement overlay
                Positioned(
                  bottom: 8.h,
                  left: 8.w,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite,
                        color: AppColors.white,
                        size: 12.sp,
                      ),
                      
                      SizedBox(width: 2.w),
                      
                      Text(
                        _formatCount(post.likesCount),
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionsTab() {
    return FutureBuilder<List<UserModel>>(
      future: FollowService.getFollowSuggestions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                  'لا توجد اقتراحات متابعة',
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

        final suggestions = snapshot.data!;
        
        return ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final user = suggestions[index];
            return _buildUserSearchItem(user);
          },
        );
      },
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _currentQuery = '';
      _searchResults.clear();
      _isSearching = false;
    });
  }

  void _navigateToProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: userId),
      ),
    );
  }

  Future<void> _toggleFollow(UserModel user) async {
    final authState = ref.read(authProvider);
    if (authState.user == null) return;

    try {
      // This would use the follow service to toggle follow status
      await FollowService.toggleFollow(user.uid);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تمت متابعة ${user.username}'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في المتابعة'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) {
      final k = (count / 1000).toStringAsFixed(1);
      return '${k}ك';
    }
    final m = (count / 1000000).toStringAsFixed(1);
    return '${m}م';
  }
}

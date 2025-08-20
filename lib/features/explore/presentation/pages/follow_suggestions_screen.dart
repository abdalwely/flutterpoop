import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/providers/follow_provider.dart';
import '../../../../shared/services/follow_service.dart';
import '../../../../shared/widgets/custom_app_bar.dart';

class FollowSuggestionsScreen extends ConsumerStatefulWidget {
  const FollowSuggestionsScreen({super.key});

  @override
  ConsumerState<FollowSuggestionsScreen> createState() => _FollowSuggestionsScreenState();
}

class _FollowSuggestionsScreenState extends ConsumerState<FollowSuggestionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Load initial suggestions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(followProvider.notifier).loadFollowSuggestions();
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query != _searchQuery) {
      setState(() {
        _searchQuery = query;
      });
      _performSearch(query);
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    
    try {
      final results = await FollowService.searchUsers(query);
      if (mounted && query == _searchQuery) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
        
        // Load follow status for search results
        final userIds = results.map((user) => user.id).toList();
        if (userIds.isNotEmpty) {
          ref.read(followProvider.notifier).batchLoadFollowStatus(userIds);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = ref.watch(followSuggestionsProvider);
    final isLoading = ref.watch(followProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'اكتشاف أشخاص',
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              ref.read(followProvider.notifier).refreshSuggestions();
            },
            icon: Icon(
              Icons.refresh,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16.w),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث عن الأشخاص',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontFamily: 'Cairo',
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _searchResults = [];
                          });
                        },
                        icon: Icon(
                          Icons.clear,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : null,
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

          // Content
          Expanded(
            child: _buildContent(suggestions, isLoading),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<UserModel> suggestions, bool isLoading) {
    if (_searchQuery.isNotEmpty) {
      return _buildSearchResults();
    }

    if (isLoading && suggestions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (suggestions.isEmpty) {
      return _buildEmptyState();
    }

    return _buildSuggestionsList(suggestions);
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return _buildEmptySearchState();
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return SuggestedUserCard(
          user: user,
          showMutualFollowers: false,
        );
      },
    );
  }

  Widget _buildSuggestionsList(List<UserModel> suggestions) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(followProvider.notifier).refreshSuggestions();
      },
      child: CustomScrollView(
        slivers: [
          // Popular Suggestions
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Text(
                'اقتراحات لك',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final user = suggestions[index];
                return SuggestedUserCard(
                  user: user,
                  showMutualFollowers: true,
                );
              },
              childCount: suggestions.length,
            ),
          ),

          // Follow All Button
          if (suggestions.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.all(16.w),
                child: ElevatedButton(
                  onPressed: () => _followAllSuggestions(suggestions),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'متابعة الكل',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
            'لا توجد اقتراحات',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'سنقترح عليك أشخاص للمتابعة قريباً',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
              fontFamily: 'Cairo',
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () {
              ref.read(followProvider.notifier).refreshSuggestions();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'تحديث',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchState() {
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
            'لا توجد نتائج',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
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

  Future<void> _followAllSuggestions(List<UserModel> suggestions) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'متابعة الكل',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'هل تريد متابعة جميع الاقتراحات (${suggestions.length} شخص)؟',
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
              'متابعة الكل',
              style: TextStyle(
                color: AppColors.primary,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      final userIds = suggestions.map((user) => user.id).toList();
      await ref.read(followProvider.notifier).batchFollowUsers(userIds);
      ref.read(followProvider.notifier).refreshSuggestions();
    }
  }
}

class SuggestedUserCard extends ConsumerStatefulWidget {
  final UserModel user;
  final bool showMutualFollowers;

  const SuggestedUserCard({
    super.key,
    required this.user,
    this.showMutualFollowers = true,
  });

  @override
  ConsumerState<SuggestedUserCard> createState() => _SuggestedUserCardState();
}

class _SuggestedUserCardState extends ConsumerState<SuggestedUserCard> {
  List<UserModel> _mutualFollowers = [];
  bool _loadingMutual = false;

  @override
  void initState() {
    super.initState();
    if (widget.showMutualFollowers) {
      _loadMutualFollowers();
    }
  }

  Future<void> _loadMutualFollowers() async {
    setState(() => _loadingMutual = true);
    try {
      final mutual = await FollowService.getMutualFollowers(widget.user.id);
      if (mounted) {
        setState(() {
          _mutualFollowers = mutual;
          _loadingMutual = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingMutual = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFollowing = ref.watch(userFollowStatusProvider(widget.user.id));
    final followStats = ref.watch(userFollowStatsProvider(widget.user.id));

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
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
      child: Column(
        children: [
          Row(
            children: [
              // Profile Image
              Container(
                width: 60.w,
                height: 60.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.border,
                    width: 1,
                  ),
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: widget.user.profilePicture,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.shimmerBase,
                      child: Icon(
                        Icons.person,
                        color: AppColors.textSecondary,
                        size: 30.sp,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.inputBackground,
                      child: Icon(
                        Icons.person,
                        color: AppColors.textSecondary,
                        size: 30.sp,
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
                          widget.user.username,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        if (widget.user.isVerified) ...[
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.verified,
                            color: AppColors.primary,
                            size: 18.sp,
                          ),
                        ],
                      ],
                    ),
                    if (widget.user.displayName.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        widget.user.displayName,
                        style: TextStyle(
                          fontSize: 14.sp,
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

              // Follow Button
              GestureDetector(
                onTap: () => ref.read(followProvider.notifier).toggleFollow(widget.user.id),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
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
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: isFollowing ? AppColors.textPrimary : AppColors.white,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Mutual Followers
          if (widget.showMutualFollowers && !_loadingMutual && _mutualFollowers.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _buildMutualFollowers(),
          ],

          // Bio
          if (widget.user.bio.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              widget.user.bio,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMutualFollowers() {
    return Row(
      children: [
        // Mutual follower avatars
        SizedBox(
          height: 24.h,
          child: Stack(
            children: _mutualFollowers.take(3).map((user) {
              final index = _mutualFollowers.indexOf(user);
              return Positioned(
                right: index * 16.0.w,
                child: Container(
                  width: 24.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 1),
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: user.profilePicture,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.shimmerBase,
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.inputBackground,
                        child: Icon(
                          Icons.person,
                          size: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        SizedBox(width: (_mutualFollowers.length * 16.0 + 8).w),

        // Mutual followers text
        Expanded(
          child: Text(
            _mutualFollowers.length == 1
                ? 'يتابعه ${_mutualFollowers.first.username}'
                : 'يتابعه ${_mutualFollowers.first.username} و ${_mutualFollowers.length - 1} آخرين',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textSecondary,
              fontFamily: 'Cairo',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

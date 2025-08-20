import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/post_model.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/story_widget.dart';
import '../../../../shared/widgets/post_widget.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../messaging/presentation/pages/messages_screen.dart';
import '../../../notifications/presentation/pages/notifications_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMorePosts();
      }
    });
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    // Simulate loading data
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isLoading = false);
  }

  Future<void> _loadMorePosts() async {
    // Implement pagination here
  }

  Future<void> _refreshFeed() async {
    // Implement pull to refresh
    await _loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: AppConstants.appName,
        titleStyle: TextStyle(
          fontSize: 24.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          fontFamily: 'Cairo',
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
            icon: Icon(
              Icons.favorite_border,
              size: 24.sp,
              color: AppColors.textPrimary,
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MessagesScreen(),
                ),
              );
            },
            icon: Icon(
              Icons.send_outlined,
              size: 24.sp,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: RefreshIndicator(
          onRefresh: _refreshFeed,
          color: AppColors.primary,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Stories Section
              SliverToBoxAdapter(
                child: Container(
                  height: 100.h,
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: 10, // Placeholder count
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(left: 12.w),
                        child: StoryWidget(
                          profileImageUrl: 'https://picsum.photos/200?random=$index',
                          username: 'user_$index',
                          isViewed: index % 3 == 0,
                          isMyStory: index == 0,
                          onTap: () => _viewStory(index),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Divider
              SliverToBoxAdapter(
                child: Container(
                  height: 1,
                  color: AppColors.divider,
                  margin: EdgeInsets.symmetric(vertical: 8.h),
                ),
              ),

              // Posts Feed
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: PostWidget(
                        post: PostModel(
                          id: 'post_$index',
                          userId: 'user_${index + 10}',
                          username: 'user_${index + 10}',
                          userProfileImage: 'https://picsum.photos/200?random=${index + 10}',
                          media: [
                            PostMedia(
                              id: 'media_${index}_1',
                              url: 'https://picsum.photos/400?random=${index + 20}',
                              type: PostType.image,
                            ),
                          ],
                          caption: 'هذا منشور تجريبي رقم ${index + 1} مع وصف طويل ليظهر كيف سيبدو المنشور في التطبيق.',
                          location: index % 3 == 0 ? PostLocation(
                            id: 'location_$index',
                            name: 'الرياض، السعودية',
                            latitude: 24.7136,
                            longitude: 46.6753,
                          ) : null,
                          likesCount: (index + 1) * 24,
                          commentsCount: (index + 1) * 5,
                          sharesCount: (index + 1) * 2,
                          likedBy: index % 2 == 0 ? ['current_user_id'] : [],
                          savedBy: index % 3 == 0 ? ['current_user_id'] : [],
                          createdAt: DateTime.now().subtract(Duration(hours: index + 1)),
                          visibility: PostVisibility.public,
                        ),
                        onProfileTap: () => _viewProfile(index),
                      ),
                    );
                  },
                  childCount: 20, // Placeholder count
                ),
              ),

              // Loading indicator at bottom
              if (_isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewStory(int index) {
    // Navigate to story view
    print('View story $index');
  }

  void _likePost(int index) {
    // Handle like post
    print('Like post $index');
  }

  void _commentOnPost(int index) {
    // Navigate to comments
    print('Comment on post $index');
  }

  void _sharePost(int index) {
    // Handle share post
    print('Share post $index');
  }

  void _savePost(int index) {
    // Handle save post
    print('Save post $index');
  }

  void _viewProfile(int index) {
    // Navigate to profile
    print('View profile $index');
  }
}

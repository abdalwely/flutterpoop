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
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/posts_provider.dart';
import '../../../messaging/presentation/pages/messages_screen.dart';
import '../../../notifications/presentation/pages/notifications_screen.dart';
import '../../../profile/presentation/pages/profile_screen.dart';
import '../../../post/presentation/pages/comments_screen.dart';

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
    final auth = ref.read(authProvider);
    if (auth.user != null) {
      await ref.read(postsProvider.notifier).loadFeedPosts(
        auth.user!.uid,
        refresh: true,
      );
    }
  }

  Future<void> _loadMorePosts() async {
    final auth = ref.read(authProvider);
    if (auth.user != null) {
      await ref.read(postsProvider.notifier).loadFeedPosts(
        auth.user!.uid,
        refresh: false,
      );
    }
  }

  Future<void> _refreshFeed() async {
    await _loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final postsState = ref.watch(postsProvider);

    // If not authenticated, show login prompt
    if (!authState.isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'يجب تسجيل الدخول أولاً',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
      );
    }

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
        isLoading: authState.isLoading,
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
              if (postsState.posts.isEmpty && !postsState.isLoading)
                SliverToBoxAdapter(
                  child: Container(
                    height: 300.h,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            size: 64.sp,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'لا توجد منشورات بعد',
                            style: TextStyle(
                              fontSize: 18.sp,
                              color: AppColors.textSecondary,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'تابع أشخاصاً لمشاهدة منشوراتهم',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.textSecondary,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final post = postsState.posts[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 16.h),
                        child: PostWidget(
                          post: post,
                          onProfileTap: () => _viewProfile(post.userId),
                          onLike: () => _likePost(post),
                          onComment: () => _commentOnPost(post),
                          onShare: () => _sharePost(post),
                          onSave: () => _savePost(post),
                        ),
                      );
                    },
                    childCount: postsState.posts.length,
                  ),
                ),

              // Loading indicator at bottom
              if (postsState.isLoading && postsState.posts.isNotEmpty)
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

  Future<void> _likePost(PostModel post) async {
    final auth = ref.read(authProvider);
    final postsNotifier = ref.read(postsProvider.notifier);

    if (auth.user == null) return;

    try {
      if (post.isLikedBy(auth.user!.uid)) {
        await postsNotifier.unlikePost(post.id, auth.user!.uid);
      } else {
        await postsNotifier.likePost(post.id, auth.user!.uid);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في التفاعل مع المنشور'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _commentOnPost(PostModel post) {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => CommentsScreen(post: post),
    //   ),
    // );
  }

  Future<void> _sharePost(PostModel post) async {
    final auth = ref.read(authProvider);
    final postsNotifier = ref.read(postsProvider.notifier);

    if (auth.user == null) return;

    try {
      await postsNotifier.sharePost(post.id, auth.user!.uid);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم مشاركة المنشور'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في مشاركة المنشور'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _savePost(PostModel post) async {
    final auth = ref.read(authProvider);
    final postsNotifier = ref.read(postsProvider.notifier);

    if (auth.user == null) return;

    try {
      if (post.isSavedBy(auth.user!.uid)) {
        await postsNotifier.unsavePost(post.id, auth.user!.uid);
      } else {
        await postsNotifier.savePost(post.id, auth.user!.uid);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في حفظ المنشور'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _viewProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: userId),
      ),
    );
  }
}

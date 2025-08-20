import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/theme/app_colors.dart';
import '../models/post_model.dart';
import '../providers/interaction_provider.dart';
import 'enhanced_interaction_widget.dart';
import 'like_animation_widget.dart';

class EnhancedPostWidget extends ConsumerStatefulWidget {
  final PostModel post;
  final VoidCallback? onProfileTap;
  final VoidCallback? onMoreTap;
  final bool showFullCaption;
  final bool isCompact;

  const EnhancedPostWidget({
    super.key,
    required this.post,
    this.onProfileTap,
    this.onMoreTap,
    this.showFullCaption = false,
    this.isCompact = false,
  });

  @override
  ConsumerState<EnhancedPostWidget> createState() => _EnhancedPostWidgetState();
}

class _EnhancedPostWidgetState extends ConsumerState<EnhancedPostWidget>
    with TickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;
  bool _showLikeAnimation = false;
  bool _showFullCaption = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _showFullCaption = widget.showFullCaption;
  }

  void _initializeAnimations() {
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _likeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _likeAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  void _onDoubleTap() async {
    final isLiked = ref.read(postLikedProvider(widget.post.id));
    
    if (!isLiked) {
      // Show like animation
      setState(() => _showLikeAnimation = true);
      _likeAnimationController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() => _showLikeAnimation = false);
            _likeAnimationController.reset();
          }
        });
      });

      // Toggle like
      await ref.read(interactionProvider.notifier).toggleLike(widget.post.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Configure timeago locale
    timeago.setLocaleMessages('ar', timeago.ArMessages());

    return Container(
      color: AppColors.white,
      margin: EdgeInsets.only(bottom: widget.isCompact ? 8.h : 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          _buildPostHeader(),
          
          // Post Content
          _buildPostContent(),
          
          // Post Interactions
          EnhancedInteractionWidget(
            postId: widget.post.id,
            postUserId: widget.post.userId,
            isCompact: widget.isCompact,
            showLabels: !widget.isCompact,
          ),
          
          // Post Caption
          if (widget.post.caption.isNotEmpty) _buildPostCaption(),
          
          // Comments Preview
          _buildCommentsPreview(),
          
          // Time
          _buildTimeStamp(),
        ],
      ),
    );
  }

  Widget _buildPostHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: widget.isCompact ? 8.h : 12.h,
      ),
      child: Row(
        children: [
          // Profile Image with Story Ring
          GestureDetector(
            onTap: widget.onProfileTap,
            child: Container(
              width: widget.isCompact ? 32.w : 40.w,
              height: widget.isCompact ? 32.h : 40.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: widget.post.userHasStory 
                    ? LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.secondary,
                          Colors.purple,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : null,
                border: widget.post.userHasStory 
                    ? null 
                    : Border.all(
                        color: AppColors.border,
                        width: 1,
                      ),
              ),
              padding: EdgeInsets.all(widget.post.userHasStory ? 2.w : 0),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: widget.post.userHasStory 
                      ? Border.all(color: AppColors.white, width: 2)
                      : null,
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: widget.post.userProfilePicture,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.shimmerBase,
                      child: Icon(
                        Icons.person,
                        color: AppColors.textSecondary,
                        size: widget.isCompact ? 16.sp : 20.sp,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.inputBackground,
                      child: Icon(
                        Icons.person,
                        color: AppColors.textSecondary,
                        size: widget.isCompact ? 16.sp : 20.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          SizedBox(width: 12.w),
          
          // User Info
          Expanded(
            child: GestureDetector(
              onTap: widget.onProfileTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.post.username,
                        style: TextStyle(
                          fontSize: widget.isCompact ? 13.sp : 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      if (widget.post.isVerified) ...[
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.verified,
                          color: AppColors.primary,
                          size: widget.isCompact ? 14.sp : 16.sp,
                        ),
                      ],
                    ],
                  ),
                  if (widget.post.location != null && widget.post.location!.name.isNotEmpty && !widget.isCompact) ...[
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: AppColors.textSecondary,
                          size: 12.sp,
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            widget.post.location!.name,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary,
                              fontFamily: 'Cairo',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // More Button
          IconButton(
            onPressed: widget.onMoreTap,
            icon: Icon(
              Icons.more_horiz,
              color: AppColors.textPrimary,
              size: widget.isCompact ? 18.sp : 20.sp,
            ),
            constraints: BoxConstraints(
              minWidth: widget.isCompact ? 32.w : 40.w,
              minHeight: widget.isCompact ? 32.h : 40.h,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostContent() {
    return GestureDetector(
      onDoubleTap: _onDoubleTap,
      child: Stack(
        children: [
          // Main Content
          _buildMediaContent(),
          
          // Like Animation Overlay
          if (_showLikeAnimation)
            Positioned.fill(
              child: Center(
                child: AnimatedBuilder(
                  animation: _likeAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _likeAnimation.value,
                      child: Opacity(
                        opacity: 1.0 - _likeAnimation.value,
                        child: const LikeAnimationWidget(),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaContent() {
    final double aspectRatio = widget.post.aspectRatio ?? 1.0;
    final double maxHeight = widget.isCompact ? 300.h : 500.h;
    
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: widget.post.mediaType == 'video' 
            ? _buildVideoContent()
            : _buildImageContent(),
      ),
    );
  }

  Widget _buildImageContent() {
    if (widget.post.mediaUrls.isEmpty) {
      return Container(
        width: double.infinity,
        height: 200.h,
        color: AppColors.inputBackground,
        child: Icon(
          Icons.image_not_supported,
          color: AppColors.textSecondary,
          size: 40.sp,
        ),
      );
    }

    if (widget.post.mediaUrls.length == 1) {
      return _buildSingleImage(widget.post.mediaUrls.first);
    }

    return _buildImageCarousel();
  }

  Widget _buildSingleImage(String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        width: double.infinity,
        color: AppColors.shimmerBase,
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: double.infinity,
        color: AppColors.inputBackground,
        child: Icon(
          Icons.error_outline,
          color: AppColors.textSecondary,
          size: 40.sp,
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    return Stack(
      children: [
        PageView.builder(
          itemCount: widget.post.mediaUrls.length,
          itemBuilder: (context, index) {
            return _buildSingleImage(widget.post.mediaUrls[index]);
          },
        ),
        // Page Indicator
        if (widget.post.mediaUrls.length > 1)
          Positioned(
            bottom: 12.h,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.post.mediaUrls.length,
                (index) => Container(
                  width: 6.w,
                  height: 6.h,
                  margin: EdgeInsets.symmetric(horizontal: 2.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVideoContent() {
    // For now, show a placeholder. In a real app, use video_player
    return Container(
      width: double.infinity,
      color: AppColors.black,
      child: Stack(
        children: [
          if (widget.post.thumbnailUrl != null && widget.post.thumbnailUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: widget.post.thumbnailUrl!,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          Center(
            child: Container(
              width: 60.w,
              height: 60.h,
              decoration: BoxDecoration(
                color: AppColors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow,
                color: AppColors.white,
                size: 30.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCaption() {
    final caption = widget.post.caption;
    final maxLines = _showFullCaption ? null : 3;
    final shouldShowMore = caption.length > 100 && !_showFullCaption;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            maxLines: maxLines,
            overflow: _showFullCaption ? TextOverflow.visible : TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: widget.post.username,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'Cairo',
                  ),
                ),
                TextSpan(
                  text: ' $caption',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textPrimary,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
          if (shouldShowMore)
            GestureDetector(
              onTap: () => setState(() => _showFullCaption = true),
              child: Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Text(
                  'المزيد',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentsPreview() {
    final statsAsync = ref.watch(postStatsStreamProvider(widget.post.id));
    
    return statsAsync.when(
      data: (stats) {
        final commentsCount = stats['commentsCount'] ?? 0;
        if (commentsCount == 0) return const SizedBox.shrink();
        
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          child: GestureDetector(
            onTap: () {
              // Open comments
            },
            child: Text(
              commentsCount == 1 
                  ? 'عرض التعليق' 
                  : 'عرض جميع التعليقات ($commentsCount)',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildTimeStamp() {
    if (widget.isCompact) return const SizedBox.shrink();
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Text(
        timeago.format(widget.post.createdAt, locale: 'ar'),
        style: TextStyle(
          fontSize: 12.sp,
          color: AppColors.textSecondary,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }
}

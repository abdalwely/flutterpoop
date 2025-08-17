import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../models/post_model.dart';
import '../providers/posts_provider.dart';
import '../providers/temp_auth_provider.dart';
import 'like_animation_widget.dart';
import 'post_actions_sheet.dart';
import 'comments_bottom_sheet.dart';
import 'share_bottom_sheet.dart';

class AdvancedPostWidget extends ConsumerStatefulWidget {
  final PostModel post;
  final VoidCallback? onProfileTap;
  final VoidCallback? onPostTap;

  const AdvancedPostWidget({
    super.key,
    required this.post,
    this.onProfileTap,
    this.onPostTap,
  });

  @override
  ConsumerState<AdvancedPostWidget> createState() => _AdvancedPostWidgetState();
}

class _AdvancedPostWidgetState extends ConsumerState<AdvancedPostWidget>
    with TickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late AnimationController _saveAnimationController;
  late AnimationController _shareAnimationController;
  late Animation<double> _likeAnimation;
  late Animation<double> _saveAnimation;
  late Animation<double> _shareAnimation;
  
  bool _showLikeAnimation = false;
  bool _isLiked = false;
  bool _isSaved = false;
  int _currentMediaIndex = 0;
  PageController? _mediaPageController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeStates();
    
    if (widget.post.isCarousel) {
      _mediaPageController = PageController();
    }
  }

  void _initializeAnimations() {
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _saveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _shareAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _likeAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _likeAnimationController,
      curve: Curves.elasticOut,
    ));

    _saveAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _saveAnimationController,
      curve: Curves.bounceOut,
    ));

    _shareAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _shareAnimationController,
      curve: Curves.easeOut,
    ));
  }

  void _initializeStates() {
    final user = ref.read(authProvider).user;
    if (user != null) {
      _isLiked = widget.post.isLikedBy(user.uid);
      _isSaved = widget.post.isSavedBy(user.uid);
    }
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    _saveAnimationController.dispose();
    _shareAnimationController.dispose();
    _mediaPageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPostHeader(),
          _buildPostMedia(),
          _buildPostActions(),
          _buildPostInfo(),
          if (widget.post.caption.isNotEmpty) _buildPostCaption(),
          _buildCommentsPreview(),
        ],
      ),
    );
  }

  Widget _buildPostHeader() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onProfileTap,
            child: Stack(
              children: [
                Container(
                  width: 44.w,
                  height: 44.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: widget.post.isUserVerified
                        ? AppColors.instagramGradient
                        : null,
                    color: widget.post.isUserVerified 
                        ? null 
                        : AppColors.border,
                  ),
                  padding: EdgeInsets.all(2.w),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.white,
                    ),
                    padding: EdgeInsets.all(2.w),
                    child: CircleAvatar(
                      backgroundImage: widget.post.userProfileImage.isNotEmpty
                          ? CachedNetworkImageProvider(widget.post.userProfileImage)
                          : null,
                      child: widget.post.userProfileImage.isEmpty
                          ? Icon(Icons.person, size: 20.sp)
                          : null,
                    ),
                  ),
                ),
                if (widget.post.isUserVerified)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16.w,
                      height: 16.h,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.white,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.verified,
                        size: 10.sp,
                        color: AppColors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          SizedBox(width: 12.w),
          
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
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      if (widget.post.isSponsored) ...[
                        SizedBox(width: 4.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            'ممول',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppColors.primary,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (widget.post.hasLocation) ...[
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          widget.post.location!.name,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          Text(
            widget.post.timeAgo,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textSecondary,
              fontFamily: 'Cairo',
            ),
          ),
          
          SizedBox(width: 8.w),
          
          IconButton(
            onPressed: () => _showPostActions(),
            icon: Icon(
              Icons.more_horiz,
              color: AppColors.textPrimary,
              size: 20.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostMedia() {
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      onTap: widget.onPostTap,
      child: Stack(
        children: [
          if (widget.post.isCarousel)
            _buildCarouselMedia()
          else
            _buildSingleMedia(widget.post.media.first),
          
          // Like Animation Overlay
          if (_showLikeAnimation)
            Positioned.fill(
              child: LikeAnimationWidget(
                onAnimationComplete: () {
                  setState(() => _showLikeAnimation = false);
                },
              ),
            ),
          
          // Media Indicators for Carousel
          if (widget.post.isCarousel)
            Positioned(
              bottom: 12.h,
              left: 0,
              right: 0,
              child: _buildMediaIndicators(),
            ),
          
          // Video Duration Overlay
          if (widget.post.isVideo)
            Positioned(
              top: 12.h,
              right: 12.w,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 4.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_arrow,
                      color: AppColors.white,
                      size: 12.sp,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      '${widget.post.media.first.duration ?? 0}ث',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 10.sp,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSingleMedia(PostMedia media) {
    return Container(
      width: double.infinity,
      height: 400.h,
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: CachedNetworkImage(
          imageUrl: media.thumbnailUrl ?? media.url,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: AppColors.shimmerBase,
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: AppColors.inputBackground,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppColors.textSecondary,
                  size: 40.sp,
                ),
                SizedBox(height: 8.h),
                Text(
                  'فشل في تحم��ل الصورة',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14.sp,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCarouselMedia() {
    return Container(
      width: double.infinity,
      height: 400.h,
      child: PageView.builder(
        controller: _mediaPageController,
        onPageChanged: (index) {
          setState(() => _currentMediaIndex = index);
        },
        itemCount: widget.post.media.length,
        itemBuilder: (context, index) {
          return _buildSingleMedia(widget.post.media[index]);
        },
      ),
    );
  }

  Widget _buildMediaIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.post.media.length,
        (index) => Container(
          width: 6.w,
          height: 6.h,
          margin: EdgeInsets.symmetric(horizontal: 2.w),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == _currentMediaIndex
                ? AppColors.white
                : AppColors.white.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildPostActions() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          // Like Button
          GestureDetector(
            onTap: _handleLike,
            child: AnimatedBuilder(
              animation: _likeAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _likeAnimation.value,
                  child: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? AppColors.like : AppColors.textPrimary,
                    size: 28.sp,
                  ),
                );
              },
            ),
          ),
          
          SizedBox(width: 16.w),
          
          // Comment Button
          GestureDetector(
            onTap: _showComments,
            child: Icon(
              Icons.mode_comment_outlined,
              color: AppColors.textPrimary,
              size: 28.sp,
            ),
          ),
          
          SizedBox(width: 16.w),
          
          // Share Button
          GestureDetector(
            onTap: _handleShare,
            child: AnimatedBuilder(
              animation: _shareAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _shareAnimation.value,
                  child: Icon(
                    Icons.send_outlined,
                    color: AppColors.textPrimary,
                    size: 28.sp,
                  ),
                );
              },
            ),
          ),
          
          const Spacer(),
          
          // Save Button
          GestureDetector(
            onTap: _handleSave,
            child: AnimatedBuilder(
              animation: _saveAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _saveAnimation.value,
                  child: Icon(
                    _isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: AppColors.textPrimary,
                    size: 28.sp,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostInfo() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.post.likesCount > 0 && !widget.post.hideLikesCount)
            GestureDetector(
              onTap: _showLikedUsers,
              child: Text(
                widget.post.likesText,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          
          if (widget.post.isVideo && widget.post.viewsCount > 0) ...[
            SizedBox(height: 4.h),
            Text(
              widget.post.viewsText,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPostCaption() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: RichText(
        text: _buildCaptionTextSpan(),
      ),
    );
  }

  TextSpan _buildCaptionTextSpan() {
    final text = widget.post.caption;
    final spans = <TextSpan>[];
    
    // Username
    spans.add(TextSpan(
      text: '${widget.post.username} ',
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        fontFamily: 'Cairo',
      ),
    ));
    
    // Caption with hashtags and mentions highlighting
    final words = text.split(' ');
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      
      if (word.startsWith('#')) {
        spans.add(TextSpan(
          text: '$word ',
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.primary,
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w500,
          ),
        ));
      } else if (word.startsWith('@')) {
        spans.add(TextSpan(
          text: '$word ',
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.primary,
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w500,
          ),
        ));
      } else {
        spans.add(TextSpan(
          text: '$word ',
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textPrimary,
            fontFamily: 'Cairo',
          ),
        ));
      }
    }
    
    return TextSpan(children: spans);
  }

  Widget _buildCommentsPreview() {
    if (widget.post.commentsCount == 0) return const SizedBox.shrink();
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: GestureDetector(
        onTap: _showComments,
        child: Text(
          widget.post.commentsText,
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    );
  }

  // Event Handlers
  void _handleDoubleTap() {
    if (!_isLiked) {
      _handleLike();
      setState(() => _showLikeAnimation = true);
    }
  }

  void _handleLike() {
    setState(() => _isLiked = !_isLiked);
    _likeAnimationController.forward().then((_) {
      _likeAnimationController.reverse();
    });
    
    final user = ref.read(authProvider).user;
    if (user != null) {
      if (_isLiked) {
        ref.read(postsProvider.notifier).likePost(widget.post.id, user.uid);
      } else {
        ref.read(postsProvider.notifier).unlikePost(widget.post.id, user.uid);
      }
    }
  }

  void _handleSave() {
    setState(() => _isSaved = !_isSaved);
    _saveAnimationController.forward().then((_) {
      _saveAnimationController.reverse();
    });
    
    final user = ref.read(authProvider).user;
    if (user != null) {
      if (_isSaved) {
        ref.read(postsProvider.notifier).savePost(widget.post.id, user.uid);
      } else {
        ref.read(postsProvider.notifier).unsavePost(widget.post.id, user.uid);
      }
    }
  }

  void _handleShare() {
    _shareAnimationController.forward().then((_) {
      _shareAnimationController.reverse();
    });
    
    _showShareOptions();
  }

  void _showPostActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PostActionsSheet(post: widget.post),
    );
  }

  void _showComments() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CommentsBottomSheet(post: widget.post),
    );
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ShareBottomSheet(post: widget.post),
    );
  }

  void _showLikedUsers() {
    // Navigate to liked users screen
    print('Show liked users for post ${widget.post.id}');
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../models/post_model.dart';

class PostWidget extends ConsumerStatefulWidget {
  final PostModel post;
  final VoidCallback? onProfileTap;
  final VoidCallback? onMoreTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onSave;
  final bool showFullCaption;

  const PostWidget({
    super.key,
    required this.post,
    this.onProfileTap,
    this.onMoreTap,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onSave,
    this.showFullCaption = false,
  });

  @override
  ConsumerState<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends ConsumerState<PostWidget>
    with TickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;
  bool _showLikeAnimation = false;

  @override
  void initState() {
    super.initState();
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

  void _onDoubleTap() {
    // TODO: Implement like functionality
    setState(() => _showLikeAnimation = true);
    _likeAnimationController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _showLikeAnimation = false);
          _likeAnimationController.reset();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          _buildPostHeader(),
          
          // Post Image
          _buildPostImage(),
          
          // Post Actions
          _buildPostActions(),
          
          // Post Info
          _buildPostInfo(),
          
          // Post Caption
          if (widget.post.caption.isNotEmpty) _buildPostCaption(),
          
          // View Comments
          _buildViewComments(),
          
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  Widget _buildPostHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          // Profile Image
          GestureDetector(
            onTap: widget.onProfileTap,
            child: Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: CachedNetworkImageProvider(widget.post.userProfileImage),
                  fit: BoxFit.cover,
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
                  Text(
                    widget.post.username,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  if (widget.post.location != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      widget.post.location!.name,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Time
          Text(
            widget.post.timeAgo,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textSecondary,
              fontFamily: 'Cairo',
            ),
          ),
          
          SizedBox(width: 8.w),
          
          // More Button
          IconButton(
            onPressed: widget.onMoreTap,
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

  Widget _buildPostImage() {
    return GestureDetector(
      onDoubleTap: _onDoubleTap,
      child: Stack(
        children: [
          // Main Image
          CachedNetworkImage(
            imageUrl: widget.post.imageUrl,
            width: double.infinity,
            height: 400.h,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: double.infinity,
              height: 400.h,
              color: AppColors.shimmerBase,
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              width: double.infinity,
              height: 400.h,
              color: AppColors.inputBackground,
              child: Icon(
                Icons.error_outline,
                color: AppColors.textSecondary,
                size: 40.sp,
              ),
            ),
          ),
          
          // Like Animation
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
                        child: Icon(
                          Icons.favorite,
                          color: AppColors.like,
                          size: 80.sp,
                        ),
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

  Widget _buildPostActions() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          // Like Button
          GestureDetector(
            onTap: widget.onLike,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                widget.post.isLiked ? Icons.favorite : Icons.favorite_border,
                color: widget.post.isLiked ? AppColors.like : AppColors.textPrimary,
                size: 24.sp,
                key: ValueKey(widget.post.isLiked),
              ),
            ),
          ),
          
          SizedBox(width: 16.w),
          
          // Comment Button
          GestureDetector(
            onTap: widget.onComment,
            child: Icon(
              Icons.mode_comment_outlined,
              color: AppColors.textPrimary,
              size: 24.sp,
            ),
          ),
          
          SizedBox(width: 16.w),
          
          // Share Button
          GestureDetector(
            onTap: widget.onShare,
            child: Icon(
              Icons.send_outlined,
              color: AppColors.textPrimary,
              size: 24.sp,
            ),
          ),
          
          const Spacer(),
          
          // Save Button
          GestureDetector(
            onTap: widget.onSave,
            child: Icon(
              widget.post.isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: AppColors.textPrimary,
              size: 24.sp,
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
          // Likes Count
          if (widget.post.likesCount > 0)
            Text(
              _formatLikesCount(widget.post.likesCount),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Cairo',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostCaption() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: RichText(
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
              text: ' ${widget.post.caption}',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textPrimary,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewComments() {
    if (widget.post.commentsCount == 0) return const SizedBox.shrink();
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: GestureDetector(
        onTap: widget.onComment,
        child: Text(
          'عرض جميع التعليقات (${widget.post.commentsCount})',
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    );
  }

  String _formatLikesCount(int count) {
    if (count == 0) return '';
    if (count == 1) return 'إعجاب واحد';
    if (count == 2) return 'إعجابان';
    if (count < 11) return '$count إعجابات';
    if (count < 100) return '$count إعجاباً';
    if (count < 1000) return '$count إعجاب';
    if (count < 1000000) {
      final k = (count / 1000).toStringAsFixed(1);
      return '${k}ألف إعجاب';
    }
    final m = (count / 1000000).toStringAsFixed(1);
    return '${m}م إعجاب';
  }
}

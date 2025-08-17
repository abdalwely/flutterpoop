import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../providers/interaction_provider.dart';
import 'like_animation_widget.dart';
import 'comments_bottom_sheet.dart';

class EnhancedInteractionWidget extends ConsumerStatefulWidget {
  final String postId;
  final String postUserId;
  final bool showLabels;
  final bool isCompact;
  final VoidCallback? onCommentTap;
  final VoidCallback? onShareTap;

  const EnhancedInteractionWidget({
    super.key,
    required this.postId,
    required this.postUserId,
    this.showLabels = true,
    this.isCompact = false,
    this.onCommentTap,
    this.onShareTap,
  });

  @override
  ConsumerState<EnhancedInteractionWidget> createState() => _EnhancedInteractionWidgetState();
}

class _EnhancedInteractionWidgetState extends ConsumerState<EnhancedInteractionWidget>
    with TickerProviderStateMixin {
  late AnimationController _heartBeatController;
  late AnimationController _saveController;
  late AnimationController _shareController;
  
  bool _showLikeAnimation = false;
  OverlayEntry? _likeOverlay;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    
    // Load interaction status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(interactionProvider.notifier).loadPostInteractionStatus(widget.postId);
      ref.read(interactionProvider.notifier).listenToPostStats(widget.postId);
    });
  }

  void _initializeControllers() {
    _heartBeatController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _saveController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _shareController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _heartBeatController.dispose();
    _saveController.dispose();
    _shareController.dispose();
    _likeOverlay?.remove();
    super.dispose();
  }

  void _handleLikeTap() async {
    HapticFeedback.lightImpact();
    
    final isCurrentlyLiked = ref.read(postLikedProvider(widget.postId));
    
    if (!isCurrentlyLiked) {
      _showLikeAnimationOverlay();
      _heartBeatController.forward().then((_) {
        _heartBeatController.reverse();
      });
    }

    await ref.read(interactionProvider.notifier).toggleLike(widget.postId);
  }

  void _handleSaveTap() async {
    HapticFeedback.selectionClick();
    
    _saveController.forward().then((_) {
      _saveController.reverse();
    });

    await ref.read(interactionProvider.notifier).toggleSave(widget.postId);
  }

  void _handleShareTap() {
    HapticFeedback.mediumImpact();
    
    _shareController.forward().then((_) {
      _shareController.reverse();
    });

    _showShareBottomSheet();
  }

  void _showLikeAnimationOverlay() {
    _likeOverlay?.remove();
    
    _likeOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: 0,
        right: 0,
        top: MediaQuery.of(context).size.height * 0.4,
        child: const LikeAnimationWidget(),
      ),
    );
    
    Overlay.of(context).insert(_likeOverlay!);
    
    Future.delayed(const Duration(milliseconds: 800), () {
      _likeOverlay?.remove();
      _likeOverlay = null;
    });
  }

  void _showShareBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareBottomSheet(
        postId: widget.postId,
        onShare: (platform) async {
          await ref.read(interactionProvider.notifier).sharePost(
            widget.postId,
            platform: platform,
          );
          if (mounted) Navigator.pop(context);
          if (widget.onShareTap != null) widget.onShareTap!();
        },
      ),
    );
  }

  void _showCommentsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(
        postId: widget.postId,
        onCommentAdded: (comment) async {
          await ref.read(interactionProvider.notifier).addComment(
            widget.postId,
            comment,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = ref.watch(postLikedProvider(widget.postId));
    final isSaved = ref.watch(postSavedProvider(widget.postId));
    final statsAsync = ref.watch(postStatsStreamProvider(widget.postId));

    return statsAsync.when(
      data: (stats) => _buildInteractionRow(isLiked, isSaved, stats),
      loading: () => _buildLoadingRow(),
      error: (_, __) => _buildInteractionRow(isLiked, isSaved, {}),
    );
  }

  Widget _buildInteractionRow(bool isLiked, bool isSaved, Map<String, dynamic> stats) {
    final likesCount = stats['likesCount'] ?? 0;
    final commentsCount = stats['commentsCount'] ?? 0;
    final sharesCount = stats['sharesCount'] ?? 0;
    final reactions = Map<String, dynamic>.from(stats['reactions'] ?? {});

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isCompact ? 12.w : 16.w,
        vertical: widget.isCompact ? 8.h : 12.h,
      ),
      child: Column(
        children: [
          // Main interaction buttons
          Row(
            children: [
              _buildLikeButton(isLiked, likesCount),
              SizedBox(width: widget.isCompact ? 16.w : 20.w),
              _buildCommentButton(commentsCount),
              SizedBox(width: widget.isCompact ? 16.w : 20.w),
              _buildShareButton(sharesCount),
              const Spacer(),
              _buildSaveButton(isSaved),
            ],
          ),
          
          if (reactions.isNotEmpty && !widget.isCompact) ...[
            SizedBox(height: 8.h),
            _buildReactionsRow(reactions),
          ],
          
          if (widget.showLabels && !widget.isCompact) ...[
            SizedBox(height: 8.h),
            _buildStatsRow(likesCount, commentsCount, sharesCount),
          ],
        ],
      ),
    );
  }

  Widget _buildLikeButton(bool isLiked, int likesCount) {
    return GestureDetector(
      onTap: _handleLikeTap,
      child: AnimatedBuilder(
        animation: _heartBeatController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_heartBeatController.value * 0.2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? AppColors.like : AppColors.textSecondary,
                  size: widget.isCompact ? 20.sp : 24.sp,
                ),
                if (widget.showLabels && likesCount > 0) ...[
                  SizedBox(width: 4.w),
                  Text(
                    _formatCount(likesCount),
                    style: TextStyle(
                      fontSize: widget.isCompact ? 12.sp : 14.sp,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommentButton(int commentsCount) {
    return GestureDetector(
      onTap: widget.onCommentTap ?? _showCommentsBottomSheet,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            MdiIcons.commentOutline,
            color: AppColors.textSecondary,
            size: widget.isCompact ? 20.sp : 24.sp,
          ),
          if (widget.showLabels && commentsCount > 0) ...[
            SizedBox(width: 4.w),
            Text(
              _formatCount(commentsCount),
              style: TextStyle(
                fontSize: widget.isCompact ? 12.sp : 14.sp,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShareButton(int sharesCount) {
    return GestureDetector(
      onTap: _handleShareTap,
      child: AnimatedBuilder(
        animation: _shareController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_shareController.value * 0.1),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  MdiIcons.shareOutline,
                  color: AppColors.textSecondary,
                  size: widget.isCompact ? 20.sp : 24.sp,
                ),
                if (widget.showLabels && sharesCount > 0) ...[
                  SizedBox(width: 4.w),
                  Text(
                    _formatCount(sharesCount),
                    style: TextStyle(
                      fontSize: widget.isCompact ? 12.sp : 14.sp,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSaveButton(bool isSaved) {
    return GestureDetector(
      onTap: _handleSaveTap,
      child: AnimatedBuilder(
        animation: _saveController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_saveController.value * 0.1),
            child: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: isSaved ? AppColors.primary : AppColors.textSecondary,
              size: widget.isCompact ? 20.sp : 24.sp,
            ),
          );
        },
      ),
    );
  }

  Widget _buildReactionsRow(Map<String, dynamic> reactions) {
    final reactionsList = reactions.entries
        .where((entry) => entry.key != 'users' && entry.value > 0)
        .toList();

    if (reactionsList.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        ...reactionsList.take(3).map((entry) {
          return Container(
            margin: EdgeInsets.only(left: 4.w),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getReactionEmoji(entry.key),
                  style: TextStyle(fontSize: 16.sp),
                ),
                SizedBox(width: 2.w),
                Text(
                  entry.value.toString(),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        if (reactionsList.length > 3) ...[
          SizedBox(width: 8.w),
          Text(
            '+${reactionsList.length - 3}',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatsRow(int likes, int comments, int shares) {
    if (likes == 0 && comments == 0 && shares == 0) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (likes > 0) ...[
          Text(
            '$likes إعجاب',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (comments > 0 || shares > 0) ...[
            SizedBox(width: 8.w),
            Text(
              '•',
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(width: 8.w),
          ],
        ],
        if (comments > 0) ...[
          Text(
            '$comments تعليق',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (shares > 0) ...[
            SizedBox(width: 8.w),
            Text(
              '•',
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(width: 8.w),
          ],
        ],
        if (shares > 0) ...[
          Text(
            '$shares مشاركة',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingRow() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          _buildLoadingButton(),
          SizedBox(width: 20.w),
          _buildLoadingButton(),
          SizedBox(width: 20.w),
          _buildLoadingButton(),
          const Spacer(),
          _buildLoadingButton(),
        ],
      ),
    );
  }

  Widget _buildLoadingButton() {
    return Container(
      width: 24.w,
      height: 24.h,
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4.r),
      ),
    );
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}ك';
    return '${(count / 1000000).toStringAsFixed(1)}م';
  }

  String _getReactionEmoji(String reactionType) {
    switch (reactionType) {
      case 'love':
        return '😍';
      case 'laugh':
        return '😂';
      case 'wow':
        return '😮';
      case 'sad':
        return '😢';
      case 'angry':
        return '😠';
      default:
        return '👍';
    }
  }
}

class ShareBottomSheet extends StatelessWidget {
  final String postId;
  final Function(String platform) onShare;

  const ShareBottomSheet({
    super.key,
    required this.postId,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'مشاركة المنشور',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildShareOption(
                'واتساب',
                MdiIcons.whatsapp,
                Colors.green,
                () => onShare('whatsapp'),
              ),
              _buildShareOption(
                'تيليجرام',
                MdiIcons.telegram,
                Colors.blue,
                () => onShare('telegram'),
              ),
              _buildShareOption(
                'تويتر',
                MdiIcons.twitter,
                Colors.lightBlue,
                () => onShare('twitter'),
              ),
              _buildShareOption(
                'نسخ الرابط',
                MdiIcons.contentCopy,
                AppColors.primary,
                () => onShare('copy'),
              ),
            ],
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildShareOption(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50.w,
            height: 50.h,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25.r),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

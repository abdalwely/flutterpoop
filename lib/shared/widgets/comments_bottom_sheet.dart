import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../providers/comments_provider.dart';
import '../providers/temp_auth_provider.dart';
import 'custom_text_field.dart';
import 'custom_button.dart';

class CommentsBottomSheet extends ConsumerStatefulWidget {
  final PostModel post;

  const CommentsBottomSheet({
    super.key,
    required this.post,
  });

  @override
  ConsumerState<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends ConsumerState<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _replyingToCommentId;
  String? _replyingToUsername;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(commentsProvider(widget.post.id).notifier).loadComments(widget.post.id);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsState = ref.watch(commentsProvider(widget.post.id));
    final user = ref.watch(authProvider).user;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildCommentsDescription(),
          Expanded(child: _buildCommentsList(commentsState)),
          if (user != null) _buildCommentInput(user.uid),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'التعليقات',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: AppColors.textPrimary,
              size: 24.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsDescription() {
    if (widget.post.commentsCount == 0) {
      return Padding(
        padding: EdgeInsets.all(16.w),
        child: Text(
          'كن أول من يعلق على هذا المنشور',
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
            fontFamily: 'Cairo',
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Text(
        '${widget.post.commentsCount} ${widget.post.commentsText}',
        style: TextStyle(
          fontSize: 14.sp,
          color: AppColors.textSecondary,
          fontFamily: 'Cairo',
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCommentsList(CommentsState state) {
    final isLoading = state.loadingStates[widget.post.id] ?? false;
    final comments = state.postComments[widget.post.id] ?? [];

    if (isLoading && comments.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mode_comment_outlined,
              size: 64.sp,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16.h),
            Text(
              'لا توجد تعليقات بعد',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'كن أول من يعلق على هذا المنشور',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textTertiary,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(commentsProvider(widget.post.id).notifier).loadComments(
        widget.post.id,
      ),
      color: AppColors.primary,
      child: ListView.separated(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(vertical: 8.h),
        itemCount: comments.length + (isLoading ? 1 : 0),
        separatorBuilder: (context, index) => SizedBox(height: 8.h),
        itemBuilder: (context, index) {
          if (index >= comments.length) {
            return _buildLoadMoreButton();
          }

          final comment = comments[index];
          return CommentWidget(
            comment: comment,
            onReply: () => _startReply(comment),
            onLike: () => _likeComment(comment.id),
            onReport: () => _reportComment(comment.id),
            onDelete: () => _deleteComment(comment.id),
          );
        },
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    final state = ref.watch(commentsProvider(widget.post.id));
    
    if (state.loadingStates[widget.post.id] ?? false) {
      return Padding(
        padding: EdgeInsets.all(16.w),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: CustomButton(
        text: 'عرض المزيد من التعليقات',
        isOutlined: true,
        onPressed: () => ref.read(commentsProvider(widget.post.id).notifier).loadMoreComments(),
      ),
    );
  }

  Widget _buildCommentInput(String userId) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_replyingToCommentId != null) _buildReplyIndicator(),
          Row(
            children: [
              CircleAvatar(
                radius: 16.r,
                backgroundImage: ref.watch(authProvider).user?.profileImageUrl.isNotEmpty == true
                    ? CachedNetworkImageProvider(ref.watch(authProvider).user!.profileImageUrl)
                    : null,
                child: ref.watch(authProvider).user?.profileImageUrl.isEmpty == true
                    ? Icon(Icons.person, size: 16.sp)
                    : null,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: CustomTextField(
                  controller: _commentController,
                  hintText: _replyingToCommentId != null 
                      ? 'رد على $_replyingToUsername...'
                      : AppConstants.commentHint,
                  maxLines: 3,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submitComment(userId),
                ),
              ),
              SizedBox(width: 8.w),
              IconButton(
                onPressed: _commentController.text.trim().isNotEmpty
                    ? () => _submitComment(userId)
                    : null,
                icon: Icon(
                  Icons.send,
                  color: _commentController.text.trim().isNotEmpty
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: 24.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReplyIndicator() {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(
            Icons.reply,
            size: 16.sp,
            color: AppColors.primary,
          ),
          SizedBox(width: 8.w),
          Text(
            'رد على $_replyingToUsername',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.primary,
              fontFamily: 'Cairo',
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _cancelReply,
            child: Icon(
              Icons.close,
              size: 16.sp,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _startReply(CommentModel comment) {
    setState(() {
      _replyingToCommentId = comment.id;
      _replyingToUsername = comment.username;
    });
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUsername = null;
    });
  }

  Future<void> _submitComment(String userId) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    try {
      await ref.read(commentsProvider(widget.post.id).notifier).addComment(
        widget.post.id,
        text,
        parentId: _replyingToCommentId,
      );

      _commentController.clear();
      _cancelReply();
      
      // Scroll to bottom to show new comment
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في إضافة التعليق: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _likeComment(String commentId) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    try {
      await ref.read(commentsProvider(widget.post.id).notifier).likeComment(commentId, user.uid);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في الإعجاب بالتعليق'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _reportComment(String commentId) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الإبلاغ عن التعليق'),
        content: const Text('هل أنت متأكد من أنك تريد الإبلاغ عن هذا التعليق؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'إبلاغ',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(commentsProvider(widget.post.id).notifier).reportComment(commentId, user.uid);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم الإبلاغ عن ا��تعليق'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الإبلاغ عن التعليق'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف التعليق'),
        content: const Text('هل أنت متأكد من أن�� تريد ��ذف هذا التعليق؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'حذف',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(commentsProvider(widget.post.id).notifier).deleteComment(commentId, user.uid);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف التعليق'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حذف التعليق'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class CommentWidget extends ConsumerWidget {
  final CommentModel comment;
  final VoidCallback? onReply;
  final VoidCallback? onLike;
  final VoidCallback? onReport;
  final VoidCallback? onDelete;

  const CommentWidget({
    super.key,
    required this.comment,
    this.onReply,
    this.onLike,
    this.onReport,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).user;
    final isOwner = currentUser?.uid == comment.userId;
    final isLiked = currentUser != null && comment.isLikedBy(currentUser.uid);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16.r,
            backgroundImage: comment.userProfileImage.isNotEmpty
                ? CachedNetworkImageProvider(comment.userProfileImage)
                : null,
            child: comment.userProfileImage.isEmpty
                ? Icon(Icons.person, size: 16.sp)
                : null,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCommentHeader(context),
                SizedBox(height: 4.h),
                _buildCommentContent(),
                SizedBox(height: 8.h),
                _buildCommentActions(context, isLiked, isOwner),
                if (comment.hasReplies) _buildRepliesButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentHeader(BuildContext context) {
    return Row(
      children: [
        Text(
          comment.username,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: 'Cairo',
          ),
        ),
        if (comment.isUserVerified) ...[
          SizedBox(width: 4.w),
          Icon(
            Icons.verified,
            size: 12.sp,
            color: AppColors.primary,
          ),
        ],
        if (comment.isFromCreator) ...[
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              'المؤلف',
              style: TextStyle(
                fontSize: 10.sp,
                color: AppColors.primary,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
        const Spacer(),
        Text(
          comment.timeAgo,
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.textSecondary,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _buildCommentContent() {
    return Text(
      comment.displayText,
      style: TextStyle(
        fontSize: 14.sp,
        color: AppColors.textPrimary,
        fontFamily: 'Cairo',
      ),
    );
  }

  Widget _buildCommentActions(BuildContext context, bool isLiked, bool isOwner) {
    return Row(
      children: [
        GestureDetector(
          onTap: onLike,
          child: Text(
            comment.likesCount > 0 ? comment.likesText : 'إعجاب',
            style: TextStyle(
              fontSize: 12.sp,
              color: isLiked ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isLiked ? FontWeight.w600 : FontWeight.normal,
              fontFamily: 'Cairo',
            ),
          ),
        ),
        SizedBox(width: 16.w),
        GestureDetector(
          onTap: onReply,
          child: Text(
            'رد',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textSecondary,
              fontFamily: 'Cairo',
            ),
          ),
        ),
        const Spacer(),
        if (isOwner)
          GestureDetector(
            onTap: onDelete,
            child: Icon(
              Icons.delete_outline,
              size: 16.sp,
              color: AppColors.error,
            ),
          )
        else
          GestureDetector(
            onTap: onReport,
            child: Icon(
              Icons.flag_outlined,
              size: 16.sp,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }

  Widget _buildRepliesButton() {
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: GestureDetector(
        onTap: () {
          // Show replies
        },
        child: Text(
          comment.repliesText,
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.textSecondary,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    );
  }
}

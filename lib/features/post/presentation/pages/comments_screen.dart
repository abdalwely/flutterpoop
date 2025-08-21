import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/comments_provider.dart';
import '../../../../shared/models/comment_model.dart';
import '../../../../shared/models/post_model.dart';
import '../../../../shared/services/comment_service.dart';

class CommentsScreen extends ConsumerStatefulWidget {
  final String postId;
  final String? postType;

  const CommentsScreen({
    super.key,
    required this.postId,
    this.postType = 'post',
  });

  // Constructor for backward compatibility with PostModel
  // const CommentsScreen.fromPost({
  //   super.key,
  //   required PostModel post,
  //  }) : postId = post.id, postType = 'post';

  @override
  ConsumerState<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends ConsumerState<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _replyingToCommentId;
  String? _replyingToUsername;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreComments();
      }
    });
  }

  Future<void> _loadComments() async {
    await ref.read(commentsProvider(widget.postId).notifier)
        .loadComments(widget.postId);
  }

  Future<void> _loadMoreComments() async {
    await ref.read(commentsProvider(widget.postId).notifier)
        .loadMoreComments();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final commentsState = ref.watch(commentsProvider(widget.postId));

    return Scaffold(
      appBar: CustomAppBar(
        title: 'التعليقات',
        titleStyle: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontFamily: 'Cairo',
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Column(
          children: [
            // Comments header
            _buildCommentsHeader(),

            // Comments list
            Expanded(
              child: commentsState.getComments(widget.postId).isEmpty && !commentsState.isLoading(widget.postId)
                  ? _buildEmptyComments()
                  : ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(vertical: 8.h),
                itemCount: commentsState.getComments(widget.postId).length + (commentsState.isLoading(widget.postId) ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == commentsState.getComments(widget.postId).length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    );
                  }

                  final comment = commentsState.getComments(widget.postId)[index];
                  return _buildCommentItem(comment, authState.user?.uid);
                },
              ),
            ),

            // Comment input
            _buildCommentInput(authState.user?.uid),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.mode_comment_outlined,
            color: AppColors.primary,
            size: 24.sp,
          ),

          SizedBox(width: 12.w),

          Text(
            'التعليقات',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyComments() {
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
              fontSize: 18.sp,
              color: AppColors.textSecondary,
              fontFamily: 'Cairo',
            ),
          ),

          SizedBox(height: 8.h),

          Text(
            'كن أول من يعلق على هذا المنشور',
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

  Widget _buildCommentItem(CommentModel comment, String? currentUserId) {
    final isOwner = comment.userId == currentUserId;
    final isPostOwner = false; // We don't have post owner info in this context

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile image
              GestureDetector(
                onTap: () => _viewProfile(comment.userId),
                child: Container(
                  width: 36.w,
                  height: 36.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(comment.userProfileImage),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              SizedBox(width: 12.w),

              // Comment content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username and badges
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _viewProfile(comment.userId),
                          child: Text(
                            comment.username,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),

                        if (comment.isUserVerified) ...[
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.verified,
                            size: 16.sp,
                            color: AppColors.primary,
                          ),
                        ],

                        if (isPostOwner) ...[
                          SizedBox(width: 4.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              'صاحب المنشور',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: AppColors.white,
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
                    ),

                    SizedBox(height: 4.h),

                    // Comment text
                    Text(
                      comment.displayText,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: comment.isDeleted
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        fontStyle: comment.isDeleted ? FontStyle.italic : FontStyle.normal,
                        fontFamily: 'Cairo',
                      ),
                    ),

                    if (!comment.isDeleted) ...[
                      SizedBox(height: 8.h),

                      // Comment actions
                      Row(
                        children: [
                          // Like button
                          GestureDetector(
                            onTap: () => _toggleCommentLike(comment),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  comment.isLikedBy(currentUserId ?? '')
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 16.sp,
                                  color: comment.isLikedBy(currentUserId ?? '')
                                      ? AppColors.like
                                      : AppColors.textSecondary,
                                ),
                                if (comment.likesCount > 0) ...[
                                  SizedBox(width: 4.w),
                                  Text(
                                    comment.likesCount.toString(),
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

                          SizedBox(width: 16.w),

                          // Reply button
                          GestureDetector(
                            onTap: () => _replyToComment(comment),
                            child: Text(
                              'رد',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),

                          if (comment.repliesCount > 0) ...[
                            SizedBox(width: 16.w),
                            GestureDetector(
                              onTap: () => _viewReplies(comment),
                              child: Text(
                                'عرض الردود (${comment.repliesCount})',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                          ],

                          const Spacer(),

                          // More options
                          GestureDetector(
                            onTap: () => _showCommentOptions(comment, isOwner),
                            child: Icon(
                              Icons.more_horiz,
                              size: 16.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(String? currentUserId) {
    if (currentUserId == null) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(
            top: BorderSide(color: AppColors.divider, width: 1),
          ),
        ),
        child: Center(
          child: Text(
            'يجب تسجيل الدخول للتعليق',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
              fontFamily: 'Cairo',
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 12.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply indicator
            if (_replyingToCommentId != null) ...[
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
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
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12.h),
            ],

            // Comment input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textPrimary,
                      fontFamily: 'Cairo',
                    ),
                    decoration: InputDecoration(
                      hintText: _replyingToCommentId != null
                          ? 'اكتب ردك...'
                          : 'أضف تعليقاً...',
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary,
                        fontFamily: 'Cairo',
                      ),
                      filled: true,
                      fillColor: AppColors.inputBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submitComment(),
                  ),
                ),

                SizedBox(width: 8.w),

                // Send button
                GestureDetector(
                  onTap: _submitComment,
                  child: Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: _commentController.text.trim().isNotEmpty
                          ? AppColors.primary
                          : AppColors.inputBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.send,
                      size: 20.sp,
                      color: _commentController.text.trim().isNotEmpty
                          ? AppColors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final authState = ref.read(authProvider);
    if (authState.user == null) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(commentsProvider(widget.postId).notifier)
          .addComment(widget.postId, text, parentId: _replyingToCommentId);

      _commentController.clear();
      _cancelReply();

      // Reload comments
      await _loadComments();

      // Scroll to top to show new comment
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في إضافة التعليق: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleCommentLike(CommentModel comment) async {
    final authState = ref.read(authProvider);
    if (authState.user == null) return;

    try {
      await ref.read(commentsProvider(widget.postId).notifier)
          .likeComment(widget.postId, comment.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ في التفاعل مع التعليق'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _replyToComment(CommentModel comment) {
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

  void _viewProfile(String userId) {
    // Navigate to user profile
    print('View profile: $userId');
  }

  void _viewReplies(CommentModel comment) {
    // Navigate to replies screen
    print('View replies for comment: ${comment.id}');
  }

  void _showCommentOptions(CommentModel comment, bool isOwner) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwner) ...[
              ListTile(
                leading: Icon(Icons.edit, color: AppColors.primary),
                title: Text(
                  'تعديل التعليق',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _editComment(comment);
                },
              ),

              ListTile(
                leading: Icon(Icons.delete, color: AppColors.error),
                title: Text(
                  'حذف التعليق',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteComment(comment);
                },
              ),
            ] else ...[
              ListTile(
                leading: Icon(Icons.report, color: AppColors.error),
                title: Text(
                  'إبلاغ عن التعليق',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _reportComment(comment);
                },
              ),
            ],

            ListTile(
              leading: Icon(Icons.copy),
              title: Text(
                'نسخ النص',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              onTap: () {
                Navigator.pop(context);
                _copyCommentText(comment);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editComment(CommentModel comment) {
    // Implement edit comment
    print('Edit comment: ${comment.id}');
  }

  Future<void> _deleteComment(CommentModel comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('حذف التعليق'),
        content: Text('هل أنت متأكد من حذف هذا التعليق؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
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
        await ref.read(commentsProvider(widget.postId).notifier)
            .deleteComment(widget.postId, comment.id);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم حذف التعليق'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('فشل في حذف التعليق'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _reportComment(CommentModel comment) {
    // Implement report comment
    print('Report comment: ${comment.id}');
  }

  void _copyCommentText(CommentModel comment) {
    // Implement copy comment text
    print('Copy comment text: ${comment.text}');
  }
}

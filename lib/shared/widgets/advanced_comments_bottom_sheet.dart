import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_colors.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';
import '../providers/interaction_provider.dart';

class AdvancedCommentsBottomSheet extends ConsumerStatefulWidget {
  final String postId;
  final Function(String)? onCommentAdded;

  const AdvancedCommentsBottomSheet({
    super.key,
    required this.postId,
    this.onCommentAdded,
  });

  @override
  ConsumerState<AdvancedCommentsBottomSheet> createState() => _AdvancedCommentsBottomSheetState();
}

class _AdvancedCommentsBottomSheetState extends ConsumerState<AdvancedCommentsBottomSheet>
    with TickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  late AnimationController _replyController;
  String? _replyingToCommentId;
  String? _replyingToUsername;
  
  // Mock data - في التطبيق الحقيقي ستأتي من Firebase
  List<CommentModel> _comments = [];

  @override
  void initState() {
    super.initState();
    _replyController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _replyController.dispose();
    super.dispose();
  }

  void _loadComments() {
    // Mock comments - في التطبيق الحقيقي ستأتي من Firebase
    setState(() {
      _comments = [
        CommentModel(
          id: '1',
          postId: widget.postId,
          userId: 'user1',
          username: 'أحمد محمد',
          userProfilePicture: '',
          content: 'تعليق رائع! أحبب�� هذا المنشور كثيراً 😍',
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
          likesCount: 5,
          repliesCount: 2,
          isLiked: false,
          parentCommentId: null,
        ),
        CommentModel(
          id: '2',
          postId: widget.postId,
          userId: 'user2',
          username: 'فاطمة علي',
          userProfilePicture: '',
          content: 'محتوى مفيد جداً، شكراً لك على المشاركة',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          likesCount: 3,
          repliesCount: 0,
          isLiked: true,
          parentCommentId: null,
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildCommentsList()),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Text(
                'التعليقات',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontFamily: 'Cairo',
                ),
              ),
              const Spacer(),
              Text(
                '${_comments.length} تعليق',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    if (_comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.comment_outlined,
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

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: _comments.length,
      itemBuilder: (context, index) {
        final comment = _comments[index];
        return CommentItem(
          comment: comment,
          onReply: () => _startReply(comment),
          onLike: () => _toggleCommentLike(comment.id),
          onDelete: () => _deleteComment(comment.id),
        );
      },
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Reply indicator
          if (_replyingToCommentId != null) _buildReplyIndicator(),
          
          Row(
            children: [
              // User avatar
              Container(
                width: 36.w,
                height: 36.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
                child: Icon(
                  Icons.person,
                  color: AppColors.white,
                  size: 20.sp,
                ),
              ),
              
              SizedBox(width: 12.w),
              
              // Comment input
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            hintText: _replyingToCommentId != null 
                                ? 'رد على $_replyingToUsername...'
                                : 'اكتب تعليق...',
                            hintStyle: TextStyle(
                              color: AppColors.textSecondary,
                              fontFamily: 'Cairo',
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontFamily: 'Cairo',
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.newline,
                        ),
                      ),
                      
                      // Emoji button
                      IconButton(
                        onPressed: _showEmojiPicker,
                        icon: Icon(
                          Icons.emoji_emotions_outlined,
                          color: AppColors.textSecondary,
                          size: 20.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(width: 8.w),
              
              // Send button
              GestureDetector(
                onTap: _sendComment,
                child: Container(
                  width: 36.w,
                  height: 36.h,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.send,
                    color: AppColors.white,
                    size: 18.sp,
                  ),
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
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(
            Icons.reply,
            color: AppColors.primary,
            size: 16.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'الرد على $_replyingToUsername',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.primary,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          IconButton(
            onPressed: _cancelReply,
            icon: Icon(
              Icons.close,
              color: AppColors.primary,
              size: 16.sp,
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
    _focusNode.requestFocus();
    _replyController.forward();
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUsername = null;
    });
    _replyController.reverse();
  }

  void _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final commentId = await ref.read(interactionProvider.notifier).addComment(
      widget.postId,
      text,
      parentCommentId: _replyingToCommentId,
    );

    if (commentId != null) {
      _commentController.clear();
      _cancelReply();
      widget.onCommentAdded?.call(text);
      _loadComments(); // Reload comments
    }
  }

  void _toggleCommentLike(String commentId) {
    // Implementation for liking comments
  }

  void _deleteComment(String commentId) {
    // Implementation for deleting comments
  }

  void _showEmojiPicker() {
    // Implementation for emoji picker
  }
}

class CommentItem extends StatelessWidget {
  final CommentModel comment;
  final VoidCallback onReply;
  final VoidCallback onLike;
  final VoidCallback onDelete;

  const CommentItem({
    super.key,
    required this.comment,
    required this.onReply,
    required this.onLike,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User avatar
          Container(
            width: 32.w,
            height: 32.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
            child: Icon(
              Icons.person,
              color: AppColors.white,
              size: 16.sp,
            ),
          ),
          
          SizedBox(width: 12.w),
          
          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username and content
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.username,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        comment.content,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textPrimary,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 8.h),
                
                // Actions
                Row(
                  children: [
                    Text(
                      _formatTime(comment.createdAt),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    
                    SizedBox(width: 16.w),
                    
                    GestureDetector(
                      onTap: onLike,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            comment.isLiked ? Icons.favorite : Icons.favorite_border,
                            color: comment.isLiked ? AppColors.like : AppColors.textSecondary,
                            size: 16.sp,
                          ),
                          if (comment.likesCount > 0) ...[
                            SizedBox(width: 4.w),
                            Text(
                              '${comment.likesCount}',
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
                    
                    GestureDetector(
                      onTap: onReply,
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
                    
                    const Spacer(),
                    
                    IconButton(
                      onPressed: () => _showCommentOptions(context),
                      icon: Icon(
                        Icons.more_horiz,
                        color: AppColors.textSecondary,
                        size: 16.sp,
                      ),
                    ),
                  ],
                ),
                
                // Replies indicator
                if (comment.repliesCount > 0) ...[
                  SizedBox(height: 8.h),
                  GestureDetector(
                    onTap: () => _showReplies(context),
                    child: Row(
                      children: [
                        Container(
                          width: 20.w,
                          height: 1.h,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'عرض ${comment.repliesCount} رد',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCommentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.copy),
              title: Text('نسخ التعليق'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.report),
              title: Text('إبلاغ عن التعليق'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.delete, color: AppColors.error),
              title: Text('حذف التعليق', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReplies(BuildContext context) {
    // Implementation for showing replies
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inHours < 1) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inDays < 1) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return 'منذ ${difference.inDays} يوم';
    }
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/chat_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/custom_app_bar.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final ChatModel chat;
  final UserModel otherUser;

  const ChatScreen({
    super.key,
    required this.chat,
    required this.otherUser,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  late AnimationController _typingController;
  late AnimationController _recordingController;
  
  bool _isTyping = false;
  bool _isRecording = false;
  bool _showEmojiPicker = false;
  String? _replyingToMessageId;
  
  List<MessageModel> _messages = [];

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _recordingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _loadMessages();
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingController.dispose();
    _recordingController.dispose();
    super.dispose();
  }

  void _loadMessages() {
    // Mock messages
    _messages = [
      MessageModel(
        id: '1',
        chatId: widget.chat.id,
        senderId: widget.otherUser.id,
        senderName: widget.otherUser.displayName,
        content: 'مرحبا! كيف حالك؟',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: true,
      ),
      MessageModel(
        id: '2',
        chatId: widget.chat.id,
        senderId: 'current_user',
        senderName: 'أنا',
        content: 'بخير والحمد لله، وأنت؟',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: true,
      ),
      MessageModel(
        id: '3',
        chatId: widget.chat.id,
        senderId: widget.otherUser.id,
        senderName: widget.otherUser.displayName,
        content: 'بخير أيضاً، شكراً لك',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        isRead: false,
      ),
    ];
    setState(() {});
  }

  void _onTextChanged() {
    final isCurrentlyTyping = _messageController.text.isNotEmpty;
    if (isCurrentlyTyping != _isTyping) {
      setState(() => _isTyping = isCurrentlyTyping);
      if (_isTyping) {
        _typingController.forward();
      } else {
        _typingController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessagesList()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 1,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
      ),
      title: Row(
        children: [
          Container(
            width: 35.w,
            height: 35.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: widget.otherUser.profilePicture,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.primary,
                  child: Icon(Icons.person, color: AppColors.white, size: 18.sp),
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUser.displayName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'Cairo',
                  ),
                ),
                Text(
                  widget.otherUser.isOnline ? 'متصل الآن' : 'آخر ظهور منذ ساعة',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: widget.otherUser.isOnline ? AppColors.success : AppColors.textSecondary,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _makeVideoCall,
          icon: Icon(Icons.videocam, color: AppColors.textPrimary),
        ),
        IconButton(
          onPressed: _makeVoiceCall,
          icon: Icon(Icons.call, color: AppColors.textPrimary),
        ),
        IconButton(
          onPressed: _showChatInfo,
          icon: Icon(Icons.info_outline, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16.w),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isCurrentUser = message.senderId == 'current_user';
        
        return MessageBubble(
          message: message,
          isCurrentUser: isCurrentUser,
          showAvatar: !isCurrentUser,
          avatarUrl: widget.otherUser.profilePicture,
          onReply: () => _replyToMessage(message),
          onReact: (emoji) => _reactToMessage(message.id, emoji),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          // Reply indicator
          if (_replyingToMessageId != null) _buildReplyIndicator(),
          
          Row(
            children: [
              // Attachment button
              IconButton(
                onPressed: _showAttachmentOptions,
                icon: Icon(Icons.add, color: AppColors.primary),
              ),
              
              // Message input
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
                          controller: _messageController,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            hintText: 'اكتب رسالة...',
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
                      IconButton(
                        onPressed: _toggleEmojiPicker,
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
              
              // Send/Record button
              AnimatedBuilder(
                animation: _typingController,
                builder: (context, child) {
                  return GestureDetector(
                    onTap: _isTyping ? _sendMessage : null,
                    onLongPressStart: _isTyping ? null : (_) => _startRecording(),
                    onLongPressEnd: _isTyping ? null : (_) => _stopRecording(),
                    child: Container(
                      width: 40.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isTyping ? Icons.send : Icons.mic,
                        color: AppColors.white,
                        size: 20.sp,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReplyIndicator() {
    final originalMessage = _messages.firstWhere(
      (m) => m.id == _replyingToMessageId,
      orElse: () => _messages.first,
    );
    
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(Icons.reply, color: AppColors.primary, size: 16.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'رد على ${originalMessage.senderName}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Cairo',
                  ),
                ),
                Text(
                  originalMessage.content,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                    fontFamily: 'Cairo',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _replyingToMessageId = null),
            icon: Icon(Icons.close, color: AppColors.primary, size: 16.sp),
          ),
        ],
      ),
    );
  }

  // Methods
  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final message = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: widget.chat.id,
      senderId: 'current_user',
      senderName: 'أنا',
      content: text,
      type: MessageType.text,
      timestamp: DateTime.now(),
      isRead: false,
      replyToMessageId: _replyingToMessageId,
    );

    setState(() {
      _messages.add(message);
      _replyingToMessageId = null;
    });

    _messageController.clear();
    _scrollToBottom();
  }

  void _replyToMessage(MessageModel message) {
    setState(() => _replyingToMessageId = message.id);
    _focusNode.requestFocus();
  }

  void _reactToMessage(String messageId, String emoji) {
    // Implementation for message reactions
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo),
              title: Text('صورة', style: TextStyle(fontFamily: 'Cairo')),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('كاميرا', style: TextStyle(fontFamily: 'Cairo')),
              onTap: () => _pickImage(ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.videocam),
              title: Text('فيديو', style: TextStyle(fontFamily: 'Cairo')),
              onTap: _pickVideo,
            ),
            ListTile(
              leading: Icon(Icons.insert_drive_file),
              title: Text('ملف', style: TextStyle(fontFamily: 'Cairo')),
              onTap: _pickFile,
            ),
          ],
        ),
      ),
    );
  }

  void _pickImage(ImageSource source) async {
    Navigator.pop(context);
    // Implementation for picking image
  }

  void _pickVideo() async {
    Navigator.pop(context);
    // Implementation for picking video
  }

  void _pickFile() async {
    Navigator.pop(context);
    // Implementation for picking file
  }

  void _startRecording() {
    setState(() => _isRecording = true);
    _recordingController.repeat();
  }

  void _stopRecording() {
    setState(() => _isRecording = false);
    _recordingController.stop();
  }

  void _toggleEmojiPicker() {
    setState(() => _showEmojiPicker = !_showEmojiPicker);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _makeVideoCall() {
    // Implementation for video call
  }

  void _makeVoiceCall() {
    // Implementation for voice call
  }

  void _showChatInfo() {
    // Implementation for chat info
  }
}

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isCurrentUser;
  final bool showAvatar;
  final String avatarUrl;
  final VoidCallback onReply;
  final Function(String) onReact;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.showAvatar,
    required this.avatarUrl,
    required this.onReply,
    required this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser && showAvatar) ...[
            Container(
              width: 24.w,
              height: 24.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
              child: Icon(Icons.person, color: AppColors.white, size: 12.sp),
            ),
            SizedBox(width: 8.w),
          ],
          
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(context),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isCurrentUser ? AppColors.primary : AppColors.inputBackground,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    topRight: Radius.circular(16.r),
                    bottomLeft: Radius.circular(isCurrentUser ? 16.r : 4.r),
                    bottomRight: Radius.circular(isCurrentUser ? 4.r : 16.r),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reply indicator
                    if (message.replyToMessageId != null) _buildReplyIndicator(),
                    
                    // Message content
                    Text(
                      message.content,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: isCurrentUser ? AppColors.white : AppColors.textPrimary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    
                    SizedBox(height: 4.h),
                    
                    // Timestamp and read status
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: isCurrentUser 
                                ? AppColors.white.withOpacity(0.7)
                                : AppColors.textSecondary,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        if (isCurrentUser) ...[
                          SizedBox(width: 4.w),
                          Icon(
                            message.isRead ? Icons.done_all : Icons.done,
                            color: message.isRead 
                                ? AppColors.white 
                                : AppColors.white.withOpacity(0.7),
                            size: 12.sp,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
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
        color: (isCurrentUser ? AppColors.white : AppColors.primary).withOpacity(0.2),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        'رد على رسالة سابقة',
        style: TextStyle(
          fontSize: 12.sp,
          color: isCurrentUser ? AppColors.white : AppColors.textPrimary,
          fontStyle: FontStyle.italic,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.reply),
              title: Text('رد', style: TextStyle(fontFamily: 'Cairo')),
              onTap: () {
                Navigator.pop(context);
                onReply();
              },
            ),
            ListTile(
              leading: Icon(Icons.copy),
              title: Text('نسخ', style: TextStyle(fontFamily: 'Cairo')),
              onTap: () => Navigator.pop(context),
            ),
            if (isCurrentUser)
              ListTile(
                leading: Icon(Icons.delete, color: AppColors.error),
                title: Text('حذف', style: TextStyle(color: AppColors.error, fontFamily: 'Cairo')),
                onTap: () => Navigator.pop(context),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}

enum MessageType { text, image, video, audio, file }

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final String? replyToMessageId;
  final String? mediaUrl;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.isRead,
    this.replyToMessageId,
    this.mediaUrl,
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/chat_provider.dart';
import '../../../../shared/models/chat_model.dart';
import '../../../../shared/services/follow_service.dart';
import '../../../../shared/models/user_model.dart';
import 'chat_screen.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadChats();
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
        _loadMoreChats();
      }
    });
  }

  Future<void> _loadChats() async {
    final authState = ref.read(authProvider);
    if (authState.user != null) {
      await ref.read(chatsProvider.notifier)
          .loadUserChats(authState.user!.uid, refresh: true);
    }
  }

  Future<void> _loadMoreChats() async {
    final authState = ref.read(authProvider);
    if (authState.user != null) {
      await ref.read(chatsProvider.notifier)
          .loadUserChats(authState.user!.uid, refresh: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final chatsState = ref.watch(chatsProvider);

    if (!authState.isAuthenticated) {
      return Scaffold(
        appBar: CustomAppBar(
          title: AppConstants.messages,
          showBackButton: false,
        ),
        body: const Center(
          child: Text(
            'يجب تسجيل الدخول أولاً',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: AppConstants.messages,
        titleStyle: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          fontFamily: 'Cairo',
        ),
        showBackButton: false,
        actions: [
          IconButton(
            onPressed: _startNewChat,
            icon: Icon(
              Icons.edit_outlined,
              size: 24.sp,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: chatsState.isLoading && chatsState.chats.isEmpty,
        child: RefreshIndicator(
          onRefresh: _loadChats,
          color: AppColors.primary,
          child: chatsState.chats.isEmpty && !chatsState.isLoading
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: chatsState.chats.length + (chatsState.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == chatsState.chats.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      );
                    }

                    final chat = chatsState.chats[index];
                    return _buildChatItem(chat, authState.user!.uid);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.message_outlined,
            size: 64.sp,
            color: AppColors.textSecondary,
          ),
          
          SizedBox(height: 16.h),
          
          Text(
            'لا توجد محادثات بعد',
            style: TextStyle(
              fontSize: 18.sp,
              color: AppColors.textSecondary,
              fontFamily: 'Cairo',
            ),
          ),
          
          SizedBox(height: 8.h),
          
          Text(
            'ابدأ محادثة جديدة مع أصدقائك',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
              fontFamily: 'Cairo',
            ),
          ),
          
          SizedBox(height: 24.h),
          
          ElevatedButton(
            onPressed: _startNewChat,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.r),
              ),
            ),
            child: Text(
              'بدء محادثة جديدة',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(ChatModel chat, String currentUserId) {
    final otherParticipant = chat.participants
        .where((p) => p.userId != currentUserId)
        .firstOrNull;
    
    if (otherParticipant == null) return const SizedBox.shrink();

    final unreadCount = chat.getUnreadCount(currentUserId);
    final lastMessage = chat.lastMessage;
    final isOnline = otherParticipant.isOnline;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      leading: Stack(
        children: [
          Container(
            width: 56.w,
            height: 56.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: otherParticipant.profileImageUrl.isNotEmpty
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(otherParticipant.profileImageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: otherParticipant.profileImageUrl.isEmpty 
                  ? AppColors.inputBackground 
                  : null,
            ),
            child: otherParticipant.profileImageUrl.isEmpty
                ? Icon(
                    Icons.person,
                    color: AppColors.textSecondary,
                    size: 28.sp,
                  )
                : null,
          ),
          
          if (isOnline)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 16.w,
                height: 16.h,
                decoration: BoxDecoration(
                  color: AppColors.online,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.white,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      
      title: Row(
        children: [
          Expanded(
            child: Text(
              otherParticipant.username,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          
          if (chat.lastMessageTime != null)
            Text(
              _formatTime(chat.lastMessageTime!),
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
            ),
        ],
      ),
      
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              lastMessage?.displayText ?? 'لا توجد رسائل',
              style: TextStyle(
                fontSize: 14.sp,
                color: unreadCount > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                fontFamily: 'Cairo',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          if (unreadCount > 0)
            Container(
              margin: EdgeInsets.only(left: 8.w),
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
        ],
      ),
      
      onTap: () => _openChat(chat, otherParticipant),
      onLongPress: () => _showChatOptions(chat),
    );
  }

  void _openChat(ChatModel chat, ChatParticipant otherParticipant) {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => ChatScreen(
    //       chat: chat,
    //       otherParticipant: otherParticipant,
    //     ),
    //   ),
    // );
  }

  void _showChatOptions(ChatModel chat) {
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
            ListTile(
              leading: Icon(Icons.archive, color: AppColors.textSecondary),
              title: Text(
                'أرشفة المحادثة',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              onTap: () {
                Navigator.pop(context);
                _archiveChat(chat);
              },
            ),
            
            ListTile(
              leading: Icon(Icons.notifications_off, color: AppColors.textSecondary),
              title: Text(
                'كتم الإشعارات',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              onTap: () {
                Navigator.pop(context);
                _muteChat(chat);
              },
            ),
            
            ListTile(
              leading: Icon(Icons.delete, color: AppColors.error),
              title: Text(
                'حذف المحادثة',
                style: TextStyle(
                  color: AppColors.error,
                  fontFamily: 'Cairo',
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteChat(chat);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startNewChat() async {
    final result = await showModalBottomSheet<UserModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildNewChatBottomSheet(),
    );

    if (result != null) {
      await _createChatWithUser(result);
    }
  }

  Widget _buildNewChatBottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        children: [
          Text(
            'بدء محادثة جديدة',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
          
          SizedBox(height: 20.h),
          
          // Search field
          TextField(
            decoration: InputDecoration(
              hintText: 'البحث عن مستخدم...',
              hintStyle: TextStyle(
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
              prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.inputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25.r),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: _searchUsers,
          ),
          
          SizedBox(height: 16.h),
          
          // User suggestions
          Expanded(
            child: FutureBuilder<List<UserModel>>(
              future: FollowService.getFollowSuggestions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا توجد اقتراحات',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                  );
                }

                final users = snapshot.data!;
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: Container(
                        width: 40.w,
                        height: 40.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: user.hasProfileImage
                              ? DecorationImage(
                                  image: CachedNetworkImageProvider(user.profileImageUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: !user.hasProfileImage 
                              ? AppColors.inputBackground 
                              : null,
                        ),
                        child: !user.hasProfileImage
                            ? Icon(
                                Icons.person,
                                color: AppColors.textSecondary,
                                size: 20.sp,
                              )
                            : null,
                      ),
                      
                      title: Text(
                        user.username,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      
                      subtitle: Text(
                        user.fullName,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      
                      onTap: () => Navigator.pop(context, user),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _searchUsers(String query) {
    // Implement user search
    print('Searching for: $query');
  }

  Future<void> _createChatWithUser(UserModel user) async {
    final authState = ref.read(authProvider);
    if (authState.user == null) return;

    try {
      final chat = await ref.read(chatsProvider.notifier)
          .createOrGetDirectChat(authState.user!.uid, user.uid);

      if (chat != null) {
        final otherParticipant = chat.participants
            .where((p) => p.userId == user.uid)
            .first;
        
        _openChat(chat, otherParticipant);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في إنشاء المحادثة'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _archiveChat(ChatModel chat) async {
    try {
      await ref.read(chatsProvider.notifier).archiveChat(chat.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم أرشفة المحادثة'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في أرشفة المحادثة'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _muteChat(ChatModel chat) {
    // Implement mute chat
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم كتم الإشعارات'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _deleteChat(ChatModel chat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('حذف المحادثة'),
        content: Text('هل أنت متأكد من حذف هذه المحادثة؟'),
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
        await ref.read(chatsProvider.notifier).deleteChat(chat.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف المحادثة'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في حذف المحادثة'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'أمس';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}

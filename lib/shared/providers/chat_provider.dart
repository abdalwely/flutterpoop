import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class ChatsState {
  final List<ChatModel> chats;
  final bool isLoading;
  final String? error;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  const ChatsState({
    this.chats = const [],
    this.isLoading = false,
    this.error,
    this.lastDocument,
    this.hasMore = true,
  });

  ChatsState copyWith({
    List<ChatModel>? chats,
    bool? isLoading,
    String? error,
    DocumentSnapshot? lastDocument,
    bool? hasMore,
  }) {
    return ChatsState(
      chats: chats ?? this.chats,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastDocument: lastDocument ?? this.lastDocument,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class ChatsNotifier extends StateNotifier<ChatsState> {
  final FirestoreService _firestoreService;

  ChatsNotifier(this._firestoreService) : super(const ChatsState());

  Future<void> loadUserChats(String userId, {bool refresh = false}) async {
    if (refresh) {
      state = const ChatsState(isLoading: true);
    } else if (state.isLoading || !state.hasMore) {
      return;
    }

    try {
      if (!refresh) {
        state = state.copyWith(isLoading: true);
      }

      // Get chats where user is participant
      Query query = FirebaseFirestore.instance
          .collection('chats')
          .where('participantIds', arrayContains: userId)
          .orderBy('lastMessageTime', descending: true)
          .limit(20);

      if (!refresh && state.lastDocument != null) {
        query = query.startAfterDocument(state.lastDocument!);
      }

      final querySnapshot = await query.get();
      final newChats = querySnapshot.docs
          .map((doc) => ChatModel.fromFirestore(doc))
          .toList();

      if (refresh) {
        state = ChatsState(
          chats: newChats,
          isLoading: false,
          hasMore: newChats.length >= 20,
          lastDocument: querySnapshot.docs.isNotEmpty 
              ? querySnapshot.docs.last 
              : null,
        );
      } else {
        state = state.copyWith(
          chats: [...state.chats, ...newChats],
          isLoading: false,
          hasMore: newChats.length >= 20,
          lastDocument: querySnapshot.docs.isNotEmpty 
              ? querySnapshot.docs.last 
              : null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<ChatModel?> createOrGetDirectChat(String currentUserId, String otherUserId) async {
    try {
      // Check if chat already exists
      final existingChatQuery = await FirebaseFirestore.instance
          .collection('chats')
          .where('type', isEqualTo: 'direct')
          .where('participantIds', arrayContains: currentUserId)
          .get();

      for (final doc in existingChatQuery.docs) {
        final chat = ChatModel.fromFirestore(doc);
        if (chat.participants.any((p) => p.userId == otherUserId)) {
          return chat;
        }
      }

      // Get other user data
      final otherUser = await _firestoreService.getUser(otherUserId);
      final currentUser = await _firestoreService.getUser(currentUserId);
      
      if (otherUser == null || currentUser == null) return null;

      // Create new chat
      final chatId = FirebaseFirestore.instance.collection('chats').doc().id;
      final participants = [
        ChatParticipant(
          userId: currentUserId,
          username: currentUser.username,
          profileImageUrl: currentUser.profileImageUrl,
          joinedAt: DateTime.now(),
        ),
        ChatParticipant(
          userId: otherUserId,
          username: otherUser.username,
          profileImageUrl: otherUser.profileImageUrl,
          joinedAt: DateTime.now(),
        ),
      ];

      final newChat = ChatModel(
        id: chatId,
        type: ChatType.direct,
        participants: participants,
        createdAt: DateTime.now(),
        createdBy: currentUserId,
      );

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .set(newChat.toJson());

      // Add to local state
      state = state.copyWith(chats: [newChat, ...state.chats]);

      return newChat;
    } catch (e) {
      state = state.copyWith(error: 'فشل في إنشاء المحادثة: $e');
      return null;
    }
  }

  Future<void> updateChatLastMessage(String chatId, MessageModel message) async {
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .update({
        'lastMessage': message.toJson(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local state
      final updatedChats = state.chats.map((chat) {
        if (chat.id == chatId) {
          return chat.copyWith(
            lastMessage: message,
            lastMessageTime: message.createdAt,
            updatedAt: DateTime.now(),
          );
        }
        return chat;
      }).toList();

      // Sort by last message time
      updatedChats.sort((a, b) {
        final aTime = a.lastMessageTime ?? a.createdAt;
        final bTime = b.lastMessageTime ?? b.createdAt;
        return bTime.compareTo(aTime);
      });

      state = state.copyWith(chats: updatedChats);
    } catch (e) {
      state = state.copyWith(error: 'فشل في تحديث المحادثة: $e');
    }
  }

  Future<void> markChatAsRead(String chatId, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .update({
        'lastReadTimes.$userId': FieldValue.serverTimestamp(),
        'unreadCounts.$userId': 0,
      });

      // Update local state
      final updatedChats = state.chats.map((chat) {
        if (chat.id == chatId) {
          final newUnreadCounts = Map<String, int>.from(chat.unreadCounts);
          final newLastReadTimes = Map<String, DateTime>.from(chat.lastReadTimes);
          
          newUnreadCounts[userId] = 0;
          newLastReadTimes[userId] = DateTime.now();
          
          return chat.copyWith(
            unreadCounts: newUnreadCounts,
            lastReadTimes: newLastReadTimes,
          );
        }
        return chat;
      }).toList();

      state = state.copyWith(chats: updatedChats);
    } catch (e) {
      state = state.copyWith(error: 'فشل في وضع علامة قراءة: $e');
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .delete();

      // Remove from local state
      final updatedChats = state.chats.where((chat) => chat.id != chatId).toList();
      state = state.copyWith(chats: updatedChats);
    } catch (e) {
      state = state.copyWith(error: 'فشل في حذف المحادثة: $e');
    }
  }

  Future<void> archiveChat(String chatId) async {
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .update({
        'isArchived': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local state
      final updatedChats = state.chats.map((chat) {
        if (chat.id == chatId) {
          return chat.copyWith(isArchived: true);
        }
        return chat;
      }).toList();

      state = state.copyWith(chats: updatedChats);
    } catch (e) {
      state = state.copyWith(error: 'فشل في أرشفة المحادثة: $e');
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  ChatModel? getChatById(String chatId) {
    try {
      return state.chats.firstWhere((chat) => chat.id == chatId);
    } catch (e) {
      return null;
    }
  }

  int getTotalUnreadCount(String userId) {
    return state.chats.fold(0, (total, chat) {
      return total + (chat.unreadCounts[userId] ?? 0);
    });
  }
}

// Messages State for individual chats
class MessagesState {
  final List<MessageModel> messages;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;

  const MessagesState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.lastDocument,
  });

  MessagesState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    String? error,
    bool? hasMore,
    DocumentSnapshot? lastDocument,
  }) {
    return MessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      lastDocument: lastDocument ?? this.lastDocument,
    );
  }
}

class MessagesNotifier extends StateNotifier<MessagesState> {
  MessagesNotifier() : super(const MessagesState());

  Future<void> loadMessages(String chatId, {bool refresh = false}) async {
    if (refresh) {
      state = const MessagesState(isLoading: true);
    } else if (state.isLoading || !state.hasMore) {
      return;
    }

    try {
      if (!refresh) {
        state = state.copyWith(isLoading: true);
      }

      Query query = FirebaseFirestore.instance
          .collection('messages')
          .where('chatId', isEqualTo: chatId)
          .orderBy('createdAt', descending: true)
          .limit(50);

      if (!refresh && state.lastDocument != null) {
        query = query.startAfterDocument(state.lastDocument!);
      }

      final querySnapshot = await query.get();
      final newMessages = querySnapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();

      if (refresh) {
        state = MessagesState(
          messages: newMessages.reversed.toList(),
          isLoading: false,
          hasMore: newMessages.length >= 50,
          lastDocument: querySnapshot.docs.isNotEmpty 
              ? querySnapshot.docs.last 
              : null,
        );
      } else {
        final allMessages = [...newMessages.reversed.toList(), ...state.messages];
        state = state.copyWith(
          messages: allMessages,
          isLoading: false,
          hasMore: newMessages.length >= 50,
          lastDocument: querySnapshot.docs.isNotEmpty 
              ? querySnapshot.docs.last 
              : null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderUsername,
    required String senderProfileImage,
    required MessageType type,
    String? text,
    String? mediaUrl,
    String? replyToMessageId,
  }) async {
    try {
      final messageId = FirebaseFirestore.instance.collection('messages').doc().id;
      final message = MessageModel(
        id: messageId,
        chatId: chatId,
        senderId: senderId,
        senderUsername: senderUsername,
        senderProfileImage: senderProfileImage,
        type: type,
        text: text,
        createdAt: DateTime.now(),
        replyToMessageId: replyToMessageId,
      );

      // Add to Firestore
      await FirebaseFirestore.instance
          .collection('messages')
          .doc(messageId)
          .set(message.toJson());

      // Add to local state immediately (optimistic update)
      state = state.copyWith(
        messages: [...state.messages, message],
      );

      // Update chat's last message
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .update({
        'lastMessage': message.toJson(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      state = state.copyWith(error: 'فشل في إرسال الرسالة: $e');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await FirebaseFirestore.instance
          .collection('messages')
          .doc(messageId)
          .update({
        'isDeleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local state
      final updatedMessages = state.messages.map((message) {
        if (message.id == messageId) {
          return message.copyWith(isDeleted: true);
        }
        return message;
      }).toList();

      state = state.copyWith(messages: updatedMessages);
    } catch (e) {
      state = state.copyWith(error: 'فشل في حذف الرسالة: $e');
    }
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      // Mark all unread messages as read
      final batch = FirebaseFirestore.instance.batch();
      final unreadMessages = state.messages.where(
        (message) => message.senderId != userId && message.status != MessageStatus.read,
      );

      for (final message in unreadMessages) {
        batch.update(
          FirebaseFirestore.instance.collection('messages').doc(message.id),
          {'status': MessageStatus.read.name},
        );
      }

      await batch.commit();

      // Update local state
      final updatedMessages = state.messages.map((message) {
        if (message.senderId != userId && message.status != MessageStatus.read) {
          return message.copyWith(status: MessageStatus.read);
        }
        return message;
      }).toList();

      state = state.copyWith(messages: updatedMessages);
    } catch (e) {
      state = state.copyWith(error: 'فشل في وضع علامة قراءة: $e');
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final chatsProvider = StateNotifierProvider<ChatsNotifier, ChatsState>((ref) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return ChatsNotifier(firestoreService);
});

final messagesProvider = StateNotifierProvider.family<MessagesNotifier, MessagesState, String>((ref, chatId) {
  return MessagesNotifier();
});

// Stream providers for real-time updates
final chatStreamProvider = StreamProvider.family<ChatModel?, String>((ref, chatId) {
  return FirebaseFirestore.instance
      .collection('chats')
      .doc(chatId)
      .snapshots()
      .map((doc) {
    if (doc.exists) {
      return ChatModel.fromFirestore(doc);
    }
    return null;
  });
});

final messagesStreamProvider = StreamProvider.family<List<MessageModel>, String>((ref, chatId) {
  return FirebaseFirestore.instance
      .collection('messages')
      .where('chatId', isEqualTo: chatId)
      .where('isDeleted', isEqualTo: false)
      .orderBy('createdAt', descending: false)
      .limit(50)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => MessageModel.fromFirestore(doc))
        .toList();
  });
});

// Individual chat providers
final chatProvider = FutureProvider.family<ChatModel?, String>((ref, chatId) async {
  final doc = await FirebaseFirestore.instance
      .collection('chats')
      .doc(chatId)
      .get();
  
  if (doc.exists) {
    return ChatModel.fromFirestore(doc);
  }
  return null;
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum MessageType { text, image, video, audio, file, post, story, reel, location, contact, sticker, gif }
enum MessageStatus { sending, sent, delivered, read, failed }
enum ChatType { direct, group }

class MessageMedia extends Equatable {
  final String id;
  final String url;
  final String? thumbnailUrl;
  final MessageType type;
  final int? duration; // for audio/video
  final int? size; // file size in bytes
  final String? fileName;
  final String? mimeType;
  final Map<String, dynamic>? metadata;

  const MessageMedia({
    required this.id,
    required this.url,
    this.thumbnailUrl,
    required this.type,
    this.duration,
    this.size,
    this.fileName,
    this.mimeType,
    this.metadata,
  });

  @override
  List<Object?> get props => [id, url, thumbnailUrl, type, duration, size, fileName, mimeType, metadata];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'type': type.name,
      'duration': duration,
      'size': size,
      'fileName': fileName,
      'mimeType': mimeType,
      'metadata': metadata,
    };
  }

  factory MessageMedia.fromJson(Map<String, dynamic> json) {
    return MessageMedia(
      id: json['id'] ?? '',
      url: json['url'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      duration: json['duration'],
      size: json['size'],
      fileName: json['fileName'],
      mimeType: json['mimeType'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }
}

class MessageReaction extends Equatable {
  final String userId;
  final String username;
  final String reaction; // emoji
  final DateTime createdAt;

  const MessageReaction({
    required this.userId,
    required this.username,
    required this.reaction,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [userId, username, reaction, createdAt];

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'reaction': reaction,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      reaction: json['reaction'] ?? '',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }
}

class SharedContent extends Equatable {
  final String id;
  final String type; // 'post', 'story', 'reel', 'profile'
  final String? thumbnailUrl;
  final String? title;
  final String? description;
  final String? ownerUsername;
  final Map<String, dynamic>? data;

  const SharedContent({
    required this.id,
    required this.type,
    this.thumbnailUrl,
    this.title,
    this.description,
    this.ownerUsername,
    this.data,
  });

  @override
  List<Object?> get props => [id, type, thumbnailUrl, title, description, ownerUsername, data];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'thumbnailUrl': thumbnailUrl,
      'title': title,
      'description': description,
      'ownerUsername': ownerUsername,
      'data': data,
    };
  }

  factory SharedContent.fromJson(Map<String, dynamic> json) {
    return SharedContent(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      title: json['title'],
      description: json['description'],
      ownerUsername: json['ownerUsername'],
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'])
          : null,
    );
  }
}

class MessageModel extends Equatable {
  final String id;
  final String chatId;
  final String senderId;
  final String senderUsername;
  final String senderProfileImage;
  final MessageType type;
  final String? text;
  final MessageMedia? media;
  final SharedContent? sharedContent;
  final String? replyToMessageId;
  final List<MessageReaction> reactions;
  final MessageStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final bool isEdited;
  final bool isDeleted;
  final bool isForwarded;
  final String? forwardedFromChatId;
  final String? forwardedFromMessageId;
  final Map<String, dynamic>? metadata;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderUsername,
    required this.senderProfileImage,
    required this.type,
    this.text,
    this.media,
    this.sharedContent,
    this.replyToMessageId,
    this.reactions = const [],
    this.status = MessageStatus.sending,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.isEdited = false,
    this.isDeleted = false,
    this.isForwarded = false,
    this.forwardedFromChatId,
    this.forwardedFromMessageId,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        id, chatId, senderId, senderUsername, senderProfileImage, type, text,
        media, sharedContent, replyToMessageId, reactions, status, createdAt,
        updatedAt, deletedAt, isEdited, isDeleted, isForwarded,
        forwardedFromChatId, forwardedFromMessageId, metadata,
      ];

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderUsername,
    String? senderProfileImage,
    MessageType? type,
    String? text,
    MessageMedia? media,
    SharedContent? sharedContent,
    String? replyToMessageId,
    List<MessageReaction>? reactions,
    MessageStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool? isEdited,
    bool? isDeleted,
    bool? isForwarded,
    String? forwardedFromChatId,
    String? forwardedFromMessageId,
    Map<String, dynamic>? metadata,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderUsername: senderUsername ?? this.senderUsername,
      senderProfileImage: senderProfileImage ?? this.senderProfileImage,
      type: type ?? this.type,
      text: text ?? this.text,
      media: media ?? this.media,
      sharedContent: sharedContent ?? this.sharedContent,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      reactions: reactions ?? this.reactions,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      isForwarded: isForwarded ?? this.isForwarded,
      forwardedFromChatId: forwardedFromChatId ?? this.forwardedFromChatId,
      forwardedFromMessageId: forwardedFromMessageId ?? this.forwardedFromMessageId,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderUsername': senderUsername,
      'senderProfileImage': senderProfileImage,
      'type': type.name,
      'text': text,
      'media': media?.toJson(),
      'sharedContent': sharedContent?.toJson(),
      'replyToMessageId': replyToMessageId,
      'reactions': reactions.map((r) => r.toJson()).toList(),
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'isForwarded': isForwarded,
      'forwardedFromChatId': forwardedFromChatId,
      'forwardedFromMessageId': forwardedFromMessageId,
      'metadata': metadata,
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      chatId: json['chatId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderUsername: json['senderUsername'] ?? '',
      senderProfileImage: json['senderProfileImage'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      text: json['text'],
      media: json['media'] != null ? MessageMedia.fromJson(json['media']) : null,
      sharedContent: json['sharedContent'] != null
          ? SharedContent.fromJson(json['sharedContent'])
          : null,
      replyToMessageId: json['replyToMessageId'],
      reactions: (json['reactions'] as List<dynamic>?)
          ?.map((r) => MessageReaction.fromJson(r))
          .toList() ?? [],
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
      deletedAt: json['deletedAt'] != null
          ? (json['deletedAt'] as Timestamp).toDate()
          : null,
      isEdited: json['isEdited'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
      isForwarded: json['isForwarded'] ?? false,
      forwardedFromChatId: json['forwardedFromChatId'],
      forwardedFromMessageId: json['forwardedFromMessageId'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel.fromJson(data);
  }

  // Helper methods
  bool get hasText => text != null && text!.isNotEmpty;
  bool get hasMedia => media != null;
  bool get hasSharedContent => sharedContent != null;
  bool get isReply => replyToMessageId != null;
  bool get hasReactions => reactions.isNotEmpty;
  bool hasReactionBy(String userId) => reactions.any((r) => r.userId == userId);
  
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }

  String get displayText {
    if (isDeleted) return 'تم حذف هذه الرسالة';
    if (hasText) return text!;
    if (hasMedia) {
      switch (type) {
        case MessageType.image:
          return '📷 صورة';
        case MessageType.video:
          return '🎥 فيديو';
        case MessageType.audio:
          return '🎵 صوت';
        case MessageType.file:
          return '📁 ملف';
        default:
          return '📎 مرفق';
      }
    }
    if (hasSharedContent) return '🔗 محتوى مشارك';
    return '';
  }
}

class ChatParticipant extends Equatable {
  final String userId;
  final String username;
  final String profileImageUrl;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime joinedAt;
  final bool isAdmin;
  final bool isMuted;
  final bool isBlocked;

  const ChatParticipant({
    required this.userId,
    required this.username,
    required this.profileImageUrl,
    this.isOnline = false,
    this.lastSeen,
    required this.joinedAt,
    this.isAdmin = false,
    this.isMuted = false,
    this.isBlocked = false,
  });

  @override
  List<Object?> get props => [
        userId, username, profileImageUrl, isOnline, lastSeen,
        joinedAt, isAdmin, isMuted, isBlocked,
      ];

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'isAdmin': isAdmin,
      'isMuted': isMuted,
      'isBlocked': isBlocked,
    };
  }

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      profileImageUrl: json['profileImageUrl'] ?? '',
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] != null
          ? (json['lastSeen'] as Timestamp).toDate()
          : null,
      joinedAt: (json['joinedAt'] as Timestamp).toDate(),
      isAdmin: json['isAdmin'] ?? false,
      isMuted: json['isMuted'] ?? false,
      isBlocked: json['isBlocked'] ?? false,
    );
  }
}

class ChatModel extends Equatable {
  final String id;
  final ChatType type;
  final String? name; // for group chats
  final String? description; // for group chats
  final String? imageUrl; // for group chats
  final List<ChatParticipant> participants;
  final MessageModel? lastMessage;
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCounts; // userId -> unread count
  final Map<String, DateTime> lastReadTimes; // userId -> last read time
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isArchived;
  final bool isMuted;
  final bool isPinned;
  final String? createdBy;
  final Map<String, dynamic>? settings;
  final Map<String, dynamic>? metadata;

  const ChatModel({
    required this.id,
    required this.type,
    this.name,
    this.description,
    this.imageUrl,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCounts = const {},
    this.lastReadTimes = const {},
    required this.createdAt,
    this.updatedAt,
    this.isArchived = false,
    this.isMuted = false,
    this.isPinned = false,
    this.createdBy,
    this.settings,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        id, type, name, description, imageUrl, participants, lastMessage,
        lastMessageTime, unreadCounts, lastReadTimes, createdAt, updatedAt,
        isArchived, isMuted, isPinned, createdBy, settings, metadata,
      ];

  ChatModel copyWith({
    String? id,
    ChatType? type,
    String? name,
    String? description,
    String? imageUrl,
    List<ChatParticipant>? participants,
    MessageModel? lastMessage,
    DateTime? lastMessageTime,
    Map<String, int>? unreadCounts,
    Map<String, DateTime>? lastReadTimes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
    bool? isMuted,
    bool? isPinned,
    String? createdBy,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? metadata,
  }) {
    return ChatModel(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      lastReadTimes: lastReadTimes ?? this.lastReadTimes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
      isMuted: isMuted ?? this.isMuted,
      isPinned: isPinned ?? this.isPinned,
      createdBy: createdBy ?? this.createdBy,
      settings: settings ?? this.settings,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'participants': participants.map((p) => p.toJson()).toList(),
      'lastMessage': lastMessage?.toJson(),
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'unreadCounts': unreadCounts,
      'lastReadTimes': lastReadTimes.map(
        (key, value) => MapEntry(key, Timestamp.fromDate(value)),
      ),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isArchived': isArchived,
      'isMuted': isMuted,
      'isPinned': isPinned,
      'createdBy': createdBy,
      'settings': settings,
      'metadata': metadata,
    };
  }

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] ?? '',
      type: ChatType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChatType.direct,
      ),
      name: json['name'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      participants: (json['participants'] as List<dynamic>?)
          ?.map((p) => ChatParticipant.fromJson(p))
          .toList() ?? [],
      lastMessage: json['lastMessage'] != null
          ? MessageModel.fromJson(json['lastMessage'])
          : null,
      lastMessageTime: json['lastMessageTime'] != null
          ? (json['lastMessageTime'] as Timestamp).toDate()
          : null,
      unreadCounts: Map<String, int>.from(json['unreadCounts'] ?? {}),
      lastReadTimes: (json['lastReadTimes'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, (value as Timestamp).toDate())) ?? {},
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
      isArchived: json['isArchived'] ?? false,
      isMuted: json['isMuted'] ?? false,
      isPinned: json['isPinned'] ?? false,
      createdBy: json['createdBy'],
      settings: json['settings'] != null
          ? Map<String, dynamic>.from(json['settings'])
          : null,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel.fromJson(data);
  }

  // Helper methods
  bool get isGroup => type == ChatType.group;
  bool get isDirect => type == ChatType.direct;
  bool get hasUnreadMessages => unreadCounts.values.any((count) => count > 0);
  
  int getUnreadCount(String userId) => unreadCounts[userId] ?? 0;
  
  ChatParticipant? getParticipant(String userId) =>
      participants.where((p) => p.userId == userId).firstOrNull;
  
  List<ChatParticipant> get onlineParticipants =>
      participants.where((p) => p.isOnline).toList();
  
  String getDisplayName(String currentUserId) {
    if (isGroup) return name ?? 'مجموعة';
    final otherParticipant = participants
        .where((p) => p.userId != currentUserId)
        .firstOrNull;
    return otherParticipant?.username ?? 'مستخدم';
  }
  
  String? getDisplayImage(String currentUserId) {
    if (isGroup) return imageUrl;
    final otherParticipant = participants
        .where((p) => p.userId != currentUserId)
        .firstOrNull;
    return otherParticipant?.profileImageUrl;
  }
  
  bool isOnline(String currentUserId) {
    if (isGroup) return onlineParticipants.isNotEmpty;
    final otherParticipant = participants
        .where((p) => p.userId != currentUserId)
        .firstOrNull;
    return otherParticipant?.isOnline ?? false;
  }
  
  String? getLastSeenText(String currentUserId) {
    if (isGroup) return null;
    final otherParticipant = participants
        .where((p) => p.userId != currentUserId)
        .firstOrNull;
    
    if (otherParticipant?.isOnline == true) return 'نشط الآن';
    if (otherParticipant?.lastSeen == null) return null;
    
    final difference = DateTime.now().difference(otherParticipant!.lastSeen!);
    if (difference.inMinutes < 5) return 'نشط منذ قليل';
    if (difference.inHours < 1) return 'نشط منذ ${difference.inMinutes} دقيقة';
    if (difference.inDays < 1) return 'نشط منذ ${difference.inHours} ساعة';
    return 'نشط منذ ${difference.inDays} يوم';
  }
}

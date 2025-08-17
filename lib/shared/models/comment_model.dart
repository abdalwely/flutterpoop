import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum CommentType { text, media, gif, sticker }

class CommentReaction extends Equatable {
  final String userId;
  final String username;
  final String profileImageUrl;
  final String reaction; // 'like', 'love', 'laugh', 'wow', 'angry', 'sad'
  final DateTime createdAt;

  const CommentReaction({
    required this.userId,
    required this.username,
    required this.profileImageUrl,
    required this.reaction,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [userId, username, profileImageUrl, reaction, createdAt];

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'reaction': reaction,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory CommentReaction.fromJson(Map<String, dynamic> json) {
    return CommentReaction(
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      profileImageUrl: json['profileImageUrl'] ?? '',
      reaction: json['reaction'] ?? '',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }
}

class CommentMedia extends Equatable {
  final String id;
  final String url;
  final String? thumbnailUrl;
  final CommentType type;
  final Map<String, dynamic>? metadata;

  const CommentMedia({
    required this.id,
    required this.url,
    this.thumbnailUrl,
    required this.type,
    this.metadata,
  });

  @override
  List<Object?> get props => [id, url, thumbnailUrl, type, metadata];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'type': type.name,
      'metadata': metadata,
    };
  }

  factory CommentMedia.fromJson(Map<String, dynamic> json) {
    return CommentMedia(
      id: json['id'] ?? '',
      url: json['url'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      type: CommentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CommentType.text,
      ),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }
}

class CommentModel extends Equatable {
  final String id;
  final String postId;
  final String? parentCommentId; // for replies
  final String userId;
  final String username;
  final String userProfileImage;
  final bool isUserVerified;
  final String text;
  final List<String> mentions;
  final List<String> hashtags;
  final CommentMedia? media;
  final List<CommentReaction> reactions;
  final Map<String, int> reactionCounts;
  final List<String> likedBy;
  final int likesCount;
  final int repliesCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isEdited;
  final bool isDeleted;
  final bool isPinned;
  final bool isFromCreator; // if comment is from post creator
  final List<String> reportedBy;
  final String? translatedText;
  final String? originalLanguage;
  final Map<String, dynamic>? metadata;

  const CommentModel({
    required this.id,
    required this.postId,
    this.parentCommentId,
    required this.userId,
    required this.username,
    required this.userProfileImage,
    this.isUserVerified = false,
    required this.text,
    this.mentions = const [],
    this.hashtags = const [],
    this.media,
    this.reactions = const [],
    this.reactionCounts = const {},
    this.likedBy = const [],
    this.likesCount = 0,
    this.repliesCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.isEdited = false,
    this.isDeleted = false,
    this.isPinned = false,
    this.isFromCreator = false,
    this.reportedBy = const [],
    this.translatedText,
    this.originalLanguage,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        id, postId, parentCommentId, userId, username, userProfileImage,
        isUserVerified, text, mentions, hashtags, media, reactions,
        reactionCounts, likedBy, likesCount, repliesCount, createdAt,
        updatedAt, isEdited, isDeleted, isPinned, isFromCreator, reportedBy,
        translatedText, originalLanguage, metadata,
      ];

  CommentModel copyWith({
    String? id,
    String? postId,
    String? parentCommentId,
    String? userId,
    String? username,
    String? userProfileImage,
    bool? isUserVerified,
    String? text,
    List<String>? mentions,
    List<String>? hashtags,
    CommentMedia? media,
    List<CommentReaction>? reactions,
    Map<String, int>? reactionCounts,
    List<String>? likedBy,
    int? likesCount,
    int? repliesCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEdited,
    bool? isDeleted,
    bool? isPinned,
    bool? isFromCreator,
    List<String>? reportedBy,
    String? translatedText,
    String? originalLanguage,
    Map<String, dynamic>? metadata,
  }) {
    return CommentModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      isUserVerified: isUserVerified ?? this.isUserVerified,
      text: text ?? this.text,
      mentions: mentions ?? this.mentions,
      hashtags: hashtags ?? this.hashtags,
      media: media ?? this.media,
      reactions: reactions ?? this.reactions,
      reactionCounts: reactionCounts ?? this.reactionCounts,
      likedBy: likedBy ?? this.likedBy,
      likesCount: likesCount ?? this.likesCount,
      repliesCount: repliesCount ?? this.repliesCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      isPinned: isPinned ?? this.isPinned,
      isFromCreator: isFromCreator ?? this.isFromCreator,
      reportedBy: reportedBy ?? this.reportedBy,
      translatedText: translatedText ?? this.translatedText,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'parentCommentId': parentCommentId,
      'userId': userId,
      'username': username,
      'userProfileImage': userProfileImage,
      'isUserVerified': isUserVerified,
      'text': text,
      'mentions': mentions,
      'hashtags': hashtags,
      'media': media?.toJson(),
      'reactions': reactions.map((r) => r.toJson()).toList(),
      'reactionCounts': reactionCounts,
      'likedBy': likedBy,
      'likesCount': likesCount,
      'repliesCount': repliesCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'isPinned': isPinned,
      'isFromCreator': isFromCreator,
      'reportedBy': reportedBy,
      'translatedText': translatedText,
      'originalLanguage': originalLanguage,
      'metadata': metadata,
    };
  }

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? '',
      postId: json['postId'] ?? '',
      parentCommentId: json['parentCommentId'],
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      userProfileImage: json['userProfileImage'] ?? '',
      isUserVerified: json['isUserVerified'] ?? false,
      text: json['text'] ?? '',
      mentions: List<String>.from(json['mentions'] ?? []),
      hashtags: List<String>.from(json['hashtags'] ?? []),
      media: json['media'] != null ? CommentMedia.fromJson(json['media']) : null,
      reactions: (json['reactions'] as List<dynamic>?)
          ?.map((r) => CommentReaction.fromJson(r))
          .toList() ?? [],
      reactionCounts: Map<String, int>.from(json['reactionCounts'] ?? {}),
      likedBy: List<String>.from(json['likedBy'] ?? []),
      likesCount: json['likesCount'] ?? 0,
      repliesCount: json['repliesCount'] ?? 0,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
      isEdited: json['isEdited'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
      isPinned: json['isPinned'] ?? false,
      isFromCreator: json['isFromCreator'] ?? false,
      reportedBy: List<String>.from(json['reportedBy'] ?? []),
      translatedText: json['translatedText'],
      originalLanguage: json['originalLanguage'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel.fromJson(data);
  }

  // Helper methods
  bool get isReply => parentCommentId != null;
  bool get hasMedia => media != null;
  bool get hasMentions => mentions.isNotEmpty;
  bool get hasHashtags => hashtags.isNotEmpty;
  bool get hasReplies => repliesCount > 0;
  bool get hasReactions => reactions.isNotEmpty;
  bool isLikedBy(String userId) => likedBy.contains(userId);
  bool hasReactionBy(String userId) => reactions.any((r) => r.userId == userId);
  String? getReactionBy(String userId) => reactions
      .where((r) => r.userId == userId)
      .map((r) => r.reaction)
      .firstOrNull;

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 7) {
      return '${difference.inDays ~/ 7} أسبوع';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }

  String get likesText {
    if (likesCount == 0) return '';
    if (likesCount == 1) return 'إعجاب واحد';
    if (likesCount == 2) return 'إعجابان';
    if (likesCount < 11) return '$likesCount إعجابات';
    if (likesCount < 100) return '$likesCount إعجاباً';
    return '$likesCount إعجاب';
  }

  String get repliesText {
    if (repliesCount == 0) return '';
    if (repliesCount == 1) return 'رد واحد';
    if (repliesCount == 2) return 'ردان';
    if (repliesCount < 11) return '$repliesCount ردود';
    return '$repliesCount رد';
  }

  List<CommentReaction> getReactionsByType(String reactionType) =>
      reactions.where((r) => r.reaction == reactionType).toList();

  int getReactionCount(String reactionType) => reactionCounts[reactionType] ?? 0;

  String get displayText => isDeleted ? 'تم حذف هذا التعليق' : text;
}

extension CommentListExtensions on List<CommentModel> {
  List<CommentModel> get topLevelComments => 
      where((comment) => comment.parentCommentId == null).toList();
  
  List<CommentModel> getRepliesFor(String commentId) =>
      where((comment) => comment.parentCommentId == commentId).toList();
  
  List<CommentModel> get pinnedComments =>
      where((comment) => comment.isPinned).toList();
  
  List<CommentModel> get creatorComments =>
      where((comment) => comment.isFromCreator).toList();
}

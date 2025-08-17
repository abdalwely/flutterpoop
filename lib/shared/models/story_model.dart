import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum StoryType { image, video, text }
enum StoryVisibility { everyone, followers, close_friends, custom }

class StoryViewer extends Equatable {
  final String userId;
  final String username;
  final String profileImageUrl;
  final DateTime viewedAt;
  final bool isFollowing;

  const StoryViewer({
    required this.userId,
    required this.username,
    required this.profileImageUrl,
    required this.viewedAt,
    this.isFollowing = false,
  });

  @override
  List<Object?> get props => [userId, username, profileImageUrl, viewedAt, isFollowing];

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'viewedAt': Timestamp.fromDate(viewedAt),
      'isFollowing': isFollowing,
    };
  }

  factory StoryViewer.fromJson(Map<String, dynamic> json) {
    return StoryViewer(
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      profileImageUrl: json['profileImageUrl'] ?? '',
      viewedAt: (json['viewedAt'] as Timestamp).toDate(),
      isFollowing: json['isFollowing'] ?? false,
    );
  }
}

class StoryInteraction extends Equatable {
  final String userId;
  final String username;
  final String profileImageUrl;
  final String type; // 'like', 'reply', 'mention', 'share'
  final String? message; // for replies
  final DateTime createdAt;

  const StoryInteraction({
    required this.userId,
    required this.username,
    required this.profileImageUrl,
    required this.type,
    this.message,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [userId, username, profileImageUrl, type, message, createdAt];

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'type': type,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory StoryInteraction.fromJson(Map<String, dynamic> json) {
    return StoryInteraction(
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      profileImageUrl: json['profileImageUrl'] ?? '',
      type: json['type'] ?? '',
      message: json['message'],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }
}

class StoryModel extends Equatable {
  final String id;
  final String userId;
  final String username;
  final String userProfileImage;
  final bool isUserVerified;
  final StoryType type;
  final String mediaUrl;
  final String? thumbnailUrl;
  final String? text;
  final String? backgroundColor;
  final String? textColor;
  final String? fontFamily;
  final double? textSize;
  final Map<String, dynamic>? textPosition;
  final List<String> mentions;
  final List<String> hashtags;
  final StoryVisibility visibility;
  final List<String> allowedViewers; // for custom visibility
  final List<StoryViewer> viewers;
  final List<StoryInteraction> interactions;
  final int viewsCount;
  final int likesCount;
  final int repliesCount;
  final int sharesCount;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isArchived;
  final bool allowReplies;
  final bool allowSharing;
  final bool isHighlight;
  final String? highlightId;
  final Map<String, dynamic>? metadata;
  final List<String> reportedBy;

  const StoryModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.userProfileImage,
    this.isUserVerified = false,
    required this.type,
    required this.mediaUrl,
    this.thumbnailUrl,
    this.text,
    this.backgroundColor,
    this.textColor,
    this.fontFamily,
    this.textSize,
    this.textPosition,
    this.mentions = const [],
    this.hashtags = const [],
    this.visibility = StoryVisibility.everyone,
    this.allowedViewers = const [],
    this.viewers = const [],
    this.interactions = const [],
    this.viewsCount = 0,
    this.likesCount = 0,
    this.repliesCount = 0,
    this.sharesCount = 0,
    required this.createdAt,
    required this.expiresAt,
    this.isArchived = false,
    this.allowReplies = true,
    this.allowSharing = true,
    this.isHighlight = false,
    this.highlightId,
    this.metadata,
    this.reportedBy = const [],
  });

  @override
  List<Object?> get props => [
        id, userId, username, userProfileImage, isUserVerified, type, mediaUrl,
        thumbnailUrl, text, backgroundColor, textColor, fontFamily, textSize,
        textPosition, mentions, hashtags, visibility, allowedViewers, viewers,
        interactions, viewsCount, likesCount, repliesCount, sharesCount,
        createdAt, expiresAt, isArchived, allowReplies, allowSharing,
        isHighlight, highlightId, metadata, reportedBy,
      ];

  StoryModel copyWith({
    String? id,
    String? userId,
    String? username,
    String? userProfileImage,
    bool? isUserVerified,
    StoryType? type,
    String? mediaUrl,
    String? thumbnailUrl,
    String? text,
    String? backgroundColor,
    String? textColor,
    String? fontFamily,
    double? textSize,
    Map<String, dynamic>? textPosition,
    List<String>? mentions,
    List<String>? hashtags,
    StoryVisibility? visibility,
    List<String>? allowedViewers,
    List<StoryViewer>? viewers,
    List<StoryInteraction>? interactions,
    int? viewsCount,
    int? likesCount,
    int? repliesCount,
    int? sharesCount,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isArchived,
    bool? allowReplies,
    bool? allowSharing,
    bool? isHighlight,
    String? highlightId,
    Map<String, dynamic>? metadata,
    List<String>? reportedBy,
  }) {
    return StoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      isUserVerified: isUserVerified ?? this.isUserVerified,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      text: text ?? this.text,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      fontFamily: fontFamily ?? this.fontFamily,
      textSize: textSize ?? this.textSize,
      textPosition: textPosition ?? this.textPosition,
      mentions: mentions ?? this.mentions,
      hashtags: hashtags ?? this.hashtags,
      visibility: visibility ?? this.visibility,
      allowedViewers: allowedViewers ?? this.allowedViewers,
      viewers: viewers ?? this.viewers,
      interactions: interactions ?? this.interactions,
      viewsCount: viewsCount ?? this.viewsCount,
      likesCount: likesCount ?? this.likesCount,
      repliesCount: repliesCount ?? this.repliesCount,
      sharesCount: sharesCount ?? this.sharesCount,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isArchived: isArchived ?? this.isArchived,
      allowReplies: allowReplies ?? this.allowReplies,
      allowSharing: allowSharing ?? this.allowSharing,
      isHighlight: isHighlight ?? this.isHighlight,
      highlightId: highlightId ?? this.highlightId,
      metadata: metadata ?? this.metadata,
      reportedBy: reportedBy ?? this.reportedBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userProfileImage': userProfileImage,
      'isUserVerified': isUserVerified,
      'type': type.name,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'text': text,
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'fontFamily': fontFamily,
      'textSize': textSize,
      'textPosition': textPosition,
      'mentions': mentions,
      'hashtags': hashtags,
      'visibility': visibility.name,
      'allowedViewers': allowedViewers,
      'viewers': viewers.map((v) => v.toJson()).toList(),
      'interactions': interactions.map((i) => i.toJson()).toList(),
      'viewsCount': viewsCount,
      'likesCount': likesCount,
      'repliesCount': repliesCount,
      'sharesCount': sharesCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'isArchived': isArchived,
      'allowReplies': allowReplies,
      'allowSharing': allowSharing,
      'isHighlight': isHighlight,
      'highlightId': highlightId,
      'metadata': metadata,
      'reportedBy': reportedBy,
    };
  }

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      userProfileImage: json['userProfileImage'] ?? '',
      isUserVerified: json['isUserVerified'] ?? false,
      type: StoryType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => StoryType.image,
      ),
      mediaUrl: json['mediaUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      text: json['text'],
      backgroundColor: json['backgroundColor'],
      textColor: json['textColor'],
      fontFamily: json['fontFamily'],
      textSize: json['textSize']?.toDouble(),
      textPosition: json['textPosition'] != null
          ? Map<String, dynamic>.from(json['textPosition'])
          : null,
      mentions: List<String>.from(json['mentions'] ?? []),
      hashtags: List<String>.from(json['hashtags'] ?? []),
      visibility: StoryVisibility.values.firstWhere(
        (e) => e.name == json['visibility'],
        orElse: () => StoryVisibility.everyone,
      ),
      allowedViewers: List<String>.from(json['allowedViewers'] ?? []),
      viewers: (json['viewers'] as List<dynamic>?)
          ?.map((v) => StoryViewer.fromJson(v))
          .toList() ?? [],
      interactions: (json['interactions'] as List<dynamic>?)
          ?.map((i) => StoryInteraction.fromJson(i))
          .toList() ?? [],
      viewsCount: json['viewsCount'] ?? 0,
      likesCount: json['likesCount'] ?? 0,
      repliesCount: json['repliesCount'] ?? 0,
      sharesCount: json['sharesCount'] ?? 0,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      expiresAt: (json['expiresAt'] as Timestamp).toDate(),
      isArchived: json['isArchived'] ?? false,
      allowReplies: json['allowReplies'] ?? true,
      allowSharing: json['allowSharing'] ?? true,
      isHighlight: json['isHighlight'] ?? false,
      highlightId: json['highlightId'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      reportedBy: List<String>.from(json['reportedBy'] ?? []),
    );
  }

  factory StoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoryModel.fromJson(data);
  }

  // Helper methods
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isVideo => type == StoryType.video;
  bool get isText => type == StoryType.text;
  bool get hasText => text != null && text!.isNotEmpty;
  bool get hasMentions => mentions.isNotEmpty;
  bool get hasHashtags => hashtags.isNotEmpty;
  bool isViewedBy(String userId) => viewers.any((v) => v.userId == userId);
  bool isLikedBy(String userId) => interactions.any((i) => i.userId == userId && i.type == 'like');

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inHours > 0) {
      return '${difference.inHours}س';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}د';
    } else {
      return 'الآن';
    }
  }

  String get timeRemaining {
    final now = DateTime.now();
    final remaining = expiresAt.difference(now);
    
    if (remaining.inHours > 0) {
      return '${remaining.inHours}س';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}د';
    } else {
      return 'انتهت';
    }
  }

  String get viewsText {
    if (viewsCount == 0) return 'لا توجد مشاهدات';
    if (viewsCount == 1) return 'مشاهدة واحدة';
    if (viewsCount == 2) return 'مشاهدتان';
    if (viewsCount < 11) return '$viewsCount مشاهدات';
    if (viewsCount < 1000) return '$viewsCount مشاهدة';
    if (viewsCount < 1000000) {
      final k = (viewsCount / 1000).toStringAsFixed(1);
      return '${k}ألف مشاهدة';
    }
    final m = (viewsCount / 1000000).toStringAsFixed(1);
    return '${m}م مشاهدة';
  }

  List<StoryViewer> get recentViewers => viewers.take(3).toList();
  List<StoryInteraction> get recentInteractions => interactions.take(5).toList();
}

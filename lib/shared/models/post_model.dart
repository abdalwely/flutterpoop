import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum PostType { image, video, carousel }
enum PostVisibility { public, followers, close_friends, private }

class PostMedia extends Equatable {
  final String id;
  final String url;
  final String? thumbnailUrl;
  final PostType type;
  final double? aspectRatio;
  final int? duration; // for videos in seconds
  final Map<String, dynamic>? metadata;

  const PostMedia({
    required this.id,
    required this.url,
    this.thumbnailUrl,
    required this.type,
    this.aspectRatio,
    this.duration,
    this.metadata,
  });

  @override
  List<Object?> get props => [id, url, thumbnailUrl, type, aspectRatio, duration, metadata];

  PostMedia copyWith({
    String? id,
    String? url,
    String? thumbnailUrl,
    PostType? type,
    double? aspectRatio,
    int? duration,
    Map<String, dynamic>? metadata,
  }) {
    return PostMedia(
      id: id ?? this.id,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      type: type ?? this.type,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      duration: duration ?? this.duration,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'type': type.name,
      'aspectRatio': aspectRatio,
      'duration': duration,
      'metadata': metadata,
    };
  }

  factory PostMedia.fromJson(Map<String, dynamic> json) {
    return PostMedia(
      id: json['id'] ?? '',
      url: json['url'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      type: PostType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PostType.image,
      ),
      aspectRatio: json['aspectRatio']?.toDouble(),
      duration: json['duration'],
      metadata: json['metadata'] != null 
          ? Map<String, dynamic>.from(json['metadata']) 
          : null,
    );
  }
}

class PostLocation extends Equatable {
  final String id;
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? countryCode;
  final String? cityName;

  const PostLocation({
    required this.id,
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.countryCode,
    this.cityName,
  });

  @override
  List<Object?> get props => [id, name, address, latitude, longitude, countryCode, cityName];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'countryCode': countryCode,
      'cityName': cityName,
    };
  }

  factory PostLocation.fromJson(Map<String, dynamic> json) {
    return PostLocation(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      countryCode: json['countryCode'],
      cityName: json['cityName'],
    );
  }
}

class PostModel extends Equatable {
  final String id;
  final String userId;
  final String username;
  final String userProfileImage;
  final bool isUserVerified;
  final String caption;
  final List<PostMedia> media;
  final PostLocation? location;
  final List<String> hashtags;
  final List<String> mentions;
  final List<String> likedBy;
  final List<String> savedBy;
  final List<String> sharedBy;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int viewsCount;
  final PostVisibility visibility;
  final bool allowComments;
  final bool allowSharing;
  final bool hideLikesCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isSponsored;
  final Map<String, dynamic>? sponsorData;
  final bool isArchived;
  final bool isDeleted;
  final List<String> reportedBy;
  final Map<String, dynamic>? analytics;

  const PostModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.userProfileImage,
    this.isUserVerified = false,
    required this.caption,
    required this.media,
    this.location,
    this.hashtags = const [],
    this.mentions = const [],
    this.likedBy = const [],
    this.savedBy = const [],
    this.sharedBy = const [],
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.viewsCount = 0,
    this.visibility = PostVisibility.public,
    this.allowComments = true,
    this.allowSharing = true,
    this.hideLikesCount = false,
    required this.createdAt,
    this.updatedAt,
    this.isSponsored = false,
    this.sponsorData,
    this.isArchived = false,
    this.isDeleted = false,
    this.reportedBy = const [],
    this.analytics,
  });

  @override
  List<Object?> get props => [
        id, userId, username, userProfileImage, isUserVerified, caption, media,
        location, hashtags, mentions, likedBy, savedBy, sharedBy, likesCount,
        commentsCount, sharesCount, viewsCount, visibility, allowComments,
        allowSharing, hideLikesCount, createdAt, updatedAt, isSponsored,
        sponsorData, isArchived, isDeleted, reportedBy, analytics,
      ];

  PostModel copyWith({
    String? id,
    String? userId,
    String? username,
    String? userProfileImage,
    bool? isUserVerified,
    String? caption,
    List<PostMedia>? media,
    PostLocation? location,
    List<String>? hashtags,
    List<String>? mentions,
    List<String>? likedBy,
    List<String>? savedBy,
    List<String>? sharedBy,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    int? viewsCount,
    PostVisibility? visibility,
    bool? allowComments,
    bool? allowSharing,
    bool? hideLikesCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSponsored,
    Map<String, dynamic>? sponsorData,
    bool? isArchived,
    bool? isDeleted,
    List<String>? reportedBy,
    Map<String, dynamic>? analytics,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      isUserVerified: isUserVerified ?? this.isUserVerified,
      caption: caption ?? this.caption,
      media: media ?? this.media,
      location: location ?? this.location,
      hashtags: hashtags ?? this.hashtags,
      mentions: mentions ?? this.mentions,
      likedBy: likedBy ?? this.likedBy,
      savedBy: savedBy ?? this.savedBy,
      sharedBy: sharedBy ?? this.sharedBy,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      viewsCount: viewsCount ?? this.viewsCount,
      visibility: visibility ?? this.visibility,
      allowComments: allowComments ?? this.allowComments,
      allowSharing: allowSharing ?? this.allowSharing,
      hideLikesCount: hideLikesCount ?? this.hideLikesCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSponsored: isSponsored ?? this.isSponsored,
      sponsorData: sponsorData ?? this.sponsorData,
      isArchived: isArchived ?? this.isArchived,
      isDeleted: isDeleted ?? this.isDeleted,
      reportedBy: reportedBy ?? this.reportedBy,
      analytics: analytics ?? this.analytics,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userProfileImage': userProfileImage,
      'isUserVerified': isUserVerified,
      'caption': caption,
      'media': media.map((m) => m.toJson()).toList(),
      'location': location?.toJson(),
      'hashtags': hashtags,
      'mentions': mentions,
      'likedBy': likedBy,
      'savedBy': savedBy,
      'sharedBy': sharedBy,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'viewsCount': viewsCount,
      'visibility': visibility.name,
      'allowComments': allowComments,
      'allowSharing': allowSharing,
      'hideLikesCount': hideLikesCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isSponsored': isSponsored,
      'sponsorData': sponsorData,
      'isArchived': isArchived,
      'isDeleted': isDeleted,
      'reportedBy': reportedBy,
      'analytics': analytics,
    };
  }

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      userProfileImage: json['userProfileImage'] ?? '',
      isUserVerified: json['isUserVerified'] ?? false,
      caption: json['caption'] ?? '',
      media: (json['media'] as List<dynamic>?)
          ?.map((m) => PostMedia.fromJson(m))
          .toList() ?? [],
      location: json['location'] != null 
          ? PostLocation.fromJson(json['location']) 
          : null,
      hashtags: List<String>.from(json['hashtags'] ?? []),
      mentions: List<String>.from(json['mentions'] ?? []),
      likedBy: List<String>.from(json['likedBy'] ?? []),
      savedBy: List<String>.from(json['savedBy'] ?? []),
      sharedBy: List<String>.from(json['sharedBy'] ?? []),
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      sharesCount: json['sharesCount'] ?? 0,
      viewsCount: json['viewsCount'] ?? 0,
      visibility: PostVisibility.values.firstWhere(
        (e) => e.name == json['visibility'],
        orElse: () => PostVisibility.public,
      ),
      allowComments: json['allowComments'] ?? true,
      allowSharing: json['allowSharing'] ?? true,
      hideLikesCount: json['hideLikesCount'] ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null 
          ? (json['updatedAt'] as Timestamp).toDate() 
          : null,
      isSponsored: json['isSponsored'] ?? false,
      sponsorData: json['sponsorData'] != null 
          ? Map<String, dynamic>.from(json['sponsorData']) 
          : null,
      isArchived: json['isArchived'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
      reportedBy: List<String>.from(json['reportedBy'] ?? []),
      analytics: json['analytics'] != null 
          ? Map<String, dynamic>.from(json['analytics']) 
          : null,
    );
  }

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel.fromJson(data);
  }

  // Helper methods
  bool isLikedBy(String userId) => likedBy.contains(userId);
  bool isSavedBy(String userId) => savedBy.contains(userId);
  bool get isVideo => media.any((m) => m.type == PostType.video);
  bool get isCarousel => media.length > 1;
  bool get hasLocation => location != null;
  bool get hasHashtags => hashtags.isNotEmpty;
  bool get hasMentions => mentions.isNotEmpty;

  // Additional getters for compatibility
  String get profileImageUrl => userProfileImage;
  String get userProfilePicture => userProfileImage;
  bool get isVerified => isUserVerified;
  bool get userHasStory => false; // Default value, can be updated from user data

  // Getters for current user interaction state (you should replace 'current_user_id' with actual current user ID)
  bool get isLiked => likedBy.contains('current_user_id');
  bool get isSaved => savedBy.contains('current_user_id');
  String get imageUrl => media.isNotEmpty ? media.first.url : '';
  List<String> get mediaUrls => media.map((m) => m.url).toList();
  PostType get mediaType => media.isNotEmpty ? media.first.type : PostType.image;
  double get aspectRatio => media.isNotEmpty ? (media.first.aspectRatio ?? 1.0) : 1.0;
  String? get thumbnailUrl => media.isNotEmpty ? media.first.thumbnailUrl : null;
  
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
    if (likesCount < 1000) return '$likesCount إعجاب';
    if (likesCount < 1000000) {
      final k = (likesCount / 1000).toStringAsFixed(1);
      return '${k}ألف إعجاب';
    }
    final m = (likesCount / 1000000).toStringAsFixed(1);
    return '${m}م إعجاب';
  }

  String get commentsText {
    if (commentsCount == 0) return '';
    if (commentsCount == 1) return 'تعليق واحد';
    if (commentsCount == 2) return 'تعليقان';
    if (commentsCount < 11) return '$commentsCount تعليقات';
    return '$commentsCount تعليق';
  }

  String get viewsText {
    if (viewsCount == 0) return '';
    if (viewsCount < 1000) return '$viewsCount مشاهدة';
    if (viewsCount < 1000000) {
      final k = (viewsCount / 1000).toStringAsFixed(1);
      return '${k}ألف مشاهدة';
    }
    final m = (viewsCount / 1000000).toStringAsFixed(1);
    return '${m}م مشاهدة';
  }
}

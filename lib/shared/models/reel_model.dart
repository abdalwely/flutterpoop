import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum ReelVisibility { public, followers, private }
enum ReelDuration { fifteen, thirty, sixty, ninety }

class ReelEffect extends Equatable {
  final String id;
  final String name;
  final String? thumbnailUrl;
  final Map<String, dynamic>? parameters;

  const ReelEffect({
    required this.id,
    required this.name,
    this.thumbnailUrl,
    this.parameters,
  });

  @override
  List<Object?> get props => [id, name, thumbnailUrl, parameters];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'thumbnailUrl': thumbnailUrl,
      'parameters': parameters,
    };
  }

  factory ReelEffect.fromJson(Map<String, dynamic> json) {
    return ReelEffect(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      parameters: json['parameters'] != null
          ? Map<String, dynamic>.from(json['parameters'])
          : null,
    );
  }
}

class ReelAudio extends Equatable {
  final String id;
  final String name;
  final String artist;
  final String url;
  final String? coverImageUrl;
  final int duration;
  final bool isOriginal;
  final bool isTrending;

  const ReelAudio({
    required this.id,
    required this.name,
    required this.artist,
    required this.url,
    this.coverImageUrl,
    required this.duration,
    this.isOriginal = false,
    this.isTrending = false,
  });

  @override
  List<Object?> get props => [id, name, artist, url, coverImageUrl, duration, isOriginal, isTrending];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'artist': artist,
      'url': url,
      'coverImageUrl': coverImageUrl,
      'duration': duration,
      'isOriginal': isOriginal,
      'isTrending': isTrending,
    };
  }

  factory ReelAudio.fromJson(Map<String, dynamic> json) {
    return ReelAudio(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      artist: json['artist'] ?? '',
      url: json['url'] ?? '',
      coverImageUrl: json['coverImageUrl'],
      duration: json['duration'] ?? 0,
      isOriginal: json['isOriginal'] ?? false,
      isTrending: json['isTrending'] ?? false,
    );
  }
}

class ReelModel extends Equatable {
  final String id;
  final String userId;
  final String username;
  final String userProfileImage;
  final bool isUserVerified;
  final String videoUrl;
  final String thumbnailUrl;
  final String caption;
  final List<String> hashtags;
  final List<String> mentions;
  final ReelAudio? audio;
  final List<ReelEffect> effects;
  final ReelVisibility visibility;
  final List<String> likedBy;
  final List<String> savedBy;
  final List<String> sharedBy;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int viewsCount;
  final int duration; // in seconds
  final bool allowComments;
  final bool allowDuets;
  final bool allowRemix;
  final bool isSponsored;
  final Map<String, dynamic>? sponsorData;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isArchived;
  final bool isDeleted;
  final List<String> reportedBy;
  final Map<String, dynamic>? analytics;
  final bool isFeatured;
  final bool isTrending;
  final double? aspectRatio;
  final Map<String, dynamic>? videoMetadata;

  const ReelModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.userProfileImage,
    this.isUserVerified = false,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.caption,
    this.hashtags = const [],
    this.mentions = const [],
    this.audio,
    this.effects = const [],
    this.visibility = ReelVisibility.public,
    this.likedBy = const [],
    this.savedBy = const [],
    this.sharedBy = const [],
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.viewsCount = 0,
    required this.duration,
    this.allowComments = true,
    this.allowDuets = true,
    this.allowRemix = true,
    this.isSponsored = false,
    this.sponsorData,
    required this.createdAt,
    this.updatedAt,
    this.isArchived = false,
    this.isDeleted = false,
    this.reportedBy = const [],
    this.analytics,
    this.isFeatured = false,
    this.isTrending = false,
    this.aspectRatio,
    this.videoMetadata,
  });

  @override
  List<Object?> get props => [
        id, userId, username, userProfileImage, isUserVerified, videoUrl,
        thumbnailUrl, caption, hashtags, mentions, audio, effects, visibility,
        likedBy, savedBy, sharedBy, likesCount, commentsCount, sharesCount,
        viewsCount, duration, allowComments, allowDuets, allowRemix, isSponsored,
        sponsorData, createdAt, updatedAt, isArchived, isDeleted, reportedBy,
        analytics, isFeatured, isTrending, aspectRatio, videoMetadata,
      ];

  ReelModel copyWith({
    String? id,
    String? userId,
    String? username,
    String? userProfileImage,
    bool? isUserVerified,
    String? videoUrl,
    String? thumbnailUrl,
    String? caption,
    List<String>? hashtags,
    List<String>? mentions,
    ReelAudio? audio,
    List<ReelEffect>? effects,
    ReelVisibility? visibility,
    List<String>? likedBy,
    List<String>? savedBy,
    List<String>? sharedBy,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    int? viewsCount,
    int? duration,
    bool? allowComments,
    bool? allowDuets,
    bool? allowRemix,
    bool? isSponsored,
    Map<String, dynamic>? sponsorData,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
    bool? isDeleted,
    List<String>? reportedBy,
    Map<String, dynamic>? analytics,
    bool? isFeatured,
    bool? isTrending,
    double? aspectRatio,
    Map<String, dynamic>? videoMetadata,
  }) {
    return ReelModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      isUserVerified: isUserVerified ?? this.isUserVerified,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      hashtags: hashtags ?? this.hashtags,
      mentions: mentions ?? this.mentions,
      audio: audio ?? this.audio,
      effects: effects ?? this.effects,
      visibility: visibility ?? this.visibility,
      likedBy: likedBy ?? this.likedBy,
      savedBy: savedBy ?? this.savedBy,
      sharedBy: sharedBy ?? this.sharedBy,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      viewsCount: viewsCount ?? this.viewsCount,
      duration: duration ?? this.duration,
      allowComments: allowComments ?? this.allowComments,
      allowDuets: allowDuets ?? this.allowDuets,
      allowRemix: allowRemix ?? this.allowRemix,
      isSponsored: isSponsored ?? this.isSponsored,
      sponsorData: sponsorData ?? this.sponsorData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
      isDeleted: isDeleted ?? this.isDeleted,
      reportedBy: reportedBy ?? this.reportedBy,
      analytics: analytics ?? this.analytics,
      isFeatured: isFeatured ?? this.isFeatured,
      isTrending: isTrending ?? this.isTrending,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      videoMetadata: videoMetadata ?? this.videoMetadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userProfileImage': userProfileImage,
      'isUserVerified': isUserVerified,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'caption': caption,
      'hashtags': hashtags,
      'mentions': mentions,
      'audio': audio?.toJson(),
      'effects': effects.map((e) => e.toJson()).toList(),
      'visibility': visibility.name,
      'likedBy': likedBy,
      'savedBy': savedBy,
      'sharedBy': sharedBy,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'viewsCount': viewsCount,
      'duration': duration,
      'allowComments': allowComments,
      'allowDuets': allowDuets,
      'allowRemix': allowRemix,
      'isSponsored': isSponsored,
      'sponsorData': sponsorData,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isArchived': isArchived,
      'isDeleted': isDeleted,
      'reportedBy': reportedBy,
      'analytics': analytics,
      'isFeatured': isFeatured,
      'isTrending': isTrending,
      'aspectRatio': aspectRatio,
      'videoMetadata': videoMetadata,
    };
  }

  factory ReelModel.fromJson(Map<String, dynamic> json) {
    return ReelModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      userProfileImage: json['userProfileImage'] ?? '',
      isUserVerified: json['isUserVerified'] ?? false,
      videoUrl: json['videoUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      caption: json['caption'] ?? '',
      hashtags: List<String>.from(json['hashtags'] ?? []),
      mentions: List<String>.from(json['mentions'] ?? []),
      audio: json['audio'] != null ? ReelAudio.fromJson(json['audio']) : null,
      effects: (json['effects'] as List<dynamic>?)
          ?.map((e) => ReelEffect.fromJson(e))
          .toList() ?? [],
      visibility: ReelVisibility.values.firstWhere(
        (e) => e.name == json['visibility'],
        orElse: () => ReelVisibility.public,
      ),
      likedBy: List<String>.from(json['likedBy'] ?? []),
      savedBy: List<String>.from(json['savedBy'] ?? []),
      sharedBy: List<String>.from(json['sharedBy'] ?? []),
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      sharesCount: json['sharesCount'] ?? 0,
      viewsCount: json['viewsCount'] ?? 0,
      duration: json['duration'] ?? 0,
      allowComments: json['allowComments'] ?? true,
      allowDuets: json['allowDuets'] ?? true,
      allowRemix: json['allowRemix'] ?? true,
      isSponsored: json['isSponsored'] ?? false,
      sponsorData: json['sponsorData'] != null
          ? Map<String, dynamic>.from(json['sponsorData'])
          : null,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
      isArchived: json['isArchived'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
      reportedBy: List<String>.from(json['reportedBy'] ?? []),
      analytics: json['analytics'] != null
          ? Map<String, dynamic>.from(json['analytics'])
          : null,
      isFeatured: json['isFeatured'] ?? false,
      isTrending: json['isTrending'] ?? false,
      aspectRatio: json['aspectRatio']?.toDouble(),
      videoMetadata: json['videoMetadata'] != null
          ? Map<String, dynamic>.from(json['videoMetadata'])
          : null,
    );
  }

  factory ReelModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReelModel.fromJson(data);
  }

  // Helper methods
  bool isLikedBy(String userId) => likedBy.contains(userId);
  bool isSavedBy(String userId) => savedBy.contains(userId);
  bool hasAudio => audio != null;
  bool hasEffects => effects.isNotEmpty;
  bool hasHashtags => hashtags.isNotEmpty;
  bool hasMentions => mentions.isNotEmpty;

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

  String get durationText {
    if (duration < 60) {
      return '${duration}ث';
    } else {
      final minutes = duration ~/ 60;
      final seconds = duration % 60;
      return '${minutes}:${seconds.toString().padLeft(2, '0')}';
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

  String get viewsText {
    if (viewsCount < 1000) return '$viewsCount مشاهدة';
    if (viewsCount < 1000000) {
      final k = (viewsCount / 1000).toStringAsFixed(1);
      return '${k}ألف مشاهدة';
    }
    final m = (viewsCount / 1000000).toStringAsFixed(1);
    return '${m}م مشاهدة';
  }

  String get commentsText {
    if (commentsCount == 0) return '';
    if (commentsCount == 1) return 'تعليق واحد';
    if (commentsCount == 2) return 'تعليقان';
    if (commentsCount < 11) return '$commentsCount تعليقات';
    return '$commentsCount تعليق';
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String uid;
  final String email;
  final String username;
  final String fullName;
  final String profileImageUrl;
  final String bio;
  final List<String> followers;
  final List<String> following;
  final int postsCount;
  final int followersCount;
  final int followingCount;
  final bool isVerified;
  final bool isPrivate;
  final DateTime createdAt;
  final DateTime? lastSeen;
  final bool isOnline;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? website;
  final String? location;

  const UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.fullName,
    required this.profileImageUrl,
    required this.bio,
    required this.followers,
    required this.following,
    required this.postsCount,
    required this.followersCount,
    required this.followingCount,
    required this.isVerified,
    required this.isPrivate,
    required this.createdAt,
    this.lastSeen,
    this.isOnline = false,
    this.phoneNumber,
    this.dateOfBirth,
    this.website,
    this.location,
  });

  @override
  List<Object?> get props => [
        uid,
        email,
        username,
        fullName,
        profileImageUrl,
        bio,
        followers,
        following,
        postsCount,
        followersCount,
        followingCount,
        isVerified,
        isPrivate,
        createdAt,
        lastSeen,
        isOnline,
        phoneNumber,
        dateOfBirth,
        website,
        location,
      ];

  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    String? fullName,
    String? profileImageUrl,
    String? bio,
    List<String>? followers,
    List<String>? following,
    int? postsCount,
    int? followersCount,
    int? followingCount,
    bool? isVerified,
    bool? isPrivate,
    DateTime? createdAt,
    DateTime? lastSeen,
    bool? isOnline,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? website,
    String? location,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      postsCount: postsCount ?? this.postsCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      isVerified: isVerified ?? this.isVerified,
      isPrivate: isPrivate ?? this.isPrivate,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      website: website ?? this.website,
      location: location ?? this.location,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'fullName': fullName,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'followers': followers,
      'following': following,
      'postsCount': postsCount,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'isVerified': isVerified,
      'isPrivate': isPrivate,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'isOnline': isOnline,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'website': website,
      'location': location,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '',
      profileImageUrl: json['profileImageUrl'] ?? '',
      bio: json['bio'] ?? '',
      followers: List<String>.from(json['followers'] ?? []),
      following: List<String>.from(json['following'] ?? []),
      postsCount: json['postsCount'] ?? 0,
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      isVerified: json['isVerified'] ?? false,
      isPrivate: json['isPrivate'] ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      lastSeen: json['lastSeen'] != null 
          ? (json['lastSeen'] as Timestamp).toDate() 
          : null,
      isOnline: json['isOnline'] ?? false,
      phoneNumber: json['phoneNumber'],
      dateOfBirth: json['dateOfBirth'] != null 
          ? (json['dateOfBirth'] as Timestamp).toDate() 
          : null,
      website: json['website'],
      location: json['location'],
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  String get profilePicture => profileImageUrl;

  // Getter للحفاظ على التوافق مع المرجع القديم "id" بدلاً من "uid"
  String get id => uid;

  bool get hasProfileImage => profileImageUrl.isNotEmpty;
  bool get hasBio => bio.isNotEmpty;
  bool get hasWebsite => website != null && website!.isNotEmpty;
  bool get hasLocation => location != null && location!.isNotEmpty;
  bool get hasPhoneNumber => phoneNumber != null && phoneNumber!.isNotEmpty;
  
  String get displayName => fullName.isNotEmpty ? fullName : username;
  
  bool isFollowing(String userId) => following.contains(userId);
  bool isFollowedBy(String userId) => followers.contains(userId);
  
  String get followerText {
    if (followersCount == 0) return 'لا يوجد متابعون';
    if (followersCount == 1) return 'متابع واحد';
    if (followersCount == 2) return 'متابعان';
    if (followersCount < 11) return '$followersCount متابعين';
    if (followersCount < 100) return '$followersCount متابعاً';
    if (followersCount < 1000) return '$followersCount متابع';
    if (followersCount < 1000000) {
      final k = (followersCount / 1000).toStringAsFixed(1);
      return '${k}ألف متابع';
    }
    final m = (followersCount / 1000000).toStringAsFixed(1);
    return '${m}م متابع';
  }
  
  String get followingText {
    if (followingCount == 0) return 'لا يتابع أحداً';
    if (followingCount == 1) return 'يتابع شخصاً واحداً';
    if (followingCount == 2) return 'يتابع شخصين';
    if (followingCount < 11) return 'يتابع $followingCount أشخاص';
    if (followingCount < 100) return 'يتابع $followingCount شخصاً';
    if (followingCount < 1000) return 'يتابع $followingCount شخص';
    if (followingCount < 1000000) {
      final k = (followingCount / 1000).toStringAsFixed(1);
      return 'يتابع ${k}ألف شخص';
    }
    final m = (followingCount / 1000000).toStringAsFixed(1);
    return 'يتابع ${m}م شخص';
  }
  
  String get postsText {
    if (postsCount == 0) return 'لا توجد منشورات';
    if (postsCount == 1) return 'منشور واحد';
    if (postsCount == 2) return 'منشوران';
    if (postsCount < 11) return '$postsCount منشورات';
    if (postsCount < 100) return '$postsCount منشوراً';
    if (postsCount < 1000) return '$postsCount منشور';
    if (postsCount < 1000000) {
      final k = (postsCount / 1000).toStringAsFixed(1);
      return '${k}ألف منشور';
    }
    final m = (postsCount / 1000000).toStringAsFixed(1);
    return '${m}م منشور';
  }
}

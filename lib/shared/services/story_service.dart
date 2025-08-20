import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import '../../core/constants/app_constants.dart';
import '../models/story_model.dart';
import '../models/user_model.dart';

class StoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Stories Collection Reference
  CollectionReference get _storiesCollection =>
      _firestore.collection(AppConstants.storiesCollection);

  // Users Collection Reference
  CollectionReference get _usersCollection =>
      _firestore.collection(AppConstants.usersCollection);

  // Create Story
  Future<String> createStory({
    required String userId,
    required StoryType type,
    File? mediaFile,
    String? text,
    String? backgroundColor,
    String? textColor,
    String? fontFamily,
    double? textSize,
    Map<String, dynamic>? textPosition,
    List<String>? mentions,
    List<String>? hashtags,
    StoryVisibility visibility = StoryVisibility.everyone,
    List<String>? allowedViewers,
    bool allowReplies = true,
    bool allowSharing = true,
  }) async {
    try {
      // Get user data
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = UserModel.fromFirestore(userDoc);

      String mediaUrl = '';
      String? thumbnailUrl;

      // Upload media if provided
      if (mediaFile != null) {
        final storyId = '${userId}_${DateTime.now().millisecondsSinceEpoch}';
        final extension = mediaFile.path.split('.').last.toLowerCase();
        
        // Determine storage path
        final isVideo = ['mp4', 'mov', 'avi', 'mkv'].contains(extension);
        final storagePath = isVideo 
            ? AppConstants.storyVideosPath 
            : AppConstants.storyImagesPath;
        
        // Upload to Firebase Storage
        final storageRef = _storage.ref()
            .child(storagePath)
            .child('$storyId.$extension');
        
        final uploadTask = await storageRef.putFile(mediaFile);
        mediaUrl = await uploadTask.ref.getDownloadURL();
        
        // Generate thumbnail for videos
        if (isVideo) {
          // Here you would generate video thumbnail
          // For now, we'll use the video URL as placeholder
          thumbnailUrl = mediaUrl;
        }
      }

      // Create story document
      final storyId = _storiesCollection.doc().id;
      final expiresAt = DateTime.now().add(const Duration(hours: 24));
      
      final story = StoryModel(
        id: storyId,
        userId: userId,
        username: userData.username,
        userProfileImage: userData.profileImageUrl,
        isUserVerified: userData.isVerified,
        type: type,
        mediaUrl: mediaUrl,
        thumbnailUrl: thumbnailUrl,
        text: text,
        backgroundColor: backgroundColor,
        textColor: textColor,
        fontFamily: fontFamily,
        textSize: textSize,
        textPosition: textPosition,
        mentions: mentions ?? [],
        hashtags: hashtags ?? [],
        visibility: visibility,
        allowedViewers: allowedViewers ?? [],
        allowReplies: allowReplies,
        allowSharing: allowSharing,
        createdAt: DateTime.now(),
        expiresAt: expiresAt,
      );

      // Save to Firestore
      await _storiesCollection.doc(storyId).set(story.toJson());

      return storyId;
    } catch (e) {
      throw Exception('خطأ في إنشاء القصة: $e');
    }
  }

  // Get Stories Feed (Following users)
  Future<Map<String, List<StoryModel>>> getStoriesFeed(String userId) async {
    try {
      // Get user's following list
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = UserModel.fromFirestore(userDoc);
      final followingList = [...userData.following, userId]; // Include own stories

      // Get active stories from following users
      final now = DateTime.now();
      final stories = <String, List<StoryModel>>{};

      for (final followedUserId in followingList) {
        final userStories = await _getUserActiveStories(followedUserId, now);
        if (userStories.isNotEmpty) {
          stories[followedUserId] = userStories;
        }
      }

      return stories;
    } catch (e) {
      throw Exception('خطأ في جلب القصص: $e');
    }
  }

  // Get User Stories
  Future<List<StoryModel>> getUserStories({
    required String userId,
    bool includeExpired = false,
  }) async {
    try {
      Query query = _storiesCollection
          .where('userId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true);

      if (!includeExpired) {
        query = query.where('expiresAt', isGreaterThan: Timestamp.now());
      }

      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => StoryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('خطأ في جلب قصص المستخدم: $e');
    }
  }

  // View Story
  Future<void> viewStory(String storyId, String viewerId) async {
    try {
      final storyDoc = await _storiesCollection.doc(storyId).get();
      if (!storyDoc.exists) return;

      final story = StoryModel.fromFirestore(storyDoc);
      
      // Don't track views for own stories
      if (story.userId == viewerId) return;

      // Check if already viewed
      if (story.isViewedBy(viewerId)) return;

      // Get viewer data
      final viewerDoc = await _usersCollection.doc(viewerId).get();
      final viewerData = UserModel.fromFirestore(viewerDoc);

      // Create viewer object
      final viewer = StoryViewer(
        userId: viewerId,
        username: viewerData.username,
        profileImageUrl: viewerData.profileImageUrl,
        viewedAt: DateTime.now(),
        isFollowing: viewerData.following.contains(story.userId),
      );

      // Update story with new viewer
      await _storiesCollection.doc(storyId).update({
        'viewers': FieldValue.arrayUnion([viewer.toJson()]),
        'viewsCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('خطأ في مشاهدة القصة: $e');
    }
  }

  // Like Story
  Future<void> likeStory(String storyId, String userId) async {
    try {
      // Get user data
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = UserModel.fromFirestore(userDoc);

      final interaction = StoryInteraction(
        userId: userId,
        username: userData.username,
        profileImageUrl: userData.profileImageUrl,
        type: 'like',
        createdAt: DateTime.now(),
      );

      // Remove existing like if any
      await _removeStoryInteraction(storyId, userId, 'like');

      // Add new like
      await _storiesCollection.doc(storyId).update({
        'interactions': FieldValue.arrayUnion([interaction.toJson()]),
        'likesCount': FieldValue.increment(1),
      });

      // Create notification
      await _createStoryNotification(storyId, userId, 'like');
    } catch (e) {
      throw Exception('خطأ في الإعجاب بالقصة: $e');
    }
  }

  // Reply to Story
  Future<void> replyToStory({
    required String storyId,
    required String userId,
    required String message,
  }) async {
    try {
      // Get user data
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = UserModel.fromFirestore(userDoc);

      final interaction = StoryInteraction(
        userId: userId,
        username: userData.username,
        profileImageUrl: userData.profileImageUrl,
        type: 'reply',
        message: message,
        createdAt: DateTime.now(),
      );

      // Add reply
      await _storiesCollection.doc(storyId).update({
        'interactions': FieldValue.arrayUnion([interaction.toJson()]),
        'repliesCount': FieldValue.increment(1),
      });

      // Create notification
      await _createStoryNotification(storyId, userId, 'reply', message);
    } catch (e) {
      throw Exception('خطأ في الرد على القصة: $e');
    }
  }

  // Share Story
  Future<void> shareStory(String storyId, String userId) async {
    try {
      await _storiesCollection.doc(storyId).update({
        'sharesCount': FieldValue.increment(1),
      });

      // Create notification
      await _createStoryNotification(storyId, userId, 'share');
    } catch (e) {
      throw Exception('خطأ في مشاركة القصة: $e');
    }
  }

  // Archive Story
  Future<void> archiveStory(String storyId) async {
    try {
      await _storiesCollection.doc(storyId).update({
        'isArchived': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('خطأ في أرشفة القصة: $e');
    }
  }

  // Delete Story
  Future<void> deleteStory(String storyId, String userId) async {
    try {
      final storyDoc = await _storiesCollection.doc(storyId).get();
      if (!storyDoc.exists) return;

      final story = StoryModel.fromFirestore(storyDoc);
      
      // Check ownership
      if (story.userId != userId) {
        throw Exception('ليس لديك صلاحية لحذف هذه القصة');
      }

      // Soft delete
      await _storiesCollection.doc(storyId).update({
        'isDeleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Delete media from storage
      if (story.mediaUrl.isNotEmpty) {
        try {
          final ref = _storage.refFromURL(story.mediaUrl);
          await ref.delete();
        } catch (e) {
          // Log error but don't throw
          print('Error deleting story media: $e');
        }
      }
    } catch (e) {
      throw Exception('خطأ في حذف القصة: $e');
    }
  }

  // Add to Highlights
  Future<void> addToHighlights({
    required String storyId,
    required String highlightId,
  }) async {
    try {
      await _storiesCollection.doc(storyId).update({
        'isHighlight': true,
        'highlightId': highlightId,
      });
    } catch (e) {
      throw Exception('خطأ في إضافة إلى المميزة: $e');
    }
  }

  // Remove from Highlights
  Future<void> removeFromHighlights(String storyId) async {
    try {
      await _storiesCollection.doc(storyId).update({
        'isHighlight': false,
        'highlightId': FieldValue.delete(),
      });
    } catch (e) {
      throw Exception('خطأ في إزالة من المميزة: $e');
    }
  }

  // Get Story Analytics
  Future<Map<String, dynamic>> getStoryAnalytics(String storyId) async {
    try {
      final doc = await _storiesCollection.doc(storyId).get();
      if (!doc.exists) throw Exception('القصة غير موجودة');
      
      final story = StoryModel.fromFirestore(doc);
      
      return {
        'views': story.viewsCount,
        'likes': story.likesCount,
        'replies': story.repliesCount,
        'shares': story.sharesCount,
        'reach': story.viewers.length,
        'profile_visits': story.viewers.where((v) => !v.isFollowing).length,
        'new_followers': story.viewers.where((v) => !v.isFollowing).length,
        'top_viewers': story.viewers.take(10).toList(),
        'engagement_rate': _calculateStoryEngagementRate(story),
      };
    } catch (e) {
      throw Exception('خطأ في جلب إحصائيات القصة: $e');
    }
  }

  // Get Expired Stories for Cleanup
  Future<List<String>> getExpiredStories() async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _storiesCollection
          .where('expiresAt', isLessThan: Timestamp.fromDate(now))
          .where('isArchived', isEqualTo: false)
          .where('isHighlight', isEqualTo: false)
          .get();

      return querySnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      throw Exception('خطأ في جلب القصص المنتهية الصلاحية: $e');
    }
  }

  // Clean Up Expired Stories
  Future<void> cleanupExpiredStories() async {
    try {
      final expiredStoryIds = await getExpiredStories();
      final batch = _firestore.batch();

      for (final storyId in expiredStoryIds) {
        batch.update(_storiesCollection.doc(storyId), {
          'isDeleted': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('خطأ في تنظيف القصص المنتهية: $e');
    }
  }

  // Helper Methods
  Future<List<StoryModel>> _getUserActiveStories(String userId, DateTime now) async {
    try {
      final querySnapshot = await _storiesCollection
          .where('userId', isEqualTo: userId)
          .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
          .where('isDeleted', isEqualTo: false)
          .orderBy('expiresAt')
          .orderBy('createdAt')
          .get();

      return querySnapshot.docs
          .map((doc) => StoryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _removeStoryInteraction(String storyId, String userId, String type) async {
    try {
      final storyDoc = await _storiesCollection.doc(storyId).get();
      if (!storyDoc.exists) return;

      final story = StoryModel.fromFirestore(storyDoc);
      final existingInteraction = story.interactions
          .where((i) => i.userId == userId && i.type == type)
          .firstOrNull;

      if (existingInteraction != null) {
        await _storiesCollection.doc(storyId).update({
          'interactions': FieldValue.arrayRemove([existingInteraction.toJson()]),
          '${type}sCount': FieldValue.increment(-1),
        });
      }
    } catch (e) {
      // Log error but don't throw
      print('Error removing story interaction: $e');
    }
  }

  Future<void> _createStoryNotification(String storyId, String fromUserId, String type, [String? message]) async {
    try {
      final storyDoc = await _storiesCollection.doc(storyId).get();
      if (!storyDoc.exists) return;

      final story = StoryModel.fromFirestore(storyDoc);
      if (story.userId == fromUserId) return; // Don't notify self

      final notificationData = {
        'type': 'story_$type',
        'fromUserId': fromUserId,
        'toUserId': story.userId,
        'storyId': storyId,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      if (message != null) {
        notificationData['message'] = message;
      }

      await _firestore
          .collection(AppConstants.notificationsCollection)
          .add(notificationData);
    } catch (e) {
      // Log error but don't throw
      print('Error creating story notification: $e');
    }
  }

  double _calculateStoryEngagementRate(StoryModel story) {
    final totalEngagements = story.likesCount + story.repliesCount + story.sharesCount;
    final reach = story.viewsCount > 0 ? story.viewsCount : 1;
    return (totalEngagements / reach) * 100;
  }

  // Stream for real-time story updates
  Stream<List<StoryModel>> getUserStoriesStream(String userId) {
    return _storiesCollection
        .where('userId', isEqualTo: userId)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .where('isDeleted', isEqualTo: false)
        .orderBy('expiresAt')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StoryModel.fromFirestore(doc))
            .toList());
  }

  Stream<StoryModel?> getStoryStream(String storyId) {
    return _storiesCollection.doc(storyId).snapshots().map((doc) {
      if (doc.exists) {
        return StoryModel.fromFirestore(doc);
      }
      return null;
    });
  }
}

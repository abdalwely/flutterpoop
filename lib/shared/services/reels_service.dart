import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../models/reel_model.dart';
import '../models/user_model.dart';

class ReelsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const Uuid _uuid = Uuid();

  // Create a new reel
  static Future<String?> createReel({
    required File videoFile,
    required File thumbnailFile,
    required String caption,
    List<String> hashtags = const [],
    List<String> mentions = const [],
    ReelAudio? audio,
    List<ReelEffect> effects = const [],
    ReelVisibility visibility = ReelVisibility.public,
    bool allowComments = true,
    bool allowDuets = true,
    bool allowRemix = true,
    Map<String, dynamic>? videoMetadata,
  }) async {
    try {
      final String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Get user data
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (!userDoc.exists) throw Exception('User not found');

      final userData = userDoc.data()!;
      final userModel = UserModel.fromJson(userData);

      // Generate reel ID
      final String reelId = _uuid.v4();

      // Upload video
      final videoRef = _storage.ref().child('reels/$reelId/video.mp4');
      final videoUploadTask = await videoRef.putFile(videoFile);
      final videoUrl = await videoUploadTask.ref.getDownloadURL();

      // Upload thumbnail
      final thumbnailRef = _storage.ref().child('reels/$reelId/thumbnail.jpg');
      final thumbnailUploadTask = await thumbnailRef.putFile(thumbnailFile);
      final thumbnailUrl = await thumbnailUploadTask.ref.getDownloadURL();

      // Extract video duration from metadata
      final duration = videoMetadata?['duration'] ?? 30;

      // Create reel model
      final reel = ReelModel(
        id: reelId,
        userId: currentUserId,
        username: userModel.username,
        userProfileImage: userModel.profileImageUrl,
        isUserVerified: userModel.isVerified,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        caption: caption,
        hashtags: hashtags,
        mentions: mentions,
        audio: audio,
        effects: effects,
        visibility: visibility,
        duration: duration,
        allowComments: allowComments,
        allowDuets: allowDuets,
        allowRemix: allowRemix,
        createdAt: DateTime.now(),
        aspectRatio: videoMetadata?['aspectRatio'],
        videoMetadata: videoMetadata,
      );

      // Save to Firestore
      await _firestore.collection('reels').doc(reelId).set(reel.toJson());

      // Update user's posts count
      await _firestore.collection('users').doc(currentUserId).update({
        'postsCount': FieldValue.increment(1),
        'lastPostAt': FieldValue.serverTimestamp(),
      });

      // Add to user's reels subcollection
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('reels')
          .doc(reelId)
          .set({
        'reelId': reelId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Send notifications to mentions
      for (final mention in mentions) {
        await _sendMentionNotification(mention, currentUserId, reelId);
      }

      return reelId;
    } catch (e) {
      print('Error creating reel: $e');
      return null;
    }
  }

  // Get trending reels
  static Future<List<ReelModel>> getTrendingReels({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('reels')
          .where('isDeleted', isEqualTo: false)
          .where('isArchived', isEqualTo: false)
          .where('isTrending', isEqualTo: true)
          .orderBy('viewsCount', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => ReelModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting trending reels: $e');
      return [];
    }
  }

  // Get reels by user
  static Future<List<ReelModel>> getUserReels(
    String userId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('reels')
          .where('userId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: false)
          .where('isArchived', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => ReelModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting user reels: $e');
      return [];
    }
  }

  // Get feed reels (following + discover)
  static Future<List<ReelModel>> getFeedReels({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      final String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return [];

      // Get user's following list
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      final List<String> following = userDoc.exists 
          ? List<String>.from(userDoc.data()!['following'] ?? [])
          : [];

      List<ReelModel> feedReels = [];

      if (following.isNotEmpty) {
        // Get reels from followed users
        Query followingQuery = _firestore
            .collection('reels')
            .where('userId', whereIn: following.take(10).toList())
            .where('isDeleted', isEqualTo: false)
            .orderBy('createdAt', descending: true)
            .limit(limit ~/ 2);

        if (startAfter != null) {
          followingQuery = followingQuery.startAfterDocument(startAfter);
        }

        final followingSnapshot = await followingQuery.get();
        feedReels.addAll(
          followingSnapshot.docs.map((doc) => ReelModel.fromFirestore(doc))
        );
      }

      // Get discover reels (trending/popular)
      final remainingLimit = limit - feedReels.length;
      if (remainingLimit > 0) {
        Query discoverQuery = _firestore
            .collection('reels')
            .where('isDeleted', isEqualTo: false)
            .where('isArchived', isEqualTo: false)
            .orderBy('viewsCount', descending: true)
            .limit(remainingLimit);

        final discoverSnapshot = await discoverQuery.get();
        final discoverReels = discoverSnapshot.docs
            .map((doc) => ReelModel.fromFirestore(doc))
            .where((reel) => !feedReels.any((fr) => fr.id == reel.id))
            .toList();

        feedReels.addAll(discoverReels);
      }

      // Shuffle for better variety
      feedReels.shuffle();
      return feedReels.take(limit).toList();
    } catch (e) {
      print('Error getting feed reels: $e');
      return [];
    }
  }

  // Search reels
  static Future<List<ReelModel>> searchReels(
    String query, {
    int limit = 20,
  }) async {
    try {
      if (query.isEmpty) return [];

      // Search by caption and hashtags
      final captionResults = await _firestore
          .collection('reels')
          .where('caption', isGreaterThanOrEqualTo: query)
          .where('caption', isLessThan: '${query}z')
          .where('isDeleted', isEqualTo: false)
          .limit(limit)
          .get();

      final hashtagResults = await _firestore
          .collection('reels')
          .where('hashtags', arrayContains: query.toLowerCase())
          .where('isDeleted', isEqualTo: false)
          .limit(limit)
          .get();

      Set<String> reelIds = {};
      List<ReelModel> results = [];

      // Process caption results
      for (final doc in captionResults.docs) {
        if (!reelIds.contains(doc.id)) {
          reelIds.add(doc.id);
          results.add(ReelModel.fromFirestore(doc));
        }
      }

      // Process hashtag results
      for (final doc in hashtagResults.docs) {
        if (!reelIds.contains(doc.id)) {
          reelIds.add(doc.id);
          results.add(ReelModel.fromFirestore(doc));
        }
      }

      // Sort by relevance and engagement
      results.sort((a, b) {
        final aScore = _calculateRelevanceScore(a, query);
        final bScore = _calculateRelevanceScore(b, query);
        return bScore.compareTo(aScore);
      });

      return results.take(limit).toList();
    } catch (e) {
      print('Error searching reels: $e');
      return [];
    }
  }

  // Like/Unlike reel
  static Future<bool> toggleLike(String reelId) async {
    try {
      final String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      return await _firestore.runTransaction((transaction) async {
        final reelRef = _firestore.collection('reels').doc(reelId);
        final reelSnapshot = await transaction.get(reelRef);

        if (!reelSnapshot.exists) return false;

        final reelData = reelSnapshot.data()!;
        final List<String> likedBy = List<String>.from(reelData['likedBy'] ?? []);
        final int likesCount = reelData['likesCount'] ?? 0;

        bool isLiked = likedBy.contains(currentUserId);

        if (isLiked) {
          // Unlike
          likedBy.remove(currentUserId);
          transaction.update(reelRef, {
            'likedBy': likedBy,
            'likesCount': (likesCount - 1).clamp(0, double.infinity),
          });
        } else {
          // Like
          likedBy.add(currentUserId);
          transaction.update(reelRef, {
            'likedBy': likedBy,
            'likesCount': likesCount + 1,
          });

          // Send notification to reel owner
          final reelUserId = reelData['userId'];
          if (reelUserId != currentUserId) {
            await _sendLikeNotification(reelUserId, currentUserId, reelId);
          }
        }

        return !isLiked; // Return new like status
      });
    } catch (e) {
      print('Error toggling like: $e');
      return false;
    }
  }

  // Save/Unsave reel
  static Future<bool> toggleSave(String reelId) async {
    try {
      final String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      return await _firestore.runTransaction((transaction) async {
        final reelRef = _firestore.collection('reels').doc(reelId);
        final reelSnapshot = await transaction.get(reelRef);

        if (!reelSnapshot.exists) return false;

        final reelData = reelSnapshot.data()!;
        final List<String> savedBy = List<String>.from(reelData['savedBy'] ?? []);

        bool isSaved = savedBy.contains(currentUserId);

        if (isSaved) {
          // Unsave
          savedBy.remove(currentUserId);
          transaction.update(reelRef, {'savedBy': savedBy});

          // Remove from user's saved reels
          final userSavedRef = _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('savedReels')
              .doc(reelId);
          transaction.delete(userSavedRef);
        } else {
          // Save
          savedBy.add(currentUserId);
          transaction.update(reelRef, {'savedBy': savedBy});

          // Add to user's saved reels
          final userSavedRef = _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('savedReels')
              .doc(reelId);
          transaction.set(userSavedRef, {
            'reelId': reelId,
            'savedAt': FieldValue.serverTimestamp(),
          });
        }

        return !isSaved; // Return new save status
      });
    } catch (e) {
      print('Error toggling save: $e');
      return false;
    }
  }

  // Share reel
  static Future<bool> shareReel(String reelId) async {
    try {
      final String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      await _firestore.collection('reels').doc(reelId).update({
        'sharesCount': FieldValue.increment(1),
        'sharedBy': FieldValue.arrayUnion([currentUserId]),
      });

      // Add to analytics
      await _firestore.collection('analytics').add({
        'type': 'reel_share',
        'reelId': reelId,
        'userId': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error sharing reel: $e');
      return false;
    }
  }

  // Add view to reel
  static Future<void> addView(String reelId) async {
    try {
      final String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      // Check if user already viewed this reel today
      final today = DateTime.now();
      final todayString = '${today.year}-${today.month}-${today.day}';
      
      final viewRef = _firestore
          .collection('reels')
          .doc(reelId)
          .collection('views')
          .doc('${currentUserId}_$todayString');

      final viewSnapshot = await viewRef.get();
      
      if (!viewSnapshot.exists) {
        // Add view record
        await viewRef.set({
          'userId': currentUserId,
          'viewedAt': FieldValue.serverTimestamp(),
          'date': todayString,
        });

        // Increment view count
        await _firestore.collection('reels').doc(reelId).update({
          'viewsCount': FieldValue.increment(1),
        });
      }
    } catch (e) {
      print('Error adding view: $e');
    }
  }

  // Delete reel
  static Future<bool> deleteReel(String reelId) async {
    try {
      final String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      // Check if user owns the reel
      final reelDoc = await _firestore.collection('reels').doc(reelId).get();
      if (!reelDoc.exists || reelDoc.data()!['userId'] != currentUserId) {
        return false;
      }

      // Soft delete - mark as deleted
      await _firestore.collection('reels').doc(reelId).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });

      // Update user's posts count
      await _firestore.collection('users').doc(currentUserId).update({
        'postsCount': FieldValue.increment(-1),
      });

      return true;
    } catch (e) {
      print('Error deleting reel: $e');
      return false;
    }
  }

  // Report reel
  static Future<bool> reportReel(String reelId, String reason) async {
    try {
      final String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      await _firestore.collection('reports').add({
        'type': 'reel',
        'contentId': reelId,
        'reportedBy': currentUserId,
        'reason': reason,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update reel reported count
      await _firestore.collection('reels').doc(reelId).update({
        'reportedBy': FieldValue.arrayUnion([currentUserId]),
      });

      return true;
    } catch (e) {
      print('Error reporting reel: $e');
      return false;
    }
  }

  // Get saved reels
  static Future<List<ReelModel>> getSavedReels({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      final String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return [];

      Query query = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('savedReels')
          .orderBy('savedAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final savedSnapshot = await query.get();
      List<ReelModel> savedReels = [];

      for (final doc in savedSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final reelId = data['reelId'];
        
        final reelDoc = await _firestore.collection('reels').doc(reelId).get();
        if (reelDoc.exists && 
            reelDoc.data()!['isDeleted'] != true &&
            reelDoc.data()!['isArchived'] != true) {
          savedReels.add(ReelModel.fromFirestore(reelDoc));
        }
      }

      return savedReels;
    } catch (e) {
      print('Error getting saved reels: $e');
      return [];
    }
  }

  // Update trending status
  static Future<void> updateTrendingReels() async {
    try {
      // Get reels from last 24 hours with high engagement
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      
      final recentReels = await _firestore
          .collection('reels')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(yesterday))
          .where('isDeleted', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      
      for (final doc in recentReels.docs) {
        final reel = ReelModel.fromFirestore(doc);
        final engagementScore = _calculateEngagementScore(reel);
        
        // Mark as trending if engagement score is high
        if (engagementScore > 0.1) { // 10% engagement rate
          batch.update(doc.reference, {'isTrending': true});
        } else {
          batch.update(doc.reference, {'isTrending': false});
        }
      }

      await batch.commit();
    } catch (e) {
      print('Error updating trending reels: $e');
    }
  }

  // Private helper methods
  static double _calculateEngagementScore(ReelModel reel) {
    if (reel.viewsCount == 0) return 0;
    
    final likes = reel.likesCount.toDouble();
    final comments = reel.commentsCount.toDouble();
    final shares = reel.sharesCount.toDouble();
    final views = reel.viewsCount.toDouble();
    
    return ((likes + comments * 2 + shares * 3) / views);
  }

  static double _calculateRelevanceScore(ReelModel reel, String query) {
    double score = 0;
    
    // Caption relevance
    if (reel.caption.toLowerCase().contains(query.toLowerCase())) {
      score += 10;
    }
    
    // Hashtag relevance
    for (final hashtag in reel.hashtags) {
      if (hashtag.toLowerCase().contains(query.toLowerCase())) {
        score += 15;
      }
    }
    
    // Add engagement bonus
    score += _calculateEngagementScore(reel) * 5;
    
    return score;
  }

  static Future<void> _sendLikeNotification(String targetUserId, String fromUserId, String reelId) async {
    await _firestore.collection('notifications').add({
      'userId': targetUserId,
      'fromUserId': fromUserId,
      'type': 'reel_like',
      'reelId': reelId,
      'message': 'أعجب بريلك',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> _sendMentionNotification(String targetUserId, String fromUserId, String reelId) async {
    await _firestore.collection('notifications').add({
      'userId': targetUserId,
      'fromUserId': fromUserId,
      'type': 'reel_mention',
      'reelId': reelId,
      'message': 'ذكرك في ريل',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

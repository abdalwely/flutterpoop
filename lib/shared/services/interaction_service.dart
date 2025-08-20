import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/post_model.dart';
import '../models/user_model.dart';

class InteractionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Like/Unlike post with real-time updates
  static Future<bool> togglePostLike(String postId) async {
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final postRef = _firestore.collection('posts').doc(postId);
      final userRef = _firestore.collection('users').doc(userId);

      return await _firestore.runTransaction((transaction) async {
        final postSnapshot = await transaction.get(postRef);
        final userSnapshot = await transaction.get(userRef);
        
        if (!postSnapshot.exists || !userSnapshot.exists) {
          throw Exception('Post or user not found');
        }

        final postData = postSnapshot.data()!;
        final userData = userSnapshot.data()!;
        
        final List<String> postLikes = List<String>.from(postData['likes'] ?? []);
        final List<String> userLikedPosts = List<String>.from(userData['likedPosts'] ?? []);
        
        bool isLiked = postLikes.contains(userId);
        
        if (isLiked) {
          // Unlike the post
          postLikes.remove(userId);
          userLikedPosts.remove(postId);
        } else {
          // Like the post
          postLikes.add(userId);
          userLikedPosts.add(postId);
          
          // Add notification for post owner
          await _addLikeNotification(postData['userId'], userId, postId);
        }

        // Update post likes count
        transaction.update(postRef, {
          'likes': postLikes,
          'likesCount': postLikes.length,
          'lastInteraction': FieldValue.serverTimestamp(),
        });

        // Update user liked posts
        transaction.update(userRef, {
          'likedPosts': userLikedPosts,
        });

        return !isLiked; // Return new like status
      });
    } catch (e) {
      print('Error toggling post like: $e');
      return false;
    }
  }

  // Save/Unsave post
  static Future<bool> togglePostSave(String postId) async {
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final userRef = _firestore.collection('users').doc(userId);
      final userSnapshot = await userRef.get();
      
      if (!userSnapshot.exists) return false;

      final userData = userSnapshot.data()!;
      final List<String> savedPosts = List<String>.from(userData['savedPosts'] ?? []);
      
      bool isSaved = savedPosts.contains(postId);
      
      if (isSaved) {
        savedPosts.remove(postId);
      } else {
        savedPosts.add(postId);
      }

      await userRef.update({
        'savedPosts': savedPosts,
      });

      return !isSaved;
    } catch (e) {
      print('Error toggling post save: $e');
      return false;
    }
  }

  // Share post (increment share count)
  static Future<bool> sharePost(String postId, {String? platform}) async {
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final postRef = _firestore.collection('posts').doc(postId);
      
      await _firestore.runTransaction((transaction) async {
        final postSnapshot = await transaction.get(postRef);
        
        if (!postSnapshot.exists) {
          throw Exception('Post not found');
        }

        final postData = postSnapshot.data()!;
        final int currentShares = postData['sharesCount'] ?? 0;
        
        transaction.update(postRef, {
          'sharesCount': currentShares + 1,
          'lastInteraction': FieldValue.serverTimestamp(),
        });

        // Add share activity
        await _addShareActivity(userId, postId, platform);
      });

      return true;
    } catch (e) {
      print('Error sharing post: $e');
      return false;
    }
  }

  // Comment on post
  static Future<String?> addPostComment(String postId, String comment, {String? parentCommentId}) async {
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final commentData = {
        'id': _firestore.collection('comments').doc().id,
        'postId': postId,
        'userId': userId,
        'content': comment,
        'parentCommentId': parentCommentId,
        'likes': <String>[],
        'likesCount': 0,
        'repliesCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isEdited': false,
        'isPinned': false,
        'reactions': <String, int>{},
      };

      final commentRef = await _firestore.collection('comments').add(commentData);
      
      // Update post comments count
      await _firestore.collection('posts').doc(postId).update({
        'commentsCount': FieldValue.increment(1),
        'lastInteraction': FieldValue.serverTimestamp(),
      });

      // If it's a reply, update parent comment replies count
      if (parentCommentId != null) {
        await _firestore.collection('comments').doc(parentCommentId).update({
          'repliesCount': FieldValue.increment(1),
        });
      }

      return commentRef.id;
    } catch (e) {
      print('Error adding comment: $e');
      return null;
    }
  }

  // Add reaction to post (love, laugh, angry, etc.)
  static Future<bool> addPostReaction(String postId, String reactionType) async {
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final postRef = _firestore.collection('posts').doc(postId);
      
      await _firestore.runTransaction((transaction) async {
        final postSnapshot = await transaction.get(postRef);
        
        if (!postSnapshot.exists) {
          throw Exception('Post not found');
        }

        final postData = postSnapshot.data()!;
        final Map<String, dynamic> reactions = Map<String, dynamic>.from(postData['reactions'] ?? {});
        final Map<String, dynamic> userReactions = Map<String, dynamic>.from(reactions['users'] ?? {});
        
        // Remove previous reaction if exists
        final String? previousReaction = userReactions[userId];
        if (previousReaction != null) {
          reactions[previousReaction] = (reactions[previousReaction] ?? 1) - 1;
          if (reactions[previousReaction] <= 0) {
            reactions.remove(previousReaction);
          }
        }

        // Add new reaction
        reactions[reactionType] = (reactions[reactionType] ?? 0) + 1;
        userReactions[userId] = reactionType;
        reactions['users'] = userReactions;

        transaction.update(postRef, {
          'reactions': reactions,
          'lastInteraction': FieldValue.serverTimestamp(),
        });
      });

      return true;
    } catch (e) {
      print('Error adding reaction: $e');
      return false;
    }
  }

  // Get post interaction statistics
  static Stream<Map<String, dynamic>> getPostInteractionStats(String postId) {
    return _firestore.collection('posts').doc(postId).snapshots().map((snapshot) {
      if (!snapshot.exists) return {};
      
      final data = snapshot.data()!;
      return {
        'likesCount': data['likesCount'] ?? 0,
        'commentsCount': data['commentsCount'] ?? 0,
        'sharesCount': data['sharesCount'] ?? 0,
        'reactions': data['reactions'] ?? {},
        'likes': List<String>.from(data['likes'] ?? []),
      };
    });
  }

  // Check if user liked post
  static Future<bool> isPostLikedByUser(String postId) async {
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final postSnapshot = await _firestore.collection('posts').doc(postId).get();
      if (!postSnapshot.exists) return false;

      final postData = postSnapshot.data()!;
      final List<String> likes = List<String>.from(postData['likes'] ?? []);
      
      return likes.contains(userId);
    } catch (e) {
      print('Error checking post like status: $e');
      return false;
    }
  }

  // Check if user saved post
  static Future<bool> isPostSavedByUser(String postId) async {
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final userSnapshot = await _firestore.collection('users').doc(userId).get();
      if (!userSnapshot.exists) return false;

      final userData = userSnapshot.data()!;
      final List<String> savedPosts = List<String>.from(userData['savedPosts'] ?? []);
      
      return savedPosts.contains(postId);
    } catch (e) {
      print('Error checking post save status: $e');
      return false;
    }
  }

  // Private helper methods
  static Future<void> _addLikeNotification(String postOwnerId, String likerId, String postId) async {
    if (postOwnerId == likerId) return; // Don't notify self

    await _firestore.collection('notifications').add({
      'id': _firestore.collection('notifications').doc().id,
      'userId': postOwnerId,
      'fromUserId': likerId,
      'type': 'like',
      'postId': postId,
      'message': 'أعجب بمنشورك',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> _addShareActivity(String userId, String postId, String? platform) async {
    await _firestore.collection('activities').add({
      'userId': userId,
      'type': 'share',
      'postId': postId,
      'platform': platform ?? 'app',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get trending posts based on interactions
  static Future<List<PostModel>> getTrendingPosts({int limit = 20}) async {
    try {
      final now = DateTime.now();
      final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));

      final query = await _firestore
          .collection('posts')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(twentyFourHoursAgo))
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      List<PostModel> posts = query.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();

      // Sort by engagement score
      posts.sort((a, b) {
        double scoreA = _calculateEngagementScore(a);
        double scoreB = _calculateEngagementScore(b);
        return scoreB.compareTo(scoreA);
      });

      return posts.take(limit).toList();
    } catch (e) {
      print('Error getting trending posts: $e');
      return [];
    }
  }

  static double _calculateEngagementScore(PostModel post) {
    final double likes = post.likesCount.toDouble();
    final double comments = post.commentsCount.toDouble();
    final double shares = post.sharesCount.toDouble();
    
    // Weight different interactions
    return (likes * 1.0) + (comments * 2.0) + (shares * 3.0);
  }

  // Batch interaction operations for better performance
  static Future<void> batchLikePosts(List<String> postIds) async {
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final batch = _firestore.batch();

      for (String postId in postIds) {
        final postRef = _firestore.collection('posts').doc(postId);
        batch.update(postRef, {
          'likes': FieldValue.arrayUnion([userId]),
          'likesCount': FieldValue.increment(1),
          'lastInteraction': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error batch liking posts: $e');
    }
  }
}

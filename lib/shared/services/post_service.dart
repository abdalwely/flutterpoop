import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import '../../core/constants/app_constants.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Posts Collection Reference
  CollectionReference get _postsCollection =>
      _firestore.collection(AppConstants.postsCollection);

  // Users Collection Reference
  CollectionReference get _usersCollection =>
      _firestore.collection(AppConstants.usersCollection);

  // Create Post
  Future<String> createPost({
    required String userId,
    required String caption,
    required List<File> mediaFiles,
    PostLocation? location,
    List<String>? hashtags,
    List<String>? mentions,
    PostVisibility visibility = PostVisibility.public,
    bool allowComments = true,
    bool allowSharing = true,
    bool hideLikesCount = false,
  }) async {
    try {
      // Get user data
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = UserModel.fromFirestore(userDoc);

      // Upload media files
      final List<PostMedia> mediaList = [];
      for (int i = 0; i < mediaFiles.length; i++) {
        final file = mediaFiles[i];
        final mediaId = '${userId}_${DateTime.now().millisecondsSinceEpoch}_$i';
        
        // Determine media type
        final extension = file.path.split('.').last.toLowerCase();
        final isVideo = ['mp4', 'mov', 'avi', 'mkv'].contains(extension);
        final mediaType = isVideo ? PostType.video : PostType.image;
        
        // Upload to Firebase Storage
        final storageRef = _storage.ref().child(
          isVideo ? AppConstants.postVideosPath : AppConstants.postImagesPath,
        ).child('$mediaId.$extension');
        
        final uploadTask = await storageRef.putFile(file);
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        
        // Create thumbnail for videos
        String? thumbnailUrl;
        if (isVideo) {
          // Here you would generate video thumbnail
          // For now, we'll use a placeholder
          thumbnailUrl = downloadUrl;
        }
        
        final media = PostMedia(
          id: mediaId,
          url: downloadUrl,
          thumbnailUrl: thumbnailUrl,
          type: mediaType,
          aspectRatio: 1.0, // You can calculate this from the actual image
        );
        
        mediaList.add(media);
      }

      // Create post document
      final postId = _postsCollection.doc().id;
      final post = PostModel(
        id: postId,
        userId: userId,
        username: userData.username,
        userProfileImage: userData.profileImageUrl,
        isUserVerified: userData.isVerified,
        caption: caption,
        media: mediaList,
        location: location,
        hashtags: hashtags ?? [],
        mentions: mentions ?? [],
        visibility: visibility,
        allowComments: allowComments,
        allowSharing: allowSharing,
        hideLikesCount: hideLikesCount,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await _postsCollection.doc(postId).set(post.toJson());
      
      // Update user posts count
      await _usersCollection.doc(userId).update({
        'postsCount': FieldValue.increment(1),
      });

      // Add to user's timeline for followers
      await _addToFollowersTimeline(post);

      return postId;
    } catch (e) {
      throw Exception('خطأ في إنشاء المنشور: $e');
    }
  }

  // Get Posts Feed
  Future<List<PostModel>> getFeedPosts({
    required String userId,
    DocumentSnapshot? lastDocument,
    int limit = 10,
  }) async {
    try {
      // Get user's following list
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = UserModel.fromFirestore(userDoc);
      final followingList = [...userData.following, userId]; // Include own posts

      Query query = _postsCollection
          .where('userId', whereIn: followingList.take(10).toList()) // Firestore limit
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('خطأ في جلب المنشورات: $e');
    }
  }

  // Get User Posts
  Future<List<PostModel>> getUserPosts({
    required String userId,
    DocumentSnapshot? lastDocument,
    int limit = 12,
  }) async {
    try {
      Query query = _postsCollection
          .where('userId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: false)
          .where('isArchived', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('خطأ في جلب منشورات المستخدم: $e');
    }
  }

  // Like Post
  Future<void> likePost(String postId, String userId) async {
    try {
      final batch = _firestore.batch();
      final postRef = _postsCollection.doc(postId);
      
      batch.update(postRef, {
        'likedBy': FieldValue.arrayUnion([userId]),
        'likesCount': FieldValue.increment(1),
      });

      await batch.commit();

      // Create notification for post owner
      await _createLikeNotification(postId, userId);
    } catch (e) {
      throw Exception('خطأ في الإعجاب بالمنشور: $e');
    }
  }

  // Unlike Post
  Future<void> unlikePost(String postId, String userId) async {
    try {
      await _postsCollection.doc(postId).update({
        'likedBy': FieldValue.arrayRemove([userId]),
        'likesCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('خطأ في إلغاء الإعجاب: $e');
    }
  }

  // Save Post
  Future<void> savePost(String postId, String userId) async {
    try {
      await _postsCollection.doc(postId).update({
        'savedBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw Exception('خطأ في حفظ المنشور: $e');
    }
  }

  // Unsave Post
  Future<void> unsavePost(String postId, String userId) async {
    try {
      await _postsCollection.doc(postId).update({
        'savedBy': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      throw Exception('خطأ في إلغاء حفظ المنشور: $e');
    }
  }

  // Share Post
  Future<void> sharePost(String postId, String userId) async {
    try {
      await _postsCollection.doc(postId).update({
        'sharedBy': FieldValue.arrayUnion([userId]),
        'sharesCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('خطأ في مشاركة المنشور: $e');
    }
  }

  // Get Post by ID
  Future<PostModel?> getPostById(String postId) async {
    try {
      final doc = await _postsCollection.doc(postId).get();
      if (doc.exists) {
        return PostModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('خطأ في جلب المنشور: $e');
    }
  }

  // Update Post
  Future<void> updatePost({
    required String postId,
    String? caption,
    List<String>? hashtags,
    List<String>? mentions,
    PostLocation? location,
    bool? allowComments,
    bool? allowSharing,
    bool? hideLikesCount,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (caption != null) updateData['caption'] = caption;
      if (hashtags != null) updateData['hashtags'] = hashtags;
      if (mentions != null) updateData['mentions'] = mentions;
      if (location != null) updateData['location'] = location.toJson();
      if (allowComments != null) updateData['allowComments'] = allowComments;
      if (allowSharing != null) updateData['allowSharing'] = allowSharing;
      if (hideLikesCount != null) updateData['hideLikesCount'] = hideLikesCount;

      await _postsCollection.doc(postId).update(updateData);
    } catch (e) {
      throw Exception('خطأ في تحديث المنشور: $e');
    }
  }

  // Delete Post
  Future<void> deletePost(String postId, String userId) async {
    try {
      // Soft delete
      await _postsCollection.doc(postId).update({
        'isDeleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update user posts count
      await _usersCollection.doc(userId).update({
        'postsCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('خطأ في حذف المنشور: $e');
    }
  }

  // Archive Post
  Future<void> archivePost(String postId) async {
    try {
      await _postsCollection.doc(postId).update({
        'isArchived': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('خطأ في أرشفة المنشور: $e');
    }
  }

  // Unarchive Post
  Future<void> unarchivePost(String postId) async {
    try {
      await _postsCollection.doc(postId).update({
        'isArchived': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('خطأ في إلغاء أرشفة المنشور: $e');
    }
  }

  // Get Saved Posts
  Future<List<PostModel>> getSavedPosts({
    required String userId,
    DocumentSnapshot? lastDocument,
    int limit = 12,
  }) async {
    try {
      Query query = _postsCollection
          .where('savedBy', arrayContains: userId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('خطأ في جلب المنشورات المحفوظة: $e');
    }
  }

  // Get Posts by Hashtag
  Future<List<PostModel>> getPostsByHashtag({
    required String hashtag,
    DocumentSnapshot? lastDocument,
    int limit = 12,
  }) async {
    try {
      Query query = _postsCollection
          .where('hashtags', arrayContains: hashtag)
          .where('isDeleted', isEqualTo: false)
          .where('visibility', isEqualTo: PostVisibility.public.name)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('خطأ في جلب المنشورات بالهاشتاغ: $e');
    }
  }

  // Get Trending Posts
  Future<List<PostModel>> getTrendingPosts({
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    try {
      // Get posts from last 7 days with high engagement
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      
      Query query = _postsCollection
          .where('createdAt', isGreaterThan: Timestamp.fromDate(weekAgo))
          .where('isDeleted', isEqualTo: false)
          .where('visibility', isEqualTo: PostVisibility.public.name)
          .orderBy('createdAt', descending: true)
          .orderBy('likesCount', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('خطأ في جلب المنشورات الرائجة: $e');
    }
  }

  // Get Post Analytics
  Future<Map<String, dynamic>> getPostAnalytics(String postId) async {
    try {
      final doc = await _postsCollection.doc(postId).get();
      if (!doc.exists) throw Exception('المنشور غير موجود');
      
      final post = PostModel.fromFirestore(doc);
      
      return {
        'views': post.viewsCount,
        'likes': post.likesCount,
        'comments': post.commentsCount,
        'shares': post.sharesCount,
        'saves': post.savedBy.length,
        'engagement_rate': _calculateEngagementRate(post),
        'reach': post.viewsCount, // Simplified
        'impressions': post.viewsCount * 1.5, // Simplified
      };
    } catch (e) {
      throw Exception('خطأ في جلب إحصائيات المنشور: $e');
    }
  }

  // Helper Methods
  Future<void> _addToFollowersTimeline(PostModel post) async {
    // This would typically be handled by Cloud Functions
    // For now, we'll just add a simple implementation
    try {
      final userDoc = await _usersCollection.doc(post.userId).get();
      final userData = UserModel.fromFirestore(userDoc);
      
      // In a real implementation, you'd iterate through followers
      // and add to their timeline collection
    } catch (e) {
      // Log error but don't throw
      print('Error adding to followers timeline: $e');
    }
  }

  Future<void> _createLikeNotification(String postId, String userId) async {
    try {
      final postDoc = await _postsCollection.doc(postId).get();
      if (!postDoc.exists) return;
      
      final post = PostModel.fromFirestore(postDoc);
      if (post.userId == userId) return; // Don't notify self
      
      // Create notification document
      await _firestore
          .collection(AppConstants.notificationsCollection)
          .add({
        'type': 'like',
        'fromUserId': userId,
        'toUserId': post.userId,
        'postId': postId,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      // Log error but don't throw
      print('Error creating like notification: $e');
    }
  }

  double _calculateEngagementRate(PostModel post) {
    final totalEngagements = post.likesCount + post.commentsCount + post.sharesCount;
    final reach = post.viewsCount > 0 ? post.viewsCount : 1;
    return (totalEngagements / reach) * 100;
  }

  // Stream for real-time post updates
  Stream<PostModel?> getPostStream(String postId) {
    return _postsCollection.doc(postId).snapshots().map((doc) {
      if (doc.exists) {
        return PostModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // Batch operations
  Future<void> batchLikePosts(List<String> postIds, String userId) async {
    try {
      final batch = _firestore.batch();
      
      for (String postId in postIds) {
        final postRef = _postsCollection.doc(postId);
        batch.update(postRef, {
          'likedBy': FieldValue.arrayUnion([userId]),
          'likesCount': FieldValue.increment(1),
        });
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('خطأ في الإعجاب بالمنشورات: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import '../../core/constants/app_constants.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Comments Collection Reference
  CollectionReference get _commentsCollection =>
      _firestore.collection(AppConstants.commentsCollection);

  // Posts Collection Reference
  CollectionReference get _postsCollection =>
      _firestore.collection(AppConstants.postsCollection);

  // Users Collection Reference
  CollectionReference get _usersCollection =>
      _firestore.collection(AppConstants.usersCollection);

  // Add Comment
  Future<String> addComment({
    required String postId,
    required String userId,
    required String text,
    String? parentCommentId,
    File? mediaFile,
    List<String>? mentions,
    List<String>? hashtags,
  }) async {
    try {
      // Get user data
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = UserModel.fromFirestore(userDoc);

      // Get post data to check if user is the creator
      final postDoc = await _postsCollection.doc(postId).get();
      final postData = PostModel.fromFirestore(postDoc);
      final isFromCreator = postData.userId == userId;

      // Upload media if provided
      CommentMedia? media;
      if (mediaFile != null) {
        final mediaId = '${userId}_${DateTime.now().millisecondsSinceEpoch}';
        final extension = mediaFile.path.split('.').last.toLowerCase();
        
        // Determine media type
        CommentType mediaType;
        if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
          mediaType = CommentType.media;
        } else {
          mediaType = CommentType.media;
        }
        
        // Upload to Firebase Storage
        final storageRef = _storage.ref()
            .child(AppConstants.chatImagesPath)
            .child('comments')
            .child('$mediaId.$extension');
        
        final uploadTask = await storageRef.putFile(mediaFile);
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        
        media = CommentMedia(
          id: mediaId,
          url: downloadUrl,
          type: mediaType,
        );
      }

      // Create comment document
      final commentId = _commentsCollection.doc().id;
      final comment = CommentModel(
        id: commentId,
        postId: postId,
        parentCommentId: parentCommentId,
        userId: userId,
        username: userData.username,
        userProfileImage: userData.profileImageUrl,
        isUserVerified: userData.isVerified,
        text: text,
        mentions: mentions ?? [],
        hashtags: hashtags ?? [],
        media: media,
        isFromCreator: isFromCreator,
        createdAt: DateTime.now(),
      );

      // Save to Firestore in batch
      final batch = _firestore.batch();
      
      // Add comment
      batch.set(_commentsCollection.doc(commentId), comment.toJson());
      
      // Update post comments count
      batch.update(_postsCollection.doc(postId), {
        'commentsCount': FieldValue.increment(1),
      });
      
      // If it's a reply, update parent comment replies count
      if (parentCommentId != null) {
        batch.update(_commentsCollection.doc(parentCommentId), {
          'repliesCount': FieldValue.increment(1),
        });
      }
      
      await batch.commit();

      // Create notifications
      await _createCommentNotifications(comment, postData);

      return commentId;
    } catch (e) {
      throw Exception('خطأ في إضافة التعليق: $e');
    }
  }

  // Get Comments for Post
  Future<List<CommentModel>> getPostComments({
    required String postId,
    DocumentSnapshot? lastDocument,
    int limit = 20,
    bool topLevelOnly = false,
  }) async {
    try {
      Query query = _commentsCollection
          .where('postId', isEqualTo: postId)
          .where('isDeleted', isEqualTo: false);

      if (topLevelOnly) {
        query = query.where('parentCommentId', isNull: true);
      }

      query = query.orderBy('createdAt', descending: false).limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => CommentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('خطأ في جلب التعليقات: $e');
    }
  }

  // Get Replies for Comment
  Future<List<CommentModel>> getCommentReplies({
    required String commentId,
    DocumentSnapshot? lastDocument,
    int limit = 10,
  }) async {
    try {
      Query query = _commentsCollection
          .where('parentCommentId', isEqualTo: commentId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: false)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => CommentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('خطأ في جلب الردود: $e');
    }
  }

  // Like Comment
  Future<void> likeComment(String commentId, String userId) async {
    try {
      await _commentsCollection.doc(commentId).update({
        'likedBy': FieldValue.arrayUnion([userId]),
        'likesCount': FieldValue.increment(1),
      });

      // Create notification for comment owner
      await _createCommentLikeNotification(commentId, userId);
    } catch (e) {
      throw Exception('خطأ في الإعجاب بالتعليق: $e');
    }
  }

  // Unlike Comment
  Future<void> unlikeComment(String commentId, String userId) async {
    try {
      await _commentsCollection.doc(commentId).update({
        'likedBy': FieldValue.arrayRemove([userId]),
        'likesCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('خطأ في إلغاء الإعجاب بالتعليق: $e');
    }
  }

  // Add Reaction to Comment
  Future<void> addReactionToComment({
    required String commentId,
    required String userId,
    required String reaction,
  }) async {
    try {
      // Get user data
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = UserModel.fromFirestore(userDoc);

      final commentReaction = CommentReaction(
        userId: userId,
        username: userData.username,
        profileImageUrl: userData.profileImageUrl,
        reaction: reaction,
        createdAt: DateTime.now(),
      );

      // Remove existing reaction if any
      await removeReactionFromComment(commentId, userId);

      // Add new reaction
      await _commentsCollection.doc(commentId).update({
        'reactions': FieldValue.arrayUnion([commentReaction.toJson()]),
        'reactionCounts.$reaction': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('خطأ في إضافة التفاعل: $e');
    }
  }

  // Remove Reaction from Comment
  Future<void> removeReactionFromComment(String commentId, String userId) async {
    try {
      final commentDoc = await _commentsCollection.doc(commentId).get();
      if (!commentDoc.exists) return;

      final comment = CommentModel.fromFirestore(commentDoc);
      final userReaction = comment.reactions
          .where((r) => r.userId == userId)
          .firstOrNull;

      if (userReaction != null) {
        await _commentsCollection.doc(commentId).update({
          'reactions': FieldValue.arrayRemove([userReaction.toJson()]),
          'reactionCounts.${userReaction.reaction}': FieldValue.increment(-1),
        });
      }
    } catch (e) {
      throw Exception('خطأ في إزالة التفاعل: $e');
    }
  }

  // Edit Comment
  Future<void> editComment({
    required String commentId,
    required String newText,
    List<String>? mentions,
    List<String>? hashtags,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'text': newText,
        'isEdited': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (mentions != null) updateData['mentions'] = mentions;
      if (hashtags != null) updateData['hashtags'] = hashtags;

      await _commentsCollection.doc(commentId).update(updateData);
    } catch (e) {
      throw Exception('خطأ في تعديل التعليق: $e');
    }
  }

  // Delete Comment
  Future<void> deleteComment(String commentId, String userId) async {
    try {
      final commentDoc = await _commentsCollection.doc(commentId).get();
      if (!commentDoc.exists) return;

      final comment = CommentModel.fromFirestore(commentDoc);
      
      // Check if user owns the comment or the post
      final postDoc = await _postsCollection.doc(comment.postId).get();
      final post = PostModel.fromFirestore(postDoc);
      
      if (comment.userId != userId && post.userId != userId) {
        throw Exception('ليس لديك صلاحية لحذف هذا التعليق');
      }

      final batch = _firestore.batch();
      
      // Soft delete comment
      batch.update(_commentsCollection.doc(commentId), {
        'isDeleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update post comments count
      batch.update(_postsCollection.doc(comment.postId), {
        'commentsCount': FieldValue.increment(-1),
      });

      // If it's a reply, update parent comment replies count
      if (comment.parentCommentId != null) {
        batch.update(_commentsCollection.doc(comment.parentCommentId!), {
          'repliesCount': FieldValue.increment(-1),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('خطأ في حذف التعليق: $e');
    }
  }

  // Pin Comment (for post owners)
  Future<void> pinComment(String commentId, String postOwnerId) async {
    try {
      final commentDoc = await _commentsCollection.doc(commentId).get();
      if (!commentDoc.exists) return;

      final comment = CommentModel.fromFirestore(commentDoc);
      
      // Verify post ownership
      final postDoc = await _postsCollection.doc(comment.postId).get();
      final post = PostModel.fromFirestore(postDoc);
      
      if (post.userId != postOwnerId) {
        throw Exception('ليس لديك صلاحية لتثبيت هذا التعليق');
      }

      // Unpin other comments first
      await _unpinAllComments(comment.postId);

      // Pin this comment
      await _commentsCollection.doc(commentId).update({
        'isPinned': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('خطأ في تثبيت التعليق: $e');
    }
  }

  // Unpin Comment
  Future<void> unpinComment(String commentId) async {
    try {
      await _commentsCollection.doc(commentId).update({
        'isPinned': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('خطأ في إلغاء تثبيت التعليق: $e');
    }
  }

  // Report Comment
  Future<void> reportComment(String commentId, String userId) async {
    try {
      await _commentsCollection.doc(commentId).update({
        'reportedBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw Exception('خطأ في الإبلاغ عن التعليق: $e');
    }
  }

  // Get Comment by ID
  Future<CommentModel?> getCommentById(String commentId) async {
    try {
      final doc = await _commentsCollection.doc(commentId).get();
      if (doc.exists) {
        return CommentModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('خطأ في جلب التعليق: $e');
    }
  }

  // Get User Comments
  Future<List<CommentModel>> getUserComments({
    required String userId,
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    try {
      Query query = _commentsCollection
          .where('userId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => CommentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('خطأ في جلب تعليقات المستخدم: $e');
    }
  }

  // Search Comments
  Future<List<CommentModel>> searchComments({
    required String query,
    String? postId,
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    try {
      Query firestoreQuery = _commentsCollection
          .where('isDeleted', isEqualTo: false);

      if (postId != null) {
        firestoreQuery = firestoreQuery.where('postId', isEqualTo: postId);
      }

      // Note: Firestore doesn't support full-text search
      // In a real app, you'd use Algolia or Elasticsearch
      firestoreQuery = firestoreQuery
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        firestoreQuery = firestoreQuery.startAfterDocument(lastDocument);
      }

      final querySnapshot = await firestoreQuery.get();
      
      // Filter by text content (basic implementation)
      final comments = querySnapshot.docs
          .map((doc) => CommentModel.fromFirestore(doc))
          .where((comment) => comment.text.toLowerCase().contains(query.toLowerCase()))
          .toList();
      
      return comments;
    } catch (e) {
      throw Exception('خطأ في البحث في التعليقات: $e');
    }
  }

  // Helper Methods
  Future<void> _unpinAllComments(String postId) async {
    try {
      final pinnedComments = await _commentsCollection
          .where('postId', isEqualTo: postId)
          .where('isPinned', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (final doc in pinnedComments.docs) {
        batch.update(doc.reference, {'isPinned': false});
      }
      await batch.commit();
    } catch (e) {
      // Log error but don't throw
      print('Error unpinning comments: $e');
    }
  }

  Future<void> _createCommentNotifications(CommentModel comment, PostModel post) async {
    try {
      final batch = _firestore.batch();
      final notificationsRef = _firestore.collection(AppConstants.notificationsCollection);

      // Notify post owner (if not commenting on own post)
      if (post.userId != comment.userId) {
        batch.set(notificationsRef.doc(), {
          'type': 'comment',
          'fromUserId': comment.userId,
          'toUserId': post.userId,
          'postId': post.id,
          'commentId': comment.id,
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }

      // Notify mentioned users
      for (final mentionedUsername in comment.mentions) {
        // In a real app, you'd look up user ID by username
        batch.set(notificationsRef.doc(), {
          'type': 'mention',
          'fromUserId': comment.userId,
          'mentionedUsername': mentionedUsername,
          'postId': post.id,
          'commentId': comment.id,
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }

      await batch.commit();
    } catch (e) {
      // Log error but don't throw
      print('Error creating comment notifications: $e');
    }
  }

  Future<void> _createCommentLikeNotification(String commentId, String userId) async {
    try {
      final commentDoc = await _commentsCollection.doc(commentId).get();
      if (!commentDoc.exists) return;

      final comment = CommentModel.fromFirestore(commentDoc);
      if (comment.userId == userId) return; // Don't notify self

      await _firestore.collection(AppConstants.notificationsCollection).add({
        'type': 'comment_like',
        'fromUserId': userId,
        'toUserId': comment.userId,
        'commentId': commentId,
        'postId': comment.postId,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      // Log error but don't throw
      print('Error creating comment like notification: $e');
    }
  }

  // Stream for real-time comment updates
  Stream<List<CommentModel>> getPostCommentsStream(String postId) {
    return _commentsCollection
        .where('postId', isEqualTo: postId)
        .where('isDeleted', isEqualTo: false)
        .where('parentCommentId', isNull: true)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommentModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<CommentModel>> getCommentRepliesStream(String commentId) {
    return _commentsCollection
        .where('parentCommentId', isEqualTo: commentId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommentModel.fromFirestore(doc))
            .toList());
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';

class CommentServiceMethods {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get Comments for a post
  static Future<List<CommentModel>> getComments(String postId) async {
    try {
      final querySnapshot = await _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => CommentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting comments: $e');
      return [];
    }
  }

  // Add Comment
  static Future<CommentModel> addComment(
    String postId,
    String text, {
    String? parentId,
  }) async {
    try {
      final commentId = _firestore.collection('comments').doc().id;
      final now = DateTime.now();
      
      final comment = CommentModel(
        id: commentId,
        postId: postId,
        parentCommentId: parentId,
        userId: 'current_user_id', // Should come from auth
        username: 'current_user',
        userProfileImage: '',
        text: text,
        createdAt: now,
      );

      await _firestore
          .collection('comments')
          .doc(commentId)
          .set(comment.toJson());

      return comment;
    } catch (e) {
      print('Error adding comment: $e');
      throw Exception('Failed to add comment');
    }
  }

  // Like Comment
  static Future<void> likeComment(String commentId, String userId) async {
    try {
      await _firestore.collection('comments').doc(commentId).update({
        'likedBy': FieldValue.arrayUnion([userId]),
        'likesCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error liking comment: $e');
      throw Exception('Failed to like comment');
    }
  }

  // Delete Comment
  static Future<void> deleteComment(String commentId, String userId) async {
    try {
      await _firestore.collection('comments').doc(commentId).delete();
    } catch (e) {
      print('Error deleting comment: $e');
      throw Exception('Failed to delete comment');
    }
  }

  // Edit Comment
  static Future<CommentModel> editComment(String commentId, String newText) async {
    try {
      await _firestore.collection('comments').doc(commentId).update({
        'text': newText,
        'isEdited': true,
        'editedAt': Timestamp.now(),
      });

      final doc = await _firestore.collection('comments').doc(commentId).get();
      return CommentModel.fromFirestore(doc);
    } catch (e) {
      print('Error editing comment: $e');
      throw Exception('Failed to edit comment');
    }
  }

  // Pin Comment
  static Future<void> pinComment(String commentId, String userId) async {
    try {
      await _firestore.collection('comments').doc(commentId).update({
        'isPinned': true,
        'pinnedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error pinning comment: $e');
      throw Exception('Failed to pin comment');
    }
  }
}

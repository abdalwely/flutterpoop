import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/comment_model.dart';
import '../services/comment_service_methods.dart';

class CommentsState {
  final Map<String, List<CommentModel>> postComments;
  final Map<String, bool> loadingStates;
  final Map<String, String?> errors;
  final Map<String, CommentModel> commentUpdates;

  const CommentsState({
    this.postComments = const {},
    this.loadingStates = const {},
    this.errors = const {},
    this.commentUpdates = const {},
  });

  CommentsState copyWith({
    Map<String, List<CommentModel>>? postComments,
    Map<String, bool>? loadingStates,
    Map<String, String?>? errors,
    Map<String, CommentModel>? commentUpdates,
  }) {
    return CommentsState(
      postComments: postComments ?? this.postComments,
      loadingStates: loadingStates ?? this.loadingStates,
      errors: errors ?? this.errors,
      commentUpdates: commentUpdates ?? this.commentUpdates,
    );
  }

  List<CommentModel> getComments(String postId) {
    return postComments[postId] ?? [];
  }

  bool isLoading(String postId) {
    return loadingStates[postId] ?? false;
  }

  String? getError(String postId) {
    return errors[postId];
  }
}

class CommentsNotifier extends StateNotifier<CommentsState> {
  CommentsNotifier() : super(const CommentsState());

  Future<void> loadComments(String postId) async {
    try {
      final newLoadingStates = Map<String, bool>.from(state.loadingStates);
      newLoadingStates[postId] = true;
      
      state = state.copyWith(loadingStates: newLoadingStates);

      final comments = await CommentServiceMethods.getComments(postId);
      
      final newPostComments = Map<String, List<CommentModel>>.from(state.postComments);
      newPostComments[postId] = comments;
      
      newLoadingStates[postId] = false;
      final newErrors = Map<String, String?>.from(state.errors);
      newErrors[postId] = null;

      state = state.copyWith(
        postComments: newPostComments,
        loadingStates: newLoadingStates,
        errors: newErrors,
      );
    } catch (e) {
      final newLoadingStates = Map<String, bool>.from(state.loadingStates);
      newLoadingStates[postId] = false;
      
      final newErrors = Map<String, String?>.from(state.errors);
      newErrors[postId] = 'فشل في تحميل التعليقات: ${e.toString()}';

      state = state.copyWith(
        loadingStates: newLoadingStates,
        errors: newErrors,
      );
    }
  }

  Future<void> addComment(String postId, String text, {String? parentId}) async {
    try {
      final comment = await CommentServiceMethods.addComment(postId, text, parentId: parentId);
      
      final newPostComments = Map<String, List<CommentModel>>.from(state.postComments);
      final currentComments = List<CommentModel>.from(newPostComments[postId] ?? []);
      
      if (parentId != null) {
        // Add as reply to parent comment
        final parentIndex = currentComments.indexWhere((c) => c.id == parentId);
        if (parentIndex != -1) {
          final parent = currentComments[parentIndex];
          final updatedParent = parent.copyWith(
            replies: [...parent.replies, comment],
            repliesCount: parent.repliesCount + 1,
          );
          currentComments[parentIndex] = updatedParent;
        }
      } else {
        // Add as new top-level comment
        currentComments.insert(0, comment);
      }
      
      newPostComments[postId] = currentComments;
      
      state = state.copyWith(postComments: newPostComments);
    } catch (e) {
      final newErrors = Map<String, String?>.from(state.errors);
      newErrors[postId] = 'فشل في إضافة التعليق: ${e.toString()}';
      
      state = state.copyWith(errors: newErrors);
    }
  }

  Future<void> likeComment(String postId, String commentId) async {
    try {
      await CommentServiceMethods.likeComment(commentId, 'current_user_id');
      
      final newPostComments = Map<String, List<CommentModel>>.from(state.postComments);
      final currentComments = List<CommentModel>.from(newPostComments[postId] ?? []);
      
      final commentIndex = currentComments.indexWhere((c) => c.id == commentId);
      if (commentIndex != -1) {
        final comment = currentComments[commentIndex];
        final currentUserId = 'current_user_id'; // TODO: Get from auth provider
        final isCurrentlyLiked = comment.likedBy.contains(currentUserId);
        final updatedLikedBy = isCurrentlyLiked
            ? comment.likedBy.where((id) => id != currentUserId).toList()
            : [...comment.likedBy, currentUserId];

        final updatedComment = comment.copyWith(
          likedBy: updatedLikedBy,
          likesCount: isCurrentlyLiked ? comment.likesCount - 1 : comment.likesCount + 1,
        );
        currentComments[commentIndex] = updatedComment;
        newPostComments[postId] = currentComments;
        
        state = state.copyWith(postComments: newPostComments);
      }
    } catch (e) {
      final newErrors = Map<String, String?>.from(state.errors);
      newErrors[postId] = 'فشل في الإعجاب بالتعليق: ${e.toString()}';
      
      state = state.copyWith(errors: newErrors);
    }
  }

  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await CommentServiceMethods.deleteComment(commentId, 'current_user_id');
      
      final newPostComments = Map<String, List<CommentModel>>.from(state.postComments);
      final currentComments = List<CommentModel>.from(newPostComments[postId] ?? []);
      
      currentComments.removeWhere((c) => c.id == commentId);
      newPostComments[postId] = currentComments;
      
      state = state.copyWith(postComments: newPostComments);
    } catch (e) {
      final newErrors = Map<String, String?>.from(state.errors);
      newErrors[postId] = 'فشل في حذف التعليق: ${e.toString()}';
      
      state = state.copyWith(errors: newErrors);
    }
  }

  Future<void> editComment(String postId, String commentId, String newText) async {
    try {
      final updatedComment = await CommentServiceMethods.editComment(commentId, newText);
      
      final newPostComments = Map<String, List<CommentModel>>.from(state.postComments);
      final currentComments = List<CommentModel>.from(newPostComments[postId] ?? []);
      
      final commentIndex = currentComments.indexWhere((c) => c.id == commentId);
      if (commentIndex != -1) {
        currentComments[commentIndex] = updatedComment.copyWith(
          isEdited: true,
          editedAt: DateTime.now(),
        );
        newPostComments[postId] = currentComments;
        
        state = state.copyWith(postComments: newPostComments);
      }
    } catch (e) {
      final newErrors = Map<String, String?>.from(state.errors);
      newErrors[postId] = 'فشل في تعديل التعليق: ${e.toString()}';
      
      state = state.copyWith(errors: newErrors);
    }
  }

  Future<void> pinComment(String postId, String commentId) async {
    try {
      await CommentServiceMethods.pinComment(commentId, 'current_user_id');
      
      final newPostComments = Map<String, List<CommentModel>>.from(state.postComments);
      final currentComments = List<CommentModel>.from(newPostComments[postId] ?? []);
      
      final commentIndex = currentComments.indexWhere((c) => c.id == commentId);
      if (commentIndex != -1) {
        final comment = currentComments[commentIndex];
        final updatedComment = comment.copyWith(
          isPinned: !comment.isPinned,
          pinnedAt: comment.isPinned ? null : DateTime.now(),
        );
        
        // Remove from current position
        currentComments.removeAt(commentIndex);
        
        // Add to appropriate position (pinned comments go to top)
        if (updatedComment.isPinned) {
          currentComments.insert(0, updatedComment);
        } else {
          currentComments.add(updatedComment);
        }
        
        newPostComments[postId] = currentComments;
        state = state.copyWith(postComments: newPostComments);
      }
    } catch (e) {
      final newErrors = Map<String, String?>.from(state.errors);
      newErrors[postId] = 'فشل في تثبيت التعليق: ${e.toString()}';
      
      state = state.copyWith(errors: newErrors);
    }
  }

  void clearError(String postId) {
    final newErrors = Map<String, String?>.from(state.errors);
    newErrors[postId] = null;

    state = state.copyWith(errors: newErrors);
  }

  Future<void> loadMoreComments() async {
    // TODO: Implement pagination for loading more comments
    print('تحميل المزيد من التعليقات');
  }

  Future<void> reportComment(String commentId, String userId) async {
    try {
      // TODO: Implement report comment functionality
      print('تم الإبلاغ عن التعليق: $commentId');
    } catch (e) {
      print('فشل في الإبلاغ عن التعليق: $e');
    }
  }
}

// Provider definitions
final commentsProvider = StateNotifierProvider.family<CommentsNotifier, CommentsState, String>((ref, postId) {
  return CommentsNotifier();
});

// Helper providers
final postCommentsProvider = Provider.family<List<CommentModel>, String>((ref, postId) {
  return ref.watch(commentsProvider(postId)).getComments(postId);
});

final commentsLoadingProvider = Provider.family<bool, String>((ref, postId) {
  return ref.watch(commentsProvider(postId)).isLoading(postId);
});

final commentsErrorProvider = Provider.family<String?, String>((ref, postId) {
  return ref.watch(commentsProvider(postId)).getError(postId);
});

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/interaction_service.dart';
import '../models/post_model.dart';

class InteractionState {
  final Map<String, bool> likedPosts;
  final Map<String, bool> savedPosts;
  final Map<String, Map<String, dynamic>> postStats;
  final bool isLoading;
  final String? error;

  const InteractionState({
    this.likedPosts = const {},
    this.savedPosts = const {},
    this.postStats = const {},
    this.isLoading = false,
    this.error,
  });

  InteractionState copyWith({
    Map<String, bool>? likedPosts,
    Map<String, bool>? savedPosts,
    Map<String, Map<String, dynamic>>? postStats,
    bool? isLoading,
    String? error,
  }) {
    return InteractionState(
      likedPosts: likedPosts ?? this.likedPosts,
      savedPosts: savedPosts ?? this.savedPosts,
      postStats: postStats ?? this.postStats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class InteractionNotifier extends StateNotifier<InteractionState> {
  InteractionNotifier() : super(const InteractionState());

  // Toggle like with optimistic update
  Future<void> toggleLike(String postId) async {
    final currentLikeStatus = state.likedPosts[postId] ?? false;
    final currentStats = state.postStats[postId] ?? {};
    final currentLikesCount = currentStats['likesCount'] ?? 0;

    // Optimistic update
    final newLikedPosts = Map<String, bool>.from(state.likedPosts);
    final newPostStats = Map<String, Map<String, dynamic>>.from(state.postStats);
    
    newLikedPosts[postId] = !currentLikeStatus;
    newPostStats[postId] = {
      ...currentStats,
      'likesCount': currentLikeStatus ? currentLikesCount - 1 : currentLikesCount + 1,
    };

    state = state.copyWith(
      likedPosts: newLikedPosts,
      postStats: newPostStats,
    );

    try {
      final actualResult = await InteractionService.togglePostLike(postId);
      
      // Update with actual result if different
      if (actualResult != newLikedPosts[postId]) {
        newLikedPosts[postId] = actualResult;
        newPostStats[postId] = {
          ...newPostStats[postId]!,
          'likesCount': actualResult ? currentLikesCount + 1 : currentLikesCount - 1,
        };
        
        state = state.copyWith(
          likedPosts: newLikedPosts,
          postStats: newPostStats,
        );
      }
    } catch (e) {
      // Revert optimistic update on error
      final revertedLikedPosts = Map<String, bool>.from(state.likedPosts);
      final revertedPostStats = Map<String, Map<String, dynamic>>.from(state.postStats);
      
      revertedLikedPosts[postId] = currentLikeStatus;
      revertedPostStats[postId] = currentStats;
      
      state = state.copyWith(
        likedPosts: revertedLikedPosts,
        postStats: revertedPostStats,
        error: 'فشل في تحديث الإعجاب',
      );
    }
  }

  // Toggle save with optimistic update
  Future<void> toggleSave(String postId) async {
    final currentSaveStatus = state.savedPosts[postId] ?? false;

    // Optimistic update
    final newSavedPosts = Map<String, bool>.from(state.savedPosts);
    newSavedPosts[postId] = !currentSaveStatus;

    state = state.copyWith(savedPosts: newSavedPosts);

    try {
      final actualResult = await InteractionService.togglePostSave(postId);
      
      // Update with actual result if different
      if (actualResult != newSavedPosts[postId]) {
        newSavedPosts[postId] = actualResult;
        state = state.copyWith(savedPosts: newSavedPosts);
      }
    } catch (e) {
      // Revert optimistic update on error
      final revertedSavedPosts = Map<String, bool>.from(state.savedPosts);
      revertedSavedPosts[postId] = currentSaveStatus;
      
      state = state.copyWith(
        savedPosts: revertedSavedPosts,
        error: 'فشل في حفظ المنشور',
      );
    }
  }

  // Share post
  Future<void> sharePost(String postId, {String? platform}) async {
    try {
      state = state.copyWith(isLoading: true);
      
      final success = await InteractionService.sharePost(postId, platform: platform);
      
      if (success) {
        final currentStats = state.postStats[postId] ?? {};
        final newPostStats = Map<String, Map<String, dynamic>>.from(state.postStats);
        
        newPostStats[postId] = {
          ...currentStats,
          'sharesCount': (currentStats['sharesCount'] ?? 0) + 1,
        };
        
        state = state.copyWith(
          postStats: newPostStats,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'فشل في مشاركة المنشور',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل في مشاركة المنشور',
      );
    }
  }

  // Add comment
  Future<String?> addComment(String postId, String comment, {String? parentCommentId}) async {
    try {
      state = state.copyWith(isLoading: true);
      
      final commentId = await InteractionService.addPostComment(
        postId, 
        comment, 
        parentCommentId: parentCommentId,
      );
      
      if (commentId != null) {
        final currentStats = state.postStats[postId] ?? {};
        final newPostStats = Map<String, Map<String, dynamic>>.from(state.postStats);
        
        newPostStats[postId] = {
          ...currentStats,
          'commentsCount': (currentStats['commentsCount'] ?? 0) + 1,
        };
        
        state = state.copyWith(
          postStats: newPostStats,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'فشل في إضافة التعليق',
        );
      }
      
      return commentId;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل في إضافة التعليق',
      );
      return null;
    }
  }

  // Add reaction
  Future<void> addReaction(String postId, String reactionType) async {
    try {
      final success = await InteractionService.addPostReaction(postId, reactionType);
      
      if (success) {
        final currentStats = state.postStats[postId] ?? {};
        final currentReactions = Map<String, dynamic>.from(currentStats['reactions'] ?? {});
        
        currentReactions[reactionType] = (currentReactions[reactionType] ?? 0) + 1;
        
        final newPostStats = Map<String, Map<String, dynamic>>.from(state.postStats);
        newPostStats[postId] = {
          ...currentStats,
          'reactions': currentReactions,
        };
        
        state = state.copyWith(postStats: newPostStats);
      } else {
        state = state.copyWith(error: 'فشل في إضافة التفاعل');
      }
    } catch (e) {
      state = state.copyWith(error: 'فشل في إضافة التفاعل');
    }
  }

  // Load post interaction status
  Future<void> loadPostInteractionStatus(String postId) async {
    try {
      final isLiked = await InteractionService.isPostLikedByUser(postId);
      final isSaved = await InteractionService.isPostSavedByUser(postId);

      final newLikedPosts = Map<String, bool>.from(state.likedPosts);
      final newSavedPosts = Map<String, bool>.from(state.savedPosts);
      
      newLikedPosts[postId] = isLiked;
      newSavedPosts[postId] = isSaved;

      state = state.copyWith(
        likedPosts: newLikedPosts,
        savedPosts: newSavedPosts,
      );
    } catch (e) {
      state = state.copyWith(error: 'فشل في تحميل حالة التفاعل');
    }
  }

  // Listen to post stats updates
  void listenToPostStats(String postId) {
    InteractionService.getPostInteractionStats(postId).listen((stats) {
      final newPostStats = Map<String, Map<String, dynamic>>.from(state.postStats);
      newPostStats[postId] = stats;
      
      state = state.copyWith(postStats: newPostStats);
    });
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Get like status for post
  bool isPostLiked(String postId) {
    return state.likedPosts[postId] ?? false;
  }

  // Get save status for post
  bool isPostSaved(String postId) {
    return state.savedPosts[postId] ?? false;
  }

  // Get post stats
  Map<String, dynamic> getPostStats(String postId) {
    return state.postStats[postId] ?? {};
  }

  // Batch operations for better performance
  Future<void> batchLoadInteractionStatus(List<String> postIds) async {
    try {
      state = state.copyWith(isLoading: true);
      
      final futures = postIds.map((postId) async {
        final isLiked = await InteractionService.isPostLikedByUser(postId);
        final isSaved = await InteractionService.isPostSavedByUser(postId);
        return {
          'postId': postId,
          'isLiked': isLiked,
          'isSaved': isSaved,
        };
      });

      final results = await Future.wait(futures);
      
      final newLikedPosts = Map<String, bool>.from(state.likedPosts);
      final newSavedPosts = Map<String, bool>.from(state.savedPosts);
      
      for (final result in results) {
        newLikedPosts[result['postId']] = result['isLiked'];
        newSavedPosts[result['postId']] = result['isSaved'];
      }

      state = state.copyWith(
        likedPosts: newLikedPosts,
        savedPosts: newSavedPosts,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل في تحميل حالة التفاعلات',
      );
    }
  }
}

// Provider definitions
final interactionProvider = StateNotifierProvider<InteractionNotifier, InteractionState>((ref) {
  return InteractionNotifier();
});

// Specific providers for easier access
final likedPostsProvider = Provider<Map<String, bool>>((ref) {
  return ref.watch(interactionProvider).likedPosts;
});

final savedPostsProvider = Provider<Map<String, bool>>((ref) {
  return ref.watch(interactionProvider).savedPosts;
});

final postStatsProvider = Provider<Map<String, Map<String, dynamic>>>((ref) {
  return ref.watch(interactionProvider).postStats;
});

// Individual post providers
final postLikedProvider = Provider.family<bool, String>((ref, postId) {
  return ref.watch(interactionProvider).likedPosts[postId] ?? false;
});

final postSavedProvider = Provider.family<bool, String>((ref, postId) {
  return ref.watch(interactionProvider).savedPosts[postId] ?? false;
});

final postStatsStreamProvider = StreamProvider.family<Map<String, dynamic>, String>((ref, postId) {
  return InteractionService.getPostInteractionStats(postId);
});

// Trending posts provider
final trendingPostsProvider = FutureProvider.family<List<PostModel>, int>((ref, limit) {
  return InteractionService.getTrendingPosts(limit: limit);
});

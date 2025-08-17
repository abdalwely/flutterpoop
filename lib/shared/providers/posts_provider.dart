import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/post_model.dart';
import '../services/post_service.dart';

class PostsState {
  final List<PostModel> posts;
  final bool isLoading;
  final String? error;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  const PostsState({
    this.posts = const [],
    this.isLoading = false,
    this.error,
    this.lastDocument,
    this.hasMore = true,
  });

  PostsState copyWith({
    List<PostModel>? posts,
    bool? isLoading,
    String? error,
    DocumentSnapshot? lastDocument,
    bool? hasMore,
  }) {
    return PostsState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastDocument: lastDocument ?? this.lastDocument,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class PostsNotifier extends StateNotifier<PostsState> {
  final PostService _postService;

  PostsNotifier(this._postService) : super(const PostsState());

  Future<void> loadFeedPosts(String userId, {bool refresh = false}) async {
    if (refresh) {
      state = const PostsState(isLoading: true);
    } else if (state.isLoading || !state.hasMore) {
      return;
    }

    try {
      if (!refresh) {
        state = state.copyWith(isLoading: true);
      }

      final posts = await _postService.getFeedPosts(
        userId: userId,
        lastDocument: refresh ? null : state.lastDocument,
      );

      if (refresh) {
        state = PostsState(
          posts: posts,
          isLoading: false,
          hasMore: posts.length >= 10,
        );
      } else {
        state = state.copyWith(
          posts: [...state.posts, ...posts],
          isLoading: false,
          hasMore: posts.length >= 10,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> likePost(String postId, String userId) async {
    try {
      // Optimistic update
      _updatePostInState(postId, (post) {
        if (post.isLikedBy(userId)) return post;
        return post.copyWith(
          likedBy: [...post.likedBy, userId],
          likesCount: post.likesCount + 1,
        );
      });

      await _postService.likePost(postId, userId);
    } catch (e) {
      // Revert optimistic update on error
      _updatePostInState(postId, (post) {
        if (!post.isLikedBy(userId)) return post;
        final newLikedBy = List<String>.from(post.likedBy)..remove(userId);
        return post.copyWith(
          likedBy: newLikedBy,
          likesCount: post.likesCount - 1,
        );
      });
      rethrow;
    }
  }

  Future<void> unlikePost(String postId, String userId) async {
    try {
      // Optimistic update
      _updatePostInState(postId, (post) {
        if (!post.isLikedBy(userId)) return post;
        final newLikedBy = List<String>.from(post.likedBy)..remove(userId);
        return post.copyWith(
          likedBy: newLikedBy,
          likesCount: post.likesCount - 1,
        );
      });

      await _postService.unlikePost(postId, userId);
    } catch (e) {
      // Revert optimistic update on error
      _updatePostInState(postId, (post) {
        if (post.isLikedBy(userId)) return post;
        return post.copyWith(
          likedBy: [...post.likedBy, userId],
          likesCount: post.likesCount + 1,
        );
      });
      rethrow;
    }
  }

  Future<void> savePost(String postId, String userId) async {
    try {
      // Optimistic update
      _updatePostInState(postId, (post) {
        if (post.isSavedBy(userId)) return post;
        return post.copyWith(
          savedBy: [...post.savedBy, userId],
        );
      });

      await _postService.savePost(postId, userId);
    } catch (e) {
      // Revert optimistic update on error
      _updatePostInState(postId, (post) {
        if (!post.isSavedBy(userId)) return post;
        final newSavedBy = List<String>.from(post.savedBy)..remove(userId);
        return post.copyWith(savedBy: newSavedBy);
      });
      rethrow;
    }
  }

  Future<void> unsavePost(String postId, String userId) async {
    try {
      // Optimistic update
      _updatePostInState(postId, (post) {
        if (!post.isSavedBy(userId)) return post;
        final newSavedBy = List<String>.from(post.savedBy)..remove(userId);
        return post.copyWith(savedBy: newSavedBy);
      });

      await _postService.unsavePost(postId, userId);
    } catch (e) {
      // Revert optimistic update on error
      _updatePostInState(postId, (post) {
        if (post.isSavedBy(userId)) return post;
        return post.copyWith(
          savedBy: [...post.savedBy, userId],
        );
      });
      rethrow;
    }
  }

  Future<void> sharePost(String postId, String userId) async {
    try {
      await _postService.sharePost(postId, userId);
      
      // Update share count
      _updatePostInState(postId, (post) {
        return post.copyWith(
          sharesCount: post.sharesCount + 1,
        );
      });
    } catch (e) {
      // Handle error
      state = state.copyWith(error: 'خطأ في مشاركة المنشور');
    }
  }

  Future<void> deletePost(String postId, String userId) async {
    try {
      await _postService.deletePost(postId, userId);
      
      // Remove post from state
      final updatedPosts = state.posts.where((post) => post.id != postId).toList();
      state = state.copyWith(posts: updatedPosts);
    } catch (e) {
      state = state.copyWith(error: 'خطأ في حذف المنشور');
    }
  }

  void _updatePostInState(String postId, PostModel Function(PostModel) updateFunction) {
    final updatedPosts = state.posts.map((post) {
      if (post.id == postId) {
        return updateFunction(post);
      }
      return post;
    }).toList();

    state = state.copyWith(posts: updatedPosts);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void addNewPost(PostModel post) {
    state = state.copyWith(posts: [post, ...state.posts]);
  }

  void updatePost(PostModel updatedPost) {
    _updatePostInState(updatedPost.id, (_) => updatedPost);
  }
}

// User Posts State and Notifier
class UserPostsNotifier extends StateNotifier<PostsState> {
  final PostService _postService;

  UserPostsNotifier(this._postService) : super(const PostsState());

  Future<void> loadUserPosts(String userId, {bool refresh = false}) async {
    if (refresh) {
      state = const PostsState(isLoading: true);
    } else if (state.isLoading || !state.hasMore) {
      return;
    }

    try {
      if (!refresh) {
        state = state.copyWith(isLoading: true);
      }

      final posts = await _postService.getUserPosts(
        userId: userId,
        lastDocument: refresh ? null : state.lastDocument,
      );

      if (refresh) {
        state = PostsState(
          posts: posts,
          isLoading: false,
          hasMore: posts.length >= 12,
        );
      } else {
        state = state.copyWith(
          posts: [...state.posts, ...posts],
          isLoading: false,
          hasMore: posts.length >= 12,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

// Saved Posts State and Notifier
class SavedPostsNotifier extends StateNotifier<PostsState> {
  final PostService _postService;

  SavedPostsNotifier(this._postService) : super(const PostsState());

  Future<void> loadSavedPosts(String userId, {bool refresh = false}) async {
    if (refresh) {
      state = const PostsState(isLoading: true);
    } else if (state.isLoading || !state.hasMore) {
      return;
    }

    try {
      if (!refresh) {
        state = state.copyWith(isLoading: true);
      }

      final posts = await _postService.getSavedPosts(
        userId: userId,
        lastDocument: refresh ? null : state.lastDocument,
      );

      if (refresh) {
        state = PostsState(
          posts: posts,
          isLoading: false,
          hasMore: posts.length >= 12,
        );
      } else {
        state = state.copyWith(
          posts: [...state.posts, ...posts],
          isLoading: false,
          hasMore: posts.length >= 12,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

// Providers
final postServiceProvider = Provider<PostService>((ref) {
  return PostService();
});

final postsProvider = StateNotifierProvider<PostsNotifier, PostsState>((ref) {
  final postService = ref.read(postServiceProvider);
  return PostsNotifier(postService);
});

final userPostsProvider = StateNotifierProvider.family<UserPostsNotifier, PostsState, String>((ref, userId) {
  final postService = ref.read(postServiceProvider);
  return UserPostsNotifier(postService);
});

final savedPostsProvider = StateNotifierProvider<SavedPostsNotifier, PostsState>((ref) {
  final postService = ref.read(postServiceProvider);
  return SavedPostsNotifier(postService);
});

// Single Post Provider
final singlePostProvider = FutureProvider.family<PostModel?, String>((ref, postId) async {
  final postService = ref.read(postServiceProvider);
  return await postService.getPostById(postId);
});

// Post Stream Provider
final postStreamProvider = StreamProvider.family<PostModel?, String>((ref, postId) {
  final postService = ref.read(postServiceProvider);
  return postService.getPostStream(postId);
});

// Trending Posts Provider
final trendingPostsProvider = FutureProvider<List<PostModel>>((ref) async {
  final postService = ref.read(postServiceProvider);
  return await postService.getTrendingPosts();
});

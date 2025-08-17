import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/follow_service.dart';
import '../models/user_model.dart';

class FollowState {
  final Map<String, bool> followingStatus;
  final Map<String, Map<String, dynamic>> followStats;
  final List<UserModel> suggestions;
  final List<UserModel> followRequests;
  final bool isLoading;
  final String? error;

  const FollowState({
    this.followingStatus = const {},
    this.followStats = const {},
    this.suggestions = const [],
    this.followRequests = const [],
    this.isLoading = false,
    this.error,
  });

  FollowState copyWith({
    Map<String, bool>? followingStatus,
    Map<String, Map<String, dynamic>>? followStats,
    List<UserModel>? suggestions,
    List<UserModel>? followRequests,
    bool? isLoading,
    String? error,
  }) {
    return FollowState(
      followingStatus: followingStatus ?? this.followingStatus,
      followStats: followStats ?? this.followStats,
      suggestions: suggestions ?? this.suggestions,
      followRequests: followRequests ?? this.followRequests,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class FollowNotifier extends StateNotifier<FollowState> {
  FollowNotifier() : super(const FollowState());

  // Toggle follow with optimistic update
  Future<void> toggleFollow(String userId) async {
    final currentStatus = state.followingStatus[userId] ?? false;
    final currentStats = state.followStats[userId] ?? {'followersCount': 0, 'followingCount': 0};

    // Optimistic update
    final newFollowingStatus = Map<String, bool>.from(state.followingStatus);
    final newFollowStats = Map<String, Map<String, dynamic>>.from(state.followStats);
    
    newFollowingStatus[userId] = !currentStatus;
    newFollowStats[userId] = {
      ...currentStats,
      'followersCount': currentStatus 
          ? (currentStats['followersCount'] as int) - 1
          : (currentStats['followersCount'] as int) + 1,
    };

    state = state.copyWith(
      followingStatus: newFollowingStatus,
      followStats: newFollowStats,
    );

    try {
      final actualResult = await FollowService.toggleFollow(userId);
      
      // Update with actual result if different
      if (actualResult != newFollowingStatus[userId]) {
        newFollowingStatus[userId] = actualResult;
        newFollowStats[userId] = {
          ...newFollowStats[userId]!,
          'followersCount': actualResult 
              ? (currentStats['followersCount'] as int) + 1
              : (currentStats['followersCount'] as int) - 1,
        };
        
        state = state.copyWith(
          followingStatus: newFollowingStatus,
          followStats: newFollowStats,
        );
      }
    } catch (e) {
      // Revert optimistic update on error
      final revertedFollowingStatus = Map<String, bool>.from(state.followingStatus);
      final revertedFollowStats = Map<String, Map<String, dynamic>>.from(state.followStats);
      
      revertedFollowingStatus[userId] = currentStatus;
      revertedFollowStats[userId] = currentStats;
      
      state = state.copyWith(
        followingStatus: revertedFollowingStatus,
        followStats: revertedFollowStats,
        error: 'فشل في تحديث المتابعة',
      );
    }
  }

  // Load follow status for a user
  Future<void> loadFollowStatus(String userId) async {
    try {
      final isFollowing = await FollowService.isFollowing(userId);
      final stats = await FollowService.getFollowStats(userId);

      final newFollowingStatus = Map<String, bool>.from(state.followingStatus);
      final newFollowStats = Map<String, Map<String, dynamic>>.from(state.followStats);
      
      newFollowingStatus[userId] = isFollowing;
      newFollowStats[userId] = stats;

      state = state.copyWith(
        followingStatus: newFollowingStatus,
        followStats: newFollowStats,
      );
    } catch (e) {
      state = state.copyWith(error: 'فشل في تحميل حالة المتابعة');
    }
  }

  // Load follow suggestions
  Future<void> loadFollowSuggestions({int limit = 10}) async {
    try {
      state = state.copyWith(isLoading: true);
      
      final suggestions = await FollowService.getFollowSuggestions(limit: limit);
      
      state = state.copyWith(
        suggestions: suggestions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل في تحميل اقتراحات المتابعة',
      );
    }
  }

  // Load follow requests
  Future<void> loadFollowRequests() async {
    try {
      state = state.copyWith(isLoading: true);
      
      final requests = await FollowService.getFollowRequests();
      
      state = state.copyWith(
        followRequests: requests,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل في تحميل طلبات المتابعة',
      );
    }
  }

  // Remove follower
  Future<void> removeFollower(String followerId) async {
    try {
      final success = await FollowService.removeFollower(followerId);
      
      if (success) {
        // Update local state if needed
        state = state.copyWith(error: null);
      } else {
        state = state.copyWith(error: 'فشل في إزالة المتابع');
      }
    } catch (e) {
      state = state.copyWith(error: 'فشل في إزالة المتابع');
    }
  }

  // Block user
  Future<void> blockUser(String userId) async {
    try {
      final success = await FollowService.blockUser(userId);
      
      if (success) {
        // Remove from following status
        final newFollowingStatus = Map<String, bool>.from(state.followingStatus);
        newFollowingStatus.remove(userId);
        
        state = state.copyWith(
          followingStatus: newFollowingStatus,
          error: null,
        );
      } else {
        state = state.copyWith(error: 'فشل في حظر المستخدم');
      }
    } catch (e) {
      state = state.copyWith(error: 'فشل في حظر المستخدم');
    }
  }

  // Search users
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      return await FollowService.searchUsers(query);
    } catch (e) {
      state = state.copyWith(error: 'فشل في البحث عن المستخدمين');
      return [];
    }
  }

  // Batch load follow status for multiple users
  Future<void> batchLoadFollowStatus(List<String> userIds) async {
    try {
      state = state.copyWith(isLoading: true);
      
      final futures = userIds.map((userId) async {
        final isFollowing = await FollowService.isFollowing(userId);
        final stats = await FollowService.getFollowStats(userId);
        return {
          'userId': userId,
          'isFollowing': isFollowing,
          'stats': stats,
        };
      });

      final results = await Future.wait(futures);
      
      final newFollowingStatus = Map<String, bool>.from(state.followingStatus);
      final newFollowStats = Map<String, Map<String, dynamic>>.from(state.followStats);
      
      for (final result in results) {
        newFollowingStatus[result['userId']] = result['isFollowing'];
        newFollowStats[result['userId']] = result['stats'];
      }

      state = state.copyWith(
        followingStatus: newFollowingStatus,
        followStats: newFollowStats,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل في تحميل حالة المتابعة',
      );
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Get follow status for user
  bool isFollowing(String userId) {
    return state.followingStatus[userId] ?? false;
  }

  // Get follow stats for user
  Map<String, dynamic> getFollowStats(String userId) {
    return state.followStats[userId] ?? {'followersCount': 0, 'followingCount': 0};
  }

  // Refresh suggestions
  Future<void> refreshSuggestions() async {
    await loadFollowSuggestions();
  }

  // Batch follow multiple users
  Future<void> batchFollowUsers(List<String> userIds) async {
    try {
      state = state.copyWith(isLoading: true);
      
      await FollowService.batchFollowUsers(userIds);
      
      // Update local state
      final newFollowingStatus = Map<String, bool>.from(state.followingStatus);
      for (final userId in userIds) {
        newFollowingStatus[userId] = true;
      }
      
      state = state.copyWith(
        followingStatus: newFollowingStatus,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل في متابعة المستخدمين',
      );
    }
  }
}

// Provider definitions
final followProvider = StateNotifierProvider<FollowNotifier, FollowState>((ref) {
  return FollowNotifier();
});

// Specific providers for easier access
final followingStatusProvider = Provider<Map<String, bool>>((ref) {
  return ref.watch(followProvider).followingStatus;
});

final followStatsProvider = Provider<Map<String, Map<String, dynamic>>>((ref) {
  return ref.watch(followProvider).followStats;
});

final followSuggestionsProvider = Provider<List<UserModel>>((ref) {
  return ref.watch(followProvider).suggestions;
});

final followRequestsProvider = Provider<List<UserModel>>((ref) {
  return ref.watch(followProvider).followRequests;
});

// Individual user providers
final userFollowStatusProvider = Provider.family<bool, String>((ref, userId) {
  return ref.watch(followProvider).followingStatus[userId] ?? false;
});

final userFollowStatsProvider = Provider.family<Map<String, dynamic>, String>((ref, userId) {
  return ref.watch(followProvider).followStats[userId] ?? {'followersCount': 0, 'followingCount': 0};
});

// Stream providers for real-time updates
final followersListProvider = StreamProvider.family<List<UserModel>, String>((ref, userId) async* {
  // This would be implemented with a real-time stream from Firestore
  yield await FollowService.getFollowers(userId);
});

final followingListProvider = StreamProvider.family<List<UserModel>, String>((ref, userId) async* {
  // This would be implemented with a real-time stream from Firestore
  yield await FollowService.getFollowing(userId);
});

final mutualFollowersProvider = FutureProvider.family<List<UserModel>, String>((ref, userId) {
  return FollowService.getMutualFollowers(userId);
});

// Search provider
final userSearchProvider = FutureProvider.family<List<UserModel>, String>((ref, query) {
  if (query.isEmpty) return Future.value([]);
  return FollowService.searchUsers(query);
});

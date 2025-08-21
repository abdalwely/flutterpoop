import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/reel_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/follow_service.dart';
import 'auth_provider.dart';

class ReelsState {
  final bool isLoading;
  final List<ReelModel> reels;
  final String? error;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;
  final int currentIndex;

  const ReelsState({
    this.isLoading = false,
    this.reels = const [],
    this.error,
    this.hasMore = true,
    this.lastDocument,
    this.currentIndex = 0,
  });

  ReelsState copyWith({
    bool? isLoading,
    List<ReelModel>? reels,
    String? error,
    bool? hasMore,
    DocumentSnapshot? lastDocument,
    int? currentIndex,
  }) {
    return ReelsState(
      isLoading: isLoading ?? this.isLoading,
      reels: reels ?? this.reels,
      error: error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      lastDocument: lastDocument ?? this.lastDocument,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

class ReelsNotifier extends StateNotifier<ReelsState> {
  final FirestoreService _firestoreService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ReelsNotifier(this._firestoreService) : super(const ReelsState());

  // Load initial reels
  Future<void> loadReels() async {
    if (state.isLoading) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      final String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get following list for personalized feed
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      final List<String> following = userDoc.exists 
          ? List<String>.from(userDoc.data()!['following'] ?? [])
          : [];

      Query query = _firestore
          .collection('reels')
          .where('isDeleted', isEqualTo: false)
          .where('isArchived', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(10);

      // If user follows people, prioritize their reels
      if (following.isNotEmpty) {
        // Mix of following and discover content
        final followingReels = await _firestore
            .collection('reels')
            .where('userId', whereIn: following.take(10).toList())
            .where('isDeleted', isEqualTo: false)
            .orderBy('createdAt', descending: true)
            .limit(5)
            .get();

        final discoverReels = await _firestore
            .collection('reels')
            .where('isDeleted', isEqualTo: false)
            .where('isTrending', isEqualTo: true)
            .orderBy('viewsCount', descending: true)
            .limit(5)
            .get();

        Set<String> addedReelIds = {};
        List<ReelModel> allReels = [];

        // Add following reels first
        for (final doc in followingReels.docs) {
          final reel = ReelModel.fromFirestore(doc);
          allReels.add(reel);
          addedReelIds.add(reel.id);
        }

        // Add discover reels
        for (final doc in discoverReels.docs) {
          if (!addedReelIds.contains(doc.id)) {
            allReels.add(ReelModel.fromFirestore(doc));
          }
        }

        // Sort by engagement and recency
        allReels.sort((a, b) {
          final aScore = _calculateEngagementScore(a);
          final bScore = _calculateEngagementScore(b);
          return bScore.compareTo(aScore);
        });

        state = state.copyWith(
          isLoading: false,
          reels: allReels,
          hasMore: allReels.length >= 10,
          lastDocument: allReels.isNotEmpty ? discoverReels.docs.lastOrNull : null,
        );
      } else {
        // Load general trending reels for new users
        final snapshot = await query.get();
        final reels = snapshot.docs.map((doc) => ReelModel.fromFirestore(doc)).toList();

        state = state.copyWith(
          isLoading: false,
          reels: reels,
          hasMore: reels.length >= 10,
          lastDocument: snapshot.docs.lastOrNull,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل في تحميل الريلز: ${e.toString()}',
      );
    }
  }

  // Load more reels (pagination)
  Future<void> loadMoreReels() async {
    if (state.isLoading || !state.hasMore || state.lastDocument == null) return;

    try {
      state = state.copyWith(isLoading: true);

      final query = _firestore
          .collection('reels')
          .where('isDeleted', isEqualTo: false)
          .where('isArchived', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .startAfterDocument(state.lastDocument!)
          .limit(10);

      final snapshot = await query.get();
      final newReels = snapshot.docs.map((doc) => ReelModel.fromFirestore(doc)).toList();

      state = state.copyWith(
        isLoading: false,
        reels: [...state.reels, ...newReels],
        hasMore: newReels.length >= 10,
        lastDocument: snapshot.docs.lastOrNull,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل في تحميل المزيد من الريلز: ${e.toString()}',
      );
    }
  }

  // Toggle like on reel
  Future<void> toggleLike(String reelId) async {
    try {
      final String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      final reelIndex = state.reels.indexWhere((reel) => reel.id == reelId);
      if (reelIndex == -1) return;

      final reel = state.reels[reelIndex];
      final isLiked = reel.isLikedBy(currentUserId);

      // Optimistic update
      List<String> newLikedBy = List.from(reel.likedBy);
      int newLikesCount = reel.likesCount;

      if (isLiked) {
        newLikedBy.remove(currentUserId);
        newLikesCount = (newLikesCount - 1).clamp(0, double.infinity).toInt();
      } else {
        newLikedBy.add(currentUserId);
        newLikesCount++;
      }

      final updatedReel = reel.copyWith(
        likedBy: newLikedBy,
        likesCount: newLikesCount,
      );

      final updatedReels = List<ReelModel>.from(state.reels);
      updatedReels[reelIndex] = updatedReel;

      state = state.copyWith(reels: updatedReels);

      // Update in Firestore
      await _firestore.runTransaction((transaction) async {
        final reelRef = _firestore.collection('reels').doc(reelId);
        final reelSnapshot = await transaction.get(reelRef);

        if (reelSnapshot.exists) {
          final currentLikedBy = List<String>.from(reelSnapshot.data()!['likedBy'] ?? []);
          final currentLikesCount = reelSnapshot.data()!['likesCount'] ?? 0;

          if (isLiked) {
            currentLikedBy.remove(currentUserId);
            transaction.update(reelRef, {
              'likedBy': currentLikedBy,
              'likesCount': (currentLikesCount - 1).clamp(0, double.infinity),
            });
          } else {
            if (!currentLikedBy.contains(currentUserId)) {
              currentLikedBy.add(currentUserId);
              transaction.update(reelRef, {
                'likedBy': currentLikedBy,
                'likesCount': currentLikesCount + 1,
              });

              // Add like notification
              if (reel.userId != currentUserId) {
                await _addLikeNotification(reel.userId, currentUserId, reelId);
              }
            }
          }
        }
      });
    } catch (e) {
      // Revert optimistic update on error
      await loadReels();
      print('Error toggling like: $e');
    }
  }

  // Toggle save on reel
  Future<void> toggleSave(String reelId) async {
    try {
      final String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      final reelIndex = state.reels.indexWhere((reel) => reel.id == reelId);
      if (reelIndex == -1) return;

      final reel = state.reels[reelIndex];
      final isSaved = reel.isSavedBy(currentUserId);

      // Optimistic update
      List<String> newSavedBy = List.from(reel.savedBy);

      if (isSaved) {
        newSavedBy.remove(currentUserId);
      } else {
        newSavedBy.add(currentUserId);
      }

      final updatedReel = reel.copyWith(savedBy: newSavedBy);
      final updatedReels = List<ReelModel>.from(state.reels);
      updatedReels[reelIndex] = updatedReel;

      state = state.copyWith(reels: updatedReels);

      // Update in Firestore
      await _firestore.collection('reels').doc(reelId).update({
        'savedBy': newSavedBy,
      });

      // Also update user's saved reels collection
      final userSavedRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('savedReels')
          .doc(reelId);

      if (isSaved) {
        await userSavedRef.delete();
      } else {
        await userSavedRef.set({
          'reelId': reelId,
          'savedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Revert optimistic update on error
      await loadReels();
      print('Error toggling save: $e');
    }
  }

  // Increment view count
  Future<void> incrementView(String reelId) async {
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

        // Update local state
        final reelIndex = state.reels.indexWhere((reel) => reel.id == reelId);
        if (reelIndex != -1) {
          final reel = state.reels[reelIndex];
          final updatedReel = reel.copyWith(viewsCount: reel.viewsCount + 1);
          final updatedReels = List<ReelModel>.from(state.reels);
          updatedReels[reelIndex] = updatedReel;
          state = state.copyWith(reels: updatedReels);
        }
      }
    } catch (e) {
      print('Error incrementing view: $e');
    }
  }

  // Follow/unfollow user from reel
  Future<void> toggleFollow(String userId) async {
    try {
      final String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null || userId == currentUserId) return;

      final isFollowing = await FollowService.isFollowing(userId);
      await FollowService.toggleFollow(userId);

      // Update reel state to reflect follow change
      await loadReels();
    } catch (e) {
      print('Error toggling follow: $e');
    }
  }

  // Share reel
  Future<void> shareReel(String reelId) async {
    try {
      final String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      // Increment share count
      await _firestore.collection('reels').doc(reelId).update({
        'sharesCount': FieldValue.increment(1),
        'sharedBy': FieldValue.arrayUnion([currentUserId]),
      });

      // Update local state
      final reelIndex = state.reels.indexWhere((reel) => reel.id == reelId);
      if (reelIndex != -1) {
        final reel = state.reels[reelIndex];
        final updatedReel = reel.copyWith(
          sharesCount: reel.sharesCount + 1,
          sharedBy: [...reel.sharedBy, currentUserId],
        );
        final updatedReels = List<ReelModel>.from(state.reels);
        updatedReels[reelIndex] = updatedReel;
        state = state.copyWith(reels: updatedReels);
      }

      // Add share analytics
      await _firestore.collection('analytics').add({
        'type': 'reel_share',
        'reelId': reelId,
        'userId': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sharing reel: $e');
    }
  }

  // Set current reel index
  void setCurrentIndex(int index) {
    state = state.copyWith(currentIndex: index);
    
    // Auto-load more when near the end
    if (index >= state.reels.length - 3) {
      loadMoreReels();
    }

    // Increment view for current reel
    if (index < state.reels.length) {
      incrementView(state.reels[index].id);
    }
  }

  // Get user reels
  Future<List<ReelModel>> getUserReels(String userId) async {
    try {
      final query = _firestore
          .collection('reels')
          .where('userId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: false)
          .where('isArchived', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(20);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => ReelModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting user reels: $e');
      return [];
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Refresh reels
  Future<void> refreshReels() async {
    state = const ReelsState();
    await loadReels();
  }

  // Helper methods
  double _calculateEngagementScore(ReelModel reel) {
    final views = reel.viewsCount.toDouble();
    final likes = reel.likesCount.toDouble();
    final comments = reel.commentsCount.toDouble();
    final shares = reel.sharesCount.toDouble();

    if (views == 0) return 0;

    final likeRate = likes / views;
    final commentRate = comments / views;
    final shareRate = shares / views;
    
    // Weight factors
    final score = (likeRate * 1.0) + (commentRate * 2.0) + (shareRate * 3.0);
    
    // Factor in recency (newer content gets slight boost)
    final hoursSinceCreation = DateTime.now().difference(reel.createdAt).inHours;
    final recencyBoost = 1.0 / (1.0 + (hoursSinceCreation / 24.0));
    
    return score * (1.0 + recencyBoost * 0.1);
  }

  Future<void> _addLikeNotification(String targetUserId, String fromUserId, String reelId) async {
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
}

// Providers
final reelsProvider = StateNotifierProvider<ReelsNotifier, ReelsState>((ref) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return ReelsNotifier(firestoreService);
});

// Provider for user's reels
final userReelsProvider = FutureProvider.family<List<ReelModel>, String>((ref, userId) async {
  final reelsNotifier = ref.read(reelsProvider.notifier);
  return await reelsNotifier.getUserReels(userId);
});

// Provider for checking follow status
final followStatusProvider = FutureProvider.family<bool, String>((ref, userId) async {
  return await FollowService.isFollowing(userId);
});

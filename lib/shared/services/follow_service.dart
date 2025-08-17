import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class FollowService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Follow/Unfollow user
  static Future<bool> toggleFollow(String targetUserId) async {
    try {
      final String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null || currentUserId == targetUserId) return false;

      return await _firestore.runTransaction((transaction) async {
        final currentUserRef = _firestore.collection('users').doc(currentUserId);
        final targetUserRef = _firestore.collection('users').doc(targetUserId);

        final currentUserSnapshot = await transaction.get(currentUserRef);
        final targetUserSnapshot = await transaction.get(targetUserRef);

        if (!currentUserSnapshot.exists || !targetUserSnapshot.exists) {
          throw Exception('User not found');
        }

        final currentUserData = currentUserSnapshot.data()!;
        final targetUserData = targetUserSnapshot.data()!;

        final List<String> currentUserFollowing = 
            List<String>.from(currentUserData['following'] ?? []);
        final List<String> targetUserFollowers = 
            List<String>.from(targetUserData['followers'] ?? []);

        bool isFollowing = currentUserFollowing.contains(targetUserId);

        if (isFollowing) {
          // Unfollow
          currentUserFollowing.remove(targetUserId);
          targetUserFollowers.remove(currentUserId);
        } else {
          // Follow
          currentUserFollowing.add(targetUserId);
          targetUserFollowers.add(currentUserId);

          // Add follow notification
          await _addFollowNotification(targetUserId, currentUserId);
        }

        // Update current user's following list
        transaction.update(currentUserRef, {
          'following': currentUserFollowing,
          'followingCount': currentUserFollowing.length,
        });

        // Update target user's followers list
        transaction.update(targetUserRef, {
          'followers': targetUserFollowers,
          'followersCount': targetUserFollowers.length,
        });

        return !isFollowing; // Return new follow status
      });
    } catch (e) {
      print('Error toggling follow: $e');
      return false;
    }
  }

  // Check if current user follows target user
  static Future<bool> isFollowing(String targetUserId) async {
    try {
      final String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      final userSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      if (!userSnapshot.exists) return false;

      final userData = userSnapshot.data()!;
      final List<String> following = List<String>.from(userData['following'] ?? []);
      
      return following.contains(targetUserId);
    } catch (e) {
      print('Error checking follow status: $e');
      return false;
    }
  }

  // Get followers list with pagination
  static Future<List<UserModel>> getFollowers(
    String userId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('follows')
          .where('followingId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      List<UserModel> followers = [];

      for (final doc in snapshot.docs) {
        final followData = doc.data() as Map<String, dynamic>;
        final followerId = followData['followerId'];
        
        final userSnapshot = await _firestore
            .collection('users')
            .doc(followerId)
            .get();

        if (userSnapshot.exists) {
          followers.add(UserModel.fromFirestore(userSnapshot));
        }
      }

      return followers;
    } catch (e) {
      print('Error getting followers: $e');
      return [];
    }
  }

  // Get following list with pagination
  static Future<List<UserModel>> getFollowing(
    String userId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('follows')
          .where('followerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      List<UserModel> following = [];

      for (final doc in snapshot.docs) {
        final followData = doc.data() as Map<String, dynamic>;
        final followingId = followData['followingId'];
        
        final userSnapshot = await _firestore
            .collection('users')
            .doc(followingId)
            .get();

        if (userSnapshot.exists) {
          following.add(UserModel.fromFirestore(userSnapshot));
        }
      }

      return following;
    } catch (e) {
      print('Error getting following: $e');
      return [];
    }
  }

  // Get mutual followers
  static Future<List<UserModel>> getMutualFollowers(String targetUserId) async {
    try {
      final String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return [];

      final currentUserSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      final targetUserSnapshot = await _firestore
          .collection('users')
          .doc(targetUserId)
          .get();

      if (!currentUserSnapshot.exists || !targetUserSnapshot.exists) {
        return [];
      }

      final currentUserFollowing = List<String>.from(
          currentUserSnapshot.data()!['following'] ?? []);
      final targetUserFollowers = List<String>.from(
          targetUserSnapshot.data()!['followers'] ?? []);

      final mutualUserIds = currentUserFollowing
          .where((id) => targetUserFollowers.contains(id))
          .toList();

      List<UserModel> mutualUsers = [];
      for (final userId in mutualUserIds.take(10)) {
        final userSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .get();

        if (userSnapshot.exists) {
          mutualUsers.add(UserModel.fromFirestore(userSnapshot));
        }
      }

      return mutualUsers;
    } catch (e) {
      print('Error getting mutual followers: $e');
      return [];
    }
  }

  // Get follow suggestions based on mutual connections
  static Future<List<UserModel>> getFollowSuggestions({int limit = 10}) async {
    try {
      final String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return [];

      final currentUserSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      if (!currentUserSnapshot.exists) return [];

      final currentUserData = currentUserSnapshot.data()!;
      final List<String> following = List<String>.from(currentUserData['following'] ?? []);
      final List<String> followers = List<String>.from(currentUserData['followers'] ?? []);

      // Get users followed by people the current user follows
      Map<String, int> suggestions = {};

      for (final followedUserId in following.take(20)) {
        final followedUserSnapshot = await _firestore
            .collection('users')
            .doc(followedUserId)
            .get();

        if (followedUserSnapshot.exists) {
          final followedUserFollowing = List<String>.from(
              followedUserSnapshot.data()!['following'] ?? []);

          for (final suggestedUserId in followedUserFollowing) {
            if (suggestedUserId != currentUserId && 
                !following.contains(suggestedUserId)) {
              suggestions[suggestedUserId] = (suggestions[suggestedUserId] ?? 0) + 1;
            }
          }
        }
      }

      // Sort by connection strength
      final sortedSuggestions = suggestions.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      List<UserModel> suggestedUsers = [];
      for (final entry in sortedSuggestions.take(limit)) {
        final userSnapshot = await _firestore
            .collection('users')
            .doc(entry.key)
            .get();

        if (userSnapshot.exists) {
          suggestedUsers.add(UserModel.fromFirestore(userSnapshot));
        }
      }

      return suggestedUsers;
    } catch (e) {
      print('Error getting follow suggestions: $e');
      return [];
    }
  }

  // Get follow statistics
  static Future<Map<String, dynamic>> getFollowStats(String userId) async {
    try {
      final userSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userSnapshot.exists) {
        return {'followersCount': 0, 'followingCount': 0};
      }

      final userData = userSnapshot.data()!;
      return {
        'followersCount': userData['followersCount'] ?? 0,
        'followingCount': userData['followingCount'] ?? 0,
      };
    } catch (e) {
      print('Error getting follow stats: $e');
      return {'followersCount': 0, 'followingCount': 0};
    }
  }

  // Search users
  static Future<List<UserModel>> searchUsers(
    String query, {
    int limit = 20,
    String? excludeUserId,
  }) async {
    try {
      if (query.isEmpty) return [];

      final String? currentUserId = _auth.currentUser?.uid;
      
      // Search by username and display name
      final usernameQuery = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('username', isLessThan: '${query.toLowerCase()}z')
          .limit(limit)
          .get();

      final displayNameQuery = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThan: '${query}z')
          .limit(limit)
          .get();

      Set<String> userIds = {};
      List<UserModel> users = [];

      // Process username results
      for (final doc in usernameQuery.docs) {
        if (doc.id != currentUserId && doc.id != excludeUserId) {
          userIds.add(doc.id);
          users.add(UserModel.fromFirestore(doc));
        }
      }

      // Process display name results
      for (final doc in displayNameQuery.docs) {
        if (doc.id != currentUserId && 
            doc.id != excludeUserId && 
            !userIds.contains(doc.id)) {
          users.add(UserModel.fromFirestore(doc));
        }
      }

      return users.take(limit).toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // Remove follower
  static Future<bool> removeFollower(String followerId) async {
    try {
      final String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      return await _firestore.runTransaction((transaction) async {
        final currentUserRef = _firestore.collection('users').doc(currentUserId);
        final followerRef = _firestore.collection('users').doc(followerId);

        final currentUserSnapshot = await transaction.get(currentUserRef);
        final followerSnapshot = await transaction.get(followerRef);

        if (!currentUserSnapshot.exists || !followerSnapshot.exists) {
          throw Exception('User not found');
        }

        final currentUserData = currentUserSnapshot.data()!;
        final followerData = followerSnapshot.data()!;

        final List<String> currentUserFollowers = 
            List<String>.from(currentUserData['followers'] ?? []);
        final List<String> followerFollowing = 
            List<String>.from(followerData['following'] ?? []);

        // Remove follower
        currentUserFollowers.remove(followerId);
        followerFollowing.remove(currentUserId);

        // Update current user's followers list
        transaction.update(currentUserRef, {
          'followers': currentUserFollowers,
          'followersCount': currentUserFollowers.length,
        });

        // Update follower's following list
        transaction.update(followerRef, {
          'following': followerFollowing,
          'followingCount': followerFollowing.length,
        });

        return true;
      });
    } catch (e) {
      print('Error removing follower: $e');
      return false;
    }
  }

  // Block user
  static Future<bool> blockUser(String targetUserId) async {
    try {
      final String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      await _firestore.runTransaction((transaction) async {
        final currentUserRef = _firestore.collection('users').doc(currentUserId);
        final targetUserRef = _firestore.collection('users').doc(targetUserId);

        final currentUserSnapshot = await transaction.get(currentUserRef);
        final targetUserSnapshot = await transaction.get(targetUserRef);

        if (!currentUserSnapshot.exists || !targetUserSnapshot.exists) {
          throw Exception('User not found');
        }

        final currentUserData = currentUserSnapshot.data()!;
        final targetUserData = targetUserSnapshot.data()!;

        // Get current lists
        final List<String> currentUserBlocked = 
            List<String>.from(currentUserData['blocked'] ?? []);
        final List<String> currentUserFollowing = 
            List<String>.from(currentUserData['following'] ?? []);
        final List<String> currentUserFollowers = 
            List<String>.from(currentUserData['followers'] ?? []);
        
        final List<String> targetUserFollowing = 
            List<String>.from(targetUserData['following'] ?? []);
        final List<String> targetUserFollowers = 
            List<String>.from(targetUserData['followers'] ?? []);

        // Add to blocked list
        if (!currentUserBlocked.contains(targetUserId)) {
          currentUserBlocked.add(targetUserId);
        }

        // Remove from following/followers
        currentUserFollowing.remove(targetUserId);
        currentUserFollowers.remove(targetUserId);
        targetUserFollowing.remove(currentUserId);
        targetUserFollowers.remove(currentUserId);

        // Update current user
        transaction.update(currentUserRef, {
          'blocked': currentUserBlocked,
          'following': currentUserFollowing,
          'followers': currentUserFollowers,
          'followingCount': currentUserFollowing.length,
          'followersCount': currentUserFollowers.length,
        });

        // Update target user
        transaction.update(targetUserRef, {
          'following': targetUserFollowing,
          'followers': targetUserFollowers,
          'followingCount': targetUserFollowing.length,
          'followersCount': targetUserFollowers.length,
        });
      });

      return true;
    } catch (e) {
      print('Error blocking user: $e');
      return false;
    }
  }

  // Get follow activity
  static Stream<List<Map<String, dynamic>>> getFollowActivity(String userId) {
    return _firestore
        .collection('follows')
        .where('followingId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'id': doc.id,
        };
      }).toList();
    });
  }

  // Private helper methods
  static Future<void> _addFollowNotification(String targetUserId, String followerId) async {
    await _firestore.collection('notifications').add({
      'id': _firestore.collection('notifications').doc().id,
      'userId': targetUserId,
      'fromUserId': followerId,
      'type': 'follow',
      'message': 'بدأ بمتابعتك',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Batch follow operations
  static Future<void> batchFollowUsers(List<String> userIds) async {
    try {
      final String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      final batch = _firestore.batch();

      for (final userId in userIds) {
        if (userId != currentUserId) {
          // Add to current user's following
          final currentUserRef = _firestore.collection('users').doc(currentUserId);
          batch.update(currentUserRef, {
            'following': FieldValue.arrayUnion([userId]),
            'followingCount': FieldValue.increment(1),
          });

          // Add to target user's followers
          final targetUserRef = _firestore.collection('users').doc(userId);
          batch.update(targetUserRef, {
            'followers': FieldValue.arrayUnion([currentUserId]),
            'followersCount': FieldValue.increment(1),
          });
        }
      }

      await batch.commit();
    } catch (e) {
      print('Error batch following users: $e');
    }
  }

  // Get follow requests (for private accounts)
  static Future<List<UserModel>> getFollowRequests() async {
    try {
      final String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return [];

      final snapshot = await _firestore
          .collection('followRequests')
          .where('targetUserId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      List<UserModel> requesters = [];
      for (final doc in snapshot.docs) {
        final requestData = doc.data();
        final requesterId = requestData['requesterId'];
        
        final userSnapshot = await _firestore
            .collection('users')
            .doc(requesterId)
            .get();

        if (userSnapshot.exists) {
          requesters.add(UserModel.fromFirestore(userSnapshot));
        }
      }

      return requesters;
    } catch (e) {
      print('Error getting follow requests: $e');
      return [];
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Users Collection
  CollectionReference get _usersCollection =>
      _firestore.collection(AppConstants.usersCollection);

  // Posts Collection
  CollectionReference get _postsCollection =>
      _firestore.collection(AppConstants.postsCollection);

  // Stories Collection
  CollectionReference get _storiesCollection =>
      _firestore.collection(AppConstants.storiesCollection);

  // Comments Collection
  CollectionReference get _commentsCollection =>
      _firestore.collection(AppConstants.commentsCollection);

  // Chats Collection
  CollectionReference get _chatsCollection =>
      _firestore.collection(AppConstants.chatsCollection);

  // Messages Collection
  CollectionReference get _messagesCollection =>
      _firestore.collection(AppConstants.messagesCollection);

  // Notifications Collection
  CollectionReference get _notificationsCollection =>
      _firestore.collection(AppConstants.notificationsCollection);

  // User Operations
  
  Future<void> createUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).set(user.toJson());
    } catch (e) {
      throw Exception('خطأ في إنشاء المستخدم: $e');
    }
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('خطأ في جلب بيانات المستخدم: $e');
    }
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _usersCollection.doc(uid).update(data);
    } catch (e) {
      throw Exception('خطأ في تحديث بيانات المستخدم: $e');
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      await _usersCollection.doc(uid).delete();
    } catch (e) {
      throw Exception('خطأ في حذف المستخدم: $e');
    }
  }

  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final querySnapshot = await _usersCollection
          .where('username', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('username', isLessThan: query.toLowerCase() + 'z')
          .limit(20)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('خطأ في البحث عن المستخدمين: $e');
    }
  }

  Future<List<UserModel>> getFollowers(String uid) async {
    try {
      final user = await getUser(uid);
      if (user == null) return [];

      final List<Future<UserModel?>> futures = user.followers
          .map((followerId) => getUser(followerId))
          .toList();

      final results = await Future.wait(futures);
      return results.whereType<UserModel>().toList();
    } catch (e) {
      throw Exception('خطأ في جلب المتابعين: $e');
    }
  }

  Future<List<UserModel>> getFollowing(String uid) async {
    try {
      final user = await getUser(uid);
      if (user == null) return [];

      final List<Future<UserModel?>> futures = user.following
          .map((followingId) => getUser(followingId))
          .toList();

      final results = await Future.wait(futures);
      return results.whereType<UserModel>().toList();
    } catch (e) {
      throw Exception('خطأ في جلب المتابَعين: $e');
    }
  }

  Future<void> followUser(String currentUserId, String targetUserId) async {
    try {
      final batch = _firestore.batch();

      // Add to current user's following list
      batch.update(_usersCollection.doc(currentUserId), {
        'following': FieldValue.arrayUnion([targetUserId]),
        'followingCount': FieldValue.increment(1),
      });

      // Add to target user's followers list
      batch.update(_usersCollection.doc(targetUserId), {
        'followers': FieldValue.arrayUnion([currentUserId]),
        'followersCount': FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('خطأ في متابعة المستخدم: $e');
    }
  }

  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      final batch = _firestore.batch();

      // Remove from current user's following list
      batch.update(_usersCollection.doc(currentUserId), {
        'following': FieldValue.arrayRemove([targetUserId]),
        'followingCount': FieldValue.increment(-1),
      });

      // Remove from target user's followers list
      batch.update(_usersCollection.doc(targetUserId), {
        'followers': FieldValue.arrayRemove([currentUserId]),
        'followersCount': FieldValue.increment(-1),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('خطأ في إلغاء متابعة المستخدم: $e');
    }
  }

  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    try {
      final user = await getUser(currentUserId);
      return user?.following.contains(targetUserId) ?? false;
    } catch (e) {
      throw Exception('خطأ في فحص حالة المتابعة: $e');
    }
  }

  Future<void> updateUserOnlineStatus(String uid, bool isOnline) async {
    try {
      await _usersCollection.doc(uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('خطأ في تحديث حالة الاتصال: $e');
    }
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  Future<bool> isUsernameAvailable(String username) async {
    try {
      final querySnapshot = await _usersCollection
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();

      return querySnapshot.docs.isEmpty;
    } catch (e) {
      throw Exception('خطأ في فحص توفر اسم المستخدم: $e');
    }
  }

  Future<List<UserModel>> getSuggestedUsers(String currentUserId, {int limit = 10}) async {
    try {
      // Get current user's following list
      final currentUser = await getUser(currentUserId);
      if (currentUser == null) return [];

      // Get users not followed by current user
      final querySnapshot = await _usersCollection
          .where(FieldPath.documentId, whereNotIn: [
            ...currentUser.following,
            currentUserId
          ])
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('خطأ في جلب المستخدمين المقترحين: $e');
    }
  }

  // Batch operations
  Future<void> batchUpdateUsers(List<String> userIds, Map<String, dynamic> data) async {
    try {
      final batch = _firestore.batch();
      
      for (String userId in userIds) {
        batch.update(_usersCollection.doc(userId), data);
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('خطأ في التحديث المجمع للمستخدمين: $e');
    }
  }

  // Get users by field
  Future<List<UserModel>> getUsersByField(String field, dynamic value, {int limit = 20}) async {
    try {
      final querySnapshot = await _usersCollection
          .where(field, isEqualTo: value)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('خطأ في جلب المستخدمين: $e');
    }
  }

  // Pagination support
  Future<List<UserModel>> getUsersPaginated({
    DocumentSnapshot? lastDocument,
    int limit = 20,
    String? orderBy,
    bool descending = false,
  }) async {
    try {
      Query query = _usersCollection;

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('خطأ في جلب المستخدمين مع التصفح: $e');
    }
  }
}

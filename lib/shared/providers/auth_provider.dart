import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final UserModel? user;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    UserModel? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final FirestoreService _firestoreService;

  AuthNotifier(this._authService, this._firestoreService) : super(const AuthState()) {
    _checkAuthState();
  }

  void _checkAuthState() {
    final user = _authService.currentUser;
    if (user != null) {
      _loadUserData(user.uid);
    }
  }

  Future<void> _loadUserData(String uid) async {
    try {
      state = state.copyWith(isLoading: true);
      final userData = await _firestoreService.getUser(uid);
      if (userData != null) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: userData,
          error: null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final user = await _authService.signInWithEmail(email, password);
      if (user != null) {
        await _loadUserData(user.uid);
        return true;
      }
      
      state = state.copyWith(
        isLoading: false,
        error: 'فشل في تسجيل الدخول',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      return false;
    }
  }

  Future<bool> signUpWithEmail(String email, String password, String username, String fullName) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final user = await _authService.signUpWithEmail(email, password);
      if (user != null) {
        // Create user profile
        final userModel = UserModel(
          uid: user.uid,
          email: email,
          username: username,
          fullName: fullName,
          profileImageUrl: '',
          bio: '',
          followers: [],
          following: [],
          postsCount: 0,
          followersCount: 0,
          followingCount: 0,
          isVerified: false,
          isPrivate: false,
          createdAt: DateTime.now(),
        );
        
        await _firestoreService.createUser(userModel);
        
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: userModel,
          error: null,
        );
        return true;
      }
      
      state = state.copyWith(
        isLoading: false,
        error: 'فشل في إنشاء الحساب',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        // Check if user exists in Firestore
        final existingUser = await _firestoreService.getUser(user.uid);
        
        if (existingUser == null) {
          // Create new user profile
          final userModel = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            username: user.displayName?.replaceAll(' ', '').toLowerCase() ?? '',
            fullName: user.displayName ?? '',
            profileImageUrl: user.photoURL ?? '',
            bio: '',
            followers: [],
            following: [],
            postsCount: 0,
            followersCount: 0,
            followingCount: 0,
            isVerified: false,
            isPrivate: false,
            createdAt: DateTime.now(),
          );
          
          await _firestoreService.createUser(userModel);
          
          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            user: userModel,
            error: null,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            user: existingUser,
            error: null,
          );
        }
        return true;
      }
      
      state = state.copyWith(
        isLoading: false,
        error: 'فشل في تسجيل الدخول بـ Google',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      return false;
    }
  }

  Future<bool> signInWithFacebook() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final user = await _authService.signInWithFacebook();
      if (user != null) {
        // Check if user exists in Firestore
        final existingUser = await _firestoreService.getUser(user.uid);
        
        if (existingUser == null) {
          // Create new user profile
          final userModel = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            username: user.displayName?.replaceAll(' ', '').toLowerCase() ?? '',
            fullName: user.displayName ?? '',
            profileImageUrl: user.photoURL ?? '',
            bio: '',
            followers: [],
            following: [],
            postsCount: 0,
            followersCount: 0,
            followingCount: 0,
            isVerified: false,
            isPrivate: false,
            createdAt: DateTime.now(),
          );
          
          await _firestoreService.createUser(userModel);
          
          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            user: userModel,
            error: null,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            user: existingUser,
            error: null,
          );
        }
        return true;
      }
      
      state = state.copyWith(
        isLoading: false,
        error: 'فشل في تسجيل الدخول بـ Facebook',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(error: _getErrorMessage(e));
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _authService.resetPassword(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      return false;
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'المستخدم غير موجود';
        case 'wrong-password':
          return 'كلمة المرور خاطئة';
        case 'email-already-in-use':
          return 'البريد الإلكتروني مستخدم بالفعل';
        case 'weak-password':
          return 'كلمة المرور ضعيفة';
        case 'invalid-email':
          return 'البريد الإلكتروني غير صحيح';
        case 'user-disabled':
          return 'تم تعطيل هذا الحساب';
        case 'too-many-requests':
          return 'محاولات كثيرة جداً، حاول لاحقاً';
        case 'operation-not-allowed':
          return 'هذه العملية غير مسموحة';
        default:
          return 'حدث خطأ غير متوقع';
      }
    }
    return error.toString();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.read(authServiceProvider);
  final firestoreService = ref.read(firestoreServiceProvider);
  return AuthNotifier(authService, firestoreService);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';

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
  AuthNotifier() : super(const AuthState());

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      // For demo purposes, accept any email/password
      if (email.isNotEmpty && password.length >= 6) {
        final user = UserModel(
          uid: 'demo_user_id',
          email: email,
          username: 'demo_user',
          fullName: 'مستخدم تجريبي',
          profileImageUrl: 'https://picsum.photos/200',
          bio: 'هذا حساب تجريبي للتطبيق',
          followers: [],
          following: [],
          postsCount: 15,
          followersCount: 1250,
          followingCount: 340,
          isVerified: true,
          isPrivate: false,
          createdAt: DateTime.now(),
        );
        
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: user,
          error: null,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'البريد الإلكتروني أو كلمة المرور غير صحيحة',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'حدث خطأ غير متوقع',
      );
      return false;
    }
  }

  Future<bool> signUpWithEmail(String email, String password, String username, String fullName) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      if (email.isNotEmpty && password.length >= 6 && username.isNotEmpty && fullName.isNotEmpty) {
        final user = UserModel(
          uid: 'new_user_id',
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
        
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: user,
          error: null,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'يرجى ملء جميع الحقول بشكل صحيح',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'حدث خطأ غير متوقع',
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      final user = UserModel(
        uid: 'google_user_id',
        email: 'user@gmail.com',
        username: 'google_user',
        fullName: 'مستخدم Google',
        profileImageUrl: 'https://picsum.photos/200?random=1',
        bio: 'مستخدم مسجل عبر Google',
        followers: [],
        following: [],
        postsCount: 8,
        followersCount: 850,
        followingCount: 200,
        isVerified: false,
        isPrivate: false,
        createdAt: DateTime.now(),
      );
      
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل في تسجيل الدخول بـ Google',
      );
      return false;
    }
  }

  Future<bool> signInWithFacebook() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      final user = UserModel(
        uid: 'facebook_user_id',
        email: 'user@facebook.com',
        username: 'facebook_user',
        fullName: 'مستخدم Facebook',
        profileImageUrl: 'https://picsum.photos/200?random=2',
        bio: 'مستخدم مسجل عبر Facebook',
        followers: [],
        following: [],
        postsCount: 12,
        followersCount: 650,
        followingCount: 180,
        isVerified: false,
        isPrivate: false,
        createdAt: DateTime.now(),
      );
      
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل في تسجيل الدخول بـ Facebook',
      );
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AuthState();
  }

  Future<bool> resetPassword(String email) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل في إرسال رسالة إعادة تعيين كلمة المرور',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

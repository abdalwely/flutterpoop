import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception('خطأ غير متوقع: $e');
    }
  }

  // Sign up with email and password
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception('خطأ غير متوقع: $e');
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      // Sign out from previous Google account
      await _googleSignIn.signOut();
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('تم إلغاء تسجيل الدخول');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credentials
      final UserCredential result = await _auth.signInWithCredential(credential);
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception('خطأ في تسجيل الدخول بـ Google: $e');
    }
  }

  // Sign in with Facebook
  Future<User?> signInWithFacebook() async {
    try {
      // Logout from previous Facebook account
      await FacebookAuth.instance.logOut();
      
      // Trigger the sign-in flow
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        // Create a credential from the access token
        final OAuthCredential facebookAuthCredential =
            FacebookAuthProvider.credential(result.accessToken!.tokenString);

        // Sign in to Firebase with the Facebook credentials
        final UserCredential userCredential =
            await _auth.signInWithCredential(facebookAuthCredential);
        return userCredential.user;
      } else if (result.status == LoginStatus.cancelled) {
        throw Exception('تم إلغاء تسجيل الدخول');
      } else {
        throw Exception('فشل في تسجيل الدخول بـ Facebook');
      }
    } on FirebaseAuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception('خطأ في تسجيل الدخول بـ Facebook: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception('خطأ في إرسال رسالة إعادة تعيين كلمة المرور: $e');
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      } else {
        throw Exception('المستخدم غير مسجل الدخول');
      }
    } on FirebaseAuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception('خطأ في تحديث كلمة المرور: $e');
    }
  }

  // Update email
  Future<void> updateEmail(String newEmail) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateEmail(newEmail.trim());
      } else {
        throw Exception('المستخدم غير مسجل الدخول');
      }
    } on FirebaseAuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception('خطأ في تحديث البريد الإلكتروني: $e');
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception('خطأ في إرسال رسالة التحقق: $e');
    }
  }

  // Reload user
  Future<void> reloadUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
      }
    } catch (e) {
      throw Exception('خطأ في تحديث بيانات المستخدم: $e');
    }
  }

  // Reauthenticate user
  Future<void> reauthenticateWithEmail(String email, String password) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final credential = EmailAuthProvider.credential(
          email: email.trim(),
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      } else {
        throw Exception('المستخدم غير مسجل الدخول');
      }
    } on FirebaseAuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception('خطأ في إعادة المصادقة: $e');
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      } else {
        throw Exception('المستخدم غير مسجل الدخول');
      }
    } on FirebaseAuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception('خطأ في حذف الحساب: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Google
      await _googleSignIn.signOut();
      
      // Sign out from Facebook
      await FacebookAuth.instance.logOut();
      
      // Sign out from Firebase
      await _auth.signOut();
    } catch (e) {
      throw Exception('خطأ في تسجيل الخروج: $e');
    }
  }

  // Check if email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Get user ID
  String? get userId => _auth.currentUser?.uid;

  // Get user email
  String? get userEmail => _auth.currentUser?.email;

  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;
}

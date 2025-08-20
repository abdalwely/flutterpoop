class AppConstants {
  // App Info
  static const String appName = 'إنستغرام';
  static const String appVersion = '1.0.0';
  
  // API Constants
  static const int requestTimeOut = 30000;
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
  static const int maxVideoSize = 100 * 1024 * 1024; // 100MB
  
  // UI Constants
  static const double borderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;
  
  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  // Story Constants
  static const Duration storyDuration = Duration(seconds: 15);
  static const int maxStoriesCount = 100;
  
  // Post Constants
  static const int maxCaptionLength = 2200;
  static const int maxHashtagsCount = 30;
  static const int maxCommentsPerLoad = 20;
  
  // Chat Constants
  static const int maxMessageLength = 1000;
  static const int maxMessagesPerLoad = 50;
  
  // Search Constants
  static const int maxSearchResults = 50;
  static const Duration searchDebounceTime = Duration(milliseconds: 500);
  
  // Firebase Collection Names
  static const String usersCollection = 'users';
  static const String postsCollection = 'posts';
  static const String storiesCollection = 'stories';
  static const String commentsCollection = 'comments';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String notificationsCollection = 'notifications';
  
  // Storage Paths
  static const String profileImagesPath = 'profile_images';
  static const String postImagesPath = 'post_images';
  static const String postVideosPath = 'post_videos';
  static const String storyImagesPath = 'story_images';
  static const String storyVideosPath = 'story_videos';
  static const String chatImagesPath = 'chat_images';
  static const String chatVideosPath = 'chat_videos';
  
  // Shared Preferences Keys
  static const String userIdKey = 'user_id';
  static const String userTokenKey = 'user_token';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String onboardingKey = 'onboarding_completed';
  
  // Error Messages (Arabic)
  static const String networkError = 'خطأ في الاتصال بالإنترنت';
  static const String unknownError = 'حدث خطأ غير متوقع';
  static const String timeoutError = 'انتهت مهلة الاتصال';
  static const String authenticationError = 'خطأ في المصادقة';
  static const String permissionDenied = 'تم رفض الإذن';
  static const String fileNotFound = 'الملف غير موجود';
  static const String invalidEmail = 'البريد الإلكتروني غير صحيح';
  static const String weakPassword = 'كلمة المرور ضعيفة';
  static const String userNotFound = 'المستخدم غير موجود';
  static const String wrongPassword = 'كلمة المرور خاطئة';
  static const String emailAlreadyInUse = 'البريد الإلكتروني مستخدم بالفعل';
  
  // Success Messages (Arabic)
  static const String loginSuccess = 'تم تسجيل الدخول بنجاح';
  static const String registerSuccess = 'تم إنشاء الحساب بنجاح';
  static const String postUploaded = 'تم نشر المنشور بنجاح';
  static const String storyUploaded = 'تم نشر القصة بنجاح';
  static const String profileUpdated = 'تم تحديث الملف الشخصي';
  static const String passwordChanged = 'تم تغيير كلمة المرور';
  
  // Button Labels (Arabic)
  static const String login = 'تسجيل الدخول';
  static const String register = 'إنشاء حساب';
  static const String logout = 'تسجيل الخروج';
  static const String save = 'حفظ';
  static const String cancel = 'إلغاء';
  static const String delete = 'حذف';
  static const String edit = 'تعديل';
  static const String share = 'مشاركة';
  static const String like = 'إعجاب';
  static const String comment = 'تعلي��';
  static const String follow = 'متابعة';
  static const String unfollow = 'إلغاء المتابعة';
  static const String send = 'إرسال';
  static const String post = 'نشر';
  static const String next = 'التالي';
  static const String skip = 'تخطي';
  static const String done = 'تم';
  static const String retry = 'إعادة المحاولة';
  
  // Screen Titles (Arabic)
  static const String home = 'الرئيسية';
  static const String search = 'البحث';
  static const String addPost = 'إضافة منشور';
  static const String reels = 'ريلز';
  static const String profile = 'الملف الشخصي';
  static const String stories = 'القصص';
  static const String messages = 'الرسائل';
  static const String notifications = 'الإشعارات';
  static const String settings = 'الإعدادات';
  static const String editProfile = 'تعديل الملف الشخصي';
  static const String followers = 'المتابعون';
  static const String following = 'المتابَعون';
  static const String posts = 'المنشورات';
  static const String explore = 'استكشاف';
  
  // Placeholder Texts (Arabic)
  static const String emailHint = 'البريد الإلكتروني';
  static const String passwordHint = 'كلمة المرور';
  static const String usernameHint = 'اسم المستخدم';
  static const String fullNameHint = 'الاسم الكامل';
  static const String bioHint = 'نبذة شخصية';
  static const String captionHint = 'اكتب تعليقاً...';
  static const String commentHint = 'أضف تعليقاً...';
  static const String messageHint = 'اكتب رسالة...';
  static const String searchHint = 'البحث';
  static const String noPostsYet = 'لا توجد منشورات بعد';
  static const String noStoriesYet = 'لا توجد قصص بعد';
  static const String noMessagesYet = 'لا توجد رسائل بعد';
  static const String noNotificationsYet = 'لا توجد إشعارات بعد';
}

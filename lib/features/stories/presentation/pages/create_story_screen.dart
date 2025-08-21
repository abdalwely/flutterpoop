import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/services/story_service.dart';
import '../../../../shared/models/story_model.dart';

class CreateStoryScreen extends ConsumerStatefulWidget {
  final File? initialMedia;
  
  const CreateStoryScreen({super.key, this.initialMedia});

  @override
  ConsumerState<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends ConsumerState<CreateStoryScreen>
    with TickerProviderStateMixin {
  File? _selectedMedia;
  StoryType _storyType = StoryType.image;
  VideoPlayerController? _videoController;
  
  final TextEditingController _textController = TextEditingController();
  
  bool _isLoading = false;
  bool _isVideo = false;
  
  // Story customization options
  StoryVisibility _visibility = StoryVisibility.everyone;
  bool _allowReplies = true;
  bool _allowSharing = true;
  
  // Text story options
  String _backgroundColor = '#000000';
  String _textColor = '#FFFFFF';
  String _fontFamily = 'Cairo';
  double _textSize = 24.0;
  Alignment _textAlignment = Alignment.center;
  
  final List<String> _backgroundColors = [
    '#000000', '#FF6B6B', '#4ECDC4', '#45B7D1', 
    '#96CEB4', '#FFEAA7', '#DDA0DD', '#98D8C8',
    '#F7DC6F', '#BB8FCE', '#85C1E9', '#F8C471'
  ];
  
  final List<String> _textColors = [
    '#FFFFFF', '#000000', '#FF6B6B', '#4ECDC4',
    '#45B7D1', '#96CEB4', '#FFEAA7', '#DDA0DD'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialMedia != null) {
      _selectedMedia = widget.initialMedia;
      _initializeMedia();
    } else {
      _pickMedia();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _initializeMedia() {
    if (_selectedMedia != null) {
      final extension = _selectedMedia!.path.split('.').last.toLowerCase();
      _isVideo = ['mp4', 'mov', 'avi', 'mkv'].contains(extension);
      
      if (_isVideo) {
        _storyType = StoryType.video;
        _initializeVideo();
      } else {
        _storyType = StoryType.image;
      }
      setState(() {});
    }
  }

  void _initializeVideo() {
    if (_selectedMedia != null && _isVideo) {
      _videoController = VideoPlayerController.file(_selectedMedia!);
      _videoController!.initialize().then((_) {
        if (mounted) {
          setState(() {});
          _videoController!.setLooping(true);
          _videoController!.play();
        }
      });
    }
  }

  Future<void> _pickMedia() async {
    final ImagePicker picker = ImagePicker();

    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildMediaSourceBottomSheet(),
    );

    if (result == null) {
      Navigator.pop(context);
      return;
    }

    try {
      setState(() => _isLoading = true);

      XFile? pickedFile;

      if (result == 'camera_photo') {
        pickedFile = await picker.pickImage(source: ImageSource.camera);
      } else if (result == 'camera_video') {
        pickedFile = await picker.pickVideo(source: ImageSource.camera);
      } else if (result == 'gallery_photo') {
        pickedFile = await picker.pickImage(source: ImageSource.gallery);
      } else if (result == 'gallery_video') {
        pickedFile = await picker.pickVideo(source: ImageSource.gallery);
      } else if (result == 'text_story') {
        _createTextStory();
        return;
      }

      if (pickedFile != null) {
        _selectedMedia = File(pickedFile.path);
        _initializeMedia();
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorSnackBar('فشل في اختيار الوسائط');
      Navigator.pop(context);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _createTextStory() {
    setState(() {
      _selectedMedia = null;
      _storyType = StoryType.text;
      _isVideo = false;
    });
  }

  Widget _buildMediaSourceBottomSheet() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'إنشاء قصة',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
          SizedBox(height: 20.h),
          _buildMediaOption(
            'التقاط صورة',
            Icons.camera_alt,
            () => Navigator.pop(context, 'camera_photo'),
          ),
          _buildMediaOption(
            'تسجيل فيديو',
            Icons.videocam,
            () => Navigator.pop(context, 'camera_video'),
          ),
          _buildMediaOption(
            'صورة من المعرض',
            Icons.photo,
            () => Navigator.pop(context, 'gallery_photo'),
          ),
          _buildMediaOption(
            'فيديو من المعرض',
            Icons.video_library,
            () => Navigator.pop(context, 'gallery_video'),
          ),
          _buildMediaOption(
            'قصة نصية',
            Icons.text_fields,
            () => Navigator.pop(context, 'text_story'),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaOption(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            SizedBox(width: 16.w),
            Icon(icon, color: AppColors.primary, size: 24.sp),
            SizedBox(width: 16.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.textPrimary,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingOverlay.message(
        message: 'جاري التحميل...',
      );
    }

    if (_selectedMedia == null && _storyType != StoryType.text) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: CustomAppBar(
        backgroundColor: AppColors.black,
        title: 'قصة جديدة',
        titleStyle: TextStyle(
          color: AppColors.white,
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          fontFamily: 'Cairo',
        ),

        actions: [
          TextButton(
            onPressed: _publishStory,
            child: Text(
              'نشر',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Story content
          Positioned.fill(
            child: _buildStoryContent(),
          ),
          
          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryContent() {
    switch (_storyType) {
      case StoryType.text:
        return _buildTextStoryContent();
      case StoryType.video:
        return _buildVideoContent();
      case StoryType.image:
      default:
        return _buildImageContent();
    }
  }

  Widget _buildTextStoryContent() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Color(int.parse(_backgroundColor.replaceFirst('#', '0xFF'))),
      child: SafeArea(
        child: Stack(
          children: [
            // Text input
            Positioned.fill(
              child: GestureDetector(
                onTap: () => _showTextEditor(),
                child: Container(
                  alignment: _textAlignment,
                  padding: EdgeInsets.all(32.w),
                  child: _textController.text.isEmpty
                      ? Text(
                          'اضغط لإضافة نص',
                          style: TextStyle(
                            color: Color(int.parse(_textColor.replaceFirst('#', '0xFF'))).withOpacity(0.7),
                            fontSize: _textSize.sp,
                            fontFamily: _fontFamily,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        )
                      : Text(
                          _textController.text,
                          style: TextStyle(
                            color: Color(int.parse(_textColor.replaceFirst('#', '0xFF'))),
                            fontSize: _textSize.sp,
                            fontFamily: _fontFamily,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: FileImage(_selectedMedia!),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Text overlay if any
            if (_textController.text.isNotEmpty)
              Positioned.fill(
                child: Container(
                  alignment: _textAlignment,
                  padding: EdgeInsets.all(32.w),
                  child: Text(
                    _textController.text,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 24.sp,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          offset: const Offset(1, 1),
                          blurRadius: 3,
                          color: AppColors.black.withOpacity(0.7),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    if (_videoController?.value.isInitialized == true) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            ),
            
            // Play/Pause button
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (_videoController!.value.isPlaying) {
                      _videoController!.pause();
                    } else {
                      _videoController!.play();
                    }
                  });
                },
                child: Container(
                  color: Colors.transparent,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _videoController!.value.isPlaying ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        width: 60.w,
                        height: 60.h,
                        decoration: BoxDecoration(
                          color: AppColors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: AppColors.white,
                          size: 30.sp,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Text overlay if any
            if (_textController.text.isNotEmpty)
              Positioned.fill(
                child: Container(
                  alignment: _textAlignment,
                  padding: EdgeInsets.all(32.w),
                  child: Text(
                    _textController.text,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 24.sp,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          offset: const Offset(1, 1),
                          blurRadius: 3,
                          color: AppColors.black.withOpacity(0.7),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      );
    }
    
    return Container(
      color: AppColors.black,
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.white),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppColors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Story customization options
            if (_storyType == StoryType.text) _buildTextStoryControls(),
            
            SizedBox(height: 16.h),
            
            // Action buttons
            Row(
              children: [
                // Add text button
                if (_storyType != StoryType.text)
                  _buildActionButton(
                    Icons.text_fields,
                    'نص',
                    () => _showTextEditor(),
                  ),
                
                if (_storyType != StoryType.text) SizedBox(width: 12.w),
                
                // Change media button
                _buildActionButton(
                  Icons.photo_library,
                  'تغيير',
                  () => _pickMedia(),
                ),
                
                SizedBox(width: 12.w),
                
                // Settings button
                _buildActionButton(
                  Icons.settings,
                  'إعدادات',
                  () => _showStorySettings(),
                ),
                
                const Spacer(),
                
                // Visibility indicator
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getVisibilityIcon(),
                        color: AppColors.white,
                        size: 16.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        _getVisibilityText(),
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 12.sp,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextStoryControls() {
    return Column(
      children: [
        // Background colors
        SizedBox(
          height: 40.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _backgroundColors.length,
            itemBuilder: (context, index) {
              final color = _backgroundColors[index];
              final isSelected = color == _backgroundColor;
              
              return GestureDetector(
                onTap: () => setState(() => _backgroundColor = color),
                child: Container(
                  width: 40.w,
                  height: 40.h,
                  margin: EdgeInsets.only(right: 8.w),
                  decoration: BoxDecoration(
                    color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: AppColors.white, width: 3)
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
        
        SizedBox(height: 12.h),
        
        // Text colors
        SizedBox(
          height: 30.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _textColors.length,
            itemBuilder: (context, index) {
              final color = _textColors[index];
              final isSelected = color == _textColor;
              
              return GestureDetector(
                onTap: () => setState(() => _textColor = color),
                child: Container(
                  width: 30.w,
                  height: 30.h,
                  margin: EdgeInsets.only(right: 8.w),
                  decoration: BoxDecoration(
                    color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: AppColors.white, width: 2)
                        : Border.all(color: AppColors.white.withOpacity(0.3), width: 1),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppColors.white,
              size: 20.sp,
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 10.sp,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTextEditor() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Text(
                  'إضافة نص',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontFamily: 'Cairo',
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            SizedBox(height: 16.h),
            
            // Text input
            Expanded(
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontFamily: 'Cairo',
                ),
                decoration: InputDecoration(
                  hintText: 'اكتب نصك هنا...',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontFamily: 'Cairo',
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  contentPadding: EdgeInsets.all(16.w),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // Done button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'تم',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStorySettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'إعدادات القصة',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontFamily: 'Cairo',
              ),
            ),
            
            SizedBox(height: 20.h),
            
            // Visibility setting
            _buildSettingItem(
              'الجمهور',
              _getVisibilityText(),
              Icons.visibility,
              () => _showVisibilityOptions(),
            ),
            
            // Reply setting
            _buildSettingToggle(
              'السماح بالردود',
              'يمكن للآخرين الرد على هذه القصة',
              _allowReplies,
              (value) => setState(() => _allowReplies = value),
            ),
            
            // Sharing setting
            _buildSettingToggle(
              'السماح بالمشاركة',
              'يمكن للآخرين مشاركة هذه القصة',
              _allowSharing,
              (value) => setState(() => _allowSharing = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(String title, String value, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: 'Cairo',
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontFamily: 'Cairo',
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildSettingToggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: 'Cairo',
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontFamily: 'Cairo',
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }

  void _showVisibilityOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'من يمكنه مشاهدة قصتك؟',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontFamily: 'Cairo',
              ),
            ),
            
            SizedBox(height: 20.h),
            
            _buildVisibilityOption(
              StoryVisibility.everyone,
              'الجميع',
              'يمكن لأي شخص مشاهدة قصتك',
              Icons.public,
            ),
            
            _buildVisibilityOption(
              StoryVisibility.followers,
              'المتابعون فقط',
              'يمكن للمتابعين فقط مشاهدة قصتك',
              Icons.group,
            ),
            
            _buildVisibilityOption(
              StoryVisibility.close_friends,
              'الأصدقاء المقربون',
              'يمكن للأصدقاء المقربين فقط مشاهدة قصتك',
              Icons.favorite,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilityOption(StoryVisibility visibility, String title, String subtitle, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: 'Cairo',
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontFamily: 'Cairo',
        ),
      ),
      trailing: _visibility == visibility
          ? Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: () {
        setState(() => _visibility = visibility);
        Navigator.pop(context);
      },
    );
  }

  IconData _getVisibilityIcon() {
    switch (_visibility) {
      case StoryVisibility.everyone:
        return Icons.public;
      case StoryVisibility.followers:
        return Icons.group;
      case StoryVisibility.close_friends:
        return Icons.favorite;
      case StoryVisibility.custom:
        return Icons.settings;
    }
  }

  String _getVisibilityText() {
    switch (_visibility) {
      case StoryVisibility.everyone:
        return 'الجميع';
      case StoryVisibility.followers:
        return 'المتابعون';
      case StoryVisibility.close_friends:
        return 'الأصدقاء المقربون';
      case StoryVisibility.custom:
        return 'مخصص';
    }
  }

  Future<void> _publishStory() async {
    final auth = ref.read(authProvider);
    
    if (auth.user == null) {
      _showErrorSnackBar('يجب تسجيل الدخول أولاً');
      return;
    }

    if (_storyType == StoryType.text && _textController.text.trim().isEmpty) {
      _showErrorSnackBar('يجب إضافة نص للقصة');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final storyService = StoryService();
      
      final List<String> hashtags = _extractHashtags(_textController.text);
      final List<String> mentions = _extractMentions(_textController.text);

      final storyId = await storyService.createStory(
        userId: auth.user!.uid,
        type: _storyType,
        mediaFile: _selectedMedia,
        text: _textController.text.isNotEmpty ? _textController.text : null,
        backgroundColor: _storyType == StoryType.text ? _backgroundColor : null,
        textColor: _storyType == StoryType.text ? _textColor : null,
        fontFamily: _storyType == StoryType.text ? _fontFamily : null,
        textSize: _storyType == StoryType.text ? _textSize : null,
        hashtags: hashtags,
        mentions: mentions,
        visibility: _visibility,
        allowReplies: _allowReplies,
        allowSharing: _allowSharing,
      );
      
      _showSuccessSnackBar('تم نشر القصة بنجاح');
      Navigator.pop(context, true);
    } catch (e) {
      _showErrorSnackBar('فشل في نشر القصة: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<String> _extractHashtags(String text) {
    final RegExp hashtagRegex = RegExp(r'#[\u0600-\u06FF\w]+');
    return hashtagRegex.allMatches(text)
        .map((match) => match.group(0)!.substring(1))
        .toList();
  }
  
  List<String> _extractMentions(String text) {
    final RegExp mentionRegex = RegExp(r'@[\u0600-\u06FF\w]+');
    return mentionRegex.allMatches(text)
        .map((match) => match.group(0)!.substring(1))
        .toList();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../widgets/image_filter_widget.dart';
import '../widgets/location_picker_widget.dart';
import '../widgets/media_editor_widget.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  final List<File>? initialMedia;

  const CreatePostScreen({
    super.key,
    this.initialMedia,
  });

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final PageController _pageController = PageController();
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  List<File> _selectedMedia = [];
  List<Map<String, dynamic>> _processedMedia = [];
  int _currentMediaIndex = 0;
  bool _isLoading = false;
  bool _isProcessing = false;
  String _selectedLocation = '';
  List<String> _selectedTags = [];
  bool _allowComments = true;
  bool _showLikesCount = true;
  String _audience = 'public'; // public, followers, close_friends

  // Filter state
  String _selectedFilter = 'original';
  double _brightness = 0.0;
  double _contrast = 0.0;
  double _saturation = 0.0;
  double _vignette = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    if (widget.initialMedia != null) {
      _selectedMedia = widget.initialMedia!;
      _processInitialMedia();
    } else {
      _pickMedia();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _captionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _processInitialMedia() {
    setState(() => _isProcessing = true);
    
    _processedMedia = _selectedMedia.map((file) => {
      'file': file,
      'filter': 'original',
      'brightness': 0.0,
      'contrast': 0.0,
      'saturation': 0.0,
      'vignette': 0.0,
    }).toList();
    
    setState(() => _isProcessing = false);
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
      
      List<XFile> pickedFiles = [];
      
      if (result == 'camera') {
        final XFile? photo = await picker.pickImage(source: ImageSource.camera);
        if (photo != null) pickedFiles.add(photo);
      } else if (result == 'gallery_single') {
        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
        if (image != null) pickedFiles.add(image);
      } else if (result == 'gallery_multiple') {
        pickedFiles = await picker.pickMultiImage();
      }

      if (pickedFiles.isNotEmpty) {
        _selectedMedia = pickedFiles.map((file) => File(file.path)).toList();
        _processInitialMedia();
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorSnackBar('فشل في اختيار الصور');
      Navigator.pop(context);
    } finally {
      setState(() => _isLoading = false);
    }
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
            'اختر مصدر الصورة',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
          SizedBox(height: 20.h),
          _buildMediaOption(
            'الكاميرا',
            Icons.camera_alt,
            () => Navigator.pop(context, 'camera'),
          ),
          _buildMediaOption(
            'صورة واحدة من المعرض',
            Icons.photo,
            () => Navigator.pop(context, 'gallery_single'),
          ),
          _buildMediaOption(
            'صور متعددة من المعرض',
            Icons.photo_library,
            () => Navigator.pop(context, 'gallery_multiple'),
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
    if (_isLoading || _isProcessing) {
      return Scaffold(
        body: const LoadingOverlay(message: 'جاري التحميل...'),
      );
    }

    if (_selectedMedia.isEmpty) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'منشور جديد',
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _publishPost,
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
      body: Column(
        children: [
          // Media Preview
          _buildMediaPreview(),
          
          // Tabs
          _buildTabBar(),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFiltersTab(),
                _buildDetailsTab(),
                _buildAdvancedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    return Container(
      height: 300.h,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentMediaIndex = index);
            },
            itemCount: _selectedMedia.length,
            itemBuilder: (context, index) {
              final mediaData = _processedMedia[index];
              return GestureDetector(
                onTap: () => _showFullScreenPreview(index),
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: FileImage(mediaData['file']),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: ImageFilterWidget(
                    filter: mediaData['filter'],
                    brightness: mediaData['brightness'],
                    contrast: mediaData['contrast'],
                    saturation: mediaData['saturation'],
                    vignette: mediaData['vignette'],
                  ),
                ),
              );
            },
          ),
          
          // Navigation dots
          if (_selectedMedia.length > 1)
            Positioned(
              bottom: 16.h,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _selectedMedia.length,
                  (index) => Container(
                    width: 8.w,
                    height: 8.h,
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentMediaIndex 
                          ? AppColors.white 
                          : AppColors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
          
          // Media controls
          Positioned(
            top: 16.h,
            right: 16.w,
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _addMoreMedia,
                    child: Icon(
                      Icons.add,
                      color: AppColors.white,
                      size: 20.sp,
                    ),
                  ),
                  if (_selectedMedia.length > 1) ...[
                    SizedBox(width: 8.w),
                    GestureDetector(
                      onTap: _removeCurrentMedia,
                      child: Icon(
                        Icons.delete,
                        color: AppColors.white,
                        size: 20.sp,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: 'Cairo',
          fontSize: 14.sp,
        ),
        tabs: const [
          Tab(text: 'فلاتر'),
          Tab(text: 'التفاصيل'),
          Tab(text: 'متقدم'),
        ],
      ),
    );
  }

  Widget _buildFiltersTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter presets
          Text(
            'فلاتر جاهزة',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 100.h,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterOption('original', 'الأصلي'),
                _buildFilterOption('vintage', 'قديم'),
                _buildFilterOption('black_white', 'أبيض وأس��د'),
                _buildFilterOption('sepia', 'بني'),
                _buildFilterOption('bright', 'ساطع'),
                _buildFilterOption('contrast', 'تباين عالي'),
              ],
            ),
          ),
          
          SizedBox(height: 24.h),
          
          // Manual adjustments
          Text(
            'تعديلات يدوية',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
          SizedBox(height: 16.h),
          
          _buildAdjustmentSlider(
            'السطوع',
            _brightness,
            -100,
            100,
            (value) => setState(() {
              _brightness = value;
              _updateCurrentMediaFilter();
            }),
          ),
          
          _buildAdjustmentSlider(
            'التباين',
            _contrast,
            -100,
            100,
            (value) => setState(() {
              _contrast = value;
              _updateCurrentMediaFilter();
            }),
          ),
          
          _buildAdjustmentSlider(
            'التشبع',
            _saturation,
            -100,
            100,
            (value) => setState(() {
              _saturation = value;
              _updateCurrentMediaFilter();
            }),
          ),
          
          _buildAdjustmentSlider(
            'التظليل',
            _vignette,
            0,
            100,
            (value) => setState(() {
              _vignette = value;
              _updateCurrentMediaFilter();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String filter, String name) {
    final isSelected = _selectedFilter == filter;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
          _updateCurrentMediaFilter();
        });
      },
      child: Container(
        width: 80.w,
        margin: EdgeInsets.only(left: 12.w),
        child: Column(
          children: [
            Container(
              width: 80.w,
              height: 60.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
                image: DecorationImage(
                  image: FileImage(_selectedMedia[_currentMediaIndex]),
                  fit: BoxFit.cover,
                ),
              ),
              child: ImageFilterWidget(filter: filter),
            ),
            SizedBox(height: 8.h),
            Text(
              name,
              style: TextStyle(
                fontSize: 12.sp,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustmentSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  fontFamily: 'Cairo',
                ),
              ),
              Text(
                value.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.2),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Caption
          Text(
            'وصف المنشور',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _captionController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'أكتب وصفاً للمنشور...',
              hintStyle: TextStyle(
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
              filled: true,
              fillColor: AppColors.inputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
            ),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
          
          SizedBox(height: 24.h),
          
          // Location
          Text(
            'الموقع',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
          SizedBox(height: 12.h),
          GestureDetector(
            onTap: _pickLocation,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppColors.textSecondary,
                    size: 20.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      _selectedLocation.isEmpty 
                          ? 'إضافة موقع' 
                          : _selectedLocation,
                      style: TextStyle(
                        color: _selectedLocation.isEmpty 
                            ? AppColors.textSecondary 
                            : AppColors.textPrimary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24.h),
          
          // Tags
          Text(
            'العلامات',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
          SizedBox(height: 12.h),
          GestureDetector(
            onTap: _addTags,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_offer,
                    color: AppColors.textSecondary,
                    size: 20.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      _selectedTags.isEmpty 
                          ? 'إضافة علامات' 
                          : _selectedTags.join(', '),
                      style: TextStyle(
                        color: _selectedTags.isEmpty 
                            ? AppColors.textSecondary 
                            : AppColors.textPrimary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Audience
          Text(
            'الجمهور',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
          SizedBox(height: 12.h),
          _buildAudienceOption('public', 'عام', 'يمكن لأي شخص رؤية هذا المنشور'),
          _buildAudienceOption('followers', 'المتابعون فقط', 'يمكن للمتابعين فقط رؤية هذا المنشور'),
          _buildAudienceOption('close_friends', 'الأصدقاء المقربون', 'يمكن للأصدقاء المقربين فقط رؤية هذا المنشور'),
          
          SizedBox(height: 24.h),
          
          // Settings
          Text(
            'إعدادات',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
          SizedBox(height: 12.h),
          
          _buildSettingItem(
            'السماح بالتعليقات',
            'يمكن للآخرين التعليق على هذا المنشور',
            _allowComments,
            (value) => setState(() => _allowComments = value),
          ),
          
          _buildSettingItem(
            'إظهار عدد الإعجابات',
            'إظهار عدد الإعجابات للآخرين',
            _showLikesCount,
            (value) => setState(() => _showLikesCount = value),
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceOption(String value, String title, String subtitle) {
    return GestureDetector(
      onTap: () => setState(() => _audience = value),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          border: Border.all(
            color: _audience == value ? AppColors.primary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _audience,
              onChanged: (val) => setState(() => _audience = val!),
              activeColor: AppColors.primary,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'Cairo',
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  void _updateCurrentMediaFilter() {
    if (_processedMedia.isNotEmpty && _currentMediaIndex < _processedMedia.length) {
      _processedMedia[_currentMediaIndex] = {
        ..._processedMedia[_currentMediaIndex],
        'filter': _selectedFilter,
        'brightness': _brightness,
        'contrast': _contrast,
        'saturation': _saturation,
        'vignette': _vignette,
      };
    }
  }

  void _showFullScreenPreview(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: AppColors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.white),
          ),
          body: PhotoView(
            imageProvider: FileImage(_selectedMedia[index]),
            backgroundDecoration: BoxDecoration(color: AppColors.black),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
          ),
        ),
      ),
    );
  }

  Future<void> _addMoreMedia() async {
    // Implementation for adding more media
  }

  void _removeCurrentMedia() {
    if (_selectedMedia.length > 1) {
      setState(() {
        _selectedMedia.removeAt(_currentMediaIndex);
        _processedMedia.removeAt(_currentMediaIndex);
        if (_currentMediaIndex >= _selectedMedia.length) {
          _currentMediaIndex = _selectedMedia.length - 1;
        }
      });
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationPickerWidget(),
      ),
    );
    
    if (result != null) {
      setState(() => _selectedLocation = result);
    }
  }

  Future<void> _addTags() async {
    // Implementation for adding tags
  }

  Future<void> _publishPost() async {
    setState(() => _isLoading = true);
    
    try {
      // TODO: Implement post publishing logic
      // This would involve uploading media to Firebase Storage
      // and creating a post document in Firestore
      
      await Future.delayed(const Duration(seconds: 2)); // Simulate upload
      
      Navigator.pop(context, true);
    } catch (e) {
      _showErrorSnackBar('فشل في نشر المنشور');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }
}

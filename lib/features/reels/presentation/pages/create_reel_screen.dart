import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../widgets/video_editor_widget.dart';
import '../widgets/audio_selector_widget.dart';
import '../widgets/effects_selector_widget.dart' show EffectsSelectorWidget, Effect;
import '../widgets/speed_controller_widget.dart';
import '../widgets/timer_widget.dart';

class CreateReelScreen extends ConsumerStatefulWidget {
  final File? initialVideo;

  const CreateReelScreen({
    super.key,
    this.initialVideo,
  });

  @override
  ConsumerState<CreateReelScreen> createState() => _CreateReelScreenState();
}

class _CreateReelScreenState extends ConsumerState<CreateReelScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Camera controllers
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  bool _isPaused = false;
  bool _isBackCamera = true;

  // Video controllers
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  
  // Recording state
  List<VideoSegment> _videoSegments = [];
  double _currentProgress = 0.0;
  double _maxDuration = 60.0; // 60 seconds max
  double _minDuration = 3.0;  // 3 seconds min
  
  // Editing state
  bool _isEditMode = false;
  String _selectedFilter = 'none';
  double _playbackSpeed = 1.0;
  String? _selectedAudio;
  List<Effect> _selectedEffects = [];
  
  // UI controllers
  late AnimationController _recordButtonController;
  late AnimationController _progressController;
  late TabController _tabController;
  
  // Timer
  bool _isTimerEnabled = false;
  int _timerDuration = 3;
  int _currentTimerCount = 0;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeControllers();
    
    if (widget.initialVideo != null) {
      _loadInitialVideo();
    } else {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeControllers();
    super.dispose();
  }

  void _initializeControllers() {
    _recordButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: Duration(seconds: _maxDuration.toInt()),
      vsync: this,
    );
    
    _tabController = TabController(length: 4, vsync: this);
  }

  void _disposeControllers() {
    _cameraController?.dispose();
    _videoController?.dispose();
    _chewieController?.dispose();
    _recordButtonController.dispose();
    _progressController.dispose();
    _tabController.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        await _setupCamera(_cameras![_isBackCamera ? 0 : 1]);
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _setupCamera(CameraDescription camera) async {
    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: true,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      print('Error setting up camera: $e');
    }
  }

  Future<void> _loadInitialVideo() async {
    try {
      setState(() => _isEditMode = true);
      
      _videoController = VideoPlayerController.file(widget.initialVideo!);
      await _videoController!.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        aspectRatio: 9 / 16,
        autoPlay: false,
        looping: true,
        showControls: false,
      );
      
      if (mounted) setState(() {});
    } catch (e) {
      print('Error loading video: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null && !_isEditMode) {
      return const LoadingOverlay.message(
        message: 'جاري تحضير الكاميرا...',
      );
    }

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera/Video Preview
            _buildPreview(),
            
            // Top Controls
            _buildTopControls(),
            
            // Side Controls
            _buildSideControls(),
            
            // Bottom Controls
            _buildBottomControls(),
            
            // Timer Overlay
            if (_isTimerEnabled && _currentTimerCount > 0)
              _buildTimerOverlay(),
            
            // Progress Bar
            _buildProgressBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Positioned.fill(
      child: _isEditMode
          ? _buildVideoPreview()
          : _buildCameraPreview(),
    );
  }

  Widget _buildCameraPreview() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Container(
        color: AppColors.black,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.white),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: Transform.scale(
        scale: 1.0,
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (_chewieController == null) {
      return Container(
        color: AppColors.black,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.white),
        ),
      );
    }

    return Chewie(controller: _chewieController!);
  }

  Widget _buildTopControls() {
    return Positioned(
      top: 16.h,
      left: 16.w,
      right: 16.w,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close button
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: AppColors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.close,
                color: AppColors.white,
                size: 20.sp,
              ),
            ),
          ),
          
          // Settings
          Row(
            children: [
              if (!_isEditMode) ...[
                _buildTopControlButton(
                  Icons.flash_auto,
                  _toggleFlash,
                ),
                SizedBox(width: 8.w),
                _buildTopControlButton(
                  Icons.timer,
                  _toggleTimer,
                  isActive: _isTimerEnabled,
                ),
                SizedBox(width: 8.w),
              ],
              _buildTopControlButton(
                Icons.settings,
                _showSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopControlButton(
    IconData icon, 
    VoidCallback onPressed, {
    bool isActive = false,
  }) {
    return Container(
      width: 40.w,
      height: 40.h,
      decoration: BoxDecoration(
        color: isActive 
            ? AppColors.primary.withOpacity(0.8)
            : AppColors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: AppColors.white,
          size: 20.sp,
        ),
      ),
    );
  }

  Widget _buildSideControls() {
    return Positioned(
      right: 16.w,
      top: 100.h,
      bottom: 200.h,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Switch camera
          if (!_isEditMode)
            _buildSideControlButton(
              Icons.flip_camera_ios,
              _switchCamera,
            ),
          
          // Speed control
          _buildSideControlButton(
            Icons.speed,
            _showSpeedController,
          ),
          
          // Effects
          _buildSideControlButton(
            Icons.auto_fix_high,
            _showEffects,
          ),
          
          // Audio
          _buildSideControlButton(
            Icons.music_note,
            _showAudioSelector,
          ),
          
          // Filters
          _buildSideControlButton(
            Icons.filter,
            _showFilters,
          ),
        ],
      ),
    );
  }

  Widget _buildSideControlButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 50.w,
      height: 50.h,
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppColors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: AppColors.white,
          size: 24.sp,
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              AppColors.black.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Segment timeline
            if (_videoSegments.isNotEmpty) _buildSegmentTimeline(),
            
            SizedBox(height: 20.h),
            
            // Main controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Gallery
                if (!_isEditMode) _buildGalleryButton(),
                
                // Record/Play button
                _buildMainActionButton(),
                
                // Next/Save button
                _buildNextButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentTimeline() {
    return Container(
      height: 40.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _videoSegments.length,
        itemBuilder: (context, index) {
          final segment = _videoSegments[index];
          return GestureDetector(
            onTap: () => _deleteSegment(index),
            child: Container(
              width: 60.w,
              height: 40.h,
              margin: EdgeInsets.only(right: 8.w),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Center(
                child: Text(
                  '${(segment.duration / 1000).toStringAsFixed(1)}s',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 10.sp,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGalleryButton() {
    return GestureDetector(
      onTap: _pickVideoFromGallery,
      child: Container(
        width: 50.w,
        height: 50.h,
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(
          Icons.photo_library,
          color: AppColors.white,
          size: 24.sp,
        ),
      ),
    );
  }

  Widget _buildMainActionButton() {
    return GestureDetector(
      onLongPressStart: (_) => _startRecording(),
      onLongPressEnd: (_) => _stopRecording(),
      onTap: _isEditMode ? _togglePlayback : null,
      child: AnimatedBuilder(
        animation: _recordButtonController,
        builder: (context, child) {
          return Container(
            width: 80.w,
            height: 80.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isRecording ? AppColors.error : AppColors.white,
              border: Border.all(
                color: AppColors.white,
                width: 4,
              ),
            ),
            child: Transform.scale(
              scale: 1.0 + (_recordButtonController.value * 0.1),
              child: Icon(
                _isEditMode 
                    ? (_videoController?.value.isPlaying == true 
                        ? Icons.pause 
                        : Icons.play_arrow)
                    : (_isRecording ? Icons.stop : Icons.videocam),
                color: _isRecording ? AppColors.white : AppColors.black,
                size: 32.sp,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNextButton() {
    final canProceed = _isEditMode || _getTotalDuration() >= _minDuration;
    
    return GestureDetector(
      onTap: canProceed ? _proceedToEdit : null,
      child: Container(
        width: 50.w,
        height: 50.h,
        decoration: BoxDecoration(
          color: canProceed 
              ? AppColors.primary 
              : AppColors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(
          _isEditMode ? Icons.check : Icons.arrow_forward,
          color: AppColors.white,
          size: 24.sp,
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Positioned(
      top: 80.h,
      left: 16.w,
      right: 16.w,
      child: Container(
        height: 4.h,
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(2.r),
        ),
        child: AnimatedBuilder(
          animation: _progressController,
          builder: (context, child) {
            return FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _currentProgress / _maxDuration,
              child: Container(
                decoration: BoxDecoration(
                  color: _currentProgress >= _maxDuration 
                      ? AppColors.error 
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimerOverlay() {
    return Positioned.fill(
      child: Container(
        color: AppColors.black.withOpacity(0.7),
        child: Center(
          child: Container(
            width: 120.w,
            height: 120.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.white,
                width: 4,
              ),
            ),
            child: Center(
              child: Text(
                '$_currentTimerCount',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 48.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Control methods
  void _toggleFlash() async {
    if (_cameraController?.value.isInitialized == true) {
      final currentFlashMode = _cameraController!.value.flashMode;
      final newFlashMode = currentFlashMode == FlashMode.off 
          ? FlashMode.auto 
          : FlashMode.off;
      await _cameraController!.setFlashMode(newFlashMode);
      setState(() {});
    }
  }

  void _toggleTimer() {
    setState(() => _isTimerEnabled = !_isTimerEnabled);
  }

  void _switchCamera() async {
    if (_cameras != null && _cameras!.length > 1) {
      setState(() => _isBackCamera = !_isBackCamera);
      await _setupCamera(_cameras![_isBackCamera ? 0 : 1]);
    }
  }

  void _startRecording() async {
    if (_isTimerEnabled) {
      await _startCountdown();
    } else {
      await _beginRecording();
    }
  }

  Future<void> _startCountdown() async {
    setState(() => _currentTimerCount = _timerDuration);
    
    for (int i = _timerDuration; i > 0; i--) {
      setState(() => _currentTimerCount = i);
      await Future.delayed(const Duration(seconds: 1));
    }
    
    setState(() => _currentTimerCount = 0);
    await _beginRecording();
  }

  Future<void> _beginRecording() async {
    if (_cameraController?.value.isInitialized == true && !_isRecording) {
      try {
        setState(() => _isRecording = true);
        _recordButtonController.forward();
        
        await _cameraController!.startVideoRecording();
        
        // Start progress tracking
        _progressController.forward();
      } catch (e) {
        print('Error starting recording: $e');
        setState(() => _isRecording = false);
        _recordButtonController.reverse();
      }
    }
  }

  void _stopRecording() async {
    if (_cameraController?.value.isInitialized == true && _isRecording) {
      try {
        final XFile video = await _cameraController!.stopVideoRecording();
        setState(() => _isRecording = false);
        _recordButtonController.reverse();
        _progressController.stop();
        
        // Add segment
        final segment = VideoSegment(
          file: File(video.path),
          duration: _progressController.value * _maxDuration * 1000,
          startTime: _getTotalDuration(),
        );
        
        setState(() {
          _videoSegments.add(segment);
          _currentProgress = _getTotalDuration();
        });
        
      } catch (e) {
        print('Error stopping recording: $e');
      }
    }
  }

  void _togglePlayback() {
    if (_videoController?.value.isInitialized == true) {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
      setState(() {});
    }
  }

  void _deleteSegment(int index) {
    setState(() {
      _videoSegments.removeAt(index);
      _currentProgress = _getTotalDuration();
    });
  }

  double _getTotalDuration() {
    return _videoSegments.fold(0.0, (sum, segment) => sum + segment.duration / 1000);
  }

  void _pickVideoFromGallery() async {
    // Implementation for picking video from gallery
  }

  void _proceedToEdit() {
    if (_isEditMode) {
      _saveReel();
    } else {
      _goToEditMode();
    }
  }

  void _goToEditMode() async {
    if (_videoSegments.isNotEmpty) {
      // Combine video segments and go to edit mode
      setState(() => _isEditMode = true);
      // Implementation for combining videos
    }
  }

  void _saveReel() async {
    // Implementation for saving the reel
    Navigator.pop(context, true);
  }

  void _showSettings() {
    // Show settings bottom sheet
  }

  void _showSpeedController() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SpeedControllerWidget(
        currentSpeed: _playbackSpeed,
        onSpeedChanged: (speed) {
          setState(() => _playbackSpeed = speed);
        },
      ),
    );
  }

  void _showEffects() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => EffectsSelectorWidget(
        selectedEffects: _selectedEffects,
        onEffectsChanged: (effects) {
          setState(() => _selectedEffects = effects);
        },
      ),
    );
  }

  void _showAudioSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => AudioSelectorWidget(
        selectedAudio: _selectedAudio,
        onAudioSelected: (audio) {
          setState(() => _selectedAudio = audio);
        },
      ),
    );
  }

  void _showFilters() {
    // Show filters bottom sheet
  }
}

class VideoSegment {
  final File file;
  final double duration; // in milliseconds
  final double startTime;

  VideoSegment({
    required this.file,
    required this.duration,
    required this.startTime,
  });
}

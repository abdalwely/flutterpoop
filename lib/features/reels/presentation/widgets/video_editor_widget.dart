import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_colors.dart';

class VideoEditorWidget extends StatefulWidget {
  final File videoFile;
  final Function(Map<String, dynamic>) onEdited;

  const VideoEditorWidget({
    super.key,
    required this.videoFile,
    required this.onEdited,
  });

  @override
  State<VideoEditorWidget> createState() => _VideoEditorWidgetState();
}

class _VideoEditorWidgetState extends State<VideoEditorWidget>
    with TickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _playButtonController;
  
  double _startTrim = 0.0;
  double _endTrim = 1.0;
  double _volume = 1.0;
  double _playbackSpeed = 1.0;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _playButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _playButtonController.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.file(widget.videoFile);
    await _controller.initialize();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: AppColors.black,
      child: Column(
        children: [
          // Video preview
          Expanded(
            flex: 3,
            child: _buildVideoPreview(),
          ),
          
          // Timeline
          Container(
            height: 100.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: _buildTimeline(),
          ),
          
          // Controls
          Container(
            height: 150.h,
            padding: EdgeInsets.all(16.w),
            child: _buildControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Container(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
          
          // Play/Pause button
          GestureDetector(
            onTap: _togglePlayback,
            child: AnimatedBuilder(
              animation: _playButtonController,
              builder: (context, child) {
                return Container(
                  width: 60.w,
                  height: 60.h,
                  decoration: BoxDecoration(
                    color: AppColors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: AppColors.white,
                    size: 30.sp,
                  ),
                );
              },
            ),
          ),
          
          // Progress indicator
          Positioned(
            bottom: 20.h,
            left: 20.w,
            right: 20.w,
            child: _buildProgressIndicator(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return ValueListenableBuilder(
      valueListenable: _controller,
      builder: (context, VideoPlayerValue value, child) {
        final duration = value.duration.inMilliseconds;
        final position = value.position.inMilliseconds;
        
        if (duration == 0) return const SizedBox.shrink();
        
        final progress = position / duration;
        
        return Container(
          height: 4.h,
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2.r),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeline() {
    return Column(
      children: [
        Text(
          'تقليم الفيديو',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            fontFamily: 'Cairo',
          ),
        ),
        SizedBox(height: 16.h),
        
        // Timeline scrubber
        Stack(
          children: [
            Container(
              height: 50.h,
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            
            // Trim handles
            Positioned(
              left: _startTrim * (MediaQuery.of(context).size.width - 32.w),
              child: _buildTrimHandle(true),
            ),
            Positioned(
              left: _endTrim * (MediaQuery.of(context).size.width - 32.w),
              child: _buildTrimHandle(false),
            ),
          ],
        ),
        
        SizedBox(height: 8.h),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(_controller.value.duration * _startTrim),
              style: TextStyle(
                color: AppColors.white.withOpacity(0.7),
                fontSize: 12.sp,
                fontFamily: 'Cairo',
              ),
            ),
            Text(
              _formatDuration(_controller.value.duration * _endTrim),
              style: TextStyle(
                color: AppColors.white.withOpacity(0.7),
                fontSize: 12.sp,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrimHandle(bool isStart) {
    return GestureDetector(
      onPanUpdate: (details) {
        final screenWidth = MediaQuery.of(context).size.width - 32.w;
        final delta = details.delta.dx / screenWidth;
        
        setState(() {
          if (isStart) {
            _startTrim = (_startTrim + delta).clamp(0.0, _endTrim - 0.1);
          } else {
            _endTrim = (_endTrim + delta).clamp(_startTrim + 0.1, 1.0);
          }
        });
        
        _notifyChanges();
      },
      child: Container(
        width: 20.w,
        height: 50.h,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Icon(
          isStart ? Icons.chevron_right : Icons.chevron_left,
          color: AppColors.white,
          size: 16.sp,
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Column(
      children: [
        // Speed control
        _buildSlider(
          'سرعة التشغيل',
          _playbackSpeed,
          0.5,
          2.0,
          (value) {
            setState(() => _playbackSpeed = value);
            _controller.setPlaybackSpeed(value);
            _notifyChanges();
          },
        ),
        
        SizedBox(height: 16.h),
        
        // Volume control
        Row(
          children: [
            IconButton(
              onPressed: _toggleMute,
              icon: Icon(
                _isMuted ? Icons.volume_off : Icons.volume_up,
                color: AppColors.white,
              ),
            ),
            Expanded(
              child: Slider(
                value: _volume,
                onChanged: _isMuted ? null : (value) {
                  setState(() => _volume = value);
                  _controller.setVolume(value);
                  _notifyChanges();
                },
                activeColor: AppColors.primary,
                inactiveColor: AppColors.white.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 14.sp,
                fontFamily: 'Cairo',
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)}x',
              style: TextStyle(
                color: AppColors.white.withOpacity(0.7),
                fontSize: 12.sp,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.white.withOpacity(0.3),
        ),
      ],
    );
  }

  void _togglePlayback() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _playButtonController.reverse();
      } else {
        _controller.play();
        _playButtonController.forward();
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0.0 : _volume);
    });
    _notifyChanges();
  }

  void _notifyChanges() {
    widget.onEdited({
      'startTrim': _startTrim,
      'endTrim': _endTrim,
      'volume': _volume,
      'playbackSpeed': _playbackSpeed,
      'isMuted': _isMuted,
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class VideoTrimmer extends StatefulWidget {
  final VideoPlayerController controller;
  final Function(double start, double end) onTrimChanged;

  const VideoTrimmer({
    super.key,
    required this.controller,
    required this.onTrimChanged,
  });

  @override
  State<VideoTrimmer> createState() => _VideoTrimmerState();
}

class _VideoTrimmerState extends State<VideoTrimmer> {
  double _startTrim = 0.0;
  double _endTrim = 1.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Stack(
        children: [
          // Background timeline
          Container(
            height: 60.h,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          
          // Active trim area
          Positioned(
            left: _startTrim * (MediaQuery.of(context).size.width - 32.w),
            width: (_endTrim - _startTrim) * (MediaQuery.of(context).size.width - 32.w),
            child: Container(
              height: 60.h,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.3),
                border: Border.symmetric(
                  vertical: BorderSide(color: AppColors.primary, width: 3),
                ),
              ),
            ),
          ),
          
          // Start handle
          Positioned(
            left: _startTrim * (MediaQuery.of(context).size.width - 32.w) - 10.w,
            child: _buildHandle(true),
          ),
          
          // End handle
          Positioned(
            left: _endTrim * (MediaQuery.of(context).size.width - 32.w) - 10.w,
            child: _buildHandle(false),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle(bool isStart) {
    return GestureDetector(
      onPanUpdate: (details) {
        final screenWidth = MediaQuery.of(context).size.width - 32.w;
        final delta = details.delta.dx / screenWidth;
        
        setState(() {
          if (isStart) {
            _startTrim = (_startTrim + delta).clamp(0.0, _endTrim - 0.05);
          } else {
            _endTrim = (_endTrim + delta).clamp(_startTrim + 0.05, 1.0);
          }
        });
        
        widget.onTrimChanged(_startTrim, _endTrim);
      },
      child: Container(
        width: 20.w,
        height: 60.h,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (index) => Container(
            width: 12.w,
            height: 2.h,
            color: AppColors.white,
          )),
        ),
      ),
    );
  }
}

class VideoProgressBar extends StatelessWidget {
  final VideoPlayerController controller;
  final Function(Duration)? onSeek;

  const VideoProgressBar({
    super.key,
    required this.controller,
    this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, VideoPlayerValue value, child) {
        if (!value.isInitialized) {
          return const SizedBox.shrink();
        }

        final duration = value.duration.inMilliseconds;
        final position = value.position.inMilliseconds;
        
        return GestureDetector(
          onTapDown: (details) {
            if (onSeek != null) {
              final screenWidth = MediaQuery.of(context).size.width;
              final tapPosition = details.localPosition.dx / screenWidth;
              final seekPosition = Duration(
                milliseconds: (duration * tapPosition).round(),
              );
              onSeek!(seekPosition);
            }
          },
          child: Container(
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2.r),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: duration > 0 ? position / duration : 0.0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

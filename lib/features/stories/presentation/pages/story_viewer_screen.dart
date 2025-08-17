import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/story_model.dart';
import '../../../../shared/models/user_model.dart';
import '../widgets/story_progress_bar.dart';
import '../widgets/story_reaction_widget.dart';

class StoryViewerScreen extends ConsumerStatefulWidget {
  final List<StoryModel> stories;
  final int initialIndex;
  final UserModel user;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    required this.initialIndex,
    required this.user,
  });

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  late AnimationController _replyController;
  
  int _currentStoryIndex = 0;
  int _currentSegmentIndex = 0;
  Timer? _progressTimer;
  VideoPlayerController? _videoController;
  
  bool _isPaused = false;
  bool _showReactions = false;
  bool _showViewers = false;
  
  final TextEditingController _replyController = TextEditingController();
  final Duration _storyDuration = const Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _currentStoryIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    
    _progressController = AnimationController(
      duration: _storyDuration,
      vsync: this,
    );
    
    _replyController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startStory();
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _videoController?.dispose();
    _progressController.dispose();
    _replyController.dispose();
    _pageController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  void _startStory() {
    if (_currentStoryIndex < widget.stories.length) {
      final story = widget.stories[_currentStoryIndex];
      _currentSegmentIndex = 0;
      _startSegment(story);
    }
  }

  void _startSegment(StoryModel story) {
    if (_currentSegmentIndex < story.mediaUrls.length) {
      _progressController.reset();
      
      if (story.mediaTypes[_currentSegmentIndex] == 'video') {
        _setupVideo(story.mediaUrls[_currentSegmentIndex]);
      } else {
        _startProgressTimer();
      }
    }
  }

  void _setupVideo(String videoUrl) {
    _videoController?.dispose();
    _videoController = VideoPlayerController.network(videoUrl);
    _videoController!.initialize().then((_) {
      if (mounted) {
        setState(() {});
        _videoController!.play();
        _startProgressTimer(duration: _videoController!.value.duration);
      }
    });
  }

  void _startProgressTimer({Duration? duration}) {
    final segmentDuration = duration ?? _storyDuration;
    
    _progressController.duration = segmentDuration;
    _progressController.forward();
    
    _progressTimer?.cancel();
    _progressTimer = Timer(segmentDuration, () {
      if (mounted && !_isPaused) {
        _nextSegment();
      }
    });
  }

  void _nextSegment() {
    final story = widget.stories[_currentStoryIndex];
    
    if (_currentSegmentIndex < story.mediaUrls.length - 1) {
      // Next segment in current story
      setState(() => _currentSegmentIndex++);
      _startSegment(story);
    } else {
      // Next story
      _nextStory();
    }
  }

  void _previousSegment() {
    if (_currentSegmentIndex > 0) {
      // Previous segment in current story
      setState(() => _currentSegmentIndex--);
      _startSegment(widget.stories[_currentStoryIndex]);
    } else {
      // Previous story
      _previousStory();
    }
  }

  void _nextStory() {
    if (_currentStoryIndex < widget.stories.length - 1) {
      setState(() {
        _currentStoryIndex++;
        _currentSegmentIndex = 0;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startStory();
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      setState(() {
        _currentStoryIndex--;
        _currentSegmentIndex = 0;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startStory();
    }
  }

  void _pauseStory() {
    setState(() => _isPaused = true);
    _progressTimer?.cancel();
    _progressController.stop();
    _videoController?.pause();
  }

  void _resumeStory() {
    setState(() => _isPaused = false);
    if (_videoController?.value.isInitialized == true) {
      _videoController!.play();
    }
    _progressController.forward();
    
    final remainingDuration = Duration(
      milliseconds: ((1 - _progressController.value) * 
          _progressController.duration!.inMilliseconds).round(),
    );
    
    _progressTimer = Timer(remainingDuration, () {
      if (mounted && !_isPaused) {
        _nextSegment();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          final tapPosition = details.globalPosition.dx;
          
          if (tapPosition < screenWidth * 0.3) {
            _previousSegment();
          } else if (tapPosition > screenWidth * 0.7) {
            _nextSegment();
          } else {
            _isPaused ? _resumeStory() : _pauseStory();
          }
        },
        onLongPressStart: (_) => _pauseStory(),
        onLongPressEnd: (_) => _resumeStory(),
        child: Stack(
          children: [
            // Story content
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentStoryIndex = index;
                  _currentSegmentIndex = 0;
                });
                _startStory();
              },
              itemCount: widget.stories.length,
              itemBuilder: (context, index) {
                return _buildStoryContent(widget.stories[index]);
              },
            ),
            
            // Top overlay
            _buildTopOverlay(),
            
            // Bottom overlay
            _buildBottomOverlay(),
            
            // Reactions overlay
            if (_showReactions) _buildReactionsOverlay(),
            
            // Viewers overlay
            if (_showViewers) _buildViewersOverlay(),
            
            // Pause indicator
            if (_isPaused) _buildPauseIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryContent(StoryModel story) {
    if (_currentSegmentIndex >= story.mediaUrls.length) {
      return const SizedBox.shrink();
    }

    final mediaUrl = story.mediaUrls[_currentSegmentIndex];
    final mediaType = story.mediaTypes[_currentSegmentIndex];

    if (mediaType == 'video') {
      return _buildVideoContent();
    } else {
      return _buildImageContent(mediaUrl);
    }
  }

  Widget _buildImageContent(String imageUrl) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppColors.black,
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.white),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: AppColors.black,
          child: const Center(
            child: Icon(
              Icons.error,
              color: AppColors.white,
              size: 50,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    if (_videoController?.value.isInitialized == true) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _videoController!.value.size.width,
            height: _videoController!.value.size.height,
            child: VideoPlayer(_videoController!),
          ),
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

  Widget _buildTopOverlay() {
    final story = widget.stories[_currentStoryIndex];
    
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8.h,
          left: 16.w,
          right: 16.w,
          bottom: 16.h,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          children: [
            // Progress bars
            StoryProgressBar(
              segmentCount: story.mediaUrls.length,
              currentSegment: _currentSegmentIndex,
              progressController: _progressController,
            ),
            
            SizedBox(height: 12.h),
            
            // User info and controls
            Row(
              children: [
                // User avatar
                Container(
                  width: 32.w,
                  height: 32.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: widget.user.profilePicture,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                
                SizedBox(width: 8.w),
                
                // Username and time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.username,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      Text(
                        _formatTime(story.createdAt),
                        style: TextStyle(
                          color: AppColors.white.withOpacity(0.7),
                          fontSize: 12.sp,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Play/Pause button
                IconButton(
                  onPressed: _isPaused ? _resumeStory : _pauseStory,
                  icon: Icon(
                    _isPaused ? Icons.play_arrow : Icons.pause,
                    color: AppColors.white,
                  ),
                ),
                
                // More options
                IconButton(
                  onPressed: _showMoreOptions,
                  icon: Icon(
                    Icons.more_horiz,
                    color: AppColors.white,
                  ),
                ),
                
                // Close button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          bottom: MediaQuery.of(context).padding.bottom + 16.h,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              AppColors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            // Reply input
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25.r),
                  border: Border.all(
                    color: AppColors.white.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        style: TextStyle(
                          color: AppColors.white,
                          fontFamily: 'Cairo',
                        ),
                        decoration: InputDecoration(
                          hintText: 'رد على القصة...',
                          hintStyle: TextStyle(
                            color: AppColors.white.withOpacity(0.7),
                            fontFamily: 'Cairo',
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: _sendReply,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _sendReply(_replyController.text),
                      icon: Icon(
                        Icons.send,
                        color: AppColors.white,
                        size: 20.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(width: 12.w),
            
            // Reactions button
            GestureDetector(
              onTap: () => setState(() => _showReactions = !_showReactions),
              child: Container(
                width: 45.w,
                height: 45.h,
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite,
                  color: AppColors.white,
                  size: 24.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionsOverlay() {
    return Positioned(
      bottom: 100.h,
      right: 16.w,
      child: StoryReactionWidget(
        onReactionSelected: _sendReaction,
        onClose: () => setState(() => _showReactions = false),
      ),
    );
  }

  Widget _buildViewersOverlay() {
    return Positioned.fill(
      child: Container(
        color: AppColors.black.withOpacity(0.8),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    Text(
                      'المشاهدون',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => setState(() => _showViewers = false),
                      icon: Icon(
                        Icons.close,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Viewers list
              Expanded(
                child: ListView.builder(
                  itemCount: 10, // Mock data
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Text('${index + 1}'),
                      ),
                      title: Text(
                        'مستخدم ${index + 1}',
                        style: TextStyle(
                          color: AppColors.white,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      subtitle: Text(
                        'منذ ${index + 1} دقائق',
                        style: TextStyle(
                          color: AppColors.white.withOpacity(0.7),
                          fontFamily: 'Cairo',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPauseIndicator() {
    return Positioned.fill(
      child: Container(
        color: AppColors.black.withOpacity(0.3),
        child: Center(
          child: Container(
            width: 80.w,
            height: 80.h,
            decoration: BoxDecoration(
              color: AppColors.black.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.play_arrow,
              color: AppColors.white,
              size: 40.sp,
            ),
          ),
        ),
      ),
    );
  }

  void _sendReply(String message) {
    if (message.trim().isNotEmpty) {
      // Implementation for sending reply
      print('Sending reply: $message');
      _replyController.clear();
    }
  }

  void _sendReaction(String reaction) {
    // Implementation for sending reaction
    print('Sending reaction: $reaction');
    setState(() => _showReactions = false);
  }

  void _showMoreOptions() {
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
            ListTile(
              leading: Icon(Icons.visibility),
              title: Text(
                'عرض المشاهدين',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              onTap: () {
                Navigator.pop(context);
                setState(() => _showViewers = true);
              },
            ),
            ListTile(
              leading: Icon(Icons.share),
              title: Text(
                'مشاركة القصة',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              onTap: () {
                Navigator.pop(context);
                _shareStory();
              },
            ),
            ListTile(
              leading: Icon(Icons.report),
              title: Text(
                'إبلاغ عن القصة',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              onTap: () {
                Navigator.pop(context);
                _reportStory();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _shareStory() {
    // Implementation for sharing story
  }

  void _reportStory() {
    // Implementation for reporting story
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inHours < 1) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inDays < 1) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return 'منذ ${difference.inDays} يوم';
    }
  }
}

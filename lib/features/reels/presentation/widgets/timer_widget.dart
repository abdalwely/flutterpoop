import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';

class TimerWidget extends StatefulWidget {
  final int duration;
  final Function(int) onDurationChanged;
  final VoidCallback? onTimerComplete;

  const TimerWidget({
    super.key,
    required this.duration,
    required this.onDurationChanged,
    this.onTimerComplete,
  });

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget>
    with TickerProviderStateMixin {
  late AnimationController _countdownController;
  late Animation<double> _scaleAnimation;
  
  int _selectedDuration = 3;
  bool _isCountingDown = false;
  int _currentCount = 0;

  final List<int> _timerOptions = [3, 5, 10, 15];

  @override
  void initState() {
    super.initState();
    _selectedDuration = widget.duration;
    
    _countdownController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _countdownController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _countdownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 20.h),
          
          // Title
          Text(
            'مؤقت التسجيل',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
          SizedBox(height: 20.h),
          
          // Timer options
          Text(
            'مدة العد التنازلي',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
          SizedBox(height: 16.h),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _timerOptions.map((duration) => _buildTimerOption(duration)).toList(),
          ),
          
          SizedBox(height: 30.h),
          
          // Countdown display
          if (_isCountingDown) _buildCountdownDisplay(),
          
          // Preview button
          if (!_isCountingDown) _buildPreviewButton(),
          
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildTimerOption(int duration) {
    final isSelected = _selectedDuration == duration;
    
    return GestureDetector(
      onTap: () {
        setState(() => _selectedDuration = duration);
        widget.onDurationChanged(duration);
      },
      child: Container(
        width: 60.w,
        height: 60.h,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.inputBackground,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            '${duration}s',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isSelected ? AppColors.white : AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownDisplay() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 120.w,
            height: 120.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.1),
              border: Border.all(
                color: AppColors.primary,
                width: 4,
              ),
            ),
            child: Center(
              child: Text(
                '$_currentCount',
                style: TextStyle(
                  fontSize: 48.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewButton() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _startPreviewCountdown,
          icon: Icon(Icons.play_arrow),
          label: Text(
            'معاينة العد التنازلي',
            style: TextStyle(
              fontFamily: 'Cairo',
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          'سيتم بدء التسجيل تلقائياً بعد انتهاء العد التنازلي',
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.textSecondary,
            fontFamily: 'Cairo',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _startPreviewCountdown() async {
    setState(() {
      _isCountingDown = true;
      _currentCount = _selectedDuration;
    });

    for (int i = _selectedDuration; i > 0; i--) {
      setState(() => _currentCount = i);
      
      // Scale animation for each count
      _countdownController.forward().then((_) {
        _countdownController.reverse();
      });
      
      // Haptic feedback
      // HapticFeedback.heavyImpact();
      
      await Future.delayed(const Duration(seconds: 1));
    }

    setState(() {
      _isCountingDown = false;
      _currentCount = 0;
    });

    // Notify completion
    if (widget.onTimerComplete != null) {
      widget.onTimerComplete!();
    }
  }
}

class CountdownOverlay extends StatefulWidget {
  final int duration;
  final VoidCallback onComplete;

  const CountdownOverlay({
    super.key,
    required this.duration,
    required this.onComplete,
  });

  @override
  State<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  int _currentCount = 0;

  @override
  void initState() {
    super.initState();
    _currentCount = widget.duration;
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0),
    ));
    
    _startCountdown();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startCountdown() async {
    for (int i = widget.duration; i > 0; i--) {
      setState(() => _currentCount = i);
      
      _controller.reset();
      _controller.forward();
      
      await Future.delayed(const Duration(seconds: 1));
    }
    
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.black.withOpacity(0.8),
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 150.w,
                  height: 150.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white.withOpacity(0.9),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$_currentCount',
                      style: TextStyle(
                        fontSize: 64.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class CircularCountdownWidget extends StatefulWidget {
  final int duration;
  final VoidCallback onComplete;
  final Color color;
  final double size;

  const CircularCountdownWidget({
    super.key,
    required this.duration,
    required this.onComplete,
    this.color = AppColors.primary,
    this.size = 100,
  });

  @override
  State<CircularCountdownWidget> createState() => _CircularCountdownWidgetState();
}

class _CircularCountdownWidgetState extends State<CircularCountdownWidget>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  
  int _currentCount = 0;

  @override
  void initState() {
    super.initState();
    _currentCount = widget.duration;
    
    _progressController = AnimationController(
      duration: Duration(seconds: widget.duration),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_progressController);
    
    _startCountdown();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _startCountdown() async {
    _progressController.forward();
    
    for (int i = widget.duration; i > 0; i--) {
      setState(() => _currentCount = i);
      await Future.delayed(const Duration(seconds: 1));
    }
    
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progress circle
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: CircularProgressPainter(
                  progress: _progressAnimation.value,
                  color: widget.color,
                ),
              );
            },
          ),
          
          // Count text
          Text(
            '$_currentCount',
            style: TextStyle(
              fontSize: (widget.size * 0.3).sp,
              fontWeight: FontWeight.bold,
              color: widget.color,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  CircularProgressPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Background circle
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    
    const startAngle = -90 * (3.14159 / 180); // Start from top
    final sweepAngle = 2 * 3.14159 * progress;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

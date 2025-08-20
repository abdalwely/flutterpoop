import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math' as math;
import '../../core/theme/app_colors.dart';

class LikeAnimationWidget extends StatefulWidget {
  final VoidCallback? onAnimationComplete;
  final Duration duration;
  final double size;

  const LikeAnimationWidget({
    super.key,
    this.onAnimationComplete,
    this.duration = const Duration(milliseconds: 800),
    this.size = 80,
  });

  @override
  State<LikeAnimationWidget> createState() => _LikeAnimationWidgetState();
}

class _LikeAnimationWidgetState extends State<LikeAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimation();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
    ));
  }

  void _startAnimation() {
    _controller.forward().then((_) {
      if (widget.onAnimationComplete != null) {
        widget.onAnimationComplete!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Main heart
                    Icon(
                      Icons.favorite,
                      size: widget.size.sp,
                      color: AppColors.like,
                    ),
                    
                    // Floating hearts
                    ..._buildFloatingHearts(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildFloatingHearts() {
    return List.generate(6, (index) {
      final angle = (index * 60) * (3.14159 / 180); // Convert to radians
      final radius = 40.0 + (index * 10);
      
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = Curves.easeOut.transform(_controller.value);
          final x = radius * progress * cos(angle);
          final y = radius * progress * sin(angle);
          
          return Transform.translate(
            offset: Offset(x, y),
            child: Opacity(
              opacity: (1 - progress).clamp(0.0, 1.0),
              child: Icon(
                Icons.favorite,
                size: (20 - (index * 2)).sp,
                color: AppColors.like.withOpacity(0.8),
              ),
            ),
          );
        },
      );
    });
  }

  double cos(double angle) {
    return math.cos(angle);
  }

  double sin(double angle) {
    return math.sin(angle);
  }
}

// Math import


class PulsingHeartWidget extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;

  const PulsingHeartWidget({
    super.key,
    this.size = 24,
    this.color = AppColors.like,
    this.duration = const Duration(milliseconds: 1000),
  });

  @override
  State<PulsingHeartWidget> createState() => _PulsingHeartWidgetState();
}

class _PulsingHeartWidgetState extends State<PulsingHeartWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Icon(
            Icons.favorite,
            size: widget.size.sp,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class BounceHeartWidget extends StatefulWidget {
  final double size;
  final Color color;
  final VoidCallback? onTap;
  final bool isLiked;

  const BounceHeartWidget({
    super.key,
    this.size = 24,
    this.color = AppColors.like,
    this.onTap,
    this.isLiked = false,
  });

  @override
  State<BounceHeartWidget> createState() => _BounceHeartWidgetState();
}

class _BounceHeartWidgetState extends State<BounceHeartWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
    
    if (widget.onTap != null) {
      widget.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Icon(
              widget.isLiked ? Icons.favorite : Icons.favorite_border,
              size: widget.size.sp,
              color: widget.isLiked ? widget.color : AppColors.textPrimary,
            ),
          );
        },
      ),
    );
  }
}

class ParticleHeartWidget extends StatefulWidget {
  final double size;
  final VoidCallback? onAnimationComplete;

  const ParticleHeartWidget({
    super.key,
    this.size = 100,
    this.onAnimationComplete,
  });

  @override
  State<ParticleHeartWidget> createState() => _ParticleHeartWidgetState();
}

class _ParticleHeartWidgetState extends State<ParticleHeartWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _particles = List.generate(12, (index) => Particle());
    
    _controller.forward().then((_) {
      if (widget.onAnimationComplete != null) {
        widget.onAnimationComplete!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: ParticleHeartPainter(
              particles: _particles,
              progress: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class Particle {
  late double x;
  late double y;
  late double vx;
  late double vy;
  late double size;
  late Color color;

  Particle() {
    final random = math.Random();
    x = 0;
    y = 0;
    vx = (random.nextDouble() - 0.5) * 4;
    vy = (random.nextDouble() - 0.5) * 4;
    size = random.nextDouble() * 8 + 4;
    color = AppColors.like.withOpacity(random.nextDouble() * 0.8 + 0.2);
  }
}

class ParticleHeartPainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  ParticleHeartPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw main heart
    paint.color = AppColors.like;
    final heartPath = _createHeartPath(centerX, centerY, 30 * (1 - progress * 0.3));
    canvas.drawPath(heartPath, paint);

    // Draw particles
    for (int i = 0; i < particles.length; i++) {
      final particle = particles[i];
      
      // Update particle position
      particle.x = centerX + particle.vx * progress * 50;
      particle.y = centerY + particle.vy * progress * 50;
      
      // Draw particle
      paint.color = particle.color.withOpacity(1 - progress);
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size * (1 - progress),
        paint,
      );
    }
  }

  Path _createHeartPath(double centerX, double centerY, double size) {
    final path = Path();
    
    // Simplified heart shape
    path.moveTo(centerX, centerY + size * 0.3);
    
    // Left curve
    path.cubicTo(
      centerX - size * 0.5, centerY - size * 0.2,
      centerX - size * 0.5, centerY - size * 0.6,
      centerX - size * 0.2, centerY - size * 0.6,
    );
    
    // Top left to center
    path.cubicTo(
      centerX - size * 0.1, centerY - size * 0.6,
      centerX, centerY - size * 0.3,
      centerX, centerY,
    );
    
    // Center to top right
    path.cubicTo(
      centerX, centerY - size * 0.3,
      centerX + size * 0.1, centerY - size * 0.6,
      centerX + size * 0.2, centerY - size * 0.6,
    );
    
    // Right curve
    path.cubicTo(
      centerX + size * 0.5, centerY - size * 0.6,
      centerX + size * 0.5, centerY - size * 0.2,
      centerX, centerY + size * 0.3,
    );
    
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

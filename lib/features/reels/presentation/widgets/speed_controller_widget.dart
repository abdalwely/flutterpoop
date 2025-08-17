import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';

class SpeedControllerWidget extends StatefulWidget {
  final double currentSpeed;
  final Function(double) onSpeedChanged;

  const SpeedControllerWidget({
    super.key,
    required this.currentSpeed,
    required this.onSpeedChanged,
  });

  @override
  State<SpeedControllerWidget> createState() => _SpeedControllerWidgetState();
}

class _SpeedControllerWidgetState extends State<SpeedControllerWidget> {
  late double _speed;
  
  final List<double> _speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _speed = widget.currentSpeed;
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
            'سرعة التشغيل',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
          SizedBox(height: 20.h),
          
          // Speed options
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            children: _speedOptions.map((speed) => _buildSpeedOption(speed)).toList(),
          ),
          
          SizedBox(height: 20.h),
          
          // Custom speed slider
          Text(
            'سرعة مخصصة',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
          SizedBox(height: 12.h),
          
          Row(
            children: [
              Text(
                '0.5x',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                  fontFamily: 'Cairo',
                ),
              ),
              Expanded(
                child: Slider(
                  value: _speed,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  onChanged: (value) {
                    setState(() => _speed = value);
                  },
                  onChangeEnd: (value) {
                    widget.onSpeedChanged(value);
                  },
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.border,
                ),
              ),
              Text(
                '2.0x',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          
          Center(
            child: Text(
              '${_speed.toStringAsFixed(2)}x',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildSpeedOption(double speed) {
    final isSelected = _speed == speed;
    
    return GestureDetector(
      onTap: () {
        setState(() => _speed = speed);
        widget.onSpeedChanged(speed);
      },
      child: Container(
        width: 80.w,
        height: 40.h,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Center(
          child: Text(
            '${speed}x',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.white : AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
        ),
      ),
    );
  }
}

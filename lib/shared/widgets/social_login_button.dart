import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';

class SocialLoginButton extends StatelessWidget {
  final String text;
  final String? icon;
  final IconData? iconData;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final bool isLoading;
  final double? width;
  final double? height;

  const SocialLoginButton({
    super.key,
    required this.text,
    this.icon,
    this.iconData,
    this.onPressed,
    this.backgroundColor = AppColors.white,
    this.textColor = AppColors.textPrimary,
    this.borderColor,
    this.isLoading = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 50.h,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(
            color: borderColor ?? AppColors.border,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20.w,
                height: 20.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  if (icon != null) ...[
                    Image.asset(
                      icon!,
                      width: 20.w,
                      height: 20.h,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.error_outline,
                          size: 20.sp,
                          color: AppColors.error,
                        );
                      },
                    ),
                    SizedBox(width: 12.w),
                  ] else if (iconData != null) ...[
                    Icon(
                      iconData,
                      size: 20.sp,
                      color: textColor,
                    ),
                    SizedBox(width: 12.w),
                  ],
                  
                  // Text
                  Flexible(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                        fontFamily: 'Cairo',
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// Specialized Social Login Buttons

class GoogleLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? text;

  const GoogleLoginButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    return SocialLoginButton(
      text: text ?? 'متابعة بحساب Google',
      iconData: Icons.g_mobiledata,
      backgroundColor: AppColors.white,
      textColor: AppColors.textPrimary,
      borderColor: AppColors.border,
      onPressed: onPressed,
      isLoading: isLoading,
    );
  }
}

class FacebookLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? text;

  const FacebookLoginButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    return SocialLoginButton(
      text: text ?? 'متابعة بحساب Facebook',
      iconData: Icons.facebook,
      backgroundColor: AppColors.facebookBlue,
      textColor: AppColors.white,
      onPressed: onPressed,
      isLoading: isLoading,
    );
  }
}

class AppleLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? text;

  const AppleLoginButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    return SocialLoginButton(
      text: text ?? 'متابعة بحساب Apple',
      iconData: Icons.apple,
      backgroundColor: AppColors.black,
      textColor: AppColors.white,
      onPressed: onPressed,
      isLoading: isLoading,
    );
  }
}

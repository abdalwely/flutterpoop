import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final bool enabled;
  final int maxLines;
  final int? maxLength;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? initialValue;
  final TextAlign textAlign;
  final TextStyle? style;
  final InputBorder? border;
  final Color? fillColor;
  final bool filled;
  final EdgeInsetsGeometry? contentPadding;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.textInputAction = TextInputAction.done,
    this.focusNode,
    this.autofocus = false,
    this.initialValue,
    this.textAlign = TextAlign.right,
    this.style,
    this.border,
    this.fillColor,
    this.filled = true,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      enabled: enabled,
      maxLines: maxLines,
      maxLength: maxLength,
      textInputAction: textInputAction,
      focusNode: focusNode,
      autofocus: autofocus,
      textAlign: textAlign,
      textDirection: TextDirection.rtl,
      style: style ?? TextStyle(
        fontSize: 16.sp,
        color: AppColors.textPrimary,
        fontFamily: 'Cairo',
      ),
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        prefixIcon: prefixIcon != null 
            ? Icon(
                prefixIcon,
                color: AppColors.textSecondary,
                size: 20.sp,
              )
            : null,
        suffixIcon: suffixIcon,
        border: border ?? OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        fillColor: fillColor ?? AppColors.inputBackground,
        filled: filled,
        contentPadding: contentPadding ?? EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 16.h,
        ),
        hintStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 16.sp,
          fontFamily: 'Cairo',
        ),
        labelStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 16.sp,
          fontFamily: 'Cairo',
        ),
        errorStyle: TextStyle(
          color: AppColors.error,
          fontSize: 12.sp,
          fontFamily: 'Cairo',
        ),
        counterStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12.sp,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }
}

// Search TextField variant
class SearchTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onClear;
  final bool showClearButton;

  const SearchTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.showClearButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(25.r),
        border: Border.all(color: AppColors.border),
      ),
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontSize: 16.sp,
          color: AppColors.textPrimary,
          fontFamily: 'Cairo',
        ),
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.textSecondary,
            size: 20.sp,
          ),
          suffixIcon: showClearButton && controller.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    controller.clear();
                    if (onClear != null) onClear!();
                  },
                  icon: Icon(
                    Icons.clear,
                    color: AppColors.textSecondary,
                    size: 20.sp,
                  ),
                )
              : null,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
          hintStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16.sp,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    );
  }
}

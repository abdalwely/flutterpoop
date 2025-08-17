import 'package:flutter/material.dart';

class AppColors {
  // Private constructor
  AppColors._();

  // Primary Colors (Instagram-like)
  static const Color primary = Color(0xFF405DE6); // Instagram gradient start
  static const Color primaryVariant = Color(0xFF5B51D8);
  static const Color secondary = Color(0xFFC13584); // Instagram gradient middle
  static const Color secondaryVariant = Color(0xFFE1306C); // Instagram gradient end
  static const Color accent = Color(0xFFFD1D1D); // Instagram red
  
  // Basic Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;
  
  // Background Colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color inputBackground = Color(0xFFFAFAFA);
  
  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkInputBackground = Color(0xFF262626);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF262626);
  static const Color textSecondary = Color(0xFF8E8E8E);
  static const Color textTertiary = Color(0xFFC7C7C7);
  static const Color textDisabled = Color(0xFFBDBDBD);
  
  // Dark Text Colors
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFA8A8A8);
  static const Color darkTextTertiary = Color(0xFF737373);
  
  // Border Colors
  static const Color border = Color(0xFFDBDBDB);
  static const Color divider = Color(0xFFEFEFEF);
  static const Color darkBorder = Color(0xFF262626);
  static const Color darkDivider = Color(0xFF363636);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFED4956);
  static const Color info = Color(0xFF2196F3);
  
  // Social Media Colors
  static const Color facebookBlue = Color(0xFF1877F2);
  static const Color googleRed = Color(0xFFDB4437);
  static const Color twitterBlue = Color(0xFF1DA1F2);
  
  // Action Colors
  static const Color like = Color(0xFFED4956); // Instagram heart red
  static const Color share = Color(0xFF262626);
  static const Color save = Color(0xFF262626);
  static const Color comment = Color(0xFF262626);
  
  // Story Colors
  static const Color storyBorder = Color(0xFFE1306C);
  static const Color storyViewed = Color(0xFF8E8E8E);
  
  // Online Status
  static const Color online = Color(0xFF4CAF50);
  static const Color offline = Color(0xFF8E8E8E);
  
  // Gradient Colors
  static const LinearGradient instagramGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF405DE6), // Blue
      Color(0xFF5B51D8), // Purple
      Color(0xFF833AB4), // Purple
      Color(0xFFC13584), // Pink
      Color(0xFFE1306C), // Pink-Red
      Color(0xFFFD1D1D), // Red
      Color(0xFFE8342B), // Red-Orange
    ],
  );
  
  static const LinearGradient storyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE1306C),
      Color(0xFFFFDC80),
    ],
  );
  
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF121212),
      Color(0xFF000000),
    ],
  );
  
  // Shadow Colors
  static const Color shadow = Color(0x1A000000);
  static const Color darkShadow = Color(0x1AFFFFFF);
  
  // Overlay Colors
  static const Color overlay = Color(0x80000000);
  static const Color lightOverlay = Color(0x40000000);
  
  // Chat Colors
  static const Color sentMessage = Color(0xFF3897F0);
  static const Color receivedMessage = Color(0xFFEFEFEF);
  static const Color darkSentMessage = Color(0xFF3897F0);
  static const Color darkReceivedMessage = Color(0xFF262626);
  
  // Notification Colors
  static const Color notificationDot = Color(0xFFED4956);
  static const Color badgeBackground = Color(0xFFED4956);
  
  // Button Colors
  static const Color buttonPrimary = primary;
  static const Color buttonSecondary = Color(0xFFEFEFEF);
  static const Color buttonDanger = error;
  static const Color buttonSuccess = success;
  
  // Input Colors
  static const Color inputFocused = primary;
  static const Color inputError = error;
  static const Color inputSuccess = success;
  
  // Loading Colors
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color darkShimmerBase = Color(0xFF2C2C2C);
  static const Color darkShimmerHighlight = Color(0xFF3A3A3A);
  
  // Helper Methods
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
  
  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
  
  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}

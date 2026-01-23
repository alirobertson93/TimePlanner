import 'package:flutter/material.dart';

/// Application color constants
///
/// WCAG 2.1 AA Contrast Requirements:
/// - Normal text: 4.5:1 minimum contrast ratio
/// - Large text (18pt+): 3:1 minimum contrast ratio
/// - UI components: 3:1 minimum contrast ratio
class AppColors {
  AppColors._();

  // Primary colors
  static const Color primary =
      Color(0xFF1976D2); // Darker blue for better contrast
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFFBBDEFB);

  // Accent colors
  static const Color accent =
      Color(0xFF00897B); // Darker teal for better contrast
  static const Color accentDark = Color(0xFF00695C);

  // Background colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface =
      Color(0xFFFAFAFA); // Slightly lighter for better text contrast

  // Text colors - all meet WCAG 2.1 AA 4.5:1 ratio on white/surface backgrounds
  static const Color textPrimary = Color(0xFF212121); // ~16:1 on white
  static const Color textSecondary =
      Color(0xFF616161); // ~5.9:1 on white (was #757575 ~4.6:1)
  static const Color textHint =
      Color(0xFF757575); // ~4.6:1 on white (was #9E9E9E ~3.5:1)

  // Status colors - designed for sufficient contrast
  static const Color success = Color(0xFF2E7D32); // Darker green for text use
  static const Color successBackground =
      Color(0xFFE8F5E9); // Light green background
  static const Color warning =
      Color(0xFFE65100); // Darker orange for text use (was #FFC107)
  static const Color warningBackground =
      Color(0xFFFFF3E0); // Light orange background
  static const Color error =
      Color(0xFFC62828); // Darker red for better contrast
  static const Color errorBackground =
      Color(0xFFFFEBEE); // Light red background
  static const Color info = Color(0xFF1565C0); // Darker blue for text use

  // Default category colors (adjusted for accessibility when used as text)
  // When used on white background, these work for icons/badges (3:1 minimum for UI)
  // When used with text overlays, use white text on these colors
  static const Color categoryWork = Color(0xFF1565C0); // Darker blue
  static const Color categoryPersonal = Color(0xFF2E7D32); // Darker green
  static const Color categoryFamily = Color(0xFFEF6C00); // Darker orange
  static const Color categoryHealth = Color(0xFFC62828); // Darker red
  static const Color categoryCreative = Color(0xFF6A1B9A); // Darker purple
  static const Color categoryChores = Color(0xFF546E7A); // Darker gray
  static const Color categorySocial = Color(0xFFE65100); // Darker orange
}

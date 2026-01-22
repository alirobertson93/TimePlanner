import 'package:flutter/material.dart';

/// Color utility functions
class ColorUtils {
  ColorUtils._();

  /// Default category color (blue) when parsing fails or category is unavailable
  static const Color defaultCategoryColor = Color(0xFF2196F3);

  /// Parses a hex color string to a Flutter Color
  /// 
  /// Supports formats:
  /// - "#RRGGBB" (with hash)
  /// - "RRGGBB" (without hash)
  /// 
  /// Returns [defaultColor] if parsing fails
  static Color parseHexColor(String? hexString, {Color defaultColor = defaultCategoryColor}) {
    if (hexString == null || hexString.isEmpty) {
      return defaultColor;
    }

    try {
      final cleanHex = hexString.replaceFirst('#', '');
      return Color(int.parse('0xFF$cleanHex'));
    } catch (e) {
      debugPrint('Invalid color format: $e');
      return defaultColor;
    }
  }
}

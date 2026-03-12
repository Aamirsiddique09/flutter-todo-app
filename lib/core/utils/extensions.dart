// lib/core/utils/theme_extensions.dart

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

extension ThemeContextExtensions on BuildContext {
  /// Check if dark mode
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Get glass background color based on theme
  Color get glassBackground => isDarkMode
      ? Colors.white.withOpacity(0.05)
      : Colors.white.withOpacity(0.7);

  /// Get glass border color based on theme
  Color get glassBorderColor => isDarkMode
      ? Colors.white.withOpacity(0.1)
      : Colors.white.withOpacity(0.3);

  /// Get primary gradient
  Gradient get primaryGradient => const LinearGradient(
    colors: [AppColors.primary, AppColors.accentPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Get glass gradient based on theme
  Gradient get glassGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: isDarkMode
        ? [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]
        : [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)],
  );

  /// Get card shadow based on theme
  BoxShadow get cardShadow => BoxShadow(
    color: isDarkMode
        ? Colors.black.withOpacity(0.3)
        : Colors.black.withOpacity(0.08),
    blurRadius: 20,
    offset: const Offset(0, 8),
  );

  /// Get glass shadow based on theme
  BoxShadow get glassShadow => BoxShadow(
    color: isDarkMode
        ? Colors.black.withOpacity(0.4)
        : Colors.black.withOpacity(0.1),
    blurRadius: 30,
    offset: const Offset(0, 10),
  );
}

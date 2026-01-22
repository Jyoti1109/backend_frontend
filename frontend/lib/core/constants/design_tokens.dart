import 'package:flutter/material.dart';

/// Unified design system for consistent UI across all screens
class DesignTokens {
  // Light theme colors
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color backgroundWhite = Colors.white;
  static const Color surfaceGray = Color(0xFFF8F9FA);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);
  static const Color borderLight = Color(0xFFE5E5E5);
  static const Color iconInactive = Color(0xFF9E9E9E);
  
  // Dark theme colors - improved contrast
  static const Color darkBackground = Color(0xFF212121); // grey[850]
  static const Color darkSurface = Color(0xFF424242); // grey[800]
  static const Color darkTextPrimary = Color(0xFFFFFFFF); // white87
  static const Color darkTextSecondary = Color(0xFFE0E0E0); // grey[200]
  static const Color darkTextTertiary = Color(0xFFBDBDBD); // grey[400]
  static const Color darkIconInactive = Color(0xFF757575); // grey[600]
  static const Color darkBorder = Color(0xFF616161); // grey[700]
  
  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  
  // Border radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  
  // Icon sizes
  static const double iconS = 20.0;
  static const double iconM = 24.0;
  static const double iconL = 28.0;
  
  // Typography
  static const TextStyle headingLarge = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.2,
  );
  
  static const TextStyle headingMedium = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );
  
  static const TextStyle headingSmall = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.4,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    color: textTertiary,
    height: 1.3,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );
  
  // Dark theme typography
  static const TextStyle darkHeadingLarge = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.w600,
    color: darkTextPrimary,
    height: 1.2,
  );
  
  static const TextStyle darkHeadingMedium = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
    color: darkTextPrimary,
    height: 1.3,
  );
  
  static const TextStyle darkBodyLarge = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    color: darkTextSecondary,
    height: 1.5,
  );
  
  static const TextStyle darkBodyMedium = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    color: darkTextSecondary,
    height: 1.4,
  );
  
  static const TextStyle darkBodySmall = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    color: darkTextTertiary,
    height: 1.3,
  );
  
  // Card styles
  static BoxDecoration cardDecoration = BoxDecoration(
    color: backgroundWhite,
    borderRadius: BorderRadius.circular(radiusL),
    border: Border.all(color: primaryGreen, width: 1.0),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  static BoxDecoration darkCardDecoration = BoxDecoration(
    color: darkSurface,
    borderRadius: BorderRadius.circular(radiusL),
    border: Border.all(color: primaryGreen, width: 1.0),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  // Bottom navigation style
  static const BottomNavigationBarThemeData bottomNavTheme = BottomNavigationBarThemeData(
    type: BottomNavigationBarType.fixed,
    selectedItemColor: primaryGreen,
    unselectedItemColor: iconInactive,
    backgroundColor: backgroundWhite,
    elevation: 8,
    selectedLabelStyle: TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 11,
    ),
    unselectedLabelStyle: TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 10,
    ),
  );
  
  // Notification icon styles
  static Widget notificationIcon({bool hasNotifications = false}) {
    return Stack(
      children: [
        Icon(
          Icons.notifications_outlined,
          size: iconM,
          color: hasNotifications ? primaryGreen : iconInactive,
        ),
        if (hasNotifications)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: primaryGreen,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
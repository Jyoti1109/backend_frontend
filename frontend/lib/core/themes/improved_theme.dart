// improved_theme.dart
import 'package:flutter/material.dart';

class ImprovedTheme {
  // Primary Colors
  static const Color primaryGreen = Color(0xFF68BB59);
  static const Color primaryPink = Color(0xFFE91E63); // NEW

  // Semantic Colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);
  static const Color infoBlue = Color(0xFF2196F3);

  // Grays
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFEEEEEE);
  static const Color gray300 = Color(0xFFE0E0E0);
  static const Color gray400 = Color(0xFFBDBDBD);
  static const Color gray500 = Color(0xFF9E9E9E);
  static const Color gray600 = Color(0xFF757575);
  static const Color gray700 = Color(0xFF616161);
  static const Color gray800 = Color(0xFF424242);
  static const Color gray900 = Color(0xFF212121);

  // Spacing
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;

  // Radius
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;

  // Typography (same for both themes)
  static const TextStyle displayLarge = TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: -0.5);
  static const TextStyle headingLarge = TextStyle(fontSize: 24, fontWeight: FontWeight.w600, height: 1.3);
  static const TextStyle headingMedium = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3);
  static const TextStyle headingSmall = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4);
  static const TextStyle bodyLarge = TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);
  static const TextStyle bodyMedium = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.4);
  static const TextStyle bodySmall = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.3);
  static const TextStyle labelLarge = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1);
  static const TextStyle labelMedium = TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5);
  static const TextStyle labelSmall = TextStyle(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 1.5);

  // Button Styles – Green
  static ButtonStyle primaryGreenButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryGreen,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMD)),
  );

  static ButtonStyle secondaryGreenButtonStyle = OutlinedButton.styleFrom(
    side: BorderSide(color: primaryGreen),
    foregroundColor: primaryGreen,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMD)),
  );

  // Button Styles – Pink (NEW)
  static ButtonStyle primaryPinkButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryPink,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMD)),
  );

  static ButtonStyle secondaryPinkButtonStyle = OutlinedButton.styleFrom(
    side: BorderSide(color: primaryPink),
    foregroundColor: primaryPink,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMD)),
  );

  // Card Decorations
  static BoxDecoration lightCardDecoration(Color primaryColor) => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radiusLG),
    border: Border.all(color: primaryColor, width: 1),
    boxShadow: [
      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 2)),
    ],
  );

  static BoxDecoration darkCardDecoration(Color primaryColor) => BoxDecoration(
    color: gray800,
    borderRadius: BorderRadius.circular(radiusLG),
    border: Border.all(color: primaryColor, width: 1),
    boxShadow: [
      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: Offset(0, 2)),
    ],
  );
}
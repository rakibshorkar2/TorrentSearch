import 'package:flutter/cupertino.dart';

class TorrentFlowTheme {
  // MARK: - Colors
  static const Color accent = Color(0xFF007AFF);
  static const Color accentLight = Color(0xFF409CFF);
  static const Color accentDark = Color(0xFF0055CC);
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3B30);
  static const Color paused = Color(0xFFFFD60A);
  static const Color stopped = Color(0xFF8E8E93);

  // MARK: - Dark Mode
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color darkSurface2 = Color(0xFF2C2C2E);
  static const Color darkSurface3 = Color(0xFF3A3A3C);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF8E8E93);
  static const Color darkSeparator = Color(0xFF38383A);

  // MARK: - Light Mode
  static const Color lightBackground = Color(0xFFF2F2F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFF2F2F7);
  static const Color lightText = Color(0xFF000000);
  static const Color lightTextSecondary = Color(0xFF8E8E93);
  static const Color lightSeparator = Color(0xFFC6C6C8);

  static const Color glassLight = Color(0xCCFFFFFF);
  static const Color glassDark = Color(0xCC1C1C1E);
  static const Color glassBorderLight = Color(0x3DFFFFFF);
  static const Color glassBorderDark = Color(0x3D8E8E93);

  static const double cornerRadius = 13;
  static const double cornerRadiusLarge = 20;
  static const double standardPadding = 16;
  static const double tightPadding = 8;
  static const double spacing = 12;

  static const Color healthGreen = Color(0xFF34C759);
  static const Color healthYellow = Color(0xFFFF9500);
  static const Color healthRed = Color(0xFFFF3B30);

  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 350);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // MARK: - Typography
  static const TextStyle largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.37,
  );
  static const TextStyle title1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.36,
  );
  static const TextStyle title2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.35,
  );
  static const TextStyle title3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.38,
  );
  static const TextStyle headline = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.41,
  );
  static const TextStyle body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.41,
  );
  static const TextStyle callout = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.32,
  );
  static const TextStyle subheadline = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.24,
  );
  static const TextStyle footnote = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.08,
  );
  static const TextStyle caption1 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  static const TextStyle caption2 = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.07,
  );

  // MARK: - Shadows
  static List<BoxShadow> glassShadow(bool isDark) => [
    BoxShadow(
      color: isDark ? const Color(0xFF000000).withValues(alpha: 0.5) : const Color(0xFF000000).withValues(alpha: 0.1),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: isDark ? const Color(0xFF000000).withValues(alpha: 0.3) : const Color(0xFF000000).withValues(alpha: 0.05),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // MARK: - Status Bar
  static void configureStatusBar() {}
}

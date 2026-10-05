import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Eco-Move Nagpur Design System
/// Light theme with crisp daylight aesthetic inspired by Apple Maps, Linear, Citymapper.
class AppTheme {
  AppTheme._();

  // ─── Color Palette ───────────────────────────────────────────────
  static const Color background = Color(0xFFFFFFFF);
  static const Color surfaceTint = Color(0xFFF8FAFC);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color cardShadow = Color(0x0D0F172A); // rgba(15,23,42,0.05)

  static const Color primaryGreen = Color(0xFF059669);   // Emerald 600 — Eco/Bus
  static const Color primaryGreenLight = Color(0xFFD1FAE5); // Emerald 100
  static const Color primaryGreenDark = Color(0xFF047857);  // Emerald 700

  static const Color metroOrange = Color(0xFFEA580C);       // Nagpur Metro Orange Line
  static const Color metroOrangeLight = Color(0xFFFFF7ED);   // Orange 50
  static const Color metroOrangeBg = Color(0xFFFED7AA);      // Orange 200

  static const Color metroAqua = Color(0xFF0284C7);          // Sky — Aqua Line
  static const Color metroAquaLight = Color(0xFFF0F9FF);     // Sky 50
  static const Color metroAquaBg = Color(0xFFBAE6FD);        // Sky 200

  static const Color textPrimary = Color(0xFF0F172A);   // Slate 900
  static const Color textSecondary = Color(0xFF475569);  // Slate 600
  static const Color textTertiary = Color(0xFF94A3B8);   // Slate 400
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color divider = Color(0xFFE2E8F0);
  static const Color inputFill = Color(0xFFF1F5F9);     // Slate 100
  static const Color chipBg = Color(0xFFF8FAFC);

  static const Color warning = Color(0xFFF59E0B);       // Amber 500
  static const Color error = Color(0xFFEF4444);          // Red 500
  static const Color success = Color(0xFF10B981);        // Emerald 500

  // ─── Shadows ─────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadows => [
    BoxShadow(
      color: cardShadow,
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get subtleShadows => [
    BoxShadow(
      color: cardShadow.withValues(alpha: 0.03),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get elevatedShadows => [
    BoxShadow(
      color: cardShadow.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  // ─── Card Decorations ────────────────────────────────────────────
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: background,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: cardBorder, width: 1),
    boxShadow: cardShadows,
  );

  static BoxDecoration get surfaceDecoration => BoxDecoration(
    color: surfaceTint,
    borderRadius: BorderRadius.circular(12),
  );

  static BoxDecoration get inputDecoration => BoxDecoration(
    color: inputFill,
    borderRadius: BorderRadius.circular(12),
  );

  // ─── ThemeData ───────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        onPrimary: textOnPrimary,
        secondary: metroOrange,
        tertiary: metroAqua,
        surface: background,
        onSurface: textPrimary,
        surfaceContainerHighest: surfaceTint,
        outline: cardBorder,
        error: error,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 32,
          letterSpacing: -1.0,
        ),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 24,
          letterSpacing: -0.5,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 20,
          letterSpacing: -0.3,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: textSecondary,
          fontWeight: FontWeight.w400,
          fontSize: 16,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: textSecondary,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: textTertiary,
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        labelMedium: baseTextTheme.labelMedium?.copyWith(
          color: textSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        labelSmall: baseTextTheme.labelSmall?.copyWith(
          color: textTertiary,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: baseTextTheme.headlineMedium?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
        iconTheme: const IconThemeData(color: textPrimary, size: 22),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: background,
        selectedItemColor: primaryGreen,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: chipBg,
        selectedColor: primaryGreenLight,
        side: const BorderSide(color: cardBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textSecondary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textTertiary, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: background,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }
}

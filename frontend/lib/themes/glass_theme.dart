import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';

class GlassTheme {
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color accentColor = Color(0xFF00D2FF);
  static const Color backgroundColor = Color(0xFF0F172A);

  static ThemeData get theme {
    return darkTheme;
  }

  static ThemeData get darkTheme {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
        ).copyWith(
          primary: primaryColor,
          secondary: accentColor,
          surface: backgroundColor,
        );

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get lightTheme {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF4F46E5),
          secondary: const Color(0xFF0284C7),
          surface: const Color(0xFFF8FAFC),
          surfaceContainerHighest: const Color(0xFFE2E8F0),
        );

    return ThemeData(
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant.withOpacity(0.45)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.primary,
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        secondaryLabelStyle: TextStyle(color: scheme.onPrimary),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
      ),
      useMaterial3: true,
    );
  }

  // Simplified glassCard to improve compatibility with emulators/hardware
  static Widget glassCard({
    required BuildContext context,
    required Widget child,
    double? width,
    double? height,
    double blur = 0, // Ignored in simplified version for stability
    double border = 1.0,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.15)
              : scheme.outlineVariant.withOpacity(0.4),
          width: border,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.18)
                : scheme.primary.withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

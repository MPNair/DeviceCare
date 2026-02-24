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
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: backgroundColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      useMaterial3: true,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: Color(0xFFF0F2F5),
      ),
      scaffoldBackgroundColor: Color(0xFFF0F2F5),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
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
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark 
          ? Colors.white.withOpacity(0.08) 
          : Colors.white.withOpacity(0.7),
        border: Border.all(
          color: isDark 
            ? Colors.white.withOpacity(0.15) 
            : Colors.white.withOpacity(0.4),
          width: border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }
}

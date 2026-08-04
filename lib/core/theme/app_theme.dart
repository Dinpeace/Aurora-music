import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFFA855F7);
  static const Color secondary = Color(0xFF22D3EE);

  static const Color background = Color(0xFF09090B);
  static const Color surface = Color(0xFF18181B);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,

      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
      ),

      textTheme: GoogleFonts.plusJakartaSansTextTheme(),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(),
    );
  }
}
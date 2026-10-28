import 'package:flutter/material.dart';

class FocusXColors {
  static const background = Color(0xFF0B0D12);
  static const surface = Color(0xFF141821);
  static const elevated = Color(0xFF1B202B);
  static const green = Color(0xFFB7FF5B);
  static const violet = Color(0xFF9275FF);
  static const muted = Color(0xFF9AA3B2);
  static const divider = Color(0xFF282E3A);
}

class FocusXTheme {
  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: FocusXColors.green,
      brightness: Brightness.dark,
      surface: FocusXColors.surface,
    ).copyWith(
      primary: FocusXColors.green,
      secondary: FocusXColors.violet,
      surface: FocusXColors.surface,
      onPrimary: FocusXColors.background,
      onSurface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: FocusXColors.background,
      fontFamily: 'Arial',
      appBarTheme: const AppBarTheme(
        backgroundColor: FocusXColors.background,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: FocusXColors.divider,
        thickness: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: FocusXColors.surface,
        indicatorColor: FocusXColors.green.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            color: states.contains(WidgetState.selected)
                ? FocusXColors.green
                : FocusXColors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FocusXColors.elevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

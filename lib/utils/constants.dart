import 'package:flutter/material.dart';

/// App-wide colors. Modern, clean green + white palette.
class AppColors {
  static const Color primaryGreen = Color(0xFF0E9F6E); // modern emerald
  static const Color darkGreen = Color(0xFF0B7A54);
  static const Color lightGreen = Color(0xFFE7F8F1);
  static const Color accent = Color(0xFF25D366); // WhatsApp green accent
  static const Color danger = Color(0xFFE0333B); // Lena hai (red)
  static const Color safe = Color(0xFF16A34A); // 0 balance (green)
  static const Color background = Color(0xFFF6F8F9);
  static const Color surface = Colors.white;
  static const Color textMuted = Color(0xFF6B7280);
}

/// Format a number as whole-rupee currency string, e.g. "Rs. 3,500"
String formatRs(num amount) {
  final rounded = amount.round();
  final str = rounded.abs().toString();
  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    final posFromEnd = str.length - i;
    buffer.write(str[i]);
    if (posFromEnd > 1 && (posFromEnd - 1) % 3 == 0) {
      buffer.write(',');
    }
  }
  final sign = rounded < 0 ? '-' : '';
  return 'Rs. $sign${buffer.toString()}';
}

/// Standard app-wide theme - Material 3, modern rounded look.
ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primaryGreen,
    primary: AppColors.primaryGreen,
    surface: AppColors.surface,
  );

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: colorScheme,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: Colors.black87,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: AppColors.surface,
      titleTextStyle: TextStyle(
        color: Colors.black87,
        fontSize: 19,
        fontWeight: FontWeight.w700,
      ),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(fontSize: 16),
      bodyLarge: TextStyle(fontSize: 18),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.lightGreen,
      elevation: 2,
      height: 66,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? AppColors.darkGreen : AppColors.textMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? AppColors.darkGreen : AppColors.textMuted);
      }),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: AppColors.surface,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}

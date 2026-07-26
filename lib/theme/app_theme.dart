import 'package:flutter/material.dart';

/// Color palette carried over from the original prototype design
/// (warm paper / craft tailoring theme), with the primary "thread" accent
/// in plum/purple.
class AppColors {
  AppColors._();

  static const paper = Color(0xFFEDE4D2);
  static const paperDark = Color(0xFFE1D5B8);
  static const cream = Color(0xFFFAF6EC);
  static const ink = Color(0xFF2B2A28);
  static const inkSoft = Color(0xFF6B6558);
  static const thread = Color(0xFF6C4A80);
  static const threadDark = Color(0xFF4A3159);
  static const pin = Color(0xFFB3402F);
  static const gold = Color(0xFFC08F1E);
  static const dashedBorder = Color(0xFFB8AD8F);
  static const inputBorder = Color(0xFFD8CBA8);
}

/// The small uppercase heading used above a section of content (e.g.
/// "MEASUREMENTS", "UPCOMING PICKUPS") — kept in one place so every screen
/// uses the exact same size, weight, and letter spacing.
const sectionLabelStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  color: AppColors.inkSoft,
  letterSpacing: 0.5,
);

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.thread,
      primary: AppColors.thread,
      secondary: AppColors.gold,
      error: AppColors.pin,
      surface: AppColors.cream,
    ),
    scaffoldBackgroundColor: AppColors.paper,
  );

  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.paper,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        color: AppColors.ink,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.cream,
      indicatorColor: AppColors.thread.withValues(alpha: 0.15),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? AppColors.threadDark : AppColors.inkSoft,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? AppColors.threadDark : AppColors.inkSoft,
        );
      }),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.thread,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: Color(0xFFC9BC98)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.thread, width: 2),
      ),
    ),
    cardTheme: const CardThemeData(
      color: AppColors.cream,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        side: BorderSide(color: AppColors.dashedBorder, width: 1.5),
      ),
    ),
    dividerColor: AppColors.inputBorder,
  );
}

import 'package:flutter/material.dart';

/// True Apple iOS Dark Glass Color System
/// Clean, restrained, authentic Apple Human Interface Guidelines aesthetic (no neon disco)
class AppColors {
  AppColors._();

  // Pure Apple OLED Black Backgrounds
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF1C1C1E);
  static const Color surfaceElevated = Color(0xFF2C2C2E);
  static const Color surfaceSubtle = Color(0xFF141416);

  // iOS Frosted Glass Layer Tints (Clean neutral translucent white/slate)
  static const Color glassFill = Color(0x731C1C1E); // ~45% iOS dark blur
  static const Color glassFillLight = Color(0x1AFFFFFF); // 10% white for highlight
  static const Color glassBorder = Color(0x1FFFFFFF); // 12% white crisp border
  static const Color glassBorderSubtle = Color(0x12FFFFFF); // 7% white

  // Native Apple System Colors (iOS 18)
  static const Color iosBlue = Color(0xFF0A84FF); // Apple system blue
  static const Color iosGreen = Color(0xFF30D158); // Apple system green
  static const Color iosRed = Color(0xFFFF453A); // Apple system red
  static const Color iosOrange = Color(0xFFFF9F0A); // Apple system orange
  static const Color iosYellow = Color(0xFFFFD60A); // Apple system yellow
  static const Color iosPurple = Color(0xFFBF5AF2); // Apple system purple
  static const Color iosIndigo = Color(0xFF5E5CE6); // Apple system indigo
  static const Color iosTeal = Color(0xFF64D2FF); // Apple system teal
  static const Color iosGray = Color(0xFF8E8E93); // Apple system gray

  // Text Hierarchy (Apple SF Style)
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textMuted = Color(0xFF636366);
  static const Color textLight = Color(0xFFEBEBF5);

  // Capybara Warm Zen Color Palette
  static const Color capybaraAmber = Color(0xFFE09F3E); // Primary warm honey amber
  static const Color capybaraGold = Color(0xFFF5A623); // Golden caramel highlight
  static const Color capybaraCopper = Color(0xFFC87D20); // Deep warm copper
  static const Color capybaraDark = Color(0xFF181512); // Deep warm glass dark surface
  static const Color capybaraGlow = Color(0x4DE09F3E); // Soft golden aura

  // Financial Accents (Primary is Capybara Amber)
  static const Color primary = capybaraAmber;
  static const Color income = iosGreen;
  static const Color expense = iosRed;
  static const Color warning = capybaraGold;

  // Restrained Minimalist Duotone Design System (Deep Black & Warm Capybara Amber)
  // Two unified colors: Obsidian/Graphite base + Signature Warm Amber accent
  static const Color catGroceries = capybaraAmber;
  static const Color catTransport = capybaraAmber;
  static const Color catHousing = capybaraAmber;
  static const Color catRestaurants = capybaraAmber;
  static const Color catHealth = capybaraAmber;
  static const Color catShopping = capybaraAmber;
  static const Color catEntertainment = capybaraAmber;
  static const Color catSalary = capybaraAmber;
  static const Color catFreelance = capybaraAmber;
  static const Color catOther = Color(0xFF8E8E93);
}

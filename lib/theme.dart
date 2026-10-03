// پرستار من — تم اپ (نسخه ۳ — توابع رنگ context-محور برای مبالغ همیشه‌خوانا)

import 'package:flutter/material.dart';

class AppColors {
  // روز
  static const teal      = Color(0xFF0D9488);
  static const tealDark  = Color(0xFF0B7268);
  static const tealSoft  = Color(0xFFE5F6F4);
  static const bgLight   = Color(0xFFF1FAF8);
  static const cardLight = Color(0xFFFFFFFF);
  static const textLight = Color(0xFF152B28);
  static const subLight  = Color(0xFF5D7A76);
  static const lineLight = Color(0xFFD8ECE9);

  // شب — ته‌مایه سبز، بدون سیاه خالص
  static const bgDark    = Color(0xFF0B1615);
  static const cardDark  = Color(0xFF132725);
  static const tealNight = Color(0xFF2DD4BF);
  static const softDark  = Color(0xFF0E2C28);
  static const textDark  = Color(0xFFDFF5F2);
  static const subDark   = Color(0xFF86A8A3);
  static const lineDark  = Color(0xFF1F3D3A);

  // معنایی
  static const success   = Color(0xFF0F9D6A);
  static const warning   = Color(0xFFB45309);
  static const danger    = Color(0xFFDC2626);
  static const info      = Color(0xFF1D6FB8);

  /// رنگ متن اصلی — بر اساس تم فعلی (برای هر متن ثابت که در هر دو حالت نمایش داده می‌شود)
  static Color textOf(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? textDark : textLight;

  /// رنگ متن کم‌رنگ — context-محور
  static Color subOf(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? subDark : subLight;

  /// رنگ مبلغ — همیشه پررنگ و کاملاً خوانا در هر دو حالت (قاعده: مبالغ هرگز کم‌رنگ!)
  static Color amountOf(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? tealNight : teal;

  /// رنگ خط جداکننده — context-محور
  static Color lineOf(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? lineDark : lineLight;
}

class AppTheme {
  static ThemeData light() => _build(
    bg: AppColors.bgLight, card: AppColors.cardLight,
    primary: AppColors.teal, onPrimary: Colors.white,
    text: AppColors.textLight, sub: AppColors.subLight,
    line: AppColors.lineLight, soft: AppColors.tealSoft,
    brightness: Brightness.light,
  );

  static ThemeData dark() => _build(
    bg: AppColors.bgDark, card: AppColors.cardDark,
    primary: AppColors.tealNight, onPrimary: AppColors.bgDark,
    text: AppColors.textDark, sub: AppColors.subDark,
    line: AppColors.lineDark, soft: AppColors.softDark,
    brightness: Brightness.dark,
  );

  static ThemeData _build({
    required Color bg, required Color card, required Color primary,
    required Color onPrimary, required Color text, required Color sub,
    required Color line, required Color soft,
    required Brightness brightness,
  }) {
    final scheme = ColorScheme(
      primary: primary, onPrimary: onPrimary,
      secondary: primary, surface: card, onSurface: text,
      error: AppColors.danger, onError: Colors.white,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      fontFamily: 'Vazirmatn',
      materialTapTargetSize: MaterialTapTargetSize.padded,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.teal, foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size.fromHeight(48),
          side: BorderSide(color: primary, width: 1.5),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: line, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: line, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        hintStyle: TextStyle(color: sub, fontSize: 13),
      ),
      cardTheme: CardThemeData(
        color: card, elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: line),
        ),
      ),
      textTheme: TextTheme(
        titleLarge:   TextStyle(color: text, fontSize: 20, fontWeight: FontWeight.bold),
        titleMedium:  TextStyle(color: text, fontSize: 15, fontWeight: FontWeight.bold),
        bodyMedium:   TextStyle(color: text, fontSize: 13),
        bodySmall:    TextStyle(color: sub,  fontSize: 11.5),
      ),
    );
  }
}
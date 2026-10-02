// پرستار من — تکه ۸: نقطه شروع اپ
// تصمیم ۳۰: حالت شب سه‌حالته — پیش‌فرض «خودکار» یعنی ThemeMode.system
// (در تکه تنظیمات پروفایل، کاربر می‌تواند روشن/شب/خودکار را انتخاب کند)

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme.dart';
import 'api_client.dart';
import 'screens/login_screen.dart';

void main() => runApp(const ParestarManApp());

class ParestarManApp extends StatelessWidget {
  const ParestarManApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'پرستار من',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system, // تصمیم ۳۰
      locale: const Locale('fa'),  // تصمیم ۱۳: MVP فقط فارسی
      supportedLocales: const [Locale('fa')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: LoginScreen(api: ApiClient(baseUrl: 'http://127.0.0.1:8081/parestaraman-server/public')),
    );
  }
}
// پرستار من — نقطه شروع اپ (نسخه ۲ — حالت شب قابل انتخاب از پروفایل + ذخیره انتخاب)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme.dart';
import 'api_client.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('theme_mode') ?? 'system';
  runApp(ParestarManApp(initialMode: saved));
}

class ParestarManApp extends StatefulWidget {
  const ParestarManApp({super.key, required this.initialMode});
  final String initialMode;

  static _ParestarManAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_ParestarManAppState>()!;

  @override
  State<ParestarManApp> createState() => _ParestarManAppState();
}

class _ParestarManAppState extends State<ParestarManApp> {
  late ThemeMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = switch (widget.initialMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  void setMode(String m) {
    setState(() {
      _mode = switch (m) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    });
    SharedPreferences.getInstance().then((p) => p.setString('theme_mode', m));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'پرستار من',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _mode,
      locale: const Locale('fa'),
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
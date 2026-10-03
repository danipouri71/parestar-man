// پرستار من — نقطه شروع (ریشه اپ در app_root.dart)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_root.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('theme_mode') ?? 'system';
  runApp(ParestarManApp(initialMode: saved));
}
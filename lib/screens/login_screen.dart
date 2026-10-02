// پرستار من — تکه ۸: صفحه ورود (تصمیم ۴ + تایمر ۹۰ ثانیه‌ای تصمیم ۴۱)

import 'dart:async';
import 'package:flutter/material.dart';
import '../api_client.dart';
import '../theme.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobile = TextEditingController();
  final _code   = TextEditingController();
  final _name   = TextEditingController();

  bool _codeSent = false;
  bool _busy = false;
  int _resendIn = 0;
  Timer? _timer;

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  void _startResendTimer() {
    _resendIn = 90; // تصمیم ۴۱ — همان قانون سرور
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendIn <= 0) { t.cancel(); } else { setState(() => _resendIn--); }
    });
  }

  Future<void> _showError(Object e) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(e.toString(), style: const TextStyle(fontSize: 13)),
      backgroundColor: AppColors.danger,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _sendCode() async {
    setState(() => _busy = true);
    try {
      await widget.api.requestOtp(_mobile.text.trim());
      setState(() { _codeSent = true; });
      _startResendTimer();
    } on ApiException catch (e) { _showError(e); }
    finally { setState(() => _busy = false); }
  }

  Future<void> _verify() async {
    setState(() => _busy = true);
    try {
      await widget.api.verifyOtp(_mobile.text.trim(), _code.text.trim(), _name.text.trim());
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => HomeScreen(api: widget.api),
      ));
    } on ApiException catch (e) { _showError(e); }
    finally { setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 48),
              const Text('🩺', textAlign: TextAlign.center, style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text('پرستار من', textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text('خدمات پرستاری در منزل، به سادگی یک لمس',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 40),

              TextField(
                controller: _mobile,
                keyboardType: TextInputType.phone,
                enabled: !_codeSent,
                decoration: const InputDecoration(hintText: 'شماره موبایل — نمونه: ۰۹۱۲۱۲۳۴۵۶۷'),
              ),
              const SizedBox(height: 12),

              if (_codeSent) ...[
                TextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    hintText: 'کد ۶ رقمی پیامک‌شده', counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                      hintText: 'نام و نام خانوادگی (فقط برای ثبت‌نام اولین بار)'),
                ),
                const SizedBox(height: 12),
              ],

              FilledButton(
                onPressed: _busy ? null : (_codeSent ? _verify : _sendCode),
                child: Text(_busy
                    ? 'لطفاً صبر کنید…'
                    : (_codeSent ? 'ورود' : 'دریافت کد تایید')),
              ),

              if (_codeSent) ...[
                const SizedBox(height: 10),
                Text(
                  _resendIn > 0
                      ? 'ارسال مجدد کد تا $_resendIn ثانیه دیگر'
                      : 'کد را دریافت نکردید؟ دوباره تلاش کنید',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 16),
              Text('🔒 هرگز با شما تماس نمی‌گیریم؛ کد تایید را در اختیار هیچ‌کس قرار ندهید.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
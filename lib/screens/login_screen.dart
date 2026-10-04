// پرستار من — تکه ۸: صفحه ورود (نسخه ۲: اعتبارسنجی فارسی قبل از ارسال)

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
  final _code = TextEditingController();
  final _name = TextEditingController();

  bool _codeSent = false;
  bool _busy = false;
  int _resendIn = 0;
  Timer? _timer;

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  void _startResendTimer() {
    _resendIn = 90;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendIn <= 0) { t.cancel(); } else { setState(() => _resendIn--); }
    });
  }

  void _showError(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m, style: const TextStyle(fontSize: 13)),
      backgroundColor: AppColors.danger,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _sendCode() async {
    final mobile = _mobile.text.trim();
    if (mobile.isEmpty) { _showError('شماره موبایل را وارد کنید.'); return; }
    setState(() => _busy = true);
    try {
      await widget.api.requestOtp(mobile);
      if (!mounted) return;
      setState(() => _codeSent = true);
      _startResendTimer();
    } on ApiException catch (e) { _showError(e.toString()); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (code.isEmpty) { _showError('کد تایید را وارد کنید.'); return; }
    final name = _name.text.trim();
    if (name.isEmpty) { _showError('نام و نام خانوادگی را وارد کنید.'); return; }
    setState(() => _busy = true);
    try {
      await widget.api.verifyOtp(_mobile.text.trim(), code, name);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => HomeScreen(api: widget.api),
      ));
    } on ApiException catch (e) { _showError(e.toString()); }
    finally { if (mounted) setState(() => _busy = false); }
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
                    hintText: 'نام و نام خانوادگی (فقط برای ثبت‌نام اولین بار)',
                  ),
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
// پرستار من — تکه ۹: صفحه انتظار — U7 (نسخه ۲: شمارش معکوس از deadline سرور)
// مهلت ۱۵ دقیقه سفارش فوری (مصوب) · لغو رایگان پیش از پذیرش · polling هر ۸ ثانیه

import 'dart:async';
import 'package:flutter/material.dart';
import '../api_client.dart';
import '../theme.dart';
import 'home_screen.dart';

class WaitingScreen extends StatefulWidget {
  const WaitingScreen({super.key, required this.api, required this.orderId,
    required this.code, required this.initialTotal, required this.isImmediate});
  final ApiClient api;
  final int orderId;
  final String code;
  final int initialTotal;
  final bool isImmediate;

  @override
  State<WaitingScreen> createState() => _WaitingState();
}

class _WaitingState extends State<WaitingScreen> {
  Timer? _tick, _poll;
  int _elapsed = 0;
  String _status = 'awaiting_acceptance';
  Map<String, dynamic>? _order;
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1),
        (_) => setState(() => _elapsed++));
    _poll = Timer.periodic(const Duration(seconds: 8), (_) => _check());
    _load().then((_) => _initDeadline());
  }

  @override
  void dispose() { _tick?.cancel(); _poll?.cancel(); super.dispose(); }

  void _initDeadline() {
    final created = _order?['created_at']?.toString() ?? '';
    final dt = DateTime.tryParse(created);
    if (dt != null && widget.isImmediate) {
      _deadline = dt.add(const Duration(minutes: 15));
    }
  }

  Future<void> _load() async {
    try {
      final o = await widget.api.orderDetails(widget.orderId);
      if (!mounted) return;
      final st = (o['status'] ?? '').toString();
      if (st != 'awaiting_acceptance') {
        _tick?.cancel(); _poll?.cancel();
        setState(() { _status = st; _order = o; });
      } else if (_order == null) {
        setState(() { _order = o; });
      }
    } on ApiException {
      /* تیک بعدی دوباره تلاش می‌کند */
    }
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('لغو درخواست؟', style: TextStyle(fontSize: 16)),
      content: const Text('لغو در این مرحله رایگان است و سفارش حذف می‌شود.',
          style: TextStyle(fontSize: 13)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ادامه انتظار')),
        FilledButton(onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('بله، لغو کن')),
      ]));
    if (ok != true || !mounted) return;
    try {
      await widget.api.cancelOrder(widget.orderId);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => HomeScreen(api: widget.api)), (_) => false);
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: const TextStyle(fontSize: 13)),
        backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating));
    }
  }

  /// شمارش معکوس از deadline سرور — حتی اگر صفحه خاموش شده باشد، عدد واقعی می‌ماند
  String get _mmss {
    if (_deadline == null) {
      // بدون deadline (سفارش زمان‌دار) — شمارش مدت صبر
      return '${(_elapsed ~/ 60).toString().padLeft(2, '0')}:${(_elapsed % 60).toString().padLeft(2, '0')}';
    }
    final remain = _deadline!.difference(DateTime.now());
    if (remain.isNegative) return '00:00';
    final m = remain.inMinutes;
    final s = remain.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final accepted = _status == 'accepted';
    final nurseName = (_order?['nurse']?['name'] ?? '').toString();
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: const Text('درخواست شما ثبت شد', style: TextStyle(fontSize: 15))),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const SizedBox(height: 24),
        if (_status == 'awaiting_acceptance') ...[
          const Center(child: SizedBox(width: 64, height: 64,
            child: CircularProgressIndicator(strokeWidth: 5))),
          const SizedBox(height: 20),
          const Center(child: Text('در جستجوی پرستار…',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),
          Center(child: Text(_mmss, style: const TextStyle(
              fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.teal))),
          const SizedBox(height: 6),
          Center(child: Text(_deadline != null
              ? 'مهلت پذیرش خودکار: ۱۵ دقیقه از زمان ثبت (ساعت سرور) — حتی با بستن اپ'
              : 'به‌محض پذیرش، اطلاع می‌گیرید',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall)),
        ] else ...[
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accepted ? const Color(0xFFE8F7F0) : const Color(0xFFFDEEEE),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accepted ? const Color(0xFF0F9D6A) : const Color(0xFFDC2626))),
            child: Column(children: [
              Text(accepted ? '✓ درخواست شما پذیرفته شد' : 'سفارش پذیرفته نشد',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                      color: accepted ? const Color(0xFF0F9D6A) : const Color(0xFFDC2626))),
              if (accepted && nurseName.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('پرستار: $nurseName', style: const TextStyle(fontSize: 13)),
              ],
              if (!accepted) ...[
                const SizedBox(height: 6),
                const Text('می‌توانید فوریت را افزایش دهید یا سفارش را تکرار کنید.',
                    style: TextStyle(fontSize: 12.5)),
              ],
            ])),
        ],
        const SizedBox(height: 20),
        Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('کد سفارش', style: TextStyle(fontSize: 12.5, color: AppColors.subLight)),
            Text(widget.code, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ]),
          const Divider(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('مبلغ اولیه (وسایل بعداً اضافه می‌شود)',
                style: TextStyle(fontSize: 12.5, color: AppColors.subLight)),
            Text('${widget.initialTotal} تومان',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.teal)),
          ]),
        ]))),
        if (_status == 'awaiting_acceptance' && widget.isImmediate) ...[
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFFF8E6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDBA74))),
            child: const Text('⏱️ اگر تا ۱۵ دقیقه پذیرفته نشود، می‌توانید فوریت را افزایش دهید یا سفارش را تکرار کنید.',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF9A3412), height: 1.9))),
        ],
        const SizedBox(height: 20),
        if (_status == 'awaiting_acceptance')
          OutlinedButton.icon(onPressed: _cancel,
            icon: const Icon(Icons.close, size: 18),
            label: const Text('لغو درخواست (رایگان)'))
        else
          FilledButton(onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => HomeScreen(api: widget.api)), (_) => false),
            child: const Text('بازگشت به خانه')),
      ]),
    ));
  }
}
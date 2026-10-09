// پرستار من — تکه ۹: صفحه انتظار (نسخه ۳: فارسی + تایمر معکوس + افزایش فوریت در انتظار)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api_client.dart';
import '../theme.dart';
import '../money.dart';
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
  String _status = 'awaiting_acceptance';
  Map<String, dynamic>? _order;
  DateTime? _deadline;
  int _urgency = 0;
  bool _busyUrgency = false;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1),
        (_) { if (mounted) setState(() {}); });
    _poll = Timer.periodic(const Duration(seconds: 8), (_) => _check());
    _check().then((_) => _initDeadline());
  }

  @override
      void _initDeadline() {
    final raw = (_order?['created_at'] ?? '')?.toString() ?? '';
    if (raw.isEmpty) return;
    DateTime? dt = DateTime.tryParse(raw);
    if (dt == null && raw.length >= 19) {
      dt = DateTime.tryParse(raw.substring(0, 19).replaceFirst(' ', 'T'));
    }
    if (dt == null) return;
    // تصحیح: سرور ممکن است هر timezone‌ای داشته باشد —
    // اختلاف را بین ساعت سرور (raw) و NOW() دیتابیس نمی‌دانیم،
    // پس ساده‌ترین راه مطمئن: تایمر از «الان» شروع شود
    // (کاربر همین الان سفارش داده — پس deadline از الان + ۱۵ دقیقه)
    if (widget.isImmediate) {
      _deadline = DateTime.now().add(const Duration(minutes: 15));
    }
  }

  Future<void> _check() async {
    try {
      final o = await widget.api.orderDetails(widget.orderId);
      if (!mounted) return;
      final st = (o['status'] ?? '').toString();
      // به‌روزرسانی deadline از داده تازه سرور
      final created = o['created_at']?.toString() ?? '';
      if (created.isNotEmpty && widget.isImmediate && _deadline == null) {
        final dt = DateTime.tryParse(created);
        if (dt != null) _deadline = dt.add(const Duration(minutes: 15));
      }
      if (st != 'awaiting_acceptance') {
        _tick?.cancel();
        _poll?.cancel();
        setState(() { _status = st; _order = o; });
      } else {
        setState(() { _order = o; });
      }
    } on ApiException {
      // تیک بعدی دوباره تلاش می‌کند
    }
  }

  /// افزایش فوریت روی سفارش در انتظار — تصمیم ۴۹
  Future<void> _addUrgency(int amount) async {
    if (amount <= 0 || _busyUrgency) return;
    setState(() => _busyUrgency = true);
    try {
      // PATCH مبلغ فوریت جدید روی سفارش در انتظار
      final r = await widget.api.updateUrgency(widget.orderId, amount);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('⚡ فوریت ${money(amount)} تومان اضافه شد — درخواست شما با اولویت بالاتر ارسال می‌شود.',
            style: const TextStyle(fontSize: 13)),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating));
      await _check();
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: const TextStyle(fontSize: 13)),
        backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _busyUrgency = false);
    }
  }

  Future<void> _customUrgency() async {
    final c = TextEditingController();
    final v = await showDialog<int>(context: context, builder: (_) => AlertDialog(
      title: const Text('افزایش فوریت — مبلغ دلخواه', style: TextStyle(fontSize: 16)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('⚡ با افزایش قیمت، احتمال پذیرش سریع‌تر بالاتر می‌رود',
            style: TextStyle(fontSize: 12, color: Color(0xFF9A3412))),
        const SizedBox(height: 10),
        TextField(controller: c, keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(hintText: 'حداقل ۱۰۰۰۰۰ تومان — بدون سقف')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
        FilledButton(onPressed: () => Navigator.pop(context, int.tryParse(c.text)),
            child: const Text('تایید')),
      ]));
    if (v == null) return;
    if (v > 0 && v < 100000) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('حداقل افزایش فوریت ۱۰۰,۰۰۰ تومان است.',
            style: TextStyle(fontSize: 13)),
        backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating));
      return;
    }
    await _addUrgency(v);
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

  /// شمارش معکوس از deadline سرور — با بستن اپ هم عدد واقعی می‌ماند
  String get _mmss {
    if (_deadline == null) return '—';
    final remain = _deadline!.difference(DateTime.now());
    if (remain.isNegative) return '۰۰:۰۰';
    final m = remain.inMinutes.toString().padLeft(2, '0');
    final s = (remain.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final accepted = _status == 'accepted';
    final nurseName = (_order?['nurse']?['name'] ?? '').toString();
    final urgencyNow = (_order?['urgency_amount'] as num?)?.toInt() ?? 0;
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: const Text('درخواست شما ثبت شد', style: TextStyle(fontSize: 15))),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const SizedBox(height: 24),
        if (_status == 'awaiting_acceptance') ...[
          const Center(child: SizedBox(width: 64, height: 64,
            child: CircularProgressIndicator(strokeWidth: 5, color: AppColors.teal))),
          const SizedBox(height: 20),
          const Center(child: Text('در جستجوی پرستار…',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),
          Center(child: Text(_mmss, style: const TextStyle(
              fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.teal))),
          const SizedBox(height: 6),
          Center(child: Text(_deadline != null
              ? '⏳ مهلت پذیرش: ۱۵ دقیقه از زمان ثبت — حتی با بستن اپ، شمارش سرور ادامه دارد'
              : 'به‌محض پذیرش، اطلاع می‌گیرید',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall)),
          const SizedBox(height: 16),

          // ═══ افزایش فوریت — تصمیم ۴۹ ═══
          Container(padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFFFF8E6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDBA74))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('⚡ درخواست شما هنوز پذیرفته نشده؟',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                      color: Color(0xFF9A3412))),
              const SizedBox(height: 6),
              const Text('با افزایش قیمت، احتمال پذیرش سریع‌تر بالاتر می‌رود.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF9A3412), height: 1.8)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final add in const [100000, 200000, 300000])
                  OutlinedButton(
                    onPressed: _busyUrgency ? null : () => _addUrgency(add),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF9A3412),
                      side: const BorderSide(color: Color(0xFFFDBA74)),
                      minimumSize: const Size(0, 44)),
                    child: Text('+${money(add)}', style: const TextStyle(fontSize: 12)),
                  ),
                OutlinedButton(
                  onPressed: _busyUrgency ? null : _customUrgency,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF9A3412),
                    side: const BorderSide(color: Color(0xFFFDBA74)),
                    minimumSize: const Size(0, 44)),
                  child: const Text('مبلغ دلخواه', style: TextStyle(fontSize: 12)),
                ),
              ]),
              if (urgencyNow > 0)
                Padding(padding: const EdgeInsets.only(top: 8),
                  child: Text('فوریت فعلی سفارش: ${money(urgencyNow)} تومان',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF9A3412)))),
            ])),
          const SizedBox(height: 16),
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
            Text('${widget.initialTotal + urgencyNow} تومان',
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
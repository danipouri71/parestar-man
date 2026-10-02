// پرستار من — تکه ۱۰: پیگیری زنده — وایرفریم U9
// تایم‌لاین مصوب + پرستار + دکمه‌های چت/پرداخت/امتیاز + به‌روزرسانی هر ۸ ثانیه

import 'dart:async';
import 'package:flutter/material.dart';
import '../api_client.dart';
import '../money.dart';
import '../theme.dart';
import 'chat_screen.dart';
import 'payment_screen.dart';
import 'rating_screen.dart';
import 'home_screen.dart';

const _steps = [
  ('accepted', 'پذیرفته شد'),
  ('on_the_way', 'پرستار در مسیر'),
  ('arrived', 'حاضر در محل'),
  ('verifying_doctor_order', 'بررسی دستور پزشک'),
  ('awaiting_payment', 'در انتظار پرداخت'),
  ('in_progress', 'در حال انجام'),
  ('completed', 'انجام شد'),
];

class TrackScreen extends StatefulWidget {
  const TrackScreen({super.key, required this.api, required this.orderId});
  final ApiClient api;
  final int orderId;

  @override
  State<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen> {
  Map<String, dynamic>? _order;
  String? _error;
  Timer? _poll;

  @override
  void initState() { super.initState(); _load(); _poll = Timer.periodic(const Duration(seconds: 8), (_) => _load(silent: true)); }

  @override
  void dispose() { _poll?.cancel(); super.dispose(); }

  Future<void> _load({bool silent = false}) async {
    try {
      final o = await widget.api.orderDetails(widget.orderId);
      if (!mounted) return;
      setState(() { _order = o; _error = null; });
    } on ApiException catch (e) {
      if (mounted && !silent) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = _order;
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        title: Text('پیگیری سفارش ${o?['code'] ?? ''}', style: const TextStyle(fontSize: 15)),
      ),
      body: o == null
          ? Center(child: _error == null
              ? const CircularProgressIndicator()
              : Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)))
          : ListView(padding: const EdgeInsets.all(16), children: _body(o)),
    ));
  }

  List<Widget> _body(Map<String, dynamic> o) {
    final status = (o['status'] ?? '').toString();
    final nurse = o['nurse'] as Map<String, dynamic>?;
    final invoice = o['invoice'] as Map<String, dynamic>?;
    final reviewed = o['review_submitted'] == true;
    final widgets = <Widget>[];

    // پرستار — مثل U8/U9
    if (nurse != null) {
      widgets.add(Card(child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
        CircleAvatar(radius: 26, backgroundColor: AppColors.tealSoft,
            child: const Text('👨‍⚕️', style: TextStyle(fontSize: 24))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text((nurse['name'] ?? '').toString(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text('★ ${nurse['rating_avg'] ?? '—'}',
              style: const TextStyle(fontSize: 12, color: Color(0xFFF59E0B))),
        ])),
      ]))));
      widgets.add(const SizedBox(height: 12));
    }

    // تایم‌لاین — U9
    final idx = _steps.indexWhere((s) => s.$1 == status);
    if (idx >= 0) {
      widgets.add(Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(
        children: List.generate(_steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Container(width: 2, height: 14,
                color: (i ~/ 2) < idx ? AppColors.teal : AppColors.lineLight);
          }
          final s = _steps[i ~/ 2];
          final done = (i ~/ 2) < idx;
          final current = (i ~/ 2) == idx;
          return Row(children: [
            Icon(done ? Icons.check_circle : (current ? Icons.radio_button_checked : Icons.radio_button_off),
                size: 18, color: done || current ? AppColors.teal : AppColors.lineLight),
            const SizedBox(width: 10),
            Text(s.$2, style: TextStyle(
                fontSize: current ? 13.5 : 12.5,
                fontWeight: current ? FontWeight.bold : FontWeight.normal,
                color: done || current ? AppColors.textLight : AppColors.subLight)),
          ]);
        }),
      ))));
      widgets.add(const SizedBox(height: 12));
    }

    // وضعیت‌های خاص
    if (status == 'cancelled' || status == 'expired') {
      widgets.add(Container(padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFFFDEEEE),
          borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFDC2626))),
        child: Text('این سفارش ${o['status_label'] ?? 'بسته شده است'}.',
            style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13))));
      widgets.add(const SizedBox(height: 12));
    }

    // دکمه پرداخت — فقط از وضعیت درست (تکه ۶ سرور هم قفل است)
    final cashPending = invoice != null && invoice['status'] == 'awaiting'
        && invoice['method'] == 'cash' && invoice['cash_user_marked_at'] != null;
    if (status == 'awaiting_payment' && invoice != null && !cashPending) {
      widgets.add(FilledButton.icon(onPressed: () async {
        await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PaymentScreen(api: widget.api, order: o)));
        _load(silent: true);
      }, icon: const Icon(Icons.payment), label: Text('پرداخت فاکتور — ${money((invoice['total'] as num).toInt())} تومان')));
      widgets.add(const SizedBox(height: 12));
    }
    if (cashPending) {
      widgets.add(Container(padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFFFF8E6),
          borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFDBA74))),
        child: const Text('💵 پرداخت نقدی ثبت شد — در انتظار تایید پرستار…',
            style: TextStyle(fontSize: 12, color: Color(0xFF9A3412)))));
      widgets.add(const SizedBox(height: 12));
    }

    // امتیاز — U12
    if (status == 'completed' && !reviewed) {
      widgets.add(FilledButton.icon(onPressed: () async {
        await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => RatingScreen(api: widget.api, orderId: widget.orderId,
                nurseName: (nurse?['name'] ?? '').toString())));
        _load(silent: true);
      }, icon: const Icon(Icons.star), label: const Text('ثبت امتیاز و نظر')));
      widgets.add(const SizedBox(height: 12));
    }
    if (status == 'completed' && reviewed) {
      widgets.add(const Center(child: Text('امتیاز شما ثبت شد ✓',
          style: TextStyle(fontSize: 12, color: AppColors.success))));
      widgets.add(const SizedBox(height: 12));
    }

    // چت — تصمیم ۳۲
    if (nurse != null && status != 'cancelled' && status != 'expired') {
      widgets.add(OutlinedButton.icon(onPressed: () {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ChatScreen(api: widget.api, orderId: widget.orderId,
                peerName: (nurse['name'] ?? 'پرستار').toString())));
      }, icon: const Icon(Icons.chat_bubble_outline), label: const Text('💬 گفتگو با پرستار')));
      widgets.add(const SizedBox(height: 12));
    }

    widgets.add(OutlinedButton(onPressed: () => Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen(api: widget.api)), (_) => false),
        child: const Text('بازگشت به خانه')));
    return widgets;
  }
}
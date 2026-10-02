// پرستار من — تکه ۱۰: فاکتور نهایی و پرداخت — وایرفریم U11
// انعام: ۱۰۰٪ به پرستار، خارج از کمیسیون (تصمیم ۲۴) — نقدی دوگام (تصمیم ۸)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api_client.dart';
import '../money.dart';
import '../theme.dart';
import 'track_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.api, required this.order});
  final ApiClient api;
  final Map<String, dynamic> order;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _tip = 0;
  bool _online = true;
  bool _busy = false;

  Map<String, dynamic> get _inv => widget.order['invoice'] as Map<String, dynamic>;

  Future<void> _customTip() async {
    final c = TextEditingController();
    final v = await showDialog<int>(context: context, builder: (_) => AlertDialog(
      title: const Text('انعام دلخواه', style: TextStyle(fontSize: 16)),
      content: TextField(controller: c, keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(hintText: 'مبلغ به تومان')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
        FilledButton(onPressed: () => Navigator.pop(context, int.tryParse(c.text) ?? 0),
            child: const Text('تایید')),
      ]));
    if (v != null && v >= 0) setState(() => _tip = v);
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m, style: const TextStyle(fontSize: 13)),
      backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating));

  Future<void> _pay() async {
    setState(() => _busy = true);
    try {
      if (_online) {
        await widget.api.payOnline(widget.order['id'] as int, _tip);
        if (!mounted) return;
        await showDialog(context: context, builder: (_) => AlertDialog(
          title: const Text('✓ پرداخت موفق', style: TextStyle(fontSize: 16)),
          content: const Text('خدمت آغاز می‌شود.', style: TextStyle(fontSize: 13)),
          actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('باشه'))],
        ));
      } else {
        await widget.api.payCash(widget.order['id'] as int, _tip);
        if (!mounted) return;
        await showDialog(context: context, builder: (_) => AlertDialog(
          title: const Text('💵 ثبت شد', style: TextStyle(fontSize: 16)),
          content: const Text('پس از تایید دریافت توسط پرستار، خدمت آغاز می‌شود.',
              style: TextStyle(fontSize: 13)),
          actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('باشه'))],
        ));
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => TrackScreen(api: widget.api, orderId: widget.order['id'] as int)));
    } on ApiException catch (e) {
      _snack(e.toString());
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = _inv;
    final base = (inv['base_price'] as num).toInt();
    final travel = (inv['travel_fee'] as num).toInt();
    final urgency = (inv['urgency_amount'] as num).toInt();
    final cons = (inv['consumables_total'] as num).toInt();
    final total = base + travel + urgency + cons + _tip;

    Widget row(String l, String v, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(l, style: TextStyle(fontSize: 12.5, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        Text(v, style: TextStyle(fontSize: 12.5, fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: bold ? AppColors.teal : null)),
      ]));

    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        title: Text('فاکتور نهایی — ${widget.order['code']}', style: const TextStyle(fontSize: 15))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
          row('هزینه خدمت', '${money(base)} تومان'),
          row('رفت‌وآمد', '${money(travel)} تومان'),
          if (urgency > 0) row('افزایش فوریت', '${money(urgency)} تومان'),
          if (cons > 0) ...[
            const Divider(height: 16),
            row('وسایل مصرفی', '${money(cons)} تومان'),
          ],
          const Divider(height: 16),
          row('جمع فاکتور', '${money(base + travel + urgency + cons)} تومان', bold: true),
        ]))),

        const SizedBox(height: 14),
        Text('انعام (اختیاری — ۱۰۰٪ به پرستار می‌رسد)',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          for (final t in const [0, 30000, 50000, 100000])
            ChoiceChip(label: Text(t == 0 ? '۰' : '+${money(t)}',
                style: const TextStyle(fontSize: 12)),
              selected: _tip == t, onSelected: (_) => setState(() => _tip = t),
              selectedColor: AppColors.tealSoft),
          ChoiceChip(label: Text(_tip > 0 && _tip != 30000 && _tip != 50000 && _tip != 100000
              ? '${money(_tip)} ✓' : 'دلخواه', style: const TextStyle(fontSize: 12)),
            selected: _tip > 0 && _tip != 30000 && _tip != 50000 && _tip != 100000,
            onSelected: (_) => _customTip(), selectedColor: AppColors.tealSoft),
        ]),

        const SizedBox(height: 14),
        Text('روش پرداخت', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, icon: Icon(Icons.credit_card), label: Text('آنلاین')),
            ButtonSegment(value: false, icon: Icon(Icons.payments_outlined), label: Text('نقدی')),
          ],
          selected: {_online},
          onSelectionChanged: (s) => setState(() => _online = s.first),
        ),

        const SizedBox(height: 18),
        Card(color: AppColors.tealSoft, child: Padding(padding: const EdgeInsets.all(14),
          child: row('قابل پرداخت', '${money(total)} تومان', bold: true))),
        const SizedBox(height: 14),
        FilledButton(onPressed: _busy ? null : _pay,
          child: Text(_busy ? 'در حال انجام…' : 'پرداخت و شروع خدمت')),
        const SizedBox(height: 8),
        Text(_online
            ? 'پرداخت آنلاین با تایید خودکار درگاه نهایی می‌شود.'
            : 'نقدی: شما ثبت می‌کنید و پرستار دریافت را تایید می‌کند (تایید دوطرفه).',
          textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
      ]),
    ));
  }
}
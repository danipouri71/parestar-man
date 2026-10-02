// پرستار من — تکه ۱۰: تاریخچه و جزئیات — وایرفریم‌های U13 و U14
// فیلتر + نشان رنگی وضعیت + فاکتور گذشته + سفارش مجدد

import 'package:flutter/material.dart';
import '../api_client.dart';
import '../money.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'order_wizard.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.api, this.embedded = false});
  final ApiClient api;
  final bool embedded; // وقتی داخل تب خانه است، Scaffold خودش را ندارد

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List _all = [];
  int _filter = 0; // 0 همه / 1 جاری / 2 انجام‌شده
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final h = await widget.api.orderHistory();
      if (!mounted) return;
      setState(() { _all = h; _loading = false; });
    } on ApiException {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isActive(String s) => !['completed', 'cancelled', 'expired'].contains(s);

  List get _filtered => _all.where((o) {
    final s = (o['status'] ?? '').toString();
    if (_filter == 1) return _isActive(s);
    if (_filter == 2) return s == 'completed';
    return true;
  }).toList();

  Color _badgeColor(String s) => s == 'completed'
      ? const Color(0xFF0F9D6A) : (s == 'cancelled' || s == 'expired'
          ? const Color(0xFFDC2626) : const Color(0xFFB45309));
  Color _badgeBg(String s) => s == 'completed'
      ? const Color(0xFFE8F7F0) : (s == 'cancelled' || s == 'expired'
          ? const Color(0xFFFDEEEE) : const Color(0xFFFFF8E6));

  @override
  Widget build(BuildContext context) {
    final body = Column(children: [
      Padding(padding: const EdgeInsets.all(12), child: Row(children: [
        for (final (i, label) in const [(0, 'همه'), (1, 'جاری'), (2, 'انجام‌شده')])
          Padding(padding: const EdgeInsets.only(left: 8), child: ChoiceChip(
            label: Text(label, style: const TextStyle(fontSize: 12)),
            selected: _filter == i, onSelected: (_) => setState(() => _filter = i),
            selectedColor: AppColors.tealSoft)),
      ])),
      Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _filtered.isEmpty
              ? const Center(child: Text('سفارشی در این دسته نیست',
                  style: TextStyle(fontSize: 12.5, color: AppColors.subLight)))
              : RefreshIndicator(onRefresh: _load, child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final o = _filtered[i] as Map<String, dynamic>;
                    final s = (o['status'] ?? '').toString();
                    final svc = o['service'] as Map<String, dynamic>? ?? {};
                    return Card(child: ListTile(
                      title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('${svc['icon'] ?? '💉'} ${svc['name'] ?? ''}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: _badgeBg(s),
                            borderRadius: BorderRadius.circular(8)),
                          child: Text((o['status_label'] ?? s).toString(),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                                color: _badgeColor(s)))),
                      ]),
                      subtitle: Padding(padding: const EdgeInsets.only(top: 4),
                        child: Text('${o['created_at_label'] ?? ''}'
                            '${o['nurse_name'] != null ? ' — ${(o['nurse_name']).toString()}' : ''}',
                            style: const TextStyle(fontSize: 11))),
                      trailing: o['total'] != null
                          ? Text('${money((o['total'] as num).toInt())}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                                  color: AppColors.teal))
                          : null,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => _DetailScreen(api: widget.api, orderId: (o['id'] as num).toInt()))),
                    ));
                  }))),
    ]);

    if (widget.embedded) return body;
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white, title: const Text('تاریخچه سفارش‌ها', style: TextStyle(fontSize: 15))),
      body: body));
  }
}

/* ═══════════ U14 — جزئیات سفارش گذشته ═══════════ */

class _DetailScreen extends StatefulWidget {
  const _DetailScreen({required this.api, required this.orderId});
  final ApiClient api;
  final int orderId;

  @override
  State<_DetailScreen> createState() => _DetailState();
}

class _DetailState extends State<_DetailScreen> {
  Map<String, dynamic>? _o;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final o = await widget.api.orderDetails(widget.orderId);
      if (!mounted) return;
      setState(() => _o = o);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString(), style: const TextStyle(fontSize: 13)),
          backgroundColor: AppColors.danger));
    }
  }

  Widget _row(String l, String v, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: const TextStyle(fontSize: 12.5, color: AppColors.subLight)),
      Text(v, style: TextStyle(fontSize: 12.5, fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: bold ? AppColors.teal : null)),
    ]));

  @override
  Widget build(BuildContext context) {
    final o = _o;
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white, title: Text('جزئیات ${o?['code'] ?? ''}',
            style: const TextStyle(fontSize: 15))),
      body: o == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              _row('خدمت', ((o['service'] as Map<String, dynamic>?)?['name'] ?? '—').toString()),
              _row('پرستار', ((o['nurse'] as Map<String, dynamic>?)?['name'] ?? '—').toString()),
              _row('آدرس', (o['address_text'] ?? '—').toString()),
              const Divider(height: 18),
              if (o['invoice'] != null) ...[
                final inv = o['invoice'] as Map<String, dynamic>,
                _row('هزینه خدمت', '${money((inv['base_price'] as num).toInt())} تومان'),
                _row('رفت‌وآمد', '${money((inv['travel_fee'] as num).toInt())} تومان'),
                if ((inv['urgency_amount'] as num).toInt() > 0)
                  _row('فوریت', '${money((inv['urgency_amount'] as num).toInt())} تومان'),
                if ((inv['consumables_total'] as num).toInt() > 0)
                  _row('وسایل مصرفی', '${money((inv['consumables_total'] as num).toInt())} تومان'),
                if ((inv['tip'] as num).toInt() > 0)
                  _row('انعام', '${money((inv['tip'] as num).toInt())} تومان'),
                _row('جمع (${inv['method'] == 'cash' ? 'نقدی' : 'آنلاین'})',
                    '${money((inv['total'] as num).toInt())} تومان', bold: true),
              ],
              const SizedBox(height: 16),
              if (o['review_submitted'] == true)
                const Center(child: Text('امتیاز شما ثبت شد ✓',
                    style: TextStyle(fontSize: 12, color: AppColors.success))),
              FilledButton.icon(onPressed: () {
                final svc = (o['service'] as Map<String, dynamic>?) ?? {};
                Navigator.of(context).push(MaterialPageRoute(builder: (_) =>
                    ServiceDetailScreen(api: widget.api, service: {
                      'id': svc['id'], 'name': svc['name'],
                      'icon': svc['icon'] ?? '💉',
                      'needs_doctor_order': svc['needs_doctor_order'] ?? 'no',
                      'care_mode': svc['care_mode'] ?? 0,
                    })));
              }, icon: const Icon(Icons.repeat), label: const Text('🔁 سفارش مجدد همین خدمت')),
            ]),
    ));
  }
}
// پرستار من — تکه ۹: جریان ثبت سفارش ۵ گامی — U2 تا U6 (نسخه ۴: فوریت در گام آخر + تاریخ شمسی)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../api_client.dart';
import '../models/order_draft.dart';
import '../theme.dart';
import '../widgets/step_header.dart';
import '../money.dart';
import 'waiting_screen.dart';

/* ═══════════ قالب مشترک گام‌ها ═══════════ */

class _Shell extends StatelessWidget {
  const _Shell({required this.title, required this.step, required this.children});
  final String title;
  final int step;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          title: Text(title, style: const TextStyle(fontSize: 15)),
        ),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          StepHeader(step: step),
          const SizedBox(height: 16),
          ...children,
        ]),
      ),
    );
  }
}

Widget _infoBox(String text) => Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: const Color(0xFFE8F2FC),
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: const Color(0xFFBFDBFE)),
  ),
  child: Text(text, style: const TextStyle(fontSize: 11.5, color: Color(0xFF1E40AF), height: 1.9)),
);

Widget _priceBox(Map<String, dynamic>? q, {int urgency = 0}) {
  final base = q == null ? 0 : (q['base_price'] as num).toInt();
  final travel = q == null ? 0 : (q['travel_fee'] as num).toInt();
  final total = base + travel + urgency;
  Row row(String l, String v, {bool bold = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(child: Text(l, style: TextStyle(fontSize: 12.5,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal))),
      Text(v, style: TextStyle(fontSize: 12.5,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: bold ? (WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark ? AppColors.tealNight : AppColors.teal) : null)),
    ]);
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.lineLight)),
    child: Column(children: [
      row('قیمت مبنا', base == 0 ? '—' : '${money(base)} تومان'),
      const SizedBox(height: 6),
      row('رفت‌وآمد', travel == 0 ? '—' : '${money(travel)} تومان'),
      if (urgency > 0) ...[const SizedBox(height: 6), row('افزایش فوریت', '+ ${money(urgency)} تومان')],
      const Divider(height: 18),
      row('جمع', '${money(total)} تومان', bold: true),
    ]),
  );
}

void _snack(BuildContext c, String m) => ScaffoldMessenger.of(c).showSnackBar(
    SnackBar(content: Text(m, style: const TextStyle(fontSize: 13)),
        backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating));

/* ═══════════ گام ۱ — U2 جزئیات خدمت ═══════════ */

class ServiceDetailScreen extends StatefulWidget {
  const ServiceDetailScreen({super.key, required this.api, required this.service});
  final ApiClient api;
  final Map<String, dynamic> service;

  @override
  State<ServiceDetailScreen> createState() => _U2State();
}

class _U2State extends State<ServiceDetailScreen> {
  late final OrderDraft _d;
  bool _loading = true;
  String? _err;
  final _rxCode = TextEditingController();

  static const _careOptions = [
    ('day_shift', 'شیفت روز', '۱۲ ساعت — ۸ صبح تا ۸ شب'),
    ('hourly_day', 'ساعتی روز', 'به ازای هر ساعت'),
    ('night_shift', 'شیفت شب', '۱۲ ساعت — ۸ شب تا ۸ صبح'),
    ('hourly_night', 'ساعتی شب', 'به ازای هر ساعت'),
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.service;
    _d = OrderDraft(
      serviceId: (s['id'] as num).toInt(),
      serviceName: (s['name'] ?? '').toString(),
      serviceIcon: (s['icon'] ?? '💉').toString(),
      needsDoctorOrder: (s['needs_doctor_order'] ?? 'no').toString(),
      isCare: s['care_mode'] == 1 || s['care_mode'] == true,
    );
    if (_d.isCare) _d.careShift = 'day_shift';
    _loadQuote();
  }

  Future<void> _loadQuote() async {
    setState(() { _loading = true; _err = null; });
    try {
      final q = await widget.api.quote({
        'service_id': _d.serviceId,
        if (_d.isCare) 'care_shift': _d.careShift,
        if (_d.isCare && _d.careShift!.startsWith('hourly')) 'care_hours': _d.careHours,
      });
      _d.basePrice = (q['base_price'] as num).toInt();
      _d.travelFee = (q['travel_fee'] as num).toInt();
      if (mounted) setState(() => _err = null);
    } on ApiException catch (e) {
      if (mounted) setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickRx() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (x != null) setState(() => _d.prescriptionPath = x.path);
  }

  @override
  Widget build(BuildContext context) {
    final needsRx = _d.needsDoctorOrder != 'no';
    return _Shell(
      title: _d.serviceName, step: 1,
      children: [
        if (_d.isCare) ...[
          Text('نوع مراقبت', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._careOptions.map((o) => RadioListTile<String>(
            value: o.$1, groupValue: _d.careShift,
            onChanged: (v) { setState(() => _d.careShift = v); _loadQuote(); },
            title: Text(o.$2, style: const TextStyle(fontSize: 13.5)),
            subtitle: Text(o.$3, style: const TextStyle(fontSize: 11)),
            dense: true,
          )),
          if (_d.careShift!.startsWith('hourly')) ...[
            Row(children: [
              const Text('تعداد ساعت:', style: TextStyle(fontSize: 13)),
              const Spacer(),
              IconButton(onPressed: _d.careHours > 1
                  ? () { setState(() => _d.careHours--); _loadQuote(); } : null,
                  icon: const Icon(Icons.remove_circle_outline)),
              Text('${_d.careHours}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(onPressed: _d.careHours < 12
                  ? () { setState(() => _d.careHours++); _loadQuote(); } : null,
                  icon: const Icon(Icons.add_circle_outline)),
            ]),
          ],
          const SizedBox(height: 8),
        ] else ...[
          Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
            Text(_d.serviceIcon, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 6),
            Text(_d.serviceName, style: Theme.of(context).textTheme.titleMedium),
          ]))),
          const SizedBox(height: 12),
        ],

        if (needsRx) ...[
          _infoBox('ℹ️ این خدمت نیازمند دستور پزشک است. عکس نسخه یا کد رهگیری را اختیاری بارگذاری کنید؛ '
              'پرستار پس از حضور در محل، دستور پزشک را بررسی و تایید می‌کند.'),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _pickRx,
            icon: const Icon(Icons.attach_file),
            label: Text(_d.prescriptionPath == null
                ? '📎 بارگذاری عکس نسخه (اختیاری)' : 'نسخه انتخاب شد ✓ — تغییر'),
          ),
          const SizedBox(height: 8),
          TextField(controller: _rxCode,
            keyboardType: TextInputType.text,
            onChanged: (v) => _d.rxTrackingCode = v,
            decoration: const InputDecoration(hintText: 'کد رهگیری نسخه (اختیاری)')),
          const SizedBox(height: 12),
        ],

        if (_err != null) _infoBox('⚠️ $_err'),
        _loading
            ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            : _priceBox({'base_price': _d.basePrice, 'travel_fee': _d.travelFee}),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _loading ? null : () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AddressScreen(api: widget.api, draft: _d))),
          child: const Text('ادامه'),
        ),
      ],
    );
  }
}

/* ═══════════ گام ۲ — U3 آدرس و لوکیشن ═══════════ */

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key, required this.api, required this.draft});
  final ApiClient api;
  final OrderDraft draft;

  @override
  State<AddressScreen> createState() => _U3State();
}

class _U3State extends State<AddressScreen> {
  List _saved = [];
  int? _selectedId;
  bool _fromMap = false;
  final _addr = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final a = await widget.api.addresses();
      if (!mounted) return;
      setState(() => _saved = a);
      if (_saved.isNotEmpty) _pick(_saved.first as Map<String, dynamic>);
    } on ApiException catch (e) { if (mounted) _snack(context, e.toString()); }
  }

  void _pick(Map<String, dynamic> a) {
    _selectedId = (a['id'] as num).toInt();
    _fromMap = false;
    widget.draft
      ..addressText = (a['full_address'] ?? '').toString()
      ..lat = (a['lat'] as num?)?.toDouble()
      ..lng = (a['lng'] as num?)?.toDouble()
      ..cityId = (a['city_id'] as num?)?.toInt();
    _addr.text = widget.draft.addressText ?? '';
    setState(() {});
  }

  Future<void> _openMap() async {
    final r = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(builder: (_) => const _MapPlaceholder()));
    if (r == null) return;
    _selectedId = null;
    _fromMap = true;
    widget.draft
      ..lat = (r['lat'] as num).toDouble()
      ..lng = (r['lng'] as num).toDouble()
      ..cityId = null;
    setState(() {});
  }

  Future<void> _continue() async {
    final d = widget.draft;
    d.addressText = _addr.text.trim();
    if (d.addressText!.isEmpty || d.lat == null || d.lng == null) {
      _snack(context, 'آدرس و موقعیت روی نقشه الزامی است.');
      return;
    }
    if (_fromMap && d.saveAddress) {
      try {
        await widget.api.addAddress({
          'title': d.addressTitle ?? 'آدرس جدید',
          'full_address': d.addressText, 'lat': d.lat, 'lng': d.lng,
          if (d.cityId != null) 'city_id': d.cityId,
        });
      } on ApiException catch (e) { if (mounted) _snack(context, e.toString()); }
    }
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PatientScreen(api: widget.api, draft: d)));
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    return _Shell(
      title: 'آدرس دریافت خدمت', step: 2,
      children: [
        OutlinedButton.icon(onPressed: _openMap, icon: const Icon(Icons.map_outlined),
          label: const Text('🎯 انتخاب موقعیت روی نقشه')),
        if (d.lat != null)
          Padding(padding: const EdgeInsets.only(top: 6),
            child: Text('📍 موقعیت انتخاب شد: ${d.lat!.toStringAsFixed(4)} , ${d.lng!.toStringAsFixed(4)}',
              style: Theme.of(context).textTheme.bodySmall)),
        const SizedBox(height: 10),
        TextField(controller: _addr, maxLines: 2,
          decoration: const InputDecoration(hintText: 'نشانی کامل — نمونه: سردشت، خیابان آزادی، پلاک ۱۲')),
        const SizedBox(height: 8),
        CheckboxListTile(value: d.saveAddress, dense: true,
          onChanged: (v) => setState(() => d.saveAddress = v ?? false),
          title: const Text('ذخیره این آدرس برای دفعه‌های بعد', style: TextStyle(fontSize: 12.5))),

        if (_saved.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('آدرس‌های ذخیره‌شده', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          ..._saved.map((a) => Card(child: ListTile(dense: true,
            leading: Icon(_selectedId == (a['id'] as num).toInt()
                ? Icons.radio_button_checked : Icons.radio_button_off,
                color: AppColors.teal),
            title: Text((a['title'] ?? 'آدرس').toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: Text((a['full_address'] ?? '').toString(),
                style: const TextStyle(fontSize: 11), maxLines: 2),
            onTap: () => _pick(a as Map<String, dynamic>)))),
        ],
        const SizedBox(height: 16),
        FilledButton(onPressed: _continue, child: const Text('ادامه')),
      ],
    );
  }
}

/// جای اتصال پلاگین نشان (تصمیم ۳۷) — فعال‌سازی نهایی کار تیم است
class _MapPlaceholder extends StatefulWidget {
  const _MapPlaceholder();
  @override
  State<_MapPlaceholder> createState() => _MapPlaceholderState();
}

class _MapPlaceholderState extends State<_MapPlaceholder> {
  final _lat = TextEditingController(text: '36.1607');
  final _lng = TextEditingController(text: '45.2994');

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: const Text('انتخاب موقعیت', style: TextStyle(fontSize: 15))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _infoBox('🗺️ این صفحه جای اتصال نقشه نشان است و در نسخه نهایی توسط تیم توسعه با پلاگین نقشه جایگزین می‌شود. '
            'فعلاً مختصات را دستی وارد یا پیش‌فرض سردشت را تایید کنید.'),
        const SizedBox(height: 12),
        TextField(controller: _lat, keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'عرض جغرافیایی (lat)')),
        const SizedBox(height: 8),
        TextField(controller: _lng, keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'طول جغرافیایی (lng)')),
        const SizedBox(height: 16),
        FilledButton(onPressed: () => Navigator.of(context).pop(
            {'lat': double.tryParse(_lat.text), 'lng': double.tryParse(_lng.text)}),
            child: const Text('تایید موقعیت')),
      ]),
    ));
  }
}

/* ═══════════ گام ۳ — U4 اطلاعات بیمار ═══════════ */

class PatientScreen extends StatefulWidget {
  const PatientScreen({super.key, required this.api, required this.draft});
  final ApiClient api;
  final OrderDraft draft;

  @override
  State<PatientScreen> createState() => _U4State();
}

class _U4State extends State<PatientScreen> {
  List _saved = [];
  int? _selectedPatientId;
  final _name = TextEditingController();
  final _cond = TextEditingController();
  final _note = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final p = await widget.api.patients();
      if (!mounted) return;
      setState(() => _saved = p);
    } on ApiException {}
  }

  void _continue() {
    final d = widget.draft;
    if (_selectedPatientId == null && _name.text.trim().length < 2) {
      _snack(context, 'نام بیمار را وارد کنید.');
      return;
    }
    d
      ..patientId = _selectedPatientId
      ..patientName = _name.text.trim()
      ..conditionNote = _cond.text.trim()
      ..nurseNote = _note.text.trim();
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => TimeUrgencyScreen(api: widget.api, draft: d)));
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    return _Shell(
      title: 'اطلاعات بیمار', step: 3,
      children: [
        if (_saved.isNotEmpty) ...[
          Text('پروفایل‌های ذخیره‌شده', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Wrap(spacing: 8, children: _saved.map((p) {
            final id = (p['id'] as num).toInt();
            return ChoiceChip(label: Text((p['full_name'] ?? '').toString(),
                style: const TextStyle(fontSize: 12)),
              selected: _selectedPatientId == id,
              onSelected: (s) => setState(() { _selectedPatientId = s ? id : null; }),
              selectedColor: AppColors.tealSoft);
          }).toList()),
          const SizedBox(height: 12),
        ],
        TextField(controller: _name, textInputAction: TextInputAction.next,
          decoration: const InputDecoration(hintText: 'نام بیمار')),
        const SizedBox(height: 8),
        TextField(controller: _cond, maxLines: 2,
          decoration: const InputDecoration(hintText: 'توضیح وضعیت — نمونه: بیمار دیابتی، رگ دست چپ ضعیف')),
        const SizedBox(height: 8),
        TextField(controller: _note, maxLines: 2,
          decoration: const InputDecoration(hintText: 'یادداشت برای پرستار (اختیاری)')),
        const SizedBox(height: 12),
        _infoBox('🔒 این اطلاعات فقط برای پرستارِ همین سفارش نمایش داده می‌شود.'),
        const SizedBox(height: 16),
        FilledButton(onPressed: _continue, child: const Text('ادامه')),
      ],
    );
  }
}

/* ═══════════ گام ۴ — U5 زمان (بدون فوریت — فوریت به گام ۵ منتقل شد) ═══════════ */

class TimeUrgencyScreen extends StatefulWidget {
  const TimeUrgencyScreen({super.key, required this.api, required this.draft});
  final ApiClient api;
  final OrderDraft draft;

  @override
  State<TimeUrgencyScreen> createState() => _U5State();
}

class _U5State extends State<TimeUrgencyScreen> {
  DateTime? _scheduled;

  String _jalali(DateTime dt) {
    final j = Jalali.fromDateTime(dt);
    final two = (int v) => v.toString().padLeft(2, '0');
    return '${j.year}/${two(j.month)}/${two(j.day)} — ${two(dt.hour)}:${two(dt.minute)}';
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(context: context,
        initialDate: DateTime.now().add(const Duration(days: 1)),
        firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)));
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context,
        initialTime: const TimeOfDay(hour: 10, minute: 0));
    if (time == null || !mounted) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (dt.isBefore(DateTime.now().add(const Duration(hours: 1)))) {
      _snack(context, 'سفارش زمان‌دار باید حداقل یک ساعت آینده باشد.');
      return;
    }
    setState(() { widget.draft.immediate = false; _scheduled = dt; });
  }

  void _continue() {
    final d = widget.draft;
    if (!d.immediate && _scheduled == null) {
      _snack(context, 'زمان سفارش را مشخص کنید یا «همین حالا» را انتخاب کنید.');
      return;
    }
    d
      ..scheduledAt = d.immediate ? null : _scheduled
      ..urgency = 0;
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ReviewScreen(api: widget.api, draft: d)));
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    return _Shell(
      title: 'زمان دریافت خدمت', step: 4,
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, icon: Icon(Icons.bolt), label: Text('همین حالا')),
            ButtonSegment(value: false, icon: Icon(Icons.schedule), label: Text('زمان مشخص')),
          ],
          selected: {d.immediate},
          onSelectionChanged: (s) => setState(() {
            d.immediate = s.first;
            if (d.immediate) _scheduled = null; // پاکسازی زمان قبلی هنگام سوییچ
          }),
        ),
        if (!d.immediate) ...[
          const SizedBox(height: 10),
          Card(child: ListTile(dense: true,
            leading: const Icon(Icons.calendar_month, color: AppColors.teal),
            title: Text(_scheduled == null ? 'انتخاب تاریخ و ساعت' : _jalali(_scheduled!),
                style: const TextStyle(fontSize: 13)),
            trailing: const Icon(Icons.edit_outlined, size: 18),
            onTap: _pickDateTime)),
        ],
        const SizedBox(height: 14),
        _priceBox({'base_price': d.basePrice, 'travel_fee': d.travelFee}),
        const SizedBox(height: 16),
        FilledButton(onPressed: _continue, child: const Text('ادامه')),
      ],
    );
  }
}

/* ═══════════ گام ۵ — U6 تایید نهایی + فوریت (انتقال به گام آخر — درخواست مالک) ═══════════ */

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key, required this.api, required this.draft});
  final ApiClient api;
  final OrderDraft draft;

  @override
  State<ReviewScreen> createState() => _U6State();
}

class _U6State extends State<ReviewScreen> {
  bool _busy = false;
  String? _schedLabel;
  int _urgency = 0;

  @override
  void initState() {
    super.initState();
    final s = widget.draft.scheduledAt;
    if (s != null) _schedLabel = _jalali(s);
  }

  String _jalali(DateTime dt) {
    final j = Jalali.fromDateTime(dt);
    final two = (int v) => v.toString().padLeft(2, '0');
    return '${j.year}/${two(j.month)}/${two(j.day)} — ${two(dt.hour)}:${two(dt.minute)}';
  }

  Row _row(String l, String v, {bool bold = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(l, style: const TextStyle(fontSize: 12.5, color: AppColors.subLight)),
      const SizedBox(width: 16),
      Expanded(child: Text(v, textAlign: TextAlign.left,
          style: TextStyle(fontSize: 12.5, fontWeight: bold ? FontWeight.bold : FontWeight.normal))),
    ]);

  Future<void> _customUrgency() async {
    final c = TextEditingController();
    final v = await showDialog<int>(context: context, builder: (_) => AlertDialog(
      title: const Text('مبلغ دلخواه فوریت', style: TextStyle(fontSize: 16)),
      content: TextField(controller: c, keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(hintText: 'حداقل ۱۰۰۰۰۰ تومان — بدون سقف')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
        FilledButton(onPressed: () => Navigator.pop(context, int.tryParse(c.text)),
            child: const Text('تایید')),
      ]));
    if (v == null) return;
    if (v > 0 && v < 100000) {
      _snack(context, 'حداقل افزایش فوریت ۱۰۰,۰۰۰ تومان است.');
      return;
    }
    setState(() => _urgency = v);
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      widget.draft.urgency = _urgency;
      final r = await widget.api.createOrder(widget.draft.toApi(),
          prescriptionPath: widget.draft.prescriptionPath);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => WaitingScreen(
        api: widget.api,
        orderId: (r['order_id'] as num).toInt(),
        code: (r['code'] ?? '').toString(),
        initialTotal: ((r['base_price'] as num?)?.toInt() ?? 0) +
            ((r['travel_fee'] as num?)?.toInt() ?? 0) +
            ((r['urgency'] as num?)?.toInt() ?? 0),
        isImmediate: widget.draft.immediate,
      )));
    } on ApiException catch (e) {
      _snack(context, e.toString());
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    return _Shell(
      title: 'تایید نهایی', step: 5,
      children: [
        Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
          _row('خدمت', '${d.serviceIcon} ${d.serviceName}'),
          const Divider(height: 16),
          _row('بیمار', d.patientId != null ? 'پروفایل ذخیره‌شده ✓' : d.patientName),
          const Divider(height: 16),
          _row('آدرس', d.addressText ?? '—'),
          const Divider(height: 16),
          _row('زمان', d.immediate ? '⚡ همین حالا' : (_schedLabel ?? '—')),
          const Divider(height: 16),
          _row('نسخه', d.prescriptionPath != null
              ? 'آپلود شد ✓' : (d.rxTrackingCode?.isNotEmpty == true ? 'کد رهگیری ثبت شد ✓' : '—')),
        ]))),
        const SizedBox(height: 12),

        // فوریت — انتقال یافته به گام آخر (درخواست مالک)
        Container(padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFFFF8E6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFDBA74))),
          child: const Text('⚡ با افزایش قیمت، احتمال پذیرش سریع‌تر بالاتر می‌رود',
            style: TextStyle(fontSize: 12, color: Color(0xFF9A3412), height: 1.8))),
        const SizedBox(height: 10),
        Wrap(spacing: 8, children: [
          ChoiceChip(label: const Text('بدون افزایش', style: TextStyle(fontSize: 12)),
            selected: _urgency == 0, onSelected: (_) => setState(() => _urgency = 0),
            selectedColor: AppColors.tealSoft),
          ChoiceChip(label: const Text('+۱۰۰ هزار', style: TextStyle(fontSize: 12)),
            selected: _urgency == 100000, onSelected: (_) => setState(() => _urgency = 100000),
            selectedColor: AppColors.tealSoft),
          ChoiceChip(label: const Text('+۲۰۰ هزار', style: TextStyle(fontSize: 12)),
            selected: _urgency == 200000, onSelected: (_) => setState(() => _urgency = 200000),
            selectedColor: AppColors.tealSoft),
          ChoiceChip(label: Text(_urgency > 0 && _urgency != 100000 && _urgency != 200000
              ? '${money(_urgency)} ✓' : 'مبلغ دلخواه', style: const TextStyle(fontSize: 12)),
            selected: _urgency > 0 && _urgency != 100000 && _urgency != 200000,
            onSelected: (_) => _customUrgency(), selectedColor: AppColors.tealSoft),
        ]),
        const SizedBox(height: 14),
        _priceBox({'base_price': d.basePrice, 'travel_fee': d.travelFee}, urgency: _urgency),
        const SizedBox(height: 8),
        Text('مبلغ نهایی پس از ثبت وسایل مصرفی توسط پرستار و پیش از پرداخت نمایش داده می‌شود.',
            textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        FilledButton(onPressed: _busy ? null : _submit,
          child: Text(_busy ? 'در حال ثبت…' : 'ثبت درخواست')),
        const SizedBox(height: 8),
        Text('درخواست به پرستارهای آنلاین نزدیک ارسال می‌شود',
            textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
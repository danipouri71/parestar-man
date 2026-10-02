// پرستار من — تکه ۱۰: امتیاز و نظر — وایرفریم U12 (نسخه هم‌خوان)

import 'package:flutter/material.dart';
import '../api_client.dart';
import '../theme.dart';
import 'home_screen.dart';

class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key, required this.api, required this.orderId, required this.nurseName});
  final ApiClient api;
  final int orderId;
  final String nurseName;

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _stars = 0;
  final _tags = <String>{};
  final _comment = TextEditingController();
  bool _busy = false;

  static const _tagOptions = ['خوش‌برخورد', 'سریع', 'ماهر', 'منظم', 'دارای تجهیزات کامل'];

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m, style: const TextStyle(fontSize: 13)),
      backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating));

  Future<void> _submit() async {
    if (_stars == 0) { _snack('لطفاً امتیاز ستاره‌ای را انتخاب کنید.'); return; }
    setState(() => _busy = true);
    try {
      await widget.api.submitReview(widget.orderId, _stars, _tags.toList(), _comment.text.trim());
      if (!mounted) return;
      await showDialog(context: context, builder: (_) => AlertDialog(
        title: const Text('✓ ممنون از شما', style: TextStyle(fontSize: 16)),
        content: const Text('امتیاز شما در پروفایل پرستار نمایش داده می‌شود.',
            style: TextStyle(fontSize: 13)),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('باشه'))],
      ));
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => HomeScreen(api: widget.api)), (_) => false);
    } on ApiException catch (e) {
      _snack(e.toString());
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white, title: const Text('امتیاز به خدمت', style: TextStyle(fontSize: 15))),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Center(child: Text('✓', style: TextStyle(fontSize: 44, color: AppColors.success))),
        const Center(child: Text('خدمت با موفقیت انجام شد',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
        const SizedBox(height: 6),
        Center(child: Text(widget.nurseName, style: Theme.of(context).textTheme.bodySmall)),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) =>
          IconButton(onPressed: () => setState(() => _stars = i + 1),
            icon: Icon(i < _stars ? Icons.star : Icons.star_border,
                size: 38, color: const Color(0xFFF59E0B))))),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
          children: _tagOptions.map((t) => FilterChip(
            label: Text(t, style: const TextStyle(fontSize: 12)),
            selected: _tags.contains(t),
            onSelected: (s) => setState(() => s ? _tags.add(t) : _tags.remove(t)),
            selectedColor: AppColors.tealSoft)).toList()),
        const SizedBox(height: 16),
        TextField(controller: _comment, maxLines: 3,
          decoration: const InputDecoration(hintText: 'نظر شما (اختیاری) — تجربه‌تان را بنویسید…')),
        const SizedBox(height: 16),
        FilledButton(onPressed: _busy ? null : _submit,
          child: Text(_busy ? 'در حال ثبت…' : 'ثبت امتیاز')),
        const SizedBox(height: 8),
        Center(child: Text('امتیاز شما در پروفایل عمومی پرستار نمایش داده می‌شود',
            style: Theme.of(context).textTheme.bodySmall)),
      ]),
    ));
  }
}
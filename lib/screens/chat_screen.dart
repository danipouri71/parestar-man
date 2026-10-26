// پرستار من — تکه ۱۰: چت درون‌اپ — وایرفریم U10
// شماره واسط (تصمیم ۳۲) — به‌روزرسانی هر ۴ ثانیه
// نسخه ۲ — اصلاح حالت شب: رنگ حباب‌ها، حاشیه و متن پیام‌ها همیشه با تم فعال هماهنگ است
//   (قبلاً حباب سفیدِ ثابت بود و متن در حالت شب روشن می‌شد → متن روشن روی سفید = ناخوانا)

import 'dart:async';
import 'package:flutter/material.dart';
import '../api_client.dart';
import '../theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.api, required this.orderId, required this.peerName});
  final ApiClient api;
  final int orderId;
  final String peerName;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<dynamic> _messages = [];
  int _afterId = 0;
  bool _sending = false;
  Timer? _poll;

  @override
  void initState() { super.initState(); _poll = Timer.periodic(const Duration(seconds: 4), (_) => _load()); }

  @override
  void dispose() { _poll?.cancel(); _input.dispose(); _scroll.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final msgs = await widget.api.chatMessages(widget.orderId, afterId: _afterId);
      if (!mounted || msgs.isEmpty) return;
      setState(() {
        _messages.addAll(msgs);
        _afterId = (msgs.last['id'] as num).toInt();
      });
      if (_scroll.hasClients) {
        await Future.delayed(const Duration(milliseconds: 50));
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    } on ApiException {
      /* تیک بعدی */
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.api.sendChat(widget.orderId, text);
      _input.clear();
      await _load();
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: const TextStyle(fontSize: 13)),
        backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // تشخیص تم فعال از روی پس‌زمینه اسکفولد — با همه نسخه‌های theme.dart سازگار است
    final dark = Theme.of(context).scaffoldBackgroundColor == AppColors.bgDark;
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        title: Text(widget.peerName, style: const TextStyle(fontSize: 15))),
      body: Column(children: [
        Container(width: double.infinity, padding: const EdgeInsets.all(8),
          color: dark ? AppColors.softDark : AppColors.tealSoft,
          child: Text('🔒 این گفتگو با شماره واسط است — شماره واقعی طرفین نمایش داده نمی‌شود',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5,
              color: dark ? AppColors.tealNight : AppColors.tealDark))),
        Expanded(child: _messages.isEmpty
            ? Center(child: Text('اولین پیام را بفرستید…',
                style: TextStyle(fontSize: 12,
                  color: dark ? AppColors.subDark : AppColors.subLight)))
            : ListView.builder(controller: _scroll, padding: const EdgeInsets.all(12),
                itemCount: _messages.length, itemBuilder: (_, i) {
                final m = _messages[i] as Map<String, dynamic>;
                final mine = m['sender_type'] == 'user';
                return Align(alignment: mine ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    constraints: const BoxConstraints(maxWidth: 260),
                    decoration: BoxDecoration(
                      color: mine
                          ? (dark ? const Color(0xFF11403A) : const Color(0xFFE5F6F4))
                          : (dark ? AppColors.cardDark : Colors.white),
                      border: Border.all(
                          color: dark ? AppColors.lineDark : AppColors.lineLight),
                      borderRadius: BorderRadius.circular(12)),
                    child: Text((m['body'] ?? '').toString(),
                        style: TextStyle(fontSize: 12.5, height: 1.7,
                          color: dark ? AppColors.textDark : AppColors.textLight))));
              })),
        SafeArea(child: Padding(padding: const EdgeInsets.all(10), child: Row(children: [
          Expanded(child: TextField(controller: _input,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
            decoration: const InputDecoration(hintText: 'نوشتن پیام…'))),
          const SizedBox(width: 8),
          InkWell(onTap: _send,
            child: CircleAvatar(radius: 22, backgroundColor: AppColors.teal,
              child: _sending
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send, size: 18, color: Colors.white))),
        ]))),
      ]),
    ));
  }
}

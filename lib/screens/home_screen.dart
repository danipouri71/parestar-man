// پرستار من — تکه ۱۰: خانه (نسخه ۴ — سوییچ حالت شب از طریق app_root.dart)

import 'package:flutter/material.dart';
import '../api_client.dart';
import '../app_root.dart';
import '../theme.dart';
import 'history_screen.dart';
import 'login_screen.dart';
import 'order_wizard.dart';
import 'track_screen.dart';

/// نگهدارنده ApiClient — هنگام ورود ساخته و به تب‌ها پاس داده می‌شود
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      body: IndexedStack(index: _tab, children: [
        _HomeTab(api: widget.api),
        HistoryScreen(api: widget.api, embedded: true),
        _NotificationsTab(api: widget.api),
        _ProfileTab(api: widget.api),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'خانه'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'تاریخچه'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'اعلان'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'پروفایل'),
        ],
      ),
    ));
  }
}

/* ═══════════ تب خانه — U1 ═══════════ */

class _HomeTab extends StatefulWidget {
  const _HomeTab({required this.api});
  final ApiClient api;

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  List _services = [];
  Map<String, dynamic>? _active;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = await widget.api.services();
      Map<String, dynamic>? active;
      try {
        final r = await widget.api.activeOrder();
        if (r['has_active'] == true && r['order'] != null) {
          active = r['order'] as Map<String, dynamic>;
        }
      } on ApiException {}
      if (!mounted) return;
      setState(() { _services = s; _active = active; });
    } on ApiException {}
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        title: const Text('پرستار من', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_outlined))]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
              Text('سلام 👋', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text('چه خدمتی نیاز دارید؟', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.95),
                itemCount: _services.length,
                itemBuilder: (_, i) {
                  final s = _services[i] as Map<String, dynamic>;
                  return Card(child: InkWell(borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ServiceDetailScreen(api: widget.api, service: s)));
                      _load();
                    },
                    child: Padding(padding: const EdgeInsets.all(8),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text((s['icon'] ?? '💉').toString(), style: const TextStyle(fontSize: 26)),
                        const SizedBox(height: 6),
                        Text((s['name'] ?? '').toString(), textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11)),
                      ]))));
                }),
              if (_active != null) ...[
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.tealSoft,
                    borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.teal)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('درخواست فعال: ${_active!['status_label'] ?? 'در جریان'}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                            color: AppColors.tealDark)),
                    const SizedBox(height: 10),
                    FilledButton(onPressed: () async {
                      await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => TrackScreen(api: widget.api,
                              orderId: (_active!['id'] as num).toInt())));
                      _load();
                    }, child: const Text('مشاهده سفارش')),
                  ])),
              ],
            ])),
    );
  }
}

/* ═══════════ تب اعلان‌ها ═══════════ */

class _NotificationsTab extends StatefulWidget {
  const _NotificationsTab({required this.api});
  final ApiClient api;
  @override
  State<_NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<_NotificationsTab> {
  List _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final n = await widget.api.notifications();
      if (!mounted) return;
      setState(() { _items = n; _loading = false; });
    } on ApiException { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white, title: const Text('اعلان‌ها', style: TextStyle(fontSize: 15))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('اعلانی ندارید',
                  style: TextStyle(fontSize: 12.5, color: AppColors.subLight)))
              : RefreshIndicator(onRefresh: _load, child: ListView.builder(
                  padding: const EdgeInsets.all(12), itemCount: _items.length,
                  itemBuilder: (_, i) {
                    final n = _items[i] as Map<String, dynamic>;
                    final unread = n['read_at'] == null;
                    return Card(margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),
                        side: unread ? const BorderSide(color: AppColors.teal, width: 1.5)
                                     : BorderSide.none),
                      child: Padding(padding: const EdgeInsets.all(12), child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text((n['title'] ?? '').toString(),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text((n['body'] ?? '').toString(),
                            style: const TextStyle(fontSize: 11.5, height: 1.8,
                                color: AppColors.subLight)),
                      ])));
                  })),
    );
  }
}

/* ═══════════ تب پروفایل — سوییچ سه‌حالته واقعی (تصمیم ۳۰) ═══════════ */

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.api});
  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    final app = ParestarManApp.of(context);
    final currentMode = app.mode;

    Widget item(IconData ic, String title, {VoidCallback? onTap}) => Card(
      child: ListTile(leading: Icon(ic, color: AppColors.teal),
        title: Text(title, style: const TextStyle(fontSize: 13)),
        trailing: const Icon(Icons.chevron_left, size: 18, color: AppColors.subLight),
        onTap: onTap));

    return Scaffold(appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white, title: const Text('پروفایل من', style: TextStyle(fontSize: 15))),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        item(Icons.location_on_outlined, 'آدرس‌های من'),
        item(Icons.credit_card_outlined, 'روش‌های پرداخت'),
        item(Icons.family_restroom, 'اطلاعات بیماران خانواده'),

        // ظاهر برنامه — سه انتخاب واقعی
        Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.dark_mode_outlined, color: AppColors.teal, size: 20),
            const SizedBox(width: 8),
            Text('ظاهر برنامه', style: const TextStyle(fontSize: 13)),
          ]),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'system', icon: Icon(Icons.settings_suggest_outlined), label: Text('خودکار')),
              ButtonSegment(value: 'light', icon: Icon(Icons.light_mode_outlined), label: Text('روشن')),
              ButtonSegment(value: 'dark', icon: Icon(Icons.dark_mode), label: Text('شب')),
            ],
            selected: {
              currentMode == ThemeMode.light ? 'light'
              : currentMode == ThemeMode.dark ? 'dark' : 'system',
            },
            onSelectionChanged: (s) => app.setMode(s.first),
          ),
        ]))),

        item(Icons.support_agent, 'پشتیبانی و شکایات'),
        item(Icons.description_outlined, 'قوانین و مقررات'),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: () {
          api.token = null;
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => LoginScreen(api: api)), (_) => false);
        }, icon: const Icon(Icons.logout), label: const Text('خروج از حساب')),
      ]),
    );
  }
}
// Parestar Man - waiting screen (final complete version)

import 'dart:async';
import 'package:flutter/material.dart';
import '../api_client.dart';
import '../theme.dart';
import 'home_screen.dart';

class WaitingScreen extends StatefulWidget {
  const WaitingScreen({
    super.key,
    required this.api,
    required this.orderId,
    required this.code,
    required this.initialTotal,
    required this.isImmediate,
  });

  final ApiClient api;
  final int orderId;
  final String code;
  final int initialTotal;
  final bool isImmediate;

  @override
  State<WaitingScreen> createState() => _WaitingState();
}

class _WaitingState extends State<WaitingScreen> {
  Timer? _tick;
  Timer? _poll;
  int _elapsed = 0;
  String _status = 'awaiting_acceptance';
  Map<String, dynamic>? _order;
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed++);
    });
    _poll = Timer.periodic(const Duration(seconds: 8), (_) => _check());
    _check().then((_) => _initDeadline());
  }

  @override
  void dispose() {
    _tick?.cancel();
    _poll?.cancel();
    super.dispose();
  }

  void _initDeadline() {
    final created = _order?['created_at']?.toString() ?? '';
    final dt = DateTime.tryParse(created);
    if (dt != null && widget.isImmediate) {
      _deadline = dt.add(const Duration(minutes: 15));
    }
  }

  Future<void> _check() async {
    try {
      final o = await widget.api.orderDetails(widget.orderId);
      if (!mounted) return;
      final st = (o['status'] ?? '').toString();
      if (st != 'awaiting_acceptance') {
        _tick?.cancel();
        _poll?.cancel();
        setState(() {
          _status = st;
          _order = o;
        });
      } else if (_order == null) {
        setState(() {
          _order = o;
        });
      }
    } on ApiException {
      // retry on next tick
    }
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await widget.api.cancelOrder(widget.orderId);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomeScreen(api: widget.api)),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString(), style: const TextStyle(fontSize: 13)),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  String _mmss() {
    if (_deadline == null) {
      final m = (_elapsed ~/ 60).toString().padLeft(2, '0');
      final s = (_elapsed % 60).toString().padLeft(2, '0');
      return '$m:$s';
    }
    final remain = _deadline!.difference(DateTime.now());
    if (remain.isNegative) return '00:00';
    final m = remain.inMinutes.toString().padLeft(2, '0');
    final s = (remain.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final accepted = _status == 'accepted';
    final nurseName = (_order?['nurse']?['name'] ?? '').toString();

    Widget banner = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accepted ? const Color(0xFFE8F7F0) : const Color(0xFFFDEEEE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accepted ? const Color(0xFF0F9D6A) : const Color(0xFFDC2626),
        ),
      ),
      child: Column(
        children: [
          Text(
            accepted ? 'DONE' : 'CLOSED',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: accepted ? const Color(0xFF0F9D6A) : const Color(0xFFDC2626),
            ),
          ),
          if (accepted && nurseName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('nurse: $nurseName', style: const TextStyle(fontSize: 13)),
            ),
        ],
      ),
    );

    Widget summary = Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('order', style: TextStyle(fontSize: 12.5)),
                Text(widget.code, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('total', style: TextStyle(fontSize: 12.5)),
                Text(
                  widget.initialTotal.toString(),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.teal),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Parestar Man', style: TextStyle(fontSize: 15)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 24),
            if (_status == 'awaiting_acceptance') ...[
              const Center(
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(strokeWidth: 5),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text('...',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _mmss(),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.teal),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  _deadline != null
                      ? '15 min server deadline - safe to close app'
                      : 'waiting for nurse',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ] else ...[
              banner,
            ],
            const SizedBox(height: 20),
            summary,
            const SizedBox(height: 20),
            if (_status == 'awaiting_acceptance')
              OutlinedButton.icon(
                onPressed: _cancel,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('cancel'),
              )
            else
              FilledButton(
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => HomeScreen(api: widget.api)),
                  (_) => false,
                ),
                child: const Text('home'),
              ),
          ],
        ),
      ),
    );
  }
}

// پرستار من — قالب‌بندی مبلغ و تاریخ شمسی (تصمیم ۴۳)

import 'package:shamsi_date/shamsi_date.dart';

String money(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    b.write(s[i]);
    final left = s.length - 1 - i;
    if (left > 0 && left % 3 == 0) b.write(',');
  }
  return b.toString();
}

/// تبدیل تاریخ میلادی خام سرور به نمایش شمسی — تصمیم ۴۳
String jalaliLabel(String? isoDateTime) {
  if (isoDateTime == null || isoDateTime.isEmpty) return '—';
  final dt = DateTime.tryParse(isoDateTime);
  if (dt == null) return isoDateTime;
  final two = (int v) => v.toString().padLeft(2, '0');
  try {
    final j = Jalali.fromDateTime(dt);
    return '${j.year}/${two(j.month)}/${two(j.day)} — ${two(dt.hour)}:${two(dt.minute)}';
  } catch (_) {
    return '${dt.year}/${two(dt.month)}/${two(dt.day)}';
  }
}
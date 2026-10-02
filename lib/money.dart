// پرستار من — تکه ۱۰: قالب‌بندی مبلغ (مبالغ همیشه خوانا — سند هویت بصری)
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
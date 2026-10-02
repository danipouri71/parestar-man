// پرستار من — تکه ۹: پیش‌نویس سفارش که بین ۵ گام جابجا می‌شود

class OrderDraft {
  OrderDraft({
    required this.serviceId,
    required this.serviceName,
    required this.serviceIcon,
    required this.needsDoctorOrder, // yes / depends / no
    required this.isCare,
  });

  final int serviceId;
  final String serviceName;
  final String serviceIcon;
  final String needsDoctorOrder;
  final bool isCare;

  // مراقبت
  String? careShift; // day_shift / hourly_day / night_shift / hourly_night
  int careHours = 1;

  // آدرس — تصمیم ۴۰: شناسه شهر، در انتخاب از نقشه با معکوس‌جو تعیین می‌شود
  int? cityId;
  String? addressText;
  double? lat;
  double? lng;
  bool saveAddress = false;
  String? addressTitle;

  // بیمار — U4
  int? patientId;
  String patientName = '';
  String conditionNote = '';
  String nurseNote = '';

  // زمان و فوریت — U5
  bool immediate = true;
  DateTime? scheduledAt;
  int urgency = 0;

  // نسخه — اختیاری (تصمیم ۲)
  String? prescriptionPath; // مسیر فایل محلی برای آپلود
  String? rxTrackingCode;

  // قیمت نمایشی از سرور (قاعده ۱ — مهر نهایی هنگام ثبت)
  int basePrice = 0;
  int travelFee = 0;

  Map<String, dynamic> toApi() => {
    'service_id': serviceId,
    if (cityId != null) 'city_id': cityId,
    'address_text': addressText,
    'lat': lat,
    'lng': lng,
    'is_immediate': immediate ? 1 : 0,
    if (!immediate && scheduledAt != null) 'scheduled_at': scheduledAt!.toIso8601String(),
    'urgency_amount': urgency,
    if (isCare) 'care_shift': careShift,
    if (isCare && (careShift ?? '').startsWith('hourly')) 'care_hours': careHours,
    if (patientId != null) 'patient_id': patientId,
    if (patientId == null) 'patient_name': patientName,
    if (patientId == null) 'condition_note': conditionNote,
    if (patientId == null) 'nurse_note': nurseNote,
    if (rxTrackingCode != null && rxTrackingCode!.isNotEmpty) 'rx_tracking_code': rxTrackingCode,
  };
}
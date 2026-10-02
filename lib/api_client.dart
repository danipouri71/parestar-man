// پرستار من — کلاینت API (نسخه ۴ — تمیز)

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required this.baseUrl});
  final String baseUrl;
  String? token;

  Map<String, String> get _jsonHeaders => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
  Map<String, String> get _authHeaders => {
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Map<String, dynamic> _handle(http.Response res) {
    final data = res.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw ApiException((data['message'] ?? 'خطای غیرمنتظره. دوباره تلاش کنید.').toString());
    }
    return data;
  }

  Future<Map<String, dynamic>> _send(String method, String path,
      {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    http.Response res;
    try {
      res = method == 'GET'
          ? await http.get(uri, headers: _jsonHeaders).timeout(const Duration(seconds: 20))
          : await http.post(uri, headers: _jsonHeaders,
              body: jsonEncode(body ?? {})).timeout(const Duration(seconds: 20));
    } catch (_) {
      throw ApiException('ارتباط با سرور برقرار نشد. اینترنت خود را بررسی کنید.');
    }
    return _handle(res);
  }

  Future<Map<String, dynamic>> _upload(String path, Map<String, String> fields,
      String fileField, String filePath) async {
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'))
      ..headers.addAll(_authHeaders)
      ..fields.addAll(fields)
      ..files.add(await http.MultipartFile.fromPath(fileField, filePath));
    http.Response res;
    try {
      final streamed = await req.send().timeout(const Duration(seconds: 60));
      res = await http.Response.fromStream(streamed);
    } catch (_) {
      throw ApiException('ارسال فایل ناموفق بود. اتصال اینترنت را بررسی کنید.');
    }
    return _handle(res);
  }

  /* ورود */
  Future<void> requestOtp(String mobile) async {
    await _send('POST', '/auth/request-otp', body: {'mobile': mobile, 'purpose': 'user'});
  }

  Future<Map<String, dynamic>> verifyOtp(String mobile, String code,
      String fullName) async {
    final r = await _send('POST', '/auth/verify', body: {
      'mobile': mobile, 'purpose': 'user', 'code': code, 'full_name': fullName,
    });
    token = r['token'] as String?;
    return r;
  }

  /* خدمات و پایه */
  Future<List<dynamic>> services() async =>
      (await _send('GET', '/services'))['data'] as List<dynamic>;

  Future<List<dynamic>> addresses() async =>
      (await _send('GET', '/addresses'))['data'] as List<dynamic>;

  Future<void> addAddress(Map<String, dynamic> d) async {
    await _send('POST', '/addresses', body: d);
  }

  Future<List<dynamic>> patients() async =>
      (await _send('GET', '/patients'))['data'] as List<dynamic>;

  Future<Map<String, dynamic>> quote(Map<String, dynamic> d) =>
      _send('POST', '/orders/quote', body: d);

  Future<Map<String, dynamic>> me() => _send('GET', '/me');

  /* سفارش‌ها */
  Future<Map<String, dynamic>> activeOrder() => _send('GET', '/orders/active');

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> d,
      {String? prescriptionPath}) async {
    if (prescriptionPath != null && prescriptionPath.isNotEmpty) {
      return _upload('/orders', d.map((k, v) => MapEntry(k, v?.toString() ?? '')),
          'prescription', prescriptionPath);
    }
    return _send('POST', '/orders', body: d);
  }

  Future<Map<String, dynamic>> orderDetails(int id) => _send('GET', '/orders/$id');

  Future<void> cancelOrder(int id) async {
    await _send('POST', '/orders/$id/cancel');
  }

  Future<List<dynamic>> orderHistory() async =>
      (await _send('GET', '/orders'))['data'] as List<dynamic>;

  /* پرداخت */
  Future<void> payOnline(int orderId, int tip) async {
    await _send('POST', '/orders/$orderId/pay-online', body: {'tip': tip});
  }

  Future<void> payCash(int orderId, int tip) async {
    await _send('POST', '/orders/$orderId/pay-cash', body: {'tip': tip});
  }

  /* امتیاز */
  Future<void> submitReview(int orderId, int stars, List<String> tags,
      String comment) async {
    await _send('POST', '/orders/$orderId/review',
        body: {'stars': stars, 'tags': tags, 'comment': comment});
  }

  /* چت */
  Future<List<dynamic>> chatMessages(int orderId, {int afterId = 0}) async {
    final r = await _send('GET', '/orders/$orderId/chat?after_id=$afterId');
    return (r['data'] ?? r) as List<dynamic>;
  }

  Future<void> sendChat(int orderId, String text) async {
    await _send('POST', '/orders/$orderId/chat', body: {'text': text});
  }

  /* اعلان‌ها */
  Future<List<dynamic>> notifications() async =>
      (await _send('GET', '/notifications'))['data'] as List<dynamic>;
}
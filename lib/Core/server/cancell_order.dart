import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

Future<void> sendCancelInvoiceEmail({
  required String customerEmail,
  required String orderId,
  required double total,
  String? reason,
}) async {
  const String apiUrl = 'https://designland-backend.vercel.app/api/cancel-email';

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'customerEmail': customerEmail,
        'orderId': orderId,
        'total': total,
        if (reason != null) 'reason': reason,
      }),
    );

    if (response.statusCode == 200) {
      debugPrint('🎉 تم إرسال إيميل إلغاء الفاتورة بنجاح!');
    } else {
      debugPrint('فشل الإرسال: ${response.body}');
    }
  } catch (e) {
    debugPrint('Error: $e');
  }
}
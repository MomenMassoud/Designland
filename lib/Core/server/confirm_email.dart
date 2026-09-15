import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

Future<void> sendInvoiceEmail({
  required String customerEmail,
  required String orderId,
  required double total,
}) async {
  const String apiUrl = 'https://designland-backend.vercel.app/api/send-email';

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
      }),
    );

    if (response.statusCode == 200) {
      debugPrint('🎉 تم إرسال الفاتورة بنجاح باستخدام http!');
    } else {
      debugPrint('فشل الإرسال: ${response.body}');
    }
  } catch (e) {
    debugPrint('Error: $e');
  }
}
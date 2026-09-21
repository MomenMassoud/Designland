import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class EmailServer {
  static const String baseUrl = 'https://designland-backend.vercel.app/api';

  Future<void> sendCancelInvoiceEmail({
    required String customerEmail,
    required String orderId,
    required double total,
    String? reason,
  }) async {
    const String apiUrl = '${baseUrl}/cancel-email';

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


  Future<void> sendInvoiceEmail({
    required String customerEmail,
    required String orderId,
    required double total,
  }) async {
    const String apiUrl = '${baseUrl}/api/send-email';

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

  Future<bool> notifyAdmins({
    required String orderId,
    required double total,
    required String customerEmail,
  }) async {
    final url = Uri.parse('$baseUrl/notify-admins');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'orderId': orderId,
          'total': total,
          'customerEmail': customerEmail,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error notifying admins: $e');
      return false;
    }
  }

  /// 3. حذف حساب المستخدم وإيميله من Auth و Firestore
  static Future<bool> deleteUserAccount({required String uid}) async {
    final url = Uri.parse('$baseUrl/delete-account');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error deleting user account: $e');
      return false;
    }
  }
}

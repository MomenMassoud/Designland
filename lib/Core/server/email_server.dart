import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class EmailServer {
  static const String baseUrl = 'https://designland-backend.vercel.app/api';

  Future<void> sendCancelInvoiceEmail({
    required String customerEmail,
    required String customerName,
    required String orderId,
    required dynamic orderNumber,
    required double total,
    required List<Map<String, dynamic>> items,
    String? reason,
  }) async {
    const String apiUrl = '$baseUrl/cancel-email';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'customerEmail': customerEmail,
          'customerName': customerName,
          'orderId': orderId,
          'orderNumber': orderNumber,
          'total': total,
          'items': items,
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
    required String customerName,
    required int orderNumber,
    required String orderId,
    required double total,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send-email'), // استبدل بالرابط الخاص بك
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'customerEmail': customerEmail,
          'customerName': customerName,
          'orderNumber': orderNumber,
          'orderId': orderId,
          'total': total,
          'items': items,
        }),
      );
    } catch (e) {
      print("Error sending email: $e");
    }
  }

  Future<bool> notifyAdmins({
    required String orderId,
    required int orderNumber,
    required double total,
    required String customerEmail,
    required String customerName,
    required String customerPhone,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> selectedAddress,
  }) async {
    final url = Uri.parse('$baseUrl/notify-admins');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'orderId': orderId,
          'orderNumber': orderNumber,
          'total': total,
          'customerEmail': customerEmail,
          'customerName': customerName,
          'customerPhone': customerPhone,
          'items': items,
          'selectedAddress': selectedAddress,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
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
   Future<bool> sendCommentNotificationToAdmins({
    required String customerName,
    required String productName,
    required String commentText,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/notify_comment"),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'customerName': customerName,
          'productName': productName,
          'commentText': commentText,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}

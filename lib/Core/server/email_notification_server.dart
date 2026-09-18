import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailNotificationService {
  // استبدل هذا الرابط برابط الـ Vercel الخاص بـ backend مشروعك
  static const String baseUrl = 'https://designland-backend.vercel.app/api';

  /// 1. إرسال إيميل مخصص من الأدمن لمستخدم معين
  Future<bool> sendCustomEmail({
    required String recipientEmail,
    required String subject,
    required String messageBody,
  }) async {
    final url = Uri.parse('$baseUrl/send-custom-email');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'recipientEmail': recipientEmail,
          'subject': subject,
          'messageBody': messageBody,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error sending custom email: $e');
      return false;
    }
  }

  /// 2. إرسال إشعار وإيميل تنبيه لجميع الأدمينات عند وجود طلب جديد
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
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  // اسم الكلاود الخاص بك
  static const String cloudName = "kvjbgvtv";

  // اسم الـ Upload Preset الشغال عندك (Unsigned)
  static const String uploadPreset = "ml_default"; // استبدله باسم الـ Preset الخاص بك

  // مفاتيح الـ API لعمليات الحذف المشفرة
  static const String apiKey = "598764841989964";
  static const String apiSecret = "eoDPZwL0WtZciyfg1g8jG0z4iic"; // استبدله بـ API Secret الخاص بحسابك

  /// 1. دالة رفع الصورة إلى Cloudinary
  static Future<String?> uploadImage(XFile imageFile) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            await imageFile.readAsBytes(),
            filename: imageFile.name,
          ),
        );

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseString);
        return jsonResponse['secure_url'] as String;
      } else {
        print('Upload failed (Status ${response.statusCode}): $responseString');
        return null;
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  /// 2. استخراج الـ public_id من رابط الصورة
  static String? getPublicIdFromUrl(String imageUrl) {
    try {
      if (imageUrl.isEmpty) return null;
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex != -1 && uploadIndex + 2 < pathSegments.length) {
        final fullFileName = pathSegments.sublist(uploadIndex + 2).join('/');
        final lastDotIndex = fullFileName.lastIndexOf('.');
        if (lastDotIndex != -1) {
          return fullFileName.substring(0, lastDotIndex);
        }
        return fullFileName;
      }
      return null;
    } catch (e) {
      print("Error extracting public_id: $e");
      return null;
    }
  }

  /// 3. دالة حذف الصورة القديمة من Cloudinary
  static Future<bool> deleteImage(String imageUrl) async {
    final publicId = getPublicIdFromUrl(imageUrl);
    if (publicId == null || publicId.isEmpty) return false;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // توقيع الطلب بـ SHA1 لضمان الأمان لدى Cloudinary
      final stringToSign = 'public_id=$publicId&timestamp=$timestamp$apiSecret';
      final signature = sha1.convert(utf8.encode(stringToSign)).toString();

      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/destroy',
      );

      final response = await http.post(
        url,
        body: {
          'public_id': publicId,
          'api_key': apiKey,
          'timestamp': timestamp.toString(),
          'signature': signature,
        },
      );

      if (response.statusCode == 200) {
        print("Image deleted successfully from Cloudinary!");
        return true;
      } else {
        print("Failed to delete image: ${response.body}");
        return false;
      }
    } catch (e) {
      print('Error deleting image from Cloudinary: $e');
      return false;
    }
  }
}
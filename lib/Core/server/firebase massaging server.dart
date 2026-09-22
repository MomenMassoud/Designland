import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FirebaseMessagingService {
  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  static Future<void> initialize() async {
    try {
      // Permission - مهم خصوصًا iOS
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Get FCM token
      final token = await _messaging.getToken();

      debugPrint('==============================');
      debugPrint('FCM TOKEN: $token');
      debugPrint('==============================');

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM TOKEN REFRESHED: $newToken');
      });
    } catch (e, stackTrace) {
      debugPrint('FCM ERROR: $e');
      debugPrint('$stackTrace');
    }
  }
}
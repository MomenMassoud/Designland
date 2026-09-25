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
      final token = await _messaging.getToken();
      _messaging.onTokenRefresh.listen((newToken) {
      });
    } catch (e, stackTrace) {
      debugPrint('$stackTrace');
    }
  }
}
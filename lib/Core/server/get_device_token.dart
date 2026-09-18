import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

Future<String?> getDeviceToken() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // 1. طلب إذن الإشعارات (ضروري جدًا للـ iOS والـ Web)
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    String? token;

    if (kIsWeb) {
      // 2. جلب التوكن للـ Web باستخدام VAPID Key
      token = await messaging.getToken(
        vapidKey: "BDSAbBoaPQaMPGfVU1C94pZR58doPiMkU4n8kAVGt79rvrZFgtITKjQMx1Uv_uQ8attJCuLM6a6FKlJYh4qTbKY",
      );
    } else {
      // 3. جلب التوكن للـ Mobile (Android / iOS)
      token = await messaging.getToken();
    }

    print("FCM Token: $token");
    return token;
  } else {
    print("المستخدم رفض إذن الإشعارات");
    return null;
  }
}
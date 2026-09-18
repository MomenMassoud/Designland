import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

Future<void> saveDeviceTokenToFirestore() async {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // تأكد من وجود مستخدم مسجل الدخول
  if (currentUser == null) return;

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // 1. طلب الإذن
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    String? token;

    if (kIsWeb) {
      token = await messaging.getToken(
        vapidKey: "BDSAbBoaPQaMPGfVU1C94pZR58doPiMkU4n8kAVGt79rvrZFgtITKjQMx1Uv_uQ8attJCuLM6a6FKlJYh4qTbKY",
      );
    } else {
      token = await messaging.getToken();
    }

    if (token != null) {
      // 2. إضافة التوكن إلى كوليكشن user في آراي devices
      await FirebaseFirestore.instance
          .collection('user')
          .doc(currentUser.uid)
          .set({
        'devices': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));

      print("Device Token Saved/Updated Successfully!");
    }
  }

  // 3. الاستماع لتغير التوكن (Token Refresh) وتحديثه تلقائياً
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    if (currentUser != null) {
      await FirebaseFirestore.instance
          .collection('user')
          .doc(currentUser.uid)
          .set({
        'devices': FieldValue.arrayUnion([newToken]),
      }, SetOptions(merge: true));
    }
  });
}
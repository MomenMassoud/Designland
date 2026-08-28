import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? currentSessionId;
  static Timer? _heartbeatTimer;

  // 1. بدء الجلسة وتشغيل الـ Heartbeat لتحديث آخر وقت نشاط باستمرار
  static Future<void> startSession() async {
    try {
      final user = _auth.currentUser;
      final sessionRef = _db.collection('analytics_sessions').doc();
      currentSessionId = sessionRef.id;

      final now = FieldValue.serverTimestamp();

      await sessionRef.set({
        'sessionId': currentSessionId,
        'userId': user?.uid ?? 'guest',
        'isGuest': user == null,
        'startTime': now,
        'lastActiveTime': now,
        'platform': kIsWeb ? 'web' : 'mobile',
        'visitedTabs': ['Home'],
        'viewedProducts': [],
      });

      // تشغيل مؤقت يحدث آخر وقت نشاط كل 15 ثانية طالما الموقع مفتوح
      _startHeartbeat();
    } catch (e) {
      debugPrint("Analytics Error (startSession): $e");
    }
  }

  // Heartbeat لإرسال تنبيه كل 15 ثانية أن المستخدم ما زال بالصفحة
  static void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _updateLastActive();
    });
  }

  // تحديث timestamp لآخر ظهور للمستخدم
  static Future<void> _updateLastActive() async {
    if (currentSessionId == null) return;
    try {
      await _db.collection('analytics_sessions').doc(currentSessionId).update({
        'lastActiveTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Analytics Error (_updateLastActive): $e");
    }
  }

  // إيقاف الـ Heartbeat وتسجيل الخروج المباشر إذا حدث عبر زر أو تنقل
  static Future<void> endSession() async {
    _heartbeatTimer?.cancel();
    await _updateLastActive();
  }

  // 2. تسجيل زيارات التبويبات
  static Future<void> logTabVisit(String tabName) async {
    if (currentSessionId == null) return;
    try {
      await _db.collection('analytics_sessions').doc(currentSessionId).update({
        'visitedTabs': FieldValue.arrayUnion([tabName]),
        'lastActiveTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Analytics Error (logTabVisit): $e");
    }
  }

  // 3. تسجيل فتح المنتج فوراً بدلاً من انتظار خروج المستخدم
  static Future<void> logProductOpen({
    required String productId,
    required String productTitle,
  }) async {
    if (currentSessionId == null) return;
    try {
      await _db.collection('analytics_sessions').doc(currentSessionId).update({
        'viewedProducts': FieldValue.arrayUnion([
          {
            'productId': productId,
            'title': productTitle,
            'openedAt': DateTime.now().toIso8601String(),
          }
        ]),
        'lastActiveTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Analytics Error (logProductOpen): $e");
    }
  }
}
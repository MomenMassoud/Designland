import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;

class UserPresenceService with WidgetsBindingObserver {
  static final UserPresenceService _instance = UserPresenceService._internal();
  factory UserPresenceService() => _instance;
  UserPresenceService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void init() {
    WidgetsBinding.instance.addObserver(this);

    // تحديث الحالة عند بدء التشغيل
    _updateStatus(isOnline: true);

    // معالجة قفل المتصفح أو التبويب خصيصاً للـ Web
    if (kIsWeb) {
      _setupWebUnloadListener();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  /// الاستماع لإغلاق التبويب أو إعادة تحميل الصفحة في الـ Web
  void _setupWebUnloadListener() {
    html.window.onBeforeUnload.listen((event) {
      final user = _auth.currentUser;
      if (user == null || user.isAnonymous) return;

      // تحديث متزامن ومباشر قبل إغلاق الصفحة
      _updateStatus(isOnline: false);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateStatus(isOnline: true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _updateStatus(isOnline: false);
    }
  }

  Future<void> _updateStatus({required bool isOnline}) async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return;

    try {
      await _firestore.collection('user').doc(user.uid).set({
        'isOnline': isOnline,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating user presence in Firestore: $e');
    }
  }

  Future<void> setOnlineOnLogin() async {
    await _updateStatus(isOnline: true);
  }

  Future<void> setOfflineOnLogout() async {
    await _updateStatus(isOnline: false);
  }
}
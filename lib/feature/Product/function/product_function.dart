import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<String> getOrCreateGuestId() async {
  const String storageKey = 'guest_device_id';

  if (kIsWeb) {
    try {
      final String? webGuestId = html.window.localStorage[storageKey];
      if (webGuestId != null && webGuestId.isNotEmpty) {
        return webGuestId;
      }
      final String newWebId = 'guest_${const Uuid().v4()}';
      html.window.localStorage[storageKey] = newWebId;
      return newWebId;
    } catch (_) {
      return 'guest_fallback_web';
    }
  } else {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? guestId = prefs.getString(storageKey);
      if (guestId == null) {
        guestId = 'guest_${const Uuid().v4()}';
        await prefs.setString(storageKey, guestId);
      }
      return guestId;
    } catch (_) {
      return 'guest_fallback_mobile';
    }
  }
}
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:universal_html/html.dart' as html; // 👈 آمن تماماً للكومبايل على الموبايل والويب

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();
Future<void> setupWeb() async {
  if (!kIsWeb) return;

  try {
    final permission =
    await html.Notification.requestPermission();

    if (permission != 'granted') {
      return;
    }
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;

      final String title =
          notification?.title ??
              message.data['title'] ??
              'إشعار جديد 🔔';

      final String body =
          notification?.body ??
              message.data['body'] ??
              '';
      try {
        final registrations =
        await html.window.navigator.serviceWorker
            ?.getRegistrations();

        if (registrations == null || registrations.isEmpty) {
          return;
        }
        for (final registration in registrations) {
          print('SW Scope: ${registration.scope}');
        }

        html.ServiceWorkerRegistration? fcmRegistration;

        for (final registration in registrations) {
          if (registration.scope.contains(
            'firebase-cloud-messaging-push-scope',
          )) {
            fcmRegistration = registration;
            break;
          }
        }

        if (fcmRegistration == null) {
          return;
        }
        await fcmRegistration.showNotification(
          title,
          {
            'body': body,
            'requireInteraction': true,
          },
        );
      } catch (e, stackTrace) {
        print(e);
        print(stackTrace);
      }
    });
  } catch (e, stackTrace) {
    print(stackTrace);
  }
}
// --- 2. تهيئة إشعارات أندرويد وآيفون للموبايل فقط ---
Future<void> setupAndroidNotifications() async {
  if (kIsWeb) return; // منع التنفيذ على الـ Web لتفادي التعارض

  // إعدادات تهيئة الموبايل
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: DarwinInitializationSettings(),
  );

  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse details) {
      print('Mobile Notification clicked: ${details.payload}');
    },
  );

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'هذه القناة خاصة بإشعارات التطبيق الهامة',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  });
}

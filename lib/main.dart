import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'Core/Utils/app_routes.dart';
import 'Core/widgets/App_localization.dart';
import 'feature/Splash/View/splash_view.dart';
import 'firebase_options.dart';




final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> setupAndroidNotifications() async {
  // 1. إنشاء قناة الإشعارات للـ Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'هذه القناة خاصة بإشعارات التطبيق الهامة',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // 2. إظهار الإشعار حتى لو التطبيق مفتوح في الـ Foreground
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // 3. الاستماع للإشعارات أثناء فتح التطبيق
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: '@mipmap/ic_launcher', // أو أيقونة إشعاراتك
          ),
        ),
      );
    }
    if (kIsWeb) {
      showWebNotification(
        message.notification?.title ?? '',
        message.notification?.body ?? '',
      );
    }
  });
}

void showWebNotification(String title, String body) {
  if (!kIsWeb) return;


}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform
  );
  runApp(
      MyApp()
  );
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final deviceLocale = Get.deviceLocale ?? const Locale('en');
    return GetMaterialApp(
      builder: (context, child) {
        return child ?? const SizedBox();
      },
      onGenerateRoute: (setting){
        return GetPageRoute(
            routeName: SplashView.id
        );
      },
      debugShowCheckedModeBanner: false,
      title: 'DesignLand',
      translations: AppTranslations(),
      locale: deviceLocale,
      initialRoute: SplashView.id,
      routes: appRoutes,
      fallbackLocale: const Locale('en', 'US'),
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
        ),
      ),
    );
  }
}
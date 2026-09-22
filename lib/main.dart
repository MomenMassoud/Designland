import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:get/get.dart';

import 'Core/Utils/app_routes.dart';
import 'Core/server/firebase massaging server.dart';
import 'Core/widgets/App_localization.dart';
import 'feature/Splash/View/splash_view.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // ضمان تهيئة أطر عمل الفلاتر
  WidgetsFlutterBinding.ensureInitialized();

  // تفعيل مسار الروابط المباشر بدون (#) للـ Web
  usePathUrlStrategy();

  // تهيئة شريط النظام والشفافية (تخص الهاتف فقط دون الـ Web)
  if (!kIsWeb) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  // تهيئة الفايربيز وإشعارات FCM بالتوازي أو التتابع المحسّن
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // تشغيل خدمة الإشعارات دون إعاقة التحميل الأول للـ UI إذا أمكن
  FirebaseMessagingService.initialize().catchError((e) {
    debugPrint('Error initializing Firebase Messaging: $e');
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // تحديد اللغة الافتراضية
    final Locale deviceLocale = Get.deviceLocale ?? const Locale('en');

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DesignLand',
      translations: AppTranslations(),
      locale: deviceLocale,
      fallbackLocale: const Locale('en', 'US'),
      initialRoute: SplashView.id,
      routes: appRoutes,

      // تحسين الثيم العام وتقليل إعادة الرندر
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
        ),
      ),

      // إزالة دالة builder غير الضرورية لتجنب التغليف الإضافي للشجرة (Extra Tree Wrapping)
      builder: (context, child) => child ?? const SizedBox.shrink(),
    );
  }
}
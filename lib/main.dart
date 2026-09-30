import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:get/get.dart';
import 'Core/Utils/app_routes.dart';
import 'Core/Utils/app_themes.dart';
import 'Core/server/firebase massaging server.dart';
import 'Core/services/user_presence_service.dart';
import 'Core/widgets/App_localization.dart';
import 'feature/Product/widget/product_widget.dart';
import 'feature/Splash/View/splash_view.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تفعيل مسار الروابط المباشر بدون (#) للـ Web
  usePathUrlStrategy();

  if (!kIsWeb) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
    );
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessagingService.initialize().catchError((e) {
    debugPrint('Error initializing Firebase Messaging: $e');
  });

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    UserPresenceService().init();
  }

  @override
  void dispose() {
    UserPresenceService().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Locale deviceLocale = Get.deviceLocale ?? const Locale('en');

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DesignLand',
      translations: AppTranslations(),
      locale: deviceLocale,
      fallbackLocale: const Locale('en', 'US'),

      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: ThemeMode.system,

      initialRoute: SplashView.id,
      getPages: appPages, // 👈 استبدال routes بـ getPages

      // معالجة فتح روابط المنتج المباشرة على الويب / الموبايل
      onGenerateRoute: (settings) {
        if (settings.name != null && settings.name!.startsWith('/product/')) {
          final productId = settings.name!.replaceFirst('/product/', '');
          return MaterialPageRoute(
            builder: (context) => ProductWidget(productDoc: productId),
            settings: settings,
          );
        }
        return null;
      },

      builder: (context, child) => child ?? const SizedBox.shrink(),
    );
  }
}